/*
 * bignum_uint32_t.h
 *
 *  Created on: Mar 5, 2015
 *      Author: psjm
 */

#ifndef BIGNUM_UINT32_T_H_
#define BIGNUM_UINT32_T_H_

void modulus_array(int length, uint32_t *a, uint32_t *modulus, uint32_t *temp,
		uint32_t *reminder);
int greater_than_array(int length, uint32_t *a, uint32_t *b);
void add_array(int length, uint32_t *a, uint32_t *b, uint32_t *result);
void sub_array(int length, uint32_t *a, uint32_t *b, uint32_t *result);
void shift_right_1_array(int length, uint32_t *a, uint32_t *result);
void shift_left_1_array(int length, uint32_t *a, uint32_t *result);
void zero_array(int length, uint32_t *a);
void copy_array(int length, uint32_t *src, uint32_t *dst);
void debugArray(char *msg, int length, uint32_t *array);

#endif /* BIGNUM_UINT32_T_H_ */
