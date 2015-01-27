modexp
======

Modular exponentiation core for implementing public key algorithms such
as RSA, DH, ElGamal etc.

The core calculates the following function:

  C = M ** e mod N

  M is a message with a length of n bits
  e is the exponent with a length of at most 32 bits
  N is the modulus  with a length of n bits
  n is can be 32 and up to and including 8192 bits in steps
  of 32 bits.

The core has a 32-bit memory like interface, but provides status signals
to inform the system that a given operation has is done. Additionally,
any errors will also be asserted.

The core is written in Verilog 2001 and suitable for implementation in
FPGA and ASIC devices. No vendor specific macros are used in the code.


## Implementation details ##

The core is iterative and will not be the fastest core on the
planet. The core will perform blinding to protect against side channel
attacks.


## FPGA-results ##

No results yet.


## Status ##

***(2014-12-07)***

Renamed the core tom modexp from rsa to make it more clear that it
provides generic modular exponentiation, not RSA.


***(2014-10-01)***

Very early phase. Started to collect information and drawing some rough
ideas on paper.
