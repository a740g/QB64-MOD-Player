'-----------------------------------------------------------------------------------------------------------------------
' 2D single-precision floating point bounding box routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Vector2f.bi'

TYPE Bounds2f
    lt AS Vector2f ' Left-Top
    rb AS Vector2f ' Right-Bottom
END TYPE

''' @brief Initializes a bounding box with coordinates.
''' @param x1 The left coordinate.
''' @param y1 The top coordinate.
''' @param x2 The right coordinate.
''' @param y2 The bottom coordinate.
''' @param dst Destination Bounds2f object.
SUB Bounds2f_Initialize (x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE, dst AS Bounds2f)
    dst.lt.x = x1
    dst.lt.y = y1
    dst.rb.x = x2
    dst.rb.y = y2
END SUB

''' @brief Initializes a bounding box with two Vector2f points.
''' @param lt Left-top point.
''' @param rb Right-bottom point.
''' @param dst Destination Bounds2f object.
SUB Bounds2f_InitializeWithVectors (lt AS Vector2f, rb AS Vector2f, dst AS Bounds2f)
    dst.lt = lt
    dst.rb = rb
END SUB

''' @brief Sets coordinates of a bounding box (alias of Bounds2f_Initialize).
''' @param x1 The left coordinate.
''' @param y1 The top coordinate.
''' @param x2 The right coordinate.
''' @param y2 The bottom coordinate.
''' @param dst Destination Bounds2f object.
SUB Bounds2f_Set (x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE, dst AS Bounds2f)
    dst.lt.x = x1
    dst.lt.y = y1
    dst.rb.x = x2
    dst.rb.y = y2
END SUB

''' @brief Sanitizes a bounding box ensuring lt.x <= rb.x and lt.y <= rb.y.
''' @param b The bounding box to sanitize in-place.
SUB Bounds2f_Sanitize (b AS Bounds2f)
    IF b.lt.x > b.rb.x THEN SWAP b.lt.x, b.rb.x
    IF b.lt.y > b.rb.y THEN SWAP b.lt.y, b.rb.y
END SUB

''' @brief Returns the width of a sanitized bounding box.
''' @param b The bounding box.
''' @return The width (rb.x - lt.x).
FUNCTION Bounds2f_GetWidth! (b AS Bounds2f)
    Bounds2f_GetWidth = b.rb.x - b.lt.x
END FUNCTION

''' @brief Returns the height of a sanitized bounding box.
''' @param b The bounding box.
''' @return The height (rb.y - lt.y).
FUNCTION Bounds2f_GetHeight! (b AS Bounds2f)
    Bounds2f_GetHeight = b.rb.y - b.lt.y
END FUNCTION

''' @brief Tests if a point lies within a bounding box (assumes sanitized).
''' @param b The bounding box.
''' @param pt The point to test.
''' @return True if the point is inside or on the boundaries of the bounding box.
FUNCTION Bounds2f_ContainsPoint%% (b AS Bounds2f, pt AS Vector2f)
    Bounds2f_ContainsPoint = pt.x >= b.lt.x _ANDALSO pt.x <= b.rb.x _ANDALSO pt.y >= b.lt.y _ANDALSO pt.y <= b.rb.y
END FUNCTION

''' @brief Tests if coordinate (x, y) lies within a bounding box (assumes sanitized).
''' @param b The bounding box.
''' @param x The x-coordinate.
''' @param y The y-coordinate.
''' @return True if the point is inside or on the boundaries of the bounding box.
FUNCTION Bounds2f_ContainsPointXY%% (b AS Bounds2f, x AS SINGLE, y AS SINGLE)
    Bounds2f_ContainsPointXY = x >= b.lt.x _ANDALSO x <= b.rb.x _ANDALSO y >= b.lt.y _ANDALSO y <= b.rb.y
END FUNCTION

''' @brief Tests if two bounding boxes intersect (assumes sanitized).
''' @param a First bounding box.
''' @param b Second bounding box.
''' @return True if the two bounding boxes overlap.
FUNCTION Bounds2f_Intersects%% (a AS Bounds2f, b AS Bounds2f)
    Bounds2f_Intersects = a.lt.x <= b.rb.x _ANDALSO a.rb.x >= b.lt.x _ANDALSO a.lt.y <= b.rb.y _ANDALSO a.rb.y >= b.lt.y
END FUNCTION
