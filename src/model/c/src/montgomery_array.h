/*
 * montgomery_array.h
 *
 *  Created on: Mar 3, 2015
 *      Author: psjm
 */

#ifndef MONTGOMERY_ARRAY_H_
#define MONTGOMERY_ARRAY_H_

void mont_prod_array(uint32_t length, uint32_t *A, uint32_t *B, uint32_t *M,
		uint32_t *s);
void mod_exp_array(uint32_t length, uint32_t *X, uint32_t *E, uint32_t *M, uint32_t *Z);


void mont_prod_array2(uint32_t explength, uint32_t modlength, uint32_t *A, uint32_t *B, uint32_t *M,
		uint32_t *s);

void mod_exp_array2(uint32_t explength, uint32_t modlength, uint32_t *X, uint32_t *E, uint32_t *M, uint32_t *Z);

#endif /* MONTGOMERY_ARRAY_H_ */
