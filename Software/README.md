# Compile `command.{h,c}` for use in python
```
    python setup.py build
```
A file will be generated under `./build` such as
```
    build/lib.freebsd-11.0-STABLE-amd64-2.7/command.so
```
The sub-directory name in front of `command.so` will differ
depending on the operating system and software version.

Please `cd` into `./build` and make a symbolic link

```
    cd build
    ln -s lib.freebsd-11.0-STABLE-amd64-2.7/command.so .
    cd ..
```
In this way the file `command.py` won't need modification.
It eliminates potential conflicts with git which is tracking
the file.

# Programming (software) interface for controlling the FPGA firmware

The FPGA firmware interacts with computer software by exchanging byte streams via gigabit ethernet connection.  The software should send appropriate command strings compiled by corresponding methods in command.py to set register/pulse/memory etc. values implemented in a control_interface firmware module.  control_interface module could send data back to the software via ethernet as well.  The software interacts with the control_interface only.  All special purpose modules that implement specific functions are connected to and controlled by the control_interface.  They receive parametric settings through regsiters and initiate actions upon receiving pulses sent by the control_interface.

The following section documents the configuration and pulse registeres each module is connected to.  The user should send appropriate commands to set each module into action.  Example python scripts are provided.

## TMIIa shift register write/read
* Action initiated by `pulse_reg(0)`.
* Value to be sent out should be written to `config_reg[NBits-1:0]`
* Value read back will be present at `status_reg[Nbits-1:0]` when `status_reg[Nbits]=='1'` indicating the value is valid.

## TMIIa analog scan
* Action (restart) initiated by `pulse_reg(2)`

### Register map
```
config_reg[239:224] : TRIGGER_RATE 
config_reg[223:208] : TRIGGER_DELAY
config_reg[207:192] : STOP_ADDR   # When MSB = '1', the scan will stop at pixel # STOP_ADDR[14:0]
config_reg[185]     : STOP_CLK_S  # 1: TM_CLK_S stops running, 0: TM_CLK_S keeps running 
config_reg[184]     : KEEP_WE     # 1: SRAM_WE stays high in writing mode, 0: SRAM_WE is quadrature lagging to TM_CLK_S
config_reg[183:180] : WR_CLK_DIV  # SRAM write clock frequency is 100MHz/2**WR_CLK_DIV
config_reg[179:176] : CLK_DIV     # Scan clock frequency is 100MHz/2**CLK_DIV
```

### Set up data for SRAM 

Function tm_sram_config() writes a list of SRAM values (4-bit per element) passed to the function into a BRAM internal to FPGA.  Upon an initialization pulse, the module writes every element to its corresponding pixel in Topmetal, then enters the normal array scan. 

```
## for TMIIa  ROW = 45, COLUMN = 216.
len(data_to_sram) = ROW*COLUMN  
data_to_sram      = [pixel_0, pixel_1, pixel_2,...,pixel_n]
```

## DAC8568
* Action initiated by `pulse_reg(1)`
* config_reg(16) (LSB of register 1) selects one of the two DACs to write to
* Each pulse registers a 16-bit word set by `config_reg[15:0]`.  Two consecutive 16-bit words are concatenated to form a 32-bit word which is then sent to the DAC. 

# Analysis
Need [gsl](https://www.gnu.org/software/gsl/) to compile and [gnuplot](http://www.gnuplot.info/) to plot results.

## ENC using injected tail-pulses
```
$ ./pulserENC
Usage:
      -r rise time in samples[150]
      -f riseFrac[0.5]
      -m fltM[-1]
      -p sPre[1000]
      -l sLen[4000]
      -s iStart[0] -e iStop[-1] starting and stopping(+1) eventid
      inFileName(.h5) outFileName
```
Input file should contain one channel (trace) of CSA response to injected tail-pulses.  The output file which contains histogram data can be plotted using `TMS1mmSingleCSAOut1ENC.gp`

