# Generate the project after git clone:
Make sure there are following lines in config/project.tcl:
```
    # Create project
    create_project top ./
```
then
``` 
    mkdir top; cd top/
    vivado -mode tcl -source ../config/project.tcl
# open GUI
    start_gui
# start synthesis
    launch_runs synth_1 -jobs 8
# start implementation
    launch_runs -jobs 8 impl_1 -to_step write_bitstream
# or do everything in tcl terminal
    open_project /path/to/example.xpr
    launch_runs -jobs 8 impl_1 -to_step write_bitstream
    wait_on_run impl_1
    exit
```

# Set KC705's ip address(192.168.2.x)
```
SW11 on KC705 board controls the value of x 
SW11: 1 2 3 4
      0 0 1 1 <- default(192.168.2.3)
      0 0 0 1 <- 192.168.2.1
      0 1 0 0 <- 192.168.2.4
      ...
```
# Set KCU105's ip address(192.168.2.x)
```
SW12 on KCU105 board controls the value of x
SW12: 1 2 3 4
      0 0 1 1 <- default(192.168.2.3)
      0 0 0 1 <- 192.168.2.1
      0 1 0 0 <- 192.168.2.4
      ...
```      
Check sr_ctrl.py:
```
    # x has to match the ip set by SW11 on KC705 or SW12 on KCU105
    host = '192.168.2.x' 
```

