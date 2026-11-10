'-----------------------------------------------------------------------------------------------------------------------
' Math functions
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

''' @brief Returns the zero-based index of the highest set bit. Given a non-zero unsigned integer, returns the position of the
''' most significant set bit (MSB), counting from the least significant bit as position 0.
''' @param n The value to examine.
''' @return The index of the highest set bit. Returns 0 if n is 0.
FUNCTION HighestSetBitIndex~& (n AS _UNSIGNED LONG)
    DECLARE LIBRARY
        FUNCTION __builtin_clz (BYVAL n AS _UNSIGNED LONG)
    END DECLARE

    IF n THEN
        HighestSetBitIndex = (8 * _SIZE_OF_LONG - 1) - __builtin_clz(n)
    END IF
END FUNCTION
