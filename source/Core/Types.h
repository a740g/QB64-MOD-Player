//----------------------------------------------------------------------------------------------------------------------
// Variable type support, size and limits
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

// QB64 false is 0 and true is -1 (sad, but true XD)
typedef int8_t qb_bool;

#ifndef INC_COMMON_CPP
    #define QB_TRUE -1
    #define QB_FALSE 0
#endif

#define TO_QB_BOOL(expression) (qb_bool(-(bool(expression))))

/// @brief Casts a QB64 _OFFSET to a C string. QB64 does the right thing to convert this to a QB64 string
/// @param p A pointer (_OFFSET)
/// @return A C string (char ptr)
inline const char *CString(uintptr_t p) {
    return reinterpret_cast<const char *>(p);
}
