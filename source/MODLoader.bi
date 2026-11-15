'-----------------------------------------------------------------------------------------------------------------------
' ProTracker / SoundTracker / NoiseTracker / FastTracker (MOD) Loader
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MODPlayer.bi'
'$INCLUDE:'SoftSynth.bi'
'$INCLUDE:'Math.bi'
'$INCLUDE:'String.bi'
'$INCLUDE:'AudioConv.bi'
'$INCLUDE:'StringFile.bi'
'$INCLUDE:'File.bi'

''' @brief Parses and loads a standard ProTracker or compatible MOD module from a memory buffer.
''' @param buffer Binary string containing the MOD module data.
''' @return _TRUE if the module was successfully parsed, _FALSE otherwise.
FUNCTION MODLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    SHARED __MODPlayer_PeriodTable() AS _UNSIGNED INTEGER

    ' Attempt to open the file
    DIM i AS LONG, memFile AS StringFile
    StringFile_Create memFile, buffer

    ' Minimum possible MOD file with 15 samples is at least 600 bytes
    IF StringFile_GetSize(memFile) < 600 THEN EXIT FUNCTION

    ' Initialize the softsynth sample mixer
    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION

    __MODPlayer_InitializeSong player ' just in case something is playing

    ' Seek to offset 1080 (438h) in the file and read the file signature if large enough
    IF StringFile_GetSize(memFile) >= 1084 THEN
        StringFile_Seek memFile, 1080
        player.song.subtype = StringFile_ReadString(memFile, 4) ' signature is 4 bytes
    ELSE
        player.song.subtype = ""
    END IF

    ' Also, seek to the beginning of the file and get the song title
    StringFile_Seek memFile, 0
    player.song.caption = String_MakePrintable(StringFile_ReadString(memFile, 20)) ' MOD song title is 20 bytes long

    DIM isFLT8 AS _BYTE ' this will we set to true if we are dealing with a FLT8 MOD

    SELECT CASE player.song.subtype
        CASE "FEST", "FIST", "LARD", "M!K!", "M&K!", "M.K.", "N.T.", "NSMS", "PATT"
            player.song.channels = 4
            player.song.instruments = 31
        CASE "OCTA", "OKTA"
            player.song.channels = 8
            player.song.instruments = 31
        CASE ELSE
            ' Parse the subtype string to check for more variants
            IF RIGHT$(player.song.subtype, 3) = "CHN" THEN
                ' Check xCNH types
                player.song.channels = VAL(LEFT$(player.song.subtype, 1))
                player.song.instruments = 31
            ELSEIF RIGHT$(player.song.subtype, 2) = "CH" _ORELSE RIGHT$(player.song.subtype, 2) = "CN" THEN
                ' Check for xxCH & xxCN types
                player.song.channels = VAL(LEFT$(player.song.subtype, 2))
                player.song.instruments = 31
            ELSEIF LEFT$(player.song.subtype, 3) = "FLT" _ORELSE LEFT$(player.song.subtype, 3) = "TDZ" _ORELSE LEFT$(player.song.subtype, 3) = "EXO" THEN
                ' Check for FLTx, TDZx & EXOx types
                player.song.channels = VAL(RIGHT$(player.song.subtype, 1))
                player.song.instruments = 31
                isFLT8 = (player.song.subtype = "FLT8")
            ELSEIF LEFT$(player.song.subtype, 2) = "CD" _ANDALSO RIGHT$(player.song.subtype, 1) = "1" THEN
                ' Check for CDx1 types
                player.song.channels = VAL(MID$(player.song.subtype, 3, 1))
                player.song.instruments = 31
            ELSEIF LEFT$(player.song.subtype, 2) = "FA" THEN
                ' Check for FAxx types
                player.song.channels = VAL(RIGHT$(player.song.subtype, 2))
                player.song.instruments = 31
            ELSE
                ' Extra checks for 15 sample MOD
                ' 15 sample MODs must be at least 600 bytes
                IF StringFile_GetSize(memFile) < 600 THEN EXIT FUNCTION

                ' Caption must only contain printable ASCII or NUL
                FOR i = 1 TO LEN(player.song.caption)
                    IF ASC(player.song.caption, i) < _ASC_SPACE _ANDALSO ASC(player.song.caption, i) <> _ASC_NUL THEN EXIT FUNCTION
                NEXT

                ' Validate all 15 sample headers (each 30 bytes starting at byte offset 20)
                DIM sIdx AS LONG, charIdx AS LONG, sampNameChar AS _UNSIGNED _BYTE
                FOR sIdx = 0 TO 14
                    ' Check sample name (22 bytes)
                    FOR charIdx = 1 TO 22
                        sampNameChar = ASC(buffer, 20 + sIdx * 30 + charIdx)
                        IF sampNameChar < _ASC_SPACE _ANDALSO sampNameChar <> _ASC_NUL THEN EXIT FUNCTION
                    NEXT charIdx

                    ' Check volume (byte 26 of 30-byte header, 1-based offset: 20 + sIdx * 30 + 26)
                    ' In Amiga ProTracker/SoundTracker volume is strictly 0..64
                    IF ASC(buffer, 20 + sIdx * 30 + 26) > __MODPLAYER_INSTRUMENT_VOLUME_MAX THEN EXIT FUNCTION

                    ' Check finetune (byte 25 of 30-byte header, 1-based offset: 20 + sIdx * 30 + 25)
                    ' Finetune must be <= 15
                    IF ASC(buffer, 20 + sIdx * 30 + 25) > 15 THEN EXIT FUNCTION
                NEXT sIdx

                ' Check song orders count at offset 470 (1-based: 471)
                DIM numOrders15 AS _UNSIGNED _BYTE: numOrders15 = ASC(buffer, 471)
                IF numOrders15 = 0 _ORELSE numOrders15 > 128 THEN EXIT FUNCTION

                ' Check order table at offset 472 (1-based: 473..600) to find maximum pattern
                DIM maxPat15 AS _UNSIGNED INTEGER: maxPat15 = 0
                FOR charIdx = 0 TO 127
                    DIM patNum15 AS _UNSIGNED _BYTE: patNum15 = ASC(buffer, 473 + charIdx)
                    IF patNum15 > maxPat15 THEN maxPat15 = patNum15
                NEXT charIdx

                ' Sanity check max pattern for 15-sample MOD (Amiga ST/PT never exceeded 64 patterns)
                IF maxPat15 > 64 THEN EXIT FUNCTION

                ' Verify that the buffer has enough bytes for the 600-byte header + pattern data
                IF StringFile_GetSize(memFile) < 600 + (maxPat15 + 1) * 1024 THEN EXIT FUNCTION

                player.song.channels = 4
                player.song.instruments = 15
                player.song.subtype = "MODF" ' change subtype to reflect 15 (Fh) sample mod, otherwise it will contain garbage
            END IF
    END SELECT

    ' Sanity check
    IF player.song.instruments = 0 _ORELSE player.song.channels = 0 THEN EXIT FUNCTION

    ' Resize the instruments array
    REDIM player.instrument(0 TO player.song.instruments - 1) AS __MODPlayerInstrument
    DIM AS _UNSIGNED _BYTE byte1, byte2

    ' Load the instruments headers
    FOR i = 0 TO player.song.instruments - 1
        player.instrument(i).subtype = __MODPLAYER_INSTRUMENT_PCM ' this format only uses PCM instruments

        ' Read the sample name
        player.instrument(i).caption = String_MakePrintable(StringFile_ReadString(memFile, 22)) ' MOD sample names are 22 bytes long

        ' Read sample length
        byte1 = StringFile_ReadByte(memFile)
        byte2 = StringFile_ReadByte(memFile)
        player.instrument(i).length = (byte1 * &H100 + byte2) * 2

        ' Read finetune
        player.instrument(i).c2Spd = __MODPlayer_GetC2Spd(StringFile_ReadByte(memFile)) ' convert finetune to c2spd

        ' Read volume
        player.instrument(i).volume = StringFile_ReadByte(memFile)
        IF player.instrument(i).volume > __MODPLAYER_INSTRUMENT_VOLUME_MAX THEN player.instrument(i).volume = __MODPLAYER_INSTRUMENT_VOLUME_MAX ' Sanity check

        ' Read loop start
        byte1 = StringFile_ReadByte(memFile)
        byte2 = StringFile_ReadByte(memFile)
        player.instrument(i).loopStart = (byte1 * &H100 + byte2) * 2

        ' Read loop length
        byte1 = StringFile_ReadByte(memFile)
        byte2 = StringFile_ReadByte(memFile)
        DIM loopLength AS _UNSIGNED LONG: loopLength = (byte1 * &H100 + byte2) * 2

        ' Some MOD file loop points are truly fucked
        ' These checks are taken directly from OpenMPT's MOD loader which seem to do a decent job dealing with messed up MODs
        ' See if loop start is incorrect as words, but correct as bytes (like in Soundtracker modules)
        IF loopLength > 2 _ANDALSO player.instrument(i).loopStart + loopLength > player.instrument(i).length _ANDALSO player.instrument(i).loopStart \ 2 + loopLength <= player.instrument(i).length THEN
            player.instrument(i).loopStart = player.instrument(i).loopStart \ 2
        END IF

        IF player.instrument(i).length = 2 THEN player.instrument(i).length = 0

        IF player.instrument(i).length > 0 THEN
            player.instrument(i).loopEnd = player.instrument(i).loopStart + loopLength

            IF player.instrument(i).loopStart >= player.instrument(i).length THEN player.instrument(i).loopStart = player.instrument(i).length - 1

            IF player.instrument(i).loopStart > player.instrument(i).loopEnd _ORELSE player.instrument(i).loopEnd < 4 _ORELSE player.instrument(i).loopEnd - player.instrument(i).loopStart < 4 THEN
                player.instrument(i).loopStart = 0
                player.instrument(i).loopEnd = 0
            END IF

            ' Fix for most likely broken sample loops. This fixes super_sufm_-_new_life.mod (M.K.) which has a long sample which is looped from 0 to 4.
            ' This module also has notes outside of the Amiga frequency range, so we cannot say that it should be played using ProTracker one-shot loops.
            ' On the other hand, "Crew Generation" by Necros (6CHN) has a sample with a similar loop, which is supposed to be played.
            ' To be able to correctly play both modules, we will draw a somewhat arbitrary line here and trust the loop points in MODs with more than
            ' 4 channels, even if they are tiny and at the very beginning of the sample.
            IF player.instrument(i).loopEnd <= 8 _ANDALSO player.instrument(i).loopStart = 0 _ANDALSO player.instrument(i).length > player.instrument(i).loopEnd _ANDALSO player.song.channels = 4 THEN
                player.instrument(i).loopEnd = 0
            END IF

            IF player.instrument(i).loopEnd > player.instrument(i).loopStart THEN
                player.instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
            ELSE
                player.instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                player.instrument(i).loopStart = 0
                player.instrument(i).loopEnd = player.instrument(i).length
            END IF
        ELSE
            player.instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            player.instrument(i).loopStart = 0
            player.instrument(i).loopEnd = 0
        END IF

        ' Set sample frame size as 1 since MODs always use 8-bit mono samples
        player.instrument(i).bytesPerSample = _SIZE_OF_BYTE
        player.instrument(i).channels = 1
    NEXT

    player.song.orders = StringFile_ReadByte(memFile)
    IF player.song.orders >= __MODPLAYER_MOD_MTM_ORDER_MAX THEN player.song.orders = __MODPLAYER_MOD_MTM_ORDER_MAX + 1 ' clamp to MOD specific max

    player.song.endJumpOrder = StringFile_ReadByte(memFile)
    IF player.song.endJumpOrder >= player.song.orders THEN player.song.endJumpOrder = 0

    ' Resize the order array (MODs always have a 128 byte long order table)
    REDIM player.order(0 TO __MODPLAYER_MOD_MTM_ORDER_MAX) AS _UNSIGNED INTEGER

    ' Load the pattern table, and find the highest pattern to load
    FOR i = 0 TO __MODPLAYER_MOD_MTM_ORDER_MAX ' MODs always have a 128 byte long order table
        player.order(i) = StringFile_ReadByte(memFile)

        IF isFLT8 THEN player.order(i) = _SHR(player.order(i), 1) ' special FLT8 handling

        IF player.order(i) > player.song.patterns THEN player.song.patterns = player.order(i)
    NEXT
    player.song.patterns = player.song.patterns + 1 ' change to count

    ' Resize the pattern data array
    REDIM player.pattern(0 TO player.song.patterns - 1) AS __MODPlayerPattern
    FOR i = 0 TO player.song.patterns - 1
        player.pattern(i).rows = __MODPLAYER_MOD_S3M_ROWS
        REDIM player.pattern(i).note(0 TO __MODPLAYER_MOD_S3M_ROWS - 1, 0 TO player.song.channels - 1) AS __MODPlayerNote
    NEXT

    ' Skip past the 4 byte signature if this is a 31 sample mod
    IF player.song.instruments = 31 THEN StringFile_Seek memFile, StringFile_GetPosition(memFile) + 4

    ' Check if the file has enough bytes for all pattern data
    DIM requiredPatternBytes AS _UNSIGNED _OFFSET
    requiredPatternBytes = player.song.patterns * __MODPLAYER_MOD_S3M_ROWS * player.song.channels * 4
    IF StringFile_GetPosition(memFile) + requiredPatternBytes > StringFile_GetSize(memFile) THEN EXIT FUNCTION

    __MODPlayer_LoadTables ' load all needed LUTs

    DIM AS _UNSIGNED _BYTE byte3, byte4
    DIM AS _UNSIGNED INTEGER a, b, c, period

    ' Load the patterns
    ' +----------+-----------+----------+-----------+
    ' | Byte 0   | Byte 1    | Byte 2   | Byte 3    |
    ' | aaaaBBBB | CCCCCCCCC | DDDDeeee | FFFFFFFFF |
    ' +----------+-----------+----------+-----------+
    FOR i = 0 TO player.song.patterns - 1
        IF isFLT8 THEN
            ' Special handling for FLT8

            FOR a = 0 TO player.pattern(i).rows - 1
                FOR b = 0 TO 3
                    GOSUB load_mod_pattern
                NEXT b
            NEXT a

            FOR a = 0 TO player.pattern(i).rows - 1
                FOR b = 4 TO 7
                    GOSUB load_mod_pattern
                NEXT b
            NEXT a
        ELSE
            ' Regular MOD pattern

            FOR a = 0 TO player.pattern(i).rows - 1
                FOR b = 0 TO player.song.channels - 1
                    GOSUB load_mod_pattern
                NEXT b
            NEXT a
        END IF
    NEXT

    ' Load the instruments
    FOR i = 0 TO player.song.instruments - 1
        DIM sampBuf AS STRING
        IF StringFile_GetPosition(memFile) < StringFile_GetSize(memFile) THEN
            sampBuf = StringFile_ReadString(memFile, player.instrument(i).length)
        END IF

        ' Load sample size bytes of data and send it to our softsynth sample manager
        SoftSynth_LoadSound player.synth, i, sampBuf, player.instrument(i).bytesPerSample, player.instrument(i).channels
    NEXT

    ' Setup the channel array
    ' __CHANNEL_PCM = 0 so all MOD channels are by default PCM
    REDIM player.channel(0 TO player.song.channels - 1) AS __MODPlayerChannel

    ' Allocate the number of softsynth voices we need
    SoftSynth_SetTotalVoices player.synth, player.song.channels

    ' Setup panning for all channels per AMIGA PAULA's panning setup - LRRLLRRL...
    ' opencp uses this: for (int i = 0; i < 8; i++) int panpos = ((i * 3) & 2) ? 0xFF : 0x00;
    ' But ours is better:
    ' If we have < 4 channels, then 0 & 1 are set as left & right
    ' If we have > 4 channels, then all prefect 4 groups are set as LRRL
    ' Any channels that are left out are simply centered by the SoftSynth
    ' We will also not do hard left or hard right. Some amount of sound from each channel is allowed to blend with the other
    IF player.song.channels > 1 _ANDALSO player.song.channels < 4 THEN
        ' Just setup channels 0 and 1. If we have a 3rd channel it will be handle by the SoftSynth
        SoftSynth_SetVoiceBalance player.synth, 0, -__MODPLAYER_STEREO_SEPARATION
        SoftSynth_SetVoiceBalance player.synth, 1, __MODPLAYER_STEREO_SEPARATION
    ELSE
        FOR i = 0 TO player.song.channels - 1 - (player.song.channels MOD 4) STEP 4
            SoftSynth_SetVoiceBalance player.synth, i + 0, -__MODPLAYER_STEREO_SEPARATION
            SoftSynth_SetVoiceBalance player.synth, i + 1, __MODPLAYER_STEREO_SEPARATION
            SoftSynth_SetVoiceBalance player.synth, i + 2, __MODPLAYER_STEREO_SEPARATION
            SoftSynth_SetVoiceBalance player.synth, i + 3, -__MODPLAYER_STEREO_SEPARATION
        NEXT
    END IF

    MODLoader_LoadFromMemory = _TRUE
    EXIT FUNCTION

    ' This part loads a single channel worth of pattern data
    ' It is here so that we do not duplicate this multiple times
    load_mod_pattern:

    byte1 = StringFile_ReadByte(memFile)
    byte2 = StringFile_ReadByte(memFile)
    byte3 = StringFile_ReadByte(memFile)
    byte4 = StringFile_ReadByte(memFile)

    player.pattern(i).note(a, b).instrument = (byte1 AND &HF0) OR _SHR(byte3, 4)

    period = _SHL(byte1 AND &HF, 8) OR byte2

    ' Do the look up in the table against what is read in and store note
    player.pattern(i).note(a, b).note = __MODPLAYER_NOTE_NONE
    FOR c = 0 TO 107
        IF period >= __MODPlayer_PeriodTable(c + 24) THEN
            player.pattern(i).note(a, b).note = c
            EXIT FOR
        END IF
    NEXT

    player.pattern(i).note(a, b).volume = __MODPLAYER_NOTE_NO_VOLUME ' MODs don't have any volume field in the pattern
    player.pattern(i).note(a, b).effect = byte3 AND &HF
    player.pattern(i).note(a, b).operand = byte4

    ' Some sanity check
    IF player.pattern(i).note(a, b).instrument > player.song.instruments THEN player.pattern(i).note(a, b).instrument = 0 ' instrument 0 means no instrument. So valid sample are 1-15/31

    RETURN
END FUNCTION

''' @brief Loads a ProTracker or compatible MOD module from a file on disk or URL.
''' @param fileName File path or URL to load.
''' @return _TRUE if the module was loaded, _FALSE otherwise.
FUNCTION MODLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    MODLoader_LoadFromDisk = MODLoader_LoadFromMemory(player, File_Load(fileName))
END FUNCTION
