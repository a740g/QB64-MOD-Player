'-----------------------------------------------------------------------------------------------------------------------
' Variable type support, size and limits
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

CONST NULL~%% = 0~%%

CONST SINGLE_EPSILON! = 1.19209289550781250000000000000000000E-7
CONST DOUBLE_EPSILON# = 2.22044604925031308084726333618164062E-16

CONST CHARACTER_BITS~%% = 8~%%

DECLARE LIBRARY "Types"
    FUNCTION CBool%% ALIAS "TO_QB_BOOL" (BYVAL x AS _OFFSET)
    FUNCTION CString$ (BYVAL p AS _UNSIGNED _OFFSET)
END DECLARE
