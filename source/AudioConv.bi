'-----------------------------------------------------------------------------------------------------------------------
' Audio conversion routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

''' @brief Converts unsigned 8-bit audio samples to signed 8-bit in-place.
''' @param buffer The unsigned 8-bit sample buffer.
SUB AudioConv_ConvertU8ToS8 (buffer AS STRING)
    DIM i AS _UNSIGNED LONG
    FOR i = 1 TO LEN(buffer)
        ASC(buffer, i) = ASC(buffer, i) XOR &H80~%%
    NEXT i
END SUB

''' @brief Converts unsigned 16-bit audio samples to signed 16-bit in-place.
''' @param buffer The unsigned 16-bit sample buffer.
SUB AudioConv_ConvertU16ToS16 (buffer AS STRING)
    DIM i AS _UNSIGNED LONG
    FOR i = 2 TO LEN(buffer) STEP 2
        ASC(buffer, i) = ASC(buffer, i) XOR &H80~%%
    NEXT i
END SUB

''' @brief Converts dual mono 8-bit audio buffer to interleaved stereo.
''' @param buffer The dual mono audio buffer.
''' @return The interleaved stereo audio buffer.
FUNCTION AudioConv_ConvertDualMonoToStereoS8$ (buffer AS STRING)
    DIM samples AS _UNSIGNED LONG: samples = LEN(buffer)
    IF samples < 4 THEN
        AudioConv_ConvertDualMonoToStereoS8 = buffer
        EXIT FUNCTION
    END IF

    DIM result AS STRING: result = SPACE$(samples)
    DIM halfLength AS _UNSIGNED LONG: halfLength = _SHR(samples, 1)
    DIM AS _UNSIGNED LONG i, j
    j = 1

    FOR i = 1 TO halfLength
        ASC(result, j) = ASC(buffer, i)
        ASC(result, j + 1) = ASC(buffer, halfLength + i)
        j = j + 2
    NEXT i

    AudioConv_ConvertDualMonoToStereoS8 = result
END FUNCTION

''' @brief Converts dual mono 16-bit audio buffer to interleaved stereo.
''' @param buffer The dual mono audio buffer.
''' @return The interleaved stereo audio buffer.
FUNCTION AudioConv_ConvertDualMonoToStereoS16$ (buffer AS STRING)
    DIM samples AS _UNSIGNED LONG: samples = LEN(buffer)
    IF samples < 8 THEN
        AudioConv_ConvertDualMonoToStereoS16 = buffer
        EXIT FUNCTION
    END IF

    DIM result AS STRING: result = SPACE$(samples)
    DIM halfBytes AS _UNSIGNED LONG: halfBytes = _SHR(samples, 1)
    DIM AS _UNSIGNED LONG i, j
    j = 1

    FOR i = 1 TO halfBytes STEP 2
        ASC(result, j) = ASC(buffer, i)
        ASC(result, j + 1) = ASC(buffer, i + 1)
        ASC(result, j + 2) = ASC(buffer, halfBytes + i)
        ASC(result, j + 3) = ASC(buffer, halfBytes + i + 1)
        j = j + 4
    NEXT i

    AudioConv_ConvertDualMonoToStereoS16 = result
END FUNCTION

''' @brief Converts 4-bit ADPCM compressed audio samples to 8-bit signed samples.
''' @param buffer The ADPCM compressed audio buffer.
''' @param compTab 16-byte compression table.
''' @return The decompressed 8-bit signed sample buffer.
FUNCTION AudioConv_ConvertADPCM4ToS8$ (buffer AS STRING, compTab AS STRING)
    DIM srcLen AS _UNSIGNED LONG: srcLen = LEN(buffer)
    IF srcLen = 0 _ORELSE LEN(compTab) < 16 THEN EXIT FUNCTION

    DIM table(0 TO 15) AS _BYTE
    DIM k AS LONG
    FOR k = 0 TO 15
        table(k) = _CAST(_BYTE, ASC(compTab, k + 1))
    NEXT k

    DIM result AS STRING: result = SPACE$(srcLen * 2)
    DIM delta AS _BYTE: delta = 0
    DIM rawByte AS _UNSIGNED _BYTE
    DIM AS _UNSIGNED LONG i, dstIdx
    dstIdx = 1

    FOR i = 1 TO srcLen
        rawByte = ASC(buffer, i)
        delta = delta + table(rawByte AND &H0F~%%)
        ASC(result, dstIdx) = delta
        dstIdx = dstIdx + 1
        delta = delta + table(_SHR(rawByte, 4))
        ASC(result, dstIdx) = delta
        dstIdx = dstIdx + 1
    NEXT i

    AudioConv_ConvertADPCM4ToS8 = result
END FUNCTION
