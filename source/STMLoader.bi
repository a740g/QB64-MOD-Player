'-----------------------------------------------------------------------------------------------------------------------
' Scream Tracker 2.x Module (STM) Loader
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MODPlayer.bi'
'$INCLUDE:'SoftSynth.bi'
'$INCLUDE:'String.bi'
'$INCLUDE:'StringFile.bi'
'$INCLUDE:'File.bi'
'$INCLUDE:'MODPlayerShared.bm'

CONST __STMLOADER_HEADER_MIN_SIZE = 1104
CONST __STMLOADER_CHANNELS = 4
CONST __STMLOADER_INSTRUMENTS = 31
CONST __STMLOADER_ROWS = 64
CONST __STMLOADER_MIX_RATE = 23863

''' @brief Calculates playback BPM from Scream Tracker 2 speed and tempo factor.
''' @param spd Speed (ticks per row, 1 to 15).
''' @param tempoFactor Fine tempo factor nibble (0 to 15).
''' @return Tempo in BPM (32 to 255).
FUNCTION __STMLoader_CalculateBPM~% (spd AS _UNSIGNED _BYTE, tempoFactor AS _UNSIGNED _BYTE)
    STATIC speedFactor(0 TO 15) AS _UNSIGNED _BYTE
    STATIC tableInit AS _BYTE
    IF NOT tableInit THEN
        speedFactor(0) = 140: speedFactor(1) = 50: speedFactor(2) = 25: speedFactor(3) = 15
        speedFactor(4) = 10: speedFactor(5) = 7: speedFactor(6) = 6: speedFactor(7) = 4
        speedFactor(8) = 3: speedFactor(9) = 3: speedFactor(10) = 2: speedFactor(11) = 2
        speedFactor(12) = 2: speedFactor(13) = 2: speedFactor(14) = 1: speedFactor(15) = 1
        tableInit = _TRUE
    END IF

    DIM s AS LONG: s = _CLAMP(spd, 0, 15)
    DIM divisor AS LONG: divisor = 50 - _SHR(CLNG(speedFactor(s)) * CLNG(tempoFactor), 4)
    IF divisor <= 0 THEN divisor = 1

    DIM tickFrames AS LONG: tickFrames = __STMLOADER_MIX_RATE \ divisor
    IF tickFrames <= 0 THEN tickFrames = 1

    DIM bpm AS LONG: bpm = (CLNG(__STMLOADER_MIX_RATE) * 5 + tickFrames) \ (tickFrames * 2)
    IF bpm < 32 THEN bpm = 32
    IF bpm > 255 THEN bpm = 255

    __STMLoader_CalculateBPM = bpm
END FUNCTION

''' @brief Parses and loads a Scream Tracker 2.x (STM) module from a memory buffer.
''' @param player The MOD player instance.
''' @param buffer In-memory binary representation of the STM file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION STMLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    IF StringFile_GetSize(memFile) < __STMLOADER_HEADER_MIN_SIZE THEN EXIT FUNCTION

    ' Title at offset 0 (20 bytes)
    DIM songTitle AS STRING: songTitle = String_MakePrintable(String_ConvertToBStr(StringFile_ReadString(memFile, 20)))

    ' Tracker name at offset 20 (8 bytes)
    DIM trackerName AS STRING: trackerName = StringFile_ReadString(memFile, 8)
    DIM tIdx AS LONG
    FOR tIdx = 1 TO 8
        DIM tc AS _UNSIGNED _BYTE: tc = ASC(trackerName, tIdx)
        IF tc <> 0 _ANDALSO (tc < 32 _ORELSE tc > 126) THEN EXIT FUNCTION
    NEXT tIdx

    ' DOS EOF at offset 28
    DIM dosEof AS _UNSIGNED _BYTE: dosEof = StringFile_ReadByte(memFile)
    IF dosEof <> &H1A _ANDALSO dosEof <> &H02 THEN EXIT FUNCTION

    ' File type at offset 29 (1 = song, 2 = module)
    DIM fileType AS _UNSIGNED _BYTE: fileType = StringFile_ReadByte(memFile)
    IF fileType <> 1 _ANDALSO fileType <> 2 THEN EXIT FUNCTION

    ' Major version at offset 30
    DIM verMajor AS _UNSIGNED _BYTE: verMajor = StringFile_ReadByte(memFile)
    IF verMajor <> 2 _ANDALSO verMajor <> 1 THEN EXIT FUNCTION

    ' Minor version at offset 31
    DIM verMinor AS _UNSIGNED _BYTE: verMinor = StringFile_ReadByte(memFile)
    DIM version AS LONG: version = CLNG(verMajor) * 100 + verMinor
    IF version <> 110 _ANDALSO version <> 200 _ANDALSO version <> 210 _ANDALSO version <> 220 _ANDALSO version <> 221 THEN
        IF verMajor <> 2 THEN EXIT FUNCTION
    END IF

    ' Initial tempo at offset 32
    DIM initTempoByte AS _UNSIGNED _BYTE: initTempoByte = StringFile_ReadByte(memFile)

    ' Patterns count at offset 33
    DIM numPatterns AS _UNSIGNED _BYTE: numPatterns = StringFile_ReadByte(memFile)
    IF numPatterns > 64 THEN EXIT FUNCTION

    ' Global volume at offset 34
    DIM globalVol AS _UNSIGNED _BYTE: globalVol = StringFile_ReadByte(memFile)
    IF globalVol > 64 _ANDALSO globalVol <> &H58 THEN EXIT FUNCTION

    ' Ensure offset 60 does not start with "SCRM" (which would be STX)
    IF MID$(buffer, 61, 4) = "SCRM" THEN EXIT FUNCTION

    ' Seek past header reserved bytes to instrument section at offset 48
    StringFile_Seek memFile, 48

    DIM initTempo AS _UNSIGNED _BYTE: initTempo = initTempoByte
    IF verMajor < 2 _ORELSE verMinor < 21 THEN
        initTempo = (initTempo \ 10) * 16 + (initTempo MOD 10)
    END IF
    IF initTempo = 0 THEN initTempo = &H60

    DIM defSpeed AS _UNSIGNED _BYTE: defSpeed = _SHR(initTempo, 4)
    IF defSpeed = 0 THEN defSpeed = 6
    DIM defBPM AS _UNSIGNED INTEGER: defBPM = __STMLoader_CalculateBPM(defSpeed, initTempo AND &H0F)

    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION
    __MODPlayer_InitializeSong player

    player.song.caption = songTitle
    player.song.channels = __STMLOADER_CHANNELS
    player.song.instruments = __STMLOADER_INSTRUMENTS
    player.song.subtype = "STM "
    player.song.isS3M = _TRUE
    player.song.useST2Tempo = _TRUE
    player.song.useST2Vibrato = _TRUE
    player.song.isStereo = _TRUE
    player.song.pcmMasterGain = 1.0!

    IF globalVol > 64 THEN globalVol = 64
    player.song.globalVolume = globalVol
    player.song.defaultGlobalVolume = globalVol

    player.song.defaultSpeed = defSpeed
    player.song.speed = defSpeed
    player.song.defaultBPM = defBPM
    player.song.BPM = defBPM

    ' Read 31 instrument headers
    REDIM player.instrument(0 TO __STMLOADER_INSTRUMENTS - 1) AS __MODPlayerInstrument
    DIM sampleOffsets(0 TO __STMLOADER_INSTRUMENTS - 1) AS _UNSIGNED LONG

    DIM i AS LONG
    FOR i = 0 TO __STMLOADER_INSTRUMENTS - 1
        player.instrument(i).subtype = __MODPLAYER_INSTRUMENT_PCM

        DIM instFileName AS STRING: instFileName = String_MakePrintable(String_ConvertToBStr(StringFile_ReadString(memFile, 12)))
        player.instrument(i).caption = instFileName

        DIM zeroByte AS _UNSIGNED _BYTE: zeroByte = StringFile_ReadByte(memFile)
        DIM diskByte AS _UNSIGNED _BYTE: diskByte = StringFile_ReadByte(memFile)
        DIM paraOffset AS _UNSIGNED INTEGER: paraOffset = StringFile_ReadInteger(memFile)
        sampleOffsets(i) = _SHL(CLNG(paraOffset), 4)

        DIM smpLength AS _UNSIGNED INTEGER: smpLength = StringFile_ReadInteger(memFile)
        DIM loopStart AS _UNSIGNED INTEGER: loopStart = StringFile_ReadInteger(memFile)
        DIM loopEnd AS _UNSIGNED INTEGER: loopEnd = StringFile_ReadInteger(memFile)
        DIM smpVol AS _UNSIGNED _BYTE: smpVol = StringFile_ReadByte(memFile)
        DIM rsvd2 AS _UNSIGNED _BYTE: rsvd2 = StringFile_ReadByte(memFile)
        DIM c2spd AS _UNSIGNED INTEGER: c2spd = StringFile_ReadInteger(memFile)
        DIM rsvd3 AS _UNSIGNED LONG: rsvd3 = StringFile_ReadLong(memFile)
        DIM paralen AS _UNSIGNED INTEGER: paralen = StringFile_ReadInteger(memFile)

        IF smpLength < 2 THEN smpLength = 0
        player.instrument(i).length = smpLength
        player.instrument(i).volume = _MIN(smpVol, 64)
        IF c2spd = 0 THEN c2spd = 8363
        player.instrument(i).c2Spd = c2spd
        player.instrument(i).bytesPerSample = _SIZE_OF_BYTE
        player.instrument(i).channels = 1

        IF loopStart < smpLength _ANDALSO loopEnd > loopStart _ANDALSO loopEnd <> &HFFFF~% _ANDALSO loopEnd <> 0 THEN
            player.instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
            player.instrument(i).loopStart = loopStart
            player.instrument(i).loopEnd = _MIN(loopEnd, smpLength)
        ELSE
            player.instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            player.instrument(i).loopStart = 0
            player.instrument(i).loopEnd = smpLength
        END IF
    NEXT i

    ' Read order table
    DIM orderTableLen AS LONG
    IF verMinor = 0 THEN orderTableLen = 64 ELSE orderTableLen = 128

    DIM rawOrders(0 TO 127) AS _UNSIGNED _BYTE
    FOR i = 0 TO orderTableLen - 1
        rawOrders(i) = StringFile_ReadByte(memFile)
    NEXT i

    DIM validOrderCount AS LONG: validOrderCount = 0
    FOR i = 0 TO orderTableLen - 1
        IF rawOrders(i) >= 99 THEN EXIT FOR
        validOrderCount = validOrderCount + 1
    NEXT i

    IF validOrderCount = 0 THEN
        validOrderCount = 1
        rawOrders(0) = 0
    END IF

    player.song.orders = validOrderCount
    REDIM player.order(0 TO player.song.orders - 1) AS _UNSIGNED INTEGER

    DIM maxPatIndex AS LONG: maxPatIndex = CLNG(numPatterns) - 1
    FOR i = 0 TO player.song.orders - 1
        player.order(i) = rawOrders(i)
        IF CLNG(player.order(i)) > maxPatIndex THEN maxPatIndex = player.order(i)
    NEXT i

    player.song.patterns = maxPatIndex + 1

    ' Allocate and initialize pattern arrays
    REDIM player.pattern(0 TO player.song.patterns - 1) AS __MODPLAYERPATTERN
    DIM p AS LONG
    FOR p = 0 TO player.song.patterns - 1
        player.pattern(p).rows = __STMLOADER_ROWS
        REDIM player.pattern(p).note(0 TO __STMLOADER_ROWS - 1, 0 TO __STMLOADER_CHANNELS - 1) AS __MODPLAYERNOTE
        DIM rInit AS LONG, cInit AS LONG
        FOR rInit = 0 TO __STMLOADER_ROWS - 1
            FOR cInit = 0 TO __STMLOADER_CHANNELS - 1
                player.pattern(p).note(rInit, cInit).note = __MODPLAYER_NOTE_NONE
                player.pattern(p).note(rInit, cInit).volume = __MODPLAYER_NOTE_NO_VOLUME
            NEXT cInit
        NEXT rInit
    NEXT p

    ' Unpack pattern data
    FOR p = 0 TO CLNG(numPatterns) - 1
        DIM row AS LONG, ch AS LONG
        FOR row = 0 TO __STMLOADER_ROWS - 1
            FOR ch = 0 TO __STMLOADER_CHANNELS - 1
                IF StringFile_GetPosition(memFile) >= StringFile_GetSize(memFile) THEN EXIT FOR

                DIM b1 AS _UNSIGNED _BYTE: b1 = StringFile_ReadByte(memFile)

                SELECT CASE b1
                    CASE &HFB, &HFC
                        ' 251 / 252: empty cell, last 3 bytes not stored in file
                        _CONTINUE

                    CASE &HFD
                        ' 253: key-off, last 3 bytes not stored in file
                        player.pattern(p).note(row, ch).note = __MODPLAYER_NOTE_KEY_OFF
                        _CONTINUE

                    CASE ELSE
                        IF StringFile_GetPosition(memFile) + 3 > StringFile_GetSize(memFile) THEN EXIT FOR

                        DIM b2 AS _UNSIGNED _BYTE: b2 = StringFile_ReadByte(memFile)
                        DIM b3 AS _UNSIGNED _BYTE: b3 = StringFile_ReadByte(memFile)
                        DIM b4 AS _UNSIGNED _BYTE: b4 = StringFile_ReadByte(memFile)

                        ' Decode note
                        IF b1 = &HFE THEN
                            player.pattern(p).note(row, ch).note = __MODPLAYER_NOTE_KEY_OFF
                        ELSEIF b1 = &HFF THEN
                            player.pattern(p).note(row, ch).note = __MODPLAYER_NOTE_NONE
                        ELSEIF (b1 AND &H0F) < 12 _ANDALSO b1 < &H60 THEN
                            player.pattern(p).note(row, ch).note = _SHR(b1, 4) * 12 + (b1 AND &H0F) + 36
                        ELSE
                            player.pattern(p).note(row, ch).note = __MODPLAYER_NOTE_NONE
                        END IF

                        ' Decode instrument (bits 3-7 of b2)
                        DIM instNum AS _UNSIGNED INTEGER: instNum = _SHR(b2, 3)
                        IF instNum > 31 THEN instNum = 0
                        player.pattern(p).note(row, ch).instrument = instNum

                        ' Decode volume (lower 3 bits of b2 + upper 4 bits of b3)
                        DIM volVal AS _UNSIGNED _BYTE: volVal = (b2 AND 7) OR _SHR(b3 AND &HF0, 1)
                        IF volVal <= 64 THEN
                            player.pattern(p).note(row, ch).volume = volVal
                        ELSE
                            player.pattern(p).note(row, ch).volume = __MODPLAYER_NOTE_NO_VOLUME
                        END IF

                        ' Decode command and operand
                        DIM cmd AS _UNSIGNED _BYTE: cmd = b3 AND &H0F
                        DIM op AS _UNSIGNED _BYTE: op = b4

                        SELECT CASE cmd
                            CASE 1 ' A - Set Speed / Tempo
                                IF op > 0 THEN
                                    DIM spd AS _UNSIGNED _BYTE
                                    IF version < 221 THEN
                                        spd = op \ 10
                                    ELSE
                                        spd = _SHR(op, 4)
                                    END IF
                                    IF spd = 0 THEN spd = 1
                                    player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_SPEED
                                    player.pattern(p).note(row, ch).operand = spd
                                END IF

                            CASE 2 ' B - Position Jump
                                player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_POSITION_JUMP
                                player.pattern(p).note(row, ch).operand = op

                            CASE 3 ' C - Pattern Break
                                player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_PATTERN_BREAK
                                player.pattern(p).note(row, ch).operand = 0

                            CASE 4 ' D - Volume Slide
                                IF op > 0 THEN
                                    player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_VOLUME_SLIDE
                                    IF (op AND &H0F) > 0 THEN
                                        player.pattern(p).note(row, ch).operand = op AND &H0F
                                    ELSE
                                        player.pattern(p).note(row, ch).operand = op AND &HF0
                                    END IF
                                END IF

                            CASE 5 ' E - Portamento Down
                                IF op > 0 THEN
                                    player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_PORTAMENTO_DOWN
                                    player.pattern(p).note(row, ch).operand = op
                                END IF

                            CASE 6 ' F - Portamento Up
                                IF op > 0 THEN
                                    player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_PORTAMENTO_UP
                                    player.pattern(p).note(row, ch).operand = op
                                END IF

                            CASE 7 ' G - Tone Portamento
                                IF op > 0 THEN
                                    player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_PORTAMENTO
                                    player.pattern(p).note(row, ch).operand = op
                                END IF

                            CASE 8 ' H - Vibrato
                                IF op > 0 THEN
                                    player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_VIBRATO
                                    player.pattern(p).note(row, ch).operand = op
                                END IF

                            CASE 9 ' I - Tremor
                                IF op > 0 THEN
                                    player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_TREMOR
                                    player.pattern(p).note(row, ch).operand = op
                                END IF

                            CASE 10 ' J - Arpeggio
                                IF op > 0 THEN
                                    player.pattern(p).note(row, ch).effect = __MODPLAYER_FX_ARPEGGIO
                                    player.pattern(p).note(row, ch).operand = op
                                END IF

                            CASE ELSE
                                player.pattern(p).note(row, ch).effect = 0
                                player.pattern(p).note(row, ch).operand = 0
                        END SELECT
                END SELECT
            NEXT ch
        NEXT row
    NEXT p

    ' Load sample data into SoftSynth
    FOR i = 0 TO __STMLOADER_INSTRUMENTS - 1
        IF player.instrument(i).length > 0 _ANDALSO sampleOffsets(i) > 0 THEN
            IF sampleOffsets(i) < StringFile_GetSize(memFile) THEN
                StringFile_Seek memFile, sampleOffsets(i)
                DIM readBytes AS _UNSIGNED LONG
                readBytes = _MIN(player.instrument(i).length, StringFile_GetSize(memFile) - sampleOffsets(i))
                DIM sampleData AS STRING: sampleData = StringFile_ReadString(memFile, readBytes)
                IF LEN(sampleData) < player.instrument(i).length THEN
                    sampleData = sampleData + STRING$(player.instrument(i).length - LEN(sampleData), 0)
                END IF
                SoftSynth_LoadSound player.synth, i, sampleData, _SIZE_OF_BYTE, 1
            END IF
        END IF
    NEXT i

    ' Setup channels
    SoftSynth_SetTotalVoices player.synth, __STMLOADER_CHANNELS
    REDIM player.channel(0 TO __STMLOADER_CHANNELS - 1) AS __MODPLAYERCHANNEL

    DIM chIdx AS LONG
    FOR chIdx = 0 TO __STMLOADER_CHANNELS - 1
        player.channel(chIdx).subtype = __MODPLAYER_INSTRUMENT_PCM
        player.channel(chIdx).channelVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX
    NEXT chIdx

    ' Scream Tracker 2 stereo panning: LRRL (64, 192, 192, 64)
    player.channel(0).panning = 64: player.channel(0).defaultPanning = 64
    player.channel(1).panning = 192: player.channel(1).defaultPanning = 192
    player.channel(2).panning = 192: player.channel(2).defaultPanning = 192
    player.channel(3).panning = 64: player.channel(3).defaultPanning = 64

    SoftSynth_SetVoiceBalance player.synth, 0, -__MODPLAYER_STEREO_SEPARATION
    SoftSynth_SetVoiceBalance player.synth, 1, __MODPLAYER_STEREO_SEPARATION
    SoftSynth_SetVoiceBalance player.synth, 2, __MODPLAYER_STEREO_SEPARATION
    SoftSynth_SetVoiceBalance player.synth, 3, -__MODPLAYER_STEREO_SEPARATION

    __MODPlayer_LoadTables

    player.initialized = _TRUE

    STMLoader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Loads a Scream Tracker 2.x (STM) module from a file on disk or URL.
''' @param player The MOD player instance.
''' @param fileName File path or URL to load.
''' @return _TRUE if the module was loaded, _FALSE otherwise.
FUNCTION STMLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    STMLoader_LoadFromDisk = STMLoader_LoadFromMemory(player, File_Load(fileName))
END FUNCTION
