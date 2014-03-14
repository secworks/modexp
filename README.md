rsa
===

RSA hardware implementation written i Verilog. Supports key lengths up to at least 4096 bit keys.


## Introduction ##
This implementation of the RSA public key system supports keypair
generation, encryption/decryption and signing/verification. The first
version will assume that the random numbers used are supplied.

The implementation (the core) is written in Verilog 2001. There will be
a python model and possibly a c model that matches the HW-implementation
closely.

The core will support keys of at least 4096 bits, and shorter key sizes
like 1024 and 2048 too.


## Implementation details ##

The core will perform blinding to protect against side channel
attacks. The first iteration will not to padding, but will support
padding in the second iteration.


## FPGA-results ##

No results yet.


## Status ##
***(2013-03-14)***

Very early phase. Started to collect information and drawing some rough
ideas on paper.
