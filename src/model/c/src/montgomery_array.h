/*
 * montgomery_array.h
 *
 *  Created on: Mar 3, 2015
 *      Author: psjm
 */

#ifndef MONTGOMERY_ARRAY_H_
#define MONTGOMERY_ARRAY_H_

void mont_prod_array(int length, uint32_t *A, uint32_t *B, uint32_t *M,
		uint32_t *temp, uint32_t *s);
void mont_exp_array(int length, uint32_t *X, uint32_t *E, uint32_t *M,
		uint32_t *Nr, uint32_t *P, uint32_t *ONE, uint32_t *temp, uint32_t *temp2, uint32_t *Z);

#endif /* MONTGOMERY_ARRAY_H_ */
