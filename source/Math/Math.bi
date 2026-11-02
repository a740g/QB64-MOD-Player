'-----------------------------------------------------------------------------------------------------------------------
' Math routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'PRINT Math_GetRandomValue
'PRINT Math_GetRandomMax
'PRINT Math_GetMaxDouble(24.4, 645.355)
'PRINT Math_GetMaxLong(-20, 0)
'PRINT Math_GetMinLong(0, 20)
'PRINT Math_GetMinInteger64(-244334, 0)
'PRINT FIX(2.5!), FIX(1.5!), FIX(2.1!), FIX(1.1!)
'PRINT Math_SingleToLong(2.5!), Math_SingleToLong(1.5!), Math_SingleToLong(2.1!), Math_SingleToLong(1.1!)
'DIM n AS SINGLE, i AS LONG
'n = 1.5!
'i = Math_SingleToLong(n)
'PRINT n, i
'PRINT Math_FastSquareRoot(256)
'PRINT Math_FastInverseSquareRoot(256)

'END
'-----------------------------------------------------------------------------------------------------------------------

DECLARE LIBRARY "Math"
    SUB Math_SetRandomSeed (BYVAL seed AS _UNSIGNED LONG)
    FUNCTION Math_GetRandomMax~&
    FUNCTION Math_GetRandomValue& ALIAS "std::rand"
    FUNCTION Math_GetRandomBetween& (BYVAL lo AS LONG, BYVAL hi AS LONG)
    FUNCTION Math_IsSingleNaN! (BYVAL n AS SINGLE)
    FUNCTION Math_IsDoubleNaN# (BYVAL n AS DOUBLE)
    FUNCTION Math_IsLongEven%% (BYVAL n AS LONG)
    FUNCTION Math_IsInteger64Even%% (BYVAL n AS _INTEGER64)
    FUNCTION Math_IsLongPowerOf2%% ALIAS "Math_IsPowerOf2" (BYVAL n AS _UNSIGNED LONG)
    FUNCTION Math_IsInteger64PowerOf2%% ALIAS "Math_IsPowerOf2" (BYVAL n AS _UNSIGNED _INTEGER64)
    FUNCTION Math_RoundUpLongToPowerOf2~& ALIAS "Math_RoundUpToPowerOf2" (BYVAL n AS _UNSIGNED LONG)
    FUNCTION Math_RoundUpInteger64ToPowerOf2~&& ALIAS "Math_RoundUpToPowerOf2" (BYVAL n AS _UNSIGNED _INTEGER64)
    FUNCTION Math_RoundDownLongToPowerOf2~& ALIAS "Math_RoundDownToPowerOf2" (BYVAL n AS _UNSIGNED LONG)
    FUNCTION Math_RoundDownInteger64ToPowerOf2~&& ALIAS "Math_RoundDownToPowerOf2" (BYVAL n AS _UNSIGNED _INTEGER64)
    FUNCTION Math_GetDigitFromLong& (BYVAL n AS _UNSIGNED LONG, BYVAL p AS _UNSIGNED LONG)
    FUNCTION Math_GetDigitFromInteger64& (BYVAL n AS _UNSIGNED _INTEGER64, BYVAL p AS _UNSIGNED LONG)
    FUNCTION Math_AverageLong& (BYVAL x AS LONG, BYVAL y AS LONG)
    FUNCTION Math_AverageInteger64&& (BYVAL x AS _INTEGER64, BYVAL y AS _INTEGER64)
    FUNCTION Math_ClampLong& ALIAS "std::clamp<int32_t>" (BYVAL n AS LONG, BYVAL lo AS LONG, BYVAL hi AS LONG)
    FUNCTION Math_ClampInteger64&& ALIAS "std::clamp<int64_t>" (BYVAL n AS _INTEGER64, BYVAL lo AS _INTEGER64, BYVAL hi AS _INTEGER64)
    FUNCTION Math_ClampSingle! ALIAS "std::clamp<float>" (BYVAL n AS SINGLE, BYVAL lo AS SINGLE, BYVAL hi AS SINGLE)
    FUNCTION Math_ClampDouble# ALIAS "std::clamp<double>" (BYVAL n AS DOUBLE, BYVAL lo AS DOUBLE, BYVAL hi AS DOUBLE)
    FUNCTION Math_RemapLong& (BYVAL value AS LONG, BYVAL oldMin AS LONG, BYVAL oldMax AS LONG, BYVAL newMin AS LONG, BYVAL newMax AS LONG)
    FUNCTION Math_RemapInteger64&& (BYVAL value AS _INTEGER64, BYVAL oldMin AS _INTEGER64, BYVAL oldMax AS _INTEGER64, BYVAL newMin AS _INTEGER64, BYVAL newMax AS _INTEGER64)
    FUNCTION Math_RemapSingle! (BYVAL value AS SINGLE, BYVAL oldMin AS SINGLE, BYVAL oldMax AS SINGLE, BYVAL newMin AS SINGLE, BYVAL newMax AS SINGLE)
    FUNCTION Math_RemapDouble# (BYVAL value AS DOUBLE, BYVAL oldMin AS DOUBLE, BYVAL oldMax AS DOUBLE, BYVAL newMin AS DOUBLE, BYVAL newMax AS DOUBLE)
    FUNCTION Math_GetMaxSingle! ALIAS "std::fmax" (BYVAL a AS SINGLE, BYVAL b AS SINGLE)
    FUNCTION Math_GetMinSingle! ALIAS "std::fmin" (BYVAL a AS SINGLE, BYVAL b AS SINGLE)
    FUNCTION Math_GetMaxDouble# ALIAS "std::fmax" (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
    FUNCTION Math_GetMinDouble# ALIAS "std::fmin" (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
    FUNCTION Math_GetMaxLong& ALIAS "std::max<int32_t>" (BYVAL a AS LONG, BYVAL b AS LONG)
    FUNCTION Math_GetMinLong& ALIAS "std::min<int32_t>" (BYVAL a AS LONG, BYVAL b AS LONG)
    FUNCTION Math_GetMaxInteger64&& ALIAS "std::max<int64_t>" (BYVAL a AS _INTEGER64, BYVAL b AS _INTEGER64)
    FUNCTION Math_GetMinInteger64&& ALIAS "std::min<int64_t>" (BYVAL a AS _INTEGER64, BYVAL b AS _INTEGER64)
    FUNCTION Math_LerpSingle! (BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE, BYVAL amount AS SINGLE)
    FUNCTION Math_LerpDouble# (BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE, BYVAL amount AS DOUBLE)
    FUNCTION Math_NormalizeSingle! (BYVAL value AS SINGLE, BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE)
    FUNCTION Math_NormalizeDouble# (BYVAL value AS DOUBLE, BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE)
    FUNCTION Math_WrapSingle! (BYVAL value AS SINGLE, BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE)
    FUNCTION Math_WrapDouble# (BYVAL value AS DOUBLE, BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE)
    FUNCTION Math_IsSingleEqual%% (BYVAL x AS SINGLE, BYVAL y AS SINGLE)
    FUNCTION Math_IsDoubleEqual%% (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE)
    FUNCTION Math_FMASingle! ALIAS "std::fma" (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
    FUNCTION Math_FMADouble# ALIAS "std::fma" (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
    FUNCTION Math_PowerSingle! ALIAS "std::pow" (BYVAL b AS SINGLE, BYVAL e AS SINGLE)
    FUNCTION Math_PowerDouble# ALIAS "std::pow" (BYVAL b AS DOUBLE, BYVAL e AS DOUBLE)
    FUNCTION Math_FastPowerSingle! ALIAS "__builtin_powif" (BYVAL b AS SINGLE, BYVAL e AS LONG)
    FUNCTION Math_FastPowerDouble# ALIAS "__builtin_powi" (BYVAL b AS DOUBLE, BYVAL e AS LONG)
    FUNCTION Math_FastSqRt! (BYVAL n AS SINGLE)
    FUNCTION Math_FastInvSqRt! (BYVAL n AS SINGLE)
    FUNCTION Math_Log10Single! ALIAS "std::log10" (BYVAL n AS SINGLE)
    FUNCTION Math_Log10Double# ALIAS "std::log10" (BYVAL n AS DOUBLE)
    FUNCTION Math_Log2Single! ALIAS "std::log2" (BYVAL n AS SINGLE)
    FUNCTION Math_Log2Double# ALIAS "std::log2" (BYVAL n AS DOUBLE)
    FUNCTION Math_CbRtSingle! ALIAS "std::cbrt" (BYVAL n AS SINGLE)
    FUNCTION Math_CbRtDouble# ALIAS "std::cbrt" (BYVAL n AS DOUBLE)
    FUNCTION Math_MulDivULong& ALIAS "Math_MulDiv" (BYVAL v AS _UNSIGNED LONG, BYVAL m AS _UNSIGNED LONG, BYVAL d AS _UNSIGNED LONG)
    FUNCTION Math_MulDivLong& ALIAS "Math_MulDiv" (BYVAL v AS LONG, BYVAL m AS LONG, BYVAL d AS LONG)
    FUNCTION Math_MulDivUInteger64&& ALIAS "Math_MulDiv" (BYVAL v AS _UNSIGNED _INTEGER64, BYVAL m AS _UNSIGNED _INTEGER64, BYVAL d AS _UNSIGNED _INTEGER64)
    FUNCTION Math_MulDivInteger64&& ALIAS "Math_MulDiv" (BYVAL v AS _INTEGER64, BYVAL m AS _INTEGER64, BYVAL d AS _INTEGER64)
    FUNCTION Math_IsLongInRange%% ALIAS "Math_IsInRange" (BYVAL n AS LONG, BYVAL lo AS LONG, BYVAL hi AS LONG)
    FUNCTION Math_IsInteger64InRange%% ALIAS "Math_IsInRange" (BYVAL n AS _INTEGER64, BYVAL lo AS _INTEGER64, BYVAL hi AS _INTEGER64)
    FUNCTION Math_IsSingleInRange%% ALIAS "Math_IsInRange" (BYVAL n AS SINGLE, BYVAL lo AS SINGLE, BYVAL hi AS SINGLE)
    FUNCTION Math_IsDoubleInRange%% ALIAS "Math_IsInRange" (BYVAL n AS DOUBLE, BYVAL lo AS DOUBLE, BYVAL hi AS DOUBLE)
END DECLARE
