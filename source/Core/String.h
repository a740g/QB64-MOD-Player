//----------------------------------------------------------------------------------------------------------------------
// String related routines
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Core/Common.h"
#include "../Core/Types.h"
#include <cctype>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <regex>

constexpr auto String_Empty = "";

/// @brief Used for formatting strings.
/// @tparam T The type of the value to format.
/// @param value The value to format.
/// @param fmt The format specifier.
/// @return A formatted string.
template <typename T> inline const char *__String_Format(const T &value, const char *fmt) {
    g_TmpBuf[0] = '\0';
    snprintf(reinterpret_cast<char *>(g_TmpBuf.data()), g_TmpBuf.size(), fmt, value);
    return reinterpret_cast<char *>(g_TmpBuf.data());
}

/// @brief Gets a string form of the boolean value passed
/// @param n A boolean value
/// @param fmt The format type needed
/// @return A string form of the boolean value
inline const char *String_FormatBoolean(intptr_t n, uint32_t fmt) {
    static const char *const BOOLEAN_STRINGS[][2] = {{"False", "True"},
                                                     {"0", "1"},
                                                     {"0", "-1"},
                                                     {"Off", "On"},
                                                     {"Disabled", "Enabled"},
                                                     {"Disable", "Enable"},
                                                     {"No", "Yes"},
                                                     {"Low", "High"},
                                                     {"Closed", "Opened"},
                                                     {"Close", "Open"},
                                                     {"Inactive", "Active"},
                                                     {"Absent", "Present"},
                                                     {"Disengaged", "Engaged"},
                                                     {"Disengage", "Engage"},
                                                     {"Disconnected", "Connected"},
                                                     {"Disconnect", "Connect"},
                                                     {"Invalid", "Valid"},
                                                     {"Down", "Up"},
                                                     {"Stopped", "Started"},
                                                     {"Stop", "Start"},
                                                     {"Unavailable", "Available"},
                                                     {"Out", "In"}};

    return BOOLEAN_STRINGS[fmt < _countof(BOOLEAN_STRINGS) ? fmt : 0][n != 0];
}

/// @brief Check if the character is an alphanumeric character
/// @param ch The character to check
/// @return True if the character is an alphanumeric character
inline qb_bool String_IsAlphaNumeric(uint32_t ch) {
    return TO_QB_BOOL(std::isalnum(ch));
}

/// @brief Check if the character is an alphabetic character
/// @param ch The character to check
/// @return True if the character is an alphabetic character
inline qb_bool String_IsAlphabetic(uint32_t ch) {
    return TO_QB_BOOL(std::isalpha(ch));
}

/// @brief Check if the character is a lowercase character
/// @param ch The character to check
/// @return True if the character is a lowercase character
inline qb_bool String_IsLowerCase(uint32_t ch) {
    return TO_QB_BOOL(std::islower(ch));
}

/// @brief Check if the character is an uppercase character
/// @param ch The character to check
/// @return True if the character is an uppercase character
inline qb_bool String_IsUpperCase(uint32_t ch) {
    return TO_QB_BOOL(std::isupper(ch));
}

/// @brief Check if the character is a numeric character
/// @param ch The character to check
/// @return True if the character is a numeric character
inline qb_bool String_IsDigit(uint32_t ch) {
    return TO_QB_BOOL(std::isdigit(ch));
}

/// @brief Check if the character is a hexadecimal numeric character
/// @param ch The character to check
/// @return True if the character is a hexadecimal numeric character
inline qb_bool String_IsHexadecimalDigit(uint32_t ch) {
    return TO_QB_BOOL(std::isxdigit(ch));
}

/// @brief Check if the character is a control character
/// @param ch The character to check
/// @return True if the character is a control character
inline qb_bool String_IsControlCharacter(uint32_t ch) {
    return TO_QB_BOOL(std::iscntrl(ch));
}

/// @brief Check if the character has a graphical representation
/// @param ch The character to check
/// @return True if the character has a graphical representation
inline qb_bool String_IsGraphicalCharacter(uint32_t ch) {
    return TO_QB_BOOL(std::isgraph(ch));
}

/// @brief Check if the character is a white-space character
/// @param ch The character to check
/// @return True if the character is white-space character
inline qb_bool String_IsWhiteSpace(uint32_t ch) {
    return TO_QB_BOOL(std::isspace(ch));
}

/// @brief Check if the character is a blank character
/// @param ch The character to check
/// @return True if the character is a blank character
inline qb_bool String_IsBlank(uint32_t ch) {
    return TO_QB_BOOL(std::isblank(ch));
}

/// @brief Check if the character can be printed
/// @param ch The character to check
/// @return True if the character can be printed
inline qb_bool String_IsPrintable(uint32_t ch) {
    return TO_QB_BOOL(std::isprint(ch));
}

/// @brief Check if the character is a punctuation character
/// @param ch The character to check
/// @return True if the character is a punctuation character
inline qb_bool String_IsPunctuation(uint32_t ch) {
    return TO_QB_BOOL(std::ispunct(ch));
}

/// @brief Compiles a RegEx and returns a context
/// @param pattern A RegEx pattern
/// @return A RegEx context
inline uintptr_t __String_RegExCompile(const char *pattern) {
    try {
        auto regexPtr = new std::regex(pattern);
        return reinterpret_cast<uintptr_t>(regexPtr);
    } catch (const std::regex_error &e) {
        return 0; // return null context on error
    }
}

/// @brief Frees resources for a compiled pattern
/// @param pattern A RegEx context
inline void String_RegExFree(uintptr_t pattern) {
    if (pattern) {
        delete reinterpret_cast<std::regex *>(pattern);
    }
}

/// @brief Searches of a occurrence of a compiled pattern in `text`
/// @param pattern A RegEx context
/// @param text The string to search
/// @param index The position in the string to start searching
/// @param matchLength The length of the match [output]
/// @return Starting position of the match (>= 0) or a negative value indicating the error
inline int32_t __String_RegExSearchCompiled(uintptr_t pattern, const char *text, int32_t index, int32_t *matchLength) {
    if (!pattern)
        return -2; // invalid context

    auto regexPtr = reinterpret_cast<std::regex *>(pattern);
    std::cmatch cm;

    // Convert index to size_t for regex_search
    auto startIndex = static_cast<size_t>(index) - 1; // QB string index starts at 1
    if (std::regex_search(text + startIndex, cm, *regexPtr)) {
        *matchLength = static_cast<int32_t>(cm.length());
        return static_cast<int32_t>(cm.position()); // return the starting position of the match (must be adjusted on the QB64 side!!!)
    }

    return -1; // no match found
}

/// @brief Searches for an occurrence of a pattern in `text`
/// @param pattern A RegEx pattern
/// @param text The string to search
/// @param index The position in the string to start searching
/// @param matchLength The length of the match [output]
/// @return Starting position of the match (>= 0) or a negative value indicating the error
inline int32_t __String_RegExSearch(const char *pattern, const char *text, int32_t index, int32_t *matchLength) {
    auto compiledPattern = __String_RegExCompile(pattern);
    auto result = __String_RegExSearchCompiled(compiledPattern, text, index, matchLength);
    String_RegExFree(compiledPattern); // clean up compiled context
    return result;
}

/// @brief Checks if `text` is a RegEx match
/// @param pattern A RegEx context
/// @param text The string to match
/// @return True if it is a match. False otherwise
inline qb_bool __String_RegExMatchCompiled(uintptr_t pattern, const char *text) {
    if (!pattern)
        return QB_FALSE; // invalid context

    auto regexPtr = reinterpret_cast<std::regex *>(pattern);
    return TO_QB_BOOL(std::regex_match(text, *regexPtr));
}

/// @brief Checks if `text` is a RegEx match
/// @param pattern A RegEx pattern
/// @param text The string to match
/// @return True if it is a match. False otherwise
inline qb_bool __String_RegExMatch(const char *pattern, const char *text) {
    uintptr_t compiledPattern = __String_RegExCompile(pattern);
    auto result = __String_RegExMatchCompiled(compiledPattern, text);
    String_RegExFree(compiledPattern); // clean up compiled context
    return result;
}
