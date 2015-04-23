package org.crypttech.modexp.testgenerator;

public class TestVector {
	public final String generator; 
	public final String seed; 
	public final int length; 
	public final int[] X; 
	public final int[] E; 
	public final int[] M; 
	public final int[] expected;
	
	public TestVector(String generator, String seed, int length, int[] x,
			int[] e, int[] m, int[] expected) {
		super();
		this.generator = generator;
		this.seed = seed;
		this.length = length;
		X = x;
		E = e;
		M = m;
		this.expected = expected;
	}
}
