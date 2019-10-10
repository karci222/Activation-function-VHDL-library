# Activation Function VHDL Library

This library contains various different implementations of activation functions.
Currently working and tested implementations are of Sigmoid and TanH activation functions.


Current structure is following:
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

