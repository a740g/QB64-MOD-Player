//----------------------------------------------------------------------------------------------------------------------
// File management routines
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <sys/stat.h>
#ifdef _WIN32
    #include <windows.h>
#endif

// These must be kept in sync with FileOps.bi
static const uint32_t __FILE_ATTRIBUTE_DIRECTORY = 0x10;    // Directory
static const uint32_t __FILE_ATTRIBUTE_REGULAR_FILE = 0x20; // Regular file
static const uint32_t __FILE_ATTRIBUTE_READONLY = 0x01;     // Read-only
static const uint32_t __FILE_ATTRIBUTE_HIDDEN = 0x02;       // Hidden
static const uint32_t __FILE_ATTRIBUTE_SYSTEM = 0x04;       // System file
static const uint32_t __FILE_ATTRIBUTE_ARCHIVE = 0x08;      // Archive

/// @brief Returns some basic attributes of a file or directory
/// @param pathName The path name to get the attribute for
/// @return A 32-bit value where each bit represents an attribute (see __FILE_* above)
inline uint32_t __File_GetAttributes(const char *pathName) {
    uint32_t attributes = 0;

#ifdef _WIN32
    DWORD winAttributes = GetFileAttributesA(pathName);

    if (winAttributes == INVALID_FILE_ATTRIBUTES) {
        return attributes; // error or file not found
    }

    if (winAttributes & FILE_ATTRIBUTE_DIRECTORY) {
        attributes |= __FILE_ATTRIBUTE_DIRECTORY;
    }

    if (!(winAttributes & FILE_ATTRIBUTE_DIRECTORY)) {
        attributes |= __FILE_ATTRIBUTE_REGULAR_FILE;
    }

    if (winAttributes & FILE_ATTRIBUTE_READONLY) {
        attributes |= __FILE_ATTRIBUTE_READONLY;
    }

    if (winAttributes & FILE_ATTRIBUTE_HIDDEN) {
        attributes |= __FILE_ATTRIBUTE_HIDDEN;
    }

    if (winAttributes & FILE_ATTRIBUTE_SYSTEM) {
        attributes |= __FILE_ATTRIBUTE_SYSTEM;
    }

    if (winAttributes & FILE_ATTRIBUTE_ARCHIVE) {
        attributes |= __FILE_ATTRIBUTE_ARCHIVE;
    }

#else
    try {
        std::filesystem::path filePath(pathName);

        if (!std::filesystem::exists(filePath)) {
            return attributes; // file or directory does not exist
        }

        if (std::filesystem::is_directory(filePath)) {
            attributes |= __FILE_ATTRIBUTE_DIRECTORY;
        }

        if (std::filesystem::is_regular_file(filePath)) {
            attributes |= __FILE_ATTRIBUTE_REGULAR_FILE;
        }

        auto perms = std::filesystem::status(filePath).permissions();

        if ((perms & std::filesystem::perms::owner_write) == std::filesystem::perms::none) {
            attributes |= __FILE_ATTRIBUTE_READONLY;
        }

        if (pathName[0] == '.') {
            attributes |= __FILE_ATTRIBUTE_HIDDEN;
        }
    } catch (const std::exception &e) {
        return attributes; // error
    }
#endif

    return attributes;
}

/// @brief Returns the 64-bit file size without opening the file
/// @param fileName The file name to get the size for
/// @return A 64-bit integer value (size)
inline int64_t __File_GetSize(const char *fileName) {
    try {
        std::filesystem::path filePath(fileName);

        if (std::filesystem::exists(filePath) && std::filesystem::is_regular_file(filePath)) {
            return int64_t(std::filesystem::file_size(filePath));
        } else {
            return -1; // not a regular file or does not exist
        }
    } catch (...) {
        return -1; // not a regular file or does not exist
    }
}

/// @brief Returns the modified time of a file as a std::time_t value.
/// @param filePath The file path to get the modified time for.
/// @return A std::time_t value containing the modified time, or -1 on error.
inline int64_t __File_GetModifiedTime(const char *filePath) {
    try {
        return int64_t(std::chrono::system_clock::to_time_t(std::chrono::time_point_cast<std::chrono::system_clock::duration>(
            std::filesystem::last_write_time(filePath) - std::filesystem::file_time_type::clock::now() + std::chrono::system_clock::now())));
    } catch (...) {
        return -1; // return -1 on error
    }
}
