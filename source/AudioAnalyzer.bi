'-----------------------------------------------------------------------------------------------------------------------
' Audio spectrum analyzer FFT
' Copyright (c) 2026 Samuel Gomes
'
' This is a heavily modified port from Open Cubic Player:
' https://www.cubic.org/player/
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

' Public constants
CONST AUDIO_ANALYZER_MAX_BIT_DEPTH = 11
CONST AUDIO_ANALYZER_MAX_SAMPLES = 2 ^ AUDIO_ANALYZER_MAX_BIT_DEPTH ' 2048
CONST AUDIO_ANALYZER_MAX_BINS = AUDIO_ANALYZER_MAX_SAMPLES \ 2 ' 1024

' Internal constants
CONST __AUDIO_ANALYZER_HALF_SAMPLES = AUDIO_ANALYZER_MAX_BINS
CONST __AUDIO_ANALYZER_QUARTER_SAMPLES = __AUDIO_ANALYZER_HALF_SAMPLES \ 2
CONST __AUDIO_ANALYZER_SCALE_FACTOR& = 2 ^ 28
CONST __AUDIO_ANALYZER_F32_TO_S16! = 32767!

' Lookup tables
DIM __AudioAnalyzer_BitReversalTable(0 TO AUDIO_ANALYZER_MAX_SAMPLES - 1) AS _UNSIGNED INTEGER
DIM __AudioAnalyzer_SinCosTable(0 TO 2 * __AUDIO_ANALYZER_HALF_SAMPLES - 1) AS LONG
DIM __AudioAnalyzer_TablesInitialized AS _BYTE

' Main audio analyzer context - holds instance-specific FFT working buffer and analysis metrics
TYPE AudioAnalyzer
    fftBuffer(0 TO 2 * AUDIO_ANALYZER_MAX_SAMPLES - 1) AS LONG
    averageIntensity AS SINGLE
    peakAmplitude AS _UNSIGNED INTEGER
    peakBin AS LONG
    initialized AS _BYTE
END TYPE

''' @brief Initializes FFT lookup tables (sine, cosine, and bit-reversal tables).
SUB __AudioAnalyzer_Init
    SHARED __AudioAnalyzer_BitReversalTable() AS _UNSIGNED INTEGER
    SHARED __AudioAnalyzer_SinCosTable() AS LONG
    SHARED __AudioAnalyzer_TablesInitialized AS _BYTE

    IF __AudioAnalyzer_TablesInitialized THEN EXIT SUB

    DIM i AS LONG
    DIM angle AS DOUBLE

    FOR i = 0 TO __AUDIO_ANALYZER_QUARTER_SAMPLES - 1
        angle = _PI(2.0# * i) / (4.0# * __AUDIO_ANALYZER_QUARTER_SAMPLES)
        __AudioAnalyzer_SinCosTable(i * 2) = INT(COS(angle) * __AUDIO_ANALYZER_SCALE_FACTOR)
        __AudioAnalyzer_SinCosTable(i * 2 + 1) = INT(SIN(angle) * __AUDIO_ANALYZER_SCALE_FACTOR)
    NEXT

    DIM reversedIndex AS LONG
    DIM stp AS LONG

    FOR i = 0 TO AUDIO_ANALYZER_MAX_SAMPLES - 1
        __AudioAnalyzer_BitReversalTable(i) = reversedIndex

        stp = __AUDIO_ANALYZER_HALF_SAMPLES
        WHILE stp <> 0 _ANDALSO stp <= reversedIndex
            reversedIndex = reversedIndex - stp
            stp = _SHR(stp, 1)
        WEND

        reversedIndex = reversedIndex + stp
    NEXT

    FOR i = __AUDIO_ANALYZER_HALF_SAMPLES \ 4 + 1 TO __AUDIO_ANALYZER_HALF_SAMPLES \ 2
        DIM mirrorIdx AS LONG
        mirrorIdx = __AUDIO_ANALYZER_HALF_SAMPLES \ 2 - i
        __AudioAnalyzer_SinCosTable(i * 2) = __AudioAnalyzer_SinCosTable(mirrorIdx * 2 + 1)
        __AudioAnalyzer_SinCosTable(i * 2 + 1) = __AudioAnalyzer_SinCosTable(mirrorIdx * 2)
    NEXT

    FOR i = __AUDIO_ANALYZER_HALF_SAMPLES \ 2 + 1 TO __AUDIO_ANALYZER_HALF_SAMPLES - 1
        DIM negMirrorIdx AS LONG
        negMirrorIdx = __AUDIO_ANALYZER_HALF_SAMPLES - i
        __AudioAnalyzer_SinCosTable(i * 2) = -__AudioAnalyzer_SinCosTable(negMirrorIdx * 2)
        __AudioAnalyzer_SinCosTable(i * 2 + 1) = __AudioAnalyzer_SinCosTable(negMirrorIdx * 2 + 1)
    NEXT

    __AudioAnalyzer_TablesInitialized = _TRUE
END SUB

''' @brief Checks whether the audio analyzer instance is initialized.
''' @param analyzer Audio analyzer context.
''' @return _TRUE if initialized, _FALSE otherwise.
FUNCTION AudioAnalyzer_IsInitialized%% (analyzer AS AudioAnalyzer)
    AudioAnalyzer_IsInitialized = analyzer.initialized
END FUNCTION

''' @brief Initializes an audio analyzer instance and ensures shared lookup tables are ready.
''' @param analyzer Audio analyzer context.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION AudioAnalyzer_Initialize%% (analyzer AS AudioAnalyzer)
    __AudioAnalyzer_Init
    analyzer.averageIntensity = 0!
    analyzer.peakAmplitude = 0
    analyzer.peakBin = 0
    analyzer.initialized = _TRUE
    AudioAnalyzer_Initialize = _TRUE
END FUNCTION

''' @brief Finalizes an audio analyzer instance.
''' @param analyzer Audio analyzer context.
SUB AudioAnalyzer_Finalize (analyzer AS AudioAnalyzer)
    analyzer.averageIntensity = 0!
    analyzer.peakAmplitude = 0
    analyzer.peakBin = 0
    analyzer.initialized = _FALSE
END SUB

''' @brief Gets the average audio signal intensity (mean squared amplitude, 0.0 - 1.0).
''' @param analyzer Audio analyzer context.
''' @return Average signal intensity as SINGLE.
FUNCTION AudioAnalyzer_GetAverageIntensity! (analyzer AS AudioAnalyzer)
    AudioAnalyzer_GetAverageIntensity = analyzer.averageIntensity
END FUNCTION

''' @brief Gets the RMS (Root Mean Square) signal level (0.0 - 1.0).
''' @param analyzer Audio analyzer context.
''' @return RMS signal level as SINGLE.
FUNCTION AudioAnalyzer_GetRMS! (analyzer AS AudioAnalyzer)
    AudioAnalyzer_GetRMS = SQR(analyzer.averageIntensity)
END FUNCTION

''' @brief Gets the peak amplitude across all frequency bins from the last FFT.
''' @param analyzer Audio analyzer context.
''' @return Peak amplitude as _UNSIGNED INTEGER.
FUNCTION AudioAnalyzer_GetPeakAmplitude~% (analyzer AS AudioAnalyzer)
    AudioAnalyzer_GetPeakAmplitude = analyzer.peakAmplitude
END FUNCTION

''' @brief Gets the 0-based frequency bin index of the peak amplitude from the last FFT.
''' @param analyzer Audio analyzer context.
''' @return Frequency bin index as LONG.
FUNCTION AudioAnalyzer_GetPeakBin& (analyzer AS AudioAnalyzer)
    AudioAnalyzer_GetPeakBin = analyzer.peakBin
END FUNCTION

''' @brief Computes a single radix-2 butterfly calculation on the analyzer's FFT buffer.
''' @param analyzer Audio analyzer context.
''' @param sampleIdx Buffer index of the first sample.
''' @param scCos Fixed-point cosine twiddle factor.
''' @param scSin Fixed-point sine twiddle factor.
''' @param distance Offset distance to the second sample in the buffer.
SUB __AudioAnalyzer_CalculateFFT (analyzer AS AudioAnalyzer, sampleIdx AS LONG, scCos AS LONG, scSin AS LONG, distance AS LONG)
    DIM realPart AS LONG: realPart = analyzer.fftBuffer(sampleIdx) - analyzer.fftBuffer(sampleIdx + distance)
    analyzer.fftBuffer(sampleIdx) = _SHR(analyzer.fftBuffer(sampleIdx) + analyzer.fftBuffer(sampleIdx + distance), 1)

    DIM imagPart AS LONG: imagPart = analyzer.fftBuffer(sampleIdx + 1) - analyzer.fftBuffer(sampleIdx + distance + 1)
    analyzer.fftBuffer(sampleIdx + 1) = _SHR(analyzer.fftBuffer(sampleIdx + 1) + analyzer.fftBuffer(sampleIdx + distance + 1), 1)

    analyzer.fftBuffer(sampleIdx + distance) = _SHR(_CAST(_INTEGER64, realPart) * _CAST(_INTEGER64, scCos), 29) - _SHR(_CAST(_INTEGER64, imagPart) * _CAST(_INTEGER64, scSin), 29)
    analyzer.fftBuffer(sampleIdx + distance + 1) = _SHR(_CAST(_INTEGER64, realPart) * _CAST(_INTEGER64, scSin), 29) + _SHR(_CAST(_INTEGER64, imagPart) * _CAST(_INTEGER64, scCos), 29)
END SUB

''' @brief Executes butterfly operations across all stages for the specified FFT bit depth.
''' @param analyzer Audio analyzer context.
''' @param stage The FFT stage / bit depth to compute.
SUB __AudioAnalyzer_PerformButterfly (analyzer AS AudioAnalyzer, stage AS LONG)
    SHARED __AudioAnalyzer_SinCosTable() AS LONG

    DIM lastStageIdx AS LONG: lastStageIdx = _SHL(1, stage) * 2
    DIM i AS LONG, j AS LONG
    DIM stepSize AS LONG, distance AS LONG
    DIM scIdx AS LONG
    DIM scCos AS LONG, scSin AS LONG
    DIM sampleIdx AS LONG

    FOR i = AUDIO_ANALYZER_MAX_BIT_DEPTH - stage TO AUDIO_ANALYZER_MAX_BIT_DEPTH - 1
        stepSize = _SHR(__AUDIO_ANALYZER_HALF_SAMPLES, i)
        distance = 2 * stepSize

        FOR j = 0 TO stepSize - 1
            scIdx = _SHL(j, i)
            scCos = __AudioAnalyzer_SinCosTable(scIdx * 2)
            scSin = __AudioAnalyzer_SinCosTable(scIdx * 2 + 1)

            sampleIdx = j * 2
            WHILE sampleIdx < lastStageIdx
                __AudioAnalyzer_CalculateFFT analyzer, sampleIdx, scCos, scSin, distance
                sampleIdx = sampleIdx + 2 * distance
            WEND
        NEXT j
    NEXT i
END SUB

''' @brief Computes FFT spectrum and signal metrics for 32-bit floating-point audio samples.
''' @param analyzer Audio analyzer context.
''' @param amplitudeArray() Output array of _UNSIGNED INTEGER amplitude values (must have at least (1 SHL bitDepth) / 2 elements).
''' @param sampleDataArray() Input array of SINGLE (fp32) audio samples (range -1.0 to 1.0).
''' @param sampleOffset Offset from LBOUND(sampleDataArray) to begin reading samples (e.g., 0 for left/mono, 1 for right).
''' @param sampleIncrement Stride between consecutive samples (1 for mono, 2 for stereo interleaved).
''' @param bitDepth Log2 of the number of samples to process (e.g., 10 = 1024 samples).
SUB AudioAnalyzer_CalculateFFT (analyzer AS AudioAnalyzer, amplitudeArray() AS _UNSIGNED INTEGER, sampleDataArray() AS SINGLE, sampleOffset AS LONG, sampleIncrement AS LONG, bitDepth AS LONG)
    SHARED __AudioAnalyzer_BitReversalTable() AS _UNSIGNED INTEGER

    IF NOT analyzer.initialized THEN
        DIM ignored AS _BYTE: ignored = AudioAnalyzer_Initialize(analyzer)
    END IF

    IF bitDepth < 1 _ORELSE bitDepth > AUDIO_ANALYZER_MAX_BIT_DEPTH THEN EXIT SUB

    DIM numSamples AS LONG: numSamples = _SHL(1, bitDepth)
    DIM halfNumSamples AS LONG: halfNumSamples = _SHR(numSamples, 1)

    IF UBOUND(amplitudeArray) - LBOUND(amplitudeArray) + 1 < halfNumSamples THEN EXIT SUB

    DIM lastSamplePos AS LONG: lastSamplePos = LBOUND(sampleDataArray) + sampleOffset + (numSamples - 1) * sampleIncrement
    IF sampleOffset < 0 _ORELSE sampleIncrement < 1 _ORELSE lastSamplePos > UBOUND(sampleDataArray) THEN EXIT SUB

    DIM samplePos AS LONG: samplePos = LBOUND(sampleDataArray) + sampleOffset
    DIM avgIntensity AS SINGLE
    DIM i AS LONG

    FOR i = 0 TO numSamples - 1
        DIM sample AS SINGLE: sample = _CLAMP(sampleDataArray(samplePos), -1!, 1)

        analyzer.fftBuffer(i * 2) = _SHL(INT(sample * __AUDIO_ANALYZER_F32_TO_S16), 12)
        analyzer.fftBuffer(i * 2 + 1) = 0

        avgIntensity = avgIntensity + sample * sample

        samplePos = samplePos + sampleIncrement
    NEXT

    analyzer.averageIntensity = avgIntensity / CSNG(numSamples)

    __AudioAnalyzer_PerformButterfly analyzer, bitDepth

    DIM shiftAmount AS LONG: shiftAmount = AUDIO_ANALYZER_MAX_BIT_DEPTH - bitDepth
    DIM peakAmp AS _UNSIGNED INTEGER
    DIM peakBinIdx AS LONG

    FOR i = 1 TO halfNumSamples
        DIM revIdx AS LONG: revIdx = _SHR(__AudioAnalyzer_BitReversalTable(i), shiftAmount)
        DIM realPart AS LONG: realPart = _SHR(analyzer.fftBuffer(revIdx * 2), 12)
        DIM imagPart AS LONG: imagPart = _SHR(analyzer.fftBuffer(revIdx * 2 + 1), 12)
        DIM magSquared AS DOUBLE: magSquared = (CDBL(realPart) * CDBL(realPart) + CDBL(imagPart) * CDBL(imagPart)) * CDBL(i)
        DIM magVal AS _UNSIGNED INTEGER: magVal = _CAST(_UNSIGNED INTEGER, _CLAMP(SQR(magSquared), 0.0#, 65535.0#))

        amplitudeArray(LBOUND(amplitudeArray) + i - 1) = magVal

        IF magVal > peakAmp THEN
            peakAmp = magVal
            peakBinIdx = i - 1
        END IF
    NEXT

    analyzer.peakAmplitude = peakAmp
    analyzer.peakBin = peakBinIdx
END SUB
