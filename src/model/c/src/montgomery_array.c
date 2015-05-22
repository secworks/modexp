#include <stdio.h>
#include <stdlib.h>
#include "bignum_uint32_t.h"
#include "montgomery_array.h"

void mont_prod_array(uint32_t length, uint32_t *A, uint32_t *B, uint32_t *M, uint32_t *s) {
	zero_array(length, s);
	for (int32_t wordIndex = ((int32_t) length) - 1; wordIndex >= 0; wordIndex--) {
		for (int i = 0; i < 32; i++) {

			uint32_t b = (B[wordIndex] >> i) & 1;

			//q = (s - b * A) & 1;
			uint32_t q = (s[length-1] ^ (A[length-1] & b)) & 1; // int q = (s - b * A) & 1;

			// s = (s + q*M + b*A) >>> 1;
			if (q == 1) {
				add_array(length, s, M, s);
			} else {
				//TODO possibly do some sub operation to temporary here just to force constant execution time.
			}

			if (b == 1) {
				add_array(length, s, A, s);
			} else {
				//TODO possibly do some sub operation to temporary here just to force constant execution time.
			}

			shift_right_1_array(length, s, s);
		}
	}
}

void m_residue_2_2N_array(uint32_t length, uint32_t N, uint32_t *M, uint32_t *temp,
		uint32_t *Nr) {
	zero_array(length, Nr);
	Nr[length - 1] = 1; // Nr = 1 == 2**(2N-2N)
	for (uint32_t i = 0; i < 2 * N; i++) {
		shift_left_1_array(length, Nr, Nr);
		modulus_array(length, Nr, M, temp, Nr);
//			debugArray(length, Nr);
	}
	// Nr = (2 ** 2N) mod M
}

uint32_t findN(uint32_t length, uint32_t *E) {
	uint32_t n = 0;
	for (uint32_t i = 0; i < 32 * length; i++) {
		uint32_t ei_ = E[length - 1 - (i / 32)];
		uint32_t ei = (ei_ >> (i % 32)) & 1;
		if (ei == 1) {
			n = i+1;
		}
	}
	return n;
}

void mont_exp_array(uint32_t length, uint32_t *X, uint32_t *E, uint32_t *M,
		uint32_t *Nr, uint32_t *P, uint32_t *ONE, uint32_t *temp,
		uint32_t *temp2, uint32_t *Z) {
	//debugArray("X ", length, X);
	//debugArray("E ", length, E);
	//debugArray("M ", length, M);

	// 1. Nr := 2 ** 2N mod M
	const uint32_t N = 32 * length;
	m_residue_2_2N_array(length, N, M, temp, Nr);
	//debugArray("Nr", length, Nr);

	// 2. Z0 := MontProd( 1, Nr, M )
	zero_array(length, ONE);
	ONE[length - 1] = 1;
	mont_prod_array(length, ONE, Nr, M, Z);
	//debugArray("Z0", length, Z);

	// 3. P0 := MontProd( X, Nr, M );
	mont_prod_array(length, X, Nr, M, P);
	//debugArray("P0", length, P);

	// 4. for i = 0 to n-1 loop
	const uint32_t n = findN(length, E); //loop optimization for low values of E. Not necessary.
	for (uint32_t i = 0; i < n; i++) {
		uint32_t ei_ = E[length - 1 - (i / 32)];
		uint32_t ei = (ei_ >> (i % 32)) & 1;
		// 6. if (ei = 1) then Zi+1 := MontProd ( Zi, Pi, M) else Zi+1 := Zi
		if (ei == 1) {
			mont_prod_array(length, Z, P, M, temp2);
			copy_array(length, temp2, Z);
			//debugArray("Z ", length, Z);
		}
		// 5. Pi+1 := MontProd( Pi, Pi, M );
		mont_prod_array(length, P, P, M, temp2);
		copy_array(length, temp2, P);
		//debugArray("P ", length, P);
		// 7. end for
	}
	// 8. Zn := MontProd( 1, Zn, M );
	mont_prod_array(length, ONE, Z, M, temp2);
	copy_array(length, temp2, Z);
	//debugArray("Z ", length, Z);
	// 9. RETURN Zn

}

// Experimental version where we add explicit lengths.
void mont_exp_array2(uint32_t explength, uint32_t modlength, uint32_t *X, uint32_t *E, uint32_t *M,
		uint32_t *Nr, uint32_t *P, uint32_t *ONE, uint32_t *temp,
		uint32_t *temp2, uint32_t *Z) {
	//debugArray("X ", length, X);
	//debugArray("E ", length, E);
	//debugArray("M ", length, M);

	// 1. Nr := 2 ** 2N mod M
	const uint32_t N = 32 * modlength;
	m_residue_2_2N_array(modlength, N, M, temp, Nr);
	//debugArray("Nr", length, Nr);

	// 2. Z0 := MontProd( 1, Nr, M )
	zero_array(modlength, ONE);
	ONE[modlength - 1] = 1;
	mont_prod_array(modlength, ONE, Nr, M, Z);
	//debugArray("Z0", length, Z);

	// 3. P0 := MontProd( X, Nr, M );
	mont_prod_array(modlength, X, Nr, M, P);
	//debugArray("P0", length, P);

	// 4. for i = 0 to explength - 1 loop
	for (uint32_t i = 0; i < (explength * 32); i++) {
		uint32_t ei_ = E[explength - 1 - (i / 32)];
		uint32_t ei = (ei_ >> (i % 32)) & 1;
		// 6. if (ei = 1) then Zi+1 := MontProd ( Zi, Pi, M) else Zi+1 := Zi
		if (ei == 1) {
			mont_prod_array(modlength, Z, P, M, temp2);
			copy_array(modlength, temp2, Z);
			//debugArray("Z ", length, Z);
		}
		// 5. Pi+1 := MontProd( Pi, Pi, M );
		mont_prod_array(modlength, P, P, M, temp2);
		copy_array(modlength, temp2, P);
		//debugArray("P ", length, P);
		// 7. end for
	}
	// 8. Zn := MontProd( 1, Zn, M );
	mont_prod_array(modlength, ONE, Z, M, temp2);
	copy_array(modlength, temp2, Z);
	//debugArray("Z ", length, Z);
	// 9. RETURN Zn

}

void die(const char *c) {
	printf("Fatal error: %s\n", c);
	exit(1);
}

void mod_exp_array(uint32_t length, uint32_t *X, uint32_t *E, uint32_t *M, uint32_t *Z) {
	uint32_t *Nr = calloc(length, sizeof(uint32_t));
	uint32_t *P = calloc(length, sizeof(uint32_t));
	uint32_t *ONE = calloc(length, sizeof(uint32_t));
	uint32_t *temp = calloc(length, sizeof(uint32_t));
	uint32_t *temp2 = calloc(length, sizeof(uint32_t));
	if (Nr == NULL) die("calloc");
	if (P == NULL) die("calloc");
	if (ONE == NULL) die("calloc");
	if (temp == NULL) die("calloc");
	if (temp2 == NULL) die("calloc");
	mont_exp_array(length, X, E, M, Nr, P, ONE, temp, temp2, Z);
	free(Nr);
	free(P);
	free(ONE);
	free(temp);
	free(temp2);
}

// Experimental version with explicit explength separate from modlength.
void mod_exp_array2(uint32_t explength, uint32_t modlength, uint32_t *X, uint32_t *E, uint32_t *M, uint32_t *Z) {
	uint32_t *Nr = calloc(modlength, sizeof(uint32_t));
	uint32_t *P = calloc(modlength, sizeof(uint32_t));
	uint32_t *ONE = calloc(modlength, sizeof(uint32_t));
	uint32_t *temp = calloc(modlength, sizeof(uint32_t));
	uint32_t *temp2 = calloc(modlength, sizeof(uint32_t));
	if (Nr == NULL) die("calloc");
	if (P == NULL) die("calloc");
	if (ONE == NULL) die("calloc");
	if (temp == NULL) die("calloc");
	if (temp2 == NULL) die("calloc");
	mont_exp_array2(explength, modlength, X, E, M, Nr, P, ONE, temp, temp2, Z);
	free(Nr);
	free(P);
	free(ONE);
	free(temp);
	free(temp2);
}
