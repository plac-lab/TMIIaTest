/*
 * Copyright (c) 2013, 2014
 *
 *     Yuan Mei
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * tcpio host port ...
 */

/* waitpid on linux */
#include <sys/types.h>
#include <sys/wait.h>

#include <sys/ioctl.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <netdb.h>

#include <err.h>
#include <errno.h>
#include <fcntl.h>

#ifdef __linux /* on linux */
#include <pty.h>
#include <utmp.h>
#else /* (__APPLE__ & __MACH__) */
#include <util.h> /* this is for mac or bsd */
#endif

#include <paths.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <pthread.h>

#include "common.h"
#include "command.h"

static time_t startTime, stopTime;
static unsigned int chMask;
static size_t nCh;
static size_t nEvents;

/******************************************************************************/
#define Sleep(x) (usleep((x)*5000))
/******************************************************************************/

#define MAXSLEEP 2
static int connect_retry(int sockfd, const struct sockaddr *addr, socklen_t alen)
{
    int nsec;
    /* Try to connect with exponential backoff. */
    for (nsec = 1; nsec <= MAXSLEEP; nsec <<= 1) {
        if (connect(sockfd, addr, alen) == 0) {
            /* Connection accepted. */
            return(0);
        }
        /*Delay before trying again. */
        if (nsec <= MAXSLEEP/2)
            sleep(nsec);
    }
    return(-1);
}

static int get_socket(char *host, char *port)
{
    int status;
    struct addrinfo addrHint, *addrList, *ap;
    int sockfd, sockopt;

    memset(&addrHint, 0, sizeof(struct addrinfo));
    addrHint.ai_flags = AI_CANONNAME|AI_NUMERICSERV;
    addrHint.ai_family = AF_INET; /* we deal with IPv4 only, for now */
    addrHint.ai_socktype = SOCK_STREAM;
    addrHint.ai_protocol = 0;
    addrHint.ai_addrlen = 0;
    addrHint.ai_canonname = NULL;
    addrHint.ai_addr = NULL;
    addrHint.ai_next = NULL;

    status = getaddrinfo(host, port, &addrHint, &addrList);
    if(status < 0) {
        error_printf("getaddrinfo: %s\n", gai_strerror(status));
        return status;
    }

    for(ap=addrList; ap!=NULL; ap=ap->ai_next) {
        sockfd = socket(ap->ai_family, ap->ai_socktype, ap->ai_protocol);
        if(sockfd < 0) continue;
        sockopt = 1;
        if(setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, (char*)&sockopt, sizeof(sockopt)) == -1) {
            close(sockfd);
            warn("setsockopt TCP_NODELAY");
            continue;
        }
        if(setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, (char*)&sockopt, sizeof(sockopt)) == -1) {
            close(sockfd);
            warn("setsockopt SO_KEEPALIVE");
            continue;
        }
        if(connect_retry(sockfd, ap->ai_addr, ap->ai_addrlen) < 0) {
            close(sockfd);
            warn("connect");
            continue;
        } else {
            break; /* success */
        }
    }
    if(ap == NULL) { /* No address succeeded */
        error_printf("Could not connect, tried %s:%s\n", host, port);
        return -1;
    }
    freeaddrinfo(addrList);
    return sockfd;
}

static int query_response_with_timeout(int sockfd, char *queryStr, size_t nbytes, char *respStr,
                                       ssize_t nbytes_ret_exp, struct timeval *tv)
{
    int maxfd;
    fd_set rfd;
    int nsel;
    ssize_t nr, nw;
    size_t ret;

    nw = send(sockfd, queryStr, nbytes, 0);
    if(nw<0) {
        warn("send");
        return (int)nw;
    }
    if(nbytes_ret_exp == 0) return 0;

    ret = 0;
    for(;;) {
        FD_ZERO(&rfd);
        FD_SET(sockfd, &rfd);
        maxfd = sockfd;
        nsel = select(maxfd+1, &rfd, NULL, NULL, tv);
        if(nsel < 0 && errno != EINTR) { /* other errors */
            return nsel;
        }
        if(nsel == 0) { /* timed out */
            break;
        }
        if(nsel>0 && FD_ISSET(sockfd, &rfd)) {
            nr = read(sockfd, respStr+ret, BUFSIZ-ret);
            // debug_printf("nr = %zd\n", nr);
            if(nr>0) {
                ret += nr;
                if(ret >= nbytes_ret_exp && nbytes_ret_exp > 0) break;
            } else {
                break;
            }
        }
    }
    return (int)ret;
}

static int query_response(int sockfd, char *queryStr, size_t nbytes,
                          char *respStr, ssize_t nbytes_ret_exp)
{
    struct timeval tv = {
        .tv_sec = 0,
        .tv_usec = 500000,
    };
    return query_response_with_timeout(sockfd, queryStr, nbytes, respStr, nbytes_ret_exp, &tv);
}

static void atexit_flush_files(void)
{
    /* hdf5io_flush_file(waveformFile); */
    /* hdf5io_close_file(waveformFile); */
}

static void signal_kill_handler(int sig)
{
    printf("\nstart time = %zd\n", startTime);
    printf("stop time  = %zd\n", time(NULL));
    fflush(stdout);

    error_printf("Killed, cleaning up...\n");
    atexit(atexit_flush_files);
    exit(EXIT_SUCCESS);
}

static void *send_and_receive_loop(void *arg)
{
    struct timeval tv; /* tv should be re-initialized in the loop since select
                          may change it after each call */
    int sockfd, maxfd, nsel;
    fd_set rfd, wfd;
    char ibuf[BUFSIZ];
    size_t iEvent = 0;
    ssize_t nr, nw, readTotal;
/*
    FILE *fp;
    if((fp=fopen("log.txt", "w"))==NULL) {
        perror("log.txt");
        return (void*)NULL;
    }
*/
    sockfd = *((int*)arg);

    readTotal = 0;
    for(;;) {
        tv.tv_sec = 10;
        tv.tv_usec = 0;
        FD_ZERO(&rfd);
        FD_SET(sockfd, &rfd);
        FD_ZERO(&wfd);
        FD_SET(sockfd, &wfd);
        maxfd = sockfd;
        nsel = select(maxfd+1, &rfd, &wfd, NULL, &tv);
        if(nsel < 0 && errno != EINTR) { /* other errors */
            warn("select");
            break;
        }
        if(nsel == 0) {
            warn("timed out");
        }
        if(nsel>0) {
            if(FD_ISSET(sockfd, &rfd)) {
                nr = read(sockfd, ibuf, sizeof(ibuf));
                debug_printf("nr = %zd\n", nr);
                if(nr < 0) {
                    warn("read");
                    break;
                }
                readTotal += nr;
//            write(fileno(fp), ibuf, nr);
            }
            if(FD_ISSET(sockfd, &wfd)) {
                strlcpy(ibuf, "CURVENext?\n", sizeof(ibuf));
                nw = write(sockfd, ibuf, 2459); // strnlen(ibuf, sizeof(ibuf)));
                debug_printf("nw = %zd\n", nw);
            }
        }
        if(iEvent >= nEvents) {
            goto end;
        }
        iEvent++;
    }
end:
    debug_printf("readTotal = %zd\n", readTotal);

//    fclose(fp);
    return (void*)NULL;
}

int main(int argc, char **argv)
{
    char buf[BUFSIZ];
    uint32_t *buf32;
    char *p, *outFileName, *scopeAddress, *scopePort;
    unsigned int v, c;
    int sockfd;
    pthread_t wTid;
    ssize_t i;
    size_t n, nWfmPerChunk = 100;

    // if(argc<6) {
    //     error_printf("%s scopeAdddress scopePort outFileName chMask(0x..) nEvents nWfmPerChunk\n",
    //                  argv[0]);
    //     return EXIT_FAILURE;
    // }
    scopeAddress = argv[1];
    scopePort = argv[2];
    // outFileName = argv[3];
    // nEvents = atol(argv[5]);
    //
    // errno = 0;
    // chMask = strtol(argv[4], &p, 16);
    // v = chMask;
    // for(c=0; v; c++) v &= v - 1; /* Brian Kernighan's way of counting bits */
    // nCh = c;
    // if(errno != 0 || *p != 0 || p == argv[4] || chMask <= 0 || nCh>SCOPE_NCH) {
    //     error_printf("Invalid chMask input: %s\n", argv[4]);
    //     return EXIT_FAILURE;
    // }
    // if(argc>=7)
    //     nWfmPerChunk = atol(argv[6]);
    //
    // debug_printf("outFileName: %s, chMask: 0x%02x, nCh: %zd, nEvents: %zd, nWfmPerChunk: %zd\n",
    //              outFileName, chMask, nCh, nEvents, nWfmPerChunk);

    sockfd = get_socket(scopeAddress, scopePort);
    if(sockfd < 0) {
        error_printf("Failed to establish a socket.\n");
        return EXIT_FAILURE;
    }

    signal(SIGKILL, signal_kill_handler);
    signal(SIGINT, signal_kill_handler);

//    pthread_create(&wTid, NULL, pop_and_save, &sockfd);

    printf("start time = %zd\n", startTime = time(NULL));

//    send_and_receive_loop(&sockfd);

    buf32 = (uint32_t*)buf;

    /* dac value */
    // n = cmd_write_register(&buf32, 0, 40632); // 3.1V
    //n = cmd_write_register(&buf32, 0, 32768); // 2.5V
    //n = cmd_read_register(&buf32, 3);
    FILE *fp;
    char buffer[15];
    fp = fopen("S1_L2.dat","r");
    fseek(fp,SEEK_SET,0);
    size_t word_counter=0;
    uint32_t * jtag_buf;
    while(1 == fread(buffer,11,1,fp)){word_counter++;}
    jtag_buf = (uint32_t*)calloc(word_counter, sizeof(uint32_t));
    fseek(fp,SEEK_SET,0);
    uint32_t wd;
    int i=0;
    while(1 == fread(buffer,11,1,fp))
    {
      sscanf(buffer,"%x",&wd);
      printf("0x%08x\n",wd);
      jtag_buf[i] = wd;
      i++;
    }
    n = cmd_write_memory(&buf32, 0,jtag_buf,word_counter);
    printf("sent: ");
    for(i=0; i<n; i++) {
        printf("%02x ", (unsigned char)buf[i]);
    }
    printf("\n");
    n = query_response(sockfd, buf, n, buf, 0);
    n = cmd_send_pulse(&buf32, 0x0000000c);
    n = query_response(sockfd, buf, n, buf, 0);
    sleep(10);
    n = cmd_read_memory(&buf32, 0,word_counter);
    n = query_response(sockfd, buf, n, buf, 1);
    printf("received: ");
    for(i=0; i<n; i++) {
        printf("%02x ", (unsigned char)buf[i]);
    }
    printf("\n");
    fclose(f);
    // /* bit 0 sends DAC, bit 8 resets topmetal_simple module */
    // n = cmd_write_register(&buf32, 1, 0x0101);
    // n = query_response(sockfd, buf, n, buf, 0);
    // n = cmd_write_register(&buf32, 1, 0x0000);
    // n = query_response(sockfd, buf, n, buf, 0);
    //
    // /* select clock source */
    // n = cmd_write_register(&buf32, 5, 0x0003);
    // n = query_response(sockfd, buf, n, buf, 0);
    // /* (15) trigger rate control, (14) trigger control */
    // /* low 4 bit controls number of resets between triggers */
    // /* 1 trigger every 2**((bit 3 downto 0)+1) resets */
    // n = cmd_write_register(&buf32, 4, 0x8000);
    // n = query_response(sockfd, buf, n, buf, 0);
    // /* trigger delay, trigger_out at val+1 TM_CLK cycles after new frame starts */
    // n = cmd_write_register(&buf32, 6, 4100);
    // n = query_response(sockfd, buf, n, buf, 0);
    // /* bit10 starts TM, bit7~4 controls number of frames between resets */
    // /* 1 reset every 2**((bit 7 downto 4)+1) frames, reset lasts one full frame */
    // /* (bit 3 downto 0) controls TM_CLK, = f_CLK/2**((bit 3 downto 0)+1) */
    // /* bit 15 (=1) vetos the output of EX_RST, bit 14 vetos trigger_out */
    // n = cmd_write_register(&buf32, 2, 0xc400); /* set vetos here, but not bit7~0 */
    // n = query_response(sockfd, buf, n, buf, 0);
    // n = cmd_write_register(&buf32, 2, 0xc000); /* set both vetos and bit7~0 */
    // n = query_response(sockfd, buf, n, buf, 0);
    // /* bit 15 enables stop_control, bit (9 downto 0) sets the stop_address */
    // /* adress of 0xff will stop at pixel #238 (counting start from 0) */
    // Sleep(100);
    // n = cmd_write_register(&buf32, 3, 0x80d5);
    // n = query_response(sockfd, buf, n, buf, 0);
    // /* force a trigger */
    // Sleep(100);
    // n = cmd_send_pulse(&buf32, 0x01); // pulse_reg(0)
    // n = query_response(sockfd, buf, n, buf, 0);
    //
     stopTime = time(NULL);
//    pthread_join(wTid, NULL);

    printf("\nstart time = %zd\n", startTime);
    printf("stop time  = %zd\n", stopTime);

    close(sockfd);
    atexit_flush_files();
    return EXIT_SUCCESS;
}
