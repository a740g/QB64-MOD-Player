//--------------------------------------------------------------------------------------------------------------------------------------------------------------
//
// QB64 support routines
//
// Copyright (c) 2022 Samuel Gomes
//
// Lot of these came from:
// https://graphics.stanford.edu/~seander/bithacks.html
// https://bits.stephan-brumme.com/
// http://aggregate.org/MAGIC/
// http://www.azillionmonkeys.com/qed/asmexample.html
// https://dspguru.com/dsp/tricks/
// http://programming.sirrida.de/
//
//--------------------------------------------------------------------------------------------------------------------------------------------------------------

#include <stdint.h>
#include <stdlib.h>

/// @brief Returns RAND_MAX for use with CRT rand()
/// @return RAND_MAX
size_t RandomMax()
{
    return RAND_MAX;
}

/// @brief Casts a QB64 OFFSET to an unsigned integer
/// @param p A pointer
/// @return Pointer value
uintptr_t CLngPtr(void *p)
{
    return (uintptr_t)p;
}

/// @brief Peeks a BYTE (8-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @return BYTE value
uint8_t PeekByteAtOffset(void *p, uintptr_t o)
{
    return *((uint8_t *)p + o);
}

/// @brief Poke a BYTE (8-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @param n BYTE value
void PokeByteAtOffset(void *p, uintptr_t o, uint8_t n)
{
    *((uint8_t *)p + o) = n;
}

/// @brief Peek an INTEGER (16-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @return INTEGER value
uint16_t PeekIntegerAtOffset(void *p, uintptr_t o)
{
    return *((uint16_t *)p + o);
}

/// @brief Poke an INTEGER (16-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @param n INTEGER value
void PokeIntegerAtOffset(void *p, uintptr_t o, uint16_t n)
{
    *((uint16_t *)p + o) = n;
}

/// @brief Peek a LONG (32-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @return LONG value
uint32_t PeekLongAtOffset(void *p, uintptr_t o)
{
    return *((uint32_t *)p + o);
}

/// @brief Poke a LONG (32-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @param n LONG value
void PokeLongAtOffset(void *p, uintptr_t o, uint32_t n)
{
    *((uint32_t *)p + o) = n;
}

/// @brief Peek a INTEGER64 (64-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @return INTEGER64 value
uint64_t PeekInteger64AtOffset(void *p, uintptr_t o)
{
    return *((uint64_t *)p + o);
}

/// @brief Poke a INTEGER64 (64-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @param n INTEGER64 value
void PokeInteger64AtOffset(void *p, uintptr_t o, uint64_t n)
{
    *((uint64_t *)p + o) = n;
}

/// @brief Peek a SINGLE (32-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @return SINGLE value
float PeekSingleAtOffset(void *p, uintptr_t o)
{
    return *((float *)p + o);
}

/// @brief Poke a SINGLE (32-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @param n SINGLE value
void PokeSingleAtOffset(void *p, uintptr_t o, float n)
{
    *((float *)p + o) = n;
}

/// @brief Peek a DOUBLE (64-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @return DOUBLE value
double PeekDoubleAtOffset(void *p, uintptr_t o)
{
    return *((double *)p + o);
}

/// @brief Poke a DOUBLE (64-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @param n DOUBLE value
void PokeDoubleAtOffset(void *p, uintptr_t o, double n)
{
    *((double *)p + o) = n;
}

/// @brief Peek an OFFSET (32/64-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @return DOUBLE value
void *PeekOffsetAtOffset(void *p, uintptr_t o)
{
    return (void *)*((uintptr_t *)p + o);
}

/// @brief Poke an OFFSET (32/64-bits) value at p + o
/// @param p Pointer base
/// @param o Offset from base
/// @param n DOUBLE value
void PokeOffsetAtOffset(void *p, uintptr_t o, void *n)
{
    *((uintptr_t *)p + o) = (uintptr_t)n;
}

/// @brief Peek a character value in a string. Zero based, faster and unsafe than ASC
/// @param s A QB64 string
/// @param o Offset from base (zero based)
/// @return The ASCII character at position o
uint8_t PeekString(char *s, uintptr_t o)
{
    return s[o];
}

/// @brief Poke a character value in a string. Zero based, faster and unsafe than ASC
/// @param s A QB64 string
/// @param o Offset from base (zero based)
/// @param n The ASCII character at position o
void PokeString(char *s, uintptr_t o, uint8_t n)
{
    s[o] = n;
}

/// @brief Returns the next (ceiling) power of 2 for x. E.g. n = 600 then returns 1024
/// @param n Any number
/// @return Next (ceiling) power of 2 for x
uint32_t NextPowerOfTwo(uint32_t n)
{
    --n;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return ++n;
}

/// @brief Returns the previous (floor) power of 2 for x. E.g. n = 600 then returns 512
/// @param n Any number
/// @return Previous (floor) power of 2 for x
uint32_t PreviousPowerOfTwo(uint32_t n)
{
    n |= (n >> 1);
    n |= (n >> 2);
    n |= (n >> 4);
    n |= (n >> 8);
    n |= (n >> 16);
    return n - (n >> 1);
}

/// @brief Returns the number using which we need to shift 1 left to get n. E.g. n = 2 then returns 1
/// @param n A power of 2 number
/// @return A number (x) that we use in 1 << x to get n
uint32_t LShOneCount(uint32_t n)
{
    return n == 0 ? 0 : (CHAR_BIT * sizeof(n)) - 1 - __builtin_clz(n);
}

/// @brief Reverses bits in a number
/// @param n The number
/// @param bytes The sizeof(number)
/// @return A number with bits reversed
size_t ReverseBits(size_t n, uint32_t bytes)
{
    n = __builtin_bswap64(n);
    n >>= ((sizeof(size_t) - bytes) * 8);
    n = ((n & 0xaaaaaaaaaaaaaaaa) >> 1) | ((n & 0x5555555555555555) << 1);
    n = ((n & 0xcccccccccccccccc) >> 2) | ((n & 0x3333333333333333) << 2);
    n = ((n & 0xf0f0f0f0f0f0f0f0) >> 4) | ((n & 0x0f0f0f0f0f0f0f0f) << 4);
    return n;
}

/// @brief Returns a random number between lo and hi (inclusive). Use srand() to seed RNG
/// @param lo The lower limit
/// @param hi The upper limit
/// @return A number between lo and hi
int32_t RandomBetween(int32_t lo, int32_t hi)
{
    return (rand() % (hi - lo + 1)) + lo;
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
int32_t ClampLong(int32_t n, int32_t lo, int32_t hi)
{
    return n > hi ? hi : (n < lo ? lo : n);
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
int64_t ClampInteger64(int64_t n, int64_t lo, int64_t hi)
{
    return n > hi ? hi : (n < lo ? lo : n);
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
float ClampSingle(float n, float lo, float hi)
{
    return n > hi ? hi : (n < lo ? lo : n);
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
double ClampDouble(double n, double lo, double hi)
{
    return n > hi ? hi : (n < lo ? lo : n);
}

/// @brief Get the digit from position p in integer n
/// @param n A number
/// @param p The position (where 1 is unit, 2 is tens and so on)
/// @return The digit at position p
int32_t GetDigitFromPosition(uint32_t n, uint32_t p)
{
    switch (p)
    {
    case 0:
        break;
    case 1:
        n /= 10;
        break;
    case 2:
        n /= 100;
        break;
    case 3:
        n /= 1000;
        break;
    case 4:
        n /= 10000;
        break;
    case 5:
        n /= 100000;
        break;
    case 6:
        n /= 1000000;
        break;
    case 7:
        n /= 10000000;
        break;
    case 8:
        n /= 100000000;
        break;
    case 9:
        n /= 1000000000;
        break;
    }
    return n % 10;
}

/// @brief Calculates the average of x and y without overflowing
/// @param x A number
/// @param y A number
/// @return Average of x & y
int32_t AverageLong(int32_t x, int32_t y)
{
    return (x & y) + ((x ^ y) / 2);
}

/// @brief Calculates the average of x and y without overflowing
/// @param x A number
/// @param y A number
/// @return Average of x & y
int64_t AverageInteger64(int64_t x, int64_t y)
{
    return (x & y) + ((x ^ y) / 2);
}

/// @brief Check if n is a power of 2
/// @param n A number
/// @return True if n is a power of 2
int32_t IsPowerOfTwo(uint32_t n)
{
    return n && !(n & (n - 1)) ? -1 : 0;
}
