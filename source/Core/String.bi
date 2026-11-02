'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$LET TOOLBOX64_STRICT = TRUE
'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'
'$INCLUDE:'../Core/PointerOps.bi'

CONST ASC_0~%% = 48~%%, CHR_0 = CHR$(ASC_0)
CONST ASC_1~%% = 49~%%, CHR_1 = CHR$(ASC_1)
CONST ASC_2~%% = 50~%%, CHR_2 = CHR$(ASC_2)
CONST ASC_3~%% = 51~%%, CHR_3 = CHR$(ASC_3)
CONST ASC_4~%% = 52~%%, CHR_4 = CHR$(ASC_4)
CONST ASC_5~%% = 53~%%, CHR_5 = CHR$(ASC_5)
CONST ASC_6~%% = 54~%%, CHR_6 = CHR$(ASC_6)
CONST ASC_7~%% = 55~%%, CHR_7 = CHR$(ASC_7)
CONST ASC_8~%% = 56~%%, CHR_8 = CHR$(ASC_8)
CONST ASC_9~%% = 57~%%, CHR_9 = CHR$(ASC_9)
CONST ASC_UPPER_A~%% = 65~%%, CHR_UPPER_A = CHR$(ASC_UPPER_A)
CONST ASC_UPPER_B~%% = 66~%%, CHR_UPPER_B = CHR$(ASC_UPPER_B)
CONST ASC_UPPER_C~%% = 67~%%, CHR_UPPER_C = CHR$(ASC_UPPER_C)
CONST ASC_UPPER_D~%% = 68~%%, CHR_UPPER_D = CHR$(ASC_UPPER_D)
CONST ASC_UPPER_E~%% = 69~%%, CHR_UPPER_E = CHR$(ASC_UPPER_E)
CONST ASC_UPPER_F~%% = 70~%%, CHR_UPPER_F = CHR$(ASC_UPPER_F)
CONST ASC_UPPER_G~%% = 71~%%, CHR_UPPER_G = CHR$(ASC_UPPER_G)
CONST ASC_UPPER_H~%% = 72~%%, CHR_UPPER_H = CHR$(ASC_UPPER_H)
CONST ASC_UPPER_I~%% = 73~%%, CHR_UPPER_I = CHR$(ASC_UPPER_I)
CONST ASC_UPPER_J~%% = 74~%%, CHR_UPPER_J = CHR$(ASC_UPPER_J)
CONST ASC_UPPER_K~%% = 75~%%, CHR_UPPER_K = CHR$(ASC_UPPER_K)
CONST ASC_UPPER_L~%% = 76~%%, CHR_UPPER_L = CHR$(ASC_UPPER_L)
CONST ASC_UPPER_M~%% = 77~%%, CHR_UPPER_M = CHR$(ASC_UPPER_M)
CONST ASC_UPPER_N~%% = 78~%%, CHR_UPPER_N = CHR$(ASC_UPPER_N)
CONST ASC_UPPER_O~%% = 79~%%, CHR_UPPER_O = CHR$(ASC_UPPER_O)
CONST ASC_UPPER_P~%% = 80~%%, CHR_UPPER_P = CHR$(ASC_UPPER_P)
CONST ASC_UPPER_Q~%% = 81~%%, CHR_UPPER_Q = CHR$(ASC_UPPER_Q)
CONST ASC_UPPER_R~%% = 82~%%, CHR_UPPER_R = CHR$(ASC_UPPER_R)
CONST ASC_UPPER_S~%% = 83~%%, CHR_UPPER_S = CHR$(ASC_UPPER_S)
CONST ASC_UPPER_T~%% = 84~%%, CHR_UPPER_T = CHR$(ASC_UPPER_T)
CONST ASC_UPPER_U~%% = 85~%%, CHR_UPPER_U = CHR$(ASC_UPPER_U)
CONST ASC_UPPER_V~%% = 86~%%, CHR_UPPER_V = CHR$(ASC_UPPER_V)
CONST ASC_UPPER_W~%% = 87~%%, CHR_UPPER_W = CHR$(ASC_UPPER_W)
CONST ASC_UPPER_X~%% = 88~%%, CHR_UPPER_X = CHR$(ASC_UPPER_X)
CONST ASC_UPPER_Y~%% = 89~%%, CHR_UPPER_Y = CHR$(ASC_UPPER_Y)
CONST ASC_UPPER_Z~%% = 90~%%, CHR_UPPER_Z = CHR$(ASC_UPPER_Z)
CONST ASC_LOWER_A~%% = 97~%%, CHR_LOWER_A = CHR$(ASC_LOWER_A)
CONST ASC_LOWER_B~%% = 98~%%, CHR_LOWER_B = CHR$(ASC_LOWER_B)
CONST ASC_LOWER_C~%% = 99~%%, CHR_LOWER_C = CHR$(ASC_LOWER_C)
CONST ASC_LOWER_D~%% = 100~%%, CHR_LOWER_D = CHR$(ASC_LOWER_D)
CONST ASC_LOWER_E~%% = 101~%%, CHR_LOWER_E = CHR$(ASC_LOWER_E)
CONST ASC_LOWER_F~%% = 102~%%, CHR_LOWER_F = CHR$(ASC_LOWER_F)
CONST ASC_LOWER_G~%% = 103~%%, CHR_LOWER_G = CHR$(ASC_LOWER_G)
CONST ASC_LOWER_H~%% = 104~%%, CHR_LOWER_H = CHR$(ASC_LOWER_H)
CONST ASC_LOWER_I~%% = 105~%%, CHR_LOWER_I = CHR$(ASC_LOWER_I)
CONST ASC_LOWER_J~%% = 106~%%, CHR_LOWER_J = CHR$(ASC_LOWER_J)
CONST ASC_LOWER_K~%% = 107~%%, CHR_LOWER_K = CHR$(ASC_LOWER_K)
CONST ASC_LOWER_L~%% = 108~%%, CHR_LOWER_L = CHR$(ASC_LOWER_L)
CONST ASC_LOWER_M~%% = 109~%%, CHR_LOWER_M = CHR$(ASC_LOWER_M)
CONST ASC_LOWER_N~%% = 110~%%, CHR_LOWER_N = CHR$(ASC_LOWER_N)
CONST ASC_LOWER_O~%% = 111~%%, CHR_LOWER_O = CHR$(ASC_LOWER_O)
CONST ASC_LOWER_P~%% = 112~%%, CHR_LOWER_P = CHR$(ASC_LOWER_P)
CONST ASC_LOWER_Q~%% = 113~%%, CHR_LOWER_Q = CHR$(ASC_LOWER_Q)
CONST ASC_LOWER_R~%% = 114~%%, CHR_LOWER_R = CHR$(ASC_LOWER_R)
CONST ASC_LOWER_S~%% = 115~%%, CHR_LOWER_S = CHR$(ASC_LOWER_S)
CONST ASC_LOWER_T~%% = 116~%%, CHR_LOWER_T = CHR$(ASC_LOWER_T)
CONST ASC_LOWER_U~%% = 117~%%, CHR_LOWER_U = CHR$(ASC_LOWER_U)
CONST ASC_LOWER_V~%% = 118~%%, CHR_LOWER_V = CHR$(ASC_LOWER_V)
CONST ASC_LOWER_W~%% = 119~%%, CHR_LOWER_W = CHR$(ASC_LOWER_W)
CONST ASC_LOWER_X~%% = 120~%%, CHR_LOWER_X = CHR$(ASC_LOWER_X)
CONST ASC_LOWER_Y~%% = 121~%%, CHR_LOWER_Y = CHR$(ASC_LOWER_Y)
CONST ASC_LOWER_Z~%% = 122~%%, CHR_LOWER_Z = CHR$(ASC_LOWER_Z)

'-----------------------------------------------------------------------------------------------------------------------
' Test code for debugging the library
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'$CONSOLE:ONLY

'PRINT String_ToCStr("abcd") + "<END", LEN(String_ToCStr("abcd"))

'PRINT String_Filter("Hello, -234.234world!", "+-01234567890.", _FALSE) + "<END"
'PRINT String_Filter("Hello,-234.234 world!", "+-01234567890.", _TRUE) + "<END"

'PRINT String_FormatBoolean(_TRUE, 20)
'PRINT String_FormatBoolean(_FALSE, 20)
'PRINT String_FormatLong(&HBE, "%.4X")
'PRINT String_FormatInteger64(&HBE, "%.10llu")
'PRINT String_FormatSingle(25.78, "%f")
'PRINT String_FormatDouble(18.4455, "%f")
'PRINT String_FormatOffset(&HDEADBEEFBEEFDEAD, "%p")
'PRINT String_FormatString("hello", "----%s----")
'PRINT String_FormatLong(0, "%.4X")

'PRINT String_RemoveEnclosingPair("(hello + (2 * 5) - world)", "()")

'DIM AS STRING myStr1, myStr2

'myStr1 = "Toolbox64"
'myStr2 = "Shadow Warrior"

'PRINT String_Reverse(myStr1)
'String_Reverse myStr2
'PRINT myStr2
'PRINT myStr1

'PRINT String_IsAlphaNumeric(ASC_9)
'PRINT String_IsAlphabetic(ASC_LOWER_X)
'PRINT String_IsLowerCase(ASC_LOWER_X)
'PRINT String_IsUpperCase(ASC_LOWER_X)
'PRINT String_IsDigit(ASC_1)
'PRINT String_IsHexadecimalDigit(ASC_LOWER_F)
'PRINT String_IsControlCharacter(_ASC_CR)
'PRINT String_IsGraphicalCharacter(_ASC_TILDE)
'PRINT String_IsWhiteSpace(_ASC_HT)
'PRINT String_IsBlank(_ASC_HT)
'PRINT String_IsPrintable(_ASC_SPACE)
'PRINT String_IsPunctuation(_ASC_EXCLAMATION)

'DIM r AS _UNSIGNED _OFFSET: r = String_RegExCompile("[Hh]ello [Ww]orld\s*[!]?")
'DIM AS LONG l, n: n = String_RegExSearchCompiled(r, "ahem.. 'hello world !' ..", 1, l)

'IF n > 0 THEN
'    PRINT "Match at"; n; ","; l; "chars long"
'END IF

'String_RegExFree r

'n = 1
'DO
'    n = String_RegExSearch("b[aeiou]b", "bub bob bib bab", n, l)
'    IF n > 0 THEN
'        PRINT "Match at"; n; ","; l; "chars long"
'        n = n + l
'    END IF
'LOOP WHILE n

'myStr1 = String_GetToken("x = sin(0.9) + cos(0.5)", " ")

'DO
'    PRINT myStr1
'    myStr1 = String_GetToken(_STR_EMPTY, " ")
'LOOP WHILE LEN(myStr1)

'END
'-----------------------------------------------------------------------------------------------------------------------

DECLARE LIBRARY "String"
    FUNCTION __String_FormatString$ ALIAS "__String_Format" (s AS STRING, fmt AS STRING)
    FUNCTION __String_FormatLong$ ALIAS "__String_Format" (BYVAL n AS LONG, fmt AS STRING)
    FUNCTION __String_FormatInteger64$ ALIAS "__String_Format" (BYVAL n AS _INTEGER64, fmt AS STRING)
    FUNCTION __String_FormatSingle$ ALIAS "__String_Format" (BYVAL n AS SINGLE, fmt AS STRING)
    FUNCTION __String_FormatDouble$ ALIAS "__String_Format" (BYVAL n AS DOUBLE, fmt AS STRING)
    FUNCTION __String_FormatOffset$ ALIAS "__String_Format" (BYVAL n AS _UNSIGNED _OFFSET, fmt AS STRING)
    FUNCTION String_FormatBoolean$ (BYVAL n AS _OFFSET, BYVAL fmt AS _UNSIGNED LONG)
    FUNCTION String_ToLowerCase~& ALIAS "tolower" (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_ToUpperCase~& ALIAS "toupper" (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsAlphaNumeric%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsAlphabetic%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsLowerCase%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsUpperCase%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsDigit%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsHexadecimalDigit%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsControlCharacter%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsGraphicalCharacter%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsWhiteSpace%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsBlank%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsPrintable%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION String_IsPunctuation%% (BYVAL ch AS _UNSIGNED LONG)
    FUNCTION __String_RegExCompile~%& (pattern AS STRING)
    SUB String_RegExFree (BYVAL regExCtx AS _UNSIGNED _OFFSET)
    FUNCTION __String_RegExSearchCompiled& (BYVAL pattern AS _UNSIGNED _OFFSET, text AS STRING, BYVAL startPos AS LONG, matchLength AS LONG)
    FUNCTION __String_RegExSearch& (pattern AS STRING, text AS STRING, BYVAL startPos AS LONG, matchLength AS LONG)
    FUNCTION __String_RegExMatchCompiled%% (BYVAL pattern AS _UNSIGNED _OFFSET, text AS STRING)
    FUNCTION __String_RegExMatch%% (pattern AS STRING, text AS STRING)
END DECLARE

' Returns a BASIC string (bstring) from a NULL terminated C string (cstring)
FUNCTION String_ToBStr$ (s AS STRING)
    $CHECKING:OFF
    DIM zeroPos AS LONG: zeroPos = INSTR(s, _CHR_NUL)
    IF zeroPos THEN String_ToBStr = LEFT$(s, zeroPos - 1) ELSE String_ToBStr = s
    $CHECKING:ON
END FUNCTION


' Just a convenience function for use when calling external libraries
FUNCTION String_ToCStr$ (s AS STRING)
    $CHECKING:OFF
    String_ToCStr = s + _CHR_NUL
    $CHECKING:ON
END FUNCTION


' Cleans text of control characters and makes it printable
FUNCTION String_MakePrintable$ (text AS STRING)
    DIM buffer AS STRING: buffer = SPACE$(LEN(text))

    $CHECKING:OFF
    DIM i AS _UNSIGNED LONG: WHILE i < LEN(text)
        DIM c AS _UNSIGNED _BYTE: c = PeekStringByte(text, i)

        IF c > _ASC_SPACE THEN PokeStringByte buffer, i, c

        i = i + 1
    WEND
    $CHECKING:ON

    String_MakePrintable = buffer
END FUNCTION


' Returns true if text has a certain enclosing pair like 'hello'
FUNCTION String_HasEnclosingPair%% (text AS STRING, pair AS STRING)
    $CHECKING:OFF
    IF LEN(text) > 1 AND LEN(pair) > 1 THEN
        String_HasEnclosingPair = (PeekStringByte(pair, 0) = PeekStringByte(text, 0) AND PeekStringByte(pair, 1) = PeekStringByte(text, LEN(text) - 1))
    END IF
    $CHECKING:ON
END FUNCTION


' Removes a string's enclosing pair if it is found. So, 'hello world' can be returned as just hello world
' pair - is the enclosing pair. E.g. "''", "()", "[]" etc.
FUNCTION String_RemoveEnclosingPair$ (text AS STRING, pair AS STRING)
    IF String_HasEnclosingPair(text, pair) THEN
        String_RemoveEnclosingPair = MID$(text, 2, LEN(text) - 2)
    ELSE
        String_RemoveEnclosingPair = text
    END IF
END FUNCTION


' Tokenizes a string to a dynamic string array
' text - is the input string
' delims - is a list of delimiters (multiple delimiters can be specified)
' quoteChars - is the string containing the opening and closing "quote" characters. Should be 2 chars only or nothing
' returnDelims - if True, then the routine will also return the delimiters in the correct position in the tokens array
' tokens() - is the array that will hold the tokens
' Returns: the number of tokens parsed
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


'  Extracts tokens from a string. A token is a word that is surrounded
'  by separators, such as spaces or commas. Tokens are extracted and
'  analyzed when parsing sentences or commands. To use the String_GetNextToken
'  function, pass the string to be parsed on the first call, then pass
'  a null string on subsequent calls until the function returns a null
'  to indicate that the entire string has been parsed.
FUNCTION String_GetToken$ (sourceString AS STRING, delimiters AS STRING)
    STATIC startPosition AS _UNSIGNED LONG, originalString AS STRING

    ' If it's the first call, make a copy of the string
    IF LEN(sourceString) THEN
        startPosition = 1
        originalString = sourceString
    END IF

    DIM currentPosition AS _UNSIGNED LONG: currentPosition = startPosition

    ' Find the start of the next token (character that isn't a delimiter)
    WHILE currentPosition <= LEN(originalString) _ANDALSO INSTR(delimiters, CHR$(ASC(originalString, currentPosition)))
        currentPosition = currentPosition + 1
    WEND

    ' Check if the token start is found
    IF currentPosition > LEN(originalString) THEN
        String_GetToken = _STR_EMPTY ' no more tokens, return an empty string
        EXIT FUNCTION
    END IF

    ' Find the end of the token
    DIM tokenStart AS _UNSIGNED LONG: tokenStart = currentPosition
    WHILE tokenStart <= LEN(originalString) _ANDALSO INSTR(delimiters, CHR$(ASC(originalString, tokenStart))) = 0
        tokenStart = tokenStart + 1
    WEND

    DIM tokenEnd AS _UNSIGNED LONG: tokenEnd = tokenStart
    String_GetToken = MID$(originalString, currentPosition, tokenEnd - currentPosition)

    ' Set the starting point for the search for the next token
    startPosition = tokenEnd
END FUNCTION


' Takes unwanted characters out of a string by comparing them with a filter string containing only acceptable characters
FUNCTION String_Filter$ (txtToFilter AS STRING, filter AS STRING, inclusiveFilter AS _BYTE)
    DIM result AS STRING: result = SPACE$(LEN(txtToFilter)) ' pre-allocate memory for the result string

    $CHECKING:OFF
    DIM i AS _UNSIGNED LONG: WHILE i < LEN(txtToFilter)
        DIM resultIndex AS _UNSIGNED LONG ' index to track the result string length
        DIM c AS _UNSIGNED _BYTE: c = PeekStringByte(txtToFilter, i)

        IF inclusiveFilter THEN
            ' Inclusive filtering (keep characters in the filter).
            IF INSTR(filter, CHR$(c)) THEN
                PokeStringByte result, resultIndex, c
                resultIndex = resultIndex + 1
            END IF
        ELSE
            ' Exclusive filtering (exclude characters in the filter).
            IF INSTR(filter, CHR$(c)) = 0 THEN
                PokeStringByte result, resultIndex, c
                resultIndex = resultIndex + 1
            END IF
        END IF

        i = i + 1
    WEND
    $CHECKING:ON

    ' Trim the extra spaces from the result string.
    String_Filter = LEFT$(result, resultIndex)
END FUNCTION


' Replaces occurences of substringToFind in originalString with replacement
FUNCTION String_Replace$ (originalString AS STRING, substringToFind AS STRING, replacement AS STRING, startPosition AS _UNSIGNED LONG, replaceCount AS LONG)
    ' Ensure a valid starting position
    DIM position AS _UNSIGNED LONG: position = startPosition
    IF position < 1 THEN position = 1

    ' Initialize the result string
    DIM resultString AS STRING: resultString = originalString

    ' Loop until the specified count is reached or all occurrences are replaced
    DO
        DIM occurrencesReplaced AS _UNSIGNED LONG
        DIM findPosition AS _UNSIGNED LONG: findPosition = INSTR(position, resultString, substringToFind)

        ' Check if the specified count is reached or no more occurrences are found
        IF findPosition = 0 _ORELSE (replaceCount _ANDALSO occurrencesReplaced >= replaceCount) THEN EXIT DO

        ' Replace the found occurrence with the new substring
        resultString = LEFT$(resultString, findPosition - 1) + replacement + MID$(resultString, findPosition + LEN(substringToFind))

        ' Move the starting position and increment the replace count
        position = findPosition + LEN(replacement)
        occurrencesReplaced = occurrencesReplaced + 1
    LOOP

    String_Replace = resultString
END FUNCTION


' Joins a bunch of strings in sourceArray using delimiter
FUNCTION String_Join$ (sourceArray() AS STRING, delimiter AS STRING)
    DIM LB AS _UNSIGNED LONG: LB = LBOUND(sourceArray)
    DIM UB AS _UNSIGNED LONG: UB = UBOUND(sourceArray)

    ' Ensure the array is not empty.
    IF UB < LB THEN EXIT FUNCTION ' does this really happen?

    ' Initialize the result string with the first element.
    DIM resultString AS STRING: resultString = sourceArray(LB)

    ' Concatenate the remaining elements with the delimiter.
    LB = LB + 1
    DIM i AS _UNSIGNED LONG: FOR i = LB TO UB
        resultString = resultString + delimiter + sourceArray(i)
    NEXT

    String_Join = resultString
END FUNCTION


' Reverses and returns the characters of a string
FUNCTION String_Reverse$ (s AS STRING)
    $CHECKING:OFF
    DIM tmp AS STRING: tmp = s
    ReverseMemory _OFFSET(tmp), LEN(tmp)
    String_Reverse = tmp
    $CHECKING:ON
END FUNCTION


' Reverses the characters of a string in-place
SUB String_Reverse (s AS STRING)
    $CHECKING:OFF
    ReverseMemory _OFFSET(s), LEN(s)
    $CHECKING:ON
END SUB


' Formats a string using C's printf() format specifier
FUNCTION String_FormatString$ (s AS STRING, fmt AS STRING)
    $CHECKING:OFF
    String_FormatString = __String_FormatString(String_ToCStr(s), String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats a long using C's printf() format specifier
FUNCTION String_FormatLong$ (n AS LONG, fmt AS STRING)
    $CHECKING:OFF
    String_FormatLong = __String_FormatLong(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats an integer64 using C's printf() format specifier
FUNCTION String_FormatInteger64$ (n AS _INTEGER64, fmt AS STRING)
    $CHECKING:OFF
    String_FormatInteger64 = __String_FormatInteger64(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats a single using C's printf() format specifier
FUNCTION String_FormatSingle$ (n AS SINGLE, fmt AS STRING)
    $CHECKING:OFF
    String_FormatSingle = __String_FormatSingle(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats a double using C's printf() format specifier
FUNCTION String_FormatDouble$ (n AS DOUBLE, fmt AS STRING)
    $CHECKING:OFF
    String_FormatDouble = __String_FormatDouble(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats an offset using C's printf() format specifier
FUNCTION String_FormatOffset$ (n AS _UNSIGNED _OFFSET, fmt AS STRING)
    $CHECKING:OFF
    String_FormatOffset = __String_FormatOffset(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Compiles a regex for quick usage with different stings via RegExMatchCompiled()
FUNCTION String_RegExCompile~%& (pattern AS STRING)
    $CHECKING:OFF
    String_RegExCompile = __String_RegExCompile(String_ToCStr(pattern))
    $CHECKING:ON
END FUNCTION


' Does a regex search for a string using a compiled pattern
FUNCTION String_RegExSearchCompiled& (pattern AS _UNSIGNED _OFFSET, text AS STRING, startPos AS LONG, matchLength AS LONG)
    $CHECKING:OFF
    IF startPos > 0 AND startPos <= LEN(text) THEN
        DIM i AS LONG: i = __String_RegExSearchCompiled(pattern, String_ToCStr(text), startPos, matchLength)
        IF i > -1 THEN String_RegExSearchCompiled = i + startPos ELSE String_RegExSearchCompiled = i
    END IF
    $CHECKING:ON
END FUNCTION


' Does a regex search for a string using a pattern string
FUNCTION String_RegExSearch& (pattern AS STRING, text AS STRING, startPos AS LONG, matchLength AS LONG)
    $CHECKING:OFF
    IF startPos > 0 AND startPos <= LEN(text) THEN
        DIM i AS LONG: i = __String_RegExSearch(String_ToCStr(pattern), String_ToCStr(text), startPos, matchLength)
        IF i > -1 THEN String_RegExSearch = i + startPos ELSE String_RegExSearch = i
    END IF
    $CHECKING:ON
END FUNCTION


' Checks if `text` is a RegEx match using a compiled pattern
FUNCTION String_RegExMatchCompiled%% (pattern AS _UNSIGNED _OFFSET, text AS STRING)
    $CHECKING:OFF
    String_RegExMatchCompiled = __String_RegExMatchCompiled(pattern, String_ToCStr(text))
    $CHECKING:ON
END FUNCTION


' Checks if `text` is a RegEx match using a pattern string
FUNCTION String_RegExMatch%% (pattern AS STRING, text AS STRING)
    $CHECKING:OFF
    String_RegExMatch = __String_RegExMatch(String_ToCStr(pattern), String_ToCStr(text))
    $CHECKING:ON
END FUNCTION
