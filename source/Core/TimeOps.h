//----------------------------------------------------------------------------------------------------------------------
// Time related routines
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

/// @brief GetTicks returns the number of "ticks" (ms) since the program started execution where 1000 "ticks" (ms) = 1 second.
/// @return Ticks in ms.
extern int64_t GetTicks();

/// @brief Calculates and returns the Hertz when repeatedly called inside a loop
/// @return A positive Hertz value
uint32_t Time_GetHertz() {
    static uint32_t counter = 0, finalFPS = 0;
    static uint64_t lastTime = 0;

    uint64_t currentTime = GetTicks();

    if (currentTime - lastTime >= 1000) {
        lastTime = currentTime;
        finalFPS = counter;
        counter = 0;
    }

    ++counter;

    return finalFPS;
}
