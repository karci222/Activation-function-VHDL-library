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

### Sigmoid
Synthesis was performed on 16 bit implementation with 12 fractional bits

|Synthesis reports| PLAN | PLAN pipelined|
|:--- |:--- |:--- |
|LUTs |   | |
|FMax |   | |
