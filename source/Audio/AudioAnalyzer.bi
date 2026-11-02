'-----------------------------------------------------------------------------------------------------------------------
' FFT routines for audio spectrum analyzers
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'

DECLARE LIBRARY "AudioAnalyzer"
    FUNCTION AudioAnalyzerFFT_DoInteger! (amplitudeArray AS _UNSIGNED INTEGER, sampleDataArray AS INTEGER, BYVAL sampleIncrement AS LONG, BYVAL bitDepth AS LONG)
    FUNCTION AudioAnalyzerFFT_DoSingle! (amplitudeArray AS _UNSIGNED INTEGER, sampleDataArray AS SINGLE, BYVAL sampleIncrement AS LONG, BYVAL bitDepth AS LONG)
END DECLARE

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'OPTION _EXPLICIT
'$DEBUG

'CONST FFT_POW = 10
'CONST FFT_FRAMES = 2 ^ FFT_POW
'CONST FFT_HALF_FRAMES = FFT_FRAMES \ 2

'DIM buffer(0 TO FFT_FRAMES - 1) AS SINGLE
'DIM outp(0 TO FFT_HALF_FRAMES - 1) AS INTEGER

'RANDOMIZE TIMER

'DO
'    DIM i AS LONG
'    FOR i = 0 TO FFT_FRAMES - 1
'        buffer(i) = RND - RND
'    NEXT i

'    PRINT USING "#####.#####"; AudioAnalyzerFFT_DoSingle(outp(0), buffer(0), 1, 10)
'LOOP UNTIL _KEYHIT = 27

'END
'-----------------------------------------------------------------------------------------------------------------------
