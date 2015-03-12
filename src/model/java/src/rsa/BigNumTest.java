package rsa;

import static org.junit.Assert.*;

import org.junit.Test;

public class BigNumTest {

	@Test
	public void testShiftRight() {
		int[] a = { 0x01234567, 0x89abcdef };
		BigNum.shift_right_1_array(2, a, a);
		BigNum.shift_right_1_array(2, a, a);
		BigNum.shift_right_1_array(2, a, a);
		BigNum.shift_right_1_array(2, a, a);
		int[] expected = { 0x00123456, 0x789abcde };
		assertArrayEquals(expected, a);
	}

	@Test
	public void testAdd() {
		int[] a = { 0x01234567, 0x89abcdef };
		int[] b = { 0x12000002, 0x77000001 };
		int[] c = new int[2];
		BigNum.add_array(2, a, b, c);
		int[] expected = { 0x1323456a, 0x00abcdf0 };
		System.out.printf("%x %x %x\n", c[0], c[1], 0x0123456789abcdefL + 0x1200000277000001L);
		assertArrayEquals(expected, c);
	}

	@Test
	public void testSub() {
		int[] a = { 0x01234567, 0x89abcdef };
		int[] b = { 0x00200000, 0x8a001001 };
		int[] c = new int[2];
		BigNum.sub_array(2, a, b, c);
		int[] expected = { 0x1034566, 0xffabbdee };
		System.out.printf("%8x %8x %x\n", c[0], c[1], 0x0123456789abcdefL - 0x002000008a001001L);
		assertArrayEquals(expected, c);
	}
	

}
