'-----------------------------------------------------------------------------------------------------------------------
' Reality Adlib Tracker (RAD) v1.0 Module Loader
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

CONST __RADLOADER_MAGIC = "RAD by REALiTY!!"
CONST __RADLOADER_VERSION_10 = &H10
CONST __RADLOADER_CHANNELS = 9
CONST __RADLOADER_ROWS_PER_PATTERN = 64
CONST __RADLOADER_MAX_INSTRUMENTS = 31
CONST __RADLOADER_MAX_PATTERNS = 32
CONST __RADLOADER_MAX_ORDERS = 128
CONST __RADLOADER_HEADER_MIN_SIZE = 32

''' @brief Parses and loads a Reality Adlib Tracker (RAD) v1.0 module from a memory buffer.
''' @param player The MOD player instance.
''' @param buffer In-memory binary representation of the RAD file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION RADLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    IF StringFile_GetSize(memFile) < __RADLOADER_HEADER_MIN_SIZE THEN EXIT FUNCTION

    DIM magic AS STRING: magic = StringFile_ReadString(memFile, 16)
    IF magic <> __RADLOADER_MAGIC THEN EXIT FUNCTION

    DIM version AS _UNSIGNED _BYTE: version = StringFile_ReadByte(memFile)
    IF version <> __RADLOADER_VERSION_10 THEN EXIT FUNCTION

    DIM flags AS _UNSIGNED _BYTE: flags = StringFile_ReadByte(memFile)
    DIM spd AS _UNSIGNED _BYTE: spd = flags AND &H1F
    IF spd <= 2 THEN spd = 6

    DIM isSlowTimer AS _BYTE: isSlowTimer = ((flags AND &H40) <> 0)
    DIM songBPM AS _UNSIGNED INTEGER
    IF isSlowTimer THEN
        songBPM = 46 ' ~18.2 Hz slow-timer
    ELSE
        songBPM = 125 ' 50 Hz standard timer
    END IF

    ' Read description string if flag bit 7 is set
    DIM descStr AS STRING: descStr = ""
    IF (flags AND &H80) <> 0 THEN
        DO UNTIL StringFile_IsEOF(memFile)
            DIM chByte AS _UNSIGNED _BYTE: chByte = StringFile_ReadByte(memFile)
            IF chByte = 0 THEN EXIT DO
            IF chByte = 1 THEN
                descStr = descStr + CHR$(13) + CHR$(10)
            ELSEIF chByte >= 2 _ANDALSO chByte <= 31 THEN
                descStr = descStr + SPACE$(chByte)
            ELSE
                descStr = descStr + CHR$(chByte)
            END IF
        LOOP
    END IF

    ' Initialize synth and song state
    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION
    __MODPlayer_InitializeSong player

    player.song.comment = descStr
    DIM firstLine AS STRING: firstLine = descStr
    DIM crlfPos AS LONG: crlfPos = INSTR(firstLine, CHR$(13))
    IF crlfPos > 0 THEN firstLine = LEFT$(firstLine, crlfPos - 1)
    crlfPos = INSTR(firstLine, CHR$(10))
    IF crlfPos > 0 THEN firstLine = LEFT$(firstLine, crlfPos - 1)
    player.song.caption = _TRIM$(firstLine)

    ' Setup channels
    player.song.channels = __RADLOADER_CHANNELS
    REDIM player.channel(0 TO __RADLOADER_CHANNELS - 1) AS __MODPLAYERCHANNEL
    SoftSynth_SetTotalVoices player.synth, __RADLOADER_CHANNELS

    ' Read instruments
    player.song.instruments = 0
    REDIM player.instrument(0 TO __RADLOADER_MAX_INSTRUMENTS - 1) AS __MODPLAYERINSTRUMENT
    DO
        IF StringFile_IsEOF(memFile) THEN EXIT FUNCTION
        DIM instNum AS _UNSIGNED _BYTE: instNum = StringFile_ReadByte(memFile)
        IF instNum = 0 THEN EXIT DO
        IF instNum > __RADLOADER_MAX_INSTRUMENTS THEN EXIT FUNCTION
        IF StringFile_GetPosition(memFile) + 11 > StringFile_GetSize(memFile) THEN EXIT FUNCTION

        DIM c_flags AS _UNSIGNED _BYTE: c_flags = StringFile_ReadByte(memFile)
        DIM m_flags AS _UNSIGNED _BYTE: m_flags = StringFile_ReadByte(memFile)
        DIM c_ksl_vol AS _UNSIGNED _BYTE: c_ksl_vol = StringFile_ReadByte(memFile)
        DIM m_ksl_vol AS _UNSIGNED _BYTE: m_ksl_vol = StringFile_ReadByte(memFile)
        DIM c_ad AS _UNSIGNED _BYTE: c_ad = StringFile_ReadByte(memFile)
        DIM m_ad AS _UNSIGNED _BYTE: m_ad = StringFile_ReadByte(memFile)
        DIM c_sr AS _UNSIGNED _BYTE: c_sr = StringFile_ReadByte(memFile)
        DIM m_sr AS _UNSIGNED _BYTE: m_sr = StringFile_ReadByte(memFile)
        DIM fb_alg AS _UNSIGNED _BYTE: fb_alg = StringFile_ReadByte(memFile)
        DIM c_wave AS _UNSIGNED _BYTE: c_wave = StringFile_ReadByte(memFile)
        DIM m_wave AS _UNSIGNED _BYTE: m_wave = StringFile_ReadByte(memFile)

        DIM instIdx AS LONG: instIdx = CLNG(instNum) - 1
        IF instIdx >= player.song.instruments THEN player.song.instruments = instIdx + 1

        player.instrument(instIdx).caption = "AdLib Instrument " + _TRIM$(STR$(instNum))
        player.instrument(instIdx).subtype = __MODPLAYER_INSTRUMENT_FM_MELODY
        player.instrument(instIdx).c2Spd = 8363
        player.instrument(instIdx).channels = 1
        player.instrument(instIdx).bytesPerSample = 1
        player.instrument(instIdx).volume = _CLAMP(63 - (c_ksl_vol AND 63), 0, __MODPLAYER_INSTRUMENT_VOLUME_MAX)

        ' Map HSC/RAD registers to standard S3M adlib() format
        player.instrument(instIdx).adlib(0) = m_flags
        player.instrument(instIdx).adlib(1) = c_flags
        player.instrument(instIdx).adlib(2) = m_ksl_vol
        player.instrument(instIdx).adlib(3) = c_ksl_vol
        player.instrument(instIdx).adlib(4) = m_ad
        player.instrument(instIdx).adlib(5) = c_ad
        player.instrument(instIdx).adlib(6) = m_sr
        player.instrument(instIdx).adlib(7) = c_sr
        player.instrument(instIdx).adlib(8) = m_wave
        player.instrument(instIdx).adlib(9) = c_wave
        player.instrument(instIdx).adlib(10) = fb_alg
        player.instrument(instIdx).adlib(11) = 0
    LOOP

    IF player.song.instruments > 0 THEN
        REDIM _PRESERVE player.instrument(0 TO player.song.instruments - 1) AS __MODPLAYERINSTRUMENT
    ELSE
        player.song.instruments = 1
        REDIM player.instrument(0 TO 0) AS __MODPLAYERINSTRUMENT
    END IF

    ' Read orders
    IF StringFile_IsEOF(memFile) THEN EXIT FUNCTION
    DIM numOrders AS _UNSIGNED _BYTE: numOrders = StringFile_ReadByte(memFile)
    IF numOrders = 0 _ORELSE numOrders > __RADLOADER_MAX_ORDERS THEN EXIT FUNCTION
    IF StringFile_GetPosition(memFile) + numOrders > StringFile_GetSize(memFile) THEN EXIT FUNCTION

    player.song.orders = numOrders
    player.song.endJumpOrder = 0
    REDIM player.order(0 TO numOrders - 1) AS _UNSIGNED INTEGER

    DIM rawOrder(0 TO 127) AS _UNSIGNED _BYTE
    DIM patternUsed(0 TO 31) AS _BYTE
    DIM o AS LONG
    FOR o = 0 TO numOrders - 1
        rawOrder(o) = StringFile_ReadByte(memFile)
    NEXT o

    DIM maxPatNum AS LONG: maxPatNum = 0
    FOR o = 0 TO numOrders - 1
        DIM oVal AS _UNSIGNED _BYTE: oVal = rawOrder(o)
        IF (oVal AND &H80) <> 0 THEN
            DIM targetOrder AS _UNSIGNED _BYTE: targetOrder = oVal AND &H7F
            IF targetOrder >= numOrders THEN targetOrder = 0
            player.song.endJumpOrder = targetOrder
            player.order(o) = __MODPLAYER_PATTERN_END
        ELSE
            IF oVal < __RADLOADER_MAX_PATTERNS THEN
                player.order(o) = oVal
                patternUsed(oVal) = _TRUE
                IF oVal >= maxPatNum THEN maxPatNum = oVal + 1
            ELSE
                player.order(o) = __MODPLAYER_PATTERN_MARKER
            END IF
        END IF
    NEXT o

    ' Read pattern offsets
    IF StringFile_GetPosition(memFile) + 64 > StringFile_GetSize(memFile) THEN EXIT FUNCTION
    DIM pattOffset(0 TO 31) AS _UNSIGNED INTEGER
    DIM pIdx AS LONG
    FOR pIdx = 0 TO 31
        DIM pOff AS _UNSIGNED INTEGER: pOff = StringFile_ReadInteger(memFile)
        IF patternUsed(pIdx) _ANDALSO pOff > 0 _ANDALSO pOff < StringFile_GetSize(memFile) THEN
            pattOffset(pIdx) = pOff
            IF pIdx >= maxPatNum THEN maxPatNum = pIdx + 1
        ELSE
            pattOffset(pIdx) = 0
        END IF
    NEXT pIdx

    player.song.patterns = maxPatNum
    IF player.song.patterns = 0 THEN player.song.patterns = 1
    REDIM player.pattern(0 TO player.song.patterns - 1) AS __MODPLAYERPATTERN

    ' Unpack patterns
    DIM p AS LONG
    FOR p = 0 TO player.song.patterns - 1
        player.pattern(p).rows = __RADLOADER_ROWS_PER_PATTERN
        REDIM player.pattern(p).note(0 TO __RADLOADER_ROWS_PER_PATTERN - 1, 0 TO __RADLOADER_CHANNELS - 1) AS __MODPLAYERNOTE
        DIM rInit AS LONG, cInit AS LONG
        FOR rInit = 0 TO __RADLOADER_ROWS_PER_PATTERN - 1
            FOR cInit = 0 TO __RADLOADER_CHANNELS - 1
                player.pattern(p).note(rInit, cInit).note = __MODPLAYER_NOTE_NONE
                player.pattern(p).note(rInit, cInit).instrument = 0
                player.pattern(p).note(rInit, cInit).volume = __MODPLAYER_NOTE_NO_VOLUME
                player.pattern(p).note(rInit, cInit).effect = 0
                player.pattern(p).note(rInit, cInit).operand = 0
            NEXT cInit
        NEXT rInit

        IF pattOffset(p) > 0 THEN
            StringFile_Seek memFile, pattOffset(p)
            DIM lastLine AS _BYTE: lastLine = _FALSE
            DO
                IF StringFile_IsEOF(memFile) THEN EXIT DO
                DIM lineByte AS _UNSIGNED _BYTE: lineByte = StringFile_ReadByte(memFile)
                DIM rowNum AS _UNSIGNED _BYTE: rowNum = lineByte AND &H7F
                IF (lineByte AND &H80) <> 0 THEN lastLine = _TRUE
                IF rowNum >= __RADLOADER_ROWS_PER_PATTERN THEN EXIT DO

                DIM lastNote AS _BYTE: lastNote = _FALSE
                DO
                    IF StringFile_GetPosition(memFile) + 3 > StringFile_GetSize(memFile) THEN EXIT DO
                    DIM chanByte AS _UNSIGNED _BYTE: chanByte = StringFile_ReadByte(memFile)
                    DIM chanNum AS _UNSIGNED _BYTE: chanNum = chanByte AND &H7F
                    IF (chanByte AND &H80) <> 0 THEN lastNote = _TRUE

                    DIM b1 AS _UNSIGNED _BYTE: b1 = StringFile_ReadByte(memFile)
                    DIM b2 AS _UNSIGNED _BYTE: b2 = StringFile_ReadByte(memFile)

                    DIM noteNum AS _UNSIGNED _BYTE: noteNum = b1 AND &H0F
                    DIM octNum AS _UNSIGNED _BYTE: octNum = _SHR(b1 AND &H70, 4)
                    DIM cellInstNum AS _UNSIGNED _BYTE: cellInstNum = _SHR(b1 AND &H80, 3) OR _SHR(b2 AND &HF0, 4)
                    DIM fxNum AS _UNSIGNED _BYTE: fxNum = b2 AND &H0F
                    DIM fxParam AS _UNSIGNED _BYTE: fxParam = 0

                    IF fxNum <> 0 THEN
                        IF NOT StringFile_IsEOF(memFile) THEN
                            fxParam = StringFile_ReadByte(memFile)
                        END IF
                    END IF

                    IF chanNum < __RADLOADER_CHANNELS THEN
                        IF noteNum = 15 THEN
                            player.pattern(p).note(rowNum, chanNum).note = __MODPLAYER_NOTE_KEY_OFF
                        ELSEIF noteNum >= 1 _ANDALSO noteNum <= 11 THEN
                            player.pattern(p).note(rowNum, chanNum).note = octNum * 12 + noteNum
                        ELSEIF noteNum = 12 THEN
                            player.pattern(p).note(rowNum, chanNum).note = (octNum + 1) * 12
                        END IF

                        IF cellInstNum > 0 THEN
                            IF cellInstNum > player.song.instruments THEN
                                DIM oldInstCount AS LONG: oldInstCount = player.song.instruments
                                player.song.instruments = cellInstNum
                                REDIM _PRESERVE player.instrument(0 TO player.song.instruments - 1) AS __MODPLAYERINSTRUMENT
                                DIM fillIdx AS LONG
                                FOR fillIdx = oldInstCount TO player.song.instruments - 1
                                    player.instrument(fillIdx).caption = "AdLib Instrument " + _TRIM$(STR$(fillIdx + 1))
                                    player.instrument(fillIdx).subtype = __MODPLAYER_INSTRUMENT_FM_MELODY
                                    player.instrument(fillIdx).c2Spd = 8363
                                    player.instrument(fillIdx).channels = 1
                                    player.instrument(fillIdx).bytesPerSample = 1
                                    player.instrument(fillIdx).volume = __MODPLAYER_INSTRUMENT_VOLUME_MAX
                                NEXT fillIdx
                            END IF
                            player.pattern(p).note(rowNum, chanNum).instrument = cellInstNum
                        END IF

                        SELECT CASE fxNum
                            CASE &H1 ' Portamento Up
                                player.pattern(p).note(rowNum, chanNum).effect = __MODPLAYER_FX_PORTAMENTO_UP
                                player.pattern(p).note(rowNum, chanNum).operand = fxParam

                            CASE &H2 ' Portamento Down
                                player.pattern(p).note(rowNum, chanNum).effect = __MODPLAYER_FX_PORTAMENTO_DOWN
                                player.pattern(p).note(rowNum, chanNum).operand = fxParam

                            CASE &H3 ' Tone Portamento
                                player.pattern(p).note(rowNum, chanNum).effect = __MODPLAYER_FX_PORTAMENTO
                                player.pattern(p).note(rowNum, chanNum).operand = fxParam

                            CASE &H5 ' Tone Portamento + Volume Slide
                                player.pattern(p).note(rowNum, chanNum).effect = __MODPLAYER_FX_PORTAMENTO_VOLUME_SLIDE
                                player.pattern(p).note(rowNum, chanNum).operand = fxParam

                            CASE &HA ' Volume Slide
                                player.pattern(p).note(rowNum, chanNum).effect = __MODPLAYER_FX_VOLUME_SLIDE
                                player.pattern(p).note(rowNum, chanNum).operand = fxParam

                            CASE &HC ' Set Volume
                                player.pattern(p).note(rowNum, chanNum).volume = _CLAMP(fxParam, 0, __MODPLAYER_INSTRUMENT_VOLUME_MAX)

                            CASE &HD ' Pattern Break
                                player.pattern(p).note(rowNum, chanNum).effect = __MODPLAYER_FX_PATTERN_BREAK
                                player.pattern(p).note(rowNum, chanNum).operand = ((fxParam \ 10) * 16) + (fxParam MOD 10)

                            CASE &HF ' Set Speed
                                player.pattern(p).note(rowNum, chanNum).effect = __MODPLAYER_FX_SPEED
                                player.pattern(p).note(rowNum, chanNum).operand = fxParam
                        END SELECT
                    END IF
                LOOP UNTIL lastNote
            LOOP UNTIL lastLine
        END IF
    NEXT p

    ' Configure song
    player.song.channels = __RADLOADER_CHANNELS
    player.song.isStereo = _FALSE
    player.song.format = MODPLAYER_FORMAT_RAD
    player.song.subtype = "RAD1"
    player.song.speed = spd
    player.song.defaultSpeed = spd
    player.song.BPM = songBPM
    player.song.defaultBPM = songBPM
    player.song.pcmMasterGain = 1.0!
    player.song.fmMasterGain = 1.0!
    player.song.globalVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX
    player.song.defaultGlobalVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX
    player.song.hasFMChannels = _TRUE

    DIM c AS LONG
    FOR c = 0 TO __RADLOADER_CHANNELS - 1
        player.channel(c).subtype = __MODPLAYER_INSTRUMENT_FM_MELODY
        player.channel(c).oplChannel = c
        player.channel(c).panning = 128
        player.channel(c).defaultPanning = 128
        player.channel(c).channelVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX
        player.channel(c).volume = 0
    NEXT c

    IF LEN(player.song.caption) = 0 THEN
        player.song.caption = "Untitled RAD"
    END IF

    player.initialized = _TRUE
    RADLoader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Loads a Reality Adlib Tracker (RAD) v1.0 module from a disk file.
''' @param player The MOD player instance.
''' @param fileName Path to the module file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION RADLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    DIM buffer AS STRING: buffer = File_Load(fileName)
    IF LEN(buffer) = 0 THEN EXIT FUNCTION
    RADLoader_LoadFromDisk = RADLoader_LoadFromMemory(player, buffer)
END FUNCTION
