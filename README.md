# Laplace Filter in ARMv8-A (AArch64) Assembly
These are the results of a 3 person group project which was part of one of my university courses. The `Aufgabenstellung` and `Ausarbeitung` PDFs are the task description provided by the university and a detailed report/rundown of our solution respectively (both in German language).

## Problem Description
The goal of the project was to implement a Laplace Filter, an imaging processing algorithm which highlights edges, in Assembly language. Additionally, we were to try and optimized the suggested formula/algorithm by mathematical/logical means as well as using SIMD instead of regular registers in the Assembly code and benchmark the results.

The target Hardware was the Raspberry Pi 3 running on a university cluster. The I/O format are bmp files.

## Using the Program
The program consists of 3 parts which can be found in the `Implementierung` directory.
- `laplace.c`: The wrapper program written in C. It contains the main-method and handles I/O operations.
- `laplace.S`: The regular implementation of the Laplace filter in Assembly.
- `simd.S`: The alternative Assembly version using SIMD registers.

>All three can be complied using the provided Makefile.

By default, the program uses the SIMD version. Additionally, there is also a benchmark mode in which each implementation is run a given number of times (A single run might be too short to tell a difference for small pictures) and returns a benchmark using GNU's CLOCK_MONOTONIC. The result picture is placed in the same directory as the input as out.bmp.

The following parameters are used to run the program:
- (mandatory) The first parameter must be the `path to the input .bmp file`. Alternatively, the first parameter can be a `-h` or `--help` flag to output these instructions.
- (optional) give a `-b` flag to run the program in benchmark mode.
- (required in benchmark mode) The number of iterations each algorithm should be run (int).

This means correct calls of the program can look like this:
```shellscript
./ laplace path {-b iterations}
```
```shellscript
./ laplace -h
```
```shellscript
./ laplace -- help
```

## My contribution
I was responsible coding the SIMD implementation and writing the report as well as some bugfixing on the other parts.
