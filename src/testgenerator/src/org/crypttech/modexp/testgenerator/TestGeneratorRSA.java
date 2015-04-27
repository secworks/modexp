package org.crypttech.modexp.testgenerator;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class TestGeneratorRSA {

	private static final BigInteger ONE = new BigInteger("1");

	public static final List<TestVector> getTestVectors() {
		Random rng = new Random(0); // any static seed
		ArrayList<TestVector> list = new ArrayList<TestVector>();
		int[] sizes = { 64, 128, 256, 512, 1024 };
		for (int size : sizes)
			generateTestVectors(rng, list, size, ((size*2) / 32) + 1, 1);
		return list;
	}

	private static void generateTestVectors(Random rng,
			ArrayList<TestVector> list, int bitLength, int wordLength, int max) {
		for (int i = 0; i < max; i++) {
			final long seed = rng.nextLong();
			rng.setSeed(seed);
			// Choose two distinct prime numbers p and q.
			BigInteger p = BigInteger.probablePrime(bitLength, rng);
			BigInteger q = BigInteger.probablePrime(bitLength, rng);
			// Compute n = pq.
			BigInteger n = p.multiply(q);
			// Compute φ(n) = φ(p)φ(q) = (p − 1)(q − 1) = n - (p + q -1)
			BigInteger φ = n.subtract(p.add(q).subtract(ONE));
			// Choose an integer e such that 1 < e < φ(n) and gcd(e, φ(n)) = 1;
			// i.e., e and φ(n) are coprime.
			BigInteger e = new BigInteger("65537");
			if (! ONE.equals(e.gcd(φ))) {
				throw new RuntimeException("Warning: The world is on fire! Invalid RSA non-coprime e,φ detected by GCD. Continuing would generate an illegal secret key.");
			}
			// Determine d as d ≡ e−1 (mod φ(n)); i.e., d is the modular
			// multiplicative inverse of e (modulo φ(n)).
			BigInteger d = e.modInverse(φ);

			BigInteger x = BigInteger.probablePrime(bitLength*2-4, rng);
			BigInteger z = x.modPow(e, n);
			TestVector tv = Util.generateTestVector("RSA_ENCRYPT_2x"
					+ bitLength, Long.toString(seed), wordLength, n, x, e, z);
			list.add(tv);
			System.out.printf(
					"%s Generated rsa encrypt test: bits: %d seed: %d\n",
					TestGeneratorRSA.class.getName(), bitLength, seed);

			TestVector tv2 = Util.generateTestVector("RSA_DECRYPT_2x"
					+ bitLength, Long.toString(seed), wordLength, n, z, d, x);
			list.add(tv2);
			System.out.printf(
					"%s Generated rsa decrypt test: bits: %d seed: %d\n",
					TestGeneratorRSA.class.getName(), bitLength, seed);
		}
	}

}
