# Newton Compiler Backend
IIB (MEng) project Newton compiler backend.

## Build Instructions
1. Install libyaml (https://github.com/yaml/libyaml) and GNU GSL (e.g. `sudo apt-get install libgsl-dev`).
2. Create config.local file in this directory, containing absolute path to this directory:

    ```WD = <absolute path to 'c_compiler' directory>```

3. Run `make` in this directory to compile C program. Executable is generated in 'build' directory.

4. Run `make` in 'verilog' directory to run C executable and synthesise verilog.
