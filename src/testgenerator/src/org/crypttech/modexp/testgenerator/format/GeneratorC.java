package org.crypttech.modexp.testgenerator.format;

import java.io.FileNotFoundException;
import java.io.PrintWriter;

import org.crypttech.modexp.testgenerator.TestVector;

public class GeneratorC extends ModExpTestFormater {
	private static final char LF = (char) 10;

	public GeneratorC(String file) throws FileNotFoundException {
		super(new PrintWriter(file));
		out("#include <stdio.h>" + LF);
		out("#include <stdlib.h>" + LF);
		out("#include \"montgomery_array.h\"" + LF);
		out("#include \"bignum_uint32_t.h\"" + LF);
	}

	StringBuilder footer = new StringBuilder();

	@Override
	public void format(TestVector testVector) {
		String testname = ("autogenerated_" + testVector.generator + "_" + testVector.seed)
				.replace("-", "M");
		footer.append("  ").append(testname).append("();").append(LF);

		StringBuilder sb = new StringBuilder();
		sb.append("void ").append(testname).append("(void) {").append(LF);
		sb.append("  printf(\"=== ").append(testname).append(" ===\\n\");")
				.append(LF);
		appendCArray(sb, "X", testVector.X);
		appendCArray(sb, "E", testVector.E);
		appendCArray(sb, "M", testVector.M);
		appendCArray(sb, "expected", testVector.expected);
		int[] Z = new int[testVector.length];
		appendCArray(sb, "Z", Z);
		sb.append("  mod_exp_array(").append(testVector.length)
				.append(", X, E, M, Z);").append(LF);
		sb.append("  assertArrayEquals(").append(testVector.length)
				.append(", expected, Z);").append(LF);
		sb.append("}").append(LF);
		out(sb.toString());
	}

	private void appendCArray(StringBuilder sb, String arrayName, int[] array) {
		sb.append("  uint32_t ").append(arrayName).append("[] = ");
		sb.append("{ ");
		for (int m : array)
			sb.append(String.format("0x%08x, ", m));
		sb.replace(sb.length() - 2, sb.length(), " };");
		sb.append(LF);
	}

	@Override
	public void close() throws Exception {
		out("void autogenerated_tests(void) {" + LF);
		out(footer.toString());
		out("}" + LF);
		super.close();
	}

}
