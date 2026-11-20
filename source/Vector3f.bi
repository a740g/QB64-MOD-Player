'-----------------------------------------------------------------------------------------------------------------------
' 3D single-precision floating point vector routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

TYPE Vector3f
    x AS SINGLE
    y AS SINGLE
    z AS SINGLE
END TYPE

''' @brief Initializes a 3D vector with x, y, and z coordinates.
''' @param x The x-coordinate.
''' @param y The y-coordinate.
''' @param z The z-coordinate.
''' @param dst The destination Vector3f object.
SUB Vector3f_Initialize (x AS SINGLE, y AS SINGLE, z AS SINGLE, dst AS Vector3f)
    dst.x = x
    dst.y = y
    dst.z = z
END SUB

''' @brief Sets the components of a 3D vector (alias of Vector3f_Initialize).
''' @param x The x-coordinate.
''' @param y The y-coordinate.
''' @param z The z-coordinate.
''' @param dst The destination Vector3f object.
SUB Vector3f_Set (x AS SINGLE, y AS SINGLE, z AS SINGLE, dst AS Vector3f)
    dst.x = x
    dst.y = y
    dst.z = z
END SUB

''' @brief Adds an (x, y, z) offset to a vector.
''' @param src The source vector.
''' @param x The x offset to add.
''' @param y The y offset to add.
''' @param z The z offset to add.
''' @param dst The destination vector.
SUB Vector3f_AddXYZ (src AS Vector3f, x AS SINGLE, y AS SINGLE, z AS SINGLE, dst AS Vector3f)
    dst.x = src.x + x
    dst.y = src.y + y
    dst.z = src.z + z
END SUB

''' @brief Adds two vectors: dst = a + b.
''' @param a First vector.
''' @param b Second vector.
''' @param dst Destination vector.
SUB Vector3f_Add (a AS Vector3f, b AS Vector3f, dst AS Vector3f)
    dst.x = a.x + b.x
    dst.y = a.y + b.y
    dst.z = a.z + b.z
END SUB

''' @brief Subtracts vector b from vector a: dst = a - b.
''' @param a First vector.
''' @param b Second vector.
''' @param dst Destination vector.
SUB Vector3f_Subtract (a AS Vector3f, b AS Vector3f, dst AS Vector3f)
    dst.x = a.x - b.x
    dst.y = a.y - b.y
    dst.z = a.z - b.z
END SUB

''' @brief Multiplies two vectors component-wise: dst = a * b.
''' @param a First vector.
''' @param b Second vector.
''' @param dst Destination vector.
SUB Vector3f_Multiply (a AS Vector3f, b AS Vector3f, dst AS Vector3f)
    dst.x = a.x * b.x
    dst.y = a.y * b.y
    dst.z = a.z * b.z
END SUB

''' @brief Scales a vector by a scalar factor: dst = src * scalar.
''' @param src Source vector.
''' @param scalar Scaling multiplier.
''' @param dst Destination vector.
SUB Vector3f_Scale (src AS Vector3f, scalar AS SINGLE, dst AS Vector3f)
    dst.x = src.x * scalar
    dst.y = src.y * scalar
    dst.z = src.z * scalar
END SUB

''' @brief Divides a vector by a scalar factor: dst = src / scalar.
''' @param src Source vector.
''' @param scalar Scaling divisor.
''' @param dst Destination vector.
SUB Vector3f_Divide (src AS Vector3f, scalar AS SINGLE, dst AS Vector3f)
    IF scalar <> 0! THEN
        DIM invScalar AS SINGLE: invScalar = 1! / scalar
        dst.x = src.x * invScalar
        dst.y = src.y * invScalar
        dst.z = src.z * invScalar
    ELSE
        dst.x = 0!
        dst.y = 0!
        dst.z = 0!
    END IF
END SUB

''' @brief Negates a vector: dst = -src.
''' @param src Source vector.
''' @param dst Destination vector.
SUB Vector3f_Negate (src AS Vector3f, dst AS Vector3f)
    dst.x = -src.x
    dst.y = -src.y
    dst.z = -src.z
END SUB

''' @brief Computes the squared Euclidean length of a vector.
''' @param src The vector.
''' @return The squared length (x*x + y*y + z*z).
FUNCTION Vector3f_LengthSquared! (src AS Vector3f)
    Vector3f_LengthSquared = src.x * src.x + src.y * src.y + src.z * src.z
END FUNCTION

''' @brief Computes the Euclidean length (magnitude) of a vector.
''' @param src The vector.
''' @return The length of the vector.
FUNCTION Vector3f_Length! (src AS Vector3f)
    Vector3f_Length = SQR(src.x * src.x + src.y * src.y + src.z * src.z)
END FUNCTION

''' @brief Computes the squared distance between two vectors.
''' @param a First vector.
''' @param b Second vector.
''' @return Squared distance between a and b.
FUNCTION Vector3f_DistanceSquared! (a AS Vector3f, b AS Vector3f)
    DIM dx AS SINGLE: dx = a.x - b.x
    DIM dy AS SINGLE: dy = a.y - b.y
    DIM dz AS SINGLE: dz = a.z - b.z
    Vector3f_DistanceSquared = dx * dx + dy * dy + dz * dz
END FUNCTION

''' @brief Computes the Euclidean distance between two vectors.
''' @param a First vector.
''' @param b Second vector.
''' @return Distance between a and b.
FUNCTION Vector3f_Distance! (a AS Vector3f, b AS Vector3f)
    DIM dx AS SINGLE: dx = a.x - b.x
    DIM dy AS SINGLE: dy = a.y - b.y
    DIM dz AS SINGLE: dz = a.z - b.z
    Vector3f_Distance = SQR(dx * dx + dy * dy + dz * dz)
END FUNCTION

''' @brief Computes the dot product of two vectors.
''' @param a First vector.
''' @param b Second vector.
''' @return Dot product (a.x * b.x + a.y * b.y + a.z * b.z).
FUNCTION Vector3f_DotProduct! (a AS Vector3f, b AS Vector3f)
    Vector3f_DotProduct = a.x * b.x + a.y * b.y + a.z * b.z
END FUNCTION

''' @brief Computes the cross product of two 3D vectors: dst = a x b.
''' @param a First vector.
''' @param b Second vector.
''' @param dst Destination vector.
SUB Vector3f_CrossProduct (a AS Vector3f, b AS Vector3f, dst AS Vector3f)
    DIM rx AS SINGLE: rx = a.y * b.z - a.z * b.y
    DIM ry AS SINGLE: ry = a.z * b.x - a.x * b.z
    DIM rz AS SINGLE: rz = a.x * b.y - a.y * b.x
    dst.x = rx
    dst.y = ry
    dst.z = rz
END SUB

''' @brief Normalizes a vector to unit length.
''' @param src Source vector.
''' @param dst Destination vector (unit length, or zero if src length is 0).
SUB Vector3f_Normalize (src AS Vector3f, dst AS Vector3f)
    DIM l AS SINGLE: l = SQR(src.x * src.x + src.y * src.y + src.z * src.z)
    IF l > 0! THEN
        DIM invL AS SINGLE: invL = 1! / l
        dst.x = src.x * invL
        dst.y = src.y * invL
        dst.z = src.z * invL
    ELSE
        dst.x = 0!
        dst.y = 0!
        dst.z = 0!
    END IF
END SUB

''' @brief Linearly interpolates between vector a and vector b: dst = a + (b - a) * t.
''' @param a Starting vector (t = 0).
''' @param b Ending vector (t = 1).
''' @param t Interpolation parameter.
''' @param dst Destination vector.
SUB Vector3f_Lerp (a AS Vector3f, b AS Vector3f, t AS SINGLE, dst AS Vector3f)
    dst.x = a.x + (b.x - a.x) * t
    dst.y = a.y + (b.y - a.y) * t
    dst.z = a.z + (b.z - a.z) * t
END SUB

''' @brief Reflects a vector off a surface with the given unit normal: dst = src - 2 * dot(src, normal) * normal.
''' @param src Incident vector.
''' @param normal Surface unit normal vector.
''' @param dst Destination reflected vector.
SUB Vector3f_Reflect (src AS Vector3f, normal AS Vector3f, dst AS Vector3f)
    DIM dot2 AS SINGLE: dot2 = 2! * (src.x * normal.x + src.y * normal.y + src.z * normal.z)
    dst.x = src.x - dot2 * normal.x
    dst.y = src.y - dot2 * normal.y
    dst.z = src.z - dot2 * normal.z
END SUB

''' @brief Clamps the magnitude of a vector to a maximum length.
''' @param src Source vector.
''' @param maxLength Maximum allowed length.
''' @param dst Destination vector.
SUB Vector3f_ClampLength (src AS Vector3f, maxLength AS SINGLE, dst AS Vector3f)
    DIM sqrLen AS SINGLE: sqrLen = src.x * src.x + src.y * src.y + src.z * src.z
    IF sqrLen > maxLength * maxLength _ANDALSO sqrLen > 0! THEN
        DIM scaleFactor AS SINGLE: scaleFactor = maxLength / SQR(sqrLen)
        dst.x = src.x * scaleFactor
        dst.y = src.y * scaleFactor
        dst.z = src.z * scaleFactor
    ELSE
        dst.x = src.x
        dst.y = src.y
        dst.z = src.z
    END IF
END SUB

''' @brief Checks if a vector is null (0, 0, 0).
''' @param src The vector to check.
''' @return _TRUE if all components are 0, _FALSE otherwise.
FUNCTION Vector3f_IsNull%% (src AS Vector3f)
    Vector3f_IsNull = src.x = 0! _ANDALSO src.y = 0! _ANDALSO src.z = 0!
END FUNCTION

''' @brief Checks if two vectors are equal.
''' @param a First vector.
''' @param b Second vector.
''' @return _TRUE if all components match, _FALSE otherwise.
FUNCTION Vector3f_IsEqual%% (a AS Vector3f, b AS Vector3f)
    Vector3f_IsEqual = a.x = b.x _ANDALSO a.y = b.y _ANDALSO a.z = b.z
END FUNCTION
