'-----------------------------------------------------------------------------------------------------------------------
' Common header
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF VERSION < 4.5.0 THEN
    $ERROR 'This requires the latest version of QB64-PE from https://github.com/QB64-Phoenix-Edition/QB64pe/releases/latest'
$END IF

$INCLUDEONCE

$IF TOOLBOX64_STRICT = DEFINED AND TOOLBOX64_STRICT = TRUE THEN
    ' All identifiers must default to long (32-bits). This results in fastest code execution on x86 & x64.
    _DEFINE A-Z AS LONG

    ' Force all arrays to be defined (technically not required, since we use _EXPLICIT below).
    OPTION _EXPLICITARRAY

    ' Force all variables to be defined.
    OPTION _EXPLICIT

    ' All arrays should be static. If dynamic arrays are required, then use "REDIM".
    '$STATIC

    ' Start array lower bound from 1. If 0 is required, then use the syntax [RE]DIM (0 To {X}) AS {TYPE}.
    OPTION BASE 1
$END IF

' Some of the types below do not have a "home" yet and should be moved to appropriate files later
TYPE Vector3f
    x AS SINGLE
    y AS SINGLE
    z AS SINGLE
END TYPE

DECLARE LIBRARY "Common"
    FUNCTION Compiler_GetFunctionName$
    FUNCTION Compiler_GetPrettyFunctionName$
END DECLARE
