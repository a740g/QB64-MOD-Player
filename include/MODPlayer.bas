'---------------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'./MODPlayer.bi'
'---------------------------------------------------------------------------------------------------------

$If MODPLAYER_BAS = UNDEFINED Then
    $Let MODPLAYER_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-----------------------------------------------------------------------------------------------------
    '$Debug
    'If LoadMODFile("C:\Users\samue\source\repos\a740g\QB64-MOD-Player\mods\dope.mod") Then
    '    EnableHQMixer TRUE
    '    StartMODPlayer
    '    Do
    '        UpdateMODPlayer
    '        Locate 1, 1
    '        Print Using "Order: ### / ###    Pattern: ### / ###    Row: ## / 64    BPM: ###    Speed: ###"; Song.orderPosition + 1; Song.orders; Order(Song.orderPosition) + 1; Song.highestPattern + 1; Song.patternRow + 1; Song.bpm; Song.speed;
    '        Limit 60
    '    Loop While KeyHit <> 27 And Song.isPlaying
    '    StopMODPlayer
    'End If
    'End
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------
    ' Loads the MOD file into memory and prepares all required gobals
    Function LoadMODFile%% (sFileName As String)
        Shared Song As SongType
        Shared Order() As Unsigned Byte
        Shared Pattern() As NoteType
        Shared Sample() As SampleType
        Shared PeriodTable() As Unsigned Integer

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
                        If Asc(Song.songName, i) < Asc(" ") And Asc(Song.songName, i) <> NULL Then
                            ' This is probably not a 15 sample MOD file
                            Close fileHandle
                            Exit Function
                        End If
                    Next
                    Song.channels = 4
                    Song.samples = 15
                    Song.subtype = "MODF" ' Change subtype to reflect 15 (Fh) sample mod, otherwise it will contain garbage
                End If
        End Select

        ' Sanity check
        If (Song.samples = 0 Or Song.channels = 0) Then
            Close fileHandle
            Exit Function
        End If

        ' Initialize the sample manager
        ReDim Sample(0 To Song.samples - 1) As SampleType
        Dim As Unsigned Byte byte1, byte2

        ' Load the sample headers
        For i = 0 To Song.samples - 1
            ' Read the sample name
            Get fileHandle, , Sample(i).sampleName

            ' Read sample length
            Get fileHandle, , byte1
            Get fileHandle, , byte2
            Sample(i).length = (byte1 * &H100 + byte2) * 2
            If Sample(i).length = 2 Then Sample(i).length = 0 ' Sanity check

            ' Read finetune
            Sample(i).c2Spd = GetC2Spd(Asc(Input$(1, fileHandle))) ' Convert finetune to c2spd

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

        ' Skip past the 4 byte marker if this is a 31 sample mod
        If Song.samples = 31 Then Seek fileHandle, Loc(1) + 5

        ' Load the period table
        Restore PeriodTab
        Read Song.periodTableMax ' Read the size
        Song.periodTableMax = Song.periodTableMax - 1 ' Change to ubound
        ReDim PeriodTable(0 To Song.periodTableMax) As Unsigned Integer ' Allocate size elements
        ' Now read size values
        For i = 0 To Song.periodTableMax
            Read PeriodTable(i)
        Next

        Dim As Unsigned Byte byte3, byte4
        Dim As Unsigned Integer a, b, c, period

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

                    Pattern(i, a, b).sample = (byte1 And &HF0) Or ShR(byte3, 4)

                    period = ShL(byte1 And &HF, 8) Or byte2

                    ' Do the look up in the table against what is read in and store note
                    Pattern(i, a, b).note = NOTE_NONE
                    For c = 0 To 107
                        If period >= PeriodTable(c + 24) Then
                            Pattern(i, a, b).note = c
                            Exit For
                        End If
                    Next

                    Pattern(i, a, b).volume = NOTE_NO_VOLUME ' MODs don't have any volume field in the pattern
                    Pattern(i, a, b).effect = byte3 And &HF
                    Pattern(i, a, b).operand = byte4

                    ' Some sanity check
                    If Pattern(i, a, b).sample > Song.samples Then Pattern(i, a, b).sample = 0 ' Sample 0 means no sample. So valid sample are 1-15/31
                Next
            Next
        Next

        ' Initialize the softsynth sample manager
        InitializeSampleManager Song.samples

        ' Load the samples
        For i = 0 To Song.samples - 1
            ' Load sample size bytes of data and send it to our softsynth sample manager
            LoadSample i, Input$(Sample(i).length, fileHandle), Sample(i).loopLength > 0, Sample(i).loopStart, Sample(i).loopEnd
        Next

        Close fileHandle

        LoadMODFile = TRUE

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
    End Function


    ' Initializes the audio mixer, prepares eveything else for playback and kick starts the timer and hence song playback
    Sub StartMODPlayer
        Shared Song As SongType
        Shared Channel() As ChannelType
        Shared SineTable() As Unsigned Byte
        Shared InvertLoopSpeedTable() As Unsigned Byte
        Shared SoftSynth As SoftSynthType

        Dim As Unsigned Integer i, s

        ' Load the sine table
        Restore SineTab
        Read s
        ReDim SineTable(0 To s - 1) As Unsigned Byte
        For i = 0 To s - 1
            Read SineTable(i)
        Next

        ' Load the invert loop table
        Restore ILSpdTab
        Read s
        ReDim InvertLoopSpeedTable(0 To s - 1) As Unsigned Byte
        For i = 0 To s - 1
            Read InvertLoopSpeedTable(i)
        Next

        ' Initialize the softsynth sample mixer
        InitializeMixer Song.channels

        ' Initialize some important stuff
        Song.tempoTimerValue = (SoftSynth.mixerRate * SONG_BPM_DEFAULT) \ 50
        Song.orderPosition = 0
        Song.patternRow = 0
        Song.speed = SONG_SPEED_DEFAULT
        Song.tick = Song.speed
        Song.isPaused = FALSE

        ' Set default BPM
        SetBPM SONG_BPM_DEFAULT

        ' Setup the channel array
        ReDim Channel(0 To Song.channels - 1) As ChannelType

        ' Setup panning for all channels per AMIGA PAULA's panning setup - LRRLLRRL...
        ' If we have < 4 channels, then 0 & 1 are set as left & right
        ' If we have > 4 channels all prefect 4 groups are set as LRRL
        ' Any channels that are left out are simply centered by the SoftSynth
        ' We will also not do hard left or hard right. ~25% of sound from each channel is blended with the other
        If Song.channels > 1 And Song.channels < 4 Then
            ' Just setup channels 0 and 1
            ' If we have a 3rd channel it will be handle by the SoftSynth
            SetVoicePanning 0, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
            SetVoicePanning 1, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
        Else
            For i = 0 To Song.channels - 1 - (Song.channels Mod 4) Step 4
                SetVoicePanning i + 0, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 1, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 2, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 3, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
            Next
        End If

        Song.isPlaying = TRUE

        ' Sine table data for tremolo & vibrato
        SineTab:
        Data 32
        Data 0,24,49,74,97,120,141,161,180,197,212,224,235,244,250,253,255,253,250,244,235,224,212,197,180,161,141,120,97,74,49,24
        Data NaN

        ' Invert loop speed table data for EFx
        ILSpdTab:
        Data 16
        Data 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128
        Data NaN
    End Sub


    ' Frees all allocated resources, stops the timer and hence song playback
    Sub StopMODPlayer
        Shared Song As SongType

        ' Tell softsynth we are done
        FinalizeMixer

        Song.isPlaying = FALSE
    End Sub


    ' This should be called at regular intervals to run the mod player and mixer code
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    Sub UpdateMODPlayer
        Shared Song As SongType
        Shared Order() As Unsigned Byte

        ' Check conditions for which we should just exit and not process anything
        If Song.orderPosition >= Song.orders Then Exit Sub

        ' Set the playing flag to true
        Song.isPlaying = TRUE

        ' If song is paused or we already have enough samples to play then exit
        If Song.isPaused Or Not NeedsSoundRefill Then Exit Sub

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
        UpdateMixer Song.samplesPerTick

        ' Increment song tick on each update
        Song.tick = Song.tick + 1
    End Sub


    ' Updates a row of notes and play them out on tick 0
    Sub UpdateMODRow
        Shared Song As SongType
        Shared Pattern() As NoteType
        Shared Sample() As SampleType
        Shared Channel() As ChannelType
        Shared PeriodTable() As Unsigned Integer

        Dim As Unsigned Byte nChannel, nNote, nSample, nVolume, nEffect, nOperand, nOpX, nOpY
        ' The effect flags below are set to true when a pattern jump effect and pattern break effect are triggered
        Dim As Byte jumpEffectFlag, breakEffectFlag, noFrequency

        ' Set the active channel count to zero
        Song.activeChannels = 0

        ' Process all channels
        For nChannel = 0 To Song.channels - 1
            nNote = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).note
            nSample = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).sample
            nVolume = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).volume
            nEffect = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).effect
            nOperand = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).operand
            nOpX = ShR(nOperand, 4)
            nOpY = nOperand And &HF
            noFrequency = FALSE

            ' Set volume. We never play if sample number is zero. Our sample array is 1 based
            ' ONLY RESET VOLUME IF THERE IS A SAMPLE NUMBER
            If nSample > 0 Then
                Channel(nChannel).sample = nSample - 1
                ' Don't get the volume if delay note, set it when the delay note actually happens
                If Not (nEffect = &HE And nOpX = &HD) Then
                    Channel(nChannel).volume = Sample(Channel(nChannel).sample).volume
                End If
            End If

            If nNote < NOTE_NONE Then
                Channel(nChannel).lastPeriod = 8363 * PeriodTable(nNote) \ Sample(Channel(nChannel).sample).c2Spd
                Channel(nChannel).note = nNote
                Channel(nChannel).restart = TRUE
                Channel(nChannel).startPosition = 0
                Song.activeChannels = nChannel

                ' Retrigger tremolo and vibrato waveforms
                If Channel(nChannel).waveControl And &HF < 4 Then Channel(nChannel).vibratoPosition = 0
                If ShR(Channel(nChannel).waveControl, 4) < 4 Then Channel(nChannel).tremoloPosition = 0

                ' ONLY RESET FREQUENCY IF THERE IS A NOTE VALUE AND PORTA NOT SET
                If nEffect <> &H3 And nEffect <> &H5 Then
                    Channel(nChannel).period = Channel(nChannel).lastPeriod
                End If
            Else
                Channel(nChannel).restart = FALSE
            End If

            If nVolume <= SAMPLE_VOLUME_MAX Then Channel(nChannel).volume = nVolume
            If nNote = NOTE_KEY_OFF Then Channel(nChannel).volume = 0

            ' Process tick 0 effects
            Select Case nEffect
                Case &H3 ' 3: Porta To Note
                    If nOperand > 0 Then Channel(nChannel).portamentoSpeed = nOperand
                    Channel(nChannel).portamentoTo = Channel(nChannel).lastPeriod
                    Channel(nChannel).restart = FALSE

                Case &H5 ' 5: Tone Portamento + Volume Slide
                    Channel(nChannel).portamentoTo = Channel(nChannel).lastPeriod
                    Channel(nChannel).restart = FALSE

                Case &H4 ' 4: Vibrato
                    If nOpX > 0 Then Channel(nChannel).vibratoSpeed = nOpX
                    If nOpY > 0 Then Channel(nChannel).vibratoDepth = nOpY

                Case &H7 ' 7: Tremolo
                    If nOpX > 0 Then Channel(nChannel).tremoloSpeed = nOpX
                    If nOpY > 0 Then Channel(nChannel).tremoloDepth = nOpY

                Case &H8 ' 8: Set Panning Position
                    ' Don't care about DMP panning BS. We are doing this Fasttracker style
                    SetVoicePanning nChannel, nOperand

                Case &H9 ' 9: Set Sample Offset
                    If nOperand > 0 Then Channel(nChannel).startPosition = ShL(nOperand, 8)

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
                            EnableHQMixer nOpY

                        Case &H1 ' 1: Fine Portamento Up
                            Channel(nChannel).period = Channel(nChannel).period - ShL(nOpY, 2)

                        Case &H2 ' 2: Fine Portamento Down
                            Channel(nChannel).period = Channel(nChannel).period + ShL(nOpY, 2)

                        Case &H3 ' 3: Glissando Control
                            Channel(nChannel).useGlissando = (nOpY <> FALSE)

                        Case &H4 ' 4: Set Vibrato Waveform
                            Channel(nChannel).waveControl = Channel(nChannel).waveControl And &HF0
                            Channel(nChannel).waveControl = Channel(nChannel).waveControl Or nOpY

                        Case &H5 ' 5: Set Finetune
                            Sample(Channel(nChannel).sample).c2Spd = GetC2Spd(nOpY)

                        Case &H6 ' 6: Pattern Loop
                            If nOpY = 0 Then
                                Channel(nChannel).patternLoopRow = Song.tickPatternRow
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
                            Channel(nChannel).waveControl = Channel(nChannel).waveControl Or ShL(nOpY, 4)

                        Case &H8 ' 8: 16 position panning
                            If nOpY > 15 Then nOpY = 15
                            ' Why does this kind of stuff bother me so much. We could have just written "/ 17" XD
                            SetVoicePanning nChannel, nOpY * ((SAMPLE_PAN_RIGHT - SAMPLE_PAN_LEFT) / 15)

                        Case &HA ' 10: Fine Volume Slide Up
                            Channel(nChannel).volume = Channel(nChannel).volume + nOpY
                            If Channel(nChannel).volume > SAMPLE_VOLUME_MAX Then Channel(nChannel).volume = SAMPLE_VOLUME_MAX

                        Case &HB ' 11: Fine Volume Slide Down
                            Channel(nChannel).volume = Channel(nChannel).volume - nOpY
                            If Channel(nChannel).volume < 0 Then Channel(nChannel).volume = 0

                        Case &HD ' 13: Delay Note
                            Channel(nChannel).restart = FALSE
                            noFrequency = TRUE

                        Case &HE ' 14: Pattern Delay
                            Song.patternDelay = nOpY

                        Case &HF ' 15: Invert Loop
                            Channel(nChannel).invertLoopSpeed = nOpY
                    End Select

                Case &HF ' 15: Set Speed
                    If nOperand < 32 Then
                        Song.speed = nOperand
                    Else
                        SetBPM nOperand
                    End If
            End Select

            DoInvertLoop nChannel ' called every tick

            If Not noFrequency Then
                If nEffect <> 7 Then SetVoiceVolume nChannel, Channel(nChannel).volume
                If Channel(nChannel).period > 0 Then SetVoiceFrequency nChannel, GetFrequencyFromPeriod(Channel(nChannel).period)
            End If
        Next

        ' Now play all samples that needs to be played
        For nChannel = 0 To Song.activeChannels
            If Channel(nChannel).restart Then
                If Sample(Channel(nChannel).sample).loopLength > 0 Then
                    PlayVoice nChannel, Channel(nChannel).sample, Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, Sample(Channel(nChannel).sample).loopStart, Sample(Channel(nChannel).sample).loopEnd
                Else
                    PlayVoice nChannel, Channel(nChannel).sample, Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, Sample(Channel(nChannel).sample).length
                End If
            End If
        Next
    End Sub


    ' Updates any tick based effects after tick 0
    Sub UpdateMODTick
        Shared Song As SongType
        Shared Pattern() As NoteType
        Shared Sample() As SampleType
        Shared Channel() As ChannelType
        Shared PeriodTable() As Unsigned Integer

        Dim As Unsigned Byte nChannel, nVolume, nEffect, nOperand, nOpX, nOpY

        ' Process all channels
        For nChannel = 0 To Song.channels - 1
            ' Only process if we have a period set
            If Channel(nChannel).period > 0 Then
                ' We are not processing a new row but tick 1+ effects
                ' So we pick these using tickPattern and tickPatternRow
                nVolume = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).volume
                nEffect = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).effect
                nOperand = Pattern(Song.tickPattern, Song.tickPatternRow, nChannel).operand
                nOpX = ShR(nOperand, 4)
                nOpY = nOperand And &HF

                DoInvertLoop nChannel ' called every tick

                Select Case nEffect
                    Case &H0 ' 0: Arpeggio
                        If (nOperand > 0) Then
                            Select Case Song.tick Mod 3 'TODO: Check why 0, 1, 2 sounds wierd
                                Case 0
                                    SetVoiceFrequency nChannel, GetFrequencyFromPeriod(Channel(nChannel).period)
                                Case 1
                                    SetVoiceFrequency nChannel, GetFrequencyFromPeriod(PeriodTable(Channel(nChannel).note + nOpX))
                                Case 2
                                    SetVoiceFrequency nChannel, GetFrequencyFromPeriod(PeriodTable(Channel(nChannel).note + nOpY))
                            End Select
                        End If

                    Case &H1 ' 1: Porta Up
                        Channel(nChannel).period = Channel(nChannel).period - ShL(nOperand, 2)
                        SetVoiceFrequency nChannel, GetFrequencyFromPeriod(Channel(nChannel).period)
                        If Channel(nChannel).period < 56 Then Channel(nChannel).period = 56

                    Case &H2 ' 2: Porta Down
                        Channel(nChannel).period = Channel(nChannel).period + ShL(nOperand, 2)
                        SetVoiceFrequency nChannel, GetFrequencyFromPeriod(Channel(nChannel).period)

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
                                        If Sample(Channel(nChannel).sample).loopLength > 0 Then
                                            PlayVoice nChannel, Channel(nChannel).sample, Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, Sample(Channel(nChannel).sample).loopStart, Sample(Channel(nChannel).sample).loopEnd
                                        Else
                                            PlayVoice nChannel, Channel(nChannel).sample, Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, Sample(Channel(nChannel).sample).length
                                        End If
                                    End If
                                End If

                            Case &HC ' 12: Cut Note
                                If Song.tick = nOpY Then
                                    Channel(nChannel).volume = 0
                                    SetVoiceVolume nChannel, Channel(nChannel).volume
                                End If

                            Case &HD ' 13: Delay Note
                                If Song.tick = nOpY Then
                                    Channel(nChannel).volume = Sample(Channel(nChannel).sample).volume
                                    If nVolume <= SAMPLE_VOLUME_MAX Then Channel(nChannel).volume = nVolume
                                    SetVoiceFrequency nChannel, GetFrequencyFromPeriod(Channel(nChannel).period)
                                    SetVoiceVolume nChannel, Channel(nChannel).volume
                                    If Sample(Channel(nChannel).sample).loopLength > 0 Then
                                        PlayVoice nChannel, Channel(nChannel).sample, Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, Sample(Channel(nChannel).sample).loopStart, Sample(Channel(nChannel).sample).loopEnd
                                    Else
                                        PlayVoice nChannel, Channel(nChannel).sample, Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, Sample(Channel(nChannel).sample).length
                                    End If
                                End If
                        End Select
                End Select
            End If
        Next
    End Sub


    ' We always set the global BPM using this and never directly
    Sub SetBPM (nBPM As Unsigned Byte)
        Shared Song As SongType

        Song.bpm = nBPM

        ' Calculate the number of samples we have to mix per tick
        Song.samplesPerTick = Song.tempoTimerValue \ nBPM
    End Sub


    ' Binary search the period table to find the closest value
    ' I hope this is the right way to do glissando. Oh well...
    Function GetClosestPeriod& (target As Long)
        Shared Song As SongType
        Shared Channel() As ChannelType
        Shared PeriodTable() As Unsigned Integer

        Dim As Long startPos, endPos, midPos, leftVal, rightVal

        If target > 27392 Then
            GetClosestPeriod = target
            Exit Function
        ElseIf target < 14 Then
            GetClosestPeriod = target
            Exit Function
        End If

        startPos = 0
        endPos = Song.periodTableMax
        While startPos + 1 < endPos
            midPos = startPos + (endPos - startPos) \ 2
            If PeriodTable(midPos) <= target Then
                endPos = midPos
            Else
                startPos = midPos
            End If
        Wend

        rightVal = Abs(PeriodTable(startPos) - target)
        leftVal = Abs(PeriodTable(endPos) - target)

        If leftVal <= rightVal Then
            GetClosestPeriod = PeriodTable(endPos)
        Else
            GetClosestPeriod = PeriodTable(startPos)
        End If
    End Function


    ' Carry out a tone portamento to a certain note
    Sub DoPortamento (chan As Unsigned Byte)
        Shared Channel() As ChannelType

        ' Slide up/down and clamp to destination
        If Channel(chan).period < Channel(chan).portamentoTo Then
            Channel(chan).period = Channel(chan).period + ShL(Channel(chan).portamentoSpeed, 2)
            If Channel(chan).period > Channel(chan).portamentoTo Then Channel(chan).period = Channel(chan).portamentoTo
        ElseIf Channel(chan).period > Channel(chan).portamentoTo Then
            Channel(chan).period = Channel(chan).period - ShL(Channel(chan).portamentoSpeed, 2)
            If Channel(chan).period < Channel(chan).portamentoTo Then Channel(chan).period = Channel(chan).portamentoTo
        End If

        If Channel(chan).useGlissando Then
            SetVoiceFrequency chan, GetFrequencyFromPeriod(GetClosestPeriod(Channel(chan).period))
        Else
            SetVoiceFrequency chan, GetFrequencyFromPeriod(Channel(chan).period)
        End If
    End Sub


    ' Carry out a volume slide using +x -y
    Sub DoVolumeSlide (chan As Unsigned Byte, x As Unsigned Byte, y As Unsigned Byte)
        Shared Channel() As ChannelType

        Channel(chan).volume = Channel(chan).volume + x - y
        If Channel(chan).volume < 0 Then Channel(chan).volume = 0
        If Channel(chan).volume > SAMPLE_VOLUME_MAX Then Channel(chan).volume = SAMPLE_VOLUME_MAX

        SetVoiceVolume chan, Channel(chan).volume
    End Sub


    ' Carry out a vibrato at a certain depth and speed
    Sub DoVibrato (chan As Unsigned Byte)
        Shared Channel() As ChannelType
        Shared SineTable() As Unsigned Byte

        Dim delta As Unsigned Integer
        Dim temp As Unsigned Byte

        temp = Channel(chan).vibratoPosition And 31

        Select Case Channel(chan).waveControl And 3
            Case 0 ' Sine
                delta = SineTable(temp)

            Case 1 ' Saw down
                temp = ShL(temp, 3)
                If Channel(chan).vibratoPosition < 0 Then temp = 255 - temp
                delta = temp

            Case 2 ' Square
                delta = 255

            Case 3 ' Random
                delta = Rnd * 255
        End Select

        delta = ShL(ShR(delta * Channel(chan).vibratoDepth, 7), 2)

        If Channel(chan).vibratoPosition >= 0 Then
            SetVoiceFrequency chan, GetFrequencyFromPeriod(Channel(chan).period + delta)
        Else
            SetVoiceFrequency chan, GetFrequencyFromPeriod(Channel(chan).period - delta)
        End If

        Channel(chan).vibratoPosition = Channel(chan).vibratoPosition + Channel(chan).vibratoSpeed
        If Channel(chan).vibratoPosition > 31 Then Channel(chan).vibratoPosition = Channel(chan).vibratoPosition - 64
    End Sub


    ' Carry out a tremolo at a certain depth and speed
    Sub DoTremolo (chan As Unsigned Byte)
        Shared Channel() As ChannelType
        Shared SineTable() As Unsigned Byte

        Dim delta As Unsigned Integer
        Dim temp As Unsigned Byte

        temp = Channel(chan).tremoloPosition And 31

        Select Case ShR(Channel(chan).waveControl, 4) And 3
            Case 0 ' Sine
                delta = SineTable(temp)

            Case 1 ' Saw down
                temp = ShL(temp, 3)
                If Channel(chan).tremoloPosition < 0 Then temp = 255 - temp
                delta = temp

            Case 2 ' Square
                delta = 255

            Case 3 ' Random
                delta = Rnd * 255
        End Select

        delta = ShR(delta * Channel(chan).tremoloDepth, 6)

        If Channel(chan).tremoloPosition >= 0 Then
            If Channel(chan).volume + delta > SAMPLE_VOLUME_MAX Then delta = SAMPLE_VOLUME_MAX - Channel(chan).volume
            SetVoiceVolume chan, Channel(chan).volume + delta
        Else
            If Channel(chan).volume - delta < 0 Then delta = Channel(chan).volume
            SetVoiceVolume chan, Channel(chan).volume - delta
        End If

        Channel(chan).tremoloPosition = Channel(chan).tremoloPosition + Channel(chan).tremoloSpeed
        If Channel(chan).tremoloPosition > 31 Then Channel(chan).tremoloPosition = Channel(chan).tremoloPosition - 64
    End Sub


    ' Carry out an invert loop (EFx) effect
    ' This will trash the sample managed by the SoftSynth
    Sub DoInvertLoop (chan As Unsigned Byte)
        Shared Channel() As ChannelType
        Shared Sample() As SampleType
        Shared InvertLoopSpeedTable() As Unsigned Byte

        Channel(chan).invertLoopDelay = Channel(chan).invertLoopDelay + InvertLoopSpeedTable(Channel(chan).invertLoopSpeed)

        If Sample(Channel(chan).sample).loopLength > 0 And Channel(chan).invertLoopDelay >= 128 Then
            Channel(chan).invertLoopDelay = 0 ' reset delay
            If Channel(chan).invertLoopPosition < Sample(Channel(chan).sample).loopStart Then Channel(chan).invertLoopPosition = Sample(Channel(chan).sample).loopStart
            Channel(chan).invertLoopPosition = Channel(chan).invertLoopPosition + 1 ' increment position by 1
            If Channel(chan).invertLoopPosition > Sample(Channel(chan).sample).loopEnd Then Channel(chan).invertLoopPosition = Sample(Channel(chan).sample).loopStart

            ' Yeah I know, this is weird. QB64 NOT is bitwise and not logical
            PokeSample Channel(chan).sample, Channel(chan).invertLoopPosition, Not PeekSample(Channel(chan).sample, Channel(chan).invertLoopPosition)
        End If
    End Sub


    ' This gives us the frequency in khz based on the period
    Function GetFrequencyFromPeriod! (period As Long)
        GetFrequencyFromPeriod = 14317056 / period
    End Function


    ' Return C2 speed for a finetune
    Function GetC2Spd~% (ft As Unsigned Byte)
        Select Case ft
            Case 0
                GetC2Spd = 8363
            Case 1
                GetC2Spd = 8413
            Case 2
                GetC2Spd = 8463
            Case 3
                GetC2Spd = 8529
            Case 4
                GetC2Spd = 8581
            Case 5
                GetC2Spd = 8651
            Case 6
                GetC2Spd = 8723
            Case 7
                GetC2Spd = 8757
            Case 8
                GetC2Spd = 7895
            Case 9
                GetC2Spd = 7941
            Case 10
                GetC2Spd = 7985
            Case 11
                GetC2Spd = 8046
            Case 12
                GetC2Spd = 8107
            Case 13
                GetC2Spd = 8169
            Case 14
                GetC2Spd = 8232
            Case 15
                GetC2Spd = 8280
            Case Else
                GetC2Spd = 8363
        End Select
    End Function
    '-----------------------------------------------------------------------------------------------------
$End If

'---------------------------------------------------------------------------------------------------------
' MODULE FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'./SoftSynth.bas'
'---------------------------------------------------------------------------------------------------------
'---------------------------------------------------------------------------------------------------------

