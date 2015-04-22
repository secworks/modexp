package org.crypttech.modexp.testgenerator;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class TestGeneratorBasic {
	public static final List<TestVector> getTestVectors() {
		Random rng = new Random(0); //any static seed
		ArrayList<TestVector> list = new ArrayList<TestVector>();
		for(int i = 0; i < 10; i++) {
			final long seed = rng.nextLong();
			rng.setSeed(seed);
			BigInteger m = BigInteger.probablePrime(33, rng);
			BigInteger x = BigInteger.probablePrime(33, rng);
			BigInteger e = BigInteger.probablePrime(33, rng);
			BigInteger z = x.modPow(e, m);
			TestVector tv = Util.generateTestVector("BASIC", Long.toString(seed), 2, m, x, e, z);
			list.add(tv);
		}
		return list;
	}


}
