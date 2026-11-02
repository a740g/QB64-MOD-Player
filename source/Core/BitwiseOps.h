//----------------------------------------------------------------------------------------------------------------------
// Bitwise operation routines
// Copyright (c) 2024 Samuel Gomes
//
// Some of these came from my old game library and some from:
// https://graphics.stanford.edu/~seander/bithacks.html
// https://bits.stephan-brumme.com/
// http://aggregate.org/MAGIC/
// http://www.azillionmonkeys.com/qed/asmexample.html
// https://dspguru.com/dsp/tricks/
// http://programming.sirrida.de/
// https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <climits>
#include <cstdint>

/// @brief Returns the number using which we need to shift 1 left to get n. E.g. n = 2 then returns 1
/// @param n A power of 2 number
/// @return A number (x) that we use in 1 << x to get n
inline uint32_t LeftShiftOneCount(uint32_t n) {
    return n == 0 ? 0 : (CHAR_BIT * sizeof(n)) - 1 - __builtin_clz(n);
}

/// @brief Reverses bits in a 8-bit number
/// @param x The number
/// @return A number with bits reversed
inline uint8_t ReverseBitsByte(uint8_t x) {
    x = ((x & 0x55) << 1) | ((x & 0xAA) >> 1);
    x = ((x & 0x33) << 2) | ((x & 0xCC) >> 2);
    return (x >> 4) | (x << 4);
}

/// @brief Reverses bits in a 16-bit number
/// @param x The number
/// @return A number with bits reversed
inline uint16_t ReverseBitsInteger(uint16_t x) {
    x = ((x & 0xaaaa) >> 1) | ((x & 0x5555) << 1);
    x = ((x & 0xcccc) >> 2) | ((x & 0x3333) << 2);
    x = ((x & 0xf0f0) >> 4) | ((x & 0x0f0f) << 4);
    return (x >> 8) | (x << 8);
}

/// @brief Reverses bits in a 32-bit number
/// @param x The number
/// @return A number with bits reversed
inline uint32_t ReverseBitsLong(uint32_t x) {
    x = ((x & 0xaaaaaaaa) >> 1) | ((x & 0x55555555) << 1);
    x = ((x & 0xcccccccc) >> 2) | ((x & 0x33333333) << 2);
    x = ((x & 0xf0f0f0f0) >> 4) | ((x & 0x0f0f0f0f) << 4);
    x = ((x & 0xff00ff00) >> 8) | ((x & 0x00ff00ff) << 8);
    return (x >> 16) | (x << 16);
}

/// @brief Reverses bits in a 64-bit number
/// @param x The number
/// @return A number with bits reversed
inline uint64_t ReverseBitsInteger64(uint64_t x) {
    x = ((x & 0xaaaaaaaaaaaaaaaa) >> 1) | ((x & 0x5555555555555555) << 1);
    x = ((x & 0xcccccccccccccccc) >> 2) | ((x & 0x3333333333333333) << 2);
    x = ((x & 0xf0f0f0f0f0f0f0f0) >> 4) | ((x & 0x0f0f0f0f0f0f0f0f) << 4);
    x = ((x & 0xff00ff00ff00ff00) >> 8) | ((x & 0x00ff00ff00ff00ff) << 8);
    x = ((x & 0xffff0000ffff0000) >> 16) | ((x & 0x0000ffff0000ffff) << 16);
    return (x >> 32) | (x << 32);
}

/// @brief Makes a four-character code
/// @param ch0 Character 0
/// @param ch1 Character 1
/// @param ch2 Character 2
/// @param ch3 Character 3
/// @return The FOURCC
inline uint32_t MakeFourCC(uint8_t ch0, uint8_t ch1, uint8_t ch2, uint8_t ch3) {
    return (ch3 << 24) | (ch2 << 16) | (ch1 << 8) | ch0;
}

/// @brief Makes a BYTE out of two nibbles
/// @param x Nibble 1
/// @param y Nibble 2
/// @return A BYTE
inline uint8_t MakeByte(uint8_t x, uint8_t y) {
    return (uint8_t)y | (x << 4);
}

/// @brief Makes an INTEGER out of two BYTEs
/// @param x BYTE 1
/// @param y BYTE 2
/// @return An INTEGER
inline uint16_t MakeInteger(uint8_t x, uint8_t y) {
    return (uint16_t)y | ((uint16_t)x << 8);
}

/// @brief Makes a LONG out of two INTEGERs
/// @param x INTEGER 1
/// @param y INTEGER 2
/// @return A LONG
inline uint32_t MakeLong(uint16_t x, uint16_t y) {
    return (uint32_t)y | ((uint32_t)x << 16);
}

/// @brief Makes a INTEGER64 out of two LONGs
/// @param x LONG 1
/// @param y LONG 2
/// @return An INTEGER64
inline uint64_t MakeInteger64(uint32_t x, uint32_t y) {
    return (uint64_t)y | ((uint64_t)x << 32);
}

/// @brief Returns the high nibble from a BYTE
/// @param x A BYTE
/// @return A Nibble
inline uint8_t HiNibble(uint8_t x) {
    return x >> 4;
}

/// @brief Returns the low nibble from a BYTE
/// @param x A BYTE
/// @return A nibble
inline uint8_t LoNibble(uint8_t x) {
    return x & 0xFu;
}

/// @brief Returns the high BYTE from an INTEGER
/// @param x An INTEGER
/// @return A BYTE
inline uint8_t HiByte(uint16_t x) {
    return (uint8_t)(x >> 8);
}

/// @brief Returns the low BYTE from an INTEGER
/// @param x An INTEGER
/// @return A BYTE
inline uint8_t LoByte(uint16_t x) {
    return (uint8_t)(x);
}

/// @brief Returns the high INTEGER from an LONG
/// @param x A LONG
/// @return An INTEGER
inline uint16_t HiInteger(uint32_t x) {
    return (uint16_t)(x >> 16);
}

/// @brief Returns the low INTEGER from an LONG
/// @param x A LONG
/// @return An INTEGER
inline uint16_t LoInteger(uint32_t x) {
    return (uint16_t)(x);
}

/// @brief Returns the high LONG from an INTEGER64
/// @param x A INTEGER64
/// @return An LONG
inline uint32_t HiLong(uint64_t x) {
    return (uint32_t)(x >> 32);
}

/// @brief Returns the low LONG from an INTEGER64
/// @param x A INTEGER64
/// @return An LONG
inline uint32_t LoLong(uint64_t x) {
    return (uint32_t)(x);
}
