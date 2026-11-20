'-----------------------------------------------------------------------------------------------------------------------
' Composer 669 / UNIS 669 Module (669) Loader
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MODPlayer.bi'
'$INCLUDE:'SoftSynth.bi'
'$INCLUDE:'String.bi'
'$INCLUDE:'StringFile.bi'
'$INCLUDE:'File.bi'
'$INCLUDE:'AudioConv.bi'
'$INCLUDE:'MODPlayerShared.bm'

CONST __C669LOADER_MAGIC_STD = "if"
CONST __C669LOADER_MAGIC_EXT = "JN"
CONST __C669LOADER_CHANNELS = 8
CONST __C669LOADER_HEADER_SIZE = 497
CONST __C669LOADER_SAMPLE_HEADER_SIZE = 25
CONST __C669LOADER_PATTERN_BYTES = 1536 ' 64 rows * 8 channels * 3 bytes
CONST __C669LOADER_MAX_SAMPLES = 64
CONST __C669LOADER_MAX_PATTERNS = 128
CONST __C669LOADER_C2SPD = 8363
CONST __C669LOADER_DEFAULT_BPM = 78
CONST __C669LOADER_DEFAULT_SPEED = 4

''' @brief Parses and loads a Composer 669 / UNIS 669 module from a memory buffer.
''' @param player The MOD player instance.
''' @param buffer In-memory binary representation of the 669 file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION C669Loader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    IF StringFile_GetSize(memFile) < __C669LOADER_HEADER_SIZE THEN EXIT FUNCTION

    DIM magic AS STRING: magic = StringFile_ReadString(memFile, 2)
    IF magic <> __C669LOADER_MAGIC_STD _ANDALSO magic <> __C669LOADER_MAGIC_EXT THEN EXIT FUNCTION

    DIM isExtended AS _BYTE: isExtended = (magic = __C669LOADER_MAGIC_EXT)

    DIM songMessage AS STRING: songMessage = StringFile_ReadString(memFile, 108)

    DIM numSamples AS _UNSIGNED _BYTE: numSamples = StringFile_ReadByte(memFile)
    IF numSamples > __C669LOADER_MAX_SAMPLES THEN EXIT FUNCTION

    DIM numPatterns AS _UNSIGNED _BYTE: numPatterns = StringFile_ReadByte(memFile)
    IF numPatterns > __C669LOADER_MAX_PATTERNS THEN EXIT FUNCTION

    DIM restartPos AS _UNSIGNED _BYTE: restartPos = StringFile_ReadByte(memFile)
    IF restartPos >= 128 THEN EXIT FUNCTION

    ' Read orders (128 bytes)
    DIM rawOrders(0 TO 127) AS _UNSIGNED _BYTE
    DIM oIdx AS LONG: FOR oIdx = 0 TO 127
        rawOrders(oIdx) = StringFile_ReadByte(memFile)
    NEXT oIdx

    ' Read tempo list (128 bytes)
    DIM tempoList(0 TO 127) AS _UNSIGNED _BYTE
    FOR oIdx = 0 TO 127
        tempoList(oIdx) = StringFile_ReadByte(memFile)
    NEXT oIdx

    ' Read breaks list (128 bytes)
    DIM breaksList(0 TO 127) AS _UNSIGNED _BYTE
    FOR oIdx = 0 TO 127
        breaksList(oIdx) = StringFile_ReadByte(memFile)
    NEXT oIdx

    ' Header validation matching OpenMPT ValidateHeader
    FOR oIdx = 0 TO 127
        IF rawOrders(oIdx) >= 128 _ANDALSO rawOrders(oIdx) < &HFE THEN EXIT FUNCTION
        IF rawOrders(oIdx) < 128 _ANDALSO tempoList(oIdx) = 0 THEN EXIT FUNCTION
        IF tempoList(oIdx) > 15 THEN EXIT FUNCTION
        IF breaksList(oIdx) >= 64 THEN EXIT FUNCTION
    NEXT oIdx

    ' Minimum required additional file size
    DIM minSize AS _UNSIGNED LONG
    minSize = __C669LOADER_HEADER_SIZE + CLNG(numSamples) * __C669LOADER_SAMPLE_HEADER_SIZE + CLNG(numPatterns) * __C669LOADER_PATTERN_BYTES
    IF StringFile_GetSize(memFile) < minSize THEN EXIT FUNCTION

    ' Initialize audio synthesis engine
    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION
    __MODPlayer_InitializeSong player

    ' Set song title from message line 1 (36 chars)
    player.song.caption = String_MakePrintable(String_ConvertToBStr(MID$(songMessage, 1, 36)))
    IF LEN(_TRIM$(player.song.caption)) = 0 THEN
        player.song.caption = "Untitled"
    END IF

    player.song.channels = __C669LOADER_CHANNELS
    player.song.subtype = "669 "
    player.song.isStereo = _TRUE
    player.song.pcmMasterGain = 64.0! / 128.0!

    ' Determine number of valid orders
    DIM numOrders AS LONG: numOrders = 0
    FOR oIdx = 0 TO 127
        IF rawOrders(oIdx) < numPatterns AND rawOrders(oIdx) < 128 THEN
            numOrders = numOrders + 1
        ELSE
            EXIT FOR
        END IF
    NEXT oIdx

    IF numOrders = 0 THEN numOrders = 1

    player.song.orders = numOrders
    REDIM player.order(0 TO player.song.orders - 1) AS _UNSIGNED INTEGER
    FOR oIdx = 0 TO player.song.orders - 1
        player.order(oIdx) = rawOrders(oIdx)
    NEXT oIdx

    IF restartPos < player.song.orders THEN
        player.song.endJumpOrder = restartPos
    ELSE
        player.song.endJumpOrder = 0
    END IF

    ' Read sample headers
    player.song.instruments = numSamples
    IF player.song.instruments > 0 THEN
        REDIM player.instrument(0 TO player.song.instruments - 1) AS __MODPLAYERINSTRUMENT
    ELSE
        REDIM player.instrument(0 TO 0) AS __MODPLAYERINSTRUMENT
    END IF

    DIM sIdx AS LONG: FOR sIdx = 0 TO player.song.instruments - 1
        DIM filename AS STRING: filename = StringFile_ReadString(memFile, 13)
        DIM smpLength AS _UNSIGNED LONG: smpLength = StringFile_ReadLong(memFile)
        DIM loopStart AS _UNSIGNED LONG: loopStart = StringFile_ReadLong(memFile)
        DIM loopEnd AS _UNSIGNED LONG: loopEnd = StringFile_ReadLong(memFile)

        ' Validate reasonable sample length
        IF smpLength >= &H4000000 THEN EXIT FUNCTION

        player.instrument(sIdx).caption = String_MakePrintable(String_ConvertToBStr(filename))
        player.instrument(sIdx).length = smpLength
        player.instrument(sIdx).c2Spd = __C669LOADER_C2SPD
        player.instrument(sIdx).volume = 64
        player.instrument(sIdx).bytesPerSample = _SIZE_OF_BYTE
        player.instrument(sIdx).subtype = __MODPLAYER_INSTRUMENT_PCM

        ' 669 Loop handling:
        IF loopEnd < &HFFFFF _ANDALSO loopEnd > 0 _ANDALSO loopEnd <= smpLength _ANDALSO loopStart < loopEnd THEN
            player.instrument(sIdx).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
            player.instrument(sIdx).loopStart = loopStart
            player.instrument(sIdx).loopEnd = loopEnd
        ELSE
            player.instrument(sIdx).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            player.instrument(sIdx).loopStart = 0
            player.instrument(sIdx).loopEnd = smpLength
        END IF
    NEXT sIdx

    ' Read patterns
    player.song.patterns = numPatterns
    IF player.song.patterns > 0 THEN
        REDIM player.pattern(0 TO player.song.patterns - 1) AS __MODPLAYERPATTERN
    ELSE
        REDIM player.pattern(0 TO 0) AS __MODPLAYERPATTERN
    END IF

    DIM p AS LONG, r AS LONG, ch AS LONG
    FOR p = 0 TO player.song.patterns - 1
        DIM pRows AS LONG
        IF breaksList(p) < 63 THEN
            pRows = breaksList(p) + 1
        ELSE
            pRows = 64
        END IF
        IF pRows <= 0 THEN pRows = 64

        player.pattern(p).rows = pRows
        REDIM player.pattern(p).note(0 TO pRows - 1, 0 TO __C669LOADER_CHANNELS - 1) AS __MODPLAYERNOTE

        FOR r = 0 TO 63
            FOR ch = 0 TO __C669LOADER_CHANNELS - 1
                DIM b0 AS _UNSIGNED _BYTE: b0 = StringFile_ReadByte(memFile)
                DIM b1 AS _UNSIGNED _BYTE: b1 = StringFile_ReadByte(memFile)
                DIM b2 AS _UNSIGNED _BYTE: b2 = StringFile_ReadByte(memFile)

                IF r < pRows THEN
                    DIM nNote AS _UNSIGNED _BYTE: nNote = _SHR(b0, 2)
                    DIM nInstr AS _UNSIGNED _BYTE: nInstr = _SHL(b0 AND &H03, 4) OR _SHR(b1, 4)
                    DIM nVol AS _UNSIGNED _BYTE: nVol = b1 AND &H0F

                    IF b0 < &HFE THEN
                        player.pattern(p).note(r, ch).note = nNote + 36
                        player.pattern(p).note(r, ch).instrument = nInstr + 1
                    ELSE
                        player.pattern(p).note(r, ch).note = __MODPLAYER_NOTE_NONE
                        player.pattern(p).note(r, ch).instrument = 0
                    END IF

                    IF b0 <= &HFE THEN
                        player.pattern(p).note(r, ch).volume = (CLNG(nVol) * 64 + 8) \ 15
                    ELSE
                        player.pattern(p).note(r, ch).volume = __MODPLAYER_NOTE_NO_VOLUME
                    END IF

                    IF b2 <> &HFF THEN
                        DIM cmd AS _UNSIGNED _BYTE: cmd = _SHR(b2, 4)
                        DIM param AS _UNSIGNED _BYTE: param = b2 AND &H0F

                        SELECT CASE cmd
                            CASE 0 ' Portamento up
                                player.pattern(p).note(r, ch).effect = 1
                                player.pattern(p).note(r, ch).operand = param

                            CASE 1 ' Portamento down
                                player.pattern(p).note(r, ch).effect = 2
                                player.pattern(p).note(r, ch).operand = param

                            CASE 2 ' Tone portamento
                                player.pattern(p).note(r, ch).effect = 3
                                player.pattern(p).note(r, ch).operand = param

                            CASE 3 ' Frequency adjust (fine portamento up)
                                player.pattern(p).note(r, ch).effect = &H0E
                                player.pattern(p).note(r, ch).operand = &H10 OR param

                            CASE 4 ' Vibrato
                                player.pattern(p).note(r, ch).effect = 4
                                player.pattern(p).note(r, ch).operand = _SHL(param, 4) OR param

                            CASE 5 ' Set speed (ticks per row)
                                player.pattern(p).note(r, ch).effect = &H0F
                                player.pattern(p).note(r, ch).operand = param

                            CASE 6 ' Extended UNIS 669: balance fine slide
                                IF isExtended THEN
                                    IF param = 0 THEN
                                        player.pattern(p).note(r, ch).effect = &H18
                                        player.pattern(p).note(r, ch).operand = 0
                                    ELSEIF param = 1 THEN
                                        player.pattern(p).note(r, ch).effect = &H18
                                        player.pattern(p).note(r, ch).operand = 255
                                    END IF
                                END IF

                            CASE 7 ' Extended UNIS 669: slot retrig
                                IF isExtended THEN
                                    player.pattern(p).note(r, ch).effect = &H0E
                                    player.pattern(p).note(r, ch).operand = &H90 OR param
                                END IF

                            CASE ELSE
                                player.pattern(p).note(r, ch).effect = 0
                                player.pattern(p).note(r, ch).operand = 0
                        END SELECT
                    ELSE
                        player.pattern(p).note(r, ch).effect = 0
                        player.pattern(p).note(r, ch).operand = 0
                    END IF
                END IF
            NEXT ch
        NEXT r

        ' Inject pattern default speed from tempoList(p) onto row 0 if no speed effect already present
        IF tempoList(p) > 0 THEN
            DIM hasSpeedEff AS _BYTE: hasSpeedEff = _FALSE
            FOR ch = 0 TO __C669LOADER_CHANNELS - 1
                IF player.pattern(p).note(0, ch).effect = &H0F THEN
                    hasSpeedEff = _TRUE
                    EXIT FOR
                END IF
            NEXT ch
            IF NOT hasSpeedEff THEN
                FOR ch = __C669LOADER_CHANNELS - 1 TO 0 STEP -1
                    IF player.pattern(p).note(0, ch).effect = 0 THEN
                        player.pattern(p).note(0, ch).effect = &H0F
                        player.pattern(p).note(0, ch).operand = tempoList(p)
                        EXIT FOR
                    END IF
                NEXT ch
            END IF
        END IF
    NEXT p

    ' Load sample data into SoftSynth
    FOR sIdx = 0 TO player.song.instruments - 1
        IF player.instrument(sIdx).length > 0 THEN
            IF StringFile_GetPosition(memFile) < StringFile_GetSize(memFile) THEN
                DIM readBytes AS _UNSIGNED LONG
                readBytes = _MIN(player.instrument(sIdx).length, StringFile_GetSize(memFile) - StringFile_GetPosition(memFile))
                DIM sampleData AS STRING: sampleData = StringFile_ReadString(memFile, readBytes)
                IF LEN(sampleData) < player.instrument(sIdx).length THEN
                    sampleData = sampleData + STRING$(player.instrument(sIdx).length - LEN(sampleData), 128)
                END IF
                ' 669 samples are 8-bit unsigned PCM - convert to signed S8 for SoftSynth
                AudioConv_ConvertU8ToS8 sampleData
                SoftSynth_LoadSound player.synth, sIdx, sampleData, _SIZE_OF_BYTE, 1
            END IF
        END IF
    NEXT sIdx

    ' Setup channels
    SoftSynth_SetTotalVoices player.synth, __C669LOADER_CHANNELS
    REDIM player.channel(0 TO __C669LOADER_CHANNELS - 1) AS __MODPLAYERCHANNEL

    FOR ch = 0 TO __C669LOADER_CHANNELS - 1
        player.channel(ch).subtype = __MODPLAYER_INSTRUMENT_PCM
        player.channel(ch).channelVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX

        ' Panning: alternating Left (0x30 = 48) and Right (0xD0 = 208)
        IF (ch AND 1) = 0 THEN
            player.channel(ch).panning = 48
            player.channel(ch).defaultPanning = 48
            SoftSynth_SetVoiceBalance player.synth, ch, -__MODPLAYER_STEREO_SEPARATION
        ELSE
            player.channel(ch).panning = 208
            player.channel(ch).defaultPanning = 208
            SoftSynth_SetVoiceBalance player.synth, ch, __MODPLAYER_STEREO_SEPARATION
        END IF
    NEXT ch

    __MODPlayer_LoadTables

    ' Initial playback speed and BPM
    DIM initSpeed AS _UNSIGNED _BYTE: initSpeed = __C669LOADER_DEFAULT_SPEED
    IF player.song.orders > 0 THEN
        DIM firstPat AS LONG: firstPat = player.order(0)
        IF firstPat < player.song.patterns AND tempoList(firstPat) > 0 THEN
            initSpeed = tempoList(firstPat)
        END IF
    END IF

    player.song.speed = initSpeed
    player.song.defaultSpeed = initSpeed
    player.song.BPM = __C669LOADER_DEFAULT_BPM
    player.song.defaultBPM = __C669LOADER_DEFAULT_BPM

    player.initialized = _TRUE

    C669Loader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Parses and loads a Composer 669 / UNIS 669 module from a disk file.
''' @param player The MOD player instance.
''' @param fileName Path to the 669 file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION C669Loader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    C669Loader_LoadFromDisk = C669Loader_LoadFromMemory(player, File_Load(fileName))
END FUNCTION
