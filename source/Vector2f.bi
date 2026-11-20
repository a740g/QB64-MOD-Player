'-----------------------------------------------------------------------------------------------------------------------
' 2D single-precision floating point vector routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

TYPE Vector2f
    x AS SINGLE
    y AS SINGLE
END TYPE

''' @brief Initializes a 2D vector with x and y coordinates.
''' @param x The x-coordinate.
''' @param y The y-coordinate.
''' @param dst The destination Vector2f object.
SUB Vector2f_Initialize (x AS SINGLE, y AS SINGLE, dst AS Vector2f)
    dst.x = x
    dst.y = y
END SUB

''' @brief Sets the components of a 2D vector (alias of Vector2f_Initialize).
''' @param x The x-coordinate.
''' @param y The y-coordinate.
''' @param dst The destination Vector2f object.
SUB Vector2f_Set (x AS SINGLE, y AS SINGLE, dst AS Vector2f)
    dst.x = x
    dst.y = y
END SUB

''' @brief Adds an (x, y) offset to a vector.
''' @param src The source vector.
''' @param x The x offset to add.
''' @param y The y offset to add.
''' @param dst The destination vector.
SUB Vector2f_AddXY (src AS Vector2f, x AS SINGLE, y AS SINGLE, dst AS Vector2f)
    dst.x = src.x + x
    dst.y = src.y + y
END SUB

''' @brief Adds two vectors: dst = a + b.
''' @param a First vector.
''' @param b Second vector.
''' @param dst Destination vector.
SUB Vector2f_Add (a AS Vector2f, b AS Vector2f, dst AS Vector2f)
    dst.x = a.x + b.x
    dst.y = a.y + b.y
END SUB

''' @brief Subtracts vector b from vector a: dst = a - b.
''' @param a First vector.
''' @param b Second vector.
''' @param dst Destination vector.
SUB Vector2f_Subtract (a AS Vector2f, b AS Vector2f, dst AS Vector2f)
    dst.x = a.x - b.x
    dst.y = a.y - b.y
END SUB

''' @brief Multiplies two vectors component-wise: dst = a * b.
''' @param a First vector.
''' @param b Second vector.
''' @param dst Destination vector.
SUB Vector2f_Multiply (a AS Vector2f, b AS Vector2f, dst AS Vector2f)
    dst.x = a.x * b.x
    dst.y = a.y * b.y
END SUB

''' @brief Scales a vector by a scalar factor: dst = src * scalar.
''' @param src Source vector.
''' @param scalar Scaling multiplier.
''' @param dst Destination vector.
SUB Vector2f_Scale (src AS Vector2f, scalar AS SINGLE, dst AS Vector2f)
    dst.x = src.x * scalar
    dst.y = src.y * scalar
END SUB

''' @brief Divides a vector by a scalar factor: dst = src / scalar.
''' @param src Source vector.
''' @param scalar Scaling divisor.
''' @param dst Destination vector.
SUB Vector2f_Divide (src AS Vector2f, scalar AS SINGLE, dst AS Vector2f)
    IF scalar <> 0! THEN
        DIM invScalar AS SINGLE: invScalar = 1! / scalar
        dst.x = src.x * invScalar
        dst.y = src.y * invScalar
    ELSE
        dst.x = 0!
        dst.y = 0!
    END IF
END SUB

''' @brief Negates a vector: dst = -src.
''' @param src Source vector.
''' @param dst Destination vector.
SUB Vector2f_Negate (src AS Vector2f, dst AS Vector2f)
    dst.x = -src.x
    dst.y = -src.y
END SUB

''' @brief Inverts the horizontal direction of a vector.
''' @param src The source vector.
''' @param dst The destination vector.
SUB Vector2f_FlipHorizontal (src AS Vector2f, dst AS Vector2f)
    dst.x = -src.x
    dst.y = src.y
END SUB

''' @brief Inverts the vertical direction of a vector.
''' @param src The source vector.
''' @param dst The destination vector.
SUB Vector2f_FlipVertical (src AS Vector2f, dst AS Vector2f)
    dst.x = src.x
    dst.y = -src.y
END SUB

''' @brief Computes the squared Euclidean length of a vector.
''' @param src The vector.
''' @return The squared length (x*x + y*y).
FUNCTION Vector2f_LengthSquared! (src AS Vector2f)
    Vector2f_LengthSquared = src.x * src.x + src.y * src.y
END FUNCTION

''' @brief Computes the Euclidean length (magnitude) of a vector.
''' @param src The vector.
''' @return The length of the vector.
FUNCTION Vector2f_Length! (src AS Vector2f)
    Vector2f_Length = SQR(src.x * src.x + src.y * src.y)
END FUNCTION

''' @brief Computes the squared distance between two vectors.
''' @param a First vector.
''' @param b Second vector.
''' @return Squared distance between a and b.
FUNCTION Vector2f_DistanceSquared! (a AS Vector2f, b AS Vector2f)
    DIM dx AS SINGLE: dx = a.x - b.x
    DIM dy AS SINGLE: dy = a.y - b.y
    Vector2f_DistanceSquared = dx * dx + dy * dy
END FUNCTION

''' @brief Computes the Euclidean distance between two vectors.
''' @param a First vector.
''' @param b Second vector.
''' @return Distance between a and b.
FUNCTION Vector2f_Distance! (a AS Vector2f, b AS Vector2f)
    DIM dx AS SINGLE: dx = a.x - b.x
    DIM dy AS SINGLE: dy = a.y - b.y
    Vector2f_Distance = SQR(dx * dx + dy * dy)
END FUNCTION

''' @brief Computes the dot product of two vectors.
''' @param a First vector.
''' @param b Second vector.
''' @return Dot product (a.x * b.x + a.y * b.y).
FUNCTION Vector2f_DotProduct! (a AS Vector2f, b AS Vector2f)
    Vector2f_DotProduct = a.x * b.x + a.y * b.y
END FUNCTION

''' @brief Computes the 2D cross product (perp-dot product) of two vectors.
''' @param a First vector.
''' @param b Second vector.
''' @return 2D cross product scalar (a.x * b.y - a.y * b.x).
FUNCTION Vector2f_CrossProduct! (a AS Vector2f, b AS Vector2f)
    Vector2f_CrossProduct = a.x * b.y - a.y * b.x
END FUNCTION

''' @brief Normalizes a vector to unit length.
''' @param src Source vector.
''' @param dst Destination vector (unit length, or zero if src length is 0).
SUB Vector2f_Normalize (src AS Vector2f, dst AS Vector2f)
    DIM l AS SINGLE: l = SQR(src.x * src.x + src.y * src.y)
    IF l > 0! THEN
        DIM invL AS SINGLE: invL = 1! / l
        dst.x = src.x * invL
        dst.y = src.y * invL
    ELSE
        dst.x = 0!
        dst.y = 0!
    END IF
END SUB

''' @brief Linearly interpolates between vector a and vector b: dst = a + (b - a) * t.
''' @param a Starting vector (t = 0).
''' @param b Ending vector (t = 1).
''' @param t Interpolation parameter.
''' @param dst Destination vector.
SUB Vector2f_Lerp (a AS Vector2f, b AS Vector2f, t AS SINGLE, dst AS Vector2f)
    dst.x = a.x + (b.x - a.x) * t
    dst.y = a.y + (b.y - a.y) * t
END SUB

''' @brief Rotates a 2D vector by an angle in radians.
''' @param src Source vector.
''' @param angleRadians Angle of rotation in radians.
''' @param dst Destination vector.
SUB Vector2f_Rotate (src AS Vector2f, angleRadians AS SINGLE, dst AS Vector2f)
    DIM cosA AS SINGLE: cosA = COS(angleRadians)
    DIM sinA AS SINGLE: sinA = SIN(angleRadians)
    DIM newX AS SINGLE: newX = src.x * cosA - src.y * sinA
    DIM newY AS SINGLE: newY = src.x * sinA + src.y * cosA
    dst.x = newX
    dst.y = newY
END SUB

''' @brief Reflects a vector off a surface with the given unit normal: dst = src - 2 * dot(src, normal) * normal.
''' @param src Incident vector.
''' @param normal Surface unit normal vector.
''' @param dst Destination reflected vector.
SUB Vector2f_Reflect (src AS Vector2f, normal AS Vector2f, dst AS Vector2f)
    DIM dot2 AS SINGLE: dot2 = 2! * (src.x * normal.x + src.y * normal.y)
    dst.x = src.x - dot2 * normal.x
    dst.y = src.y - dot2 * normal.y
END SUB

''' @brief Returns the angle of a 2D vector in radians (-pi to pi).
''' @param src The vector.
''' @return Angle in radians.
FUNCTION Vector2f_Angle! (src AS Vector2f)
    Vector2f_Angle = _ATAN2(src.y, src.x)
END FUNCTION

''' @brief Creates a 2D vector from an angle and length.
''' @param angleRadians Angle in radians.
''' @param length Length/magnitude of the vector.
''' @param dst Destination vector.
SUB Vector2f_FromAngle (angleRadians AS SINGLE, length AS SINGLE, dst AS Vector2f)
    dst.x = COS(angleRadians) * length
    dst.y = SIN(angleRadians) * length
END SUB

''' @brief Checks if a vector is null (0, 0).
''' @param src The vector to check.
''' @return _TRUE if both components are 0, _FALSE otherwise.
FUNCTION Vector2f_IsNull%% (src AS Vector2f)
    Vector2f_IsNull = src.x = 0! _ANDALSO src.y = 0!
END FUNCTION

''' @brief Checks if two vectors are equal.
''' @param a First vector.
''' @param b Second vector.
''' @return _TRUE if both components match, _FALSE otherwise.
FUNCTION Vector2f_IsEqual%% (a AS Vector2f, b AS Vector2f)
    Vector2f_IsEqual = a.x = b.x _ANDALSO a.y = b.y
END FUNCTION

''' @brief Clamps the magnitude of a vector to a maximum length.
''' @param src Source vector.
''' @param maxLength Maximum allowed length.
''' @param dst Destination vector.
SUB Vector2f_ClampLength (src AS Vector2f, maxLength AS SINGLE, dst AS Vector2f)
    DIM sqrLen AS SINGLE: sqrLen = src.x * src.x + src.y * src.y
    IF sqrLen > maxLength * maxLength _ANDALSO sqrLen > 0! THEN
        DIM scaleFactor AS SINGLE: scaleFactor = maxLength / SQR(sqrLen)
        dst.x = src.x * scaleFactor
        dst.y = src.y * scaleFactor
    ELSE
        dst.x = src.x
        dst.y = src.y
    END IF
END SUB
