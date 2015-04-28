package org.crypttech.modexp.testgenerator;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;


public class TestGenerator65537 {

	public static final List<TestVector> getTestVectors() {
		Random rng = new Random(0); //any static seed
		ArrayList<TestVector> list = new ArrayList<TestVector>();
		int[] sizes = { 64, 128, 256, 512, 1024, 2048 };
		for (int size : sizes) 
			generateTestVectors(rng, list, size, (size/32)+1, 3); //+1 because model requires leading zeros currently
		return list;
	}

	private static void generateTestVectors(Random rng,
			ArrayList<TestVector> list, int bitLength, int wordLength, int max) {
		for(int i = 0; i < max; i++) {
			final long seed = rng.nextLong();
			rng.setSeed(seed);
			BigInteger m = BigInteger.probablePrime(bitLength, rng);
			BigInteger x = BigInteger.probablePrime(bitLength, rng);
			BigInteger e = new BigInteger("65537");
			BigInteger z = x.modPow(e, m);
			TestVector tv = Util.generateTestVector("65537_"+bitLength, Long.toString(seed), wordLength, m, x, e, z);
			list.add(tv);
			System.out.printf("%s Generated test: bits: %d seed: %d\n", TestGenerator65537.class.getName(), bitLength, seed);
		}
	}
}
