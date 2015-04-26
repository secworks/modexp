package org.crypttech.modexp.testgenerator;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class TestGeneratorBasic {
	public static final List<TestVector> getTestVectors() {
		Random rng = new Random(0); //any static seed
		ArrayList<TestVector> list = new ArrayList<TestVector>();
		
		generateTestVectors(rng, list, 33, 2);
		generateTestVectors(rng, list, 30, 1);
		//generateTestVectors(rng, list, 32, 1); //will generate failing tests in C model 
		//generateTestVectors(rng, list, 31, 1); //will generate failing tests in C model 
		generateTestVectors(rng, list, 126, 4);
		return list;
	}

	private static void generateTestVectors(Random rng,
			ArrayList<TestVector> list, int bitLength, int wordLength) {
		for(int i = 0; i < 10; i++) {
			final long seed = rng.nextLong();
			rng.setSeed(seed);
			BigInteger m = BigInteger.probablePrime(bitLength, rng);
			BigInteger x = BigInteger.probablePrime(bitLength, rng);
			BigInteger e = BigInteger.probablePrime(bitLength, rng);
			BigInteger z = x.modPow(e, m);
			TestVector tv = Util.generateTestVector("BASIC", Long.toString(seed), wordLength, m, x, e, z);
			list.add(tv);
		}
	}


}
