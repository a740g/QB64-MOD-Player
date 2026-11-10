'-----------------------------------------------------------------------------------------------------------------------
' 2D integer vector routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

TYPE Vector2i
    x AS LONG
    y AS LONG
END TYPE

''' @brief Initializes a 2D integer vector with x and y coordinates.
''' @param x The x-coordinate.
''' @param y The y-coordinate.
''' @param dst The destination Vector2i object.
SUB Vector2i_Initialize (x AS LONG, y AS LONG, dst AS Vector2i)
    dst.x = x
    dst.y = y
END SUB

''' @brief Adds an (x, y) offset to a vector.
''' @param src The source vector.
''' @param x The x offset to add.
''' @param y The y offset to add.
''' @param dst The destination vector.
SUB Vector2i_AddXY (src AS Vector2i, x AS LONG, y AS LONG, dst AS Vector2i)
    dst.x = src.x + x
    dst.y = src.y + y
END SUB

''' @brief Inverts the horizontal direction of a vector.
''' @param src The source vector.
''' @param dst The destination vector.
SUB Vector2i_FlipHorizontal (src AS Vector2i, dst AS Vector2i)
    dst.x = -src.x
    dst.y = src.y
END SUB

''' @brief Inverts the vertical direction of a vector.
''' @param src The source vector.
''' @param dst The destination vector.
SUB Vector2i_FlipVertical (src AS Vector2i, dst AS Vector2i)
    dst.x = src.x
    dst.y = -src.y
END SUB

''' @brief Checks if a vector is null (0, 0).
''' @param src The vector to check.
''' @return _TRUE if both x and y are 0, _FALSE otherwise.
FUNCTION Vector2i_IsNull%% (src AS Vector2i)
    Vector2i_IsNull = src.x = 0 _ANDALSO src.y = 0
END FUNCTION
