# Activation Function VHDL Library

This library contains various different implementations of activation functions.
Currently working and tested implementations are of Sigmoid and TanH activation functions.

****

### Repo structure
```
ELU
Sigmoid
|    Sigmoid.vhd
|    SigmoidTop.vhd
|----Test
|    |   Testbench.vhd
|    |   env.vhd
|
TanH
|    TanH.vhd
|    TanHTop.vhd
|----Test
|    |   Testbench.vhd
|    |   env.vhd
```

****

## Synthesis reports

Synthesized for Cyclone 10 GX family FPGAs

### Sigmoid
Synthesis was performed on 16 bit implementation with 12 fractional bits

|Synthesis reports| PLAN | PLAN pipelined|
|:--- |:--- |:--- |
|LUTs (Registers) | 46 (34) | 48 (54) | 
|FMax | 246 MHz |  444 MHz |

### TanH

Synthesis was performed on 16 bit implementation with 12 fractional bits

|Synthesis reports| PlaTanH | PlaTanH pipelined|
|:--- |:--- |:--- |
|LUTs (Registers) | 86 (34) | 102 (61) | 
|FMax | 195 MHz |  305 MHz |
