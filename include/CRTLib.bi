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
        Function StrLen~& Alias strlen (ByVal str As Offset)
        Sub StrNCpy Alias strncpy (ByVal dst As Offset, Byval src As Offset, Byval count As Unsigned Offset)
        Function MemChr%& Alias memchr (ByVal ptr As Offset, Byval ch As Long, Byval count As Unsigned Offset)
        Function MemCmp& Alias memcmp (ByVal lhs As Offset, Byval rhs As Offset, Byval count As Unsigned Offset)
        Sub MemSet Alias memset (ByVal dst As Offset, Byval ch As Long, Byval count As Unsigned Offset)
        Sub MemCpy Alias memcpy (ByVal dst As Offset, Byval src As Offset, Byval count As Unsigned Offset)
        Sub MemMove Alias memmove (ByVal dst As Offset, Byval src As Offset, Byval count As Unsigned Offset)
        Sub MemCCpy Alias memccpy (ByVal dst As Offset, Byval src As Offset, Byval c As Long, Byval count As Unsigned Offset)
        Function Rand& Alias rand
        Sub SRand Alias srand (ByVal seed As Unsigned Long)
        Function GetChar& Alias getchar
        Sub PutChar Alias putchar (ByVal ch As Long)
        Function GetTicks~&&
    End Declare

    Declare CustomType Library "CRTLib"
        $If 32BIT Then
            Function CLngPtr~& (ByVal p As Offset)
        $Else
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
        Function RandomBetween& (ByVal lo As Long, Byval hi As Long)
        Function IsPowerOfTwo& (ByVal n As Unsigned Long)
        Function NextPowerOfTwo~& (ByVal n As Unsigned Long)
        Function PreviousPowerOfTwo~& (ByVal n As Unsigned Long)
        Function LeftShiftOneCount~& (ByVal n As Unsigned Long)
        Function ReverseBitsLong~& (ByVal n As Unsigned Long)
        Function ReverseBitsInteger64~&& (ByVal n As Unsigned Integer64)
        Function ClampLong& (ByVal n As Long, Byval lo As Long, Byval hi As Long)
        Function ClampInteger64&& (ByVal n As Integer64, Byval lo As Integer64, Byval hi As Integer64)
        Function ClampSingle! (ByVal n As Single, Byval lo As Single, Byval hi As Single)
        Function ClampDouble# (ByVal n As Double, Byval lo As Double, Byval hi As Double)
        Function GetDigitFromLong& (ByVal n As Unsigned Long, Byval p As Unsigned Long)
        Function GetDigitFromInteger64& (ByVal n As Unsigned Integer64, Byval p As Unsigned Long)
        Function AverageLong& (ByVal x As Long, Byval y As Long)
        Function AverageInteger64&& (ByVal x As Integer64, Byval y As Integer64)
        Function FindFirstBitSetLong& (ByVal x As Unsigned Long)
        Function FindFirstBitSetInteger64& (ByVal x As Unsigned Integer64)
        Function CountLeadingZerosLong& (ByVal x As Unsigned Long)
        Function CountLeadingZerosInteger64& (ByVal x As Unsigned Integer64)
        Function CountTrailingZerosLong& (ByVal x As Unsigned Long)
        Function CountTrailingZerosInteger64& (ByVal x As Unsigned Integer64)
        Function PopulationCountLong& (ByVal x As Unsigned Long)
        Function PopulationCountInteger64& (ByVal x As Unsigned Integer64)
        Function ByteSwapInteger~% (ByVal x As Unsigned Integer)
        Function ByteSwapLong~& (ByVal x As Unsigned Long)
        Function ByteSwapInteger64~&& (ByVal x As Unsigned Integer64)
        Function MakeFourCC~& (ByVal ch0 As Unsigned Byte, Byval ch1 As Unsigned Byte, Byval ch2 As Unsigned Byte, Byval ch3 As Unsigned Byte)
        Function MakeByte~%% (ByVal x As Unsigned Byte, Byval y As Unsigned Byte)
        Function MakeInteger~% (ByVal x As Unsigned Byte, Byval y As Unsigned Byte)
        Function MakeLong~& (ByVal x As Unsigned Integer, Byval y As Unsigned Integer)
        Function MakeInteger64~&& (ByVal x As Unsigned Long, Byval y As Unsigned Long)
        Function HiNibble~%% (ByVal x As Unsigned Byte)
        Function LoNibble~%% (ByVal x As Unsigned Byte)
        Function HiByte~%% (ByVal x As Unsigned Integer)
        Function LoByte~%% (ByVal x As Unsigned Integer)
        Function HiInteger~% (ByVal x As Unsigned Long)
        Function LoInteger~% (ByVal x As Unsigned Long)
        Function HiLong~& (ByVal x As Unsigned Integer64)
        Function LoLong~& (ByVal x As Unsigned Integer64)
        Function MaxLong& (ByVal a As Long, Byval b As Long)
        Function MinLong& (ByVal a As Long, Byval b As Long)
        Function MaxInteger64&& (ByVal a As Integer64, Byval b As Integer64)
        Function MinInteger64&& (ByVal a As Integer64, Byval b As Integer64)
        Function MaxSingle! (ByVal a As Single, Byval b As Single)
        Function MinSingle! (ByVal a As Single, Byval b As Single)
        Function MaxDouble# (ByVal a As Double, Byval b As Double)
        Function MinDouble# (ByVal a As Double, Byval b As Double)
    End Declare
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

