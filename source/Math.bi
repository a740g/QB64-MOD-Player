'-----------------------------------------------------------------------------------------------------------------------
' Math functions
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

''' @brief Returns the zero-based index of the highest set bit. Given a non-zero unsigned integer, returns the position of the
''' most significant set bit (MSB), counting from the least significant bit as position 0.
''' @param n The value to examine.
''' @return The index of the highest set bit. Returns 0 if n is 0.
FUNCTION Math_HighestSetBitIndex~& (n AS _UNSIGNED LONG)
    DECLARE LIBRARY
        FUNCTION __builtin_clz (BYVAL n AS _UNSIGNED LONG)
    END DECLARE

    IF n THEN
        Math_HighestSetBitIndex = (8 * _SIZE_OF_LONG - 1) - __builtin_clz(n)
    END IF
END FUNCTION

''' @brief Rounds down an unsigned long integer to the nearest power of 2.
''' @param n The value to round down.
''' @return The nearest power of 2 less than or equal to n, or 0 if n is 0.
FUNCTION Math_RoundDownLongToPowerOf2~& (n AS _UNSIGNED LONG)
    IF n THEN Math_RoundDownLongToPowerOf2 = _SHL(1~&, Math_HighestSetBitIndex(n))
END FUNCTION

''' @brief Returns a random long integer between lo and hi, inclusive.
''' @param lo Lower bound.
''' @param hi Upper bound.
''' @return A random integer in the range [lo, hi].
FUNCTION Math_GetRandomBetween& (lo AS LONG, hi AS LONG)
    Math_GetRandomBetween = INT(RND * (hi - lo + 1)) + lo
END FUNCTION
