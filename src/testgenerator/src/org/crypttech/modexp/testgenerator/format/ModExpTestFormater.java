package org.crypttech.modexp.testgenerator.format;

import java.io.PrintWriter;

import org.crypttech.modexp.testgenerator.TestVector;

public abstract class ModExpTestFormater implements AutoCloseable {
	private static final char LF = (char) 10;
	private final boolean alwaysLF;
	private final PrintWriter pw;

	public ModExpTestFormater(PrintWriter pw, boolean alwaysLF) {
		this.pw = pw;
		this.alwaysLF = alwaysLF;
	}

	public ModExpTestFormater(PrintWriter pw) {
		this(pw, false);
	}

	public abstract void format(TestVector testVector);

	protected final void out(String s) {
		pw.print(s);
		if (alwaysLF)
			pw.print(LF);
	}

	protected final void out(String frmt, Object... args) {
		out(String.format(frmt, args));
	}

	@Override
	public void close() throws Exception {
		pw.close();
		System.out.printf("%s closing...\n", this.getClass().getName());
	}
}
