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
FUNCTION MTMLoader_LoadFromMemory%% (buffer AS STRING)
    SHARED __Song AS __SongType
    SHARED __Order() AS _UNSIGNED INTEGER
    SHARED __Pattern() AS __NoteType
    SHARED __Instrument() AS __InstrumentType
    SHARED __Channel() AS __ChannelType
    SHARED __MODPlayer_Synth AS SoftSynthType

    ' Open the buffer as a StringFile
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    ' An MTM file must be at least 66 bytes long to contain the header
    IF StringFile_GetSize(memFile) < 66 THEN EXIT FUNCTION

    ' Initialize the softsynth sample mixer
    IF NOT SoftSynth_Initialize(__MODPlayer_Synth) THEN EXIT FUNCTION

    __MODPlayer_InitializeSong ' just in case something is playing

    ' Read the file signature
    __Song.subtype = StringFile_ReadString(memFile, 4) ' read 4 bytes. Last byte is the version

    ' Check if this is really an MTM file
    IF LEFT$(__Song.subtype, 3) <> "MTM" THEN EXIT FUNCTION

    ' Change the FourCC so that it is completely printable
    MID$(__Song.subtype, 4, 1) = HEX$(ASC(__Song.subtype, 4) - 15)

    ' Read the MTM song title (20 bytes)
    __Song.caption = String_MakePrintable(StringFile_ReadString(memFile, 20)) ' MTM song name is 20 bytes

    ' Read the number of tracks saved
    DIM numTracks AS _UNSIGNED INTEGER: numTracks = StringFile_ReadInteger(memFile)

    ' Read the highest pattern number saved
    __Song.patterns = StringFile_ReadByte(memFile) + 1 ' convert to count / length

    ' Read the last order to play
    __Song.orders = StringFile_ReadByte(memFile) + 1 ' convert to count / length

    ' Read length of the extra comment field
    DIM commentLen AS _UNSIGNED INTEGER: commentLen = StringFile_ReadInteger(memFile)

    ' Read the number of instruments
    __Song.instruments = StringFile_ReadByte(memFile)

    ' Read the attribute byte and discard it
    DIM byte1 AS _UNSIGNED _BYTE: byte1 = StringFile_ReadByte(memFile)

    ' Read the beats per track (row count)
    __Song.rows = StringFile_ReadByte(memFile)

    ' Read the number of channels
    __Song.channels = StringFile_ReadByte(memFile)

    ' Sanity check
    IF numTracks = 0 _ORELSE __Song.instruments = 0 _ORELSE __Song.rows = 0 _ORELSE __Song.channels = 0 THEN EXIT FUNCTION

    ' Resize the channel array
    REDIM __Channel(0 TO __Song.channels - 1) AS __ChannelType

    ' Allocate the number of softsynth voices we need
    SoftSynth_SetTotalVoices __MODPlayer_Synth, __Song.channels

    ' Read the panning positions
    DIM i AS LONG: FOR i = 0 TO __MTM_S3M_CHANNEL_MAX
        byte1 = StringFile_ReadByte(memFile) ' read the raw value

        ' Adjust and save the values per our mixer requirements
        IF i < __Song.channels _ANDALSO byte1 < 16 THEN
            ' __CHANNEL_PCM = 0 so all MTM channels are by default PCM
            SoftSynth_SetVoiceBalance __MODPlayer_Synth, i, (byte1 / 15!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1
        END IF
    NEXT i

    ' Resize the instruments array
    REDIM __Instrument(0 TO __Song.instruments - 1) AS __InstrumentType

    ' Read the instruments information
    FOR i = 0 TO __Song.instruments - 1
        __Instrument(i).subtype = __INSTRUMENT_PCM ' this format only uses PCM instruments

        ' Read the sample name
        __Instrument(i).caption = String_MakePrintable(StringFile_ReadString(memFile, 22)) ' MTM sample names are 22 bytes long

        ' Read sample length
        __Instrument(i).length = StringFile_ReadLong(memFile)

        ' Read loop start
        __Instrument(i).loopStart = StringFile_ReadLong(memFile)
        IF __Instrument(i).loopStart < 0 _ORELSE __Instrument(i).loopStart >= __Instrument(i).length THEN __Instrument(i).loopStart = 0 ' sanity check

        ' Read loop end
        __Instrument(i).loopEnd = StringFile_ReadLong(memFile)
        IF __Instrument(i).loopEnd < 0 _ORELSE __Instrument(i).loopEnd >= __Instrument(i).length THEN
            __Instrument(i).loopEnd = __Instrument(i).length ' sanity check
        END IF

        ' Set sound to looping and fix loop points if needed
        IF __Instrument(i).loopEnd - __Instrument(i).loopStart > 1 THEN ' we need 2 frames minimum to mark the sound as looping (TODO: check if this is normal)
            __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
        ELSE
            __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            __Instrument(i).loopStart = 0
            __Instrument(i).loopEnd = __Instrument(i).length
        END IF

        ' Read finetune
        __Instrument(i).c2Spd = __MODPlayer_GetC2Spd(StringFile_ReadByte(memFile)) ' convert finetune to c2spd

        ' Read volume
        __Instrument(i).volume = StringFile_ReadByte(memFile)
        IF __Instrument(i).volume > __INSTRUMENT_VOLUME_MAX THEN __Instrument(i).volume = __INSTRUMENT_VOLUME_MAX ' MTM uses MOD volume specs.

        ' Read attribute
        byte1 = StringFile_ReadByte(memFile)
        __Instrument(i).bytesPerSample = _SIZE_OF_BYTE + _SIZE_OF_BYTE * (byte1 AND &H1) ' 1 if 8-bit else 2 if 16-bit
        __Instrument(i).channels = 1 ' all MTM sounds are mono
    NEXT i

    ' Resize the order array (MTMs like MODs always have a 128 byte long order table)
    REDIM __Order(0 TO __MOD_MTM_ORDER_MAX) AS _UNSIGNED INTEGER

    ' Read order list
    FOR i = 0 TO __MOD_MTM_ORDER_MAX ' MTMs like MODs always have a 128 byte long order table
        __Order(i) = StringFile_ReadByte(memFile)
    NEXT

    ' Read and convert track data
    DIM mtmTrack(0 TO numTracks - 1, 0 TO __Song.rows - 1) AS __NoteType, j AS LONG
    DIM AS _UNSIGNED _BYTE byte2, byte3
    FOR i = 0 TO numTracks - 1
        FOR j = 0 TO __Song.rows - 1
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
            IF mtmTrack(i, j).instrument > __Song.instruments THEN mtmTrack(i, j).instrument = 0 ' sanity check

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
    REDIM __Pattern(0 TO __Song.patterns - 1, 0 TO __Song.rows - 1, 0 TO __Song.channels - 1) AS __NoteType

    ' Read track sequencing data and assemble that to our pattern data
    DIM k AS LONG, w AS _UNSIGNED INTEGER
    FOR i = 0 TO __Song.patterns - 1
        FOR j = 0 TO __MTM_S3M_CHANNEL_MAX ' MTM files stores data for 32 channels irrespective of the actual channels used
            ' Read the data
            w = StringFile_ReadInteger(memFile)

            IF j >= __Song.channels THEN _CONTINUE ' ignore excess channel information

            IF w THEN
                FOR k = 0 TO __Song.rows - 1
                    __Pattern(i, k, j) = mtmTrack(w - 1, k)
                NEXT k
            ELSE
                ' Populate empty channel
                FOR k = 0 TO __Song.rows - 1
                    __Pattern(i, k, j).note = __NOTE_NONE
                    __Pattern(i, k, j).instrument = 0
                    __Pattern(i, k, j).effect = 0
                    __Pattern(i, k, j).operand = 0
                    __Pattern(i, k, j).volume = __NOTE_NO_VOLUME
                NEXT k
            END IF
        NEXT j
    NEXT i

    ' Read the tune comment
    __Song.comment = StringFile_ReadString(memFile, commentLen) ' read the comment and leave it untouched

    ' Load the instruments
    FOR i = 0 TO __Song.instruments - 1
        DIM sampBuf AS STRING: sampBuf = StringFile_ReadString(memFile, __Instrument(i).length)

        ' Convert 8-bit unsigned samples to 8-bit signed
        IF __Instrument(i).bytesPerSample = _SIZE_OF_BYTE THEN AudioConv_ConvertU8ToS8 sampBuf

        ' Load sample size bytes of data and send it to our softsynth sample manager
        SoftSynth_LoadSound __MODPlayer_Synth, i, sampBuf, __Instrument(i).bytesPerSample, __Instrument(i).channels
    NEXT i

    ' Load all needed LUTs
    __MODPlayer_LoadTables

    MTMLoader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Loads a MultiTracker Module (MTM) from a file on disk or URL.
''' @param fileName File path or URL to load.
''' @return _TRUE if the module was loaded, _FALSE otherwise.
FUNCTION MTMLoader_LoadFromDisk%% (fileName AS STRING)
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    MTMLoader_LoadFromDisk = MTMLoader_LoadFromMemory(File_Load(fileName))
END FUNCTION
