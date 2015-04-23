package org.crypttech.modexp.testgenerator.format;

import java.io.PrintWriter;

import org.crypttech.modexp.testgenerator.TestVector;

public abstract class ModExpTestFormater implements AutoCloseable {
	private PrintWriter pw;
	
	public ModExpTestFormater(PrintWriter pw) {
		this.pw = pw;
	}
	
	public abstract void format(TestVector testVector);

	protected final void out(String s) {
		pw.print(s);
	}
	
	@Override
	public void close() throws Exception {
		pw.close();
	}
	
	
}
