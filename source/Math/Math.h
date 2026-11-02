//----------------------------------------------------------------------------------------------------------------------
// Math routines
// Copyright (c) 2026 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Core/Types.h"
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstdint>
#include <cstdlib>

#define Math_GetRandomMax() RAND_MAX

extern void sub_randomize(double seed, int32_t passed); // QB64's random seed function

/// @brief Set the seed for the random number generator (CRT and QB64)
/// @param seed Any number
inline void Math_SetRandomSeed(uint32_t seed) {
    std::srand(seed);
    sub_randomize(seed, 1);
}

/// @brief Returns a random number between lo and hi (inclusive). Use srand() to seed RNG
/// @param lo The lower limit
/// @param hi The upper limit
/// @return A number between lo and hi
inline int32_t Math_GetRandomBetween(int32_t lo, int32_t hi) {
    return lo + std::rand() % (hi - lo + 1);
}

/// @brief Determines if the given floating point number arg is a not-a-number (NaN) value
/// @param n A single value
/// @return True if the value is NaN
inline constexpr qb_bool Math_IsSingleNaN(float n) {
    return TO_QB_BOOL(std::isnan(n));
}

/// @brief Determines if the given floating point number arg is a not-a-number (NaN) value
/// @param n A double value
/// @return True if the value is NaN
inline constexpr qb_bool Math_IsDoubleNaN(double n) {
    return TO_QB_BOOL(std::isnan(n));
}

/// @brief Returns true if n is even
/// @param n Any integer
/// @return True if n is even
inline constexpr qb_bool Math_IsLongEven(int32_t n) {
    return TO_QB_BOOL((n & 1) == 0);
}

/// @brief Returns true if n is even
/// @param n Any integer
/// @return True if n is even
inline constexpr qb_bool Math_IsInteger64Even(int64_t n) {
    return TO_QB_BOOL((n & 1) == 0);
}

/// @brief Returns true if n is odd.
/// @param n Any integer.
/// @return True if n is odd.
template <std::integral T> inline constexpr qb_bool Math_IsPowerOf2(T n) {
    using UT = std::make_unsigned_t<T>;
    UT un = static_cast<UT>(n);
    return TO_QB_BOOL(un && !(un & (un - 1)));
}

/// @brief Returns the next (ceiling) power of 2 for x. E.g. n = 600 then returns 1024.
/// @param n Any number.
/// @return Next (ceiling) power of 2 for x.
template <std::integral T> inline constexpr T Math_RoundUpToPowerOf2(T n) {
    using UT = std::make_unsigned_t<T>;

    UT un = static_cast<UT>(n - 1);

    if constexpr (sizeof(UT) >= 1) {
        un |= un >> 1;
        un |= un >> 2;
        un |= un >> 4;
    }
    if constexpr (sizeof(UT) >= 2) {
        un |= un >> 8;
    }
    if constexpr (sizeof(UT) >= 4) {
        un |= un >> 16;
    }
    if constexpr (sizeof(UT) >= 8) {
        un |= un >> 32;
    }

    return static_cast<T>(un + 1);
}

/// @brief Returns the next (floor) power of 2 for x. E.g. n = 600 then returns 512.
/// @param n Any number.
/// @return Next (floor) power of 2 for x.
template <std::integral T> static inline constexpr T Math_RoundDownToPowerOf2(T n) {
    using UT = std::make_unsigned_t<T>;

    UT un = static_cast<UT>(n);

    if constexpr (sizeof(UT) >= 1) {
        un |= un >> 1;
        un |= un >> 2;
        un |= un >> 4;
    }
    if constexpr (sizeof(UT) >= 2) {
        un |= un >> 8;
    }
    if constexpr (sizeof(UT) >= 4) {
        un |= un >> 16;
    }
    if constexpr (sizeof(UT) >= 8) {
        un |= un >> 32;
    }

    return static_cast<T>(un - (un >> 1));
}

/// @brief Get the digit from position p in integer n
/// @param n A number
/// @param p The position (where 1 is unit, 2 is tens and so on)
/// @return The digit at position p
inline constexpr int32_t Math_GetDigitFromLong(uint32_t n, uint32_t p) {
    switch (p) {
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

/// @brief Get the digit from position p in integer n
/// @param n A number
/// @param p The position (where 1 is unit, 2 is tens and so on)
/// @return The digit at position p
inline int32_t Math_GetDigitFromInteger64(uint64_t n, uint32_t p) {
    return (n / (uint64_t)__builtin_powi(10, p)) % 10;
}

/// @brief Calculates the average of x and y without overflowing
/// @param x A number
/// @param y A number
/// @return Average of x & y
inline constexpr int32_t Math_AverageLong(int32_t x, int32_t y) {
    return (x & y) + ((x ^ y) / 2);
}

/// @brief Calculates the average of x and y without overflowing
/// @param x A number
/// @param y A number
/// @return Average of x & y
inline constexpr int64_t Math_AverageInteger64(int64_t x, int64_t y) {
    return (x & y) + ((x ^ y) / 2);
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline constexpr int32_t Math_RemapLong(int32_t value, int32_t oldMin, int32_t oldMax, int32_t newMin, int32_t newMax) {
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline constexpr int64_t Math_RemapInteger64(int64_t value, int64_t oldMin, int64_t oldMax, int64_t newMin, int64_t newMax) {
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline constexpr float Math_RemapSingle(float value, float oldMin, float oldMax, float newMin, float newMax) {
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline constexpr double Math_RemapDouble(double value, double oldMin, double oldMax, double newMin, double newMax) {
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Calculate linear interpolation between two floats
/// @param start The starting value (the value at amount = 0)
/// @param end TThe ending value (the value at amount = 1)
/// @param amount An amount (usually 0.0 - 1.0)
/// @return An interpolated value
inline constexpr float Math_LerpSingle(float start, float end, float amount) {
    return start + amount * (end - start);
}

/// @brief Calculate linear interpolation between two doubles
/// @param start The starting value (the value at amount = 0)
/// @param end TThe ending value (the value at amount = 1)
/// @param amount An amount (usually 0.0 - 1.0)
/// @return An interpolated value
inline constexpr double Math_LerpDouble(double start, double end, double amount) {
    return start + amount * (end - start);
}

/// @brief Normalize input value within input range
/// @param value The value to normalize
/// @param start The starting value of the input range
/// @param end The ending value of the input range
/// @return A normalized value between 0.0 and 1.0
inline constexpr float Math_NormalizeSingle(float value, float start, float end) {
    return (value - start) / (end - start);
}

/// @brief Normalize input value within input range
/// @param value The value to normalize
/// @param start The starting value of the input range
/// @param end The ending value of the input range
/// @return A normalized value between 0.0 and 1.0
inline constexpr double Math_NormalizeDouble(double value, double start, double end) {
    return (value - start) / (end - start);
}

/// @brief Wrap input value from min to max
/// @param value The input value that needs to be wrapped
/// @param min The minimum value of the range
/// @param max The maximum value of the range
/// @return The wrapped value
inline float Math_WrapSingle(float value, float min, float max) {
    return value - (max - min) * std::floor((value - min) / (max - min));
}

/// @brief Wrap input value from min to max
/// @param value The input value that needs to be wrapped
/// @param min The minimum value of the range
/// @param max The maximum value of the range
/// @return The wrapped value
inline double Math_WrapDouble(double value, double min, double max) {
    return value - (max - min) * std::floor((value - min) / (max - min));
}

/// @brief Check whether two given floats are almost equal
/// @param x A floating point value
/// @param y A floating point value
/// @return True if both are almost equal
inline qb_bool Math_IsSingleEqual(float x, float y) {
    return TO_QB_BOOL(std::fabs(x - y) <= FLT_EPSILON * std::fmax(1.0f, std::fmax(std::fabs(x), std::fabs(y))));
}

/// @brief Check whether two given floats are almost equal
/// @param x A floating point value
/// @param y A floating point value
/// @return True if both are almost equal
inline qb_bool Math_IsDoubleEqual(double x, double y) {
    return TO_QB_BOOL(std::fabs(x - y) <= DBL_EPSILON * std::fmax(1.0, std::fmax(std::fabs(x), std::fabs(y))));
}

/// @brief This one comes from https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Approximations_that_depend_on_the_floating_point_representation
/// @param x A floating-pointer number
/// @return An approximate square root
inline float Math_FastSqRt(float x) noexcept {
    auto i = reinterpret_cast<int32_t *>(&x);
    *i -= (1 << 23);
    *i >>= 1;
    *i += (1 << 29);
    return x;
}

/// @brief This one comes from https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Reciprocal_of_the_square_root
/// @param x A floating-pointer number
/// @return An approximate square root
inline float Math_FastInvSqRt(float x) noexcept {
    auto xhalf = 0.5f * x;
    auto i = reinterpret_cast<int32_t *>(&x);
    *i = 0x5f375a86 - (*i >> 1);
    x = x * (1.5f - xhalf * x * x);
    return x;
}

/// @brief Performs a multiply-divide operation with full precision and rounding to nearest.
/// @tparam T The data type to use.
/// @param val The value to multiply.
/// @param mul The value to multiply by.
/// @param div The value to divide by.
/// @return The result of the multiply-divide operation.
template <std::unsigned_integral T> inline constexpr T Math_MulDiv(T val, T mul, T div) noexcept {
    using Wide = std::conditional_t<(sizeof(T) < 8), std::uint64_t, unsigned __int128>;

    Wide wval = static_cast<Wide>(val);
    Wide wmul = static_cast<Wide>(mul);
    Wide wdiv = static_cast<Wide>(div);

    Wide result = (wval * wmul + (wdiv >> 1)) / wdiv;

    return static_cast<T>(result);
}

/// @brief Performs a multiply-divide operation with full precision and rounding to nearest.
/// @tparam T The data type to use.
/// @param val The value to multiply.
/// @param mul The value to multiply by.
/// @param div The value to divide by.
/// @return The result of the multiply-divide operation.
template <std::signed_integral T> inline constexpr T Math_MulDiv(T val, T mul, T div) noexcept {
    using Wide = std::conditional_t<(sizeof(T) < 8), std::int64_t, __int128>;

    Wide wval = static_cast<Wide>(val);
    Wide wmul = static_cast<Wide>(mul);
    Wide wdiv = static_cast<Wide>(div);

    Wide sign = (wdiv < 0) ? -1 : 1;
    wval *= sign;
    wmul *= sign;
    wdiv *= sign;

    Wide result = (wval * wmul + (wdiv >> 1)) / wdiv;

    return static_cast<T>(result);
}

/// @brief Check if test is within [lower, upper] range (inclusive).
/// @tparam T Type of test value.
/// @tparam U Type of lower bound.
/// @tparam V Type of upper bound.
/// @param test The value to check.
/// @param lower The lower bound.
/// @param upper The upper bound.
/// @return True if test is within [lower, upper] range (inclusive).
template <std::integral T, std::integral U, std::integral V> inline constexpr qb_bool Math_IsInRange(T test, U lower, V upper) noexcept {
    using UT = std::make_unsigned_t<std::common_type_t<T, U, V>>;
    return TO_QB_BOOL(UT(test - lower) <= UT(upper - lower));
}

/// @brief Check if test is within [lower, upper] range (inclusive).
/// @tparam T Type of test value.
/// @tparam U Type of lower bound.
/// @tparam V Type of upper bound.
/// @param test The value to check.
/// @param lower The lower bound.
/// @param upper The upper bound.
/// @return True if test is within [lower, upper] range (inclusive).
template <std::floating_point T, std::floating_point U, std::floating_point V> inline constexpr qb_bool Math_IsInRange(T test, U lower, V upper) noexcept {
    return TO_QB_BOOL(test >= lower && test <= upper);
}
