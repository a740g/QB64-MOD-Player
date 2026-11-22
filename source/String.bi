'-----------------------------------------------------------------------------------------------------------------------
' String related stuff
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

''' @brief Converts a C-style string (null-terminated) to a BASIC string.
''' @param s The C-style string to convert.
''' @return The converted BASIC string.
FUNCTION String_ConvertToBStr$ (s AS STRING)
    DIM nulPos AS _UNSIGNED LONG: nulPos = INSTR(s, _CHR_NUL)
    String_ConvertToBStr = _IIF(nulPos, LEFT$(s, nulPos - 1), s)
END FUNCTION

''' @brief Converts a BASIC string to a C-style string (null-terminated).
''' @param s The BASIC string to convert.
''' @return The converted C-style string.
FUNCTION String_ConvertToCStr$ (s AS STRING)
    String_ConvertToCStr = s + _CHR_NUL
END FUNCTION

''' @brief Cleans text of control characters and makes it printable.
''' @param text The input string to sanitize.
''' @return A string containing only printable characters with control characters replaced by spaces.
FUNCTION String_MakePrintable$ (text AS STRING)
    DIM buffer AS STRING: buffer = text
    DIM l AS _UNSIGNED LONG: l = LEN(buffer)

    DIM i AS _UNSIGNED LONG
    FOR i = 1 TO l
        DIM c AS _UNSIGNED _BYTE: c = ASC(buffer, i)
        IF c < _ASC_SPACE _ORELSE c = _ASC_DEL THEN ASC(buffer, i) = _ASC_SPACE
    NEXT i

    String_MakePrintable = buffer
END FUNCTION

''' @brief Tokenizes a string into a dynamic string array using specified delimiters and quote characters.
''' @param text The input string to parse.
''' @param delims A string containing delimiter characters.
''' @param quoteChars A string containing opening and closing quote characters (or empty).
''' @param returnDelims If _TRUE, delimiters are also returned as elements in the tokens array.
''' @param tokens() Dynamic string array that receives the parsed tokens. The caller's lower bound is preserved.
''' @return The number of tokens parsed.
FUNCTION String_Tokenize& (text AS STRING, delims AS STRING, quoteChars AS STRING, returnDelims AS _BYTE, tokens() AS STRING)
    DIM baseIndex AS LONG: baseIndex = LBOUND(tokens)
    REDIM tokens(baseIndex TO baseIndex) AS STRING
    tokens(baseIndex) = _STR_EMPTY

    DIM textLen AS LONG: textLen = LEN(text)
    IF textLen = 0 THEN EXIT FUNCTION ' nothing to be done

    DIM arrCapacity AS LONG: arrCapacity = 64
    REDIM tokens(baseIndex TO baseIndex + arrCapacity - 1) AS STRING
    DIM arrIdx AS LONG: arrIdx = baseIndex

    DIM hasQuotes AS _BYTE: hasQuotes = (LEN(quoteChars) > 0)
    DIM openQuote AS _UNSIGNED _BYTE, closeQuote AS _UNSIGNED _BYTE
    IF hasQuotes THEN
        openQuote = ASC(quoteChars, 1)
        closeQuote = ASC(quoteChars, LEN(quoteChars))
    END IF

    DIM isDelim(0 TO 255) AS _BYTE
    DIM d AS LONG
    FOR d = 1 TO LEN(delims)
        isDelim(ASC(delims, d)) = _TRUE
    NEXT d

    DIM insideQuote AS _BYTE ' flag to track if currently inside a quote
    DIM tokenStart AS LONG, tokenLen AS LONG
    DIM AS LONG i, count
    DIM c AS _UNSIGNED _BYTE

    ' Iterate through the characters in the text string
    FOR i = 1 TO textLen
        c = ASC(text, i)
        IF insideQuote THEN
            IF c = closeQuote THEN
                ' Closing quote char encountered, resume delimiting
                insideQuote = _FALSE
                GOSUB add_token ' add the token to the array
                IF returnDelims THEN GOSUB add_delim ' add the closing quote char as delimiter if required
            ELSE
                IF tokenStart = 0 THEN tokenStart = i
                tokenLen = tokenLen + 1
            END IF
        ELSE
            IF hasQuotes _ANDALSO c = openQuote THEN
                ' Opening quote char encountered, temporarily stop delimiting
                insideQuote = _TRUE
                GOSUB add_token ' add the token to the array
                IF returnDelims THEN GOSUB add_delim ' add the opening quote char as delimiter if required
            ELSEIF isDelim(c) THEN
                GOSUB add_token ' found a delimiter, add the token to the array
                IF returnDelims THEN GOSUB add_delim ' found a delimiter, add it to the array if required
            ELSE
                IF tokenStart = 0 THEN tokenStart = i
                tokenLen = tokenLen + 1
            END IF
        END IF
    NEXT i

    GOSUB add_token ' add the final token if there is any

    IF count > 0 THEN
        REDIM _PRESERVE tokens(baseIndex TO baseIndex + count - 1) AS STRING ' resize the array to the exact size
    ELSE
        REDIM tokens(baseIndex TO baseIndex) AS STRING
        tokens(baseIndex) = _STR_EMPTY
    END IF

    String_Tokenize = count

    EXIT FUNCTION

    ' Add the token to the array if there is any
    add_token:
    IF tokenLen > 0 THEN
        tokens(arrIdx) = MID$(text, tokenStart, tokenLen) ' extract token slice in a single allocation
        tokenStart = 0
        tokenLen = 0
        GOSUB increment_counters_and_resize_array
    END IF
    RETURN

    ' Add delimiter to array if required
    add_delim:
    tokens(arrIdx) = MID$(text, i, 1) ' add delimiter to array
    GOSUB increment_counters_and_resize_array
    RETURN

    ' Increment the count and array index and resize the array if needed
    increment_counters_and_resize_array:
    count = count + 1 ' increment the token count
    arrIdx = arrIdx + 1 ' move to next position
    IF arrIdx > UBOUND(tokens) THEN
        arrCapacity = arrCapacity * 2
        REDIM _PRESERVE tokens(baseIndex TO baseIndex + arrCapacity - 1) AS STRING
    END IF
    RETURN
END FUNCTION
