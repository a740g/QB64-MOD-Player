'-----------------------------------------------------------------------------------------------------------------------
' Advanced Music Format (AMF / DSMI / Asylum) Loader
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MODPlayer.bi'
'$INCLUDE:'SoftSynth.bi'
'$INCLUDE:'String.bi'
'$INCLUDE:'AudioConv.bi'
'$INCLUDE:'StringFile.bi'
'$INCLUDE:'File.bi'
'$INCLUDE:'MODPlayerShared.bm'

CONST __AMFLOADER_MAGIC = "AMF"
CONST __AMFLOADER_ASYLUM_MAGIC = "ASYLUM Music Format V1.0"
CONST __AMFLOADER_ASYLUM_HEADER_SIG = __AMFLOADER_ASYLUM_MAGIC + _CHR_NUL

''' @brief Translates an AMF effect command and parameter into the unified replayer note structure.
''' @param noteCell The target note cell to update.
''' @param cmd AMF command byte (e.g. &H81 to &H97).
''' @param param AMF parameter byte.
SUB __AMFLoader_TranslateEffect (noteCell AS __MODPlayerNote, cmd AS _UNSIGNED _BYTE, param AS _UNSIGNED _BYTE)
    DIM maskedCmd AS _UNSIGNED _BYTE: maskedCmd = cmd AND &H7F
    DIM signedParam AS INTEGER
    IF param >= 128 THEN signedParam = CINT(param) - 256 ELSE signedParam = param

    SELECT CASE maskedCmd
        CASE &H01 ' Speed (ticks per row)
            noteCell.effect = __MODPLAYER_FX_SPEED
            noteCell.operand = param

        CASE &H02 ' Volume slide
            noteCell.effect = __MODPLAYER_FX_VOLUME_SLIDE
            IF signedParam > 0 THEN
                noteCell.operand = _SHL(param AND &H0F, 4)
            ELSE
                noteCell.operand = (-signedParam) AND &H0F
            END IF

        CASE &H03 ' Set Volume
            noteCell.volume = _MIN(param, 64)

        CASE &H04 ' Portamento Up / Down
            IF signedParam >= 0 THEN
                noteCell.effect = __MODPLAYER_FX_PORTAMENTO_DOWN
                noteCell.operand = param
            ELSE
                noteCell.effect = __MODPLAYER_FX_PORTAMENTO_UP
                noteCell.operand = (-signedParam) AND &H7F
            END IF

        CASE &H06 ' Tone Portamento (Porta to note)
            noteCell.effect = __MODPLAYER_FX_PORTAMENTO
            noteCell.operand = param

        CASE &H07 ' Tremor
            noteCell.effect = __MODPLAYER_FX_TREMOR
            noteCell.operand = param

        CASE &H08 ' Arpeggio
            noteCell.effect = __MODPLAYER_FX_ARPEGGIO
            noteCell.operand = param

        CASE &H09 ' Vibrato
            noteCell.effect = __MODPLAYER_FX_VIBRATO
            noteCell.operand = param

        CASE &H0A ' Tone Portamento + Volume Slide
            noteCell.effect = __MODPLAYER_FX_PORTAMENTO_VOLUME_SLIDE
            IF signedParam > 0 THEN
                noteCell.operand = _SHL(param AND &H0F, 4)
            ELSE
                noteCell.operand = (-signedParam) AND &H0F
            END IF

        CASE &H0B ' Vibrato + Volume Slide
            noteCell.effect = __MODPLAYER_FX_VIBRATO_VOLUME_SLIDE
            IF signedParam > 0 THEN
                noteCell.operand = _SHL(param AND &H0F, 4)
            ELSE
                noteCell.operand = (-signedParam) AND &H0F
            END IF

        CASE &H0C ' Pattern Break
            noteCell.effect = __MODPLAYER_FX_PATTERN_BREAK
            noteCell.operand = param

        CASE &H0D ' Position Jump
            noteCell.effect = __MODPLAYER_FX_POSITION_JUMP
            noteCell.operand = param

        CASE &H0F ' Retrigger
            noteCell.effect = __MODPLAYER_FX_EXT
            noteCell.operand = &H90 OR (param AND &H0F)

        CASE &H10 ' Sample Offset
            noteCell.effect = __MODPLAYER_FX_SAMPLE_OFFSET
            noteCell.operand = param

        CASE &H11 ' Fine Volume Slide
            noteCell.effect = __MODPLAYER_FX_EXT
            IF signedParam > 0 THEN
                noteCell.operand = &HA0 OR (param AND &H0F)
            ELSE
                noteCell.operand = &HB0 OR ((-signedParam) AND &H0F)
            END IF

        CASE &H12 ' Fine Portamento
            noteCell.effect = __MODPLAYER_FX_EXT
            IF signedParam < 0 THEN
                noteCell.operand = &H10 OR ((-signedParam) AND &H0F)
            ELSE
                noteCell.operand = &H20 OR (param AND &H0F)
            END IF

        CASE &H13 ' Note Delay
            noteCell.effect = __MODPLAYER_FX_EXT
            noteCell.operand = &HD0 OR (param AND &H0F)

        CASE &H14 ' Note Cut
            noteCell.effect = __MODPLAYER_FX_EXT
            noteCell.operand = &HC0 OR (param AND &H0F)

        CASE &H15 ' Set Tempo (BPM)
            noteCell.effect = __MODPLAYER_FX_TEMPO
            IF param < 32 THEN noteCell.operand = 32 ELSE noteCell.operand = param

        CASE &H16 ' Extra Fine Portamento
            IF signedParam < 0 THEN
                noteCell.effect = __MODPLAYER_FX_PORTA_EXTRA_FINE_UP
                noteCell.operand = &HE0 OR ((-signedParam) AND &H0F)
            ELSE
                noteCell.effect = __MODPLAYER_FX_PORTA_EXTRA_FINE_DOWN
                noteCell.operand = &HE0 OR (param AND &H0F)
            END IF

        CASE &H17 ' Panning
            IF param = 100 THEN
                noteCell.effect = __MODPLAYER_FX_PANNING_8
                noteCell.operand = 128
            ELSE
                noteCell.effect = __MODPLAYER_FX_PANNING_8
                noteCell.operand = _CLAMP((signedParam + 64) * 2, 0, 255)
            END IF
    END SELECT
END SUB

''' @brief Parses and loads a DSMI AMF module from an initialized StringFile buffer.
''' @param player The MOD player instance.
''' @param memFile The StringFile handle.
''' @param buffer The complete binary buffer.
''' @param version The AMF version byte (1 or 8..14).
''' @return _TRUE on success, _FALSE on failure.
FUNCTION __AMFLoader_LoadDSMI%% (player AS MODPlayer, memFile AS StringFile, buffer AS STRING, version AS _UNSIGNED _BYTE)
    DIM bufSize AS _UNSIGNED LONG: bufSize = StringFile_GetSize(memFile)
    IF bufSize < 41 THEN EXIT FUNCTION

    DIM songTitle AS STRING: songTitle = String_MakePrintable(StringFile_ReadString(memFile, 32))
    DIM numSamples AS _UNSIGNED _BYTE: numSamples = StringFile_ReadByte(memFile)
    DIM numOrders AS _UNSIGNED _BYTE: numOrders = StringFile_ReadByte(memFile)
    DIM numTracks AS _UNSIGNED INTEGER: numTracks = StringFile_ReadInteger(memFile)
    DIM numChannels AS _UNSIGNED _BYTE
    IF version >= 9 THEN
        numChannels = StringFile_ReadByte(memFile)
    ELSE
        numChannels = 4
    END IF

    ' Sanity checks
    IF numSamples = 0 _ORELSE numOrders = 0 _ORELSE numTracks = 0 THEN EXIT FUNCTION
    IF numChannels = 0 _ORELSE numChannels > 32 THEN EXIT FUNCTION

    ' Initialize SoftSynth
    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION
    __MODPlayer_InitializeSong player

    ' Skip channel remap table in v9/v10
    IF version = 9 _ORELSE version = 10 THEN
        IF StringFile_GetPosition(memFile) + 16 > bufSize THEN EXIT FUNCTION
        StringFile_Seek memFile, StringFile_GetPosition(memFile) + 16
    END IF

    ' Channel panning table in v11+
    DIM chnPanning(0 TO 31) AS INTEGER
    DIM ch AS LONG
    FOR ch = 0 TO 31
        chnPanning(ch) = -1
    NEXT ch

    IF version >= 11 THEN
        DIM panLen AS LONG: panLen = 16
        IF version >= 12 THEN panLen = 32
        IF StringFile_GetPosition(memFile) + panLen > bufSize THEN EXIT FUNCTION
        FOR ch = 0 TO panLen - 1
            DIM rawPanByte AS _UNSIGNED _BYTE: rawPanByte = StringFile_ReadByte(memFile)
            IF rawPanByte = 100 THEN
                chnPanning(ch) = 128
            ELSE
                DIM signedPan AS INTEGER
                IF rawPanByte >= 128 THEN signedPan = CINT(rawPanByte) - 256 ELSE signedPan = rawPanByte
                chnPanning(ch) = _CLAMP((signedPan + 64) * 2, 0, 255)
            END IF
        NEXT ch
    END IF

    ' Tempo and speed in v13+
    DIM defaultTempo AS _UNSIGNED _BYTE: defaultTempo = 125
    DIM defaultSpeed AS _UNSIGNED _BYTE: defaultSpeed = 6
    IF version >= 13 THEN
        IF StringFile_GetPosition(memFile) + 2 > bufSize THEN EXIT FUNCTION
        defaultTempo = StringFile_ReadByte(memFile)
        defaultSpeed = StringFile_ReadByte(memFile)
        IF defaultTempo < 32 THEN defaultTempo = 125
        IF defaultSpeed = 0 THEN defaultSpeed = 6
    END IF

    ' Orders and track assignments
    DIM orderTrack(0 TO numOrders - 1, 0 TO numChannels - 1) AS _UNSIGNED INTEGER
    DIM orderRows(0 TO numOrders - 1) AS _UNSIGNED INTEGER

    DIM ord AS LONG
    FOR ord = 0 TO numOrders - 1
        IF version >= 14 THEN
            IF StringFile_GetPosition(memFile) + 2 > bufSize THEN EXIT FUNCTION
            orderRows(ord) = StringFile_ReadInteger(memFile)
            IF orderRows(ord) = 0 _ORELSE orderRows(ord) > 256 THEN orderRows(ord) = 64
        ELSE
            orderRows(ord) = 64
        END IF

        IF StringFile_GetPosition(memFile) + (CLNG(numChannels) * 2) > bufSize THEN EXIT FUNCTION
        FOR ch = 0 TO numChannels - 1
            orderTrack(ord, ch) = StringFile_ReadInteger(memFile)
        NEXT ch
    NEXT ord

    ' Sample headers
    DIM isTruncatedV10 AS _BYTE
    IF version = 10 THEN
        DIM probePos AS _UNSIGNED LONG: probePos = StringFile_GetPosition(memFile)
        DIM testSmp AS LONG
        FOR testSmp = 0 TO numSamples - 1
            IF probePos + 65 > bufSize THEN isTruncatedV10 = _TRUE: EXIT FOR
            DIM pType AS _UNSIGNED _BYTE: pType = ASC(buffer, probePos + 1)
            IF pType > 1 THEN isTruncatedV10 = _TRUE: EXIT FOR
            DIM pIdx AS _UNSIGNED LONG: pIdx = CVL(MID$(buffer, probePos + 46 + 1, 4))
            IF pIdx > numSamples THEN isTruncatedV10 = _TRUE: EXIT FOR
            DIM pLen AS _UNSIGNED LONG: pLen = CVL(MID$(buffer, probePos + 50 + 1, 4))
            IF pLen > &H100000 THEN isTruncatedV10 = _TRUE: EXIT FOR
            DIM pVol AS _UNSIGNED _BYTE: pVol = ASC(buffer, probePos + 56 + 1)
            IF pVol > 64 THEN isTruncatedV10 = _TRUE: EXIT FOR
            probePos = probePos + 65
        NEXT testSmp
    END IF

    DIM smpHdrSize AS LONG
    IF version < 10 _ORELSE isTruncatedV10 THEN smpHdrSize = 59 ELSE smpHdrSize = 65

    player.song.instruments = numSamples
    REDIM player.instrument(0 TO numSamples - 1) AS __MODPLAYERINSTRUMENT
    DIM sampleIndexMap(0 TO numSamples - 1) AS _UNSIGNED LONG

    DIM s AS LONG
    FOR s = 0 TO numSamples - 1
        IF StringFile_GetPosition(memFile) + smpHdrSize > bufSize THEN EXIT FUNCTION
        DIM smpType AS _UNSIGNED _BYTE: smpType = StringFile_ReadByte(memFile)
        DIM smpName AS STRING: smpName = String_MakePrintable(StringFile_ReadString(memFile, 32))
        DIM smpFilename AS STRING: smpFilename = String_MakePrintable(StringFile_ReadString(memFile, 13))
        DIM smpIdx AS _UNSIGNED LONG: smpIdx = StringFile_ReadLong(memFile)
        sampleIndexMap(s) = smpIdx

        DIM smpLen AS _UNSIGNED LONG
        DIM smpC2Spd AS _UNSIGNED INTEGER
        DIM smpVol AS _UNSIGNED _BYTE
        DIM smpLoopStart AS _UNSIGNED LONG
        DIM smpLoopEnd AS _UNSIGNED LONG

        IF version < 10 THEN
            smpLen = StringFile_ReadInteger(memFile)
            smpC2Spd = StringFile_ReadInteger(memFile)
            smpVol = StringFile_ReadByte(memFile)
            smpLoopStart = StringFile_ReadInteger(memFile)
            smpLoopEnd = StringFile_ReadInteger(memFile)
            IF smpLoopEnd = &HFFFF THEN smpLoopEnd = 0: smpLoopStart = 0
        ELSEIF isTruncatedV10 THEN
            smpLen = StringFile_ReadLong(memFile)
            smpC2Spd = StringFile_ReadInteger(memFile)
            smpVol = StringFile_ReadByte(memFile)
            smpLoopStart = StringFile_ReadInteger(memFile)
            smpLoopEnd = smpLen
        ELSE
            smpLen = StringFile_ReadLong(memFile)
            smpC2Spd = StringFile_ReadInteger(memFile)
            smpVol = StringFile_ReadByte(memFile)
            smpLoopStart = StringFile_ReadLong(memFile)
            smpLoopEnd = StringFile_ReadLong(memFile)
        END IF

        player.instrument(s).caption = smpName
        IF LEN(player.instrument(s).caption) = 0 THEN player.instrument(s).caption = smpFilename
        player.instrument(s).length = smpLen
        IF smpC2Spd = 0 THEN smpC2Spd = 8363
        player.instrument(s).c2Spd = smpC2Spd
        player.instrument(s).volume = _MIN(smpVol, 64)
        player.instrument(s).subtype = __MODPLAYER_INSTRUMENT_PCM
        player.instrument(s).bytesPerSample = 1
        player.instrument(s).channels = 1

        DIM hasLoop AS _BYTE
        hasLoop = (smpType <> 0 _ANDALSO smpLoopEnd > smpLoopStart + 2 _ANDALSO smpLoopEnd <= smpLen)
        IF hasLoop THEN
            player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
            player.instrument(s).loopStart = smpLoopStart
            player.instrument(s).loopEnd = smpLoopEnd
        ELSE
            player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            player.instrument(s).loopStart = 0
            player.instrument(s).loopEnd = smpLen
        END IF
    NEXT s

    ' Track mapping table
    IF StringFile_GetPosition(memFile) + (CLNG(numTracks) * 2) > bufSize THEN EXIT FUNCTION
    REDIM trackMap(0 TO numTracks - 1) AS _UNSIGNED INTEGER
    DIM maxPhysicalTrack AS _UNSIGNED INTEGER
    DIM t AS LONG
    FOR t = 0 TO numTracks - 1
        trackMap(t) = StringFile_ReadInteger(memFile)
        IF trackMap(t) > maxPhysicalTrack THEN maxPhysicalTrack = trackMap(t)
    NEXT t

    ' Physical tracks
    REDIM trackData(0 TO maxPhysicalTrack) AS STRING
    FOR t = 1 TO maxPhysicalTrack
        IF StringFile_GetPosition(memFile) + 3 > bufSize THEN EXIT FUNCTION
        DIM numEvents AS _UNSIGNED INTEGER: numEvents = StringFile_ReadInteger(memFile)
        DIM trkType AS _UNSIGNED _BYTE: trkType = StringFile_ReadByte(memFile)
        DIM trackBytes AS LONG: trackBytes = CLNG(numEvents) * 3
        IF version = 1 _ANDALSO numEvents > 0 THEN trackBytes = trackBytes + 3
        IF trackBytes > 0 THEN
            IF StringFile_GetPosition(memFile) + trackBytes > bufSize THEN EXIT FUNCTION
            trackData(t) = StringFile_ReadString(memFile, trackBytes)
        ELSE
            trackData(t) = _STR_EMPTY
        END IF
    NEXT t

    ' Read sample PCM data (8-bit unsigned PCM)
    FOR smpIdx = 1 TO numSamples
        IF StringFile_GetPosition(memFile) >= bufSize THEN EXIT FOR
        DIM targetInst AS LONG: targetInst = -1
        FOR s = 0 TO numSamples - 1
            IF sampleIndexMap(s) = smpIdx THEN
                targetInst = s
                EXIT FOR
            END IF
        NEXT s

        IF targetInst >= 0 _ANDALSO player.instrument(targetInst).length > 0 THEN
            DIM targetLen AS _UNSIGNED LONG: targetLen = player.instrument(targetInst).length
            IF StringFile_GetPosition(memFile) + targetLen <= bufSize THEN
                DIM sampRaw AS STRING: sampRaw = StringFile_ReadString(memFile, targetLen)
                AudioConv_ConvertU8ToS8 sampRaw
                SoftSynth_LoadSound player.synth, targetInst, sampRaw, 1, 1

                ' Replicate across any duplicate instrument references sharing this sample index
                FOR s = targetInst + 1 TO numSamples - 1
                    IF sampleIndexMap(s) = smpIdx _ANDALSO player.instrument(s).length = targetLen THEN
                        SoftSynth_LoadSound player.synth, s, sampRaw, 1, 1
                    END IF
                NEXT s
            ELSE
                EXIT FOR
            END IF
        END IF
    NEXT smpIdx

    ' Populate patterns
    player.song.orders = numOrders
    player.song.patterns = numOrders
    REDIM player.order(0 TO numOrders - 1) AS _UNSIGNED INTEGER
    REDIM player.pattern(0 TO numOrders - 1) AS __MODPLAYERPATTERN

    FOR ord = 0 TO numOrders - 1
        player.order(ord) = ord
        DIM patRows AS _UNSIGNED INTEGER: patRows = orderRows(ord)
        player.pattern(ord).rows = patRows
        REDIM player.pattern(ord).note(0 TO patRows - 1, 0 TO numChannels - 1) AS __MODPLAYERNOTE

        DIM r AS LONG
        FOR r = 0 TO patRows - 1
            FOR ch = 0 TO numChannels - 1
                player.pattern(ord).note(r, ch).note = __MODPLAYER_NOTE_NONE
                player.pattern(ord).note(r, ch).instrument = 0
                player.pattern(ord).note(r, ch).volume = __MODPLAYER_NOTE_NO_VOLUME
                player.pattern(ord).note(r, ch).effect = 0
                player.pattern(ord).note(r, ch).operand = 0
            NEXT ch
        NEXT r

        FOR ch = 0 TO numChannels - 1
            DIM logicalTrk AS _UNSIGNED INTEGER: logicalTrk = orderTrack(ord, ch)
            IF logicalTrk > 0 _ANDALSO logicalTrk <= numTracks THEN
                DIM physTrk AS _UNSIGNED INTEGER: physTrk = trackMap(logicalTrk - 1)
                IF physTrk > 0 _ANDALSO physTrk <= maxPhysicalTrack THEN
                    DIM trkBytesStr AS STRING: trkBytesStr = trackData(physTrk)
                    DIM evOffset AS LONG: evOffset = 1
                    DIM evLen AS LONG: evLen = LEN(trkBytesStr)
                    WHILE evOffset + 2 <= evLen
                        DIM evRow AS _UNSIGNED _BYTE: evRow = ASC(trkBytesStr, evOffset)
                        DIM evCmd AS _UNSIGNED _BYTE: evCmd = ASC(trkBytesStr, evOffset + 1)
                        DIM evVal AS _UNSIGNED _BYTE: evVal = ASC(trkBytesStr, evOffset + 2)
                        evOffset = evOffset + 3

                        IF evRow = 255 _ANDALSO evCmd = 255 _ANDALSO evVal = 255 THEN EXIT WHILE
                        IF evRow < patRows THEN
                            IF evCmd < &H7F THEN
                                IF evCmd = 0 _ANDALSO evVal = 0 THEN
                                    player.pattern(ord).note(evRow, ch).effect = __MODPLAYER_FX_EXT
                                    player.pattern(ord).note(evRow, ch).operand = &HC0
                                ELSE
                                    player.pattern(ord).note(evRow, ch).note = evCmd
                                    IF evVal <> 255 THEN
                                        player.pattern(ord).note(evRow, ch).volume = _MIN(evVal, 64)
                                    END IF
                                END IF
                            ELSEIF evCmd = &H80 THEN
                                player.pattern(ord).note(evRow, ch).instrument = CLNG(evVal) + 1
                            ELSEIF evCmd > &H80 THEN
                                __AMFLoader_TranslateEffect player.pattern(ord).note(evRow, ch), evCmd, evVal
                            END IF
                        END IF
                    WEND
                END IF
            END IF
        NEXT ch
    NEXT ord

    ' Channel configuration
    player.song.channels = numChannels
    REDIM player.channel(0 TO numChannels - 1) AS __MODPLAYERCHANNEL
    SoftSynth_SetTotalVoices player.synth, numChannels
    FOR ch = 0 TO numChannels - 1
        player.channel(ch).subtype = __MODPLAYER_INSTRUMENT_PCM
        player.channel(ch).volume = 64
        player.channel(ch).channelVolume = 64
        IF chnPanning(ch) >= 0 THEN
            player.channel(ch).panning = chnPanning(ch)
        ELSE
            IF (ch AND 1) = 0 THEN player.channel(ch).panning = 64 ELSE player.channel(ch).panning = 192
        END IF
        player.channel(ch).defaultPanning = player.channel(ch).panning
    NEXT ch

    player.song.caption = songTitle
    player.song.subtype = "AMF"
    player.song.format = MODPLAYER_FORMAT_AMF
    player.song.pcmMasterGain = 48.0! / 128.0!
    player.song.isStereo = _TRUE
    player.song.hasFMChannels = _FALSE
    player.song.defaultSpeed = defaultSpeed
    player.song.defaultBPM = defaultTempo
    player.song.speed = defaultSpeed
    player.song.BPM = defaultTempo
    player.song.tick = player.song.speed
    player.song.defaultGlobalVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX
    player.song.globalVolume = player.song.defaultGlobalVolume
    SoftSynth_SetGlobalVolume player.synth, 1.0!

    __MODPlayer_LoadTables
    player.initialized = _TRUE
    __AMFLoader_LoadDSMI = _TRUE
END FUNCTION

''' @brief Parses and loads an ASYLUM AMF module from an initialized StringFile buffer.
''' @param player The MOD player instance.
''' @param memFile The StringFile handle.
''' @param buffer The complete binary buffer.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION __AMFLoader_LoadAsylum%% (player AS MODPlayer, memFile AS StringFile)
    DIM bufSize AS _UNSIGNED LONG: bufSize = StringFile_GetSize(memFile)
    IF bufSize < 38 THEN EXIT FUNCTION

    StringFile_Seek memFile, 32 ' Skip 32-byte signature
    DIM defaultSpeed AS _UNSIGNED _BYTE: defaultSpeed = StringFile_ReadByte(memFile)
    DIM defaultTempo AS _UNSIGNED _BYTE: defaultTempo = StringFile_ReadByte(memFile)
    DIM numSamples AS _UNSIGNED _BYTE: numSamples = StringFile_ReadByte(memFile)
    DIM numPatterns AS _UNSIGNED _BYTE: numPatterns = StringFile_ReadByte(memFile)
    DIM numOrders AS _UNSIGNED _BYTE: numOrders = StringFile_ReadByte(memFile)
    DIM restartPos AS _UNSIGNED _BYTE: restartPos = StringFile_ReadByte(memFile)

    IF numSamples = 0 _ORELSE numSamples > 64 _ORELSE numPatterns = 0 _ORELSE numOrders = 0 THEN EXIT FUNCTION

    DIM minRequiredSize AS _UNSIGNED LONG
    minRequiredSize = 38 + 256 + (64 * 37) + (CLNG(numPatterns) * 64 * 8 * 4)
    IF bufSize < minRequiredSize THEN EXIT FUNCTION

    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION
    __MODPlayer_InitializeSong player

    ' Order table (256 bytes)
    player.song.orders = numOrders
    REDIM player.order(0 TO numOrders - 1) AS _UNSIGNED INTEGER
    DIM ord AS LONG
    FOR ord = 0 TO 255
        DIM ordVal AS _UNSIGNED _BYTE: ordVal = StringFile_ReadByte(memFile)
        IF ord < numOrders THEN player.order(ord) = ordVal
    NEXT ord

    ' Sample headers (64 entries * 37 bytes)
    player.song.instruments = numSamples
    REDIM player.instrument(0 TO numSamples - 1) AS __MODPLAYERINSTRUMENT

    DIM s AS LONG
    FOR s = 0 TO 63
        DIM smpName AS STRING: smpName = String_MakePrintable(StringFile_ReadString(memFile, 22))
        DIM finetune AS _UNSIGNED _BYTE: finetune = StringFile_ReadByte(memFile)
        DIM defaultVolume AS _UNSIGNED _BYTE: defaultVolume = StringFile_ReadByte(memFile)
        DIM transposeByte AS _UNSIGNED _BYTE: transposeByte = StringFile_ReadByte(memFile)
        DIM smpLen AS _UNSIGNED LONG: smpLen = StringFile_ReadLong(memFile)
        DIM loopStart AS _UNSIGNED LONG: loopStart = StringFile_ReadLong(memFile)
        DIM loopLength AS _UNSIGNED LONG: loopLength = StringFile_ReadLong(memFile)

        IF s < numSamples THEN
            player.instrument(s).caption = smpName
            player.instrument(s).length = smpLen
            player.instrument(s).c2Spd = __MODPlayer_GetS3MC2Spd(finetune AND 15)
            player.instrument(s).volume = _MIN(defaultVolume, 64)
            player.instrument(s).subtype = __MODPLAYER_INSTRUMENT_PCM
            player.instrument(s).bytesPerSample = 1
            player.instrument(s).channels = 1

            IF loopLength > 2 _ANDALSO loopStart + loopLength <= smpLen THEN
                player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
                player.instrument(s).loopStart = loopStart
                player.instrument(s).loopEnd = loopStart + loopLength
            ELSE
                player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                player.instrument(s).loopStart = 0
                player.instrument(s).loopEnd = smpLen
            END IF
        END IF
    NEXT s

    ' Patterns (numPatterns of 64 rows * 8 channels)
    player.song.patterns = numPatterns
    player.song.channels = 8
    REDIM player.pattern(0 TO numPatterns - 1) AS __MODPLAYERPATTERN

    DIM p AS LONG
    FOR p = 0 TO numPatterns - 1
        player.pattern(p).rows = 64
        REDIM player.pattern(p).note(0 TO 63, 0 TO 7) AS __MODPLAYERNOTE

        DIM r AS LONG
        FOR r = 0 TO 63
            DIM ch AS LONG
            FOR ch = 0 TO 7
                DIM nNote AS _UNSIGNED _BYTE: nNote = StringFile_ReadByte(memFile)
                DIM nInst AS _UNSIGNED _BYTE: nInst = StringFile_ReadByte(memFile)
                DIM nCmd AS _UNSIGNED _BYTE: nCmd = StringFile_ReadByte(memFile)
                DIM nParam AS _UNSIGNED _BYTE: nParam = StringFile_ReadByte(memFile)

                IF nNote > 0 _ANDALSO nNote <= 96 THEN
                    player.pattern(p).note(r, ch).note = nNote + 24
                ELSE
                    player.pattern(p).note(r, ch).note = __MODPLAYER_NOTE_NONE
                END IF

                player.pattern(p).note(r, ch).instrument = nInst
                player.pattern(p).note(r, ch).volume = __MODPLAYER_NOTE_NO_VOLUME
                player.pattern(p).note(r, ch).effect = nCmd
                player.pattern(p).note(r, ch).operand = nParam
            NEXT ch
        NEXT r
    NEXT p

    ' Sample PCM data (8-bit signed PCM)
    FOR s = 0 TO numSamples - 1
        IF player.instrument(s).length > 0 THEN
            IF StringFile_GetPosition(memFile) + player.instrument(s).length <= bufSize THEN
                DIM sData AS STRING: sData = StringFile_ReadString(memFile, player.instrument(s).length)
                SoftSynth_LoadSound player.synth, s, sData, 1, 1
            ELSE
                EXIT FOR
            END IF
        END IF
    NEXT s

    ' Channel setup (8 channels, Amiga LRRL panning)
    REDIM player.channel(0 TO 7) AS __MODPLAYERCHANNEL
    SoftSynth_SetTotalVoices player.synth, 8
    FOR ch = 0 TO 7
        player.channel(ch).subtype = __MODPLAYER_INSTRUMENT_PCM
        player.channel(ch).volume = 64
        player.channel(ch).channelVolume = 64
        IF (ch AND 1) = 0 THEN player.channel(ch).panning = 64 ELSE player.channel(ch).panning = 192
        player.channel(ch).defaultPanning = player.channel(ch).panning
    NEXT ch

    player.song.caption = "Asylum Music"
    player.song.subtype = "AMF"
    player.song.format = MODPLAYER_FORMAT_AMF
    player.song.pcmMasterGain = 48.0! / 128.0!
    player.song.isStereo = _TRUE
    player.song.hasFMChannels = _FALSE
    player.song.defaultSpeed = defaultSpeed
    IF player.song.defaultSpeed = 0 THEN player.song.defaultSpeed = 6
    player.song.defaultBPM = defaultTempo
    IF player.song.defaultBPM < 32 THEN player.song.defaultBPM = 125
    player.song.speed = player.song.defaultSpeed
    player.song.BPM = player.song.defaultBPM
    player.song.tick = player.song.speed
    player.song.defaultGlobalVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX
    player.song.globalVolume = player.song.defaultGlobalVolume
    SoftSynth_SetGlobalVolume player.synth, 1.0!

    __MODPlayer_LoadTables
    player.initialized = _TRUE
    __AMFLoader_LoadAsylum = _TRUE
END FUNCTION

''' @brief Parses and loads an Advanced Music Format (.AMF / DSMI or Asylum) module from memory.
''' @param player The MOD player instance.
''' @param buffer The in-memory file content.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION AMFLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    DIM bufSize AS _UNSIGNED LONG: bufSize = StringFile_GetSize(memFile)
    IF bufSize < 38 THEN EXIT FUNCTION

    DIM sig AS STRING: sig = StringFile_ReadString(memFile, 3)
    IF sig = __AMFLOADER_MAGIC THEN
        DIM version AS _UNSIGNED _BYTE: version = StringFile_ReadByte(memFile)
        IF version = 1 _ORELSE (version >= 8 _ANDALSO version <= 14) THEN
            AMFLoader_LoadFromMemory = __AMFLoader_LoadDSMI(player, memFile, buffer, version)
            EXIT FUNCTION
        END IF
    END IF

    ' Check for Asylum AMF
    StringFile_Seek memFile, 0
    DIM asylumSig AS STRING: asylumSig = StringFile_ReadString(memFile, 25)
    IF asylumSig = __AMFLOADER_ASYLUM_HEADER_SIG THEN
        AMFLoader_LoadFromMemory = __AMFLoader_LoadAsylum(player, memFile)
        EXIT FUNCTION
    END IF
END FUNCTION

''' @brief Loads an Advanced Music Format (.AMF) module from disk.
''' @param player The MOD player instance.
''' @param fileName Path to the module file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION AMFLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    DIM buffer AS STRING: buffer = File_Load(fileName)
    IF LEN(buffer) = 0 THEN EXIT FUNCTION

    AMFLoader_LoadFromDisk = AMFLoader_LoadFromMemory(player, buffer)
END FUNCTION
