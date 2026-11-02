'-----------------------------------------------------------------------------------------------------------------------
' Memory-only file-like object
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'
'$INCLUDE:'../Core/PointerOps.bi'

' Simplified memory-only file-like object
TYPE StringFile
    buffer AS STRING
    cursor AS _UNSIGNED LONG
END TYPE

''' @brief Creates a new StringFile object. StringFile APIs are much simpler, limited and safer than MemFile.
''' Unlike MemFile, StringFile uses a QB string as a backing buffer. So, no explicit memory management (i.e. freeing) is required.
''' @param stringFile StringFile object
''' @param src Source string
SUB StringFile_Create (stringFile AS StringFile, src AS STRING)
    stringFile.buffer = src
    stringFile.cursor = 0
END SUB

''' @brief Checks if the file is at EOF.
''' @param stringFile StringFile object.
''' @return Returns true if the file is at EOF.
FUNCTION StringFile_IsEOF%% (stringFile AS StringFile)
    StringFile_IsEOF = (stringFile.cursor >= LEN(stringFile.buffer))
END FUNCTION

''' @brief Gets the size of the file.
''' @param stringFile StringFile object.
''' @return Returns the size of the file.
FUNCTION StringFile_GetSize~& (stringFile AS StringFile)
    StringFile_GetSize = LEN(stringFile.buffer)
END FUNCTION

''' @brief Gets the current position in the file.
''' @param stringFile StringFile object.
''' @return Returns the current position in the file.
FUNCTION StringFile_GetPosition~& (stringFile AS StringFile)
    StringFile_GetPosition = stringFile.cursor
END FUNCTION

''' @brief Seeks to a specific position in the file.
''' @param stringFile StringFile object.
''' @param position Position in the file to seek to.
SUB StringFile_Seek (stringFile AS StringFile, position AS _UNSIGNED LONG)
    IF position <= LEN(stringFile.buffer) THEN ' allow seeking to EOF position
        stringFile.cursor = position
    ELSE
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END SUB

''' @brief Resizes the file.
''' @param stringFile StringFile object.
''' @param newSize New size of the file.
SUB StringFile_Resize (stringFile AS StringFile, newSize AS _UNSIGNED LONG)
    DIM AS _UNSIGNED LONG curSize: curSize = LEN(stringFile.buffer)

    IF newSize > curSize THEN
        stringFile.buffer = stringFile.buffer + STRING$(newSize - curSize, NULL)
    ELSEIF newSize < curSize THEN
        stringFile.buffer = LEFT$(stringFile.buffer, newSize)
        IF stringFile.cursor > newSize THEN stringFile.cursor = newSize ' reposition cursor to EOF position
    END IF
END SUB

''' @brief Reads a string from the file.
''' @param stringFile StringFile object.
''' @param size Size of the string to read.
''' @return Returns the string read from the file.
FUNCTION StringFile_ReadString$ (stringFile AS StringFile, size AS _UNSIGNED LONG)
    IF size > 0 THEN ' reading 0 bytes will simply do nothing
        IF stringFile.cursor < LEN(stringFile.buffer) THEN ' we'll allow partial string reads but check if we have anything to read at all
            DIM dst AS STRING: dst = MID$(stringFile.buffer, stringFile.cursor + 1, size)

            stringFile.cursor = stringFile.cursor + LEN(dst) ' increment cursor by size bytes

            StringFile_ReadString = dst
        ELSE ' not enough bytes to read
            ERROR _ERR_ILLEGAL_FUNCTION_CALL
        END IF
    END IF
END FUNCTION

''' @brief Writes a string to the file.
''' @param stringFile StringFile object.
''' @param src Source string.
SUB StringFile_WriteString (stringFile AS StringFile, src AS STRING)
    DIM srcSize AS _UNSIGNED LONG: srcSize = LEN(src)

    IF srcSize > 0 THEN ' writing 0 bytes will simply do nothing
        DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

        ' Grow the buffer if needed
        IF stringFile.cursor + srcSize >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + srcSize - curSize, NULL)

        MID$(stringFile.buffer, stringFile.cursor + 1, srcSize) = src
        stringFile.cursor = stringFile.cursor + srcSize ' this puts the cursor right after the last position written
    END IF
END SUB

''' @brief Reads a byte from the file.
''' @param stringFile StringFile object.
''' @return Returns the byte read from the file.
FUNCTION StringFile_ReadByte~%% (stringFile AS StringFile)
    IF stringFile.cursor + _SIZE_OF_BYTE <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadByte = PeekStringByte(stringFile.buffer, stringFile.cursor) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_BYTE ' this puts the cursor right after the last position read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION

''' @brief Writes a byte to the file.
''' @param stringFile StringFile object.
''' @param src Source byte.
SUB StringFile_WriteByte (stringFile AS StringFile, src AS _UNSIGNED _BYTE)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_BYTE >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_BYTE - curSize, NULL)

    PokeStringByte stringFile.buffer, stringFile.cursor, src ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_BYTE ' this puts the cursor right after the last position written
END SUB

''' @brief Reads an integer from the file.
''' @param stringFile StringFile object.
''' @return Returns the integer read from the file.
FUNCTION StringFile_ReadInteger~% (stringFile AS StringFile)
    IF stringFile.cursor + _SIZE_OF_INTEGER <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadInteger = CVI(MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_INTEGER)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_INTEGER ' this puts the cursor right after the last position read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION

''' @brief Writes an integer to the file.
''' @param stringFile StringFile object.
''' @param src Source integer.
SUB StringFile_WriteInteger (stringFile AS StringFile, src AS _UNSIGNED INTEGER)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_INTEGER >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_INTEGER - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_INTEGER) = MKI$(src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_INTEGER ' this puts the cursor right after the last position written
END SUB

''' @brief Reads a long from the file.
''' @param stringFile StringFile object.
''' @return Returns the long read from the file.
FUNCTION StringFile_ReadLong~& (stringFile AS StringFile)
    IF stringFile.cursor + _SIZE_OF_LONG <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadLong = CVL(MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_LONG)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_LONG ' this puts the cursor right after the last position read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION

''' @brief Writes a long to the file.
''' @param stringFile StringFile object.
''' @param src Source long.
SUB StringFile_WriteLong (stringFile AS StringFile, src AS _UNSIGNED LONG)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_LONG >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_LONG - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_LONG) = MKL$(src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_LONG ' this puts the cursor right after the last position written
END SUB

''' @brief Reads a single from the file.
''' @param stringFile StringFile object.
''' @return Returns the single read from the file.
FUNCTION StringFile_ReadSingle! (stringFile AS StringFile)
    IF stringFile.cursor + _SIZE_OF_SINGLE <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadSingle = CVS(MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_SINGLE)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_SINGLE ' this puts the cursor right after the last position read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION

''' @brief Writes a single to the file.
''' @param stringFile StringFile object.
''' @param src Source single.
SUB StringFile_WriteSingle (stringFile AS StringFile, src AS SINGLE)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_SINGLE >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_SINGLE - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_SINGLE) = MKS$(src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_SINGLE ' this puts the cursor right after the last position written
END SUB

''' @brief Reads an integer64 from the file.
''' @param stringFile StringFile object.
''' @return Returns the integer64 read from the file.
FUNCTION StringFile_ReadInteger64~&& (stringFile AS StringFile)
    IF stringFile.cursor + _SIZE_OF_INTEGER64 <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadInteger64 = _CV(_UNSIGNED _INTEGER64, MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_INTEGER64)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_INTEGER64 ' this puts the cursor right after the last position read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION

''' @brief Writes an integer64 to the file.
''' @param stringFile StringFile object.
''' @param src Source integer64.
SUB StringFile_WriteInteger64 (stringFile AS StringFile, src AS _UNSIGNED _INTEGER64)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_INTEGER64 >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_INTEGER64 - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_INTEGER64) = _MK$(_UNSIGNED _INTEGER64, src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_INTEGER64 ' this puts the cursor right after the last position written
END SUB

''' @brief Reads a double from the file.
''' @param stringFile StringFile object.
''' @return Returns the double read from the file.
FUNCTION StringFile_ReadDouble# (stringFile AS StringFile)
    IF stringFile.cursor + _SIZE_OF_DOUBLE <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadDouble = CVD(MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_DOUBLE)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_DOUBLE ' this puts the cursor right after the last position read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION

''' @brief Writes a double to the file.
''' @param stringFile StringFile object.
''' @param src Source double.
SUB StringFile_WriteDouble (stringFile AS StringFile, src AS DOUBLE)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_DOUBLE >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_DOUBLE - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_DOUBLE) = MKD$(src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_DOUBLE ' this puts the cursor right after the last position written
END SUB

''' @brief Reads an _OFFSET from the file.
''' @param stringFile StringFile object.
''' @return Returns the _OFFSET read from the file.
FUNCTION StringFile_ReadOffset~%& (stringFile AS StringFile)
    IF stringFile.cursor + _SIZE_OF_OFFSET <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadOffset = _CV(_UNSIGNED _OFFSET, MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_OFFSET)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_OFFSET ' this puts the cursor right after the last position read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION

''' @brief Writes an _OFFSET to the file.
''' @param stringFile StringFile object.
''' @param src Source _OFFSET.
SUB StringFile_WriteOffset (stringFile AS StringFile, src AS _UNSIGNED _OFFSET)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_OFFSET >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_OFFSET - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_OFFSET) = _MK$(_UNSIGNED _OFFSET, src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_OFFSET ' this puts the cursor right after the last position written
END SUB
