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


void small_e_256_mod(void) {
  printf("=== Simple test with small, implicit e ===\n");
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

void small_e_256_mod2(void) {
  printf("=== Simple test with explicit e ===\n");
  uint32_t X[] = {0x00000000, 0xbd589a51, 0x2ba97013,
                  0xc4736649, 0xe233fd5c, 0x39fcc5e5,
                  0x2d60b324, 0x1112f2d0, 0x1177c62b};
  uint32_t E[] = {0x00010001};

  uint32_t M[] = {0x00000000, 0xf169d36e, 0xbe2ce61d,
                   0xc2e87809, 0x4fed15c3, 0x7c70eac5,
                   0xa123e643, 0x299b36d2, 0x788e583b };

  uint32_t expected[] = {0x00000000, 0x7c5f0fee, 0x73028fc5,
                         0xc4fe57c4, 0x91a6f5be, 0x33a5c174,
                         0x2d2c2bcd, 0xda80e7d6, 0xfb4c889f};

  uint32_t Z[] = {0x00000000, 0x00000000, 0x00000000,
                  0x00000000, 0x00000000, 0x00000000,
                  0x00000000, 0x00000000, 0x00000000};

  mod_exp_array2(1, 9, X, E, M, Z);
  assertArrayEquals(9, expected, Z);
}


void simple_tests(void) {
  simple_3_7_11();
  simple_251_251_257();
  small_e_256_mod();
  small_e_256_mod2();
}

//======================================================================
// EOF simple_tests.h
//======================================================================
