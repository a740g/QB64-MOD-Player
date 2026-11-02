'-----------------------------------------------------------------------------------------------------------------------
' 2D Bounding Box (integer) routines
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'Vector2i.bi'

TYPE Bounds2i
    lt AS Vector2i
    rb AS Vector2i
END TYPE

DECLARE LIBRARY "Bounds2i"
    SUB Bounds2i_Reset (dst AS Bounds2i)
    SUB Bounds2i_Initialize (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG, dst AS Bounds2i)
    SUB Bounds2i_InitializeFromPositionSize (position AS Vector2i, size AS Vector2i, dst AS Bounds2i)
    SUB Bounds2i_InitializeFromPoints (p1 AS Vector2i, p2 AS Vector2i, dst AS Bounds2i)
    FUNCTION Bounds2i_IsEmpty%% (src AS Bounds2i)
    FUNCTION Bounds2i_IsValid%% (src AS Bounds2i)
    FUNCTION Bounds2i_HasNoWidth%% (src AS Bounds2i)
    FUNCTION Bounds2i_HasNoHeight%% (src AS Bounds2i)
    FUNCTION Bounds2i_GetWidth~& (src AS Bounds2i)
    FUNCTION Bounds2i_GetHeight~& (src AS Bounds2i)
    SUB Bounds2i_GetCenter (src AS Bounds2i, dst AS Vector2i)
    SUB Bounds2i_GetSize (src AS Bounds2i, dst AS Vector2i)
    SUB Bounds2i_Sanitize (src AS Bounds2i)
    SUB Bounds2i_SetRightTop (point AS Vector2i, dst AS Bounds2i)
    SUB Bounds2i_SetRightTopXY (BYVAL x AS LONG, BYVAL y AS LONG, dst AS Bounds2i)
    SUB Bounds2i_SetLeftBottom (point AS Vector2i, dst AS Bounds2i)
    SUB Bounds2i_SetLeftBottomXY (BYVAL x AS LONG, BYVAL y AS LONG, dst AS Bounds2i)
    SUB Bounds2i_GetRightTop (src AS Bounds2i, dst AS Vector2i)
    SUB Bounds2i_GetLeftBottom (src AS Bounds2i, dst AS Vector2i)
    FUNCTION Bounds2i_GetArea~& (src AS Bounds2i)
    FUNCTION Bounds2i_GetPerimeter~& (src AS Bounds2i)
    FUNCTION Bounds2i_GetDiagonalLength~& (src AS Bounds2i)
    FUNCTION Bounds2i_HasSameArea%% (src1 AS Bounds2i, src2 AS Bounds2i)
    SUB Bounds2i_Inflate (src AS Bounds2i, BYVAL x AS LONG, BYVAL y AS LONG, dst AS Bounds2i)
    SUB Bounds2i_InflateByVector (src AS Bounds2i, vector AS Vector2i, dst AS Bounds2i)
    SUB Bounds2i_Deflate (src AS Bounds2i, BYVAL x AS LONG, BYVAL y AS LONG, dst AS Bounds2i)
    SUB Bounds2i_DeflateByVector (src AS Bounds2i, vector AS Vector2i, dst AS Bounds2i)
    SUB Bounds2i_IncludePoint (src AS Bounds2i, point AS Vector2i, dst AS Bounds2i)
    SUB Bounds2i_Translate (src AS Bounds2i, BYVAL x AS LONG, BYVAL y AS LONG, dst AS Bounds2i)
    SUB Bounds2i_TranslateByVector (src AS Bounds2i, vector AS Vector2i, dst AS Bounds2i)
    FUNCTION Bounds2i_ContainsXY%% (src AS Bounds2i, BYVAL x AS LONG, BYVAL y AS LONG)
    FUNCTION Bounds2i_ContainsPoint%% (src AS Bounds2i, point AS Vector2i)
    FUNCTION Bounds2i_ContainsBounds%% (src1 AS Bounds2i, src2 AS Bounds2i)
    FUNCTION Bounds2i_Intersects%% (src1 AS Bounds2i, src2 AS Bounds2i)
    SUB Bounds2i_MakeUnion (src1 AS Bounds2i, src2 AS Bounds2i, dst AS Bounds2i)
    SUB Bounds2i_MakeIntersection (src1 AS Bounds2i, src2 AS Bounds2i, dst AS Bounds2i)
END DECLARE
