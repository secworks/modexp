/*
 * bignum_uint32_t.h
 *
 *  Created on: Mar 5, 2015
 *      Author: psjm
 */

#ifndef BIGNUM_UINT32_T_H_
#define BIGNUM_UINT32_T_H_

void modulus_array(uint32_t length, uint32_t *a, uint32_t *modulus, uint32_t *temp,
		uint32_t *reminder);
int greater_than_array(uint32_t length, uint32_t *a, uint32_t *b);
void add_array(uint32_t length, uint32_t *a, uint32_t *b, uint32_t *result);
void sub_array(uint32_t length, uint32_t *a, uint32_t *b, uint32_t *result);
void shift_right_1_array(uint32_t length, uint32_t *a, uint32_t *result);
void shift_left_1_array(uint32_t length, uint32_t *a, uint32_t *result);
void zero_array(uint32_t length, uint32_t *a);
void copy_array(uint32_t length, uint32_t *src, uint32_t *dst);
void debugArray(char *msg, uint32_t length, uint32_t *array);
void assertArrayEquals(uint32_t length, uint32_t *expected, uint32_t *actual);
void print_assert_array_stats(void);

#endif /* BIGNUM_UINT32_T_H_ */
