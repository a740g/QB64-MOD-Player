'-----------------------------------------------------------------------------------------------------------------------
' Audio conversion routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

''' @brief Converts unsigned 8-bit audio samples to signed 8-bit in-place.
''' @param buffer Pointer to the unsigned 8-bit sample buffer.
''' @param samples Number of samples in the buffer.
SUB AudioConv_ConvertU8ToS8 (buffer AS STRING)
    DIM i AS _UNSIGNED LONG
    FOR i = 1 TO LEN(buffer)
        ASC(buffer, i) = ASC(buffer, i) XOR &H80~%%
    NEXT i
END SUB

''' @brief Converts unsigned 16-bit audio samples to signed 16-bit in-place.
''' @param buffer Pointer to the unsigned 16-bit sample buffer.
''' @param samples Number of samples in the buffer.
SUB AudioConv_ConvertU16ToS16 (buffer AS _UNSIGNED _OFFSET, samples AS _UNSIGNED LONG)
    IF buffer = 0 _ORELSE samples = 0 THEN EXIT SUB

    DIM m AS _MEM: m = _MEM(buffer, _CAST(_UNSIGNED _OFFSET, samples) * 2)
    DIM i AS _UNSIGNED _OFFSET
    DIM w AS _UNSIGNED INTEGER

    FOR i = 0 TO samples - 1
        _MEMGET m, m.OFFSET + (i * 2), w
        w = w XOR &H8000~%
        _MEMPUT m, m.OFFSET + (i * 2), w
    NEXT i

    _MEMFREE m
END SUB

''' @brief Converts dual mono 8-bit audio buffer to interleaved stereo.
''' @param src Pointer to the dual mono audio buffer.
''' @param samples Number of samples in the buffer.
''' @param dst Pointer to the buffer where interleaved stereo samples will be stored.
SUB AudioConv_ConvertDualMonoToStereoS8 (src AS _UNSIGNED _OFFSET, samples AS _UNSIGNED LONG, dst AS _UNSIGNED _OFFSET)
    IF src = 0 _ORELSE dst = 0 _ORELSE samples < 4 THEN EXIT SUB

    DIM mSrc AS _MEM: mSrc = _MEM(src, samples)
    DIM mDst AS _MEM: mDst = _MEM(dst, samples)
    DIM halfLength AS _UNSIGNED LONG: halfLength = _SHR(samples, 1)
    DIM AS _UNSIGNED _OFFSET i, j
    DIM AS _BYTE b1, b2

    FOR i = 0 TO halfLength - 1
        _MEMGET mSrc, mSrc.OFFSET + i, b1
        _MEMGET mSrc, mSrc.OFFSET + halfLength + i, b2
        _MEMPUT mDst, mDst.OFFSET + j, b1
        _MEMPUT mDst, mDst.OFFSET + j + 1, b2
        j = j + 2
    NEXT i

    _MEMFREE mDst
    _MEMFREE mSrc
END SUB

''' @brief Converts dual mono 16-bit audio buffer to interleaved stereo.
''' @param src Pointer to the dual mono audio buffer.
''' @param samples Number of samples in the buffer.
''' @param dst Pointer to the buffer where interleaved stereo samples will be stored.
SUB AudioConv_ConvertDualMonoToStereoS16 (src AS _UNSIGNED _OFFSET, samples AS _UNSIGNED LONG, dst AS _UNSIGNED _OFFSET)
    IF src = 0 _ORELSE dst = 0 _ORELSE samples < 4 THEN EXIT SUB

    DIM byteSize AS _UNSIGNED _OFFSET: byteSize = _CAST(_UNSIGNED _OFFSET, samples) * 2
    DIM mSrc AS _MEM: mSrc = _MEM(src, byteSize)
    DIM mDst AS _MEM: mDst = _MEM(dst, byteSize)
    DIM halfLength AS _UNSIGNED LONG: halfLength = _SHR(samples, 1)
    DIM AS _UNSIGNED _OFFSET i, j
    DIM AS INTEGER w1, w2

    FOR i = 0 TO halfLength - 1
        _MEMGET mSrc, mSrc.OFFSET + (i * 2), w1
        _MEMGET mSrc, mSrc.OFFSET + ((halfLength + i) * 2), w2
        _MEMPUT mDst, mDst.OFFSET + j, w1
        _MEMPUT mDst, mDst.OFFSET + j + 2, w2
        j = j + 4
    NEXT i

    _MEMFREE mDst
    _MEMFREE mSrc
END SUB

''' @brief Converts 4-bit ADPCM compressed audio samples to 8-bit signed samples.
''' @param src Pointer to the ADPCM compressed audio buffer.
''' @param srcLen Number of bytes in the input buffer.
''' @param compTab 16-byte compression table.
''' @param dst Pointer to the buffer where 8-bit signed samples will be stored.
SUB AudioConv_ConvertADPCM4ToS8 (src AS _UNSIGNED _OFFSET, srcLen AS _UNSIGNED LONG, compTab AS STRING, dst AS _UNSIGNED _OFFSET)
    IF src = 0 _ORELSE dst = 0 _ORELSE srcLen = 0 _ORELSE LEN(compTab) < 16 THEN EXIT SUB

    DIM table(0 TO 15) AS _BYTE
    DIM k AS LONG
    FOR k = 0 TO 15
        table(k) = _CAST(_BYTE, ASC(compTab, k + 1))
    NEXT k

    DIM mSrc AS _MEM: mSrc = _MEM(src, srcLen)
    DIM mDst AS _MEM: mDst = _MEM(dst, _CAST(_UNSIGNED _OFFSET, srcLen) * 2)
    DIM delta AS _BYTE: delta = 0
    DIM rawByte AS _UNSIGNED _BYTE
    DIM AS _UNSIGNED _OFFSET i, dstIdx

    FOR i = 0 TO srcLen - 1
        _MEMGET mSrc, mSrc.OFFSET + i, rawByte
        delta = delta + table(rawByte AND &H0F~%%)
        _MEMPUT mDst, mDst.OFFSET + dstIdx, delta
        dstIdx = dstIdx + 1
        delta = delta + table(_SHR(rawByte, 4))
        _MEMPUT mDst, mDst.OFFSET + dstIdx, delta
        dstIdx = dstIdx + 1
    NEXT i

    _MEMFREE mDst
    _MEMFREE mSrc
END SUB
