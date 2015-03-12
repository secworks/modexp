package rsa;

public class BigNum {
	static void debugArray(int length, int[] array) {
		System.out.println(" debug => ");
		for (int a : array) {
			System.out.printf("%8x ", a);
		}
		System.out.println();
	}
	
	static void debugArray(String s, int length, int[] array) {
		System.out.printf(" debug %s => ", s);
		for (int a : array) {
			System.out.printf("%8x ", a);
		}
		System.out.println();
	}
	
	static void copy_array(int length, int[] src, int[] dst) {
		for (int i = 0; i < length; i++)
			dst[i] = src[i];
	}

	static void add_array(int length, int[] a, int b[], int result[]) {
		long carry = 0;
		for (int i = length - 1; i >= 0; i--) {
			long r = carry;
			int aa = a[i];
			int bb = b[i];
			r += aa & 0xFFFFFFFFL;
			r += bb & 0xFFFFFFFFL;
			carry = ((int) (r >> 32l)) & 1;
			result[i] = (int) r;
		}
	}

	static void sub_array(int length, int[] a, int[] b, int result[]) {
		long carry = 1;
		for (int wordIndex = length - 1; wordIndex >= 0; wordIndex--) {
			long r = carry;
			int aa = a[wordIndex];
			int bb = ~b[wordIndex];
			r += aa & 0xFFFFFFFFL;
			r += bb & 0xFFFFFFFFL;
			carry = (r >> 32l) & 1;
			result[wordIndex] = (int) r;
		}
	}

	static void shift_right_1_array(int length, int[] a, int result[]) {
		int prev = 0; // MSB will be zero extended
		for (int wordIndex = 0; wordIndex < length; wordIndex++) {
			int aa = a[wordIndex];
			result[wordIndex] = (aa >>> 1) | (prev << 31);
			prev = aa & 1; // Lower word will be extended with LSB of this word
		}
	}

	static void shift_left_1_array(int length, int[] a, int result[]) {
		int prev = 0; // LSB will be zero extended
		for (int wordIndex = length - 1; wordIndex >= 0; wordIndex--) {
			int aa = a[wordIndex];
			result[wordIndex] = (aa << 1) | prev;
			prev = aa >>> 31; // Lower word will be extended with LSB of this
								// word
		}
	}

	static void zero_array(int length, int[] a) {
		for (int i = 0; i < length; i++)
			a[i] = 0;
	}

	static boolean greater_than_array(int length, int[] a, int[] b) {
		for (int i = 0; i < length; i++) {
			long aa = a[i] & 0xFFFF_FFFFL;
			long bb = b[i] & 0xFFFF_FFFFL;
			if (aa > bb)
				return true;
			if (aa < bb)
				return false;

		}
		return false;
	}


}
