'-----------------------------------------------------------------------------------------------------------------------
' MultiTracker Module (MTM) Loader
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

''' @brief Parses and loads a MultiTracker Module (MTM) from a memory buffer.
''' @param buffer Binary string containing the MTM module data.
''' @return _TRUE if the module was successfully parsed, _FALSE otherwise.
FUNCTION MTMLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    ' Open the buffer as a StringFile
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    ' An MTM file must be at least 66 bytes long to contain the header
    IF StringFile_GetSize(memFile) < 66 THEN EXIT FUNCTION

    ' Initialize the softsynth sample mixer
    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION

    __MODPlayer_InitializeSong player ' just in case something is playing

    ' Read the file signature
    player.song.subtype = StringFile_ReadString(memFile, 4) ' read 4 bytes. Last byte is the version

    ' Check if this is really an MTM file
    IF LEFT$(player.song.subtype, 3) <> "MTM" THEN EXIT FUNCTION

    ' Change the FourCC so that it is completely printable
    MID$(player.song.subtype, 4, 1) = HEX$(ASC(player.song.subtype, 4) - 15)

    ' Read the MTM song title (20 bytes)
    player.song.caption = String_MakePrintable(StringFile_ReadString(memFile, 20)) ' MTM song name is 20 bytes
    player.song.isStereo = _TRUE

    ' Read the number of tracks saved
    DIM numTracks AS _UNSIGNED INTEGER: numTracks = StringFile_ReadInteger(memFile)

    ' Read the highest pattern number saved
    player.song.patterns = StringFile_ReadByte(memFile) + 1 ' convert to count / length

    ' Read the last order to play
    player.song.orders = StringFile_ReadByte(memFile) + 1 ' convert to count / length

    ' Read length of the extra comment field
    DIM commentLen AS _UNSIGNED INTEGER: commentLen = StringFile_ReadInteger(memFile)

    ' Read the number of instruments
    player.song.instruments = StringFile_ReadByte(memFile)

    ' Read the attribute byte and discard it
    DIM byte1 AS _UNSIGNED _BYTE: byte1 = StringFile_ReadByte(memFile)

    ' Read the beats per track (row count)
    DIM numRows AS _UNSIGNED _BYTE: numRows = StringFile_ReadByte(memFile)

    ' Read the number of channels
    player.song.channels = StringFile_ReadByte(memFile)

    ' Sanity check
    IF numTracks = 0 _ORELSE player.song.instruments = 0 _ORELSE numRows = 0 _ORELSE player.song.channels = 0 THEN EXIT FUNCTION

    ' Set PCM master gain (matches OpenMPT MTM default pre-amp of 48)
    player.song.pcmMasterGain = 48.0! / 128.0!

    ' Resize the channel array
    REDIM player.channel(0 TO player.song.channels - 1) AS __MODPLAYERCHANNEL
    DIM cIdx AS LONG: FOR cIdx = 0 TO player.song.channels - 1
        player.channel(cIdx).subtype = __MODPLAYER_INSTRUMENT_PCM
    NEXT cIdx

    ' Allocate the number of softsynth voices we need
    SoftSynth_SetTotalVoices player.synth, player.song.channels

    ' Read the panning positions
    DIM i AS LONG: FOR i = 0 TO __MODPLAYER_MTM_S3M_CHANNEL_MAX
        byte1 = StringFile_ReadByte(memFile) ' read the raw value

        ' Adjust and save the values per our mixer requirements
        IF i < player.song.channels _ANDALSO byte1 < 16 THEN
            player.channel(i).panning = byte1 * 17
            player.channel(i).defaultPanning = player.channel(i).panning
            ' __CHANNEL_PCM = 0 so all MTM channels are by default PCM
            SoftSynth_SetVoiceBalance player.synth, i, (byte1 / 15!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1
        END IF
    NEXT i

    ' Resize the instruments array
    REDIM player.instrument(0 TO player.song.instruments - 1) AS __MODPLAYERINSTRUMENT

    ' Read the instruments information
    FOR i = 0 TO player.song.instruments - 1
        player.instrument(i).subtype = __MODPLAYER_INSTRUMENT_PCM ' this format only uses PCM instruments

        ' Read the sample name
        player.instrument(i).caption = String_MakePrintable(StringFile_ReadString(memFile, 22)) ' MTM sample names are 22 bytes long

        ' Read sample length
        player.instrument(i).length = StringFile_ReadLong(memFile)

        ' Read loop start
        player.instrument(i).loopStart = StringFile_ReadLong(memFile)
        IF player.instrument(i).loopStart < 0 _ORELSE player.instrument(i).loopStart >= player.instrument(i).length THEN player.instrument(i).loopStart = 0 ' sanity check

        ' Read loop end
        player.instrument(i).loopEnd = StringFile_ReadLong(memFile)
        IF player.instrument(i).loopEnd < 0 _ORELSE player.instrument(i).loopEnd >= player.instrument(i).length THEN
            player.instrument(i).loopEnd = player.instrument(i).length ' sanity check
        END IF

        ' Set sound to looping and fix loop points if needed
        IF player.instrument(i).loopEnd - player.instrument(i).loopStart > 1 _ANDALSO player.instrument(i).loopEnd > 2 THEN ' loop requires loopEnd > loopStart and loopEnd > 2 (standard MTM / MultiTracker spec)
            player.instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
        ELSE
            player.instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            player.instrument(i).loopStart = 0
            player.instrument(i).loopEnd = player.instrument(i).length
        END IF

        ' Read finetune
        player.instrument(i).c2Spd = __MODPlayer_GetC2Spd(StringFile_ReadByte(memFile)) ' convert finetune to c2spd

        ' Read volume
        player.instrument(i).volume = StringFile_ReadByte(memFile)
        IF player.instrument(i).volume > __MODPLAYER_INSTRUMENT_VOLUME_MAX THEN player.instrument(i).volume = __MODPLAYER_INSTRUMENT_VOLUME_MAX ' MTM uses MOD volume specs.

        ' Read attribute
        byte1 = StringFile_ReadByte(memFile)
        player.instrument(i).bytesPerSample = _SIZE_OF_BYTE + _SIZE_OF_BYTE * (byte1 AND &H1) ' 1 if 8-bit else 2 if 16-bit
        player.instrument(i).channels = 1 ' all MTM sounds are mono
    NEXT i

    ' Resize the order array (MTMs like MODs always have a 128 byte long order table)
    REDIM player.order(0 TO __MODPLAYER_MOD_MTM_ORDER_MAX) AS _UNSIGNED INTEGER

    ' Read order list
    FOR i = 0 TO __MODPLAYER_MOD_MTM_ORDER_MAX ' MTMs like MODs always have a 128 byte long order table
        player.order(i) = StringFile_ReadByte(memFile)
    NEXT

    ' Read and convert track data
    DIM mtmTrack(0 TO numTracks - 1, 0 TO numRows - 1) AS __MODPlayerNote, j AS LONG
    DIM AS _UNSIGNED _BYTE byte2, byte3
    FOR i = 0 TO numTracks - 1
        FOR j = 0 TO numRows - 1
            ' Read 3 bytes
            byte1 = StringFile_ReadByte(memFile)
            byte2 = StringFile_ReadByte(memFile)
            byte3 = StringFile_ReadByte(memFile)

            ' +----------+----------+----------+
            ' |  BYTE 0  |  BYTE 1  |  BYTE 2  |
            ' | ppppppii | iiiieeee | aaaaaaaa |
            ' +----------+----------+----------+
            ' p = pitch value (0 = no pitch stated)
            ' i = instrument number (0 = no instrument number)
            ' e = effect number
            ' a = effect argument
            mtmTrack(i, j).note = _SHR(byte1, 2)
            IF mtmTrack(i, j).note = 0 THEN
                mtmTrack(i, j).note = __MODPLAYER_NOTE_NONE
            ELSE
                mtmTrack(i, j).note = mtmTrack(i, j).note + 24
            END IF

            mtmTrack(i, j).instrument = _SHL(byte1 AND &H3, 4) OR _SHR(byte2, 4)
            IF mtmTrack(i, j).instrument > player.song.instruments THEN mtmTrack(i, j).instrument = 0 ' sanity check

            mtmTrack(i, j).effect = byte2 AND &HF
            mtmTrack(i, j).operand = byte3
            mtmTrack(i, j).volume = __MODPLAYER_NOTE_NO_VOLUME

            ' MTM fix: when the effect is volume-slide, slide-up always overrides slide-down
            IF mtmTrack(i, j).effect = &HA _ANDALSO (mtmTrack(i, j).operand AND &HF0) <> 0 THEN
                mtmTrack(i, j).operand = mtmTrack(i, j).operand AND &HF0
            END IF

            ' MultiTracker does not support 8xx panning (only E8x)
            IF mtmTrack(i, j).effect = &H8 THEN
                mtmTrack(i, j).effect = 0
                mtmTrack(i, j).operand = 0
            END IF

            ' MultiTracker unsupported extended effects (E0x, E3x, E4x, E6x, E7x, EFx)
            IF mtmTrack(i, j).effect = &HE THEN
                SELECT CASE mtmTrack(i, j).operand AND &HF0
                    CASE &H00, &H30, &H40, &H60, &H70, &HF0
                        mtmTrack(i, j).effect = 0
                        mtmTrack(i, j).operand = 0
                END SELECT
            END IF
        NEXT j
    NEXT i

    ' Resize the pattern data array
    REDIM player.pattern(0 TO player.song.patterns - 1) AS __MODPLAYERPATTERN
    FOR i = 0 TO player.song.patterns - 1
        player.pattern(i).rows = numRows
        REDIM player.pattern(i).note(0 TO numRows - 1, 0 TO player.song.channels - 1) AS __MODPLAYERNOTE
    NEXT

    ' Read track sequencing data and assemble that to our pattern data
    DIM k AS LONG, w AS _UNSIGNED INTEGER
    FOR i = 0 TO player.song.patterns - 1
        FOR j = 0 TO __MODPLAYER_MTM_S3M_CHANNEL_MAX ' MTM files stores data for 32 channels irrespective of the actual channels used
            ' Read the data
            w = StringFile_ReadInteger(memFile)

            IF j >= player.song.channels THEN _CONTINUE ' ignore excess channel information

            IF w THEN
                FOR k = 0 TO numRows - 1
                    player.pattern(i).note(k, j) = mtmTrack(w - 1, k)
                NEXT k
            ELSE
                ' Populate empty channel
                FOR k = 0 TO numRows - 1
                    player.pattern(i).note(k, j).note = __MODPLAYER_NOTE_NONE
                    player.pattern(i).note(k, j).instrument = 0
                    player.pattern(i).note(k, j).effect = 0
                    player.pattern(i).note(k, j).operand = 0
                    player.pattern(i).note(k, j).volume = __MODPLAYER_NOTE_NO_VOLUME
                NEXT k
            END IF
        NEXT j
    NEXT i

    ' MultiTracker vs DMP tempo quirk detection:
    ' In MultiTracker, speed commands reset tempo to 125, and tempo commands reset speed to 6.
    ' DMP and external players did not implement this quirk.
    ' If both speed and tempo commands are present, check if any row has both on different channels.
    ' If they appear on the same row, it was written for DMP (do not enable MTM tempo mode).
    ' If they never appear on the same row, enable MTM tempo reset mode.
    DIM AS _BYTE hasSpeed, hasTempo, hasSpeedAndTempoOnSameRow
    FOR i = 0 TO player.song.patterns - 1
        FOR k = 0 TO numRows - 1
            DIM AS _BYTE rowHasSpeed, rowHasTempo
            FOR j = 0 TO player.song.channels - 1
                IF player.pattern(i).note(k, j).effect = __MODPLAYER_FX_SPEED_TEMPO _ANDALSO player.pattern(i).note(k, j).operand > 0 THEN
                    IF player.pattern(i).note(k, j).operand < 32 THEN
                        hasSpeed = _TRUE
                        rowHasSpeed = _TRUE
                    ELSE
                        hasTempo = _TRUE
                        rowHasTempo = _TRUE
                    END IF
                END IF
            NEXT j
            IF rowHasSpeed _ANDALSO rowHasTempo THEN
                hasSpeedAndTempoOnSameRow = _TRUE
            END IF
        NEXT k
    NEXT i

    IF hasSpeed _ANDALSO hasTempo _ANDALSO NOT hasSpeedAndTempoOnSameRow THEN
        player.song.useMTMTempoMode = _TRUE
    ELSE
        player.song.useMTMTempoMode = _FALSE
    END IF

    ' Read the tune comment
    IF commentLen > 0 THEN
        DIM rawComment AS STRING: rawComment = StringFile_ReadString(memFile, commentLen)
        DIM lineCount AS LONG: lineCount = commentLen \ 40
        DIM lastNonEmptyLine AS LONG: lastNonEmptyLine = -1
        DIM lIdx AS LONG
        FOR lIdx = 0 TO lineCount - 1
            DIM rawLine AS STRING: rawLine = MID$(rawComment, lIdx * 40 + 1, 40)
            DIM nulPos AS LONG: nulPos = INSTR(rawLine, _CHR_NUL)
            IF nulPos > 0 THEN
                rawLine = LEFT$(rawLine, nulPos - 1)
            ELSE
                rawLine = LEFT$(rawLine, 39)
            END IF
            IF LEN(RTRIM$(rawLine)) > 0 THEN lastNonEmptyLine = lIdx
        NEXT lIdx

        DIM formattedComment AS STRING: formattedComment = _STR_EMPTY
        FOR lIdx = 0 TO lastNonEmptyLine
            rawLine = MID$(rawComment, lIdx * 40 + 1, 40)
            nulPos = INSTR(rawLine, _CHR_NUL)
            IF nulPos > 0 THEN
                rawLine = LEFT$(rawLine, nulPos - 1)
            ELSE
                rawLine = LEFT$(rawLine, 39)
            END IF
            IF lIdx > 0 THEN formattedComment = formattedComment + CHR$(13) + CHR$(10)
            formattedComment = formattedComment + RTRIM$(rawLine)
        NEXT lIdx

        player.song.comment = formattedComment
    ELSE
        player.song.comment = _STR_EMPTY
    END IF

    ' Load the instruments
    FOR i = 0 TO player.song.instruments - 1
        DIM sampBuf AS STRING: sampBuf = StringFile_ReadString(memFile, player.instrument(i).length)

        ' Convert unsigned samples to signed
        IF player.instrument(i).bytesPerSample = _SIZE_OF_BYTE THEN
            AudioConv_ConvertU8ToS8 sampBuf
        ELSEIF player.instrument(i).bytesPerSample = 2 THEN
            AudioConv_ConvertU16ToS16 sampBuf
        END IF

        ' Load sample size bytes of data and send it to our softsynth sample manager
        SoftSynth_LoadSound player.synth, i, sampBuf, player.instrument(i).bytesPerSample, player.instrument(i).channels
    NEXT i

    ' Load all needed LUTs
    __MODPlayer_LoadTables

    MTMLoader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Loads a MultiTracker Module (MTM) from a file on disk or URL.
''' @param fileName File path or URL to load.
''' @return _TRUE if the module was loaded, _FALSE otherwise.
FUNCTION MTMLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    MTMLoader_LoadFromDisk = MTMLoader_LoadFromMemory(player, File_Load(fileName))
END FUNCTION
