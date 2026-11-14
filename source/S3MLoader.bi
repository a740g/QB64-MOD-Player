'-----------------------------------------------------------------------------------------------------------------------
' Scream Tracker 3 (S3M) Loader
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

''' @brief Parses and loads a Scream Tracker 3 (S3M) module from a memory buffer.
''' @param buffer Binary string containing the S3M module data.
''' @return _TRUE if the module was successfully parsed, _FALSE otherwise.
FUNCTION S3MLoader_LoadFromMemory%% (buffer AS STRING)
    SHARED __Song AS __SongType
    SHARED __Order() AS _UNSIGNED INTEGER
    SHARED __Pattern() AS __NoteType
    SHARED __Instrument() AS __InstrumentType
    SHARED __Channel() AS __ChannelType
    SHARED __MODPlayer_Synth AS SoftSynthType

    ' Open the buffer as a StringFile
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    ' An S3M file must be at least 48 bytes long to contain the SCRM signature at offset 44
    IF StringFile_GetSize(memFile) < 48 THEN EXIT FUNCTION

    ' Initialize the softsynth sample mixer
    IF NOT SoftSynth_Initialize(__MODPlayer_Synth) THEN EXIT FUNCTION

    __MODPlayer_InitializeSong ' just in case something is playing

    ' Seek to offset 44 (2Ch) in the file & read the file signature
    StringFile_Seek memFile, 44
    __Song.subtype = StringFile_ReadString(memFile, 4) ' 4 bytes

    ' Check if this is really an S3M file
    IF __Song.subtype <> "SCRM" THEN EXIT FUNCTION

    ' Seek to the beginning of the file and get the song title
    StringFile_Seek memFile, 0
    __Song.caption = String_MakePrintable(StringFile_ReadString(memFile, 28)) ' 28 bytes

    ' Skip past the DOS EOF marker byte, file type byte and expansion / reserved word
    StringFile_Seek memFile, StringFile_GetPosition(memFile) + 4 ' 4 bytes

    ' Read the song orders (note that this count includes 254 & 255 marker orders)
    __Song.orders = StringFile_ReadInteger(memFile) ' TODO: this includes markers!

    ' Read the number of instruments
    __Song.instruments = StringFile_ReadInteger(memFile)

    ' Read the number of patterns
    __Song.patterns = StringFile_ReadInteger(memFile) ' TODO: includes marker patterns!

    ' Read the 16-bit flags
    DIM word1 AS _UNSIGNED INTEGER: word1 = StringFile_ReadInteger(memFile)

    ' Set individual flags
    ' TODO: Check and discard members which are not really needed
    __Song.useST2Vibrato = _READBIT(word1, 0)
    __Song.useST2Tempo = _READBIT(word1, 1)
    __Song.useAmigaSlides = _READBIT(word1, 2)
    __Song.useVolumeOptimization = _READBIT(word1, 3)
    __Song.useAmigaLimits = _READBIT(word1, 4)
    __Song.useFilterSFX = _READBIT(word1, 5)
    __Song.useST300VolumeSlides = _READBIT(word1, 6)
    __Song.hasSpecialCustomData = _READBIT(word1, 7)

    '_ECHO "useST2Vibrato =" + STR$(__Song.useST2Vibrato)
    '_ECHO "useST2Tempo =" + STR$(__Song.useST2Tempo)
    '_ECHO "useAmigaSlides =" + STR$(__Song.useAmigaSlides)
    '_ECHO "useVolumeOptimization =" + STR$(__Song.useVolumeOptimization)
    '_ECHO "useAmigaLimits =" + STR$(__Song.useAmigaLimits)
    '_ECHO "useFilterSFX =" + STR$(__Song.useFilterSFX)
    '_ECHO "useST300VolumeSlides =" + STR$(__Song.useST300VolumeSlides)
    '_ECHO "hasSpecialCustomData =" + STR$(__Song.hasSpecialCustomData)

    ' Read "Created with tracker / version" info
    word1 = StringFile_ReadInteger(memFile)
    '_ECHO "CWT/V = " + HEX$(word1)

    ' ST3.00 does volumeslides on EVERY tick. So we'll update the flag
    __Song.useST300VolumeSlides = __Song.useST300VolumeSlides _ORELSE (word1 = &H1300)
    '_ECHO "useST300VolumeSlides =" + STR$(__Song.useST300VolumeSlides)

    ' Read the sample format type
    word1 = StringFile_ReadInteger(memFile)
    '_ECHO "Sample Format =" + STR$(word1)
    DIM isUnsignedFormat AS _BYTE: isUnsignedFormat = (word1 = 2)
    '_ECHO "isUnsignedFormat =" + STR$(isUnsignedFormat)

    ' Skip the 4 byte signature
    StringFile_Seek memFile, StringFile_GetPosition(memFile) + 4

    ' Read and set the global volume
    DIM byte1 AS _UNSIGNED _BYTE: byte1 = StringFile_ReadByte(memFile)
    '_ECHO "Global volume =" + STR$(byte1)
    IF byte1 > __S3M_GLOBAL_VOLUME_MAX THEN byte1 = __S3M_GLOBAL_VOLUME_MAX
    SoftSynth_SetGlobalVolume __MODPlayer_Synth, byte1 / __S3M_GLOBAL_VOLUME_MAX
    '_ECHO "SoftSynth global volume =" + STR$(SoftSynth_GetGlobalVolume)

    ' Read the initial speed value
    __Song.defaultSpeed = StringFile_ReadByte(memFile)
    '_ECHO "Initial speed =" + STR$(__Song.defaultSpeed)

    ' Read the initial BPM
    __Song.defaultBPM = StringFile_ReadByte(memFile)
    '_ECHO "Initial BPM =" + STR$(__Song.defaultBPM)
    IF __Song.defaultBPM = 0 THEN __Song.defaultBPM = __SONG_BPM_DEFAULT ' avoid division by zero

    ' Read SoundBlaster master volume crap and check if the stereo frag is set
    byte1 = StringFile_ReadByte(memFile)
    '_ECHO "SoundBlaster master volume =" + STR$(byte1)
    DIM isStereo AS _BYTE: isStereo = _READBIT(byte1, 7)
    '_ECHO "isStereo =" + STR$(isStereo)

    ' Skip Ultrasound ultra-click removal crap
    StringFile_Seek memFile, StringFile_GetPosition(memFile) + 1 ' 1 byte

    ' Read and store if we have to load default pan values later
    byte1 = StringFile_ReadByte(memFile)
    '_ECHO "Default panning =" + STR$(byte1)
    DIM useDefaultPanning AS _BYTE: useDefaultPanning = (byte1 = 252)
    '_ECHO "useDefaultPanning =" + STR$(useDefaultPanning)

    ' Skip 8 reserved bytes and the 2 byte special parapointer
    StringFile_Seek memFile, StringFile_GetPosition(memFile) + 10

    ' Load channel info and count total channels
    DIM channelInfo(0 TO __MTM_S3M_CHANNEL_MAX) AS _UNSIGNED _BYTE ' channel info that we'll use later

    DIM i AS LONG: FOR i = 0 TO __MTM_S3M_CHANNEL_MAX
        channelInfo(i) = StringFile_ReadByte(memFile)

        ' Check if the channel is enabled
        ' 0 <= x <= 7: Left PCM channel 1-8 (Lx)
        ' 8 <= x <= 15: Right PCM channel 1-8 (Rx)
        ' 16 <= x <= 24: Adlib/OPL2 #1 melody (Ax)
        ' 25 <= x <= 29: Adlib/OPL2 #1 drums (Ax)
        ' Channel is enabled if bit 7 is not set
        IF NOT _READBIT(channelInfo(i), 7) THEN __Song.channels = i + 1 ' change to count

        '_ECHO "Channel info" + STR$(i) + " =" + STR$(channelInfo(i))
    NEXT i

    '_ECHO "Channels =" + STR$(__Song.channels)

    ' Resize the channel array
    REDIM __Channel(0 TO __Song.channels - 1) AS __ChannelType

    ' Allocate the number of SoftSynth voices we need
    SoftSynth_SetTotalVoices __MODPlayer_Synth, __Song.channels

    ' Set voice panning positions
    FOR i = 0 TO __Song.channels - 1
        ' 0 <= x <= 7: Left PCM channel 1-8 (Lx)
        ' 8 <= x <= 15: Right PCM channel 1-8 (Rx)
        ' 16 <= x <= 24: Adlib/OPL2 #1 melody (Ax)
        ' 25 <= x <= 29: Adlib/OPL2 #1 drums (Ax)
        SELECT CASE channelInfo(i)
            CASE 0 TO 7
                SoftSynth_SetVoiceBalance __MODPlayer_Synth, i, -__CHANNEL_STEREO_SEPARATION ' pan to the left
                __Channel(i).subtype = __INSTRUMENT_PCM

            CASE 8 TO 15
                SoftSynth_SetVoiceBalance __MODPlayer_Synth, i, __CHANNEL_STEREO_SEPARATION ' pan it to the right
                __Channel(i).subtype = __INSTRUMENT_PCM

            CASE 16 TO 24
                __Channel(i).subtype = __INSTRUMENT_FM_MELODY ' FM melody channel

            CASE 25 TO 29
                __Channel(i).subtype = __INSTRUMENT_FM_BASSDRUM ' FM drums channel
        END SELECT

        '_ECHO "Channel " + STR$(i) + " enabled =" + STR$(NOT _READBIT(channelInfo(i), 7))
        '_ECHO "Channel " + STR$(i) + " panning =" + STR$(SoftSynth_GetVoiceBalance(i)) + " , subtype =" + STR$(__Channel(i).subtype)
    NEXT i

    ' Resize the order array
    REDIM __Order(0 TO __Song.orders - 1) AS _UNSIGNED INTEGER

    ' Read order list
    ' Note: We'll need to handle 254 & 255 marker orders correctly in the player
    FOR i = 0 TO __Song.orders - 1
        __Order(i) = StringFile_ReadByte(memFile)
        '_ECHO "Order" + STR$(i) + " =" + STR$(__Order(i))
    NEXT i

    ' Load and convert instrument parapointers
    DIM instrumentPointer(0 TO __Song.instruments - 1) AS _UNSIGNED LONG

    FOR i = 0 TO __Song.instruments - 1
        instrumentPointer(i) = _SHL(StringFile_ReadInteger(memFile), 4) ' convert to real file offset (x 16)
        '_ECHO "Instrument" + STR$(i) + " is at" + STR$(instrumentPointer(i))
    NEXT i

    ' Load and convert pattern parapointers
    DIM patternPointer(0 TO __Song.patterns - 1) AS _UNSIGNED LONG

    FOR i = 0 TO __Song.patterns - 1
        patternPointer(i) = _SHL(StringFile_ReadInteger(memFile), 4) ' convert to real file offset (x 16)
        '_ECHO "Pattern" + STR$(i) + " is at" + STR$(patternPointer(i))
    NEXT i

    ' Load the panning table if it is present
    IF useDefaultPanning THEN
        ' We have a total of 32 pan positions in the file
        FOR i = 0 TO __MTM_S3M_CHANNEL_MAX
            byte1 = StringFile_ReadByte(memFile)

            ' Only set the pan position if the channel is there
            IF i < __Song.channels THEN
                ' WTF! Ewww!
                IF _READBIT(byte1, 4) THEN ' if bit 4 is set - byte1 AND &H10
                    SoftSynth_SetVoiceBalance __MODPlayer_Synth, i, (byte1 AND 15) / 15! * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1
                    '_ECHO "Channel " + STR$(i) + " panning =" + STR$(SoftSynth_GetVoiceBalance(i))
                END IF
            END IF
        NEXT i
    END IF

    ' Set everything to mono if stereo flag is not set. This is so retarded! Sigh!
    IF NOT isStereo THEN
        FOR i = 0 TO __Song.channels - 1
            SoftSynth_SetVoiceBalance __MODPlayer_Synth, i, 0!
            '_ECHO "Channel " + STR$(i) + " panning =" + STR$(SoftSynth_GetVoiceBalance(i))
        NEXT i
    END IF

    ' Resize the instruments array
    REDIM __Instrument(0 TO __Song.instruments - 1) AS __InstrumentType
    DIM isSampleCompressed(0 TO __Song.instruments - 1) AS _BYTE ' flags that tells us if we need to decode ADPCM samples

    ' Go through the instrument data and load whatever we need
    FOR i = 0 TO __Song.instruments - 1
        '_ECHO "Instrument:" + STR$(i)

        ' Seek to the correct position in the file to read the instrument info
        StringFile_Seek memFile, instrumentPointer(i)

        ' Read the instrument type
        __Instrument(i).subtype = StringFile_ReadByte(memFile)
        '_ECHO " Type =" + STR$(__Instrument(i).subtype)

        ' Read the instrument file name. We'll replace it with the title later on if needed
        __Instrument(i).caption = String_MakePrintable(String_ConvertToBStr(StringFile_ReadString(memFile, 12)))
        '_ECHO " File name = " + __Instrument(i).caption

        IF __Instrument(i).subtype > __INSTRUMENT_PCM THEN ' this is an FM instrument
            'TODO: Implement FM instrument loading support
            ERROR _ERR_FEATURE_UNAVAILABLE
        ELSE ' this is a standard PCM or blank instrument
            ' Read and convert the actual address to the PCM instrument sample data
            ' Convert this to a long. Eww! WTF!
            byte1 = StringFile_ReadByte(memFile)
            word1 = StringFile_ReadInteger(memFile)
            instrumentPointer(i) = _SHL(_SHL(byte1, 16) + word1, 4) ' we'll re-use instrumentPointer array for this

            '_ECHO "Sample" + STR$(i) + " is at" + STR$(instrumentPointer(i))

            ' Read the length
            __Instrument(i).length = StringFile_ReadLong(memFile)
            '_ECHO " Length =" + STR$(__Instrument(i).length)

            ' Read loop start
            __Instrument(i).loopStart = StringFile_ReadLong(memFile)
            '_ECHO " Loop start =" + STR$(__Instrument(i).loopStart)

            ' Read loop end
            __Instrument(i).loopEnd = StringFile_ReadLong(memFile)
            '_ECHO " Loop end =" + STR$(__Instrument(i).loopEnd)

            ' Read volume
            __Instrument(i).volume = StringFile_ReadByte(memFile)
            IF __Instrument(i).volume > __INSTRUMENT_VOLUME_MAX THEN __Instrument(i).volume = __INSTRUMENT_VOLUME_MAX
            '_ECHO " Volume =" + STR$(__Instrument(i).volume)

            ' Skip 1 reserved byte
            StringFile_Seek memFile, StringFile_GetPosition(memFile) + 1

            ' 0 = PCM, 1 = DP30ADPCM (WTF is this?), 3 = ADPCM (this is mostly ModPlug), 4 = also ADPCM (apparently; per milkyplay)
            isSampleCompressed(i) = StringFile_ReadByte(memFile) > 0 ' we'll attempt to decompress anything that is not PCM. Oh well...

            ' bits: 0 = loop, 1 = stereo (chans not interleaved! fuck fuck fuck), 2 = 16-bit samples (little endian)
            byte1 = StringFile_ReadByte(memFile)

            IF _READBIT(byte1, 0) THEN
                __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
            ELSE
                __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            END IF
            '_ECHO " Playmode =" + STR$(__Instrument(i).playMode)

            IF _READBIT(byte1, 1) THEN
                __Instrument(i).channels = 2
                isSampleCompressed(i) = _FALSE ' per OpenMPT stereo samples cannot be compressed
            ELSE
                __Instrument(i).channels = 1
            END IF
            '_ECHO " Channels =" + STR$(__Instrument(i).channels)

            IF _READBIT(byte1, 2) THEN
                __Instrument(i).bytesPerSample = _SIZE_OF_INTEGER
                isSampleCompressed(i) = _FALSE ' per OpenMPT 16-bit samples cannot be compressed
            ELSE
                __Instrument(i).bytesPerSample = _SIZE_OF_BYTE
            END IF
            '_ECHO " Bytes / sample =" + STR$(__Instrument(i).bytesPerSample)

            ' Read C2SPD (only the low word is used)
            __Instrument(i).c2Spd = StringFile_ReadLong(memFile) AND &HFFFF
            '_ECHO " C2SPD =" + STR$(__Instrument(i).c2Spd)

            ' Skip 12 useless bytes
            StringFile_Seek memFile, StringFile_GetPosition(memFile) + 12

            ' Store the instrument name if it is not empty
            DIM instrumentName AS STRING: instrumentName = String_MakePrintable(StringFile_ReadString(memFile, 28))
            IF LEN(_TRIM$(instrumentName)) <> NULL THEN __Instrument(i).caption = instrumentName
            '_ECHO " Instrument name = " + __Instrument(i).caption

            ' Read and verify the 'SCRS' label. This will ensure we are reading the file correctly somewhat until this point
            IF StringFile_ReadString(memFile, 4) <> "SCRS" _ANDALSO __INSTRUMENT_PCM = __Instrument(i).subtype THEN EXIT FUNCTION

            ' Validate a few things
            IF __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP _ANDALSO __Instrument(i).loopEnd > 2 THEN
                IF __Instrument(i).loopEnd > __Instrument(i).length THEN __Instrument(i).loopEnd = __Instrument(i).length
            ELSE
                __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                __Instrument(i).loopStart = 0
                __Instrument(i).loopEnd = __Instrument(i).length
            END IF
        END IF
    NEXT i

    __Song.rows = __MOD_S3M_ROWS ' S3M specific value

    ' Resize the pattern data array
    REDIM __Pattern(0 TO __Song.patterns - 1, 0 TO __Song.rows - 1, 0 TO __Song.channels - 1) AS __NoteType

    ' Load pattern data and convert it to MOD / MTM style
    FOR i = 0 TO __Song.patterns - 1
        ' Set the entire pattern to defaults first
        DIM row AS LONG: FOR row = 0 TO __Song.rows - 1
            DIM chan AS LONG: FOR chan = 0 TO __Song.channels - 1
                __Pattern(i, row, chan).note = __NOTE_NONE
                __Pattern(i, row, chan).instrument = 0
                __Pattern(i, row, chan).effect = 0
                __Pattern(i, row, chan).operand = 0
                __Pattern(i, row, chan).volume = __NOTE_NO_VOLUME
            NEXT chan
        NEXT row

        ' Seek to the correct position in the file to read the pattern data
        StringFile_Seek memFile, patternPointer(i) + 2 ' + 2 here is for the packed data size that we'll conveniently ignore

        row = 0
        WHILE row < __Song.rows
            DIM flags AS _UNSIGNED _BYTE: flags = StringFile_ReadByte(memFile)

            IF flags THEN ' we have some data; unpack it
                chan = flags AND 31 ' get the channel number

                IF chan >= __Song.channels _ORELSE _READBIT(channelInfo(chan), 7) THEN
                    ' Invalid channel: we'll ignore the remaining packed data
                    IF flags AND 32 THEN ' ignore the note
                        StringFile_Seek memFile, StringFile_GetPosition(memFile) + 2
                    END IF

                    IF flags AND 64 THEN ' ignore the volume data
                        StringFile_Seek memFile, StringFile_GetPosition(memFile) + 1
                    END IF

                    IF flags AND 128 THEN ' ignore the effect data
                        StringFile_Seek memFile, StringFile_GetPosition(memFile) + 2
                    END IF
                ELSE
                    IF flags AND 32 THEN ' we have a note
                        word1 = StringFile_ReadByte(memFile)

                        SELECT CASE word1
                            CASE 255
                                __Pattern(i, row, chan).note = __NOTE_NONE

                            CASE 254
                                __Pattern(i, row, chan).note = __NOTE_KEY_OFF

                            CASE ELSE
                                __Pattern(i, row, chan).note = _SHR(word1, 4) * 12 + (word1 AND &HF)
                        END SELECT

                        __Pattern(i, row, chan).instrument = StringFile_ReadByte(memFile)

                        'IF __Pattern(i, row, chan).instrument >= __Song.instruments THEN _ECHO "Invalid instrument:" + STR$(__Pattern(i, row, chan).instrument)
                    END IF

                    IF flags AND 64 THEN ' we have volume data
                        __Pattern(i, row, chan).volume = StringFile_ReadByte(memFile)
                    END IF

                    IF flags AND 128 THEN ' we have effect data
                        __Pattern(i, row, chan).effect = StringFile_ReadByte(memFile)
                        __Pattern(i, row, chan).operand = StringFile_ReadByte(memFile)

                        ' Convert S3M effects to MOD effects
                        SELECT CASE __Pattern(i, row, chan).effect
                            CASE &H0 ' None
                                __Pattern(i, row, chan).operand = &H0 ' get rid of any false arpeggio if there is any param

                            CASE &H1 ' Axx Set Speed
                                __Pattern(i, row, chan).effect = __MOD_FX_SPEED

                            CASE &H2 ' Bxx Position Jumpp
                                __Pattern(i, row, chan).effect = __MOD_FX_POSITION_JUMP

                            CASE &H3 ' Cxx Pattern Break
                                __Pattern(i, row, chan).effect = __MOD_FX_PATTERN_BREAK

                            CASE &H4 ' Dxy Volume Slide or Fine Volume Slide
                                __Pattern(i, row, chan).effect = __MOD_FX_VOLUME_FINE_SLIDE

                            CASE &H5 ' Exx Portamento Down or Fine Portamento Down or Extra Fine Portamento Down
                                __Pattern(i, row, chan).effect = __MOD_FX_PORTAMENTO_EXTRA_FINE_DOWN

                            CASE &H6 ' Fxx Portamento Up or Fine Portamento Up or Extra Fine Portamento Up
                                __Pattern(i, row, chan).effect = __MOD_FX_PORTAMENTO_EXTRA_FINE_UP

                            CASE &H7 ' Gxx Tone Portamento
                                __Pattern(i, row, chan).effect = __MOD_FX_PORTAMENTO

                            CASE &H8 ' Hxy Vibrato
                                __Pattern(i, row, chan).effect = __MOD_FX_VIBRATO

                            CASE &H9 ' Ixy Tremor
                                __Pattern(i, row, chan).effect = __MOD_FX_TREMOR

                            CASE &HA ' Jxy Arpeggio
                                __Pattern(i, row, chan).effect = __MOD_FX_ARPEGGIO

                            CASE &HB ' Kxy Volume Slide + Vibrato
                                __Pattern(i, row, chan).effect = __MOD_FX_VIBRATO_VOLUME_FINE_SLIDE

                            CASE &HC ' Lxy Volume Slide + Tone Portamento
                                __Pattern(i, row, chan).effect = __MOD_FX_PORTAMENTO_VOLUME_FINE_SLIDE

                            CASE &HD ' Mxx Set Channel Volume
                                __Pattern(i, row, chan).effect = __MOD_FX_CHANNEL_VOLUME

                            CASE &HE ' Nxy Channel Volume Slide
                                __Pattern(i, row, chan).effect = __MOD_FX_CHANNEL_VOLUME_SLIDE

                            CASE &HF ' Oxx Sample Offset
                                __Pattern(i, row, chan).effect = __MOD_FX_SAMPLE_OFFSET

                            CASE &H10 ' Pxy Panning Slide or Fine Panning Slide
                                __Pattern(i, row, chan).effect = __MOD_FX_PANNING_FINE_SLIDE

                            CASE &H11 ' Qxy Retrigger + Volume Slide
                                __Pattern(i, row, chan).effect = __MOD_FX_NOTE_RETRIGGER_VOLUME_SLIDE

                            CASE &H12 ' Rxy Tremolo
                                __Pattern(i, row, chan).effect = __MOD_FX_TREMOLO

                            CASE &H13 ' Sxy Special commands
                                SELECT CASE _SHR(__Pattern(i, row, chan).operand, 4)
                                    CASE &H1 ' S1x Glissando Control
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_GLISSANDO_CONTROL, 4) OR (__Pattern(i, row, chan).operand AND &HF)

                                    CASE &H2 ' S2x Set Finetune
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_FINETUNE, 4) OR (__Pattern(i, row, chan).operand AND &HF)

                                    CASE &H3 ' S3x Set Vibrato Waveform
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_VIBRATO_WAVEFORM, 4) OR (__Pattern(i, row, chan).operand AND &HF)

                                    CASE &H4 ' S4x Set Tremolo Waveform
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_TREMOLO_WAVEFORM, 4) OR (__Pattern(i, row, chan).operand AND &HF)

                                    CASE &H5 ' S5x Set Panbrello Waveform
                                        __Pattern(i, row, chan).effect = __MOD_FX_PANBRELLO_WAVEFORM
                                        __Pattern(i, row, chan).operand = __Pattern(i, row, chan).operand AND &HF

                                    CASE &H6 ' S6x Fine Pattern Delay
                                        __Pattern(i, row, chan).effect = __MOD_FX_PATTERN_FINE_DELAY
                                        __Pattern(i, row, chan).operand = __Pattern(i, row, chan).operand AND &HF

                                    CASE &H8 ' S8x Set Panning
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_PANNING_4, 4) OR (__Pattern(i, row, chan).operand AND &HF)

                                    CASE &H9 ' S9x Sound Control
                                        __Pattern(i, row, chan).effect = __MOD_FX_SOUND_CONTROL
                                        __Pattern(i, row, chan).operand = __Pattern(i, row, chan).operand AND &HF

                                    CASE &HA ' SAx High Offset
                                        __Pattern(i, row, chan).effect = __MOD_FX_HIGH_OFFSET
                                        __Pattern(i, row, chan).operand = __Pattern(i, row, chan).operand AND &HF

                                    CASE &HB ' SB0 Pattern Loop Start
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_PATTERN_LOOP, 4) OR (__Pattern(i, row, chan).operand AND &HF) ' SBx

                                    CASE &HC ' SCx Note Cut
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_NOTE_CUT, 4) OR (__Pattern(i, row, chan).operand AND &HF) ' SCx

                                    CASE &HD ' SDx Note Delay
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_NOTE_DELAY, 4) OR (__Pattern(i, row, chan).operand AND &HF) ' SDx

                                    CASE &HE ' SEx Pattern Delay
                                        __Pattern(i, row, chan).effect = __MOD_FX_EXTENDED
                                        __Pattern(i, row, chan).operand = _SHL(__MOD_FX_EXTENDED_PATTERN_DELAY, 4) OR (__Pattern(i, row, chan).operand AND &HF) ' SEx

                                        'CASE ELSE
                                        '    ' Trap for unhandled stuff
                                        '    _ECHO "Uhandled special effect:" + STR$(__Pattern(i, row, chan).operand) + " |" + STR$(_SHR(__Pattern(i, row, chan).operand, 4))
                                END SELECT

                            CASE &H14 ' Txx Tempo
                                __Pattern(i, row, chan).effect = __MOD_FX_TEMPO

                            CASE &H15 ' Uxy Fine Vibrato
                                __Pattern(i, row, chan).effect = __MOD_FX_VIBRATO_FINE

                            CASE &H16 ' Vxx Set Global Volume
                                __Pattern(i, row, chan).effect = __MOD_FX_GLOBAL_VOLUME

                            CASE &H17 ' Wxy Global Volume Slide
                                __Pattern(i, row, chan).effect = __MOD_FX_GLOBAL_VOLUME_SLIDE

                            CASE &H18 ' Xxx Set Panning
                                IF __Pattern(i, row, chan).operand <= 128 THEN
                                    ' Ranges from 0 (left) to 128 (right)
                                    __Pattern(i, row, chan).effect = __MOD_FX_PANNING_8
                                    __Pattern(i, row, chan).operand = (__Pattern(i, row, chan).operand * 255&) \ 128&
                                else
                                    ' If it is anything else, then we'll simply ignore the effect
                                    __Pattern(i, row, chan).effect = &H0
                                    __Pattern(i, row, chan).operand = &H0
                                END IF

                            CASE &H19 ' Yxy Panbrello
                                __Pattern(i, row, chan).effect = __MOD_FX_PANBRELLO

                            CASE &H20 ' Zxx MIDI Macro
                                __Pattern(i, row, chan).effect = __MOD_FX_MIDI_MACRO

                                'CASE ELSE
                                '    ' Trap for unhandled stuff
                                '    _ECHO "Uhandled effect:" + STR$(__Pattern(i, row, chan).effect)
                        END SELECT
                    END IF
                END IF
            ELSE ' end of row; move to the next one
                row = row + 1
            END IF
        WEND
    NEXT i

    ' Read the PCM instrument sample data
    FOR i = 0 TO __Song.instruments - 1
        IF __Instrument(i).subtype > __INSTRUMENT_PCM THEN
            ' TODO: Can this happen? Probably a corrupt file?
            ERROR _ERR_FEATURE_UNAVAILABLE
        ELSE
            ' Seek to the correct position in the file to read the PCM instrument sample data
            StringFile_Seek memFile, instrumentPointer(i)

            DIM sampBuf AS STRING

            ' Load the data
            IF isSampleCompressed(i) THEN
                ' Decode ADPCM samples before sending it to the SoftSynth!
                DIM compressionTable AS STRING * 16: compressionTable = StringFile_ReadString(memFile, LEN(compressionTable))
                sampBuf = AudioConv_ConvertADPCM4ToS8(StringFile_ReadString(memFile, _SHR(__Instrument(i).length + 1, 1)), compressionTable)
                '_ECHO "Decompressed to S8:" + STR$(i)
            ELSE
                sampBuf = StringFile_ReadString(memFile, __Instrument(i).length)

                ' Convert unsigned samples to signed if unsigned flag was set
                ' This is not needed if the sample is ADPCM4 compressed
                IF isUnsignedFormat THEN
                    IF __Instrument(i).bytesPerSample = _SIZE_OF_INTEGER THEN
                        ' Apparently 16-bit audio data is also unsigned when the unsigned flag is set! Fuck!
                        AudioConv_ConvertU16ToS16 sampBuf
                        '_ECHO "Converted to S16:" + STR$(i)
                    ELSE
                        ' Else we'll assume these are 8-bit samples
                        AudioConv_ConvertU8ToS8 sampBuf
                        '_ECHO "Converted to S8:" + STR$(i)
                    END IF
                END IF

                ' Stereo sample data is not interleaved! This should be fixed before sending it to the SoftSynth!
                ' Again, this is not needed if the sample is ADPCM4 compressed
                IF __Instrument(i).channels = 2 THEN
                    IF __Instrument(i).bytesPerSample = _SIZE_OF_INTEGER THEN
                        sampBuf = AudioConv_ConvertDualMonoToStereoS16(sampBuf)
                        '_ECHO "Fixed S16 stereo data:" + STR$(i)
                    ELSE
                        sampBuf = AudioConv_ConvertDualMonoToStereoS8(sampBuf)
                        '_ECHO "Fixed S8 stereo data:" + STR$(i)
                    END IF
                END IF
            END IF

            ' Load sample size bytes of data and send it to our softsynth sample manager
            ' Sounds with zero frames will not cause any issues
            SoftSynth_LoadSound __MODPlayer_Synth, i, sampBuf, __Instrument(i).bytesPerSample, __Instrument(i).channels
        END IF
    NEXT i

    ' Load all needed LUTs
    __MODPlayer_LoadTables

    ' What a fucked up format!
    S3MLoader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Loads a Scream Tracker 3 (S3M) module from a file on disk or URL.
''' @param fileName File path or URL to load.
''' @return _TRUE if the module was loaded, _FALSE otherwise.
FUNCTION S3MLoader_LoadFromDisk%% (fileName AS STRING)
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    S3MLoader_LoadFromDisk = S3MLoader_LoadFromMemory(File_Load(fileName))
END FUNCTION
