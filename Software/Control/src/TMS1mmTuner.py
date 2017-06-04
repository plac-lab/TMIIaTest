#!/usr/bin/env python
# -*- coding: utf-8 -*-

## @package TMS1mmTuner
# Human interface for tuning the Topmetal-S 1mm version chip
#

from __future__ import print_function
import Tkinter as tk
import threading
import math,sys,time,os,shutil
import socket
from command import *
import TMS1mmSingle

class CommonData(object):

    def __init__(self, tms1mmReg):
        # number of voltages to control
        self.nVolts = 7
        # update time interval (second)
        self.tI = 0.5

        self.cv = threading.Condition() # condition variable
        self.quit = False
        self.vUpdated = False

        self.voltsNames = ['VBIASN', 'VBIASP', 'VCASN', 'VCASP', 'VDIS', 'VREF', 'DAC_BufferX2_VREF']
        self.inputVs = [1.38, 1.55, 1.45, 1.35, 1.58, 2.68, 1.2]
        self.inputVcodes = [0 for i in xrange(self.nVolts)]

        self.voltsOutput = [0.0 for i in xrange(self.nVolts)]
        self.inputIs = [0.0 for i in xrange(self.nVolts)]

        self.tms1mmReg = tms1mmReg

class ControlPanelGUI(object):

    def __init__(self, master, cd):
        self.master = master
        self.cd = cd
        self.nVolts = cd.nVolts

        # appropriate quitting
        master.wm_protocol("WM_DELETE_WINDOW", self.quit)

        # frame for controls
        self.voltagesFrame = tk.Frame(master)
        self.voltagesFrame.pack(side=tk.TOP)

        # GUI widgets    
        self.voltsNameLabels =  [tk.Label(self.voltagesFrame, text=self.cd.voltsNames[i])
                             for i in xrange(self.nVolts)]
        self.voltsILabels = [tk.Label(self.voltagesFrame, font="Courier 10", text="0.0 A")
                             for i in xrange(self.nVolts)]

        self.voltsOutputLabels = [tk.Label(self.voltagesFrame, font="Courier 10", text="0.0 V")
                                  for i in xrange(self.nVolts)]

        self.voltsSetVars = [tk.DoubleVar() for i in xrange(self.nVolts)]
        for i in xrange(self.nVolts):
            self.voltsSetVars[i].set(self.cd.inputVs[i])
        self.voltsSetEntries = [tk.Spinbox(self.voltagesFrame, width=8, justify=tk.RIGHT,
                                           textvariable=self.voltsSetVars[i],
                                           from_=0.0, to=3.3, increment=0.001,
                                           command=self.set_voltage_update)
                                for i in xrange(self.nVolts)]
        for v in self.voltsSetEntries:
            v.bind('<Return>', self.set_voltage_update)

        self.voltsSetCodeVars = [tk.IntVar() for i in xrange(self.nVolts)]
        self.voltsSetCodeEntries = [tk.Spinbox(self.voltagesFrame, width=8, justify=tk.RIGHT,
                                               textvariable=self.voltsSetCodeVars[i],
                                               from_=0, to=65535, increment=1,
                                               command=self.set_voltage_dac_code_update)
                                    for i in xrange(self.nVolts)]
        for v in self.voltsSetCodeEntries:
            v.bind('<Return>', self.set_voltage_dac_code_update)

        # caption    
        tk.Label(self.voltagesFrame, text="Name", width=15,
                 fg="white", bg="black").grid(row=0, column=0)
        tk.Label(self.voltagesFrame, text="Set Voltage [V]", width=20,
                 fg="white", bg="black").grid(row=0, column=1)
        tk.Label(self.voltagesFrame, text="Set Volt DAC code", width=20,
                 fg="white", bg="black").grid(row=0, column=2)        
        tk.Label(self.voltagesFrame, text="Measured Voltage [V]",
                 fg="white", bg="black").grid(row=0, column=3)

        # placing widgets        
        for i in xrange(self.nVolts):
            self.voltsNameLabels[i].grid(row=i+1,column=0)
            self.voltsSetEntries[i].grid(row=i+1, column=1)
            self.voltsSetCodeEntries[i].grid(row=i+1, column=2)
            self.voltsOutputLabels[i].grid(row=i+1, column=3)

        # self-updating functions
        self.update_values_display()

    def quit(self):
        with self.cd.cv:
            self.cd.quit = True
            self.cd.cv.notify()
        self.master.destroy()

    def update_values_display(self):
        for i in xrange(self.nVolts):
            self.voltsILabels[i].configure(text="% 7.3f" % self.cd.inputIs[i])
            self.voltsOutputLabels[i].configure(text="% 7.3f" % self.cd.voltsOutput[i])
        self.master.after(int(1000*self.cd.tI), self.update_values_display)

    def set_voltage_update(self, *args):
        with self.cd.cv:
            for i in xrange(self.nVolts):
                self.cd.inputVs[i] = self.voltsSetVars[i].get()
                self.cd.inputVcodes[i] = self.cd.tms1mmReg.dac_volt2code(self.cd.inputVs[i])
                self.voltsSetCodeVars[i].set(self.cd.inputVcodes[i])
            self.cd.vUpdated = True
            print(self.cd.inputVs)
            print(self.cd.inputVcodes)
        return True

    def set_voltage_dac_code_update(self, *args):
        with self.cd.cv:
            for i in xrange(self.nVolts):
                self.cd.inputVcodes[i] = self.voltsSetCodeVars[i].get()
                self.cd.inputVs[i] = self.cd.tms1mmReg.dac_code2volt(self.cd.inputVcodes[i])
                self.voltsSetVars[i].set(self.cd.inputVs[i])
            self.cd.vUpdated = True
            print(self.cd.inputVcodes)
        return True

class TMS1mmConfig(threading.Thread):
    # Do not try to access tk.IntVar etc. here.  Since after
    # master.destroy(), those variables associated with tk seem to be
    # destroyed as well and accessing them would result in this thread
    # to hang.
    
    def __init__(self, cd, s):
        threading.Thread.__init__(self)
        self.cd = cd
        self.s = s
        self.cmd = Cmd()
        self.dac8568 = TMS1mmSingle.DAC8568(self.cmd)
        self.tms1mmReg = cd.tms1mmReg

    def run(self):
        with self.cd.cv:
            while not self.cd.quit:
                self.cd.cv.wait(self.cd.tI)
                if self.cd.vUpdated:
                    self.set_voltage_outputs()
                    self.cd.vUpdated = False
                self.get_inputs()

    def set_voltage_outputs(self):
        x2gain = 2
        bufferTest = True
        sdmTest = True

        self.tms1mmReg.set_power_down(0, 0)
        self.tms1mmReg.set_power_down(3, 0)

        if bufferTest:
            self.tms1mmReg.set_k(0, 0) # 0 - K1 is open, disconnect CSA output
            self.tms1mmReg.set_k(1, 1) # 1 - K2 is closed, allow BufferX2_testIN to inject signal
            self.tms1mmReg.set_k(4, 0) # 0 - K5 is open, disconnect SDM loads
            self.tms1mmReg.set_k(6, 1) # 1 - K7 is closed, BufferX2 output to AOUT_BufferX2
        if x2gain == 2:
            self.tms1mmReg.set_k(2, 1) # 1 - K3 is closed, K4 is open, setting gain to X2
            self.tms1mmReg.set_k(3, 0)
        else:
            self.tms1mmReg.set_k(2, 0)
            self.tms1mmReg.set_k(3, 1)
        if sdmTest:
            self.tms1mmReg.set_k(4, 0)
            self.tms1mmReg.set_k(5, 1)
        else:
            self.tms1mmReg.set_k(5, 0)

        s.sendall(dac8568.turn_on_2V5_ref())
        s.sendall(dac8568.set_voltage(7, 1.65)) # DAC_CH8 -> Ref2 1.65V

        self.tms1mmReg.set_k(6, 1) # 1 - K7 is closed, BufferX2 output to AOUT_BufferX2
        self.tms1mmReg.set_k(7, 1) # 1 - K8 is closed, connect CSA out to AOUT1_CSA
        self.tms1mmReg.set_dac(0, self.cd.inputVcodes[0]) # VBIASN
        s.sendall(dac8568.set_voltage(0, self.cd.inputVs[0]))
        self.tms1mmReg.set_dac(1, self.cd.inputVcodes[1]) # VBIASP
        s.sendall(dac8568.set_voltage(1, self.cd.inputVs[1]))
        self.tms1mmReg.set_dac(2, self.cd.inputVcodes[2]) # VCASN
        s.sendall(dac8568.set_voltage(2, self.cd.inputVs[2]))
        self.tms1mmReg.set_dac(3, self.cd.inputVcodes[3]) # VCASP
        s.sendall(dac8568.set_voltage(3, self.cd.inputVs[3]))
        self.tms1mmReg.set_dac(4, self.cd.inputVcodes[4]) # VDIS
        s.sendall(dac8568.set_voltage(4, self.cd.inputVs[4]))
        self.tms1mmReg.set_dac(5, self.cd.inputVcodes[5]) # VREF
        s.sendall(dac8568.set_voltage(5, self.cd.inputVs[5]))
        #
        s.sendall(dac8568.set_voltage(6, self.cd.inputVs[6])) # DAC_BufferX2_VREF

        data_to_send = self.tms1mmReg.get_config_vector()
        print("Sent:   0x%0x" % (data_to_send))
        div=7
        TMS1mmSingle.shift_register_rw(self.s, (data_to_send), div)

    def get_inputs(self):
        return
        
if __name__ == "__main__":

    host = '192.168.2.3'
    port = 1024
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((host,port))

    cmd = Cmd()
    dac8568 = TMS1mmSingle.DAC8568(cmd)
    s.sendall(dac8568.turn_on_2V5_ref())
    s.sendall(dac8568.set_voltage(6, 1.2))

    # enable/disable SDM clock
    s.sendall(cmd.write_register(9, 0x02))

    root = tk.Tk()
    root.wm_title("Topmetal-S 1mm version Tuner")

    cd = CommonData(TMS1mmSingle.TMS1mmReg())
    tms1mmConfig = TMS1mmConfig(cd, s)

    controlPanel = ControlPanelGUI(root, cd)
    tms1mmConfig.start()
    root.mainloop()
    tms1mmConfig.join()

    s.close()
