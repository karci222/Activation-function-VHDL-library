# Activation Function VHDL Library

This library contains various different implementations of activation functions.
Currently working and tested implementations are of Sigmoid and TanH activation functions.

****

The library currently implements TanH and Sigmoid activation functions, using a so-called PLAN and PLATANH methods. They are
proposed in following works:

* PLAN https://digital-library.theiet.org/content/journals/10.1049/ip-cds_19971587
* PLATanH Proposed in https://ieeexplore.ieee.org/abstract/document/8050805

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
