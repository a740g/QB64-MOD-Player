'---------------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'MODPlayer.bi'
'---------------------------------------------------------------------------------------------------------

$If MODPLAYER_BAS = UNDEFINED Then
    $Let MODPLAYER_BAS = TRUE

    '-----------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-----------------------------------------------------------------------------------------------------
    '$Debug
    'If LoadMODFile("C:\Users\samue\OneDrive\Documents\GitHub\QB64-MOD-Player\mods\rez-monday.mod") Then
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
        ' TODO: For funkrepeat load a another copy of the inverted looped samples into a 31 + n slot
        '   Check which sample needs this by quickly checking the pattern data above
        '   Then during playback use the 31 + n sample when the effect is encountered
        For i = 0 To Song.samples - 1
            ' Load sample size bytes of data and send it to our softsynth sample manager
            LoadSample i, Input$(Sample(i).length, fileHandle)
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

        ' Initialize the softsynth sample mixer
        InitializeMixer Song.channels

        ' Initialize some important stuff
        Song.tempoTimerValue = (SoftSynth.mixerRate * SONG_BPM_DEFAULT) / 50
        Song.orderPosition = 0
        Song.patternRow = 0
        Song.speed = SONG_SPEED_DEFAULT
        Song.tick = Song.speed
        Song.isPaused = FALSE

        ' Set default BPM
        SetBPM SONG_BPM_DEFAULT

        ' Setup the channel array
        ReDim Channel(0 To Song.channels - 1) As ChannelType

        ' Setup panning for all channels except last one if we have an odd number
        ' I hope I did this right. But I don't care even if it not the classic way. This is cooler :)
        For i = 0 To Song.channels - 1 - (Song.channels Mod 2)
            If i Mod 2 = 0 Then
                SetVoicePanning i, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
            Else
                SetVoicePanning i, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
            End If
        Next
        ' Set the last channel to center. This also works for single channel
        If Song.channels Mod 2 = 1 Then
            SetVoicePanning Song.channels - 1, SAMPLE_PAN_CENTER
        End If

        Song.isPlaying = TRUE
    End Sub


    ' Frees all allocated resources, stops the timer and hence song playback
    Sub StopMODPlayer
        ' Tell softsynth we are done
        FinalizeMixer

        Song.isPlaying = FALSE
    End Sub


    ' This should be called at regular intervals to run the mod player and mixer code
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    Sub UpdateMODPlayer
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
            nOpX = SHR(nOperand, 4)
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
                Channel(nChannel).lastPeriod = 8363 * PeriodTable(nNote) / Sample(Channel(nChannel).sample).c2Spd
                Channel(nChannel).note = nNote
                Channel(nChannel).restart = TRUE
                Channel(nChannel).startPosition = 0
                Song.activeChannels = nChannel

                ' Retrigger tremolo and vibrato waveforms
                If Channel(nChannel).waveControl And &HF < 4 Then Channel(nChannel).vibratoPosition = 0
                If SHR(Channel(nChannel).waveControl, 4) < 4 Then Channel(nChannel).tremoloPosition = 0

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
                    If nOperand > 0 Then Channel(nChannel).startPosition = SHL(nOperand, 8)

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
                            Channel(nChannel).period = Channel(nChannel).period - SHL(nOpY, 2)

                        Case &H2 ' 2: Fine Portamento Down
                            Channel(nChannel).period = Channel(nChannel).period + SHL(nOpY, 2)

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
                            Channel(nChannel).waveControl = Channel(nChannel).waveControl Or SHL(nOpY, 4)

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
                            ' TODO:
                            Channel(nChannel).funkrepeatSpeed = nOpY
                            Title "Funkrepeat speed: " + Str$(Channel(nChannel).funkrepeatSpeed)
                    End Select

                Case &HF ' 15: Set Speed
                    If nOperand < 32 Then
                        Song.speed = nOperand
                    Else
                        SetBPM nOperand
                    End If
            End Select

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
                nOpX = SHR(nOperand, 4)
                nOpY = nOperand And &HF

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
                        Channel(nChannel).period = Channel(nChannel).period - SHL(nOperand, 2)
                        SetVoiceFrequency nChannel, GetFrequencyFromPeriod(Channel(nChannel).period)
                        If Channel(nChannel).period < 56 Then Channel(nChannel).period = 56

                    Case &H2 ' 2: Porta Down
                        Channel(nChannel).period = Channel(nChannel).period + SHL(nOperand, 2)
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
                                    If Channel(nChannel).sample > 0 Then Channel(nChannel).volume = Sample(Channel(nChannel).sample).volume
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
        Song.bpm = nBPM

        ' Calculate the number of samples we have to mix per tick
        Song.samplesPerTick = Song.tempoTimerValue / nBPM
    End Sub


    ' Binary search the period table to find the closest value
    ' I hope this is the right way to do glissando. Oh well...
    Function GetClosestPeriod& (target As Long)
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
            midPos = startPos + (endPos - startPos) / 2
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
        ' Slide up/down and clamp to destination
        If Channel(chan).period < Channel(chan).portamentoTo Then
            Channel(chan).period = Channel(chan).period + SHL(Channel(chan).portamentoSpeed, 2)
            If Channel(chan).period > Channel(chan).portamentoTo Then Channel(chan).period = Channel(chan).portamentoTo
        ElseIf Channel(chan).period > Channel(chan).portamentoTo Then
            Channel(chan).period = Channel(chan).period - SHL(Channel(chan).portamentoSpeed, 2)
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
        Channel(chan).volume = Channel(chan).volume + x - y
        If Channel(chan).volume < 0 Then Channel(chan).volume = 0
        If Channel(chan).volume > SAMPLE_VOLUME_MAX Then Channel(chan).volume = SAMPLE_VOLUME_MAX

        SetVoiceVolume chan, Channel(chan).volume
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

            Case 3 ' Random
                delta = Rnd * 255
        End Select

        delta = SHL(SHR(delta * Channel(chan).vibratoDepth, 7), 2)

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

            Case 3 ' Random
                delta = Rnd * 255
        End Select

        delta = SHR(delta * Channel(chan).tremoloDepth, 6)

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

'---------------------------------------------------------------------------------------------------------
' MODULE FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'SoftSynth.bas'
'---------------------------------------------------------------------------------------------------------

