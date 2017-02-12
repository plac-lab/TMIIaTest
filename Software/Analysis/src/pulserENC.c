/** \file
 * Analyze CSA output traces responding to pulses for ENC evaluation.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <string.h>
#include <unistd.h>

#include <gsl/gsl_histogram2d.h>

#include "common.h"
#include "filters.h"
#include "hdf5rawWaveformIo.h"
typedef SCOPE_DATA_TYPE IN_WFM_BASE_TYPE;
typedef SCOPE_DATA_TYPE OUT_WFM_BASE_TYPE;

/** Parameters settable from commandline */
typedef struct param
{
    size_t diffSep;  //!< rise-time in samples for pulse finding
    double riseFrac; //!< fraction of max pulse height for pulse edge location
    double fltM;     //!< exp decay constant for Trapezoidal filter
    size_t sPre;     //!< samples before rising edge
    size_t sLen;     //!< total number of samples of a pulse
    size_t sHscale;  //!< histogram sample scaling factor
} param_t;

param_t param_default = {
    .diffSep = 150,
    .riseFrac = 0.5,
    .fltM = -1.0,
    .sPre = 1000,
    .sLen = 4000,
    .sHscale = 4
};

void print_usage(const param_t *pm)
{
    printf("Usage:\n");
    printf("      -r rise time in samples[%zd]\n", pm->diffSep);
    printf("      -f riseFrac[%g]\n", pm->riseFrac);
    printf("      -m fltM[%g]\n", pm->fltM);
    printf("      -p sPre[%zd]\n", pm->sPre);
    printf("      -l sLen[%zd]\n", pm->sLen);
    printf("      -s iStart[0] -e iStop[-1] starting and stopping(+1) eventid\n");
    printf("      inFileName(.h5) outFileName\n");
}

/** Find pulses by their rising edges.
 *
 * @param[out] npulse number of pulses found
 * @param[in] fltH input waveform should be loaded into it already
 * @param[in] diffSep basically the rise time in samples
 * @param[in] riseFrac fraction of max pulse height to set pulse edge location
 * @param[in] M exp decay constant for Trapezoidal filter
 * @return the list of rising edge positions (times)
 */
size_t *find_pulses(size_t *npulse, filters_t *fltH, size_t diffSep, double riseFrac, double M)
{

    size_t n, nc = 1024;
    size_t *pulseRiseT = NULL, *pulseRiseT1;

    size_t flt_k = 2*diffSep, flt_l = 2*flt_k;
    double flt_M = M, max, dV;
    ssize_t i, j, sep, prev;

    if((pulseRiseT = calloc(nc, sizeof(size_t))) == NULL) {
        error_printf("calloc failed for pulseRiseT in %s()\n", __FUNCTION__);
        return NULL;
    }
    
    filters_trapezoidal(fltH, flt_k, flt_l, flt_M);

    max = 0.0;
    for(i=0; i<fltH->wavLen; i++)
        if(fltH->outWav[i] > max) max = fltH->outWav[i];

    sep = flt_k + flt_l;
    prev = 0;
    n = 0;
    for(i=0; i<fltH->wavLen; i++) {
        j = ((i+diffSep)>=fltH->wavLen)?(fltH->wavLen-1):(i+diffSep);
        dV = fltH->inWav[j] - fltH->inWav[i];
        if(dV > max * riseFrac) {
            if(i-prev > sep) {
                pulseRiseT[n] = j; n++;
                if(n >= nc) {
                    nc *= 2;
                    if((pulseRiseT1 = realloc(pulseRiseT, nc * sizeof(size_t))) == NULL) {
                        error_printf("realloc failed for pulseRiseT in %s()\n", __FUNCTION__);
                        *npulse = n;
                        return pulseRiseT;
                    }
                    pulseRiseT = pulseRiseT1;
                }
                prev = i;
            }
        }
    }
    *npulse = n;
    return pulseRiseT;
}

int main(int argc, char **argv)
{
    int optC = 0;
    param_t pm;

    char *inFileName, *outFileName;
    struct hdf5rawWaveformIo_waveform_file *inWfmFile;
    struct waveform_attribute inWfmAttr;
    struct hdf5rawWaveformIo_waveform_event inWfmEvent;
    IN_WFM_BASE_TYPE *inWfmBuf;
    // OUT_WFM_BASE_TYPE *outWfmBuf;
    filters_t *fltHdl;

    ssize_t iStart=0, iStop=-1, i, j, k, iCh;
    size_t nEventsInFile, chGrpLen, npulse, *pulseRiseT, nSep;
    unsigned int v, c;
    size_t chGrpIdx[SCOPE_NCH] = {0};
    double frameSize, val, sep, sepMu, sepSigma;

    gsl_histogram2d *wav2H, *flt2H;
        
    memcpy(&pm, &param_default, sizeof(pm));
    // parse switches
    while((optC = getopt(argc, argv, "e:f:l:m:p:r:s:")) != -1) {
        switch(optC) {
        case 'e':
            iStop = atoll(optarg);
            break;
        case 'f':
            pm.riseFrac = atof(optarg);
            break;
        case 'l':
            pm.sLen = atoll(optarg);
            break;
        case 'm':
            pm.fltM = atof(optarg);
            break;
        case 'p':
            pm.sPre = atoll(optarg);
            break;
        case 'r':
            pm.diffSep = atoll(optarg);
            break;
        case 's':
            iStart = atoll(optarg);
            break;
        default:
            print_usage(&pm);
            return EXIT_FAILURE;
            break;
        }
    }

    argc -= optind;
    argv += optind;
    if(argc<2 || argc>=3) {
        print_usage(&pm);
        return EXIT_FAILURE;
    }

    inFileName = argv[0];
    outFileName = argv[1];

    inWfmFile = hdf5rawWaveformIo_open_file_for_read(inFileName);
    hdf5rawWaveformIo_read_waveform_attribute_in_file_header(inWfmFile, &inWfmAttr);

    fprintf(stderr, "waveform_attribute:\n"
            "     chMask  = 0x%04x\n"
            "     nPt     = %zd\n"
            "     nFrames = %zd\n"
            "     dt      = %g\n"
            "     t0      = %g\n"
            "     ymult   = %g %g %g %g\n"
            "     yoff    = %g %g %g %g\n"
            "     yzero   = %g %g %g %g\n",
            inWfmAttr.chMask, inWfmAttr.nPt, inWfmAttr.nFrames, inWfmAttr.dt,
            inWfmAttr.t0, inWfmAttr.ymult[0], inWfmAttr.ymult[1], inWfmAttr.ymult[2],
            inWfmAttr.ymult[3], inWfmAttr.yoff[0], inWfmAttr.yoff[1],
            inWfmAttr.yoff[2], inWfmAttr.yoff[3], inWfmAttr.yzero[0],
            inWfmAttr.yzero[1], inWfmAttr.yzero[2], inWfmAttr.yzero[3]);

    nEventsInFile = hdf5rawWaveformIo_get_number_of_events(inWfmFile);
    fprintf(stderr, "Number of events in file: %zd\n", nEventsInFile);
    if(iStart < 0) iStart = 0;
    if(iStart >= nEventsInFile) iStart = nEventsInFile - 1;
    if(iStop < 0) iStop = nEventsInFile;
    if(iStop <= iStart) iStop = iStart + 1;
    
    if(inWfmAttr.nFrames > 0) {
        frameSize = inWfmAttr.nPt / (double)inWfmAttr.nFrames;
    } else {
        frameSize = (double)inWfmAttr.nPt;
    }

    v = inWfmAttr.chMask;
    for(c=0; v; c++) v &= v - 1;
    /* Brian Kernighan's way of counting bits */
    chGrpLen = inWfmFile->nCh / c;
    i=0;
    for(v=0; v<SCOPE_NCH; v++)
        if((inWfmAttr.chMask >> v) & 0x01) {
            chGrpIdx[i] = v;
            i++;
        }
    inWfmBuf = (IN_WFM_BASE_TYPE*)malloc(inWfmFile->nPt * inWfmFile->nCh * sizeof(IN_WFM_BASE_TYPE));
    inWfmEvent.wavBuf = inWfmBuf;

    fltHdl = filters_init(NULL, inWfmFile->nPt);
    wav2H = gsl_histogram2d_alloc(pm.sLen/pm.sHscale, 128);
    gsl_histogram2d_set_ranges_uniform(wav2H, -0.5 * inWfmAttr.dt, (pm.sLen+0.5) * inWfmAttr.dt,
        inWfmAttr.yzero[chGrpIdx[0]] + (-128.5 - inWfmAttr.yoff[chGrpIdx[0]]) * inWfmAttr.ymult[chGrpIdx[0]],
        inWfmAttr.yzero[chGrpIdx[0]] + ( 127.5 - inWfmAttr.yoff[chGrpIdx[0]]) * inWfmAttr.ymult[chGrpIdx[0]]);
    
    flt2H = gsl_histogram2d_alloc(pm.sLen/pm.sHscale, 256);
    gsl_histogram2d_set_ranges_uniform(flt2H, -0.5 * inWfmAttr.dt, (pm.sLen+0.5) * inWfmAttr.dt, -0.01, -0.01 + 256 * inWfmAttr.ymult[chGrpIdx[0]]);

    nSep = 0; sepMu = 0.0; sepSigma = 0.0;
    for(inWfmEvent.eventId = iStart; inWfmEvent.eventId < iStop; inWfmEvent.eventId++) {
        hdf5rawWaveformIo_read_event(inWfmFile, &inWfmEvent);
        for(iCh=0; iCh < 1 /* inWfmFile->nCh */; iCh++) {
            for(i=0; i<inWfmFile->nPt; i++) {
                val = (inWfmBuf[(size_t)(iCh * inWfmFile->nPt + i)]
                       - inWfmAttr.yoff[chGrpIdx[iCh]])
                    * inWfmAttr.ymult[chGrpIdx[iCh]]
                    + inWfmAttr.yzero[chGrpIdx[iCh]];

                fltHdl->inWav[i] = val;
            }
        }
        pulseRiseT = find_pulses(&npulse, fltHdl,
                                 pm.diffSep, pm.riseFrac, pm.fltM);
        fprintf(stderr, "eventId = %zd, npulse = %zd, first at %zd\n",
               inWfmEvent.eventId, npulse, pulseRiseT[0]);
        for(i=0; i<npulse-1; i++) {
            sep = pulseRiseT[i+1] - pulseRiseT[i];
            sepMu += sep;
            sepSigma += sep * sep;
            nSep++;
        }

        for(i=1; i<npulse-1; i++) {
            for(j=0; j<pm.sLen; j++) {
                k = pulseRiseT[i]-pm.sPre + j;
                gsl_histogram2d_increment(wav2H, j*inWfmAttr.dt, fltHdl->inWav[k]);
                gsl_histogram2d_increment(flt2H, j*inWfmAttr.dt, fltHdl->outWav[k]);
            }
        }
        free(pulseRiseT);
    }
    sepMu /= (double)nSep;    
    sepSigma = sqrt(1.0/(double)(nSep-1) * (sepSigma - nSep * sepMu * sepMu));

    printf("nSep = %zd, sepMu = %g, sepSigma = %g\n", nSep, sepMu, sepSigma);

    FILE *ofp;
    if((ofp = fopen(outFileName, "w"))==NULL) {
        perror(outFileName);
        goto Exit;
    }
    gsl_histogram2d_fprintf(ofp, wav2H, "%24.16e", "%g");
    fprintf(ofp, "\n\n");
    gsl_histogram2d_fprintf(ofp, flt2H, "%24.16e", "%g");
    fprintf(ofp, "\n\n");

    fprintf(ofp, "# baseline distribution");
    double yl, yu;
    for(i=0; i<gsl_histogram2d_ny(wav2H); i++) {
        gsl_histogram2d_get_yrange(wav2H, i, &yl, &yu);
        fprintf(ofp, "%24.16e, %g\n", yl, gsl_histogram2d_get(wav2H, 0, i));
    }
    fprintf(ofp, "\n\n");

    fprintf(ofp, "# filtered distribution");
    for(i=0; i<gsl_histogram2d_ny(flt2H); i++) {
        gsl_histogram2d_get_yrange(flt2H, i, &yl, &yu);
        fprintf(ofp, "%24.16e, %g\n", yl,
                gsl_histogram2d_get(flt2H, (pm.sPre+3*pm.diffSep)/pm.sHscale, i));
    }

    fclose(ofp);

Exit:
    free(inWfmBuf); inWfmBuf = NULL;
    gsl_histogram2d_free(wav2H);
    gsl_histogram2d_free(flt2H);
    filters_close(fltHdl);
    hdf5rawWaveformIo_close_file(inWfmFile);

    return EXIT_SUCCESS;
}
