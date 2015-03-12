package rsa;

import org.junit.Test;

public class Montgomery {
	static final int TEST_CONSTANT_PRIME_15_1 = 65537;
	static final int TEST_CONSTANT_PRIME_31_1 = 2147483647; // eighth Mersenne prime


	
	int mont_prod(int A, int B, int M) {
		int s = 0;
		for(int i = 0; i < 32; i++) {
			int b = (B >>> i) & 1;
			int q = (s - b * A) & 1;
			s = (s + q*M + b*A) >>> 1;
		}
		return s;
	}
	
	int m_residue(int A, int M) {
		long x = A & 0xFFFFFFFFFL;
		long m = M & 0xFFFFFFFFFL;
		x <<= 32;
		x %= m;
		return (int) x;
	}

	boolean test_montgomery_a_b_m(int A, int B, int M) {
		//int prodMod = (A * B) % M;
		int prodMod = A % M;
		prodMod *= B % M;
		prodMod %= M;
		int Ar = m_residue(A, M);
		int Br = m_residue(B, M);
		int monProdMod = mont_prod(Ar, Br, M);
		int monProdMod_ = mont_prod(1, monProdMod, M);
		boolean success = prodMod == monProdMod_;
		System.out.printf("%c A=%3x B=%3x M=%3x A*B=%3x Ar=%3x Br=%3x Ar*Br=%3x A*B=%3x\n",
				success ? '*' : ' ', A, B, M, prodMod, Ar, Br,
				monProdMod, monProdMod_);
		return success;
	}

	@Test
	public void test_montgomery() {
		test_montgomery_a_b_m(11, 17, 19);
		test_montgomery_a_b_m(11, 19, 17);
		test_montgomery_a_b_m(17, 11, 19);
		test_montgomery_a_b_m(17, 19, 11);
		test_montgomery_a_b_m(19, 11, 17);
		test_montgomery_a_b_m(19, 17, 11);

		test_montgomery_a_b_m(TEST_CONSTANT_PRIME_15_1, 17, 19);
		test_montgomery_a_b_m(TEST_CONSTANT_PRIME_15_1, 19, 17);
		test_montgomery_a_b_m(17, TEST_CONSTANT_PRIME_15_1, 19);
		test_montgomery_a_b_m(17, 19, TEST_CONSTANT_PRIME_15_1);
		test_montgomery_a_b_m(19, TEST_CONSTANT_PRIME_15_1, 17);
		test_montgomery_a_b_m(19, 17, TEST_CONSTANT_PRIME_15_1);

		test_montgomery_a_b_m(TEST_CONSTANT_PRIME_15_1, 17,
				TEST_CONSTANT_PRIME_31_1);
		test_montgomery_a_b_m(TEST_CONSTANT_PRIME_15_1, TEST_CONSTANT_PRIME_31_1,
				17);
		test_montgomery_a_b_m(17, TEST_CONSTANT_PRIME_15_1,
				TEST_CONSTANT_PRIME_31_1);
		test_montgomery_a_b_m(17, TEST_CONSTANT_PRIME_31_1,
				TEST_CONSTANT_PRIME_15_1);
		test_montgomery_a_b_m(TEST_CONSTANT_PRIME_31_1, TEST_CONSTANT_PRIME_15_1,
				17);
		test_montgomery_a_b_m(TEST_CONSTANT_PRIME_31_1, 17,
				TEST_CONSTANT_PRIME_15_1);
	}

}
