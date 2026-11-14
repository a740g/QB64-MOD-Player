'-----------------------------------------------------------------------------------------------------------------------
' MultiTracker Module (MTM) Loader
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

''' @brief Parses and loads a MultiTracker Module (MTM) from a memory buffer.
''' @param buffer Binary string containing the MTM module data.
''' @return _TRUE if the module was successfully parsed, _FALSE otherwise.
FUNCTION MTMLoader_LoadFromMemory%% (player AS MODPlayerType, buffer AS STRING)


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
    player.song.rows = StringFile_ReadByte(memFile)

    ' Read the number of channels
    player.song.channels = StringFile_ReadByte(memFile)

    ' Sanity check
    IF numTracks = 0 _ORELSE player.song.instruments = 0 _ORELSE player.song.rows = 0 _ORELSE player.song.channels = 0 THEN EXIT FUNCTION

    ' Resize the channel array
    REDIM player.channel(0 TO player.song.channels - 1) AS __ChannelType

    ' Allocate the number of softsynth voices we need
    SoftSynth_SetTotalVoices player.synth, player.song.channels

    ' Read the panning positions
    DIM i AS LONG: FOR i = 0 TO __MTM_S3M_CHANNEL_MAX
        byte1 = StringFile_ReadByte(memFile) ' read the raw value

        ' Adjust and save the values per our mixer requirements
        IF i < player.song.channels _ANDALSO byte1 < 16 THEN
            ' __CHANNEL_PCM = 0 so all MTM channels are by default PCM
            SoftSynth_SetVoiceBalance player.synth, i, (byte1 / 15!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1
        END IF
    NEXT i

    ' Resize the instruments array
    REDIM player.instrument(0 TO player.song.instruments - 1) AS __InstrumentType

    ' Read the instruments information
    FOR i = 0 TO player.song.instruments - 1
        player.instrument(i).subtype = __INSTRUMENT_PCM ' this format only uses PCM instruments

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
        IF player.instrument(i).loopEnd - player.instrument(i).loopStart > 1 THEN ' we need 2 frames minimum to mark the sound as looping (TODO: check if this is normal)
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
        IF player.instrument(i).volume > __INSTRUMENT_VOLUME_MAX THEN player.instrument(i).volume = __INSTRUMENT_VOLUME_MAX ' MTM uses MOD volume specs.

        ' Read attribute
        byte1 = StringFile_ReadByte(memFile)
        player.instrument(i).bytesPerSample = _SIZE_OF_BYTE + _SIZE_OF_BYTE * (byte1 AND &H1) ' 1 if 8-bit else 2 if 16-bit
        player.instrument(i).channels = 1 ' all MTM sounds are mono
    NEXT i

    ' Resize the order array (MTMs like MODs always have a 128 byte long order table)
    REDIM player.order(0 TO __MOD_MTM_ORDER_MAX) AS _UNSIGNED INTEGER

    ' Read order list
    FOR i = 0 TO __MOD_MTM_ORDER_MAX ' MTMs like MODs always have a 128 byte long order table
        player.order(i) = StringFile_ReadByte(memFile)
    NEXT

    ' Read and convert track data
    DIM mtmTrack(0 TO numTracks - 1, 0 TO player.song.rows - 1) AS __NoteType, j AS LONG
    DIM AS _UNSIGNED _BYTE byte2, byte3
    FOR i = 0 TO numTracks - 1
        FOR j = 0 TO player.song.rows - 1
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
                mtmTrack(i, j).note = __NOTE_NONE
            ELSE
                mtmTrack(i, j).note = mtmTrack(i, j).note + 24
            END IF

            mtmTrack(i, j).instrument = _SHL(byte1 AND &H3, 4) OR _SHR(byte2, 4)
            IF mtmTrack(i, j).instrument > player.song.instruments THEN mtmTrack(i, j).instrument = 0 ' sanity check

            mtmTrack(i, j).effect = byte2 AND &HF
            mtmTrack(i, j).operand = byte3
            mtmTrack(i, j).volume = __NOTE_NO_VOLUME

            ' MTM fix: when the effect is volume-slide, slide-up always overrides slide-down
            IF mtmTrack(i, j).effect = &HA _ANDALSO (mtmTrack(i, j).operand AND &HF0) <> 0 THEN
                mtmTrack(i, j).operand = mtmTrack(i, j).operand AND &HF0
            END IF
        NEXT j
    NEXT i

    ' Resize the pattern data array
    REDIM player.pattern(0 TO player.song.patterns - 1, 0 TO player.song.rows - 1, 0 TO player.song.channels - 1) AS __NoteType

    ' Read track sequencing data and assemble that to our pattern data
    DIM k AS LONG, w AS _UNSIGNED INTEGER
    FOR i = 0 TO player.song.patterns - 1
        FOR j = 0 TO __MTM_S3M_CHANNEL_MAX ' MTM files stores data for 32 channels irrespective of the actual channels used
            ' Read the data
            w = StringFile_ReadInteger(memFile)

            IF j >= player.song.channels THEN _CONTINUE ' ignore excess channel information

            IF w THEN
                FOR k = 0 TO player.song.rows - 1
                    player.pattern(i, k, j) = mtmTrack(w - 1, k)
                NEXT k
            ELSE
                ' Populate empty channel
                FOR k = 0 TO player.song.rows - 1
                    player.pattern(i, k, j).note = __NOTE_NONE
                    player.pattern(i, k, j).instrument = 0
                    player.pattern(i, k, j).effect = 0
                    player.pattern(i, k, j).operand = 0
                    player.pattern(i, k, j).volume = __NOTE_NO_VOLUME
                NEXT k
            END IF
        NEXT j
    NEXT i

    ' Read the tune comment
    player.song.comment = StringFile_ReadString(memFile, commentLen) ' read the comment and leave it untouched

    ' Load the instruments
    FOR i = 0 TO player.song.instruments - 1
        DIM sampBuf AS STRING: sampBuf = StringFile_ReadString(memFile, player.instrument(i).length)

        ' Convert 8-bit unsigned samples to 8-bit signed
        IF player.instrument(i).bytesPerSample = _SIZE_OF_BYTE THEN AudioConv_ConvertU8ToS8 sampBuf

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
FUNCTION MTMLoader_LoadFromDisk%% (player AS MODPlayerType, fileName AS STRING)
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    MTMLoader_LoadFromDisk = MTMLoader_LoadFromMemory(player, File_Load(fileName))
END FUNCTION
