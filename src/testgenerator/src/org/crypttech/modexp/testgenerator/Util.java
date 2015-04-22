package org.crypttech.modexp.testgenerator;

import java.math.BigInteger;

public class Util {
	public static TestVector generateTestVector(String generator, String seed, int length, 
			BigInteger m, BigInteger x, BigInteger e, BigInteger z) {
		//System.out.printf("%s %s %s %s\n", m.toString(16), x.toString(16), e.toString(16), z.toString(16));
		int[] mi = toInt(length, m);
		int[] xi = toInt(length, x);
		int[] ei = toInt(length, e);
		int[] zi = toInt(length, z);
		return new TestVector(generator, seed, length, xi, ei, mi, zi);
	}

	
	public static int[] toInt(int length, BigInteger bi) {
		byte[] ba = bi.toByteArray();
		int[] ia = new int[length];
		for (int j = ba.length-1; j >= 0; j--) {
			int changeByte = ((ba.length-1-j)%4);
			int jj = length -1 - (ba.length-1-j)/4;
			ia[jj] |= (ba[j] & 0xff) << (changeByte*8);
		}
		return ia;
	}

}
