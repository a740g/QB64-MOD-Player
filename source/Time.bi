'-----------------------------------------------------------------------------------------------------------------------
' Time related routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

''' @brief Measures the number of times this function is called per second.
''' @return The number of calls per second.
FUNCTION Time_MeasureHertz~&
    STATIC AS _UNSIGNED LONG counter, finalHz
    STATIC lastSec AS DOUBLE

    DIM currentSec AS DOUBLE: currentSec = _UPTIME

    IF currentSec - lastSec >= 1.0# THEN
        lastSec = currentSec
        finalHz = counter
        counter = 0
    END IF

    counter = counter + 1

    Time_MeasureHertz = finalHz
END FUNCTION
