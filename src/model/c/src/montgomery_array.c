#include <stdio.h>
#include <stdlib.h>
#include "bignum_uint32_t.h"
#include "montgomery_array.h"

void mont_prod_array(int length, uint32_t *A, uint32_t *B, uint32_t *M,
		uint32_t *temp, uint32_t *s) {
	zero_array(length, s);
	for (int wordIndex = length - 1; wordIndex >= 0; wordIndex--) {
		for (int i = 0; i < 32; i++) {

			int b = (B[wordIndex] >> i) & 1;

			//q = (s - b * A) & 1;
			sub_array(length, s, A, temp);
			int q;
			if (b == 1) {
				q = temp[length - 1] & 1;
			} else {
				q = s[length - 1] & 1;
			}

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

void m_residue_2_2N_array(int length, int N, uint32_t *M, uint32_t *temp,
		uint32_t *Nr) {
	zero_array(length, Nr);
	Nr[length - 1] = 1; // Nr = 1 == 2**(2N-2N)
	for (int i = 0; i < 2 * N; i++) {
		shift_left_1_array(length, Nr, Nr);
		modulus_array(length, Nr, M, temp, Nr);
//			debugArray(length, Nr);
	}
	// Nr = (2 ** 2N) mod M
}

int findN(int length, uint32_t *E) {
	int n = -1;
	for (int i = 0; i < 32 * length; i++) {
		uint32_t ei_ = E[length - 1 - (i / 32)];
		uint32_t ei = (ei_ >> (i % 32)) & 1;
		if (ei == 1) {
			n = i;
		}
	}
	return n + 1;
}

void mont_exp_array(int length, uint32_t *X, uint32_t *E, uint32_t *M,
		uint32_t *Nr, uint32_t *P, uint32_t *ONE, uint32_t *temp,
		uint32_t *temp2, uint32_t *Z) {
	//debugArray("X ", length, X);
	//debugArray("E ", length, E);
	//debugArray("M ", length, M);

	// 1. Nr := 2 ** 2N mod M
	const int N = 32 * length;
	m_residue_2_2N_array(length, N, M, temp, Nr);
	//debugArray("Nr", length, Nr);

	// 2. Z0 := MontProd( 1, Nr, M )
	zero_array(length, ONE);
	ONE[length - 1] = 1;
	mont_prod_array(length, ONE, Nr, M, temp, Z);
	//debugArray("Z0", length, Z);

	// 3. P0 := MontProd( X, Nr, M );
	mont_prod_array(length, X, Nr, M, temp, P);
	//debugArray("P0", length, P);

	// 4. for i = 0 to n-1 loop
	const int n = findN(length, E); //loop optimization for low values of E. Not necessary.
	for (int i = 0; i < n; i++) {
		uint32_t ei_ = E[length - 1 - (i / 32)];
		uint32_t ei = (ei_ >> (i % 32)) & 1;
		// 6. if (ei = 1) then Zi+1 := MontProd ( Zi, Pi, M) else Zi+1 := Zi
		if (ei == 1) {
			mont_prod_array(length, Z, P, M, temp, temp2);
			copy_array(length, temp2, Z);
			//debugArray("Z ", length, Z);
		}
		// 5. Pi+1 := MontProd( Pi, Pi, M );
		mont_prod_array(length, P, P, M, temp, temp2);
		copy_array(length, temp2, P);
		//debugArray("P ", length, P);
		// 7. end for
	}
	// 8. Zn := MontProd( 1, Zn, M );
	mont_prod_array(length, ONE, Z, M, temp, temp2);
	copy_array(length, temp2, Z);
	//debugArray("Z ", length, Z);
	// 9. RETURN Zn

}

