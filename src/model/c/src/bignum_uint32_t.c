#include <stdio.h>
#include <stdlib.h>
#include "bignum_uint32_t.h"

int assert_array_total = 0;
int assert_array_error = 0;
void assertArrayEquals(uint32_t length, uint32_t *expected, uint32_t *actual) { //needed in tests
	int equals = 1;
	for (uint32_t i = 0; i < length; i++)
		equals &= expected[i] == actual[i];
	printf("%s expected: \n[", equals ? "PASS" : "FAIL");
	for (uint32_t i = 0; i < length - 1; i++) {
          if ((i > 0) && (!(i % 4)))
            printf("\n ");
          printf("0x%08x, ", expected[i]);
        }
        printf("0x%08x]", expected[length - 1]);

        printf("\n\n");
        printf("actual:\n[");
	for (uint32_t i = 0; i < length - 1; i++) {
          if ((i > 0) && (!(i % 4)))
            printf("\n ");
          printf("0x%08x, ", actual[i]);
        }
	printf("0x%08x]\n", actual[length - 1]);

        printf("\n");
	assert_array_total++;
	if (!equals)
		assert_array_error++;
}

void print_assert_array_stats(void) {
	printf("%d tests, failed: %d\n", assert_array_total, assert_array_error);
}

void copy_array(uint32_t length, uint32_t *src, uint32_t *dst) {
	for (uint32_t i = 0; i < length; i++)
		dst[i] = src[i];
}

void add_array(uint32_t length, uint32_t *a, uint32_t *b, uint32_t *result) {
	uint64_t carry = 0;
	for (int32_t i = ((int32_t) length) - 1; i >= 0; i--) {
		uint64_t r = carry;
		uint32_t aa = a[i];
		uint32_t bb = b[i];
		r += aa & 0xFFFFFFFFul;
		r += bb & 0xFFFFFFFFul;
		carry = r >> 32;
		result[i] = (uint32_t) r;
	}
}

void sub_array(uint32_t length, uint32_t *a, uint32_t *b, uint32_t *result) {
	uint64_t carry = 1;
	for (int32_t wordIndex = ((int32_t) length) - 1; wordIndex >= 0; wordIndex--) {
		uint64_t r = carry;
		uint32_t aa = a[wordIndex];
		uint32_t bb = ~b[wordIndex];
		r += aa & 0xFFFFFFFFul;
		r += bb & 0xFFFFFFFFul;
		carry = r >> 32;
		result[wordIndex] = (uint32_t) r;
	}
}

void shift_right_1_array(uint32_t length, uint32_t *a, uint32_t *result) {
	uint32_t prev = 0; // MSB will be zero extended
	for (uint32_t wordIndex = 0; wordIndex < length; wordIndex++) {
		uint32_t aa = a[wordIndex];
		result[wordIndex] = (aa >> 1) | (prev << 31);
		prev = aa & 1; // Lower word will be extended with LSB of this word
	}
}

void shift_left_1_array(uint32_t length, uint32_t *a, uint32_t *result) {
	uint32_t prev = 0; // LSB will be zero extended
	for (int32_t wordIndex = ((int32_t) length) - 1; wordIndex >= 0; wordIndex--) {
		uint32_t aa = a[wordIndex];
		result[wordIndex] = (aa << 1) | prev;

		// Higher word will be extended with MSB of this word
		prev = aa >> 31;
	}
}

void debugArray(char *msg, uint32_t length, uint32_t *array) {
	printf("%s ", msg);
	for (uint32_t i = 0; i < length; i++) {
		printf("%8x ", array[i]);
	}
	printf("\n");
}

void modulus_array(uint32_t length, uint32_t *a, uint32_t *modulus, uint32_t *temp,
		uint32_t *reminder) {
	copy_array(length, a, reminder);

	while (!greater_than_array(length, modulus, reminder)) {

		copy_array(length, modulus, temp);

		while (((temp[0] & 0x80000000) == 0)
				&& (!greater_than_array(length, temp, reminder))) {
			sub_array(length, reminder, temp, reminder);
			shift_left_1_array(length, temp, temp);
		}
	}
}

void zero_array(uint32_t length, uint32_t *a) {
	for (uint32_t i = 0; i < length; i++)
		a[i] = 0;
}

int greater_than_array(uint32_t length, uint32_t *a, uint32_t *b) {
	for (uint32_t i = 0; i < length; i++) {
		if (a[i] > b[i])
			return 1;
		if (a[i] < b[i])
			return 0;
	}
	return 0;
}
