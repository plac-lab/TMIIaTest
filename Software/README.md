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
