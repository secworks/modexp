package org.crypttech.modexp.testgenerator;

import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

import org.crypttech.modexp.testgenerator.format.GeneratorC;

public class TestGenerator {
	public static void main(String[] argv) throws Exception {
		System.out.println("Generating modexp test values.");

		List<TestVector> vectors = new ArrayList<TestVector>();
		vectors.addAll(TestGeneratorBasic.getTestVectors());
		PrintWriter pw = new PrintWriter("../model/c/src/bajs.c");
		try (GeneratorC genC = new GeneratorC(pw)) {
			for (TestVector vector : vectors)
				genC.format(vector);
		}
	}
}
