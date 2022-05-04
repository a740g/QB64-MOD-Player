'-----------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2022 Samuel Gomes
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------
$NoPrefix
DefLng A-Z
Option Explicit
Option ExplicitArray
Option Base 1
'$Static
$Resize:Smooth
'$Debug
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------
Const FALSE%% = 0%%, TRUE%% = Not FALSE
Const NULL%% = 0%%
Const NULLSTRING$ = ""

Const AMIGA_PAULA_CLOCK_RATE! = 7159090.5! ' PAL: 7093789.2, NSTC: 7159090.5
Const PATTERN_ROW_MAX~%% = 63~%% ' Max row number in a pattern
Const ORDER_TABLE_MAX~%% = 127~%% ' Max position in the order table
Const SAMPLE_VOLUME_MAX~%% = 64~%% ' This is the maximum volume of any sample in the MOD
Const SAMPLE_PAN_LEFT~%% = 0~%% ' This value is per "set pan position" effect
Const SAMPLE_PAN_CENTRE~%% = 64~%% ' This value is per "set pan position" effect
Const SAMPLE_PAN_RIGHT~%% = 128~%% ' This value is per "set pan position" effect
Const SONG_SPEED_DEFAULT~%% = 6~%% ' This is the default speed for song where it is not specified
Const SONG_BPM_DEFAULT~%% = 125~%% ' Default song BPM
Const SONG_VOLUME_MAX~%% = 255~%% ' Max song master volume
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' USER DEFINED TYPES
'-----------------------------------------------------------------------------------------------------
' +-------------------------------------+
' | Byte 0    Byte 1   Byte 2   Byte 3  |
' +-------------------------------------+
' |aaaaBBBB CCCCCCCCC DDDDeeee FFFFFFFFF|
' +-------------------------------------+
Type PatternType
    sample As Unsigned Byte ' aaaaDDDD = sample number
    period As Unsigned Integer ' BBBBCCCCCCCC = sample period value
    effect As Unsigned Byte ' eeee = effect number
    operand As Unsigned Byte ' FFFFFFFF = effect parameters
End Type

Type SampleType
    sampleName As String * 22 ' Sample name or message
    length As Long ' Sample length in bytes
    fineTune As Unsigned Byte ' Lower four bits are the finetune value, stored as a signed four bit number
    volume As Unsigned Byte ' Volume: 0 - 64
    loopStart As Long ' Loop start in bytes
    loopLength As Long ' Loop length in bytes
    loopEnd As Long ' Loop end in bytes
End Type

Type ChannelType
    sample As Unsigned Byte ' Sample number copied from pattern array
    period As Unsigned Integer ' Effect period copied from pattern array
    effect As Unsigned Byte ' Effect copied from pattern array
    operand As Unsigned Byte ' Effect param copied from pattern array
    volume As Unsigned Byte ' Sample volume initially copied from sample array
    pitch As Single ' Sample pitch. The mixer code uses this to step through the sample correctly
    panningPosition As Unsigned Byte ' Position 0 is left ... 64 is centre ... 128 is right
    played As Byte ' This is set to true once the mixer is done with the sample
    samplePosition As Single ' Where are we in the sample buffer
    'sampleFinePosition As Long ' Sample fine position
    'sampleNote As Integer ' Sample note
    'sampleNoteFine As Integer ' Sample note fine
End Type

Type SongType
    songName As String * 20 ' Song name
    subtype As String * 4 ' 4 char MOD type - use this to find out what tracker was used
    channels As Unsigned Byte ' Number of channels in the song - can be any number depending on the MOD file
    samples As Unsigned Byte ' Number of samples in the song - can be 15 or 31 depending on the MOD file
    orders As Unsigned Byte ' Song length in orders
    endJumpOrder As Unsigned Byte ' This is used for jumping to an order if global looping is on
    highestPattern As Unsigned Byte ' The highest pattern number read from the MOD file
    orderPosition As Unsigned Byte ' The position in the order list
    patternRow As Unsigned Byte ' Points to the pattern row to be played
    patternDelay As Unsigned Byte ' Number of times to delay pattern
    isLooping As Byte ' Set this to true to loop the song once we reach the max order specified in the song
    isPlaying As Byte ' This is set to true as long as the song is playing
    isPaused As Byte ' Set this to true to pause playback
    qb64Timer As Long ' We use this to store the QB64 timer number
    speed As Unsigned Byte ' Current song speed
    bpm As Unsigned Byte ' Current song BPM
    tick As Unsigned Byte ' Current song tick
    qb64SoundPipe As Long ' QB64 sound pipe that we will use to stream the mixed audio
    volume As Unsigned Byte ' Song master volume 0 is none ... 255 is full
    mixRate As Long ' This is always set by QB64 internal audio engine
    mixBufferSize As Unsigned Long ' This is the amount of samples we have to mix based on mixerRate & bpm
    useHQMix As Byte ' If this is set to true, then we are using linear interpolation mixing
End Type
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' EXTERNAL LIBRARIES
'-----------------------------------------------------------------------------------------------------
Declare Library
    Function isprint& (ByVal c As Long)
End Declare
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------    ------------------------------------------------------------------
Dim Shared Song As SongType
Dim Shared Order(0 To ORDER_TABLE_MAX) As Unsigned Byte ' Order list
ReDim Shared Pattern(0 To 0, 0 To 0, 0 To 0) As PatternType ' Pattern data strored as (pattern, row, channel)
ReDim Shared Sample(1 To 1) As SampleType ' Sample info array. One based because sample 0 means nothing (well something :) in the pattern data
ReDim Shared SampleData(1 To 1) As String ' Sample data array. Again one based for same reason above
ReDim Shared Channel(0 To 0) As ChannelType ' Channel info array
ReDim Shared FrequencyTable(0 To 0) As Unsigned Integer
ReDim Shared NoteTable(0 To 0) As String * 3
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM DATA
'-----------------------------------------------------------------------------------------------------
' Amiga frequency table
FreqTab:
Data 296
Data 907,900,894,887,881,875,868,862
Data 856,850,844,838,832,826,820,814
Data 808,802,796,791,785,779,774,768
Data 762,757,752,746,741,736,730,725
Data 720,715,709,704,699,694,689,684
Data 678,675,670,665,660,655,651,646
Data 640,636,632,628,623,619,614,610
Data 604,601,597,592,588,584,580,575
Data 570,567,563,559,555,551,547,543
Data 538,535,532,528,524,520,516,513
Data 508,505,502,498,494,491,487,484
Data 480,477,474,470,467,463,460,457
Data 453,450,447,444,441,437,434,431
Data 428,425,422,419,416,413,410,407
Data 404,401,398,395,392,390,387,384
Data 381,379,376,373,370,368,365,363
Data 360,357,355,352,350,347,345,342
Data 339,337,335,332,330,328,325,323
Data 320,318,316,314,312,309,307,305
Data 302,300,298,296,294,292,290,288
Data 285,284,282,280,278,276,274,272
Data 269,268,266,264,262,260,258,256
Data 254,253,251,249,247,245,244,242
Data 240,238,237,235,233,232,230,228
Data 226,225,223,222,220,219,217,216
Data 214,212,211,209,208,206,205,203
Data 202,200,199,198,196,195,193,192
Data 190,189,188,187,185,184,183,181
Data 180,179,177,176,175,174,172,171
Data 170,169,167,166,165,164,163,161
Data 160,159,158,157,156,155,154,152
Data 151,150,149,148,147,146,145,144
Data 143,142,141,140,139,138,137,136
Data 135,134,133,132,131,130,129,128
Data 127,126,125,125,123,123,122,121
Data 120,119,118,118,117,116,115,114
Data 113,113,112,111,110,109,109,108
Data NaN

NoteTab:
Data 37
Data "   "
Data C-1,C#1,D-1,D#1,E-1,F-1,F#1,G-1,G#1,A-1,A#1,B-1
Data C-2,C#2,D-2,D#2,E-2,F-2,F#2,G-2,G#2,A-2,A#2,B-2
Data C-3,C#3,D-3,D#3,E-3,F-3,F#3,G-3,G#3,A-3,A#3,B-3
Data LOL
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'-----------------------------------------------------------------------------------------------------
Dim modfile As String

If CommandCount > 0 Then modfile = Command$ Else modfile = "elysium.mod"

If LoadMODFile(modfile) Then
    Print "Loaded MOD file!"
Else
    Print "Failed to load file!"
    End
End If

'PrintMODInfo

StartMODPlayer
'Song.volume = 0.5
'Song.isLooping = TRUE
Song.useHQMix = TRUE

Dim nChan As Unsigned Byte
Do
    If InKey$ = Chr$(27) Then Exit Do

    Print Hex$(Song.orderPosition); "-"; Hex$(Order(Song.orderPosition)); "-"; Hex$(Song.patternRow); ": ";
    For nChan = 0 To Song.channels - 1
        Print Hex$(nChan); "> "; Hex$(Channel(nChan).sample); " "; NoteTable(Channel(nChan).period / 8); " "; Hex$(Channel(nChan).effect); " "; Hex$(Channel(nChan).operand); " ";
    Next
    Print

    Delay 0.01
Loop While Song.isPlaying

StopMODPlayer

End
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------
' Dumps mod guts to the screen
' This is just used for debugging
Sub PrintMODInfo
    Print "Name: "; Song.songName
    Print "Type: "; Song.subtype; " with"; Song.channels; "channels and"; Song.samples; "samples"
    Print "Orders:"; Song.orders, "Highest Pattern:"; Song.highestPattern, "End Jump Order:"; Song.endJumpOrder
    Sleep

    Dim i As Unsigned Byte

    Print
    Print "Sample info:"
    For i = 1 To Song.samples
        Print "Sample name: "; Sample(i).sampleName
        Print "Volume:"; Sample(i).volume, "Finetune:"; Sample(i).fineTune
        Print "Length:"; Sample(i).length, "Loop length:"; Sample(i).loopLength, "Loop start:"; Sample(i).loopStart, "Loop end:"; Sample(i).loopEnd
        Sleep
    Next
End Sub

' Calculates and sets the timer speed and also the mixer buffer update size
' We always set the global BPM using this and never directly
Sub UpdateMODTimer (nBPM As Unsigned Byte)
    Song.bpm = nBPM

    ' Calculate the mixer buffer update size
    Song.mixBufferSize = ((Song.mixRate * 10) / Song.bpm) / 4

    ' S / (2 * B / 5) (where S is second and B is BPM)
    On Timer(Song.qb64Timer, 1 / (2 * Song.bpm / 5)) MODPlayerTimerHandler
End Sub


' Loads the MOD file into memory and prepares all required gobals
Function LoadMODFile%% (sName As String)
    ' By default we assume a failure
    LoadMODFile = FALSE

    ' Check if the file exists
    If Not FileExists(sName) Then Exit Function

    ' Attempt to open the file
    Dim fileHandle As Long
    fileHandle = FreeFile

    Open sName For Binary Access Read As fileHandle

    ' Check what kind of MOD file this is
    ' Seek to offset 1080 (438h) in the file & read in 4 bytes
    Dim i As Unsigned Integer
    Get fileHandle, 1081, Song.subtype

    ' Also, seek to the beginning of the file and get the song title
    Get fileHandle, 1, Song.songName

    Song.channels = 0
    Song.samples = 0

    Select Case Song.subtype
        Case "FEST", "FIST", "LARD", "M!K!", "M&K!", "M.K.", "N.T.", "NSMS", "PATT"
            Song.channels = 4
            Song.samples = 31
        Case "OCTA", "OKTA"
            Song.channels = 8
            Song.samples = 31
        Case Else
            ' Parse the subtype string to check for more variants
            If Right$(Song.subtype, 3) = "CHN" Then
                ' Check xCNH types
                Song.channels = Val(Left$(Song.subtype, 1))
                Song.samples = 31
            ElseIf Right$(Song.subtype, 2) = "CH" Or Right$(Song.subtype, 2) = "CN" Then
                ' Check for xxCH & xxCN types
                Song.channels = Val(Left$(Song.subtype, 2))
                Song.samples = 31
            ElseIf Left$(Song.subtype, 3) = "FLT" Or Left$(Song.subtype, 3) = "TDZ" Or Left$(Song.subtype, 3) = "EXO" Then
                ' Check for FLTx, TDZx & EXOx types
                Song.channels = Val(Right$(Song.subtype, 1))
                Song.samples = 31
            ElseIf Left$(Song.subtype, 2) = "CD" And Right$(Song.subtype, 1) = "1" Then
                ' Check for CDx1 types
                Song.channels = Val(Mid$(Song.subtype, 3, 1))
                Song.samples = 31
            ElseIf Left$(Song.subtype, 2) = "FA" Then
                ' Check for FAxx types
                Song.channels = Val(Right$(Song.subtype, 2))
                Song.samples = 31
            Else
                ' Sanity check for default 15 sample MODs
                For i = 1 To Len(Song.songName)
                    If isprint(Asc(Song.songName, i)) = 0 And Asc(Song.songName, i) <> NULL Then
                        ' This is probably not a 15 sample MOD file
                        Close fileHandle
                        Exit Function
                    End If
                Next
                Song.channels = 4
                Song.samples = 15
                Song.subtype = "MO15" ' Change subtype to reflect 15-sample mod, otherwise it will contain garbage
            End If
    End Select

    ' Sanity check
    If (Song.samples = 0 Or Song.channels = 0) Then
        Close fileHandle
        Exit Function
    End If

    ' Resize the sample array
    ReDim Sample(1 To Song.samples) As SampleType
    Dim As Unsigned Byte byte1, byte2

    ' Load the sample headers
    For i = 1 To Song.samples
        ' Read the sample name
        Get fileHandle, , Sample(i).sampleName

        ' Read sample length
        Get fileHandle, , byte1
        Get fileHandle, , byte2
        Sample(i).length = (byte1 * &H100 + byte2) * 2
        If Sample(i).length = 2 Then Sample(i).length = 0 ' Sanity check

        ' Read finetune
        Sample(i).fineTune = Asc(Input$(1, fileHandle))
        If Sample(i).fineTune > 7 Then Sample(i).fineTune = Sample(i).fineTune - 16 ' This will make our finetunes value proper on the numberline

        ' Read volume
        Sample(i).volume = Asc(Input$(1, fileHandle))
        If Sample(i).volume > SAMPLE_VOLUME_MAX Then Sample(i).volume = SAMPLE_VOLUME_MAX ' Sanity check

        ' Read loop start
        Get fileHandle, , byte1
        Get fileHandle, , byte2
        Sample(i).loopStart = (byte1 * &H100 + byte2) * 2
        If Sample(i).loopStart > Sample(i).length - 1 Then Sample(i).loopStart = 0 ' Sanity check

        ' Read loop length
        Get fileHandle, , byte1
        Get fileHandle, , byte2
        Sample(i).loopLength = (byte1 * &H100 + byte2) * 2
        If Sample(i).loopLength = 2 Then Sample(i).loopLength = 0 ' Sanity check

        ' Calculate repeat end
        Sample(i).loopEnd = Sample(i).loopStart + Sample(i).loopLength
        If Sample(i).loopEnd > Sample(i).length Then Sample(i).loopEnd = Sample(i).length ' Sanity check
    Next

    Song.orders = Asc(Input$(1, fileHandle))
    If Song.orders > ORDER_TABLE_MAX + 1 Then Song.orders = ORDER_TABLE_MAX + 1
    Song.endJumpOrder = Asc(Input$(1, fileHandle))
    If Song.endJumpOrder >= Song.orders Then Song.endJumpOrder = 0

    'Load the pattern table, and find the highest pattern to load.
    Song.highestPattern = 0
    For i = 0 To ORDER_TABLE_MAX
        Order(i) = Asc(Input$(1, fileHandle))
        If Order(i) > Song.highestPattern Then Song.highestPattern = Order(i)
    Next

    ' Resize pattern data array
    ReDim Pattern(0 To Song.highestPattern, 0 To PATTERN_ROW_MAX, 0 To Song.channels - 1) As PatternType

    ' Skip past the 4 byte marker if this is a 31 sample mod
    If Song.samples = 31 Then Seek fileHandle, Loc(1) + 5

    ' Load the frequency table
    Dim c As Unsigned Integer
    Restore FreqTab
    Read c ' Read the size
    ReDim FrequencyTable(0 To c - 1) As Unsigned Integer ' Allocate size elements
    ' Now read size values
    For i = 0 To c - 1
        Read FrequencyTable(i)
    Next

    Dim As Unsigned Byte byte3, byte4
    Dim As Unsigned Integer a, b, period

    ' Load the patterns
    ' TODO: special handling for FLT8?
    For i = 0 To Song.highestPattern
        For a = 0 To PATTERN_ROW_MAX
            For b = 0 To Song.channels - 1
                Get fileHandle, , byte1
                Get fileHandle, , byte2
                Get fileHandle, , byte3
                Get fileHandle, , byte4

                Pattern(i, a, b).sample = (byte1 And &HF0) Or SHR(byte3, 4)

                period = SHL(byte1 And &HF, 8) Or byte2
                ' Do the look up in the table against what is read in
                ' Store note (in midi style format)
                Pattern(i, a, b).period = 0
                For c = 1 To 36
                    If period > FrequencyTable(c * 8) - 3 And period < FrequencyTable(c * 8) + 3 Then
                        Pattern(i, a, b).period = c * 8
                    End If
                Next

                Pattern(i, a, b).effect = byte3 And &HF
                Pattern(i, a, b).operand = byte4

                ' Some sanity check
                If Pattern(i, a, b).sample > Song.samples Then Pattern(i, a, b).sample = 0 ' Sample 0 means no sample. So valid sample are 1-15/31
                '  TODO: Check if these are really required
                'If Pattern(i, a, b).effect = &HC And Pattern(i, a, b).operand > 64 Then Pattern(i, a, b).operand = 64
            Next
        Next
    Next

    ' Resize the sample data array
    ReDim SampleData(1 To Song.samples) As String

    ' Load the samples
    For i = 1 To Song.samples
        ' Resize the sample data
        SampleData(i) = Space$(Sample(i).length)
        ' Now load the data
        Get fileHandle, , SampleData(i)
        ' Allocate 2 bytes more than needed for mixer runoff
        SampleData(i) = SampleData(i) + String$(2, NULL)
    Next

    Close fileHandle

    LoadMODFile = TRUE
End Function


' Initializes the audio mixer, prepares eveything else for playback and kick starts the timer and hence song playback
Sub StartMODPlayer
    ' Load the note table
    Dim As Unsigned Integer i, s
    Restore NoteTab
    Read s
    ReDim NoteTable(0 To s - 1) As String * 3
    For i = 0 To s - 1
        Read NoteTable(i)
    Next

    ' Set the mix rate to match that of the system
    Song.mixRate = SndRate

    ' Initialize some important stuff
    Song.orderPosition = 0
    Song.patternRow = 0
    Song.speed = SONG_SPEED_DEFAULT
    Song.tick = Song.speed
    Song.volume = SONG_VOLUME_MAX
    Song.isPaused = FALSE

    ' Setup the channel array
    ReDim Channel(0 To Song.channels - 1) As ChannelType

    ' Setup panning for all channels except last one if we have an odd number
    For i = 0 To Song.channels - 1 - (Song.channels Mod 2)
        If i Mod 2 = 0 Then
            Channel(i).panningPosition = SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTRE / 2
        Else
            Channel(i).panningPosition = SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTRE / 2
        End If
    Next
    ' Set the last channel to center. This also works for single channel
    If Song.channels Mod 2 = 1 Then
        Channel(Song.channels - 1).panningPosition = SAMPLE_PAN_CENTRE
    End If

    ' Allocate a QB64 sound pipe
    Song.qb64SoundPipe = SndOpenRaw

    ' Allocate a QB64 Timer
    Song.qb64Timer = FreeTimer
    UpdateMODTimer SONG_BPM_DEFAULT
    Timer(Song.qb64Timer) On

    Song.isPlaying = TRUE
End Sub


' Frees all allocated resources, stops the timer and hence song playback
Sub StopMODPlayer
    ' Free QB64 timer
    Timer(Song.qb64Timer) Off
    Timer(Song.qb64Timer) Free

    ' Close QB64 sound pipe
    SndClose Song.qb64SoundPipe

    Song.isPlaying = FALSE
End Sub


' Called by the QB64 timer at a specified rate
Sub MODPlayerTimerHandler
    ' Simply do not process anything if song is paused
    If Song.isPaused Then Exit Sub

    ' Check conditions for which we should just exit or loop
    If Song.orderPosition >= Song.orders Then
        If Song.isLooping Then
            Song.orderPosition = Song.endJumpOrder
            Song.patternRow = 0
            Song.speed = SONG_SPEED_DEFAULT
            Song.tick = Song.speed
        Else
            Song.isPlaying = FALSE
            Exit Sub
        End If
    End If

    ' Set the playing flag to true
    Song.isPlaying = TRUE

    If Song.tick >= Song.speed Then
        ' Reset song tick
        Song.tick = 0

        ' Process pattern row if pattern delay is over
        If Song.patternDelay = 0 Then
            UpdateMODRow

            ' Increment the row counter
            ' Note UpdateMODTick() should not pickup stuff from the pattern array but from the channel array
            ' This is because we are already at a new row not processed by UpdateMODRow()
            Song.patternRow = Song.patternRow + 1

            ' Check if we have finished the pattern and then move to the next one
            If Song.patternRow > PATTERN_ROW_MAX Then
                Song.orderPosition = Song.orderPosition + 1
                Song.patternRow = 0
            End If
        Else
            Song.patternDelay = Song.patternDelay - 1
        End If
    Else
        UpdateMODTick
    End If

    ' Mix the current tick
    MixMODFrame

    ' Increment song tick on each update
    Song.tick = Song.tick + 1
End Sub


' Updates a row of notes and play them out on tick 0
Sub UpdateMODRow
    ' The pattern that we are playing is always Order(OrderPosition)
    Dim As Unsigned Byte nPattern, nSample, nEffect, nOperand, nOpX, nOpY, nChannel
    Dim nPeriod As Unsigned Integer

    nPattern = Order(Song.orderPosition)

    ' Process all channels
    For nChannel = 0 To Song.channels - 1
        nSample = Pattern(nPattern, Song.patternRow, nChannel).sample
        nPeriod = Pattern(nPattern, Song.patternRow, nChannel).period
        nEffect = Pattern(nPattern, Song.patternRow, nChannel).effect
        nOperand = Pattern(nPattern, Song.patternRow, nChannel).operand
        nOpX = SHR(nOperand, 4)
        nOpY = nOperand And &HF

        ' Set volume. We never play if sample number is zero. Our sample array is 1 based
        ' ONLY RESET VOLUME IF THERE IS AN SAMPLE NUMBER
        If nSample > 0 Then
            Channel(nChannel).sample = nSample
            Channel(nChannel).volume = Sample(nSample).volume
        End If

        ' ONLY RESET PITCH IF THERE IS A PERIOD VALUE AND PORTA NOT SET
        If nPeriod > 0 Then
            Channel(nChannel).period = nPeriod
            ' If not a porta effect, then set the channel pitch to the looked up amiga value + or - any finetune
            If nEffect <> 3 And nEffect <> 5 Then
                Channel(nChannel).pitch = (AMIGA_PAULA_CLOCK_RATE / (FrequencyTable(nPeriod + Sample(Channel(nChannel).sample).fineTune) * 2)) / Song.mixRate
                Channel(nChannel).played = FALSE
                Channel(nChannel).samplePosition = 0
            End If
        End If

        ' Process tick 0 effects
        Select Case nEffect
            Case &H0 ' Arpeggio
            Case &H1 ' Slide up
            Case &H2 ' Slide Down
            Case &H3 ' Tone Portamento
            Case &H4 ' Vibrato
            Case &H5 ' Tone Portamento + Volume Slide
            Case &H6 ' Vibrato + Volume Slide
            Case &H7 ' Tremolo
            Case &H8 ' Set Panning Position
                If nOperand = 164 Then
                    ' TODO: handle surround?
                    Title "Surround effect 8 not implemented!"
                Else
                    Channel(nChannel).panningPosition = nOperand
                End If

            Case &H9 ' Set Sample Offset
            Case &HA ' Volume Slide
            Case &HB ' Position Jump
            Case &HC ' Set Volume
                Channel(nChannel).volume = nOperand
                If Channel(nChannel).volume > SAMPLE_VOLUME_MAX Then Channel(nChannel).volume = SAMPLE_VOLUME_MAX

            Case &HD ' Pattern Break
            Case &HE ' Extended Effects
            Case &HF ' Set Speed
                If nOperand < 32 Then
                    Song.speed = nOperand
                Else
                    UpdateMODTimer nOperand
                End If

            Case Else
                Title "Effect not supported: " + Str$(nEffect) + "!"
        End Select
    Next
End Sub


' Updates any tick based effects after tick 0
Sub UpdateMODTick
    ' The pattern that we are playing is always Order(OrderPosition)
    Dim As Unsigned Byte nPattern, nSample, nEffect, nOperand, nOpX, nOpY, nChannel
    Dim nPeriod As Unsigned Integer

    nPattern = Order(Song.orderPosition)

    ' Process all channels
    For nChannel = 0 To Song.channels - 1
        ' We are not processing a new row but tick 1+ effects
        ' So we pick these up from the channel array
        nSample = Channel(nChannel).sample
        nPeriod = Channel(nChannel).period
        nEffect = Channel(nChannel).effect
        nOperand = Channel(nChannel).operand
        nOpX = SHR(nOperand, 4)
        nOpY = nOperand And &HF

        Select Case nEffect
            Case &H0 ' Arpeggio
            Case &H1 ' Slide up
            Case &H2 ' Slide Down
            Case &H3 ' Tone Portamento
            Case &H4 ' Vibrato
            Case &H5 ' Tone Portamento + Volume Slide
            Case &H6 ' Vibrato + Volume Slide
            Case &H7 ' Tremolo
            Case &H8 ' Set Panning Position
            Case &H9 ' Set Sample Offset
            Case &HA ' Volume Slide
            Case &HB ' Position Jump
            Case &HC ' Set Volume
            Case &HD ' Pattern Break
            Case &HE ' Extended Effects
            Case &HF ' Set Speed
            Case Else
                Title "Effect not supported: " + Str$(nEffect) + "!"
        End Select
    Next
End Sub


' Mixes and queues a frame/tick worth of samples
' All mixing calculations are done using floating-point math (it's 2022 :)
Sub MixMODFrame
    Dim i As Unsigned Long
    Dim As Unsigned Byte chan, nSample, vol, pan
    Dim As Single fpos, sam, samLT, samRT
    Dim As Byte sam1, sam2

    For i = 1 To Song.mixBufferSize
        samLT = 0
        samRT = 0

        For chan = 0 To Song.channels - 1
            ' Check if we need to mix the sample, wrap or simply stop
            ' Get one sample from each channel
            ' Add the sample to samLT & samRT after coverting to QB64 sound pipe format considering panning
            ' Increment the sample position and check other stuff

            ' Get the sample number we need to work with
            nSample = Channel(chan).sample

            ' Only proceed if we have a valid sample number (> 0)
            If Not nSample = 0 Then
                ' Check if we are looping
                If Sample(nSample).loopLength > 0 Then
                    ' Reset loop position if we reached the end of the loop
                    If Channel(chan).samplePosition > Sample(nSample).loopEnd Then
                        Channel(chan).samplePosition = Sample(nSample).loopStart
                    End If
                Else
                    ' For non-looping sample simply set the played flag as true if we reached the end
                    If Channel(chan).samplePosition >= Sample(nSample).length Then
                        Channel(chan).played = TRUE
                    End If
                End If

                ' Only mix the sample if we have not completed or are looping
                If Not Channel(chan).played Or Sample(nSample).loopLength > 0 Then
                    fpos = Channel(chan).samplePosition
                    vol = Channel(chan).volume
                    pan = Channel(chan).panningPosition

                    ' Get a sample, change format and add
                    ' Samples are stored in a string and strings are 1 based
                    If Song.useHQMix Then
                        sam1 = Asc(SampleData(nSample), 1 + Fix(fpos))
                        sam2 = Asc(SampleData(nSample), 2 + Fix(fpos))
                        sam = sam1 + (sam2 - sam1) * (fpos - Fix(fpos))
                    Else
                        sam1 = Asc(SampleData(nSample), 1 + fpos)
                        sam = sam1
                    End If

                    ' The following two lines does volume & panning
                    samLT = samLT + (sam * (((SAMPLE_PAN_RIGHT - pan) * vol) / SAMPLE_PAN_RIGHT) / SAMPLE_VOLUME_MAX) / 128 ' MOD sound samples are signed -128 to 127
                    samRT = samRT + (sam * ((pan * vol) / SAMPLE_PAN_RIGHT) / SAMPLE_VOLUME_MAX) / 128 ' So, we divide the samples by 128 to convert these to QB64 sound pipe format

                    ' Move to the next sample position based on the pitch
                    Channel(chan).samplePosition = Channel(chan).samplePosition + Channel(chan).pitch
                End If
            End If
        Next

        ' Now divide the summed sample by the number of channels and apply master volume
        samLT = (samLT / Song.channels) * Song.volume / SONG_VOLUME_MAX
        samRT = (samRT / Song.channels) * Song.volume / SONG_VOLUME_MAX
        ' Feed the sample to the QB64 sound pipe
        SndRaw samLT, samRT, Song.qb64SoundPipe
    Next
End Sub
'-----------------------------------------------------------------------------------------------------

