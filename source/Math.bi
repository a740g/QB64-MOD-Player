'-----------------------------------------------------------------------------------------------------------------------
' Math functions
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

CONST NULL~%% = 0~%%

CONST SINGLE_EPSILON! = 1.19209289550781250000000000000000000E-7
CONST DOUBLE_EPSILON# = 2.22044604925031308084726333618164062E-16

CONST CHARACTER_BITS& = 8&

DECLARE LIBRARY
    ''' @brief Counts the number of leading zero bits in an unsigned 32-bit integer.
    ''' @param n The 32-bit unsigned integer to examine.
    ''' @return The number of leading zero bits (0 to 32).
    FUNCTION Math_CountLeadingZeros~& ALIAS "__builtin_clz" (BYVAL n AS _UNSIGNED LONG)
END DECLARE

''' @brief Returns the zero-based index of the highest set bit. Given a non-zero unsigned integer, returns the position of the
''' most significant set bit (MSB), counting from the least significant bit as position 0.
''' @param n The value to examine.
''' @return The index of the highest set bit. Returns 0 if n is 0.
FUNCTION Math_GetHighestSetBitIndex~& (n AS _UNSIGNED LONG)
    IF n THEN
        Math_GetHighestSetBitIndex = (CHARACTER_BITS * _SIZE_OF_LONG - 1) - Math_CountLeadingZeros(n)
    END IF
END FUNCTION

''' @brief Rounds down an unsigned long integer to the nearest power of 2.
''' @param n The value to round down.
''' @return The nearest power of 2 less than or equal to n, or 0 if n is 0.
FUNCTION Math_RoundDownToPowerOf2~& (n AS _UNSIGNED LONG)
    IF n THEN
        Math_RoundDownToPowerOf2 = _SHL(1~&, (CHARACTER_BITS * _SIZE_OF_LONG - 1) - Math_CountLeadingZeros(n))
    END IF
END FUNCTION

''' @brief Returns a random long integer between lo and hi, inclusive.
''' @param lo Lower bound.
''' @param hi Upper bound.
''' @return A random integer in the range [lo, hi].
FUNCTION Math_GetRandomBetween& (lo AS LONG, hi AS LONG)
    Math_GetRandomBetween = INT(RND * (hi - lo + 1)) + lo
END FUNCTION
