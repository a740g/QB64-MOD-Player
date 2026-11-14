'-----------------------------------------------------------------------------------------------------------------------
' String related stuff
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

OPTION _EXPLICIT

'$INCLUDE:'Asc.bi'

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
    DIM buffer AS STRING: buffer = SPACE$(LEN(text))

    DIM i AS _UNSIGNED LONG, c AS _UNSIGNED _BYTE
    WHILE i < LEN(text)
        i = i + 1

        c = ASC(text, i)
        IF c > _ASC_SPACE THEN ASC(buffer, i) = c
    WEND

    String_MakePrintable = buffer
END FUNCTION

''' @brief Tokenizes a string into a dynamic string array using specified delimiters and quote characters.
''' @param text The input string to parse.
''' @param delims A string containing delimiter characters.
''' @param quoteChars A string containing opening and closing quote characters (or empty).
''' @param returnDelims If _TRUE, delimiters are also returned as elements in the tokens array.
''' @param tokens() Dynamic string array that receives the parsed tokens.
''' @return The number of tokens parsed.
FUNCTION String_Tokenize& (text AS STRING, delims AS STRING, quoteChars AS STRING, returnDelims AS _BYTE, tokens() AS STRING)
    IF LEN(text) = 0 THEN EXIT FUNCTION ' nothing to be done

    DIM arrIdx AS LONG: arrIdx = LBOUND(tokens) ' we'll always start from the array lower bound - whatever it is
    DIM insideQuote AS _BYTE ' flag to track if currently inside a quote

    DIM token AS STRING ' holds a token until it is ready to be added to the array
    DIM char AS STRING * 1 ' this is a single char from text we are iterating through
    DIM AS LONG i, count

    ' Iterate through the characters in the text string
    FOR i = 1 TO LEN(text)
        char = CHR$(ASC(text, i))
        IF insideQuote THEN
            IF char = RIGHT$(quoteChars, 1) THEN
                ' Closing quote char encountered, resume delimiting
                insideQuote = _FALSE
                GOSUB add_token ' add the token to the array
                IF returnDelims THEN GOSUB add_delim ' add the closing quote char as delimiter if required
            ELSE
                token = token + char ' add the character to the current token
            END IF
        ELSE
            IF char = LEFT$(quoteChars, 1) THEN
                ' Opening quote char encountered, temporarily stop delimiting
                insideQuote = _TRUE
                GOSUB add_token ' add the token to the array
                IF returnDelims THEN GOSUB add_delim ' add the opening quote char as delimiter if required
            ELSEIF INSTR(delims, char) = 0 THEN
                token = token + char ' add the character to the current token
            ELSE
                GOSUB add_token ' found a delimiter, add the token to the array
                IF returnDelims THEN GOSUB add_delim ' found a delimiter, add it to the array if required
            END IF
        END IF
    NEXT

    GOSUB add_token ' add the final token if there is any

    IF count THEN REDIM _PRESERVE tokens(LBOUND(tokens) TO arrIdx - 1) AS STRING ' resize the array to the exact size

    String_Tokenize = count

    EXIT FUNCTION

    ' Add the token to the array if there is any
    add_token:
    IF LEN(token) THEN
        tokens(arrIdx) = token ' add the token to the token array
        token = _STR_EMPTY ' clear the current token
        GOSUB increment_counters_and_resize_array
    END IF
    RETURN

    ' Add delimiter to array if required
    add_delim:
    tokens(arrIdx) = char ' add delimiter to array
    GOSUB increment_counters_and_resize_array
    RETURN

    ' Increment the count and array index and resize the array if needed
    increment_counters_and_resize_array:
    count = count + 1 ' increment the token count
    arrIdx = arrIdx + 1 ' move to next position
    IF arrIdx > UBOUND(tokens) THEN REDIM _PRESERVE tokens(LBOUND(tokens) TO UBOUND(tokens) + 512) AS STRING ' resize in 512 chunks
    RETURN
END FUNCTION
