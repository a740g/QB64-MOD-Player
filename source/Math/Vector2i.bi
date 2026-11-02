'-----------------------------------------------------------------------------------------------------------------------
' 2D Vector (integer) routines
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'

TYPE Vector2i
    x AS LONG
    y AS LONG
END TYPE

DECLARE LIBRARY "Vector2i"
    SUB Vector2i_Reset (dst AS Vector2i)
    SUB Vector2i_Initialize (BYVAL x AS LONG, BYVAL y AS LONG, dst AS Vector2i)
    FUNCTION Vector2i_IsNull%% (src AS Vector2i)
    SUB Vector2i_Add (src1 AS Vector2i, src2 AS Vector2i, dst AS Vector2i)
    SUB Vector2i_AddValue (src AS Vector2i, BYVAL value AS LONG, dst AS Vector2i)
    SUB Vector2i_AddXY (src AS Vector2i, BYVAL x AS LONG, BYVAL y AS LONG, dst AS Vector2i)
    SUB Vector2i_Subtract (src1 AS Vector2i, src2 AS Vector2i, dst AS Vector2i)
    SUB Vector2i_SubtractValue (src AS Vector2i, BYVAL value AS LONG, dst AS Vector2i)
    SUB Vector2i_SubtractXY (src AS Vector2i, BYVAL x AS LONG, BYVAL y AS LONG, dst AS Vector2i)
    SUB Vector2i_Multiply (src1 AS Vector2i, src2 AS Vector2i, dst AS Vector2i)
    SUB Vector2i_MultiplyValue (src AS Vector2i, BYVAL value AS LONG, dst AS Vector2i)
    SUB Vector2i_MultiplyXY (src AS Vector2i, BYVAL x AS LONG, BYVAL y AS LONG, dst AS Vector2i)
    SUB Vector2i_Divide (src1 AS Vector2i, src2 AS Vector2i, dst AS Vector2i)
    SUB Vector2i_DivideValue (src AS Vector2i, BYVAL value AS LONG, dst AS Vector2i)
    SUB Vector2i_DivideXY (src AS Vector2i, BYVAL x AS LONG, BYVAL y AS LONG, dst AS Vector2i)
    SUB Vector2i_Negate (src AS Vector2i, dst AS Vector2i)
    FUNCTION Vector2i_GetLengthSquared~& (src AS Vector2i)
    FUNCTION Vector2i_GetLength~& (src AS Vector2i)
    FUNCTION Vector2i_GetDistanceSquared~& (src1 AS Vector2i, src2 AS Vector2i)
    FUNCTION Vector2i_GetDistance~& (src1 AS Vector2i, src2 AS Vector2i)
    SUB Vector2i_GetSizeVector (src1 AS Vector2i, src2 AS Vector2i, dst AS Vector2i)
    FUNCTION Vector2i_GetArea~& (src AS Vector2i)
    FUNCTION Vector2i_GetPerimeter~& (src AS Vector2i)
    FUNCTION Vector2i_GetDotProduct~& (src1 AS Vector2i, src2 AS Vector2i)
    FUNCTION Vector2i_GetCrossProduct~& (src1 AS Vector2i, src2 AS Vector2i)
    SUB Vector2i_TurnLeft (src AS Vector2i, dst AS Vector2i)
    SUB Vector2i_TurnRight (src AS Vector2i, dst AS Vector2i)
    SUB Vector2i_FlipVertical (src AS Vector2i, dst AS Vector2i)
    SUB Vector2i_FlipHorizontal (src AS Vector2i, dst AS Vector2i)
    SUB Vector2i_Lerp (src1 AS Vector2i, src2 AS Vector2i, BYVAL t AS SINGLE, dst AS Vector2i)
    SUB Vector2i_Reflect (src AS Vector2i, normal AS Vector2i, dst AS Vector2i)
    SUB Vector2i_Rotate (src AS Vector2i, BYVAL angle AS SINGLE, dst AS Vector2i)
    SUB Vector2i_MoveTowards (src AS Vector2i, target AS Vector2i, BYVAL maxDistance AS LONG, dst AS Vector2i)
    SUB Vector2i_Clamp (src AS Vector2i, min AS Vector2i, max AS Vector2i, dst AS Vector2i)
    SUB Vector2i_ClampValue (src AS Vector2i, BYVAL min AS LONG, BYVAL max AS LONG, dst AS Vector2i)
END DECLARE
