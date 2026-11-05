'-----------------------------------------------------------------------------------------------------------------------
' FFT routines for audio spectrum analyzers - Pure QB64-PE implementation
' Copyright (c) 2024 Samuel Gomes
' Copyright (c) 2004-2022 Stian Skjelstad
' Copyright (c) 1994-2005 Niklas Beisert
'
' Ported from the C++ DECLARE LIBRARY implementation to native QB64-PE.
' Original code from Open Cubic Player: https://www.cubic.org/player/
'
' This performs a fixed-point radix-2 DIT FFT for real-time audio spectrum visualization.
' It computes the amplitude spectrum for positive frequencies only.
'
' Public API:
' AudioAnalyzerFFT_DoInteger!(amplitudeArray(), sampleDataArray(), sampleIncrement, bitDepth)
' AudioAnalyzerFFT_DoSingle!(amplitudeArray(), sampleDataArray(), sampleIncrement, bitDepth)
'
' NOTE: The API now takes arrays directly instead of passing first-element references
' through DECLARE LIBRARY. Calling code change:
' OLD: AudioAnalyzerFFT_DoSingle(outp(0), buffer(0), 1, 10)
' NEW: AudioAnalyzerFFT_DoSingle(outp(), buffer(), 1, 10)
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

CONST __AA_FFT_POWER = 11
CONST __AA_NUM_SAMPLES = 2048 ' 1 << 11
CONST __AA_HALF_SAMPLES = 1024 ' NUM_SAMPLES >> 1
CONST __AA_QUARTER_SAMPLES = 512 ' HALF_SAMPLES >> 1
CONST __AA_SCALE_FACTOR& = 268435456 ' 1 << 28
CONST __AA_S16_TO_F32_MULTIPLIER! = 1! / 32768!
CONST __AA_F32_TO_S16_MULTIPLIER! = 32767!

DIM SHARED __AA_bitReversalTable(__AA_NUM_SAMPLES - 1) AS _UNSIGNED INTEGER
DIM SHARED __AA_sinCosTable(2 * __AA_HALF_SAMPLES - 1) AS LONG ' flattened [HALF_SAMPLES]
DIM SHARED __AA_fftBuffer(2 * __AA_NUM_SAMPLES - 1) AS LONG ' flattened [NUM_SAMPLES]
DIM SHARED __AA_initialized AS _BYTE

SUB __AudioAnalyzer_Init
    IF __AA_initialized THEN EXIT SUB

    DIM i AS LONG
    DIM angle AS DOUBLE

    ' Build sin/cos table for the first quadrant
    FOR i = 0 TO __AA_QUARTER_SAMPLES - 1
        angle = (2.0# * _PI * i) / (4.0# * __AA_QUARTER_SAMPLES)
        __AA_sinCosTable(i * 2) = INT(COS(angle) * __AA_SCALE_FACTOR) ' [i][0] = cos
        __AA_sinCosTable(i * 2 + 1) = INT(SIN(angle) * __AA_SCALE_FACTOR) ' [i][1] = sin
    NEXT

    ' Build bit-reversal table
    DIM reversedIndex AS LONG
    DIM stp AS LONG
    reversedIndex = 0

    FOR i = 0 TO __AA_NUM_SAMPLES - 1
        __AA_bitReversalTable(i) = reversedIndex

        stp = __AA_HALF_SAMPLES
        DO WHILE stp <> 0 AND stp <= reversedIndex
            reversedIndex = reversedIndex - stp
            stp = _SHR(stp, 1)
        LOOP
        reversedIndex = reversedIndex + stp
    NEXT

    ' Extend sin/cos table: second octant (mirror)
    ' indices QUARTER_SAMPLES/2 + 1 to QUARTER_SAMPLES (i.e., HALF_SAMPLES/4 + 1 to HALF_SAMPLES/2)
    FOR i = __AA_HALF_SAMPLES \ 4 + 1 TO __AA_HALF_SAMPLES \ 2
        DIM mirrorIdx AS LONG
        mirrorIdx = __AA_HALF_SAMPLES \ 2 - i
        __AA_sinCosTable(i * 2) = __AA_sinCosTable(mirrorIdx * 2 + 1) ' cos = sin of mirror
        __AA_sinCosTable(i * 2 + 1) = __AA_sinCosTable(mirrorIdx * 2) ' sin = cos of mirror
    NEXT

    ' Extend sin/cos table: second quadrant
    ' indices HALF_SAMPLES/2 + 1 to HALF_SAMPLES - 1
    FOR i = __AA_HALF_SAMPLES \ 2 + 1 TO __AA_HALF_SAMPLES - 1
        DIM negMirrorIdx AS LONG
        negMirrorIdx = __AA_HALF_SAMPLES - i
        __AA_sinCosTable(i * 2) = -__AA_sinCosTable(negMirrorIdx * 2) ' cos negated
        __AA_sinCosTable(i * 2 + 1) = __AA_sinCosTable(negMirrorIdx * 2 + 1) ' sin same
    NEXT

    __AA_initialized = _TRUE
END SUB

' =====================================================================================================================
' HELPER: Signed arithmetic right shift for LONG (>> with sign extension)
' =====================================================================================================================
FUNCTION __AA_SAR& (value AS LONG, bits AS LONG)
    IF value >= 0 THEN
        __AA_SAR = _SHR(value, bits)
    ELSE
        __AA_SAR = NOT _SHR(NOT value, bits)
    END IF
END FUNCTION

' =====================================================================================================================
' HELPER: Signed arithmetic right shift for _INTEGER64 (>> with sign extension)
' =====================================================================================================================
FUNCTION __AA_SAR64&& (value AS _INTEGER64, bits AS LONG)
    IF value >= 0 THEN
        __AA_SAR64 = _SHR(value, bits)
    ELSE
        __AA_SAR64 = NOT _SHR(NOT value, bits)
    END IF
END FUNCTION

' =====================================================================================================================
' HELPER: Fixed-point multiply with 29-bit right shift
' int32_t((int64_t(a) * int64_t(b)) >> 29)
' =====================================================================================================================
FUNCTION __AA_MultiplyShift29& (a AS LONG, b AS LONG)
    DIM product AS _INTEGER64
    product = _CAST(_INTEGER64, a) * _CAST(_INTEGER64, b)
    __AA_MultiplyShift29 = __AA_SAR64(product, 29)
END FUNCTION

' =====================================================================================================================
' CORE: Single butterfly calculation
' Operates on __AA_fftBuffer at flat indices sampleIdx and sampleIdx + distance
' =====================================================================================================================
SUB __AA_CalculateFFT (sampleIdx AS LONG, scCos AS LONG, scSin AS LONG, distance AS LONG)
    DIM realPart AS LONG
    DIM imagPart AS LONG

    ' Butterfly: split into sum and difference
    realPart = __AA_fftBuffer(sampleIdx) - __AA_fftBuffer(sampleIdx + distance)
    __AA_fftBuffer(sampleIdx) = __AA_SAR(__AA_fftBuffer(sampleIdx) + __AA_fftBuffer(sampleIdx + distance), 1)

    imagPart = __AA_fftBuffer(sampleIdx + 1) - __AA_fftBuffer(sampleIdx + distance + 1)
    __AA_fftBuffer(sampleIdx + 1) = __AA_SAR(__AA_fftBuffer(sampleIdx + 1) + __AA_fftBuffer(sampleIdx + distance + 1), 1)

    ' Twiddle factor rotation
    __AA_fftBuffer(sampleIdx + distance) = __AA_MultiplyShift29(realPart, scCos) - __AA_MultiplyShift29(imagPart, scSin)
    __AA_fftBuffer(sampleIdx + distance + 1) = __AA_MultiplyShift29(realPart, scSin) + __AA_MultiplyShift29(imagPart, scCos)
END SUB

' =====================================================================================================================
' CORE: Perform all butterfly stages of the FFT
' stage = bitDepth (number of stages to perform)
' =====================================================================================================================
SUB __AA_PerformButterflyOperation (stage AS LONG)
    ' lastStageIdx is the flat index corresponding to data[1 << stage]
    ' Since data is [N], flat index = (1 << stage) * 2
    DIM lastStageIdx AS LONG
    lastStageIdx = _SHL(1, stage) * 2

    DIM i AS LONG, j AS LONG
    DIM stepSize AS LONG, distance AS LONG
    DIM scIdx AS LONG
    DIM scCos AS LONG, scSin AS LONG
    DIM sampleIdx AS LONG

    FOR i = __AA_FFT_POWER - stage TO __AA_FFT_POWER - 1
        stepSize = _SHR(__AA_HALF_SAMPLES, i)
        distance = 2 * stepSize ' distance in int32 (flat array) units

        FOR j = 0 TO stepSize - 1
            ' Look up sin/cos twiddle factor
            scIdx = _SHL(j, i)
            scCos = __AA_sinCosTable(scIdx * 2)
            scSin = __AA_sinCosTable(scIdx * 2 + 1)

            ' Walk through all pairs at this stride
            ' In C++: for (currentSample = data[j]; currentSample < lastStageData; currentSample += 2*distance)
            ' data[j] flat index = j * 2
            ' advance by 2*distance flat int32 units
            ' stop when flat index >= lastStageIdx
            sampleIdx = j * 2
            DO WHILE sampleIdx < lastStageIdx
                __AA_CalculateFFT sampleIdx, scCos, scSin, distance
                sampleIdx = sampleIdx + 2 * distance
            LOOP
        NEXT j
    NEXT i
END SUB

' =====================================================================================================================
' PUBLIC API: FFT for 16-bit integer sample data
' =====================================================================================================================
' @param amplitudeArray() Output array of _UNSIGNED INTEGER amplitude values (must be at least (1<<bitDepth)/2 elements)
' @param sampleDataArray() Input array of INTEGER (16-bit signed) sample data
' @param sampleIncrement Step between consecutive samples (1 for mono, 2 for stereo interleaved)
' @param bitDepth Log2 of the number of samples to process (e.g., 10 = 1024 samples)
' @return Average intensity (RMS-like energy measure) of the input signal as SINGLE
FUNCTION AudioAnalyzerFFT_DoInteger! (amplitudeArray() AS _UNSIGNED INTEGER, sampleDataArray() AS INTEGER, sampleIncrement AS LONG, bitDepth AS LONG)
    $CHECKING:OFF
    __AudioAnalyzer_Init

    DIM numSamples AS LONG
    DIM halfNumSamples AS LONG
    DIM averageIntensity AS SINGLE
    DIM i AS LONG
    DIM samplePos AS LONG
    DIM sample AS SINGLE

    ' Clamp numSamples to our maximum buffer size
    numSamples = _SHL(1, bitDepth)
    IF numSamples > __AA_NUM_SAMPLES THEN numSamples = __AA_NUM_SAMPLES
    halfNumSamples = _SHR(numSamples, 1)
    averageIntensity = 0!

    ' Load sample data into FFT buffer (real part only, imaginary = 0)
    ' Samples are shifted left by 12 bits for fixed-point precision
    samplePos = LBOUND(sampleDataArray)
    FOR i = 0 TO numSamples - 1
        DIM rawSample AS LONG
        rawSample = sampleDataArray(samplePos)
        __AA_fftBuffer(i * 2) = _SHL(rawSample, 12) ' real part
        __AA_fftBuffer(i * 2 + 1) = 0 ' imaginary part

        sample = CSNG(rawSample) * __AA_S16_TO_F32_MULTIPLIER
        averageIntensity = averageIntensity + sample * sample

        samplePos = samplePos + sampleIncrement
    NEXT

    averageIntensity = averageIntensity / CSNG(numSamples)

    ' Perform the FFT
    __AA_PerformButterflyOperation bitDepth

    ' Extract amplitude spectrum for positive frequencies
    DIM shiftAmount AS LONG
    shiftAmount = __AA_FFT_POWER - bitDepth

    FOR i = 1 TO halfNumSamples
        DIM revIdx AS LONG
        DIM realPart AS LONG, imagPart AS LONG
        DIM magnitude AS DOUBLE

        revIdx = _SHR(__AA_bitReversalTable(i), shiftAmount)
        realPart = __AA_SAR(__AA_fftBuffer(revIdx * 2), 12)
        imagPart = __AA_SAR(__AA_fftBuffer(revIdx * 2 + 1), 12)

        magnitude = SQR(CDBL(realPart) * CDBL(realPart) + CDBL(imagPart) * CDBL(imagPart)) * SQR(CDBL(i))

        ' Clamp to uint16 range
        IF magnitude > 65535.0# THEN magnitude = 65535.0#
        IF magnitude < 0.0# THEN magnitude = 0.0#
        amplitudeArray(LBOUND(amplitudeArray) + i - 1) = _CAST(_UNSIGNED INTEGER, magnitude)
    NEXT

    AudioAnalyzerFFT_DoInteger = averageIntensity
    $CHECKING:ON
END FUNCTION

' =====================================================================================================================
' PUBLIC API: FFT for 32-bit floating-point sample data
' =====================================================================================================================
' @param amplitudeArray() Output array of _UNSIGNED INTEGER amplitude values (must be at least (1<<bitDepth)/2 elements)
' @param sampleDataArray() Input array of SINGLE (fp32) sample data (expected range -1.0 to 1.0)
' @param sampleIncrement Step between consecutive samples (1 for mono, 2 for stereo interleaved)
' @param bitDepth Log2 of the number of samples to process (e.g., 10 = 1024 samples)
' @return Average intensity (RMS-like energy measure) of the input signal as SINGLE
FUNCTION AudioAnalyzerFFT_DoSingle! (amplitudeArray() AS _UNSIGNED INTEGER, sampleDataArray() AS SINGLE, sampleIncrement AS LONG, bitDepth AS LONG)
    $CHECKING:OFF
    __AudioAnalyzer_Init

    DIM numSamples AS LONG
    DIM halfNumSamples AS LONG
    DIM averageIntensity AS SINGLE
    DIM i AS LONG
    DIM samplePos AS LONG
    DIM sample AS SINGLE

    ' Clamp numSamples to our maximum buffer size
    numSamples = _SHL(1, bitDepth)
    IF numSamples > __AA_NUM_SAMPLES THEN numSamples = __AA_NUM_SAMPLES
    halfNumSamples = _SHR(numSamples, 1)
    averageIntensity = 0!

    ' Load sample data into FFT buffer
    ' Clamp float to [-1, 1], convert to fixed-point << 12
    samplePos = LBOUND(sampleDataArray)
    FOR i = 0 TO numSamples - 1
        sample = sampleDataArray(samplePos)

        ' Clamp
        IF sample > 1! THEN sample = 1!
        IF sample < -1! THEN sample = -1!

        __AA_fftBuffer(i * 2) = _SHL(INT(sample * __AA_F32_TO_S16_MULTIPLIER), 12) ' real part
        __AA_fftBuffer(i * 2 + 1) = 0 ' imaginary part

        averageIntensity = averageIntensity + sample * sample

        samplePos = samplePos + sampleIncrement
    NEXT

    averageIntensity = averageIntensity / CSNG(numSamples)

    ' Perform the FFT
    __AA_PerformButterflyOperation bitDepth

    ' Extract amplitude spectrum for positive frequencies
    DIM shiftAmount AS LONG
    shiftAmount = __AA_FFT_POWER - bitDepth

    FOR i = 1 TO halfNumSamples
        DIM revIdx AS LONG
        DIM realPart AS LONG, imagPart AS LONG
        DIM magnitude AS DOUBLE

        revIdx = _SHR(__AA_bitReversalTable(i), shiftAmount)
        realPart = __AA_SAR(__AA_fftBuffer(revIdx * 2), 12)
        imagPart = __AA_SAR(__AA_fftBuffer(revIdx * 2 + 1), 12)

        magnitude = SQR(CDBL(realPart) * CDBL(realPart) + CDBL(imagPart) * CDBL(imagPart)) * SQR(CDBL(i))

        ' Clamp to uint16 range
        IF magnitude > 65535.0# THEN magnitude = 65535.0#
        IF magnitude < 0.0# THEN magnitude = 0.0#
        amplitudeArray(LBOUND(amplitudeArray) + i - 1) = _CAST(_UNSIGNED INTEGER, magnitude)
    NEXT

    AudioAnalyzerFFT_DoSingle = averageIntensity
    $CHECKING:ON
END FUNCTION
