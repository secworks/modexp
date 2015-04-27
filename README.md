modexp
======

Modular exponentiation core for implementing public key algorithms such
as RSA, DH, ElGamal etc.

The core calculates the following function:

  C = M ** e mod N

  M is a message with a length of n bits
  e is the exponent with a length of m bits
  N is the modulus  with a length of n bits

The size n be one and up to and including 8192 bits in steps of 32
bits.

The size m be one and up to and including 8192 bits in steps of 32
bits.

The core has a 32-bit memory like interface, but provides status signals
to inform the system that a given operation has is done. Additionally,
any errors will also be asserted.

The core is written in Verilog 2001 and suitable for implementation in
FPGA and ASIC devices. No vendor specific macros are used in the code.


## Implementation details ##

The core is iterative with 32-bit operands and not the fastest core on
the planet.


## Future developments ##

- The core will perform blinding to protect against side channel
  attacks.

- Increased operands to 64-, 128-, or possibly even 256 bits for
  increased performance.


## FPGA-results ##

## Altera Cyclone-V ###

- 203 registers
- 387 ALMs
- 106496 block memory bits
- 107 MHz


### Xilinx Artix-7 100T ###

- 160 registers
- 565 LUTs
- 13 RAMB18E1 block memories
- 160 MHz

### Xilinx Spartan-6 LX45 ###

- 169 registers
- 589 LUTs
- 13 RAMB8BWER block memories
- 136 MHz


## Status ##

***(2015-04-27)***

Modexp simulation with exponent and modolus with up to 1280 bits
simulates. The auto test generation system works. Implementation in
different FPGA types and vendors works.


***(2015-04-23)***

The Montgomery multiplication module works. The Residue calculation
module works. Top level integration and debugging is onging. The core
does not yet work and there are dragons to be found.


***(2014-12-07)***

Renamed the core tom modexp from rsa to make it more clear that it
provides generic modular exponentiation, not RSA.


***(2014-10-01)***

Very early phase. Started to collect information and drawing some rough
ideas on paper.
