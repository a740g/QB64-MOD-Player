'-----------------------------------------------------------------------------------------------------------------------
' Bitwise operation routines
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

DECLARE LIBRARY "BitwiseOps"
    FUNCTION LeftShiftOneCount~& (BYVAL n AS _UNSIGNED LONG)
    FUNCTION ReverseBitsByte~%% (BYVAL n AS _UNSIGNED _BYTE)
    FUNCTION ReverseBitsInteger~% (BYVAL n AS _UNSIGNED INTEGER)
    FUNCTION ReverseBitsLong~& (BYVAL n AS _UNSIGNED LONG)
    FUNCTION ReverseBitsInteger64~&& (BYVAL n AS _UNSIGNED _INTEGER64)
    FUNCTION FindFirstBitSetLong& ALIAS "__builtin_ffs" (BYVAL x AS _UNSIGNED LONG)
    FUNCTION FindFirstBitSetInteger64& ALIAS "__builtin_ffsll" (BYVAL x AS _UNSIGNED _INTEGER64)
    FUNCTION CountLeadingZerosLong& ALIAS "__builtin_clz" (BYVAL x AS _UNSIGNED LONG)
    FUNCTION CountLeadingZerosInteger64& ALIAS "__builtin_clzll" (BYVAL x AS _UNSIGNED _INTEGER64)
    FUNCTION CountTrailingZerosLong& ALIAS "__builtin_ctz" (BYVAL x AS _UNSIGNED LONG)
    FUNCTION CountTrailingZerosInteger64& ALIAS "__builtin_ctzll" (BYVAL x AS _UNSIGNED _INTEGER64)
    FUNCTION PopulationCountLong& ALIAS "__builtin_popcount" (BYVAL x AS _UNSIGNED LONG)
    FUNCTION PopulationCountInteger64& ALIAS "__builtin_popcountll" (BYVAL x AS _UNSIGNED _INTEGER64)
    FUNCTION ByteSwapInteger~% ALIAS "__builtin_bswap16" (BYVAL x AS _UNSIGNED INTEGER)
    FUNCTION ByteSwapLong~& ALIAS "__builtin_bswap32" (BYVAL x AS _UNSIGNED LONG)
    FUNCTION ByteSwapInteger64~&& ALIAS "__builtin_bswap64" (BYVAL x AS _UNSIGNED _INTEGER64)
    FUNCTION MakeFourCC~& (BYVAL ch0 AS _UNSIGNED _BYTE, BYVAL ch1 AS _UNSIGNED _BYTE, BYVAL ch2 AS _UNSIGNED _BYTE, BYVAL ch3 AS _UNSIGNED _BYTE)
    FUNCTION MakeByte~%% (BYVAL x AS _UNSIGNED _BYTE, BYVAL y AS _UNSIGNED _BYTE)
    FUNCTION MakeInteger~% (BYVAL x AS _UNSIGNED _BYTE, BYVAL y AS _UNSIGNED _BYTE)
    FUNCTION MakeLong~& (BYVAL x AS _UNSIGNED INTEGER, BYVAL y AS _UNSIGNED INTEGER)
    FUNCTION MakeInteger64~&& (BYVAL x AS _UNSIGNED LONG, BYVAL y AS _UNSIGNED LONG)
    FUNCTION HiNibble~%% (BYVAL x AS _UNSIGNED _BYTE)
    FUNCTION LoNibble~%% (BYVAL x AS _UNSIGNED _BYTE)
    FUNCTION HiByte~%% (BYVAL x AS _UNSIGNED INTEGER)
    FUNCTION LoByte~%% (BYVAL x AS _UNSIGNED INTEGER)
    FUNCTION HiInteger~% (BYVAL x AS _UNSIGNED LONG)
    FUNCTION LoInteger~% (BYVAL x AS _UNSIGNED LONG)
    FUNCTION HiLong~& (BYVAL x AS _UNSIGNED _INTEGER64)
    FUNCTION LoLong~& (BYVAL x AS _UNSIGNED _INTEGER64)
END DECLARE
