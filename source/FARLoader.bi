'-----------------------------------------------------------------------------------------------------------------------
' Farandole Composer Module (FAR) Loader
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MODPlayer.bi'
'$INCLUDE:'SoftSynth.bi'
'$INCLUDE:'String.bi'
'$INCLUDE:'StringFile.bi'
'$INCLUDE:'File.bi'
'$INCLUDE:'MODPlayerShared.bm'

CONST __FARLOADER_MAGIC = "FAR" + CHR$(254)
CONST __FARLOADER_EOF = CHR$(13) + CHR$(10) + CHR$(26)
CONST __FARLOADER_CHANNELS = 16
CONST __FARLOADER_HEADER_MIN_SIZE = 869
CONST __FARLOADER_C2SPD = 16726

''' @brief Parses and loads a Farandole Composer (FAR) module from a memory buffer.
''' @param player The MOD player instance.
''' @param buffer In-memory binary representation of the FAR file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION FARLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    IF StringFile_GetSize(memFile) < __FARLOADER_HEADER_MIN_SIZE THEN EXIT FUNCTION

    IF StringFile_ReadString(memFile, 4) <> __FARLOADER_MAGIC THEN EXIT FUNCTION

    DIM songTitle AS STRING: songTitle = String_MakePrintable(StringFile_ReadString(memFile, 40))

    IF StringFile_ReadString(memFile, 3) <> __FARLOADER_EOF THEN EXIT FUNCTION

    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION

    __MODPlayer_InitializeSong player

    DIM headerLen AS _UNSIGNED INTEGER: headerLen = StringFile_ReadInteger(memFile)
    DIM version AS _UNSIGNED _BYTE: version = StringFile_ReadByte(memFile)
    IF headerLen < 98 THEN EXIT FUNCTION

    DIM onOff(0 TO __FARLOADER_CHANNELS - 1) AS _UNSIGNED _BYTE
    DIM i AS LONG: FOR i = 0 TO __FARLOADER_CHANNELS - 1
        onOff(i) = StringFile_ReadByte(memFile)
    NEXT i

    StringFile_Seek memFile, StringFile_GetPosition(memFile) + 9

    DIM defaultSpeed AS _UNSIGNED _BYTE: defaultSpeed = StringFile_ReadByte(memFile)

    DIM chnPanning(0 TO __FARLOADER_CHANNELS - 1) AS _UNSIGNED _BYTE
    FOR i = 0 TO __FARLOADER_CHANNELS - 1
        chnPanning(i) = StringFile_ReadByte(memFile)
    NEXT i

    StringFile_Seek memFile, StringFile_GetPosition(memFile) + 4

    DIM msgLen AS _UNSIGNED INTEGER: msgLen = StringFile_ReadInteger(memFile)
    IF msgLen > 0 _ANDALSO StringFile_GetPosition(memFile) + msgLen <= StringFile_GetSize(memFile) THEN
        DIM rawComment AS STRING: rawComment = StringFile_ReadString(memFile, msgLen)
        DIM formattedComment AS STRING: formattedComment = _STR_EMPTY
        DIM cOffset AS LONG: cOffset = 1
        WHILE cOffset <= LEN(rawComment)
            DIM lineChunk AS STRING: lineChunk = MID$(rawComment, cOffset, 132)
            DIM k AS LONG
            FOR k = 1 TO LEN(lineChunk)
                IF ASC(lineChunk, k) = 0 THEN MID$(lineChunk, k, 1) = " "
            NEXT k
            lineChunk = RTRIM$(String_MakePrintable(lineChunk))
            IF LEN(formattedComment) > 0 THEN
                formattedComment = formattedComment + CHR$(13) + CHR$(10) + lineChunk
            ELSE
                formattedComment = lineChunk
            END IF
            cOffset = cOffset + 132
        WEND
        DO WHILE RIGHT$(formattedComment, 2) = CHR$(13) + CHR$(10)
            formattedComment = LEFT$(formattedComment, LEN(formattedComment) - 2)
        LOOP
        player.song.comment = formattedComment
    ELSE
        player.song.comment = _STR_EMPTY
    END IF

    DIM rawOrders(0 TO 255) AS _UNSIGNED _BYTE
    FOR i = 0 TO 255
        rawOrders(i) = StringFile_ReadByte(memFile)
    NEXT i

    DIM numPatternsByte AS _UNSIGNED _BYTE: numPatternsByte = StringFile_ReadByte(memFile)
    DIM numOrders AS _UNSIGNED _BYTE: numOrders = StringFile_ReadByte(memFile)
    DIM restartPos AS _UNSIGNED _BYTE: restartPos = StringFile_ReadByte(memFile)

    DIM patSizes(0 TO 255) AS _UNSIGNED INTEGER
    FOR i = 0 TO 255
        patSizes(i) = StringFile_ReadInteger(memFile)
    NEXT i

    IF headerLen > StringFile_GetPosition(memFile) THEN
        StringFile_Seek memFile, headerLen
    END IF

    IF numOrders = 0 THEN numOrders = 1
    player.song.orders = numOrders
    IF restartPos < player.song.orders THEN
        player.song.endJumpOrder = restartPos
    ELSE
        player.song.endJumpOrder = 0
    END IF

    REDIM player.order(0 TO player.song.orders - 1) AS _UNSIGNED INTEGER
    FOR i = 0 TO player.song.orders - 1
        player.order(i) = rawOrders(i)
    NEXT i

    DIM maxPat AS LONG: maxPat = 0
    FOR i = 0 TO 255
        IF patSizes(i) > 0 THEN maxPat = i
    NEXT i
    FOR i = 0 TO player.song.orders - 1
        IF player.order(i) > maxPat THEN maxPat = player.order(i)
    NEXT i
    player.song.patterns = maxPat + 1

    REDIM player.pattern(0 TO player.song.patterns - 1) AS __MODPLAYERPATTERN

    DIM p AS LONG: FOR p = 0 TO 255
        DIM patSize AS _UNSIGNED INTEGER: patSize = patSizes(p)
        IF patSize = 0 THEN
            IF p < player.song.patterns THEN
                player.pattern(p).rows = __MODPLAYER_MOD_S3M_ROWS
                REDIM player.pattern(p).note(0 TO __MODPLAYER_MOD_S3M_ROWS - 1, 0 TO __FARLOADER_CHANNELS - 1) AS __MODPLAYERNOTE
                DIM r AS LONG: FOR r = 0 TO __MODPLAYER_MOD_S3M_ROWS - 1
                    DIM c AS LONG: FOR c = 0 TO __FARLOADER_CHANNELS - 1
                        player.pattern(p).note(r, c).note = __MODPLAYER_NOTE_NONE
                        player.pattern(p).note(r, c).instrument = 0
                        player.pattern(p).note(r, c).volume = __MODPLAYER_NOTE_NO_VOLUME
                        player.pattern(p).note(r, c).effect = 0
                        player.pattern(p).note(r, c).operand = 0
                    NEXT c
                NEXT r
            END IF
        ELSE
            IF StringFile_GetPosition(memFile) + patSize > StringFile_GetSize(memFile) THEN EXIT FUNCTION
            DIM breakRow AS _UNSIGNED _BYTE: breakRow = StringFile_ReadByte(memFile)
            DIM tempoUnused AS _UNSIGNED _BYTE: tempoUnused = StringFile_ReadByte(memFile)
            DIM rows AS LONG: rows = (patSize - 2) \ (__FARLOADER_CHANNELS * 4)
            IF rows <= 0 THEN rows = __MODPLAYER_MOD_S3M_ROWS

            IF p < player.song.patterns THEN
                player.pattern(p).rows = rows
                REDIM player.pattern(p).note(0 TO rows - 1, 0 TO __FARLOADER_CHANNELS - 1) AS __MODPLAYERNOTE

                FOR r = 0 TO rows - 1
                    FOR c = 0 TO __FARLOADER_CHANNELS - 1
                        DIM noteVal AS _UNSIGNED _BYTE: noteVal = StringFile_ReadByte(memFile)
                        DIM instrVal AS _UNSIGNED _BYTE: instrVal = StringFile_ReadByte(memFile)
                        DIM volVal AS _UNSIGNED _BYTE: volVal = StringFile_ReadByte(memFile)
                        DIM fxByte AS _UNSIGNED _BYTE: fxByte = StringFile_ReadByte(memFile)

                        IF onOff(c) = 0 THEN
                            player.pattern(p).note(r, c).note = __MODPLAYER_NOTE_NONE
                            player.pattern(p).note(r, c).instrument = 0
                            player.pattern(p).note(r, c).volume = __MODPLAYER_NOTE_NO_VOLUME
                            player.pattern(p).note(r, c).effect = 0
                            player.pattern(p).note(r, c).operand = 0
                        ELSE
                            ' Note & Instrument
                            IF noteVal > 0 _ANDALSO noteVal <= 72 THEN
                                player.pattern(p).note(r, c).note = noteVal + 35
                                player.pattern(p).note(r, c).instrument = instrVal + 1
                            ELSE
                                player.pattern(p).note(r, c).note = __MODPLAYER_NOTE_NONE
                                player.pattern(p).note(r, c).instrument = 0
                            END IF

                            ' Volume
                            IF volVal >= 1 _ANDALSO volVal <= 16 THEN
                                player.pattern(p).note(r, c).volume = ((volVal - 1) * 64) \ 15
                            ELSEIF volVal > 16 _ANDALSO (volVal AND &H0F) > 0 THEN
                                player.pattern(p).note(r, c).volume = _MIN((((volVal AND &H0F) - 1) * 64) \ 15, 64)
                            ELSE
                                player.pattern(p).note(r, c).volume = __MODPLAYER_NOTE_NO_VOLUME
                            END IF

                            ' Effect & Operand
                            DIM fxCmd AS _UNSIGNED _BYTE: fxCmd = _SHR(fxByte, 4)
                            DIM fxParam AS _UNSIGNED _BYTE: fxParam = fxByte AND &H0F

                            SELECT CASE fxCmd
                                CASE &H0
                                    player.pattern(p).note(r, c).effect = 0
                                    player.pattern(p).note(r, c).operand = 0

                                CASE &H1 ' Pitch adjust up (fine portamento up)
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_EXT
                                    player.pattern(p).note(r, c).operand = &H10 OR fxParam

                                CASE &H2 ' Pitch adjust down (fine portamento down)
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_EXT
                                    player.pattern(p).note(r, c).operand = &H20 OR fxParam

                                CASE &H3 ' Tone portamento
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_PORTAMENTO
                                    IF fxParam > 0 THEN
                                        player.pattern(p).note(r, c).operand = _CLAMP(60 \ fxParam, 1, 255)
                                    ELSE
                                        player.pattern(p).note(r, c).operand = 0
                                    END IF

                                CASE &H4 ' Retrigger
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_EXT
                                    DIM retrigTicks AS LONG: retrigTicks = (6 \ (1 + fxParam)) + 1
                                    player.pattern(p).note(r, c).operand = &H90 OR (retrigTicks AND &H0F)

                                CASE &H5 ' Vibrato depth
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_VIBRATO
                                    player.pattern(p).note(r, c).operand = fxParam

                                CASE &H6 ' Vibrato speed
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_VIBRATO
                                    player.pattern(p).note(r, c).operand = _SHL(fxParam, 4)

                                CASE &H7 ' Volume slide up
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_VOLUME_SLIDE
                                    player.pattern(p).note(r, c).operand = _SHL(fxParam, 4)

                                CASE &H8 ' Volume slide down
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_VOLUME_SLIDE
                                    player.pattern(p).note(r, c).operand = fxParam

                                CASE &H9 ' Sustained vibrato
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_VIBRATO
                                    player.pattern(p).note(r, c).operand = _SHL(fxParam, 4)

                                CASE &HA ' Slide to volume / set volume
                                    IF player.pattern(p).note(r, c).volume = __MODPLAYER_NOTE_NO_VOLUME THEN
                                        player.pattern(p).note(r, c).volume = _MIN(_SHL(fxParam, 2) + 4, 64)
                                    END IF
                                    player.pattern(p).note(r, c).effect = 0
                                    player.pattern(p).note(r, c).operand = 0

                                CASE &HB ' Panning
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_PANNING_8
                                    player.pattern(p).note(r, c).operand = fxParam * 17

                                CASE &HC ' Note offset / note delay
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_EXT
                                    DIM noteDelayTicks AS LONG: noteDelayTicks = (6 \ (1 + fxParam)) + 1
                                    player.pattern(p).note(r, c).operand = &HD0 OR (noteDelayTicks AND &H0F)

                                CASE &HF ' Set tempo / speed
                                    player.pattern(p).note(r, c).effect = __MODPLAYER_FX_SPEED_TEMPO
                                    player.pattern(p).note(r, c).operand = fxParam

                                CASE ELSE
                                    player.pattern(p).note(r, c).effect = 0
                                    player.pattern(p).note(r, c).operand = 0
                            END SELECT
                        END IF
                    NEXT c
                NEXT r

                ' Pattern break
                IF breakRow > 0 _ANDALSO breakRow < rows - 2 THEN
                    DIM targetBreakRow AS LONG: targetBreakRow = breakRow + 1
                    DIM bChn AS LONG: bChn = __FARLOADER_CHANNELS - 1
                    DIM chkChn AS LONG
                    FOR chkChn = 0 TO __FARLOADER_CHANNELS - 1
                        IF player.pattern(p).note(targetBreakRow, chkChn).effect = 0 THEN
                            bChn = chkChn
                            EXIT FOR
                        END IF
                    NEXT chkChn
                    player.pattern(p).note(targetBreakRow, bChn).effect = __MODPLAYER_FX_PATTERN_BREAK
                    player.pattern(p).note(targetBreakRow, bChn).operand = 0
                END IF
            ELSE
                StringFile_Seek memFile, StringFile_GetPosition(memFile) + (patSize - 2)
            END IF
        END IF
    NEXT p

    IF StringFile_GetPosition(memFile) + 8 > StringFile_GetSize(memFile) THEN EXIT FUNCTION
    DIM sampleMap(0 TO 7) AS _UNSIGNED _BYTE
    FOR i = 0 TO 7
        sampleMap(i) = StringFile_ReadByte(memFile)
    NEXT i

    DIM maxSample AS LONG: maxSample = -1
    DIM s AS LONG: FOR s = 0 TO 63
        IF (sampleMap(s \ 8) AND _SHL(1, (s MOD 8))) <> 0 THEN
            maxSample = s
        END IF
    NEXT s

    IF maxSample >= 0 THEN
        player.song.instruments = maxSample + 1
        REDIM player.instrument(0 TO player.song.instruments - 1) AS __MODPLAYERINSTRUMENT
    ELSE
        player.song.instruments = 0
    END IF

    FOR s = 0 TO 63
        IF (sampleMap(s \ 8) AND _SHL(1, (s MOD 8))) <> 0 THEN
            IF StringFile_GetPosition(memFile) + 48 > StringFile_GetSize(memFile) THEN EXIT FOR

            DIM smpName AS STRING: smpName = StringFile_ReadString(memFile, 32)
            DIM smpLen AS _UNSIGNED LONG: smpLen = StringFile_ReadLong(memFile)
            DIM finetune AS _UNSIGNED _BYTE: finetune = StringFile_ReadByte(memFile)
            DIM smpVol AS _UNSIGNED _BYTE: smpVol = StringFile_ReadByte(memFile)
            DIM loopStart AS _UNSIGNED LONG: loopStart = StringFile_ReadLong(memFile)
            DIM loopEnd AS _UNSIGNED LONG: loopEnd = StringFile_ReadLong(memFile)
            DIM smpType AS _UNSIGNED _BYTE: smpType = StringFile_ReadByte(memFile)
            DIM loopMode AS _UNSIGNED _BYTE: loopMode = StringFile_ReadByte(memFile)

            DIM is16Bit AS _BYTE: is16Bit = ((smpType AND 1) <> 0)
            DIM isLooped AS _BYTE: isLooped = (((loopMode AND &H08) <> 0) _ANDALSO loopEnd > loopStart _ANDALSO loopEnd <= smpLen)

            DIM sampData AS STRING
            IF smpLen > 0 _ANDALSO StringFile_GetPosition(memFile) + smpLen <= StringFile_GetSize(memFile) THEN
                sampData = StringFile_ReadString(memFile, smpLen)
            ELSE
                sampData = _STR_EMPTY
                smpLen = 0
            END IF

            IF s < player.song.instruments THEN
                player.instrument(s).caption = String_MakePrintable(smpName)
                player.instrument(s).length = smpLen
                player.instrument(s).c2Spd = __FARLOADER_C2SPD
                player.instrument(s).subtype = __MODPLAYER_INSTRUMENT_PCM
                IF is16Bit THEN
                    player.instrument(s).bytesPerSample = 2
                ELSE
                    player.instrument(s).bytesPerSample = 1
                END IF
                player.instrument(s).channels = 1

                IF smpVol > 0 THEN
                    player.instrument(s).volume = _MIN(CLNG(smpVol) * 4, __MODPLAYER_INSTRUMENT_VOLUME_MAX)
                ELSEIF smpLen > 0 THEN
                    player.instrument(s).volume = __MODPLAYER_INSTRUMENT_VOLUME_MAX
                ELSE
                    player.instrument(s).volume = 0
                END IF

                IF isLooped THEN
                    player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
                    player.instrument(s).loopStart = loopStart
                    player.instrument(s).loopEnd = loopEnd
                ELSE
                    player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                    player.instrument(s).loopStart = 0
                    player.instrument(s).loopEnd = smpLen
                END IF

                IF smpLen > 0 THEN
                    SoftSynth_LoadSound player.synth, s, sampData, player.instrument(s).bytesPerSample, 1
                END IF
            END IF
        END IF
    NEXT s

    player.song.caption = songTitle
    player.song.subtype = "FAR"
    player.song.format = MODPLAYER_FORMAT_FAR
    player.song.channels = __FARLOADER_CHANNELS
    player.song.pcmMasterGain = 32.0! / 128.0! ' Matches OpenMPT FAR pre-amp of 32
    player.song.isStereo = _TRUE
    player.song.hasFMChannels = _FALSE

    IF defaultSpeed > 0 THEN
        player.song.defaultSpeed = defaultSpeed
    ELSE
        player.song.defaultSpeed = 6
    END IF
    player.song.defaultBPM = 80
    player.song.speed = player.song.defaultSpeed
    player.song.BPM = player.song.defaultBPM
    player.song.tick = player.song.speed

    player.song.globalVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX
    player.song.defaultGlobalVolume = player.song.globalVolume
    player.song.isPlaying = _TRUE
    player.song.isLooping = _TRUE

    SoftSynth_SetTotalVoices player.synth, __FARLOADER_CHANNELS
    REDIM player.channel(0 TO __FARLOADER_CHANNELS - 1) AS __MODPLAYERCHANNEL

    DIM cIdx AS LONG: FOR cIdx = 0 TO __FARLOADER_CHANNELS - 1
        player.channel(cIdx).defaultPanning = (chnPanning(cIdx) AND &H0F) * 17
        player.channel(cIdx).panning = player.channel(cIdx).defaultPanning
        player.channel(cIdx).subtype = __MODPLAYER_INSTRUMENT_PCM
        player.channel(cIdx).vibratoDepth = 4
        IF onOff(cIdx) = 0 THEN
            player.channel(cIdx).channelVolume = 0
        ELSE
            player.channel(cIdx).channelVolume = 64
        END IF
        SoftSynth_SetVoiceBalance player.synth, cIdx, (CSNG(player.channel(cIdx).defaultPanning) / 255!) * 2! - 1!
    NEXT cIdx

    __MODPlayer_LoadTables

    player.initialized = _TRUE

    FARLoader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Loads a Farandole Composer (FAR) module from a file on disk or URL.
''' @param player The MOD player instance.
''' @param fileName File path or URL to load.
''' @return _TRUE if the module was loaded, _FALSE otherwise.
FUNCTION FARLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    FARLoader_LoadFromDisk = FARLoader_LoadFromMemory(player, File_Load(fileName))
END FUNCTION
