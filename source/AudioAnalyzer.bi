'-----------------------------------------------------------------------------------------------------------------------
' Audio spectrum analyzer FFT
' Copyright (c) 2026 Samuel Gomes
'
' This is a heavily modified port from Open Cubic Player:
' https://www.cubic.org/player/
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

CONST __AA_FFT_POWER& = 11
CONST __AA_NUM_SAMPLES& = 2 ^ __AA_FFT_POWER
CONST __AA_HALF_SAMPLES& = __AA_NUM_SAMPLES \ 2
CONST __AA_QUARTER_SAMPLES& = __AA_HALF_SAMPLES \ 2
CONST __AA_SCALE_FACTOR& = 2 ^ 28
CONST __AA_F32_TO_S16_MULTIPLIER! = 32767!

DIM SHARED __AA_bitReversalTable(0 TO __AA_NUM_SAMPLES - 1) AS _UNSIGNED INTEGER
DIM SHARED __AA_sinCosTable(0 TO 2 * __AA_HALF_SAMPLES - 1) AS LONG
DIM SHARED __AA_fftBuffer(0 TO 2 * __AA_NUM_SAMPLES - 1) AS LONG
DIM SHARED __AA_initialized AS _BYTE

''' @brief Initializes FFT lookup tables (sine, cosine, and bit-reversal tables).
SUB __AA_Init
    IF __AA_initialized THEN EXIT SUB

    DIM i AS LONG
    DIM angle AS DOUBLE

    FOR i = 0 TO __AA_QUARTER_SAMPLES - 1
        angle = _PI(2.0# * i) / (4.0# * __AA_QUARTER_SAMPLES)
        __AA_sinCosTable(i * 2) = INT(COS(angle) * __AA_SCALE_FACTOR)
        __AA_sinCosTable(i * 2 + 1) = INT(SIN(angle) * __AA_SCALE_FACTOR)
    NEXT

    DIM reversedIndex AS LONG
    DIM stp AS LONG

    FOR i = 0 TO __AA_NUM_SAMPLES - 1
        __AA_bitReversalTable(i) = reversedIndex

        stp = __AA_HALF_SAMPLES
        WHILE stp <> 0 _ANDALSO stp <= reversedIndex
            reversedIndex = reversedIndex - stp
            stp = _SHR(stp, 1)
        WEND

        reversedIndex = reversedIndex + stp
    NEXT

    FOR i = __AA_HALF_SAMPLES \ 4 + 1 TO __AA_HALF_SAMPLES \ 2
        DIM mirrorIdx AS LONG
        mirrorIdx = __AA_HALF_SAMPLES \ 2 - i
        __AA_sinCosTable(i * 2) = __AA_sinCosTable(mirrorIdx * 2 + 1)
        __AA_sinCosTable(i * 2 + 1) = __AA_sinCosTable(mirrorIdx * 2)
    NEXT

    FOR i = __AA_HALF_SAMPLES \ 2 + 1 TO __AA_HALF_SAMPLES - 1
        DIM negMirrorIdx AS LONG
        negMirrorIdx = __AA_HALF_SAMPLES - i
        __AA_sinCosTable(i * 2) = -__AA_sinCosTable(negMirrorIdx * 2)
        __AA_sinCosTable(i * 2 + 1) = __AA_sinCosTable(negMirrorIdx * 2 + 1)
    NEXT

    __AA_initialized = _TRUE
END SUB

''' @brief Computes a single radix-2 butterfly calculation on the FFT buffer.
''' @param sampleIdx Buffer index of the first sample.
''' @param scCos Fixed-point cosine twiddle factor.
''' @param scSin Fixed-point sine twiddle factor.
''' @param distance Offset distance to the second sample in the buffer.
SUB __AA_CalculateFFT (sampleIdx AS LONG, scCos AS LONG, scSin AS LONG, distance AS LONG)
    DIM realPart AS LONG: realPart = __AA_fftBuffer(sampleIdx) - __AA_fftBuffer(sampleIdx + distance)
    __AA_fftBuffer(sampleIdx) = _SHR(__AA_fftBuffer(sampleIdx) + __AA_fftBuffer(sampleIdx + distance), 1)

    DIM imagPart AS LONG: imagPart = __AA_fftBuffer(sampleIdx + 1) - __AA_fftBuffer(sampleIdx + distance + 1)
    __AA_fftBuffer(sampleIdx + 1) = _SHR(__AA_fftBuffer(sampleIdx + 1) + __AA_fftBuffer(sampleIdx + distance + 1), 1)

    __AA_fftBuffer(sampleIdx + distance) = _SHR(_CAST(_INTEGER64, realPart) * _CAST(_INTEGER64, scCos), 29) - _SHR(_CAST(_INTEGER64, imagPart) * _CAST(_INTEGER64, scSin), 29)
    __AA_fftBuffer(sampleIdx + distance + 1) = _SHR(_CAST(_INTEGER64, realPart) * _CAST(_INTEGER64, scSin), 29) + _SHR(_CAST(_INTEGER64, imagPart) * _CAST(_INTEGER64, scCos), 29)
END SUB

''' @brief Executes butterfly operations across all stages for the specified FFT bit depth.
''' @param stage The FFT stage / bit depth to compute.
SUB __AA_PerformButterflyOperation (stage AS LONG)
    DIM lastStageIdx AS LONG: lastStageIdx = _SHL(1, stage) * 2
    DIM i AS LONG, j AS LONG
    DIM stepSize AS LONG, distance AS LONG
    DIM scIdx AS LONG
    DIM scCos AS LONG, scSin AS LONG
    DIM sampleIdx AS LONG

    FOR i = __AA_FFT_POWER - stage TO __AA_FFT_POWER - 1
        stepSize = _SHR(__AA_HALF_SAMPLES, i)
        distance = 2 * stepSize

        FOR j = 0 TO stepSize - 1
            scIdx = _SHL(j, i)
            scCos = __AA_sinCosTable(scIdx * 2)
            scSin = __AA_sinCosTable(scIdx * 2 + 1)

            sampleIdx = j * 2
            WHILE sampleIdx < lastStageIdx
                __AA_CalculateFFT sampleIdx, scCos, scSin, distance
                sampleIdx = sampleIdx + 2 * distance
            WEND
        NEXT j
    NEXT i
END SUB

''' @brief Computes FFT spectrum and signal intensity for 32-bit floating-point audio samples.
''' @param amplitudeArray() Output array of _UNSIGNED INTEGER amplitude values (must have at least (1 SHL bitDepth) / 2 elements).
''' @param sampleDataArray() Input array of SINGLE (fp32) audio samples (range -1.0 to 1.0).
''' @param sampleOffset Offset from LBOUND(sampleDataArray) to begin reading samples (e.g., 0 for left/mono, 1 for right).
''' @param sampleIncrement Stride between consecutive samples (1 for mono, 2 for stereo interleaved).
''' @param bitDepth Log2 of the number of samples to process (e.g., 10 = 1024 samples).
''' @return Average signal intensity (RMS energy measure) as SINGLE.
FUNCTION AudioAnalyzer_CalculateFFT! (amplitudeArray() AS _UNSIGNED INTEGER, sampleDataArray() AS SINGLE, sampleOffset AS LONG, sampleIncrement AS LONG, bitDepth AS LONG)
    __AA_Init

    DIM numSamples AS LONG: numSamples = _SHL(1, bitDepth)
    DIM halfNumSamples AS LONG: halfNumSamples = _SHR(numSamples, 1)
    DIM samplePos AS LONG: samplePos = LBOUND(sampleDataArray) + sampleOffset
    DIM averageIntensity AS SINGLE
    DIM i AS LONG

    FOR i = 0 TO numSamples - 1
        DIM sample AS SINGLE: sample = _CLAMP(sampleDataArray(samplePos), -1!, 1)

        __AA_fftBuffer(i * 2) = _SHL(INT(sample * __AA_F32_TO_S16_MULTIPLIER), 12)
        __AA_fftBuffer(i * 2 + 1) = 0

        averageIntensity = averageIntensity + sample * sample

        samplePos = samplePos + sampleIncrement
    NEXT

    averageIntensity = averageIntensity / CSNG(numSamples)

    __AA_PerformButterflyOperation bitDepth

    DIM shiftAmount AS LONG: shiftAmount = __AA_FFT_POWER - bitDepth

    FOR i = 1 TO halfNumSamples
        DIM revIdx AS LONG: revIdx = _SHR(__AA_bitReversalTable(i), shiftAmount)
        DIM realPart AS LONG: realPart = _SHR(__AA_fftBuffer(revIdx * 2), 12)
        DIM imagPart AS LONG: imagPart = _SHR(__AA_fftBuffer(revIdx * 2 + 1), 12)
        DIM magnitude AS DOUBLE: magnitude = _CLAMP(SQR(CDBL(realPart) * CDBL(realPart) + CDBL(imagPart) * CDBL(imagPart)) * SQR(CDBL(i)), 0.0#, 65535.0#)

        amplitudeArray(LBOUND(amplitudeArray) + i - 1) = _CAST(_UNSIGNED INTEGER, magnitude)
    NEXT

    AudioAnalyzer_CalculateFFT = averageIntensity
END FUNCTION
