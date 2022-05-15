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
Const FALSE` = 0`, TRUE` = Not FALSE
Const NULL~` = 0~`
Const NULLSTRING$ = ""

Const AMIGA_CONSTANT! = 14317056!
Const PATTERN_ROW_MAX~%% = 63~%% ' Max row number in a pattern
Const NOTE_NONE = 132 ' Note will be set to this when there is nothing
Const NOTE_KEY_OFF = 133
Const NOTE_NO_VOLUME = 255 ' When a note has no volume, then it will be set to this
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
Type NoteType
    note As Unsigned Byte ' Contains info on 1 note
    sample As Unsigned Byte ' Sample number to play
    volume As Unsigned Byte ' Volume value. Not used for MODs. 255 = no volume
    effect As Unsigned Byte ' Effect number
    operand As Unsigned Byte ' Effect parameters
End Type

Type SampleType
    sampleName As String * 22 ' Sample name or message
    length As Long ' Sample length in bytes
    c2SPD As Unsigned Integer ' Sample finetune is converted to c2spd
    volume As Unsigned Byte ' Volume: 0 - 64
    loopStart As Long ' Loop start in bytes
    loopLength As Long ' Loop length in bytes
    loopEnd As Long ' Loop end in bytes
End Type

Type ChannelType
    sample As Unsigned Byte ' Sample number to be mixed
    volume As Integer ' Channel volume. This is a signed int because we need -ve values & to clip properly
    panningPosition As Single ' Position 0 is leftmost ... 255 is rightmost (fp32)
    pitch As Single ' Sample pitch. The mixer code uses this to step through the sample correctly (fp32)
    samplePosition As Single ' Where are we in the sample buffer (fp32)
    isPlaying As Byte ' This is set to false once the mixer is done with the sample
    frequency As Unsigned Integer ' This is the period of the playing sample used by various effects
    note As Unsigned Byte ' Last note set in channel
    period As Unsigned Integer ' Last period set in channel
    patternLoopRow As Integer ' This (signed) is the beginning of the loop in the pattern for effect E6x
    patternLoopRowCounter As Unsigned Byte ' This is a loop counter for effect E6x
    portamentoTo As Unsigned Integer ' Frequency to porta to value for E3x
    portamentoSpeed As Unsigned Byte ' Porta speed for E3x
    vibratoPosition As Byte ' Vibrato position in the sine table for E4x (signed)
    vibratoSpeed As Unsigned Byte ' Vibrato speed
    vibratoDepth As Unsigned Byte ' Vibrato depth
    tremoloPosition As Byte ' Tremolo position in the sine table (signed)
    tremoloSpeed As Unsigned Byte ' Tremolo speed
    tremoloDepth As Unsigned Byte ' Tremolo depth
    waveControl As Unsigned Byte ' Waveform type for vibrato and tremolo (4 bits each)
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
ReDim Shared Pattern(0 To 0, 0 To 0, 0 To 0) As NoteType ' Pattern data strored as (pattern, row, channel)
ReDim Shared Sample(1 To 1) As SampleType ' Sample info array. One based because sample 0 means nothing (well something :) in the pattern data
ReDim Shared SampleData(1 To 1) As String ' Sample data array. Again one based for same reason above
ReDim Shared Channel(0 To 0) As ChannelType ' Channel info array
ReDim Shared PeriodTable(0 To 0) As Unsigned Integer ' Amiga period table
ReDim Shared SineTable(0 To 0) As Unsigned Byte ' Sine table used for effects
ReDim Shared NoteTable(0 To 0) As String * 2 ' This is for the UI. TODO: Move this out to a different file
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM DATA
'-----------------------------------------------------------------------------------------------------
' Amiga period table data for 11 octaves
PeriodTab:
Data 134
Data 27392,25856,24384,23040,21696,20480,19328,18240,17216,16256,15360,14496
Data 13696,12928,12192,11520,10848,10240,9664,9120,8608,8128,7680,7248
Data 6848,6464,6096,5760,5424,5120,4832,4560,4304,4064,3840,3624
Data 3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1812
Data 1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906
Data 856,808,762,720,678,640,604,570,538,508,480,453
Data 428,404,381,360,339,320,302,285,269,254,240,226
Data 214,202,190,180,170,160,151,143,135,127,120,113
Data 107,101,95,90,85,80,75,71,67,63,60,56
Data 53,50,47,45,42,40,37,35,33,31,30,28
Data 26,25,23,22,21,20,18,17,16,15,15,14
Data 0,0
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
Data 12
Data "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - This is just test code. We have no proper UI yet
'-----------------------------------------------------------------------------------------------------
Title "QB64 MOD Player"

Dim As String modFileName
If CommandCount > 0 Then modFileName = Command$ Else modFileName = "mods/rez-monday.mod"

If LoadMODFile(modFileName) Then
    Print "Loaded MOD file!"
Else
    Print "Failed to load file!"
    End
End If

'PrintMODInfo

Title "QB64 MOD Player - " + modFileName
StartMODPlayer
'Song.isLooping = TRUE

Width 12 + (Song.channels * 18), 40

Dim nChan As Unsigned Byte, k As String, n As Unsigned Byte
Do
    Color 15
    Print Using "### ### ##:"; Song.orderPosition; Order(Song.orderPosition); Song.patternRow;
    For nChan = 0 To Song.channels - 1
        Color 14
        Print Using " (##)"; nChan + 1;
        Color 13
        Print Using " ## "; Channel(nChan).sample;
        n = Pattern(Order(Song.orderPosition), Song.patternRow, nChan).note
        Color 10
        If n = NOTE_NONE Then
            Print "--- ";
        ElseIf n = NOTE_KEY_OFF Then
            Print "^^^ ";
        Else
            Print Using "&# "; NoteTable(n Mod 12); n \ 12;
        End If
        Color 11
        Print Right$(" " + Hex$(Pattern(Order(Song.orderPosition), Song.patternRow, nChan).effect), 2); " ";
        Print Right$(" " + Hex$(Pattern(Order(Song.orderPosition), Song.patternRow, nChan).operand), 2);
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
            Song.patternRow = 0

        Case ".", ">"
            Song.orderPosition = Song.orderPosition + 1
            If Song.orderPosition >= Song.orders Then Song.orderPosition = 0
            Song.patternRow = 0
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
        Print "Volume:"; Sample(i).volume, "C2SPD:"; Sample(i).c2SPD
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
        Sample(i).c2SPD = GetC2SPD(Asc(Input$(1, fileHandle))) ' Convert finetune to c2spd

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
    ReDim Pattern(0 To Song.highestPattern, 0 To PATTERN_ROW_MAX, 0 To Song.channels - 1) As NoteType
    Dim c As Unsigned Integer

    ' Skip past the 4 byte marker if this is a 31 sample mod
    If Song.samples = 31 Then Seek fileHandle, Loc(1) + 5

    ' Load the frequency table
    Restore PeriodTab
    Read c ' Read the size
    ReDim PeriodTable(0 To c - 1) As Unsigned Integer ' Allocate size elements
    ' Now read size values
    For i = 0 To c - 1
        Read PeriodTable(i)
    Next

    Dim As Unsigned Byte byte3, byte4
    Dim As Unsigned Integer a, b, period

    ' Load the patterns
    ' +-------------------------------------+
    ' | Byte 0    Byte 1   Byte 2   Byte 3  |
    ' +-------------------------------------+
    ' |aaaaBBBB CCCCCCCCC DDDDeeee FFFFFFFFF|
    ' +-------------------------------------+
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
                Pattern(i, a, b).note = NOTE_NONE
                For c = 0 To 107
                    If period >= PeriodTable(c + 24) Then
                        Pattern(i, a, b).note = c
                        Exit For
                    End If
                Next

                Pattern(i, a, b).volume = NOTE_NO_VOLUME
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
    ReDim NoteTable(0 To s - 1) As String * 2
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
    ' Check conditions for which we should just exit and not process anything
    If Song.isPaused Or Song.orderPosition >= Song.orders Then Exit Sub

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

                ' Check if we need to loop or stop
                If Song.orderPosition >= Song.orders Then
                    If Song.isLooping Then
                        Song.orderPosition = Song.endJumpOrder
                        Song.speed = SONG_SPEED_DEFAULT
                        Song.tick = Song.speed
                    Else
                        Song.isPlaying = FALSE
                    End If
                End If
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
    Dim As Unsigned Byte nChannel, nNote, nSample, nVolume, nEffect, nOperand, nOpX, nOpY
    Dim nPatternRow As Integer
    Dim As Bit jumpEffectFlag, breakEffectFlag ' This is set to true when a pattern jump effect and pattern break effect are triggered

    ' We need this so that we don't start accessing -1 elements in the pattern array when there is a pattern jump
    nPatternRow = Song.patternRow

    ' Process all channels
    For nChannel = 0 To Song.channels - 1
        nNote = Pattern(Song.tickPattern, nPatternRow, nChannel).note
        nSample = Pattern(Song.tickPattern, nPatternRow, nChannel).sample
        nVolume = Pattern(Song.tickPattern, nPatternRow, nChannel).volume
        nEffect = Pattern(Song.tickPattern, nPatternRow, nChannel).effect
        nOperand = Pattern(Song.tickPattern, nPatternRow, nChannel).operand
        nOpX = SHR(nOperand, 4)
        nOpY = nOperand And &HF

        ' Set volume. We never play if sample number is zero. Our sample array is 1 based
        ' ONLY RESET VOLUME IF THERE IS A SAMPLE NUMBER
        If nSample > 0 Then
            Channel(nChannel).sample = nSample
            ' Don't get the volume if delay note, set it when the delay note actually happens
            If Not (nEffect = &HE And nOpX = &HD) Then
                Channel(nChannel).volume = Sample(nSample).volume
            End If
        End If


        If nNote < NOTE_NONE And Channel(nChannel).sample > 0 Then
            Channel(nChannel).period = 8363 * PeriodTable(nNote) / Sample(Channel(nChannel).sample).c2SPD
            Channel(nChannel).note = nNote

            ' Retrigger tremolo and vibrato waveforms
            If Channel(nChannel).waveControl And &HF < 4 Then Channel(nChannel).vibratoPosition = 0
            If SHR(Channel(nChannel).waveControl, 4) < 4 Then Channel(nChannel).tremoloPosition = 0

            ' ONLY RESET FREQUENCY IF THERE IS A NOTE VALUE AND PORTA NOT SET
            If nEffect <> &H3 And nEffect <> &H5 Then ' TODO: And note delay?
                Channel(nChannel).frequency = Channel(nChannel).period
                Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).frequency)
                Channel(nChannel).isPlaying = TRUE
                Channel(nChannel).samplePosition = 0
            End If
        End If

        If nVolume <= SAMPLE_VOLUME_MAX Then Channel(nChannel).volume = nVolume
        If nNote = NOTE_KEY_OFF Then Channel(nChannel).volume = 0

        ' Process tick 0 effects
        Select Case nEffect
            Case &H3 ' 3: Porta To Note
                If nOperand > 0 Then Channel(nChannel).portamentoSpeed = nOperand
                If nNote >= 0 Then Channel(nChannel).portamentoTo = Channel(nChannel).period

            Case &H5 ' 5: Tone Portamento + Volume Slide
                If nNote >= 0 Then Channel(nChannel).portamentoTo = Channel(nChannel).period

            Case &H4 ' 4: Vibrato
                If nOpX > 0 Then Channel(nChannel).vibratoSpeed = nOpX
                If nOpY > 0 Then Channel(nChannel).vibratoDepth = nOpY

            Case &H7 ' 7: Tremolo
                If nOpX > 0 Then Channel(nChannel).tremoloSpeed = nOpX
                If nOpY > 0 Then Channel(nChannel).tremoloDepth = nOpY

            Case &H8 ' 8: Set Panning Position
                ' Don't care about DMP panning BS. We are doing this Fasttracker style
                Channel(nChannel).panningPosition = nOperand

            Case &H9 ' 9: Set Sample Offset
                If nOperand > 0 Then Channel(nChannel).samplePosition = nOperand * 256

            Case &HB ' 11: Jump To Pattern
                Song.orderPosition = nOperand
                If Song.orderPosition >= Song.orders Then Song.orderPosition = Song.endJumpOrder
                Song.patternRow = -1 ' This will increment right after & we will start at 0
                jumpEffectFlag = TRUE

            Case &HC ' 12: Set Volume
                Channel(nChannel).volume = nOperand ' Operand can never be -ve cause it is unsigned. So we only clip for max below
                If Channel(nChannel).volume > SAMPLE_VOLUME_MAX Then Channel(nChannel).volume = SAMPLE_VOLUME_MAX

            Case &HD ' 13: Pattern Break
                Song.patternRow = (nOpX * 10) + nOpY - 1
                If Song.patternRow > PATTERN_ROW_MAX Then Song.patternRow = -1
                If Not breakEffectFlag And Not jumpEffectFlag Then
                    Song.orderPosition = Song.orderPosition + 1
                    If Song.orderPosition >= Song.orders Then Song.orderPosition = Song.endJumpOrder
                End If
                breakEffectFlag = TRUE

            Case &HE ' 14: Extended Effects
                Select Case nOpX
                    Case &H0 ' 0: Set Filter
                        Song.useHQMixer = nOpY <> 0

                    Case &H1 ' 1: Fine Portamento Up
                        Channel(nChannel).frequency = Channel(nChannel).frequency - nOpY * 4
                        Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).frequency)

                    Case &H2 ' 2: Fine Portamento Down
                        Channel(nChannel).frequency = Channel(nChannel).frequency + nOpY * 4
                        Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).frequency)

                    Case &H3 ' 3: Glissando Control
                        Title "Extended effect not implemented: " + Str$(nEffect) + "-" + Str$(nOpX)

                    Case &H4 ' 4: Set Vibrato Waveform
                        Channel(nChannel).waveControl = Channel(nChannel).waveControl And &HF0
                        Channel(nChannel).waveControl = Channel(nChannel).waveControl Or nOpY

                    Case &H5 ' 5: Set Finetune
                        Sample(Channel(nChannel).sample).c2SPD = GetC2SPD(nOpY)

                    Case &H6 ' 6: Pattern Loop
                        If nOpY = 0 Then
                            Channel(nChannel).patternLoopRow = nPatternRow
                        Else
                            If Channel(nChannel).patternLoopRowCounter = 0 Then
                                Channel(nChannel).patternLoopRowCounter = nOpY
                            Else
                                Channel(nChannel).patternLoopRowCounter = Channel(nChannel).patternLoopRowCounter - 1
                            End If
                            If Channel(nChannel).patternLoopRowCounter > 0 Then Song.patternRow = Channel(nChannel).patternLoopRow - 1
                        End If

                    Case &H7 ' 7: Set Tremolo WaveForm
                        Channel(nChannel).waveControl = Channel(nChannel).waveControl And &HF
                        Channel(nChannel).waveControl = Channel(nChannel).waveControl Or SHL(nOpY, 4)

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

                    Case &HD ' 13: Delay Note
                        Channel(nChannel).isPlaying = FALSE

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
    Dim As Unsigned Byte nChannel, nEffect, nOperand, nOpX, nOpY

    ' Process all channels
    For nChannel = 0 To Song.channels - 1
        ' Only process if we have a period set
        If Not Channel(nChannel).frequency = 0 Then
            ' We are not processing a new row but tick 1+ effects
            ' So we pick these using tickPattern and tickPatternRow
            nEffect = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).effect
            nOperand = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).operand
            nOpX = SHR(nOperand, 4)
            nOpY = nOperand And &HF

            Select Case nEffect
                Case &H0 ' 0: Arpeggio
                    If (nOperand > 0) Then
                        Select Case (Song.tick + 1) Mod 3 ' Song.tick + 1 here to make it sound like FT2. Dunno why it works yet :(
                            Case 0
                                Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).frequency)
                            Case 1
                                Channel(nChannel).pitch = GetPitchFromPeriod(PeriodTable(Channel(nChannel).note + nOpX))
                            Case 2
                                Channel(nChannel).pitch = GetPitchFromPeriod(PeriodTable(Channel(nChannel).note + nOpY))
                        End Select
                    End If

                Case &H1 ' 1: Porta Up
                    Channel(nChannel).frequency = Channel(nChannel).frequency - nOperand * 4
                    Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).frequency)
                    If Channel(nChannel).frequency < 56 Then Channel(nChannel).frequency = 56

                Case &H2 ' 2: Porta Down
                    Channel(nChannel).frequency = Channel(nChannel).frequency + nOperand * 4
                    Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).frequency)

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
                    DoTremolo nChannel

                Case &HA ' 10: Volume Slide
                    DoVolumeSlide nChannel, nOpX, nOpY

                Case &HE ' 14: Extended Effects
                    Select Case nOpX
                        Case &H9 ' 9: Retrigger Note
                            If nOpY <> 0 Then
                                If Song.tick Mod nOpY = 0 Then
                                    Channel(nChannel).isPlaying = TRUE
                                    Channel(nChannel).samplePosition = 0
                                End If
                            End If

                        Case &HC ' 12: Cut Note
                            If Song.tick = nOpY Then Channel(nChannel).volume = 0

                        Case &HD ' 13: Delay Note
                            If Song.tick = nOpY Then
                                If Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).sample > 0 Then
                                    Channel(nChannel).volume = Sample(Channel(nChannel).sample).volume
                                End If
                                If Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).volume <= SAMPLE_VOLUME_MAX Then
                                    Channel(nChannel).volume = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).volume
                                End If
                                Channel(nChannel).pitch = GetPitchFromPeriod(Channel(nChannel).frequency)
                                Channel(nChannel).isPlaying = TRUE
                                Channel(nChannel).samplePosition = 0
                            End If
                    End Select
            End Select
        End If
    Next
End Sub


' Mixes and queues a frame/tick worth of samples
' All mixing calculations are done using floating-point math (it's 2022 :)
Sub MixMODFrame
    Dim As Unsigned Long i, npos
    Dim As Unsigned Byte chan, nSample, vol
    Dim As Single fpan, fpos, fsam, fsamLT, fsamRT
    Dim As Byte bsam1, bsam2
    Dim As Bit isLooping

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
                        fpos = Sample(nSample).loopStart
                    End If
                Else
                    ' For non-looping sample simply set the isplayed flag as false if we reached the end
                    If fpos >= Sample(nSample).length Then
                        Channel(chan).isPlaying = FALSE
                    End If
                End If

                ' We don't want anything below 0
                If fpos < 0 Then fpos = 0

                ' Only mix the sample if we have not completed or are looping
                If Channel(chan).isPlaying Or isLooping Then
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

        ' Feed the samples to the QB64 sound pipe
        SndRaw fsamLT, fsamRT, Song.qb64SoundPipe
    Next
End Sub


' Carry out a tone portamento to a certain note
Sub DoPortamento (chan As Unsigned Byte)
    If Channel(chan).frequency < Channel(chan).portamentoTo Then
        Channel(chan).frequency = Channel(chan).frequency + Channel(chan).portamentoSpeed * 4
        If Channel(chan).frequency > Channel(chan).portamentoTo Then Channel(chan).frequency = Channel(chan).portamentoTo
    ElseIf Channel(chan).frequency > Channel(chan).portamentoTo Then
        Channel(chan).frequency = Channel(chan).frequency - Channel(chan).portamentoSpeed * 4
        If Channel(chan).frequency < Channel(chan).portamentoTo Then Channel(chan).frequency = Channel(chan).portamentoTo
    End If

    Channel(chan).pitch = GetPitchFromPeriod(Channel(chan).frequency)
End Sub


' Carry out a volume slide using +x -y
Sub DoVolumeSlide (chan As Unsigned Byte, x As Unsigned Byte, y As Unsigned Byte)
    Channel(chan).volume = Channel(chan).volume + x - y
    If Channel(chan).volume < 0 Then Channel(chan).volume = 0
    If Channel(chan).volume > SAMPLE_VOLUME_MAX Then Channel(chan).volume = SAMPLE_VOLUME_MAX
End Sub


' Carry out a vibrato at a certain depth and speed
Sub DoVibrato (chan As Unsigned Byte)
    Dim delta As Unsigned Integer
    Dim temp As Unsigned Byte

    temp = Channel(chan).vibratoPosition And 31

    Select Case Channel(chan).waveControl And 3
        Case 0 ' Sine
            delta = SineTable(temp)

        Case 1 ' Saw down
            temp = SHL(temp, 3)
            If Channel(chan).vibratoPosition < 0 Then temp = 255 - temp
            delta = temp

        Case 2 ' Square
            delta = 255

        Case 3 ' TODO: Random?
            delta = SineTable(temp)
    End Select

    delta = SHR(delta * Channel(chan).vibratoDepth, 5) ' SHR 7 SHL 2

    If Channel(chan).vibratoPosition >= 0 Then
        Channel(chan).pitch = GetPitchFromPeriod(Channel(chan).frequency + delta)
    Else
        Channel(chan).pitch = GetPitchFromPeriod(Channel(chan).frequency - delta)
    End If

    Channel(chan).vibratoPosition = Channel(chan).vibratoPosition + Channel(chan).vibratoSpeed
    If Channel(chan).vibratoPosition > 31 Then Channel(chan).vibratoPosition = Channel(chan).vibratoPosition - 64
End Sub


' Carry out a tremolo at a certain depth and speed
Sub DoTremolo (chan As Unsigned Byte)
    Dim delta As Unsigned Integer
    Dim temp As Unsigned Byte

    temp = Channel(chan).tremoloPosition And 31

    Select Case SHR(Channel(chan).waveControl, 4) And 3
        Case 0 ' Sine
            delta = SineTable(temp)

        Case 1 ' Saw down
            temp = SHL(temp, 3)
            If Channel(chan).tremoloPosition < 0 Then temp = 255 - temp
            delta = temp

        Case 2 ' Square
            delta = 255

        Case 3 ' TODO: Random?
            delta = SineTable(temp)
    End Select

    delta = SHR(delta * Channel(chan).tremoloDepth, 6)

    If Channel(chan).tremoloPosition >= 0 Then
        If Channel(chan).volume + delta > SAMPLE_VOLUME_MAX Then delta = SAMPLE_VOLUME_MAX - Channel(chan).volume
        Channel(chan).volume = Channel(chan).volume + delta
    Else
        If Channel(chan).volume - delta < 0 Then delta = Channel(chan).volume
        Channel(chan).volume = Channel(chan).volume - delta
    End If

    Channel(chan).tremoloPosition = Channel(chan).tremoloPosition + Channel(chan).tremoloSpeed
    If Channel(chan).tremoloPosition > 31 Then Channel(chan).tremoloPosition = Channel(chan).tremoloPosition - 64
End Sub


' This gives us the sample pitch based on the period for mixing
Function GetPitchFromPeriod! (period As Unsigned Integer)
    GetPitchFromPeriod = AMIGA_CONSTANT / (period * Song.mixerRate)
End Function


' Return C2 speed for a finetune
Function GetC2SPD~% (ft As Unsigned Byte)
    Select Case ft
        Case 0
            GetC2SPD = 8363
        Case 1
            GetC2SPD = 8413
        Case 2
            GetC2SPD = 8463
        Case 3
            GetC2SPD = 8529
        Case 4
            GetC2SPD = 8581
        Case 5
            GetC2SPD = 8651
        Case 6
            GetC2SPD = 8723
        Case 7
            GetC2SPD = 8757
        Case 8
            GetC2SPD = 7895
        Case 9
            GetC2SPD = 7941
        Case 10
            GetC2SPD = 7985
        Case 11
            GetC2SPD = 8046
        Case 12
            GetC2SPD = 8107
        Case 13
            GetC2SPD = 8169
        Case 14
            GetC2SPD = 8232
        Case 15
            GetC2SPD = 8280
        Case Else
            GetC2SPD = 8363
    End Select
End Function
'-----------------------------------------------------------------------------------------------------

