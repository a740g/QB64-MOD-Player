'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' C Runtime Library bindings + support functions
' Copyright (c) 2023 Samuel Gomes
'
' See https://en.cppreference.com/w/ for CRT documentation
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If CRTLIB_BI = UNDEFINED Then
    $Let CRTLIB_BI = TRUE

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' This only includes CRT library functions that makes sense in QB64
    Declare CustomType Library
        Function IsAlNum& Alias isalnum (ByVal ch As Long)
        Function IsAlpha& Alias isalpha (ByVal ch As Long)
        Function IsLower& Alias islower (ByVal ch As Long)
        Function IsUpper& Alias isupper (ByVal ch As Long)
        Function IsDigit& Alias isdigit (ByVal ch As Long)
        Function IsXDigit& Alias isxdigit (ByVal ch As Long)
        Function IsCntrl& Alias iscntrl (ByVal ch As Long)
        Function IsGraph& Alias isgraph (ByVal ch As Long)
        Function IsSpace& Alias isspace (ByVal ch As Long)
        Function IsBlank& Alias isblank (ByVal ch As Long)
        Function IsPrint& Alias isprint (ByVal ch As Long)
        Function IsPunct& Alias ispunct (ByVal ch As Long)
        Function ToLower& Alias tolower (ByVal ch As Long)
        Function ToUpper& Alias toupper (ByVal ch As Long)
        Function Rand& Alias rand
        Sub SRand Alias srand (ByVal seed As Unsigned Long)
        Function GetChar& Alias getchar
        Sub PutChar Alias putchar (ByVal ch As Long)
        Function StrLen~& Alias strlen (ByVal str As Offset)
        Sub StrNCpy Alias strncpy (ByVal dst As Offset, Byval src As Offset, Byval count As Unsigned Offset)
        Function MemChr%& Alias memchr (ByVal ptr As Offset, Byval ch As Long, Byval count As Unsigned Offset)
        Function MemCmp& Alias memcmp (ByVal lhs As Offset, Byval rhs As Offset, Byval count As Unsigned Offset)
        Sub MemSet Alias memset (ByVal dst As Offset, Byval ch As Long, Byval count As Unsigned Offset)
        Sub MemCpy Alias memcpy (ByVal dst As Offset, Byval src As Offset, Byval count As Unsigned Offset)
        Sub MemMove Alias memmove (ByVal dst As Offset, Byval src As Offset, Byval count As Unsigned Offset)
        Sub MemCCpy Alias memccpy (ByVal dst As Offset, Byval src As Offset, Byval c As Long, Byval count As Unsigned Offset)
        Function GetTicks~&&
    End Declare

    Declare CustomType Library "CRTLib"
        $If 32BIT Then
            Function RandomMax~&
            Function CLngPtr~& (ByVal p As Offset)
        $Else
            Function RandomMax~&&
            Function CLngPtr~&& (ByVal p As Offset)
        $End If
        Function PeekByteAtOffset~%% (ByVal p As Offset, Byval o As Offset)
        Sub PokeByteAtOffset (ByVal p As Offset, Byval o As Offset, Byval n As Unsigned Byte)
        Function PeekIntegerAtOffset~% (ByVal p As Offset, Byval o As Offset)
        Sub PokeIntegerAtOffset (ByVal p As Offset, Byval o As Offset, Byval n As Unsigned Integer)
        Function PeekLongAtOffset~& (ByVal p As Offset, Byval o As Offset)
        Sub PokeLongAtOffset (ByVal p As Offset, Byval o As Offset, Byval n As Unsigned Long)
        Function PeekInteger64AtOffset~&& (ByVal p As Offset, Byval o As Offset)
        Sub PokeInteger64AtOffset (ByVal p As Offset, Byval o As Offset, Byval n As Unsigned Integer64)
        Function PeekSingleAtOffset! (ByVal p As Offset, Byval o As Offset)
        Sub PokeSingleAtOffset (ByVal p As Offset, Byval o As Offset, Byval n As Single)
        Function PeekDoubleAtOffset# (ByVal p As Offset, Byval o As Offset)
        Sub PokeDoubleAtOffset (ByVal p As Offset, Byval o As Offset, Byval n As Double)
        Function PeekOffsetAtOffset%& (ByVal p As Offset, Byval o As Offset)
        Sub PokeOffsetAtOffset (ByVal p As Offset, Byval o As Offset, Byval n As Offset)
        Function PeekString~%% (s As String, Byval o As Offset)
        Sub PokeString (s As String, Byval o As Offset, Byval n As Unsigned Byte)
        Function NextPowerOfTwo~& (ByVal n As Unsigned Long)
        Function PreviousPowerOfTwo~& (ByVal n As Unsigned Long)
        Function LShOneCount~& (ByVal n As Unsigned Long)
        Function ReverseBits~&& (ByVal n As Offset, Byval bytes As Unsigned Long)
        Function RandomBetween& (ByVal lo As Long, Byval hi As Long)
        Function ClampLong& (ByVal n As Long, Byval lo As Long, Byval hi As Long)
        Function ClampInteger64&& (ByVal n As Integer64, Byval lo As Integer64, Byval hi As Integer64)
        Function ClampSingle! (ByVal n As Single, Byval lo As Single, Byval hi As Single)
        Function ClampDouble# (ByVal n As Double, Byval lo As Double, Byval hi As Double)
        Function GetDigitFromPosition& (ByVal n As Unsigned Long, Byval p As Unsigned Long)
        Function AverageLong& (ByVal x As Long, Byval y As Long)
        Function AverageInteger64&& (ByVal x As Integer64, Byval y As Integer64)
        Function IsPowerOfTwo& (ByVal n As Unsigned Long)
    End Declare
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

