package rsa;

public class PerformanceClock {
	static long then;
	static void updateThen() {
		then = System.currentTimeMillis();
	}
	static void debug(String s) {
		long time = System.currentTimeMillis() - then;
		System.out.printf(" %5d ms %s\n", time, s);
		updateThen();
	}
	
}
