#!/usr/bin/env python
# -*- coding: utf-8 -*-

## @package fungen_ctrl
# Control the function generator
#

from __future__ import print_function
import time
import os
import sys
import shutil
import math
# use either usbtmc or NI Visa
try:
    import usbtmc
except:
    import visa

## Rigol DG1022
class DG1022(object):

    ## @var handle to instrument
    _instr = None

    ## Initialization
    def __init__(self):
        try:
            rm = visa.ResourceManager()
            rm.list_resources()                 # list available instruments
            self._instr = rm.open_resource('USB0::0x1AB1::0x0588::DG1D131402088::INSTR')
        except:
            self._instr = usbtmc.Instrument(0x1ab1, 0x0588) # RIGOL TECHNOLOGIES,DG1022 ,DG1D131402088
            self._instr.timeout = 10

    ## Generate tail-pulse and write into instrument's memory
    # @param xp number of samples before the edge
    # @param np total number of samples for the pulse
    # @param alpha exp-decay coefficient in exp(-alpha * (i - xp))
    def setup_tail_pulse(self, freq=100, xp=16, np=1024, alpha=0.01):
        self._instr.write("FUNC USER")
        time.sleep(0.5)
        self._instr.write("FREQ %g" % freq)
        time.sleep(0.5)

        amax = 16383
        vals=[0 for i in xrange(np)]
        for i in xrange(np):
            if i<xp:
                vals[i] = amax
            else:
                vals[i] = int(amax*(1-math.exp(-(i-xp)*alpha)))
        string = "DATA:DAC VOLATILE"
        for i in xrange(np):
            string += (",%d"% vals[i])
        self._instr.write(string)
        time.sleep(1.0)
        self._instr.write("FUNC:USER VOLATILE")
        time.sleep(0.5)

    def set_frequency(self, freq=100.0):
        self._instr.write("FREQ %g" % freq)
        time.sleep(0.5)

    def set_voltage(self, vLow=0.0, vHigh=1.0):
        self._instr.write("VOLT:UNIT VPP")
        time.sleep(0.5)
        self._instr.write("VOLTage:LOW %g" % vLow)
        time.sleep(0.5)
        self._instr.write("VOLTage:HIGH %g" % vHigh)
        time.sleep(0.5)

    def turn_on_output(self):
        self._instr.write("OUTP:LOAD 50")
        time.sleep(0.5)
        self._instr.write("OUTP ON")
        time.sleep(0.5)

    def close(self):
        self._instr.close()

if __name__ == "__main__":

    fg = DG1022()
    fg.set_voltage(0.0, 0.1)
    fg.setup_tail_pulse(100, 64, 1024, 0.01)
    fg.turn_on_output()
    fg.close()
