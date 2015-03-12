#include <stdio.h>
#include <stdlib.h>
#include "bignum_uint32_t.h"

void copy_array(int length, uint32_t *src, uint32_t *dst) {
	for (int i = 0; i < length; i++)
		dst[i] = src[i];
}

void add_array(int length, uint32_t *a, uint32_t *b, uint32_t *result) {
	uint64_t carry = 0;
	for (int i = length - 1; i >= 0; i--) {
		uint64_t r = carry;
		uint32_t aa = a[i];
		uint32_t bb = b[i];
		r += aa & 0xFFFFFFFFul;
		r += bb & 0xFFFFFFFFul;
		carry = r >> 32;
		result[i] = (uint32_t) r;
	}
}

void sub_array(int length, uint32_t *a, uint32_t *b, uint32_t *result) {
	uint64_t carry = 1;
	for (int wordIndex = length - 1; wordIndex >= 0; wordIndex--) {
		uint64_t r = carry;
		uint32_t aa = a[wordIndex];
		uint32_t bb = ~b[wordIndex];
		r += aa & 0xFFFFFFFFul;
		r += bb & 0xFFFFFFFFul;
		carry = r >> 32;
		result[wordIndex] = (uint32_t) r;
	}
}

void shift_right_1_array(int length, uint32_t *a, uint32_t *result) {
	uint32_t prev = 0; // MSB will be zero extended
	for (int wordIndex = 0; wordIndex < length; wordIndex++) {
		uint32_t aa = a[wordIndex];
		result[wordIndex] = (aa >> 1) | (prev << 31);
		prev = aa & 1; // Lower word will be extended with LSB of this word
	}
}

void shift_left_1_array(int length, uint32_t *a, uint32_t *result) {
	uint32_t prev = 0; // LSB will be zero extended
	for (int wordIndex = length - 1; wordIndex >= 0; wordIndex--) {
		uint32_t aa = a[wordIndex];
		result[wordIndex] = (aa << 1) | prev;

		// Higher word will be extended with MSB of this word
		prev = aa >> 31;
	}
}

void debugArray(char *msg, int length, uint32_t *array) {
	printf("%s ", msg);
	for (int i = 0; i < length; i++) {
		printf("%8x ", array[i]);
	}
	printf("\n");
}

void modulus_array(int length, uint32_t *a, uint32_t *modulus, uint32_t *temp,
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

void zero_array(int length, uint32_t *a) {
	for (int i = 0; i < length; i++)
		a[i] = 0;
}

int greater_than_array(int length, uint32_t *a, uint32_t *b) {
	for (int i = 0; i < length; i++) {
		if (a[i] > b[i])
			return 1;
		if (a[i] < b[i])
			return 0;
	}
	return 0;
}
