//----------------------------------------------------------------------------------------------------------------------
// 2D Vector (integer) routines
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Core/Types.h"
#include <algorithm>
#include <cmath>
#include <cstdint>

struct Vector2i {
    int32_t x;
    int32_t y;
};

#define VECTOR2I_SRC(src) reinterpret_cast<const Vector2i *>(src)
#define VECTOR2I_DST(dst) reinterpret_cast<Vector2i *>(dst)

inline void Vector2i_Reset(void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_DST(dst)->y = 0;
}

inline void Vector2i_Initialize(int32_t x, int32_t y, void *dst) {
    VECTOR2I_DST(dst)->x = x;
    VECTOR2I_DST(dst)->y = y;
}

inline qb_bool Vector2i_IsNull(const void *src) {
    return TO_QB_BOOL(VECTOR2I_SRC(src)->x == 0 && VECTOR2I_SRC(src)->y == 0);
}

inline void Vector2i_Add(const void *src1, const void *src2, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src1)->x + VECTOR2I_SRC(src2)->x;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src1)->y + VECTOR2I_SRC(src2)->y;
}

inline void Vector2i_AddValue(const void *src, int32_t value, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x + value;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y + value;
}

inline void Vector2i_AddXY(const void *src, int32_t x, int32_t y, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x + x;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y + y;
}

inline void Vector2i_Subtract(const void *src1, const void *src2, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src1)->x - VECTOR2I_SRC(src2)->x;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src1)->y - VECTOR2I_SRC(src2)->y;
}

inline void Vector2i_SubtractValue(const void *src, int32_t value, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x - value;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y - value;
}

inline void Vector2i_SubtractXY(const void *src, int32_t x, int32_t y, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x - x;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y - y;
}

inline void Vector2i_Multiply(const void *src1, const void *src2, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src1)->x * VECTOR2I_SRC(src2)->x;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src1)->y * VECTOR2I_SRC(src2)->y;
}

inline void Vector2i_MultiplyValue(const void *src, int32_t value, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x * value;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y * value;
}

inline void Vector2i_MultiplyXY(const void *src, int32_t x, int32_t y, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x * x;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y * y;
}

inline void Vector2i_Divide(const void *src1, const void *src2, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src2)->x ? VECTOR2I_SRC(src1)->x / VECTOR2I_SRC(src2)->x : 0;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src2)->y ? VECTOR2I_SRC(src1)->y / VECTOR2I_SRC(src2)->y : 0;
}

inline void Vector2i_DivideValue(const void *src, int32_t value, void *dst) {
    if (value) {
        VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x / value;
        VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y / value;
    } else {
        VECTOR2I_DST(dst)->x = VECTOR2I_DST(dst)->y = 0;
    }
}

inline void Vector2i_DivideXY(const void *src, int32_t x, int32_t y, void *dst) {
    VECTOR2I_DST(dst)->x = x ? VECTOR2I_SRC(src)->x / x : 0;
    VECTOR2I_DST(dst)->y = y ? VECTOR2I_SRC(src)->y / y : 0;
}

inline void Vector2i_Negate(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = -VECTOR2I_SRC(src)->x;
    VECTOR2I_DST(dst)->y = -VECTOR2I_SRC(src)->y;
}

inline int32_t Vector2i_GetLengthSquared(const void *src) {
    return VECTOR2I_SRC(src)->x * VECTOR2I_SRC(src)->x + VECTOR2I_SRC(src)->y * VECTOR2I_SRC(src)->y;
}

inline int32_t Vector2i_GetLength(const void *src) {
    return std::sqrt(Vector2i_GetLengthSquared(src));
}

inline int32_t Vector2i_GetDistanceSquared(const void *src1, const void *src2) {
    Vector2i diff;
    Vector2i_Subtract(src1, src2, &diff);
    return Vector2i_GetLengthSquared(&diff);
}

inline int32_t Vector2i_GetDistance(const void *src1, const void *src2) {
    return std::sqrt(Vector2i_GetDistanceSquared(src1, src2));
}

inline void Vector2i_GetSizeVector(const void *src1, const void *src2, void *dst) {
    VECTOR2I_DST(dst)->x = 1 + std::abs(VECTOR2I_SRC(src1)->x - VECTOR2I_SRC(src2)->x);
    VECTOR2I_DST(dst)->y = 1 + std::abs(VECTOR2I_SRC(src1)->y - VECTOR2I_SRC(src2)->y);
}

inline int32_t Vector2i_GetArea(const void *src) {
    return VECTOR2I_SRC(src)->x * VECTOR2I_SRC(src)->y;
}

inline int32_t Vector2i_GetPerimeter(const void *src) {
    return 2 * (VECTOR2I_SRC(src)->x + VECTOR2I_SRC(src)->y);
}

inline int32_t Vector2i_GetDotProduct(const void *src1, const void *src2) {
    return VECTOR2I_SRC(src1)->x * VECTOR2I_SRC(src2)->x + VECTOR2I_SRC(src1)->y * VECTOR2I_SRC(src2)->y;
}

inline int32_t Vector2i_GetCrossProduct(const void *src1, const void *src2) {
    return VECTOR2I_SRC(src1)->x * VECTOR2I_SRC(src2)->y - VECTOR2I_SRC(src1)->y * VECTOR2I_SRC(src2)->x;
}

inline void Vector2i_TurnRight(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->y;
    VECTOR2I_DST(dst)->y = -VECTOR2I_SRC(src)->x;
}

inline void Vector2i_TurnLeft(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = -VECTOR2I_SRC(src)->y;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->x;
}

inline void Vector2i_FlipHorizontal(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = -VECTOR2I_SRC(src)->x;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y;
}

inline void Vector2i_FlipVertical(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x;
    VECTOR2I_DST(dst)->y = -VECTOR2I_SRC(src)->y;
}

inline void Vector2i_Lerp(const void *src1, const void *src2, float amount, void *dst) {
    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src1)->x + (VECTOR2I_SRC(src2)->x - VECTOR2I_SRC(src1)->x) * amount;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src1)->y + (VECTOR2I_SRC(src2)->y - VECTOR2I_SRC(src1)->y) * amount;
}

inline void Vector2i_Reflect(const void *src, const void *normal, void *dst) {
    auto dot = Vector2i_GetDotProduct(src, normal);
    Vector2i scaled;
    Vector2i_MultiplyValue(normal, 2 * dot, &scaled);
    Vector2i_Subtract(src, &scaled, dst);
}

inline void Vector2i_Rotate(const void *src, float angle, void *dst) {
    auto cosres = std::cos(angle);
    auto sinres = std::sin(angle);

    VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x * cosres - VECTOR2I_SRC(src)->y * sinres;
    VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->x * sinres + VECTOR2I_SRC(src)->y * cosres;
}

inline void Vector2i_MoveTowards(const void *src, const void *target, int32_t maxDistance, void *dst) {
    auto dx = VECTOR2I_SRC(target)->x - VECTOR2I_SRC(src)->x;
    auto dy = VECTOR2I_SRC(target)->y - VECTOR2I_SRC(src)->y;
    auto value = (dx * dx) + (dy * dy);

    if ((value == 0) || ((maxDistance >= 0) && (value <= maxDistance * maxDistance))) {
        VECTOR2I_DST(dst)->x = VECTOR2I_SRC(target)->x;
        VECTOR2I_DST(dst)->y = VECTOR2I_SRC(target)->y;
    } else {
        auto dist = std::sqrt(value);
        VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x + dx / dist * maxDistance;
        VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y + dy / dist * maxDistance;
    }
}

inline void Vector2i_Clamp(const void *src, const void *min, const void *max, void *dst) {
    VECTOR2I_DST(dst)->x = std::min(std::max(VECTOR2I_SRC(src)->x, VECTOR2I_SRC(min)->x), VECTOR2I_SRC(max)->x);
    VECTOR2I_DST(dst)->y = std::min(std::max(VECTOR2I_SRC(src)->y, VECTOR2I_SRC(min)->y), VECTOR2I_SRC(max)->y);
}

inline void Vector2i_ClampValue(const void *src, int32_t min, int32_t max, void *dst) {
    auto length = VECTOR2I_SRC(src)->x * VECTOR2I_SRC(src)->x + VECTOR2I_SRC(src)->y * VECTOR2I_SRC(src)->y;

    if (length > 0) {
        length = std::sqrt(length);

        if (length < min) {
            float scale = min / length;
            VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x * scale;
            VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y * scale;
        } else if (length > max) {
            float scale = max / length;
            VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x * scale;
            VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y * scale;
        } else {
            VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x;
            VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y;
        }
    } else {
        VECTOR2I_DST(dst)->x = VECTOR2I_SRC(src)->x;
        VECTOR2I_DST(dst)->y = VECTOR2I_SRC(src)->y;
    }
}
