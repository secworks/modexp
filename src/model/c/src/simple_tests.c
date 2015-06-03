//======================================================================
//
// simple_tests.h
// --------------
// Header fil to export the simple tests of the modexp C model.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2015, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//======================================================================

#include <stdio.h>
#include <stdlib.h>
#include "montgomery_array.h"
#include "bignum_uint32_t.h"

void simple_3_7_11(void) {
  printf("=== Simple test with X = 3, E = 7 and M = 11 ===\n");
  uint32_t X[] = { 0x3 };
  uint32_t E[] = { 0x7 };
  uint32_t M[] = { 0xb };
  uint32_t expected[] = { 0x9 };
  uint32_t Z[] = { 0x00000000 };
  mod_exp_array(1, X, E, M, Z);
  assertArrayEquals(1, expected, Z);
}

void simple_251_251_257(void) {
  printf("=== Simple test with X = 251, E = 251 and M = 257 ===\n");
  uint32_t X[] = { 0xfb };
  uint32_t E[] = { 0xfb };
  uint32_t M[] = { 0x101 };
  uint32_t expected[] = { 0xb7 };
  uint32_t Z[] = { 0x00000000 };
  mod_exp_array(1, X, E, M, Z);
  assertArrayEquals(1, expected, Z);
}


void bigger_test(void)
{
  printf("=== Bigger test with 128 bit operands.\n");
  uint32_t exponent[] = {0x3285c343, 0x2acbcb0f, 0x4d023228, 0x2ecc73db};
  uint32_t modulus[]  = {0x267d2f2e, 0x51c216a7, 0xda752ead, 0x48d22d89};
  uint32_t message[]  = {0x29462882, 0x12caa2d5, 0xb80e1c66, 0x1006807f};
  uint32_t expected[] = {0x0ddc404d, 0x91600596, 0x7425a8d8, 0xa066ca56};
  uint32_t result[]   = {0x00000000, 0x00000000, 0x00000000, 0x00000000};

  mod_exp_array(4, message, exponent, modulus, result);
  assertArrayEquals(4, expected, result);
}


void small_e_64_mod(void)
{
  printf("=== Simple test with small e and 64 bit modulus  ===\n");
  uint32_t X[] = { 0x00000000, 0xdb5a7e09, 0x86b98bfb };
  uint32_t E[] = { 0x00000000, 0x00000000, 0x00010001 };
  uint32_t M[] = { 0x00000000, 0xb3164743, 0xe1de267d };
  uint32_t expected[] = { 0x00000000, 0x9fc7f328, 0x3ba0ae18 };
  uint32_t Z[] = { 0x00000000, 0x00000000, 0x00000000 };
  mod_exp_array(3, X, E, M, Z);
  assertArrayEquals(3, expected, Z);
}

void small_e_256_mod(void) {
  printf("=== Simple test with small e and 256 bit modulus  ===\n");
  uint32_t X[] = {0x00000000, 0xbd589a51, 0x2ba97013,
                  0xc4736649, 0xe233fd5c, 0x39fcc5e5,
                  0x2d60b324, 0x1112f2d0, 0x1177c62b};
  uint32_t E[] = {0x00000000, 0x00000000, 0x00000000,
                  0x00000000, 0x00000000, 0x00000000,
                  0x00000000, 0x00000000, 0x00010001};

  uint32_t M[] = {0x00000000, 0xf169d36e, 0xbe2ce61d,
                   0xc2e87809, 0x4fed15c3, 0x7c70eac5,
                   0xa123e643, 0x299b36d2, 0x788e583b };

  uint32_t expected[] = {0x00000000, 0x7c5f0fee, 0x73028fc5,
                         0xc4fe57c4, 0x91a6f5be, 0x33a5c174,
                         0x2d2c2bcd, 0xda80e7d6, 0xfb4c889f};

  uint32_t Z[] = {0x00000000, 0x00000000, 0x00000000,
                  0x00000000, 0x00000000, 0x00000000,
                  0x00000000, 0x00000000, 0x00000000};

  mod_exp_array(9, X, E, M, Z);
  assertArrayEquals(9, expected, Z);
}

void rob_dec_1024(void)
{
  uint32_t exponent[] = {0x00000000, 0x3ff26c9e, 0x32685b93, 0x66570228, 0xf0603c4e,
                         0x04a717c1, 0x8038b116, 0xeb48325e, 0xcada992a,
                         0x920bb241, 0x5aee4afe, 0xe2a37e87, 0xb35b9519,
                         0xb335775d, 0x989553e9, 0x1326f46e, 0x2cdf6b7b,
                         0x84aabfa9, 0xef24c600, 0xb56872ad, 0x5edb9041,
                         0xe8ecd7f8, 0x535133fb, 0xdefc92c7, 0x42384226,
                         0x7d40e5f5, 0xc91bd745, 0x9578e460, 0xfc858374,
                         0x3172bed3, 0x73b6957c, 0xc0d6a68e, 0x33156a61};


  uint32_t modulus[] = {0x00000000, 0xd075ec0a, 0x95048ef8, 0xcaa69073, 0x8d9d58e9,
                        0x1764b437, 0x50b58cad, 0x8a6e3199, 0x135f80ee,
                        0x84eb2bde, 0x58d38ee3, 0x5825e91e, 0xafdeb1ba,
                        0xa15a160b, 0x0057c47c, 0xc7765e31, 0x868a3e15,
                        0x5ee57cef, 0xb008c4dd, 0x6a0a89ee, 0x98a4ee9c,
                        0x971a07de, 0x61e5b0d3, 0xcf70e1cd, 0xc6a0de5b,
                        0x451f2fb9, 0xdb995196, 0x9f2f884b, 0x4b09749a,
                        0xe6c4ddbe, 0x7ee61f79, 0x265c6adf, 0xb16b3015};


  uint32_t message[] = {0x00000000, 0x0001ffff, 0xffffffff, 0xffffffff, 0xffffffff,
                        0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
                        0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
                        0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
                        0xffffffff, 0xffffffff, 0xffffffff, 0x00303130,
                        0x0d060960, 0x86480165, 0x03040201, 0x05000420,
                        0x8e36fc9a, 0xa31724c3, 0x2416263c, 0x0366a175,
                        0xfabbb92b, 0x741ca649, 0x6107074d, 0x0343b597};


  uint32_t expected[] = {0x00000000, 0x06339a64, 0x367db02a, 0xf41158cc, 0x95e76049,
                         0x4519c165, 0x111184be, 0xe41d8ee2, 0x2ae5f5d1,
                         0x1da7f962, 0xac93ac88, 0x915eee13, 0xa3350c22,
                         0xf0dfa62e, 0xfdfc2b62, 0x29f26e27, 0xbebdc84e,
                         0x4746df79, 0x7b387ad2, 0x13423c9f, 0x98e8a146,
                         0xff486b6c, 0x1a85414e, 0x73117121, 0xb700e547,
                         0xab4e07b2, 0x21b988b8, 0x24dd77c2, 0x046b0a20,
                         0xcddb986a, 0xac75c2f2, 0xb044ed59, 0xea565879};


  uint32_t target[] = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000};

  printf("=== 1024 bit decipher/sign test from Robs RSA code. ===\n");

  mod_exp_array(33, message, exponent, modulus, target);
  assertArrayEquals(33, expected, target);
}


void rob_enc_1024(void)
{
  uint32_t exponent[] = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                         0x00000000, 0x00000000, 0x00000000, 0x00000000,
                         0x00000000, 0x00000000, 0x00000000, 0x00000000,
                         0x00000000, 0x00000000, 0x00000000, 0x00000000,
                         0x00000000, 0x00000000, 0x00000000, 0x00000000,
                         0x00000000, 0x00000000, 0x00000000, 0x00000000,
                         0x00000000, 0x00000000, 0x00000000, 0x00000000,
                         0x00000000, 0x00000000, 0x00000000, 0x00010001};


  uint32_t modulus[] = {0x00000000, 0xd075ec0a, 0x95048ef8, 0xcaa69073, 0x8d9d58e9,
                        0x1764b437, 0x50b58cad, 0x8a6e3199, 0x135f80ee,
                        0x84eb2bde, 0x58d38ee3, 0x5825e91e, 0xafdeb1ba,
                        0xa15a160b, 0x0057c47c, 0xc7765e31, 0x868a3e15,
                        0x5ee57cef, 0xb008c4dd, 0x6a0a89ee, 0x98a4ee9c,
                        0x971a07de, 0x61e5b0d3, 0xcf70e1cd, 0xc6a0de5b,
                        0x451f2fb9, 0xdb995196, 0x9f2f884b, 0x4b09749a,
                        0xe6c4ddbe, 0x7ee61f79, 0x265c6adf, 0xb16b3015};


  uint32_t message[] = {0x00000000, 0x0001ffff, 0xffffffff, 0xffffffff, 0xffffffff,
                        0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
                        0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
                        0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
                        0xffffffff, 0xffffffff, 0xffffffff, 0x00303130,
                        0x0d060960, 0x86480165, 0x03040201, 0x05000420,
                        0x8e36fc9a, 0xa31724c3, 0x2416263c, 0x0366a175,
                        0xfabbb92b, 0x741ca649, 0x6107074d, 0x0343b597};


  uint32_t expected[] = {0x00000000, 0x06339a64, 0x367db02a, 0xf41158cc, 0x95e76049,
                         0x4519c165, 0x111184be, 0xe41d8ee2, 0x2ae5f5d1,
                         0x1da7f962, 0xac93ac88, 0x915eee13, 0xa3350c22,
                         0xf0dfa62e, 0xfdfc2b62, 0x29f26e27, 0xbebdc84e,
                         0x4746df79, 0x7b387ad2, 0x13423c9f, 0x98e8a146,
                         0xff486b6c, 0x1a85414e, 0x73117121, 0xb700e547,
                         0xab4e07b2, 0x21b988b8, 0x24dd77c2, 0x046b0a20,
                         0xcddb986a, 0xac75c2f2, 0xb044ed59, 0xea565879};


  uint32_t target[] = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000,
                       0x00000000, 0x00000000, 0x00000000, 0x00000000};

  printf("=== 1024 bit encipher/verify test from Robs RSA code. ===\n");

  mod_exp_array(33, expected, exponent, modulus, target);
  assertArrayEquals(33, message, target);
}


void simple_tests(void) {
//  simple_3_7_11();
//  simple_251_251_257();
//  bigger_test();
//  small_e_256_mod();
//  small_e_64_mod();
  rob_enc_1024();
  rob_dec_1024();
  //  small_e_256_mod2();
}

//======================================================================
// EOF simple_tests.c
//======================================================================
