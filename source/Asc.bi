'-----------------------------------------------------------------------------------------------------------------------
' ASCII character classification and conversion routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

OPTION _EXPLICIT

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

''' @brief Converts a character to lowercase.
''' @param c The ASCII code of the character to convert.
''' @return The ASCII code of the lowercase character.
FUNCTION Asc_ToLowercase~%% (c AS _UNSIGNED _BYTE)
    Asc_ToLowercase = _IIF(c >= ASC_UPPER_A _ANDALSO c <= ASC_UPPER_Z, c + 32, c)
END FUNCTION

''' @brief Converts a character to uppercase.
''' @param c The ASCII code of the character to convert.
''' @return The ASCII code of the uppercase character.
FUNCTION Asc_ToUppercase~%% (c AS _UNSIGNED _BYTE)
    Asc_ToUppercase = _IIF(c >= ASC_LOWER_A _ANDALSO c <= ASC_LOWER_Z, c - 32, c)
END FUNCTION

''' @brief Checks if a character is alphanumeric.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is alphanumeric, _FALSE otherwise.
FUNCTION Asc_IsAlphanumeric%% (c AS _UNSIGNED _BYTE)
    Asc_IsAlphanumeric = (c >= ASC_0 _ANDALSO c <= ASC_9) _ORELSE (c >= ASC_UPPER_A _ANDALSO c <= ASC_UPPER_Z) _ORELSE (c >= ASC_LOWER_A _ANDALSO c <= ASC_LOWER_Z)
END FUNCTION

''' @brief Checks if a character is alphabetic.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is alphabetic, _FALSE otherwise.
FUNCTION Asc_IsAlphabetic%% (c AS _UNSIGNED _BYTE)
    Asc_IsAlphabetic = (c >= ASC_UPPER_A _ANDALSO c <= ASC_UPPER_Z) _ORELSE (c >= ASC_LOWER_A _ANDALSO c <= ASC_LOWER_Z)
END FUNCTION

''' @brief Checks if a character is lowercase.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is lowercase, _FALSE otherwise.
FUNCTION Asc_IsLowercase%% (c AS _UNSIGNED _BYTE)
    Asc_IsLowercase = c >= ASC_LOWER_A _ANDALSO c <= ASC_LOWER_Z
END FUNCTION

''' @brief Checks if a character is uppercase.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is uppercase, _FALSE otherwise.
FUNCTION Asc_IsUppercase%% (c AS _UNSIGNED _BYTE)
    Asc_IsUppercase = c >= ASC_UPPER_A _ANDALSO c <= ASC_UPPER_Z
END FUNCTION

''' @brief Checks if a character is a decimal digit.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is a decimal digit, _FALSE otherwise.
FUNCTION Asc_IsDecimalDigit%% (c AS _UNSIGNED _BYTE)
    Asc_IsDecimalDigit = c >= ASC_0 _ANDALSO c <= ASC_9
END FUNCTION

''' @brief Checks if a character is a hexadecimal digit.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is a hexadecimal digit, _FALSE otherwise.
FUNCTION Asc_IsHexadecimalDigit%% (c AS _UNSIGNED _BYTE)
    Asc_IsHexadecimalDigit = (c >= ASC_0 _ANDALSO c <= ASC_9) _ORELSE (c >= ASC_UPPER_A _ANDALSO c <= ASC_UPPER_F) _ORELSE (c >= ASC_LOWER_A _ANDALSO c <= ASC_LOWER_F)
END FUNCTION

''' @brief Checks if a character is an octal digit.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is an octal digit, _FALSE otherwise.
FUNCTION Asc_IsOctalDigit%% (c AS _UNSIGNED _BYTE)
    Asc_IsOctalDigit = c >= ASC_0 _ANDALSO c <= ASC_7
END FUNCTION

''' @brief Checks if a character is a binary digit.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is a binary digit, _FALSE otherwise.
FUNCTION Asc_IsBinaryDigit%% (c AS _UNSIGNED _BYTE)
    Asc_IsBinaryDigit = c = ASC_0 _ORELSE c = ASC_1
END FUNCTION

''' @brief Checks if a character is a control character.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is a control character, _FALSE otherwise.
FUNCTION Asc_IsControlCharacter%% (c AS _UNSIGNED _BYTE)
    Asc_IsControlCharacter = c < _ASC_SPACE _ORELSE c = _ASC_DEL
END FUNCTION

''' @brief Checks if a character is whitespace.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is whitespace, _FALSE otherwise.
FUNCTION Asc_IsWhitespace%% (c AS _UNSIGNED _BYTE)
    Asc_IsWhitespace = c = _ASC_SPACE _ORELSE c = _ASC_HT _ORELSE c = _ASC_LF _ORELSE c = _ASC_VT _ORELSE c = _ASC_FF _ORELSE c = _ASC_CR
END FUNCTION

''' @brief Checks if a character is blank (space or horizontal tab).
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is blank, _FALSE otherwise.
FUNCTION Asc_IsBlank%% (c AS _UNSIGNED _BYTE)
    Asc_IsBlank = c = _ASC_SPACE _ORELSE c = _ASC_HT
END FUNCTION

''' @brief Checks if a character is punctuation.
''' @param c The ASCII code of the character to check.
''' @return _TRUE if the character is punctuation, _FALSE otherwise.
FUNCTION Asc_IsPunctuation%% (c AS _UNSIGNED _BYTE)
    Asc_IsPunctuation = (c >= _ASC_EXCLAMATION _ANDALSO c <= _ASC_FORWARDSLASH) _ORELSE (c >= _ASC_COLON _ANDALSO c <= _ASC_ATSIGN) _ORELSE (c >= _ASC_LEFTSQUAREBRACKET _ANDALSO c <= _ASC_GRAVE) _ORELSE (c >= _ASC_LEFTCURLYBRACKET _ANDALSO c <= _ASC_TILDE)
END FUNCTION
