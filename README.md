# TMIIaTest
Topmetal-IIa test control firmware/software and analysis
# Set KC705's ipaddress(192.168.2.x)
SW11 on KC705 board controls the value of x 
SW11: 1 2 3 4
      0 0 1 1 <- default(192.168.2.3)
      0 0 0 1 <- 192.168.2.1
      0 1 0 0 <- 192.168.2.4
      ...
Check sr_ctrl.py:
```
    #ipaddrss of KC705, x can be changed according to the SW11's value   
    host = '192.168.2.x' 
```             
