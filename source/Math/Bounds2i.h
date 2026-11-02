//----------------------------------------------------------------------------------------------------------------------
// 2D Bounding Box (integer) routines
// Copyright (c) 2024 Samuel Gomes
//
// Rule:
// Trival local and dependency functions can be nested in hot paths as long as:
// 1. We do not repeat unnecessary calculations.
// 2. We do not have direct or indirect nested TO_QB_BOOL insertions.
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Vector2i.h"

struct Bounds2i {
    Vector2i lt;
    Vector2i rb;
};

#define BOUNDS2I_SRC(src) reinterpret_cast<const Bounds2i *>(src)
#define BOUNDS2I_DST(dst) reinterpret_cast<Bounds2i *>(dst)

inline void Bounds2i_Reset(void *dst) {
    BOUNDS2I_DST(dst)->lt.x = BOUNDS2I_DST(dst)->lt.y = BOUNDS2I_DST(dst)->rb.x = BOUNDS2I_DST(dst)->rb.y = 0;
}

inline void Bounds2i_Initialize(int32_t x1, int32_t y1, int32_t x2, int32_t y2, void *dst) {
    BOUNDS2I_DST(dst)->lt.x = x1;
    BOUNDS2I_DST(dst)->lt.y = y1;
    BOUNDS2I_DST(dst)->rb.x = x2;
    BOUNDS2I_DST(dst)->rb.y = y2;
}

inline void Bounds2i_InitializeFromPositionSize(const void *position, const void *size, void *dst) {
    BOUNDS2I_DST(dst)->lt = *VECTOR2I_SRC(position);
    BOUNDS2I_DST(dst)->rb.x = VECTOR2I_SRC(position)->x + VECTOR2I_SRC(size)->x - 1;
    BOUNDS2I_DST(dst)->rb.y = VECTOR2I_SRC(position)->y + VECTOR2I_SRC(size)->y - 1;
}

inline void Bounds2i_InitializeFromPoints(const void *p1, const void *p2, void *dst) {
    BOUNDS2I_DST(dst)->lt = *VECTOR2I_SRC(p1);
    BOUNDS2I_DST(dst)->rb = *VECTOR2I_SRC(p2);
}

/// @brief Checks if the bounding box is empty (i.e has no width or height).
/// @param src The source bounding box.
/// @return True if the bounding box is empty, false otherwise.
inline qb_bool Bounds2i_IsEmpty(const void *src) {
    return TO_QB_BOOL(BOUNDS2I_SRC(src)->rb.x <= BOUNDS2I_SRC(src)->lt.x || BOUNDS2I_SRC(src)->rb.y <= BOUNDS2I_SRC(src)->lt.y);
}

/// @brief Checks if the bounding box is valid (i.e has a non-negative width and height).
/// @param src The source bounding box.
/// @return True if the bounding box is valid, false otherwise.
inline qb_bool Bounds2i_IsValid(const void *src) {
    return TO_QB_BOOL(BOUNDS2I_SRC(src)->rb.x >= BOUNDS2I_SRC(src)->lt.x && BOUNDS2I_SRC(src)->rb.y >= BOUNDS2I_SRC(src)->lt.y);
}

inline qb_bool Bounds2i_HasNoWidth(const void *src) {
    return TO_QB_BOOL(BOUNDS2I_SRC(src)->rb.x < BOUNDS2I_SRC(src)->lt.x);
}

inline qb_bool Bounds2i_HasNoHeight(const void *src) {
    return TO_QB_BOOL(BOUNDS2I_SRC(src)->rb.y < BOUNDS2I_SRC(src)->lt.y);
}

inline int32_t Bounds2i_GetWidth(const void *src) {
    auto w = BOUNDS2I_SRC(src)->rb.x - BOUNDS2I_SRC(src)->lt.x + 1;
    return w > 0 ? w : 0;
}

inline int32_t Bounds2i_GetHeight(const void *src) {
    auto h = BOUNDS2I_SRC(src)->rb.y - BOUNDS2I_SRC(src)->lt.y + 1;
    return h > 0 ? h : 0;
}

inline void Bounds2i_GetCenter(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = BOUNDS2I_SRC(src)->lt.x + (BOUNDS2I_SRC(src)->rb.x - BOUNDS2I_SRC(src)->lt.x) / 2;
    VECTOR2I_DST(dst)->y = BOUNDS2I_SRC(src)->lt.y + (BOUNDS2I_SRC(src)->rb.y - BOUNDS2I_SRC(src)->lt.y) / 2;
}

inline void Bounds2i_GetSize(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = Bounds2i_GetWidth(src);
    VECTOR2I_DST(dst)->y = Bounds2i_GetHeight(src);
}

inline void Bounds2i_Sanitize(void *dst) {
    if (BOUNDS2I_DST(dst)->lt.x > BOUNDS2I_DST(dst)->rb.x) {
        std::swap(BOUNDS2I_DST(dst)->lt.x, BOUNDS2I_DST(dst)->rb.x);
    }
    if (BOUNDS2I_DST(dst)->lt.y > BOUNDS2I_DST(dst)->rb.y) {
        std::swap(BOUNDS2I_DST(dst)->lt.y, BOUNDS2I_DST(dst)->rb.y);
    }
}

inline void Bounds2i_SetRightTop(const void *point, void *dst) {
    BOUNDS2I_DST(dst)->rb.x = VECTOR2I_SRC(point)->x;
    BOUNDS2I_DST(dst)->lt.y = VECTOR2I_SRC(point)->y;
}

inline void Bounds2i_SetRightTopXY(int32_t x, int32_t y, void *dst) {
    BOUNDS2I_DST(dst)->rb.x = x;
    BOUNDS2I_DST(dst)->lt.y = y;
}

inline void Bounds2i_SetLeftBottom(const void *point, void *dst) {
    BOUNDS2I_DST(dst)->lt.x = VECTOR2I_SRC(point)->x;
    BOUNDS2I_DST(dst)->rb.y = VECTOR2I_SRC(point)->y;
}

inline void Bounds2i_SetLeftBottomXY(int32_t x, int32_t y, void *dst) {
    BOUNDS2I_DST(dst)->lt.x = x;
    BOUNDS2I_DST(dst)->rb.y = y;
}

inline void Bounds2i_GetRightTop(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = BOUNDS2I_SRC(src)->rb.x;
    VECTOR2I_DST(dst)->y = BOUNDS2I_SRC(src)->lt.y;
}

inline void Bounds2i_GetLeftBottom(const void *src, void *dst) {
    VECTOR2I_DST(dst)->x = BOUNDS2I_SRC(src)->lt.x;
    VECTOR2I_DST(dst)->y = BOUNDS2I_SRC(src)->rb.y;
}

inline int32_t Bounds2i_GetArea(const void *src) {
    return Bounds2i_GetWidth(src) * Bounds2i_GetHeight(src);
}

inline int32_t Bounds2i_GetPerimeter(const void *src) {
    return (Bounds2i_GetWidth(src) + Bounds2i_GetHeight(src)) * 2;
}

inline int32_t Bounds2i_GetDiagonalLength(const void *src) {
    return Vector2i_GetDistance(&BOUNDS2I_SRC(src)->lt, &BOUNDS2I_SRC(src)->rb);
}

inline qb_bool Bounds2i_HasSameArea(const void *src1, const void *src2) {
    return TO_QB_BOOL(Bounds2i_GetArea(src1) == Bounds2i_GetArea(src2));
}

inline void Bounds2i_Inflate(const void *src, int32_t x, int32_t y, void *dst) {
    Vector2i_SubtractXY(&BOUNDS2I_SRC(src)->lt, x, y, &BOUNDS2I_DST(dst)->lt);
    Vector2i_AddXY(&BOUNDS2I_SRC(src)->rb, x, y, &BOUNDS2I_DST(dst)->rb);
}

inline void Bounds2i_InflateByVector(const void *src, const void *vector, void *dst) {
    Vector2i_Subtract(&BOUNDS2I_SRC(src)->lt, vector, &BOUNDS2I_DST(dst)->lt);
    Vector2i_Add(&BOUNDS2I_SRC(src)->rb, vector, &BOUNDS2I_DST(dst)->rb);
}

inline void Bounds2i_Deflate(const void *src, int32_t x, int32_t y, void *dst) {
    Vector2i_AddXY(&BOUNDS2I_SRC(src)->lt, x, y, &BOUNDS2I_DST(dst)->lt);
    Vector2i_SubtractXY(&BOUNDS2I_SRC(src)->rb, x, y, &BOUNDS2I_DST(dst)->rb);
}

inline void Bounds2i_DeflateByVector(const void *src, const void *vector, void *dst) {
    Vector2i_Add(&BOUNDS2I_SRC(src)->lt, vector, &BOUNDS2I_DST(dst)->lt);
    Vector2i_Subtract(&BOUNDS2I_SRC(src)->rb, vector, &BOUNDS2I_DST(dst)->rb);
}

inline void Bounds2i_IncludePoint(const void *src, const void *point, void *dst) {
    BOUNDS2I_DST(dst)->lt.x = std::min(BOUNDS2I_SRC(src)->lt.x, VECTOR2I_SRC(point)->x);
    BOUNDS2I_DST(dst)->lt.y = std::min(BOUNDS2I_SRC(src)->lt.y, VECTOR2I_SRC(point)->y);
    BOUNDS2I_DST(dst)->rb.x = std::max(BOUNDS2I_SRC(src)->rb.x, VECTOR2I_SRC(point)->x);
    BOUNDS2I_DST(dst)->rb.y = std::max(BOUNDS2I_SRC(src)->rb.y, VECTOR2I_SRC(point)->y);
}

inline void Bounds2i_Translate(const void *src, int32_t x, int32_t y, void *dst) {
    Vector2i_AddXY(&BOUNDS2I_SRC(src)->lt, x, y, &BOUNDS2I_DST(dst)->lt);
    Vector2i_AddXY(&BOUNDS2I_SRC(src)->rb, x, y, &BOUNDS2I_DST(dst)->rb);
}

inline void Bounds2i_TranslateByVector(const void *src, const void *vector, void *dst) {
    Vector2i_Add(&BOUNDS2I_SRC(src)->lt, vector, &BOUNDS2I_DST(dst)->lt);
    Vector2i_Add(&BOUNDS2I_SRC(src)->rb, vector, &BOUNDS2I_DST(dst)->rb);
}

inline qb_bool Bounds2i_ContainsXY(const void *src, int32_t x, int32_t y) {
    return TO_QB_BOOL(BOUNDS2I_SRC(src)->lt.x <= x && BOUNDS2I_SRC(src)->rb.x >= x && BOUNDS2I_SRC(src)->lt.y <= y && BOUNDS2I_SRC(src)->rb.y >= y);
}

inline qb_bool Bounds2i_ContainsPoint(const void *src, const void *point) {
    return Bounds2i_ContainsXY(src, VECTOR2I_SRC(point)->x, VECTOR2I_SRC(point)->y);
}

inline qb_bool Bounds2i_ContainsBounds(const void *src1, const void *src2) {
    return TO_QB_BOOL(Bounds2i_ContainsPoint(src1, &BOUNDS2I_SRC(src2)->lt) && Bounds2i_ContainsPoint(src1, &BOUNDS2I_SRC(src2)->rb));
}

inline qb_bool Bounds2i_Intersects(const void *src1, const void *src2) {
    auto a = BOUNDS2I_SRC(src1);
    auto b = BOUNDS2I_SRC(src2);
    return TO_QB_BOOL(a->lt.x <= b->rb.x && b->lt.x <= a->rb.x && a->lt.y <= b->rb.y && b->lt.y <= a->rb.y);
}

inline void Bounds2i_MakeUnion(const void *src1, const void *src2, void *dst) {
    auto src1Valid = BOUNDS2I_SRC(src1)->rb.x >= BOUNDS2I_SRC(src1)->lt.x && BOUNDS2I_SRC(src1)->rb.y >= BOUNDS2I_SRC(src1)->lt.y;
    auto src2Valid = BOUNDS2I_SRC(src2)->rb.x >= BOUNDS2I_SRC(src2)->lt.x && BOUNDS2I_SRC(src2)->rb.y >= BOUNDS2I_SRC(src2)->lt.y;

    if (src1Valid && src2Valid) {
        BOUNDS2I_DST(dst)->lt.x = std::min(BOUNDS2I_SRC(src1)->lt.x, BOUNDS2I_SRC(src2)->lt.x);
        BOUNDS2I_DST(dst)->lt.y = std::min(BOUNDS2I_SRC(src1)->lt.y, BOUNDS2I_SRC(src2)->lt.y);
        BOUNDS2I_DST(dst)->rb.x = std::max(BOUNDS2I_SRC(src1)->rb.x, BOUNDS2I_SRC(src2)->rb.x);
        BOUNDS2I_DST(dst)->rb.y = std::max(BOUNDS2I_SRC(src1)->rb.y, BOUNDS2I_SRC(src2)->rb.y);
    } else if (src1Valid) {
        *BOUNDS2I_DST(dst) = *BOUNDS2I_SRC(src1);
    } else if (src2Valid) {
        *BOUNDS2I_DST(dst) = *BOUNDS2I_SRC(src2);
    } else {
        Bounds2i_Reset(dst);
    }
}

inline void Bounds2i_MakeIntersection(const void *src1, const void *src2, void *dst) {
    auto src1Valid = (BOUNDS2I_SRC(src1)->rb.x >= BOUNDS2I_SRC(src1)->lt.x && BOUNDS2I_SRC(src1)->rb.y >= BOUNDS2I_SRC(src1)->lt.y);
    auto src2Valid = (BOUNDS2I_SRC(src2)->rb.x >= BOUNDS2I_SRC(src2)->lt.x && BOUNDS2I_SRC(src2)->rb.y >= BOUNDS2I_SRC(src2)->lt.y);
    auto intersects = (BOUNDS2I_SRC(src1)->lt.x <= BOUNDS2I_SRC(src2)->rb.x && BOUNDS2I_SRC(src2)->lt.x <= BOUNDS2I_SRC(src1)->rb.x &&
                       BOUNDS2I_SRC(src1)->lt.y <= BOUNDS2I_SRC(src2)->rb.y && BOUNDS2I_SRC(src2)->lt.y <= BOUNDS2I_SRC(src1)->rb.y);

    if (src1Valid && src2Valid && intersects) {
        BOUNDS2I_DST(dst)->lt.x = std::max(BOUNDS2I_SRC(src1)->lt.x, BOUNDS2I_SRC(src2)->lt.x);
        BOUNDS2I_DST(dst)->lt.y = std::max(BOUNDS2I_SRC(src1)->lt.y, BOUNDS2I_SRC(src2)->lt.y);
        BOUNDS2I_DST(dst)->rb.x = std::min(BOUNDS2I_SRC(src1)->rb.x, BOUNDS2I_SRC(src2)->rb.x);
        BOUNDS2I_DST(dst)->rb.y = std::min(BOUNDS2I_SRC(src1)->rb.y, BOUNDS2I_SRC(src2)->rb.y);
    } else {
        Bounds2i_Reset(dst);
    }
}
