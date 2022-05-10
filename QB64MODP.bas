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
'$Debug
$Resize:Smooth
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------
Const FALSE%% = 0%%, TRUE%% = Not FALSE
Const NULL%% = 0%%
Const NULLSTRING$ = ""

Const AMIGA_CONSTANT! = 3579545.25! ' PAL: 7093789.2 / 2, NSTC: 7159090.5 / 2
Const PATTERN_ROW_MAX~%% = 63~%% ' Max row number in a pattern
Const ORDER_TABLE_MAX~%% = 127~%% ' Max position in the order table
Const SAMPLE_VOLUME_MAX~%% = 64~%% ' This is the maximum volume of any sample in the MOD
Const SAMPLE_PAN_LEFT~%% = 0~%% ' Leftmost pannning position
Const SAMPLE_PAN_RIGHT~%% = 255~%% ' Rightmost pannning position
Const SAMPLE_PAN_CENTRE! = (SAMPLE_PAN_RIGHT - SAMPLE_PAN_LEFT) / 2! ' Center panning position
Const SONG_SPEED_DEFAULT~%% = 6~%% ' This is the default speed for song where it is not specified
Const SONG_BPM_DEFAULT~%% = 125~%% ' Default song BPM
Const SONG_VOLUME_MAX~%% = 255~%% ' Max song master volume
Const BUFFER_UNDERRUN_PROTECTION~%% = 64~%% ' This prevents audio pops and glitches due to QB64 timer inaccuracy
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
    period As Integer ' BBBBCCCCCCCC = sample period value (signed becuase invalids will have -1)
    effect As Unsigned Byte ' eeee = effect number
    operand As Unsigned Byte ' FFFFFFFF = effect parameters
End Type

Type SampleType
    sampleName As String * 22 ' Sample name or message
    length As Long ' Sample length in bytes
    fineTune As Byte ' Lower four bits are the finetune value, stored as a *signed* four bit number
    volume As Unsigned Byte ' Volume: 0 - 64
    loopStart As Long ' Loop start in bytes
    loopLength As Long ' Loop length in bytes
    loopEnd As Long ' Loop end in bytes
End Type

Type ChannelType
    sample As Unsigned Byte ' Sample number to be mixed
    volume As Integer ' Channel volume. This is a signed int because we need -ve values & to clip properly
    played As Byte ' This is set to true once the mixer is done with the sample
    pitch As Single ' Sample pitch. The mixer code uses this to step through the sample correctly
    frequency As Unsigned Integer ' This is frequency of the playing sample used by various effects
    period As Integer ' Period + finetune for various effects (signed, see above)
    panningPosition As Single ' Position 0 is leftmost ... 255 is rightmost
    samplePosition As Single ' Where are we in the sample buffer (fp32)
    patternLoopRow As Integer ' This (signed) is the beginning of the loop in the pattern for effect E6x
    patternLoopRowCounter As Unsigned Byte ' This is a loop counter for effect E6x
    portamentoTo As Unsigned Integer ' Note to porta to value for E3x
    portamentoSpeed As Unsigned Byte ' Porta speed for E3x
    vibratoPosition As Byte ' Vibrato position in the sine table for E4x (signed)
    vibratoDepth As Unsigned Byte ' Vibrato depth
    vibratoSpeed As Unsigned Byte ' Vibrato speed
    tremoloPosition As Byte ' Tremolo position in the sine table (singned)
    waveControl As Unsigned Byte ' Waveform type for vibrato and tremolo (4 bits each)
    sampleOffset As Long ' This is used for effect 9xy
End Type

Type SongType
    songName As String * 20 ' Song name
    subtype As String * 4 ' 4 char MOD type - use this to find out what tracker was used
    channels As Unsigned Byte ' Number of channels in the song - can be any number depending on the MOD file
    samples As Unsigned Byte ' Number of samples in the song - can be 15 or 31 depending on the MOD file
    orders As Unsigned Byte ' Song length in orders
    endJumpOrder As Unsigned Byte ' This is used for jumping to an order if global looping is on
    highestPattern As Unsigned Byte ' The highest pattern number read from the MOD file
    orderPosition As Integer ' The position in the order list. Signed so that we can properly wrap
    patternRow As Integer ' Points to the pattern row to be played. This is signed because sometimes we need to set it to -1
    patternDelay As Unsigned Byte ' Number of times to delay pattern for effect EE
    tickPattern As Unsigned Byte ' Pattern number for UpdateMODRow() & UpdateMODTick()
    tickPatternRow As Integer ' Pattern row number for UpdateMODTick() only (signed)
    isLooping As Byte ' Set this to true to loop the song once we reach the max order specified in the song
    isPlaying As Byte ' This is set to true as long as the song is playing
    isPaused As Byte ' Set this to true to pause playback
    qb64Timer As Long ' We use this to store the QB64 timer number
    speed As Unsigned Byte ' Current song speed
    bpm As Unsigned Byte ' Current song BPM
    tick As Unsigned Byte ' Current song tick
    qb64SoundPipe As Long ' QB64 sound pipe that we will use to stream the mixed audio
    volume As Unsigned Byte ' Song master volume 0 is none ... 255 is full
    mixerRate As Long ' This is always set by QB64 internal audio engine
    mixerBufferSize As Unsigned Long ' This is the amount of samples we have to mix based on mixerRate & bpm
    useHQMixer As Byte ' If this is set to true, then we are using linear interpolation mixing
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
'-----------------------------------------------------------------------------------------------------
Dim Shared Song As SongType
Dim Shared Order(0 To ORDER_TABLE_MAX) As Unsigned Byte ' Order list
ReDim Shared Pattern(0 To 0, 0 To 0, 0 To 0) As PatternType ' Pattern data strored as (pattern, row, channel)
ReDim Shared Sample(1 To 1) As SampleType ' Sample info array. One based because sample 0 means nothing (well something :) in the pattern data
ReDim Shared SampleData(1 To 1) As String ' Sample data array. Again one based for same reason above
ReDim Shared Channel(0 To 0) As ChannelType ' Channel info array
ReDim Shared FrequencyTable(0 To 0) As Unsigned Integer ' Amiga frequency table
ReDim Shared SineTable(0 To 0) As Unsigned Byte ' Sine table used for effects
ReDim Shared NoteTable(0 To 0) As String * 3 ' This is for the UI. TODO: Move this out to a different file
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM DATA
'-----------------------------------------------------------------------------------------------------
' Amiga frequency table.
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

' Sine table for tremolo & vibrato
SineTab:
Data 32
Data 0,24,49,74,97,120,141,161
Data 180,197,212,224,235,244,250,253
Data 255,253,250,244,235,224,212,197
Data 180,161,141,120,97,74,49,24
Data NaN

' Note string table for UI
' TODO: Move this out to different file
NoteTab:
Data 37
Data "   "
Data C-1,C#1,D-1,D#1,E-1,F-1,F#1,G-1,G#1,A-1,A#1,B-1
Data C-2,C#2,D-2,D#2,E-2,F-2,F#2,G-2,G#2,A-2,A#2,B-2
Data C-3,C#3,D-3,D#3,E-3,F-3,F#3,G-3,G#3,A-3,A#3,B-3
Data LOL
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - This is just test code. We have no proper UI yet
'-----------------------------------------------------------------------------------------------------
Dim As String modFileName

If CommandCount > 0 Then modFileName = Command$ Else modFileName = "mods/nemesis.mod"

If LoadMODFile(modFileName) Then
    Print "Loaded MOD file!"
Else
    Print "Failed to load file!"
    End
End If

'PrintMODInfo

Title "QB64 MOD Player - " + modFileName
StartMODPlayer
Song.isLooping = TRUE

Width 12 + (Song.channels * 18), 40

Dim nChan As Unsigned Byte, k As String
Do
    Print Using "### ### ##: "; Song.orderPosition; Order(Song.orderPosition); Song.patternRow;
    For nChan = 0 To Song.channels - 1
        Print Using ">##< ## & \\ \\ "; nChan; Channel(nChan).sample; NoteTable(Pattern(Order(Song.orderPosition), Song.patternRow, nChan).period / 8); Hex$(Pattern(Order(Song.orderPosition), Song.patternRow, nChan).effect); Hex$(Pattern(Order(Song.orderPosition), Song.patternRow, nChan).operand);
    Next
    Print 'SndRawLen

    k = InKey$

    Select Case k
        Case Chr$(27)
            Exit Do

        Case " "
            Song.isPaused = Not Song.isPaused

        Case "=", "+"
            Song.volume = Song.volume + 1

        Case "-", "_"
            Song.volume = Song.volume - 1

        Case "l", "L"
            Song.isLooping = Not Song.isLooping

        Case "q", "Q"
            Song.useHQMixer = Not Song.useHQMixer

        Case ",", "<"
            Song.orderPosition = Song.orderPosition - 1
            If Song.orderPosition < 0 Then Song.orderPosition = Song.orders - 1

        Case ".", ">"
            Song.orderPosition = Song.orderPosition + 1
            If Song.orderPosition >= Song.orders Then Song.orderPosition = 0
    End Select

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
    Song.mixerBufferSize = (Song.mixerRate * 5) / (2 * Song.bpm)

    ' S / (2 * B / 5) (where S is second and B is BPM)
    On Timer(Song.qb64Timer, 5 / (2 * Song.bpm)) MODPlayerTimerHandler
End Sub


' Loads the MOD file into memory and prepares all required gobals
Function LoadMODFile%% (sFileName As String)
    ' By default we assume a failure
    LoadMODFile = FALSE

    ' Check if the file exists
    If Not FileExists(sFileName) Then Exit Function

    ' Attempt to open the file
    Dim fileHandle As Long
    fileHandle = FreeFile

    Open sFileName For Binary Access Read As fileHandle

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
                ' Extra checks for 15 sample MOD
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
        If Sample(i).loopStart >= Sample(i).length Then Sample(i).loopStart = 0 ' Sanity check

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
    Dim c As Unsigned Integer

    ' Skip past the 4 byte marker if this is a 31 sample mod
    If Song.samples = 31 Then Seek fileHandle, Loc(1) + 5

    ' Load the frequency table
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

                ' Do the look up in the table against what is read in and store note
                Pattern(i, a, b).period = -1
                For c = 1 To 36
                    If period > FrequencyTable(c * 8) - 3 And period < FrequencyTable(c * 8) + 3 Then
                        Pattern(i, a, b).period = c * 8
                    End If
                Next

                Pattern(i, a, b).effect = byte3 And &HF
                Pattern(i, a, b).operand = byte4

                ' Some sanity check
                If Pattern(i, a, b).sample > Song.samples Then Pattern(i, a, b).sample = 0 ' Sample 0 means no sample. So valid sample are 1-15/31
            Next
        Next
    Next

    ' Resize the sample data array
    ReDim SampleData(1 To Song.samples) As String

    ' Load the samples
    For i = 1 To Song.samples
        ' Read and load sample size bytes of data. Also allocate 2 bytes more than needed for mixer runoff
        SampleData(i) = Input$(Sample(i).length, fileHandle) + String$(2, NULL)
    Next

    Close fileHandle

    LoadMODFile = TRUE
End Function


' Initializes the audio mixer, prepares eveything else for playback and kick starts the timer and hence song playback
Sub StartMODPlayer
    Dim As Unsigned Integer i, s

    ' Load the sine table
    Restore SineTab
    Read s
    ReDim SineTable(0 To s - 1) As Unsigned Byte
    For i = 0 To s - 1
        Read SineTable(i)
    Next

    ' Load the note table. TODO: Move this out to UI code files
    Restore NoteTab
    Read s
    ReDim NoteTable(0 To s - 1) As String * 3
    For i = 0 To s - 1
        Read NoteTable(i)
    Next

    ' Set the mix rate to match that of the system
    Song.mixerRate = SndRate + BUFFER_UNDERRUN_PROTECTION ' <-- This is just a lame way to avoid clicks & pops. We should really move to a polling system

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
    ' I hope I did this right. But i don't care even if it not the classic way. This is cooler :)
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

            ' Save the pattern and row for UpdateMODTick()
            ' The pattern that we are playing is always Song.tickPattern
            Song.tickPattern = Order(Song.orderPosition)
            Song.tickPatternRow = Song.patternRow

            ' Process the row
            UpdateMODRow

            ' Increment the row counter
            ' Note UpdateMODTick() should pickup stuff using tickPattern & tickPatternRow
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
    Dim As Unsigned Byte nSample, nEffect, nOperand, nOpX, nOpY, nChannel
    Dim As Integer nPeriod, nPatternRow
    ' This are set to true when a pattern jump effect and pattern break effect are triggered
    Dim As Byte patternJumpFlag, patternBreakFlag

    ' We need this so that we don't start accessing -1 elements in the pattern array when there is a pattern jump
    nPatternRow = Song.patternRow

    ' Process all channels
    For nChannel = 0 To Song.channels - 1
        nSample = Pattern(Song.tickPattern, nPatternRow, nChannel).sample
        nPeriod = Pattern(Song.tickPattern, nPatternRow, nChannel).period
        nEffect = Pattern(Song.tickPattern, nPatternRow, nChannel).effect
        nOperand = Pattern(Song.tickPattern, nPatternRow, nChannel).operand
        nOpX = SHR(nOperand, 4)
        nOpY = nOperand And &HF

        ' Set volume. We never play if sample number is zero. Our sample array is 1 based
        ' ONLY RESET VOLUME IF THERE IS A SAMPLE NUMBER
        If nSample > 0 Then
            Channel(nChannel).sample = nSample
            Channel(nChannel).volume = Sample(nSample).volume
        End If

        ' ONLY RESET PITCH IF THERE IS A PERIOD VALUE AND PORTA NOT SET
        If nPeriod >= 0 Then
            Channel(nChannel).period = nPeriod + Sample(Channel(nChannel).sample).fineTune

            ' Retrigger tremolo and vibrato waveforms
            If Channel(nChannel).waveControl And &HF < 4 Then Channel(nChannel).vibratoPosition = 0
            If SHR(Channel(nChannel).waveControl, 4) < 4 Then Channel(nChannel).tremoloPosition = 0

            ' If not a porta effect, then set the channel pitch to the looked up amiga value + or - any finetune
            If nEffect <> &H3 And nEffect <> &H5 Then ' TODO: And note delay?
                Channel(nChannel).played = FALSE
                Channel(nChannel).samplePosition = 0
                Channel(nChannel).frequency = FrequencyTable(Channel(nChannel).period)
                Channel(nChannel).pitch = GetPitchFromFrequency(Channel(nChannel).frequency)
            End If
        End If

        ' Process tick 0 effects
        Select Case nEffect
            Case &H3 ' 3: Porta To Note
                ' Just remember stuff here
                If nOperand > 0 Then Channel(nChannel).portamentoSpeed = nOperand
                If nPeriod >= 0 Then Channel(nChannel).portamentoTo = FrequencyTable(Channel(nChannel).period)

            Case &H5 ' 5: Tone Portamento + Volume Slide
                ' Just remember stuff here
                If nPeriod >= 0 Then Channel(nChannel).portamentoTo = FrequencyTable(Channel(nChannel).period)

            Case &H4 ' 4: Vibrato
                If nOpX > 0 Then Channel(nChannel).vibratoSpeed = nOpX
                If nOpY > 0 Then Channel(nChannel).vibratoDepth = nOpY

            Case &H8 ' 8: Set Panning Position
                ' Don't care about DMP panning BS. We are doing this Fasttracker style
                Channel(nChannel).panningPosition = nOperand

            Case &H9 ' 9: Set Sample Offset
                If nOperand > 0 Then Channel(nChannel).sampleOffset = nOperand * 256
                If Channel(nChannel).sampleOffset >= Sample(Channel(nChannel).sample).length Then Channel(nChannel).sampleOffset = Sample(Channel(nChannel).sample).length
                Channel(nChannel).samplePosition = Channel(nChannel).sampleOffset

            Case &HB ' 11: Jump To Pattern
                Song.orderPosition = nOperand
                Song.patternRow = -1 ' This will increment right after & we will start at 0
                If Song.orderPosition >= Song.orders Then Song.orderPosition = Song.endJumpOrder
                patternJumpFlag = TRUE

            Case &HC ' 12: Set Volume
                Channel(nChannel).volume = nOperand ' Operand can never be -ve cause it is unsigned. So we only clip for max below
                If Channel(nChannel).volume > SAMPLE_VOLUME_MAX Then Channel(nChannel).volume = SAMPLE_VOLUME_MAX

            Case &HD ' 13: Pattern Break
                Song.patternRow = (nOpX * 10) + nOpY - 1
                If Song.patternRow > PATTERN_ROW_MAX Then Song.patternRow = -1
                If Not patternBreakFlag And Not patternJumpFlag Then Song.orderPosition = Song.orderPosition + 1
                If Song.orderPosition >= Song.orders Then Song.orderPosition = Song.endJumpOrder
                patternBreakFlag = TRUE

            Case &HE ' 14: Extended Effects
                Select Case nOpX
                    Case &H0 ' 0: Set Filter
                        Song.useHQMixer = nOpY <> 0

                    Case &H1 ' 1: Fine Portamento Up
                        Channel(nChannel).frequency = Channel(nChannel).frequency - nOpY ' TODO: Check this!
                        If Channel(nChannel).frequency < 108 Then Channel(nChannel).frequency = 108
                        Channel(nChannel).pitch = GetPitchFromFrequency(Channel(nChannel).frequency)

                    Case &H2 ' 2: Fine Portamento Down
                        Channel(nChannel).frequency = Channel(nChannel).frequency + nOpY ' TODO: Check this!
                        If Channel(nChannel).frequency > 907 Then Channel(nChannel).frequency = 907
                        Channel(nChannel).pitch = GetPitchFromFrequency(Channel(nChannel).frequency)

                    Case &H3 ' 3: Glissando Control
                        Title "Extended effect not implemented: " + Str$(nEffect) + "-" + Str$(nOpX)

                    Case &H4 ' 4: Set Vibrato Waveform
                        Title "Extended effect not implemented: " + Str$(nEffect) + "-" + Str$(nOpX)

                    Case &H5 ' 5: Set Finetune
                        Sample(Channel(nChannel).sample).fineTune = nOpY
                        If Sample(Channel(nChannel).sample).fineTune > 7 Then Sample(Channel(nChannel).sample).fineTune = Sample(Channel(nChannel).sample).fineTune - 16

                    Case &H6 ' 6: Pattern Loop
                        If nOpY = 0 Then
                            Channel(nChannel).patternLoopRow = nPatternRow
                        Else
                            If Channel(nChannel).patternLoopRowCounter = 0 Then
                                Channel(nChannel).patternLoopRowCounter = nOpY
                            Else
                                Channel(nChannel).patternLoopRowCounter = Channel(nChannel).patternLoopRowCounter - 1
                            End If
                        End If
                        If Channel(nChannel).patternLoopRowCounter > 0 Then Song.patternRow = Channel(nChannel).patternLoopRow - 1

                    Case &H7 ' 7: Set Tremolo WaveForm
                        Title "Extended effect not implemented: " + Str$(nEffect) + "-" + Str$(nOpX)

                    Case &H8 ' 8: 16 position panning
                        If nOpY > 15 Then nOpY = 15
                        ' Why does this kind of stuff bother me so much. We just could have written "/ 17" XD
                        Channel(nChannel).panningPosition = nOpY * ((SAMPLE_PAN_RIGHT - SAMPLE_PAN_LEFT) / 15)

                    Case &HA ' 10: Fine Volume Slide Up
                        Channel(nChannel).volume = Channel(nChannel).volume + nOpY
                        If Channel(nChannel).volume > SAMPLE_VOLUME_MAX Then Channel(nChannel).volume = SAMPLE_VOLUME_MAX

                    Case &HB ' 11: Fine Volume Slide Down
                        Channel(nChannel).volume = Channel(nChannel).volume - nOpY
                        If Channel(nChannel).volume < 0 Then Channel(nChannel).volume = 0

                    Case &HE ' 14: Pattern Delay
                        Song.patternDelay = nOpY

                    Case &HF ' 15: Invert Loop
                        Title "Extended effect not implemented: " + Str$(nEffect) + "-" + Str$(nOpX)
                End Select

            Case &HF ' 15: Set Speed
                If nOperand < 32 Then
                    Song.speed = nOperand
                Else
                    UpdateMODTimer nOperand
                End If
        End Select
    Next
End Sub


' Updates any tick based effects after tick 0
Sub UpdateMODTick
    ' The pattern that we are playing is always Order(OrderPosition)
    Dim As Unsigned Byte nSample, nEffect, nOperand, nOpX, nOpY, nChannel
    Dim nPeriod As Integer

    ' Process all channels
    For nChannel = 0 To Song.channels - 1
        ' We are not processing a new row but tick 1+ effects
        ' So we pick these using tickPattern and tickPatternRow
        nSample = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).sample
        nPeriod = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).period
        nEffect = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).effect
        nOperand = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).operand
        nOpX = SHR(nOperand, 4)
        nOpY = nOperand And &HF

        Select Case nEffect
            Case &H0 ' 0: Arpeggio
                If (nOperand > 0) Then
                    Select Case (Song.tick + 1) Mod 3 ' +1 here to make it sound like FT2. Dunno why it works yet :(
                        Case 0
                            Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).period)
                        Case 1
                            Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).period + (8 * nOpX))
                        Case 2
                            Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).period + (8 * nOpY))
                    End Select
                End If

            Case &H1 ' 1: Porta Up
                Channel(nChannel).frequency = Channel(nChannel).frequency - nOperand
                If Channel(nChannel).frequency < 108 Then Channel(nChannel).frequency = 108
                Channel(nChannel).pitch = GetPitchFromFrequency(Channel(nChannel).frequency)

            Case &H2 ' 2: Porta Down
                Channel(nChannel).frequency = Channel(nChannel).frequency + nOperand
                If Channel(nChannel).frequency > 907 Then Channel(nChannel).frequency = 907
                Channel(nChannel).pitch = GetPitchFromFrequency(Channel(nChannel).frequency)

            Case &H3 ' 3: Porta To Note
                DoPortamento nChannel

            Case &H4 ' 4: Vibrato
                DoVibrato nChannel

            Case &H5 ' 5: Tone Portamento + Volume Slide
                DoPortamento nChannel
                DoVolumeSlide nChannel, nOpX, nOpY

            Case &H6 ' 6: Vibrato + Volume Slide
                DoVibrato nChannel
                DoVolumeSlide nChannel, nOpX, nOpY

            Case &H7 ' 7: Tremolo
                Title "Effect not implemented: " + Str$(nEffect)

            Case &HA ' 10: Volume Slide
                DoVolumeSlide nChannel, nOpX, nOpY

            Case &HE ' 14: Extended Effects
                Select Case nOpX
                    Case &H9 ' 9: Retrigger Note
                        If nOpY <> 0 Then
                            If Song.tick Mod nOpY = 0 Then
                                Channel(nChannel).played = FALSE
                                Channel(nChannel).samplePosition = 0
                            End If
                        End If

                    Case &HC ' 12: Cut Note
                        If Song.tick = nOpY Then Channel(nChannel).volume = 0

                    Case &HD ' 13: Delay Note
                        If Song.tick = nOpY Then
                            If nSample > 0 Then Channel(nChannel).volume = Sample(Channel(nChannel).sample).volume
                            Channel(nChannel).period = nPeriod + Sample(Channel(nChannel).sample).fineTune
                            Channel(nChannel).frequency = FrequencyTable(Channel(nChannel).period)
                            Channel(nChannel).pitch = GetPitchFromFrequency(Channel(nChannel).frequency)
                            Channel(nChannel).played = FALSE
                            Channel(nChannel).samplePosition = 0
                        End If
                End Select
        End Select
    Next
End Sub


' Mixes and queues a frame/tick worth of samples
' All mixing calculations are done using floating-point math (it's 2022 :)
Sub MixMODFrame
    Dim As Unsigned Long i, npos
    Dim As Unsigned Byte chan, nSample, vol
    Dim As Single fpan, fpos, fsam, fsamLT, fsamRT
    Dim As Byte bsam1, bsam2, isLooping

    For i = 1 To Song.mixerBufferSize
        fsamLT = 0
        fsamRT = 0

        For chan = 0 To Song.channels - 1
            ' Check if we need to mix the sample, wrap or simply stop
            ' Get one sample from each channel
            ' Add the sample to samLT & samRT after applying panning & volume
            ' Increment the sample position and check other stuff

            ' Get the sample number we need to work with
            nSample = Channel(chan).sample

            ' Only proceed if we have a valid sample number (> 0)
            If Not nSample = 0 Then
                ' We need these too many times
                fpos = Channel(chan).samplePosition
                isLooping = (Sample(nSample).loopLength > 0)

                ' Check if we are looping
                If isLooping Then
                    ' Reset loop position if we reached the end of the loop
                    If fpos >= Sample(nSample).loopEnd Then
                        Channel(chan).samplePosition = Sample(nSample).loopStart
                    End If
                Else
                    ' For non-looping sample simply set the played flag as true if we reached the end
                    If fpos >= Sample(nSample).length Then
                        Channel(chan).played = TRUE
                    End If
                End If

                ' We don't want anything below 0
                If fpos < 0 Then Channel(chan).samplePosition = 0

                ' Only mix the sample if we have not completed or are looping
                If Not Channel(chan).played Or isLooping Then
                    fpos = Channel(chan).samplePosition
                    vol = Channel(chan).volume
                    fpan = Channel(chan).panningPosition

                    ' Get a sample, change format and add
                    ' Samples are stored in a string and strings are 1 based
                    If Song.useHQMixer Then
                        ' Apply interpolation
                        npos = Fix(fpos)
                        bsam1 = Asc(SampleData(nSample), 1 + npos)
                        bsam2 = Asc(SampleData(nSample), 2 + npos)
                        fsam = bsam1 + (bsam2 - bsam1) * (fpos - npos)
                    Else
                        bsam1 = Asc(SampleData(nSample), 1 + fpos)
                        fsam = bsam1
                    End If

                    ' The following two lines does volume & panning
                    ' The below expressions were simplified and rearranged to reduce the number of divisions
                    fsamLT = fsamLT + (fsam * vol * (SAMPLE_PAN_RIGHT - fpan)) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)
                    fsamRT = fsamRT + (fsam * vol * fpan) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)

                    ' Move to the next sample position based on the pitch
                    Channel(chan).samplePosition = fpos + Channel(chan).pitch
                End If
            End If
        Next

        ' Man! I was probably more drunk than I thought and made such a simple thing so complicated earlier
        fsam = Song.volume / (256 * SONG_VOLUME_MAX)
        fsamLT = fsamLT * fsam
        fsamRT = fsamRT * fsam

        ' Clip samples to QB64 range
        If fsamLT < -1 Then fsamLT = -1
        If fsamLT > 1 Then fsamLT = 1
        If fsamRT < -1 Then fsamRT = -1
        If fsamRT > 1 Then fsamRT = 1

        ' Feed the sample to the QB64 sound pipe
        SndRaw fsamLT, fsamRT, Song.qb64SoundPipe
    Next
End Sub


' This gives us the sample pitch based on the period
Function GetPitchFromPeriod! (period As Integer)
    GetPitchFromPeriod = GetPitchFromFrequency(FrequencyTable(period))
End Function


' This gives us the sample pitch based on the period
Function GetPitchFromFrequency! (freq As Unsigned Integer)
    GetPitchFromFrequency = AMIGA_CONSTANT / (freq * Song.mixerRate)
End Function


Sub DoPortamento (chan As Unsigned Byte)
    If Channel(chan).frequency < Channel(chan).portamentoTo Then
        Channel(chan).frequency = Channel(chan).frequency + Channel(chan).portamentoSpeed
        If Channel(chan).frequency > Channel(chan).portamentoTo Then Channel(chan).frequency = Channel(chan).portamentoTo
    ElseIf Channel(chan).frequency > Channel(chan).portamentoTo Then
        Channel(chan).frequency = Channel(chan).frequency - Channel(chan).portamentoSpeed
        If Channel(chan).frequency < Channel(chan).portamentoTo Then Channel(chan).frequency = Channel(chan).portamentoTo
    End If

    Channel(chan).pitch = GetPitchFromFrequency(Channel(chan).frequency)
End Sub


Sub DoVolumeSlide (chan As Unsigned Byte, x As Unsigned Byte, y As Unsigned Byte)
    Channel(chan).volume = Channel(chan).volume + x - y
    If Channel(chan).volume < 0 Then Channel(chan).volume = 0
    If Channel(chan).volume > SAMPLE_VOLUME_MAX Then Channel(chan).volume = SAMPLE_VOLUME_MAX
End Sub


Sub DoVibrato (chan As Unsigned Byte)
    Dim delta As Unsigned Integer
    Dim temp As Unsigned Byte

    temp = Channel(chan).vibratoPosition And 31

    Select Case Channel(chan).waveControl And 3
        Case 0
            delta = SineTable(temp)

        Case 1
            temp = SHL(temp, 3)
            If Channel(chan).vibratoPosition < 0 Then temp = 255 - temp
            delta = temp

        Case 2
            delta = 255

        Case 3
            delta = SineTable(temp)
    End Select

    delta = delta * Channel(chan).vibratoDepth
    delta = SHR(delta, 7)

    If Channel(chan).vibratoPosition >= 0 Then
        Channel(chan).pitch = GetPitchFromFrequency(Channel(chan).frequency + delta)
    Else
        Channel(chan).pitch = GetPitchFromFrequency(Channel(chan).frequency - delta)
    End If

    Channel(chan).vibratoPosition = Channel(chan).vibratoPosition + Channel(chan).vibratoSpeed
    If Channel(chan).vibratoPosition > 31 Then Channel(chan).vibratoPosition = Channel(chan).vibratoPosition - 64
End Sub
'-----------------------------------------------------------------------------------------------------

