'-----------------------------------------------------------------------------------------------------------------------
' UltraTracker (ULT) Module Loader
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

CONST __ULTLOADER_MAGIC_PREFIX = "MAS_UTrack_V00"
CONST __ULTLOADER_HEADER_MIN_SIZE = 48
CONST __ULTLOADER_MAX_SAMPLES = 64
CONST __ULTLOADER_MAX_CHANNELS = 32
CONST __ULTLOADER_MAX_PATTERNS = 128
CONST __ULTLOADER_DEFAULT_BPM = 125
CONST __ULTLOADER_DEFAULT_SPEED = 6

''' @brief Translates an UltraTracker effect nibble and parameter into a MODPlayer effect or volume.
''' @param cmd 4-bit effect command nibble (0-15).
''' @param param 8-bit effect parameter.
''' @param version Tracker version (1=v1.3, 2=v1.4, 3=v1.5, 4=v1.6).
''' @param outEffect Output MODPlayer effect constant.
''' @param outOperand Output effect parameter.
''' @param outVolume Output volume (0-64), or __MODPLAYER_NOTE_NO_VOLUME (255) if not a volume command.
SUB __ULTLoader_TranslateEffect (cmd AS _UNSIGNED _BYTE, param AS _UNSIGNED _BYTE, version AS _UNSIGNED _BYTE, outEffect AS _UNSIGNED _BYTE, outOperand AS _UNSIGNED _BYTE, outVolume AS _UNSIGNED _BYTE)
    outEffect = 0
    outOperand = 0
    outVolume = __MODPLAYER_NOTE_NO_VOLUME

    SELECT CASE cmd AND &H0F
        CASE &H00 ' Arpeggio (only active if param > 0 and version >= 3)
            IF param > 0 AND version >= 3 THEN
                outEffect = __MODPLAYER_FX_ARPEGGIO
                outOperand = param
            END IF

        CASE &H01 ' Portamento Up
            outEffect = __MODPLAYER_FX_PORTAMENTO_UP
            outOperand = param

        CASE &H02 ' Portamento Down
            outEffect = __MODPLAYER_FX_PORTAMENTO_DOWN
            outOperand = param

        CASE &H03 ' Tone Portamento
            outEffect = __MODPLAYER_FX_PORTAMENTO
            outOperand = param

        CASE &H04 ' Vibrato
            outEffect = __MODPLAYER_FX_VIBRATO
            outOperand = param

        CASE &H05 ' Special (Key-off and reverse playback handled in caller)
            ' Handled in caller

        CASE &H07 ' Tremolo (version >= 4)
            IF version >= 4 THEN
                outEffect = __MODPLAYER_FX_TREMOLO
                outOperand = param
            END IF

        CASE &H09 ' Sample Offset (multiples of 1024 GUS bytes -> scale by 4 for 256-byte steps)
            outEffect = __MODPLAYER_FX_SAMPLE_OFFSET
            DIM ofs AS LONG: ofs = CLNG(param) * 4
            IF ofs > 255 THEN ofs = 255
            outOperand = ofs

        CASE &H0A ' Volume Slide
            DIM vsParam AS _UNSIGNED _BYTE: vsParam = param
            IF (vsParam AND &HF0) THEN vsParam = vsParam AND &HF0
            outEffect = __MODPLAYER_FX_VOLUME_SLIDE
            outOperand = vsParam

        CASE &H0B ' Set Panning / Balance (0-15 -> 0-255)
            outEffect = __MODPLAYER_FX_PANNING_8
            outOperand = (param AND &H0F) * 17

        CASE &H0C ' Set Volume (0-255 -> 0-64)
            outVolume = _CLAMP((CLNG(param) * 64 + 128) \ 255, 0, 64)

        CASE &H0D ' Pattern Break (decimal encoded in hex/BCD: 0x20 = row 20)
            outEffect = __MODPLAYER_FX_PATTERN_BREAK
            outOperand = param

        CASE &H0E ' Extended Effects
            DIM eSub AS _UNSIGNED _BYTE: eSub = _SHR(param, 4)
            DIM eVal AS _UNSIGNED _BYTE: eVal = param AND &H0F
            SELECT CASE eSub
                CASE &H01 ' Fine Portamento Up
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &H10 OR eVal
                CASE &H02 ' Fine Portamento Down
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &H20 OR eVal
                CASE &H08 ' Pattern Loop (version >= 4)
                    IF version >= 4 THEN
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &H60 OR eVal
                    END IF
                CASE &H09 ' Retrigger Note
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &H90 OR eVal
                CASE &H0A ' Fine Volume Slide Up
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &HA0 OR eVal
                CASE &H0B ' Fine Volume Slide Down
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &HB0 OR eVal
                CASE &H0C ' Note Cut
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &HC0 OR eVal
                CASE &H0D ' Note Delay
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &HD0 OR eVal
            END SELECT

        CASE &H0F ' Speed / BPM
            IF param = 0 THEN
                outEffect = __MODPLAYER_FX_SPEED
                outOperand = 6
            ELSEIF param < &H30 THEN
                outEffect = __MODPLAYER_FX_SPEED
                outOperand = param
            ELSE
                outEffect = __MODPLAYER_FX_TEMPO
                outOperand = param
            END IF
    END SELECT
END SUB

''' @brief Parses and loads an UltraTracker (ULT) module from a memory buffer.
''' @param player The MOD player instance.
''' @param buffer In-memory binary representation of the ULT file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION ULTLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    DIM memFile AS StringFile
    StringFile_Create memFile, buffer

    IF StringFile_GetSize(memFile) < __ULTLOADER_HEADER_MIN_SIZE THEN EXIT FUNCTION

    DIM magic AS STRING: magic = StringFile_ReadString(memFile, 15)
    IF LEFT$(magic, 14) <> __ULTLOADER_MAGIC_PREFIX THEN EXIT FUNCTION

    DIM verChar AS _UNSIGNED _BYTE: verChar = ASC(magic, 15)
    IF verChar < 49 _ORELSE verChar > 52 THEN EXIT FUNCTION ' '1' through '4'
    DIM version AS _UNSIGNED _BYTE: version = verChar - 48

    ' Song title (32 bytes)
    DIM songName AS STRING: songName = StringFile_ReadString(memFile, 32)

    ' Song message lines (1 byte)
    DIM msgLines AS _UNSIGNED _BYTE: msgLines = StringFile_ReadByte(memFile)

    ' Initialize player synthesizer
    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION

    ' Set song globals
    player.song.caption = String_MakePrintable(String_ConvertToBStr(songName))
    player.song.comment = _STR_EMPTY
    player.song.speed = __ULTLOADER_DEFAULT_SPEED
    player.song.defaultSpeed = __ULTLOADER_DEFAULT_SPEED
    player.song.BPM = __ULTLOADER_DEFAULT_BPM
    player.song.defaultBPM = __ULTLOADER_DEFAULT_BPM
    player.song.useAmigaLimits = _FALSE
    player.song.useAmigaSlides = _FALSE
    player.song.useVolumeOptimization = _FALSE
    player.song.useFilterSFX = _FALSE
    player.song.isS3M = _FALSE
    player.song.isRAD = _FALSE
    player.song.isULT = _TRUE
    player.song.isStereo = _TRUE
    player.song.hasFMChannels = _FALSE
    player.song.subtype = "ULT" + CHR$(verChar)

    ' Read song text message if present (version >= 2)
    IF version >= 2 _ANDALSO msgLines > 0 THEN
        DIM msgBytes AS _UNSIGNED LONG: msgBytes = CLNG(msgLines) * 32
        IF StringFile_GetPosition(memFile) + msgBytes <= StringFile_GetSize(memFile) THEN
            DIM comments AS STRING: comments = _STR_EMPTY
            DIM mLine AS LONG
            FOR mLine = 1 TO msgLines
                DIM lineText AS STRING: lineText = _TRIM$(StringFile_ReadString(memFile, 32))
                IF LEN(comments) > 0 THEN
                    comments = comments + _STR_CRLF + lineText
                ELSE
                    comments = lineText
                END IF
            NEXT mLine
            player.song.comment = comments
        ELSE
            StringFile_Seek memFile, StringFile_GetPosition(memFile) + msgBytes
        END IF
    END IF

    IF StringFile_IsEOF(memFile) THEN EXIT FUNCTION

    ' Number of samples
    DIM numSamples AS _UNSIGNED _BYTE: numSamples = StringFile_ReadByte(memFile)
    IF numSamples > __ULTLOADER_MAX_SAMPLES THEN EXIT FUNCTION

    player.song.instruments = numSamples
    IF player.song.instruments > 0 THEN
        REDIM player.instrument(0 TO player.song.instruments - 1) AS __MODPLAYERINSTRUMENT
    END IF

    ' Read sample headers
    DIM s AS LONG
    FOR s = 0 TO player.song.instruments - 1
        DIM sName AS STRING: sName = StringFile_ReadString(memFile, 32)
        DIM dosName AS STRING: dosName = StringFile_ReadString(memFile, 12)
        DIM loopStart AS _UNSIGNED LONG: loopStart = StringFile_ReadLong(memFile)
        DIM loopEnd AS _UNSIGNED LONG: loopEnd = StringFile_ReadLong(memFile)
        DIM sizeStart AS _UNSIGNED LONG: sizeStart = StringFile_ReadLong(memFile)
        DIM sizeEnd AS _UNSIGNED LONG: sizeEnd = StringFile_ReadLong(memFile)
        DIM volByte AS _UNSIGNED _BYTE: volByte = StringFile_ReadByte(memFile)
        DIM flags AS _UNSIGNED _BYTE: flags = StringFile_ReadByte(memFile)
        DIM c2spd AS _UNSIGNED LONG: c2spd = 8363
        DIM finetune AS INTEGER: finetune = 0

        IF version >= 4 THEN
            c2spd = StringFile_ReadInteger(memFile)
            finetune = _CAST(INTEGER, StringFile_ReadInteger(memFile))
        ELSE
            finetune = _CAST(INTEGER, StringFile_ReadInteger(memFile))
            c2spd = 8363
        END IF

        DIM smpLength AS _UNSIGNED LONG: smpLength = 0
        IF sizeEnd > sizeStart THEN
            smpLength = sizeEnd - sizeStart
        END IF

        ' Apply finetune adjustment
        IF c2spd = 0 THEN c2spd = 8363
        IF finetune <> 0 THEN
            c2spd = _ROUND(c2spd * (2.0! ^ (CSNG(finetune) / 393216.0!)))
            IF c2spd = 0 THEN c2spd = 8363
        END IF

        player.instrument(s).caption = String_MakePrintable(String_ConvertToBStr(sName))
        IF LEN(player.instrument(s).caption) = 0 THEN
            player.instrument(s).caption = String_MakePrintable(String_ConvertToBStr(dosName))
        END IF

        player.instrument(s).length = smpLength
        player.instrument(s).c2Spd = c2spd
        player.instrument(s).volume = _CLAMP((CLNG(volByte) * 64 + 128) \ 255, 0, 64)
        player.instrument(s).channels = 1
        player.instrument(s).subtype = __MODPLAYER_INSTRUMENT_PCM

        IF (flags AND 4) THEN
            player.instrument(s).bytesPerSample = 2 ' 16-bit signed PCM
        ELSE
            player.instrument(s).bytesPerSample = 1 ' 8-bit signed PCM
        END IF

        DIM smpBytes AS _UNSIGNED LONG: smpBytes = smpLength * CLNG(player.instrument(s).bytesPerSample)
        player.instrument(s).length = smpBytes

        ' Loop setup
        ' In ULT: Bit 3 (8) = loop, Bit 4 (16) = bidi loop
        ' Values: 8=forward 8-bit, 12=forward 16-bit, 16/20/24/28=bidi
        IF (flags AND 24) _ANDALSO smpBytes > 0 _ANDALSO loopEnd > loopStart _ANDALSO loopStart < smpBytes THEN
            DIM safeLoopEnd AS _UNSIGNED LONG: safeLoopEnd = _MIN(loopEnd, smpBytes)
            IF safeLoopEnd > loopStart THEN
                IF (flags AND 16) THEN
                    player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_BIDIRECTIONAL_LOOP
                ELSE
                    player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
                END IF
                player.instrument(s).loopStart = loopStart
                player.instrument(s).loopEnd = safeLoopEnd
            ELSE
                player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                player.instrument(s).loopStart = 0
                player.instrument(s).loopEnd = smpBytes
            END IF
        ELSE
            player.instrument(s).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            player.instrument(s).loopStart = 0
            player.instrument(s).loopEnd = smpBytes
        END IF
    NEXT s

    ' Read order sequence (256 bytes)
    DIM rawOrders(0 TO 255) AS _UNSIGNED _BYTE
    DIM oCount AS LONG: oCount = 0
    DIM oIdx AS LONG
    FOR oIdx = 0 TO 255
        rawOrders(oIdx) = StringFile_ReadByte(memFile)
    NEXT oIdx

    FOR oIdx = 0 TO 255
        IF rawOrders(oIdx) = 255 THEN EXIT FOR
        oCount = oCount + 1
    NEXT oIdx

    IF oCount = 0 THEN
        oCount = 1
        rawOrders(0) = 0
    END IF

    player.song.orders = oCount
    REDIM player.order(0 TO oCount - 1) AS _UNSIGNED INTEGER
    FOR oIdx = 0 TO oCount - 1
        player.order(oIdx) = rawOrders(oIdx)
    NEXT oIdx

    ' Channels and Patterns count (Base 0)
    DIM numChannels AS _UNSIGNED _BYTE: numChannels = StringFile_ReadByte(memFile) + 1
    DIM numPatterns AS _UNSIGNED _BYTE: numPatterns = StringFile_ReadByte(memFile) + 1

    IF numChannels < 1 _ORELSE numChannels > __ULTLOADER_MAX_CHANNELS THEN EXIT FUNCTION
    IF numPatterns < 1 _ORELSE numPatterns > __ULTLOADER_MAX_PATTERNS THEN EXIT FUNCTION

    player.song.channels = numChannels
    player.song.patterns = numPatterns

    REDIM player.channel(0 TO numChannels - 1) AS __MODPLAYERCHANNEL

    ' Read channel panning table
    DIM ch AS LONG
    IF version >= 3 THEN
        FOR ch = 0 TO numChannels - 1
            DIM pVal AS _UNSIGNED _BYTE: pVal = StringFile_ReadByte(memFile) AND &H0F
            __MODPlayer_SetChannelPanning player, ch, pVal * 17
        NEXT ch
    ELSE
        FOR ch = 0 TO numChannels - 1
            IF (ch AND 1) THEN
                __MODPlayer_SetChannelPanning player, ch, 192
            ELSE
                __MODPlayer_SetChannelPanning player, ch, 64
            END IF
        NEXT ch
    END IF

    ' Allocate patterns (64 rows each)
    REDIM player.pattern(0 TO numPatterns - 1) AS __MODPLAYERPATTERN
    DIM p AS LONG, r AS LONG
    FOR p = 0 TO numPatterns - 1
        player.pattern(p).rows = 64
        REDIM player.pattern(p).note(0 TO 63, 0 TO numChannels - 1) AS __MODPLAYERNOTE
        FOR r = 0 TO 63
            FOR ch = 0 TO numChannels - 1
                player.pattern(p).note(r, ch).note = __MODPLAYER_NOTE_NONE
                player.pattern(p).note(r, ch).instrument = 0
                player.pattern(p).note(r, ch).volume = __MODPLAYER_NOTE_NO_VOLUME
                player.pattern(p).note(r, ch).effect = 0
                player.pattern(p).note(r, ch).operand = 0
            NEXT ch
        NEXT r
    NEXT p

    ' Read and unpack pattern data (stored channel-by-channel across all patterns)
    FOR ch = 0 TO numChannels - 1
        FOR p = 0 TO numPatterns - 1
            r = 0
            WHILE r < 64 AND NOT StringFile_IsEOF(memFile)
                DIM x8 AS _UNSIGNED _BYTE: x8 = StringFile_ReadByte(memFile)
                DIM repeatCount AS _UNSIGNED _BYTE: repeatCount = 1

                IF x8 = &HFC THEN
                    repeatCount = StringFile_ReadByte(memFile)
                    x8 = StringFile_ReadByte(memFile)
                END IF

                DIM insByte AS _UNSIGNED _BYTE: insByte = StringFile_ReadByte(memFile)
                DIM fxtByte AS _UNSIGNED _BYTE: fxtByte = StringFile_ReadByte(memFile)
                DIM f2pByte AS _UNSIGNED _BYTE: f2pByte = StringFile_ReadByte(memFile)
                DIM fxpByte AS _UNSIGNED _BYTE: fxpByte = StringFile_ReadByte(memFile)

                IF repeatCount = 0 THEN repeatCount = 1
                IF r + repeatCount > 64 THEN repeatCount = 64 - r

                ' Note decoding
                DIM decNote AS _UNSIGNED _BYTE
                IF x8 >= 1 AND x8 <= 96 THEN
                    decNote = x8 + 23
                ELSE
                    decNote = __MODPLAYER_NOTE_NONE
                END IF

                ' Instrument
                DIM decIns AS _UNSIGNED INTEGER: decIns = insByte

                ' Effect 1 (primary) and Effect 2 (secondary)
                DIM cmd1 AS _UNSIGNED _BYTE: cmd1 = _SHR(fxtByte, 4)
                DIM param1 AS _UNSIGNED _BYTE: param1 = fxpByte
                DIM cmd2 AS _UNSIGNED _BYTE: cmd2 = fxtByte AND &H0F
                DIM param2 AS _UNSIGNED _BYTE: param2 = f2pByte

                ' Check for Key-off special effect (50C / 5C0 in version >= 3)
                IF (cmd1 = &H05 _ANDALSO ((param1 AND &H0F) = &H0C _ORELSE (param1 AND &HF0) = &HC0) _ANDALSO version >= 3) _ORELSE _
                   (cmd2 = &H05 _ANDALSO ((param2 AND &H0F) = &H0C _ORELSE (param2 AND &HF0) = &HC0) _ANDALSO version >= 3) THEN
                    decNote = __MODPLAYER_NOTE_KEY_OFF
                END IF

                DIM eff1 AS _UNSIGNED _BYTE, op1 AS _UNSIGNED _BYTE, vol1 AS _UNSIGNED _BYTE
                DIM eff2 AS _UNSIGNED _BYTE, op2 AS _UNSIGNED _BYTE, vol2 AS _UNSIGNED _BYTE

                __ULTLoader_TranslateEffect cmd1, param1, version, eff1, op1, vol1
                __ULTLoader_TranslateEffect cmd2, param2, version, eff2, op2, vol2

                ' Volume
                DIM decVol AS _UNSIGNED _BYTE: decVol = __MODPLAYER_NOTE_NO_VOLUME
                IF vol1 <= 64 THEN decVol = vol1
                IF vol2 <= 64 THEN decVol = vol2

                ' Effect combination
                DIM decEff AS _UNSIGNED _BYTE: decEff = 0
                DIM decOp AS _UNSIGNED _BYTE: decOp = 0
                DIM extraEff AS _UNSIGNED _BYTE: extraEff = 0
                DIM extraOp AS _UNSIGNED _BYTE: extraOp = 0

                IF eff1 > 0 AND eff2 = 0 THEN
                    decEff = eff1: decOp = op1
                ELSEIF eff2 > 0 AND eff1 = 0 THEN
                    decEff = eff2: decOp = op2
                ELSEIF eff1 > 0 AND eff2 > 0 THEN
                    DIM isGlobal1 AS _BYTE, isGlobal2 AS _BYTE
                    isGlobal1 = (eff1 = __MODPLAYER_FX_SPEED _ORELSE eff1 = __MODPLAYER_FX_TEMPO _ORELSE eff1 = __MODPLAYER_FX_PATTERN_BREAK)
                    isGlobal2 = (eff2 = __MODPLAYER_FX_SPEED _ORELSE eff2 = __MODPLAYER_FX_TEMPO _ORELSE eff2 = __MODPLAYER_FX_PATTERN_BREAK)

                    IF isGlobal1 AND NOT isGlobal2 THEN
                        decEff = eff2: decOp = op2
                        extraEff = eff1: extraOp = op1
                    ELSEIF isGlobal2 AND NOT isGlobal1 THEN
                        decEff = eff1: decOp = op1
                        extraEff = eff2: extraOp = op2
                    ELSE
                        decEff = eff1: decOp = op1
                        extraEff = eff2: extraOp = op2
                    END IF
                END IF

                ' Write to pattern note matrix across repeated rows
                DIM k AS LONG
                FOR k = 0 TO repeatCount - 1
                    DIM curRow AS LONG: curRow = r + k
                    player.pattern(p).note(curRow, ch).note = decNote
                    player.pattern(p).note(curRow, ch).instrument = decIns
                    player.pattern(p).note(curRow, ch).volume = decVol
                    player.pattern(p).note(curRow, ch).effect = decEff
                    player.pattern(p).note(curRow, ch).operand = decOp

                    ' If there is an extra global effect, try to host it on an earlier vacant channel
                    IF extraEff > 0 THEN
                        DIM altCh AS LONG
                        FOR altCh = 0 TO ch - 1
                            IF player.pattern(p).note(curRow, altCh).effect = 0 THEN
                                player.pattern(p).note(curRow, altCh).effect = extraEff
                                player.pattern(p).note(curRow, altCh).operand = extraOp
                                EXIT FOR
                            END IF
                        NEXT altCh
                    END IF
                NEXT k

                r = r + repeatCount
            WEND
        NEXT p
    NEXT ch

    ' Load sample PCM audio data into SoftSynth
    FOR s = 0 TO player.song.instruments - 1
        IF player.instrument(s).length > 0 THEN
            DIM bytesToRead AS _UNSIGNED LONG
            bytesToRead = player.instrument(s).length
            IF StringFile_GetPosition(memFile) + bytesToRead <= StringFile_GetSize(memFile) THEN
                DIM sampData AS STRING: sampData = StringFile_ReadString(memFile, bytesToRead)
                SoftSynth_LoadSound player.synth, s, sampData, player.instrument(s).bytesPerSample, 1
            ELSE
                ' Truncated sample data - read whatever is left
                DIM remainingBytes AS _UNSIGNED LONG
                remainingBytes = StringFile_GetSize(memFile) - StringFile_GetPosition(memFile)
                IF remainingBytes > 0 THEN
                    DIM partialData AS STRING: partialData = StringFile_ReadString(memFile, remainingBytes)
                    SoftSynth_LoadSound player.synth, s, partialData, player.instrument(s).bytesPerSample, 1
                END IF
            END IF
        END IF
    NEXT s

    ' Setup master gain and voice panning
    DIM pcmPreAmp AS LONG: pcmPreAmp = _CLAMP(256 \ player.song.channels, 32, 64)
    player.song.pcmMasterGain = CSNG(pcmPreAmp) / 128.0!
    SoftSynth_SetTotalVoices player.synth, numChannels

    FOR ch = 0 TO numChannels - 1
        SoftSynth_SetVoiceBalance player.synth, ch, (CSNG(player.channel(ch).defaultPanning) / 255!) * 2! - 1!
    NEXT ch

    __MODPlayer_LoadTables

    ULTLoader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Loads an UltraTracker (ULT) module from a disk file.
''' @param player The MOD player instance.
''' @param fileName Path to the module file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION ULTLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    DIM buffer AS STRING: buffer = File_Load(fileName)
    IF LEN(buffer) = 0 THEN EXIT FUNCTION
    ULTLoader_LoadFromDisk = ULTLoader_LoadFromMemory(player, buffer)
END FUNCTION
