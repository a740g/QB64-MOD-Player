'-----------------------------------------------------------------------------------------------------------------------
' Digitrakker (MDL) Module Loader
' Supports Digitrakker v0.0 (v2.0), v1.0 (v2.9/3.0 early), and v1.1 (v3.0+)
' Handles 4 to 32 channels, 8-bit and 16-bit signed PCM samples, 8-bit/16-bit Huffman delta decompression,
' multi-sample instruments, bidirectional looping, and dual-effects.
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'File.bi'
'$INCLUDE:'StringFile.bi'
'$INCLUDE:'MODPlayer.bi'

CONST __MDLLOADER_MAGIC = "DMDL"
CONST __MDLLOADER_MAX_CHANNELS = 32
CONST __MDLLOADER_MAX_SAMPLES = 255
CONST __MDLLOADER_MAX_INSTRUMENTS = 255
CONST __MDLLOADER_MAX_TRACKS = 4096

''' @brief Translates Digitrakker effect commands to MODPlayer internal effect representation.
''' @param cmd Command code (low nibble 0-15 for effect 1, or high nibble 1-6 for effect 2 [commands G-L]).
''' @param isEffect2 _TRUE if translating effect 2 (commands G-L), _FALSE for effect 1.
''' @param param Effect operand parameter byte.
''' @param outEffect Output MODPlayer effect constant.
''' @param outOperand Output MODPlayer effect operand.
''' @param outVolume Output volume (0-64), or __MODPLAYER_NOTE_NO_VOLUME (255) if not a volume command.
SUB __MDLLoader_TranslateEffect (cmd AS _UNSIGNED _BYTE, isEffect2 AS _BYTE, param AS _UNSIGNED _BYTE, outEffect AS _UNSIGNED _BYTE, outOperand AS _UNSIGNED _BYTE, outVolume AS _UNSIGNED _BYTE)
    outEffect = 0
    outOperand = 0
    outVolume = __MODPLAYER_NOTE_NO_VOLUME

    IF isEffect2 THEN
        SELECT CASE cmd
            CASE 1 ' Gxx / GFx / GEx - Volume Slide Up
                IF param >= &HF0 THEN
                    ' Fine Volume Slide Up
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &HA0 OR (param AND &H0F)
                ELSEIF param >= &HE0 THEN
                    ' Extra Fine Volume Slide Up -> approximate as fine 1
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &HA1
                ELSE
                    outEffect = __MODPLAYER_FX_VOLUME_SLIDE
                    outOperand = _SHL(_CLAMP(param, 0, 15), 4)
                END IF

            CASE 2 ' Hxx / HFx / HEx - Volume Slide Down
                IF param >= &HF0 THEN
                    ' Fine Volume Slide Down
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &HB0 OR (param AND &H0F)
                ELSEIF param >= &HE0 THEN
                    ' Extra Fine Volume Slide Down -> approximate as fine 1
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &HB1
                ELSE
                    outEffect = __MODPLAYER_FX_VOLUME_SLIDE
                    outOperand = _CLAMP(param, 0, 15)
                END IF

            CASE 3 ' Ixy - Multi Retrig Note
                outEffect = __MODPLAYER_FX_EXT
                outOperand = &H90 OR (param AND &H0F)

            CASE 4 ' Jxy - Tremolo
                outEffect = __MODPLAYER_FX_TREMOLO
                outOperand = param

            CASE 5 ' Kxy - Tremor
                outEffect = __MODPLAYER_FX_EXT
                outOperand = &H90 OR (param AND &H0F)

            CASE 6 ' Lxx - Reserved
        END SELECT
    ELSE
        SELECT CASE cmd
            CASE &H01 ' 1xx / 1Fx / 1Ex - Note Slide Up (Portamento Up)
                IF param >= &HF0 THEN
                    ' Fine Portamento Up
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &H10 OR (param AND &H0F)
                ELSEIF param >= &HE0 THEN
                    ' Extra Fine Portamento Up -> fine 1
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &H11
                ELSE
                    outEffect = __MODPLAYER_FX_PORTAMENTO_UP
                    outOperand = param
                END IF

            CASE &H02 ' 2xx / 2Fx / 2Ex - Note Slide Down (Portamento Down)
                IF param >= &HF0 THEN
                    ' Fine Portamento Down
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &H20 OR (param AND &H0F)
                ELSEIF param >= &HE0 THEN
                    ' Extra Fine Portamento Down -> fine 1
                    outEffect = __MODPLAYER_FX_EXT
                    outOperand = &H21
                ELSE
                    outEffect = __MODPLAYER_FX_PORTAMENTO_DOWN
                    outOperand = param
                END IF

            CASE &H03 ' 3xx - Tone Portamento
                outEffect = __MODPLAYER_FX_PORTAMENTO
                outOperand = param

            CASE &H04 ' 4xy - Vibrato
                outEffect = __MODPLAYER_FX_VIBRATO
                outOperand = param

            CASE &H05 ' 5xy - Arpeggio
                outEffect = __MODPLAYER_FX_ARPEGGIO
                outOperand = param

            CASE &H07 ' 7xx - Set BPM (Tempo)
                outEffect = __MODPLAYER_FX_TEMPO
                outOperand = param

            CASE &H08 ' 8xx - Set Panning (0-127 -> 0-255)
                outEffect = __MODPLAYER_FX_PANNING_8
                outOperand = _CLAMP(CLNG(param) * 2, 0, 255)

            CASE &H09 ' 9xx - Set Envelope (Ignored in basic replayer)

            CASE &H0B ' Bxx - Position Jump
                outEffect = __MODPLAYER_FX_POSITION_JUMP
                outOperand = param

            CASE &H0C ' Cxx - Set Global Volume (0-255 -> 0-64)
                outEffect = __MODPLAYER_FX_VOLUME
                outVolume = _CLAMP((CLNG(param) * 64 + 128) \ 255, 0, 64)

            CASE &H0D ' Dxx - Pattern Break (row index directly)
                outEffect = __MODPLAYER_FX_PATTERN_BREAK
                outOperand = param

            CASE &H0E ' Extended Effects
                DIM eSub AS _UNSIGNED _BYTE: eSub = _SHR(param, 4)
                DIM eVal AS _UNSIGNED _BYTE: eVal = param AND &H0F
                SELECT CASE eSub
                    CASE &H01 ' Pan slide left -> approximate panning
                        outEffect = __MODPLAYER_FX_PANNING_8
                        outOperand = 0
                    CASE &H02 ' Pan slide right
                        outEffect = __MODPLAYER_FX_PANNING_8
                        outOperand = 255
                    CASE &H04 ' Vibrato Waveform
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &H40 OR eVal
                    CASE &H05 ' Set Finetune
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &H50 OR eVal
                    CASE &H06 ' Pattern Loop
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &H60 OR eVal
                    CASE &H07 ' Tremolo Waveform
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &H70 OR eVal
                    CASE &H09 ' Retrig Note
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &H90 OR eVal
                    CASE &H0C ' Note Cut
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &HC0 OR eVal
                    CASE &H0D ' Note Delay
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &HD0 OR eVal
                    CASE &H0E ' Pattern Delay
                        outEffect = __MODPLAYER_FX_EXT
                        outOperand = &HE0 OR eVal
                    CASE &H0F ' Sample Offset
                        outEffect = __MODPLAYER_FX_SAMPLE_OFFSET
                        outOperand = eVal
                END SELECT

            CASE &H0F ' Fxx - Set Speed
                outEffect = __MODPLAYER_FX_SPEED
                outOperand = param
        END SELECT
    END IF
END SUB

''' @brief Decompresses a Digitrakker Huffman-delta audio sample bitstream.
''' @param buffer Binary string holding file contents.
''' @param startOffset Offset into buffer where the sample payload starts (1-based).
''' @param packLen Length of compressed bitstream in bytes (excluding the 4-byte header).
''' @param sampleFrames Number of sample frames to decompress.
''' @param is16Bit _TRUE if 16-bit signed PCM, _FALSE if 8-bit.
''' @return Decompressed signed PCM sample string.
FUNCTION __MDLLoader_DecompressSample$ (buffer AS STRING, startOffset AS _UNSIGNED LONG, packLen AS _UNSIGNED LONG, sampleFrames AS _UNSIGNED LONG, is16Bit AS _BYTE)
    IF sampleFrames = 0 THEN
        __MDLLoader_DecompressSample = _STR_EMPTY
        EXIT FUNCTION
    END IF

    DIM outBuf AS STRING
    IF is16Bit THEN
        outBuf = STRING$(sampleFrames * 2, 0)
    ELSE
        outBuf = STRING$(sampleFrames, 0)
    END IF

    DIM curByte AS _UNSIGNED LONG: curByte = startOffset
    DIM endByte AS _UNSIGNED LONG: endByte = startOffset + packLen - 1
    IF endByte > LEN(buffer) THEN endByte = LEN(buffer)

    DIM bitBuffer AS _UNSIGNED _INTEGER64: bitBuffer = 0
    DIM bitsLeft AS LONG: bitsLeft = 0
    DIM lastAccum AS LONG: lastAccum = 0
    DIM f AS _UNSIGNED LONG

    IF is16Bit THEN
        ' 16-bit packing: low byte is raw 8 bits, high byte is delta-Huffman compressed
        FOR f = 1 TO sampleFrames
            DO WHILE bitsLeft <= 24 AND curByte <= endByte
                bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                curByte = curByte + 1
                bitsLeft = bitsLeft + 8
            LOOP

            ' Read 8-bit raw low byte
            DIM lowByte AS _UNSIGNED _BYTE
            lowByte = bitBuffer AND &HFF
            bitBuffer = _SHR(bitBuffer, 8)
            bitsLeft = bitsLeft - 8

            DO WHILE bitsLeft <= 24 AND curByte <= endByte
                bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                curByte = curByte + 1
                bitsLeft = bitsLeft + 8
            LOOP

            ' Read sign bit and branch bit
            DIM sign AS _UNSIGNED _BYTE: sign = bitBuffer AND 1
            DIM branch AS _UNSIGNED _BYTE: branch = _SHR(bitBuffer, 1) AND 1
            bitBuffer = _SHR(bitBuffer, 2)
            bitsLeft = bitsLeft - 2

            DIM byteVal AS LONG: byteVal = 0
            IF branch = 1 THEN
                DO WHILE bitsLeft < 3 AND curByte <= endByte
                    bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                    curByte = curByte + 1
                    bitsLeft = bitsLeft + 8
                LOOP
                byteVal = bitBuffer AND 7
                bitBuffer = _SHR(bitBuffer, 3)
                bitsLeft = bitsLeft - 3
            ELSE
                byteVal = 8
                DO
                    DO WHILE bitsLeft < 1 AND curByte <= endByte
                        bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                        curByte = curByte + 1
                        bitsLeft = bitsLeft + 8
                    LOOP
                    IF bitsLeft < 1 THEN EXIT DO
                    DIM bBit AS _UNSIGNED _BYTE: bBit = bitBuffer AND 1
                    bitBuffer = _SHR(bitBuffer, 1)
                    bitsLeft = bitsLeft - 1
                    IF bBit = 0 THEN
                        byteVal = byteVal + 16
                    ELSE
                        EXIT DO
                    END IF
                LOOP

                DO WHILE bitsLeft < 4 AND curByte <= endByte
                    bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                    curByte = curByte + 1
                    bitsLeft = bitsLeft + 8
                LOOP
                byteVal = byteVal + (bitBuffer AND 15)
                bitBuffer = _SHR(bitBuffer, 4)
                bitsLeft = bitsLeft - 4
            END IF

            IF sign = 1 THEN byteVal = byteVal XOR &HFF
            lastAccum = (lastAccum + byteVal) AND &HFF

            ' Write 16-bit little-endian sample word (low byte, high byte)
            DIM outPos AS _UNSIGNED LONG: outPos = (f - 1) * 2 + 1
            ASC(outBuf, outPos) = lowByte
            ASC(outBuf, outPos + 1) = lastAccum
        NEXT f
    ELSE
        ' 8-bit packing: whole byte is delta-Huffman compressed
        FOR f = 1 TO sampleFrames
            DO WHILE bitsLeft <= 24 AND curByte <= endByte
                bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                curByte = curByte + 1
                bitsLeft = bitsLeft + 8
            LOOP

            DIM sign8 AS _UNSIGNED _BYTE: sign8 = bitBuffer AND 1
            DIM branch8 AS _UNSIGNED _BYTE: branch8 = _SHR(bitBuffer, 1) AND 1
            bitBuffer = _SHR(bitBuffer, 2)
            bitsLeft = bitsLeft - 2

            DIM byteVal8 AS LONG: byteVal8 = 0
            IF branch8 = 1 THEN
                DO WHILE bitsLeft < 3 AND curByte <= endByte
                    bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                    curByte = curByte + 1
                    bitsLeft = bitsLeft + 8
                LOOP
                byteVal8 = bitBuffer AND 7
                bitBuffer = _SHR(bitBuffer, 3)
                bitsLeft = bitsLeft - 3
            ELSE
                byteVal8 = 8
                DO
                    DO WHILE bitsLeft < 1 AND curByte <= endByte
                        bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                        curByte = curByte + 1
                        bitsLeft = bitsLeft + 8
                    LOOP
                    IF bitsLeft < 1 THEN EXIT DO
                    DIM bBit8 AS _UNSIGNED _BYTE: bBit8 = bitBuffer AND 1
                    bitBuffer = _SHR(bitBuffer, 1)
                    bitsLeft = bitsLeft - 1
                    IF bBit8 = 0 THEN
                        byteVal8 = byteVal8 + 16
                    ELSE
                        EXIT DO
                    END IF
                LOOP

                DO WHILE bitsLeft < 4 AND curByte <= endByte
                    bitBuffer = bitBuffer OR (_SHL(_CAST(_UNSIGNED _INTEGER64, ASC(buffer, curByte)), bitsLeft))
                    curByte = curByte + 1
                    bitsLeft = bitsLeft + 8
                LOOP
                byteVal8 = byteVal8 + (bitBuffer AND 15)
                bitBuffer = _SHR(bitBuffer, 4)
                bitsLeft = bitsLeft - 4
            END IF

            IF sign8 = 1 THEN byteVal8 = byteVal8 XOR &HFF
            lastAccum = (lastAccum + byteVal8) AND &HFF

            ASC(outBuf, f) = lastAccum
        NEXT f
    END IF

    __MDLLoader_DecompressSample = outBuf
END FUNCTION

''' @brief Parses and loads a Digitrakker (MDL) module from a memory buffer.
''' @param player The MOD player instance.
''' @param buffer In-memory binary representation of the MDL file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION MDLLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    MDLLoader_LoadFromMemory = _FALSE

    ' Header check: must be at least 6 bytes and start with "DMDL"
    IF LEN(buffer) < 6 THEN EXIT FUNCTION
    IF MID$(buffer, 1, 4) <> __MDLLOADER_MAGIC THEN EXIT FUNCTION

    DIM version AS _UNSIGNED _BYTE: version = ASC(buffer, 5)
    ' Versions supported: 0x00 (v0.0), 0x10 (v1.0), 0x11 (v1.1)
    IF version <> &H00 AND version <> &H10 AND version <> &H11 THEN EXIT FUNCTION

    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION

    DIM memFile AS StringFile
    StringFile_Create memFile, buffer
    StringFile_Seek memFile, 5 ' skip magic and version

    ' File-level state
    DIM songTitle AS STRING: songTitle = _STR_EMPTY
    DIM composerName AS STRING: composerName = _STR_EMPTY
    DIM songLength AS _UNSIGNED INTEGER: songLength = 0
    DIM songRepeat AS _UNSIGNED INTEGER: songRepeat = 0
    DIM mainVolume AS _UNSIGNED _BYTE: mainVolume = 255
    DIM defaultSpeed AS _UNSIGNED _BYTE: defaultSpeed = 6
    DIM defaultBPM AS _UNSIGNED _BYTE: defaultBPM = 125
    DIM channelPan(0 TO __MDLLOADER_MAX_CHANNELS - 1) AS _UNSIGNED _BYTE
    DIM channelEnabled(0 TO __MDLLOADER_MAX_CHANNELS - 1) AS _BYTE
    DIM activeChannels AS LONG: activeChannels = 0
    DIM orders(0 TO 255) AS _UNSIGNED _BYTE
    DIM comments AS STRING: comments = _STR_EMPTY

    ' Pattern state
    DIM numPatterns AS _UNSIGNED _BYTE: numPatterns = 0
    DIM patChannels(0 TO 255) AS _UNSIGNED _BYTE
    DIM patRows(0 TO 255) AS _UNSIGNED INTEGER
    DIM patTracks(0 TO 255, 0 TO __MDLLOADER_MAX_CHANNELS - 1) AS _UNSIGNED INTEGER

    ' Track storage: each track is stored as a string where each row is 6 bytes:
    ' (note, instrument, volume, fxCmds, fx1Param, fx2Param)
    DIM totalTracks AS _UNSIGNED INTEGER: totalTracks = 0
    REDIM trackRows(0 TO 0) AS _UNSIGNED LONG
    REDIM trackData(0 TO 0) AS STRING

    ' Instrument storage (multi-sample mappings)
    DIM totalInstruments AS _UNSIGNED _BYTE: totalInstruments = 0
    REDIM insMapCount(0 TO __MDLLOADER_MAX_INSTRUMENTS) AS _UNSIGNED _BYTE
    REDIM insMapSmp(0 TO __MDLLOADER_MAX_INSTRUMENTS, 0 TO 15) AS _UNSIGNED _BYTE
    REDIM insMapNote(0 TO __MDLLOADER_MAX_INSTRUMENTS, 0 TO 15) AS _UNSIGNED _BYTE
    REDIM insMapVol(0 TO __MDLLOADER_MAX_INSTRUMENTS, 0 TO 15) AS _UNSIGNED _BYTE

    ' Sample storage
    DIM totalSamples AS _UNSIGNED _BYTE: totalSamples = 0
    REDIM sampleCaption(0 TO __MDLLOADER_MAX_SAMPLES) AS STRING
    REDIM sampleC4Spd(0 TO __MDLLOADER_MAX_SAMPLES) AS _UNSIGNED LONG
    REDIM sampleLength(0 TO __MDLLOADER_MAX_SAMPLES) AS _UNSIGNED LONG
    REDIM sampleLoopStart(0 TO __MDLLOADER_MAX_SAMPLES) AS _UNSIGNED LONG
    REDIM sampleLoopLen(0 TO __MDLLOADER_MAX_SAMPLES) AS _UNSIGNED LONG
    REDIM sampleVolume(0 TO __MDLLOADER_MAX_SAMPLES) AS _UNSIGNED _BYTE
    REDIM sampleBps(0 TO __MDLLOADER_MAX_SAMPLES) AS _UNSIGNED _BYTE
    REDIM sampleIsBidi(0 TO __MDLLOADER_MAX_SAMPLES) AS _BYTE
    REDIM sampleIsLoop(0 TO __MDLLOADER_MAX_SAMPLES) AS _BYTE
    REDIM samplePackMethod(0 TO __MDLLOADER_MAX_SAMPLES) AS _UNSIGNED _BYTE
    REDIM samplePcm(0 TO __MDLLOADER_MAX_SAMPLES) AS STRING
    DIM maxSampleID AS LONG: maxSampleID = 0

    ' First pass: scan and process chunks
    DO UNTIL StringFile_IsEOF(memFile)
        IF StringFile_GetPosition(memFile) + 6 > StringFile_GetSize(memFile) THEN EXIT DO

        DIM chunkID AS STRING: chunkID = StringFile_ReadString(memFile, 2)
        DIM chunkLen AS _UNSIGNED LONG: chunkLen = StringFile_ReadLong(memFile)
        DIM chunkStart AS _UNSIGNED LONG: chunkStart = StringFile_GetPosition(memFile)
        DIM nextChunk AS _UNSIGNED LONG: nextChunk = chunkStart + chunkLen

        IF nextChunk > StringFile_GetSize(memFile) THEN
            nextChunk = StringFile_GetSize(memFile)
        END IF

        SELECT CASE chunkID
            CASE "IN" ' Song Infoblock
                IF chunkLen >= 65 THEN
                    songTitle = _TRIM$(StringFile_ReadString(memFile, 32))
                    composerName = _TRIM$(StringFile_ReadString(memFile, 20))
                    songLength = StringFile_ReadInteger(memFile)
                    songRepeat = StringFile_ReadInteger(memFile)
                    mainVolume = StringFile_ReadByte(memFile)
                    defaultSpeed = StringFile_ReadByte(memFile)
                    defaultBPM = StringFile_ReadByte(memFile)

                    IF songLength = 0 THEN songLength = 1
                    IF songLength > 256 THEN songLength = 256

                    DIM ch AS LONG
                    FOR ch = 0 TO 31
                        DIM chInfo AS _UNSIGNED _BYTE: chInfo = StringFile_ReadByte(memFile)
                        channelPan(ch) = _CLAMP(CLNG(chInfo AND &H7F) * 2, 0, 255)
                        IF (chInfo AND &H80) = 0 THEN
                            channelEnabled(ch) = _TRUE
                            IF ch + 1 > activeChannels THEN activeChannels = ch + 1
                        ELSE
                            channelEnabled(ch) = _FALSE
                        END IF
                    NEXT ch

                    IF activeChannels = 0 THEN activeChannels = 4

                    ' Sequencer orders
                    DIM oIdx AS LONG
                    FOR oIdx = 0 TO songLength - 1
                        IF NOT StringFile_IsEOF(memFile) THEN
                            orders(oIdx) = StringFile_ReadByte(memFile)
                        ELSE
                            orders(oIdx) = 0
                        END IF
                    NEXT oIdx
                END IF

            CASE "ME" ' Song Message / Comments
                IF chunkLen > 0 THEN
                    DIM msgStr AS STRING: msgStr = StringFile_ReadString(memFile, chunkLen)
                    DIM cleanMsg AS STRING: cleanMsg = _STR_EMPTY
                    DIM mPos AS LONG
                    FOR mPos = 1 TO LEN(msgStr)
                        DIM mCh AS _UNSIGNED _BYTE: mCh = ASC(msgStr, mPos)
                        IF mCh = 0 THEN
                            EXIT FOR
                        ELSEIF mCh = 13 THEN
                            cleanMsg = cleanMsg + _STR_CRLF
                        ELSEIF mCh <> 10 THEN
                            cleanMsg = cleanMsg + CHR$(mCh)
                        END IF
                    NEXT mPos
                    comments = cleanMsg
                END IF

            CASE "PA" ' Pattern Data
                IF chunkLen >= 1 THEN
                    numPatterns = StringFile_ReadByte(memFile)
                    DIM p AS LONG
                    IF version = 0 THEN
                        ' v0.0: Fixed 64 rows, 32 channels per pattern (32 words per pattern)
                        FOR p = 0 TO numPatterns - 1
                            patRows(p) = 64
                            patChannels(p) = activeChannels
                            FOR ch = 0 TO 31
                                DIM tIdx AS _UNSIGNED INTEGER: tIdx = 0
                                IF NOT StringFile_IsEOF(memFile) THEN tIdx = StringFile_ReadInteger(memFile)
                                IF ch < __MDLLOADER_MAX_CHANNELS THEN
                                    patTracks(p, ch) = tIdx
                                    IF tIdx > 0 AND ch + 1 > activeChannels THEN activeChannels = ch + 1
                                END IF
                            NEXT ch
                        NEXT p
                    ELSE
                        ' v1.0 / v1.1: Dynamic rows and channels per pattern
                        FOR p = 0 TO numPatterns - 1
                            IF StringFile_GetPosition(memFile) + 18 > nextChunk THEN EXIT FOR
                            DIM numCh AS _UNSIGNED _BYTE: numCh = StringFile_ReadByte(memFile)
                            DIM rByte AS _UNSIGNED _BYTE: rByte = StringFile_ReadByte(memFile)
                            StringFile_Seek memFile, StringFile_GetPosition(memFile) + 16 ' Skip pattern name

                            patChannels(p) = numCh
                            patRows(p) = CLNG(rByte) + 1
                            IF numCh > activeChannels THEN activeChannels = numCh

                            FOR ch = 0 TO numCh - 1
                                DIM tNum AS _UNSIGNED INTEGER: tNum = 0
                                IF NOT StringFile_IsEOF(memFile) THEN tNum = StringFile_ReadInteger(memFile)
                                IF ch < __MDLLOADER_MAX_CHANNELS THEN
                                    patTracks(p, ch) = tNum
                                END IF
                            NEXT ch
                        NEXT p
                    END IF
                END IF

            CASE "TR" ' Track Data
                IF chunkLen >= 2 THEN
                    totalTracks = StringFile_ReadInteger(memFile)
                    IF totalTracks > 0 AND totalTracks <= __MDLLOADER_MAX_TRACKS THEN
                        REDIM trackRows(0 TO totalTracks) AS _UNSIGNED LONG
                        REDIM trackData(0 TO totalTracks) AS STRING
                        DIM t AS LONG
                        FOR t = 1 TO totalTracks
                            IF StringFile_GetPosition(memFile) + 2 > nextChunk THEN EXIT FOR
                            DIM tDataLen AS _UNSIGNED INTEGER: tDataLen = StringFile_ReadInteger(memFile)
                            IF StringFile_GetPosition(memFile) + tDataLen > StringFile_GetSize(memFile) THEN
                                tDataLen = StringFile_GetSize(memFile) - StringFile_GetPosition(memFile)
                            END IF

                            DIM tPacked AS STRING: tPacked = StringFile_ReadString(memFile, tDataLen)

                            ' Depack track into 6-byte row slots
                            ' (note, instrument, volume, fxCmds, fx1Param, fx2Param)
                            DIM dpos AS LONG: dpos = 1
                            DIM rCount AS LONG: rCount = 0
                            DIM tBuf AS STRING: tBuf = STRING$(256 * 6, 0)
                            DIM lastSlotStr AS STRING: lastSlotStr = STRING$(6, 0)

                            DO WHILE dpos <= LEN(tPacked) AND rCount < 256
                                DIM bCmd AS _UNSIGNED _BYTE: bCmd = ASC(tPacked, dpos)
                                dpos = dpos + 1

                                DIM yy AS _UNSIGNED _BYTE: yy = bCmd AND 3
                                DIM cnt AS LONG: cnt = _SHR(bCmd, 2) + 1

                                SELECT CASE yy
                                    CASE 0 ' Empty rows
                                        DIM k0 AS LONG
                                        FOR k0 = 1 TO cnt
                                            IF rCount < 256 THEN
                                                DIM o0 AS _UNSIGNED LONG: o0 = rCount * 6 + 1
                                                ASC(tBuf, o0) = 0
                                                ASC(tBuf, o0 + 1) = 0
                                                ASC(tBuf, o0 + 2) = 0
                                                ASC(tBuf, o0 + 3) = 0
                                                ASC(tBuf, o0 + 4) = 0
                                                ASC(tBuf, o0 + 5) = 0
                                                rCount = rCount + 1
                                            END IF
                                        NEXT k0

                                    CASE 1 ' Repeat last row
                                        DIM k1 AS LONG
                                        FOR k1 = 1 TO cnt
                                            IF rCount < 256 THEN
                                                DIM o1 AS _UNSIGNED LONG: o1 = rCount * 6 + 1
                                                MID$(tBuf, o1, 6) = lastSlotStr
                                                rCount = rCount + 1
                                            END IF
                                        NEXT k1

                                    CASE 2 ' Copy from earlier row in this track
                                        DIM refPos AS LONG: refPos = _SHR(bCmd, 2)
                                        IF refPos < rCount THEN
                                            lastSlotStr = MID$(tBuf, refPos * 6 + 1, 6)
                                        ELSE
                                            lastSlotStr = STRING$(6, 0)
                                        END IF
                                        IF rCount < 256 THEN
                                            DIM o2 AS _UNSIGNED LONG: o2 = rCount * 6 + 1
                                            MID$(tBuf, o2, 6) = lastSlotStr
                                            rCount = rCount + 1
                                        END IF

                                    CASE 3 ' Explicit slot with field flags
                                        DIM nVal AS _UNSIGNED _BYTE: nVal = 0
                                        DIM iVal AS _UNSIGNED _BYTE: iVal = 0
                                        DIM vVal AS _UNSIGNED _BYTE: vVal = 0
                                        DIM fxVal AS _UNSIGNED _BYTE: fxVal = 0
                                        DIM p1Val AS _UNSIGNED _BYTE: p1Val = 0
                                        DIM p2Val AS _UNSIGNED _BYTE: p2Val = 0

                                        IF (bCmd AND 4) AND dpos <= LEN(tPacked) THEN
                                            nVal = ASC(tPacked, dpos): dpos = dpos + 1
                                        END IF
                                        IF (bCmd AND 8) AND dpos <= LEN(tPacked) THEN
                                            iVal = ASC(tPacked, dpos): dpos = dpos + 1
                                        END IF
                                        IF (bCmd AND 16) AND dpos <= LEN(tPacked) THEN
                                            vVal = ASC(tPacked, dpos): dpos = dpos + 1
                                        END IF
                                        IF (bCmd AND 32) AND dpos <= LEN(tPacked) THEN
                                            fxVal = ASC(tPacked, dpos): dpos = dpos + 1
                                        END IF
                                        IF (bCmd AND 64) AND dpos <= LEN(tPacked) THEN
                                            p1Val = ASC(tPacked, dpos): dpos = dpos + 1
                                        END IF
                                        IF (bCmd AND 128) AND dpos <= LEN(tPacked) THEN
                                            p2Val = ASC(tPacked, dpos): dpos = dpos + 1
                                        END IF

                                        IF rCount < 256 THEN
                                            DIM o3 AS _UNSIGNED LONG: o3 = rCount * 6 + 1
                                            ASC(tBuf, o3) = nVal
                                            ASC(tBuf, o3 + 1) = iVal
                                            ASC(tBuf, o3 + 2) = vVal
                                            ASC(tBuf, o3 + 3) = fxVal
                                            ASC(tBuf, o3 + 4) = p1Val
                                            ASC(tBuf, o3 + 5) = p2Val
                                            lastSlotStr = MID$(tBuf, o3, 6)
                                            rCount = rCount + 1
                                        END IF
                                END SELECT
                            LOOP

                            trackRows(t) = rCount
                            IF rCount > 0 THEN
                                trackData(t) = LEFT$(tBuf, rCount * 6)
                            ELSE
                                trackData(t) = _STR_EMPTY
                            END IF
                        NEXT t
                    END IF
                END IF

            CASE "II" ' Instruments (v1.0/v1.1)
                IF chunkLen >= 1 THEN
                    totalInstruments = StringFile_ReadByte(memFile)
                    DIM insIdx AS LONG
                    FOR insIdx = 1 TO totalInstruments
                        IF StringFile_GetPosition(memFile) + 34 > nextChunk THEN EXIT FOR
                        DIM iNum AS _UNSIGNED _BYTE: iNum = StringFile_ReadByte(memFile)
                        DIM numSmps AS _UNSIGNED _BYTE: numSmps = StringFile_ReadByte(memFile)
                        StringFile_Seek memFile, StringFile_GetPosition(memFile) + 32 ' Skip instrument name

                        IF iNum <= __MDLLOADER_MAX_INSTRUMENTS THEN
                            insMapCount(iNum) = numSmps
                            DIM smpM AS LONG
                            FOR smpM = 0 TO numSmps - 1
                                IF StringFile_GetPosition(memFile) + 14 > nextChunk THEN EXIT FOR
                                DIM sID AS _UNSIGNED _BYTE: sID = StringFile_ReadByte(memFile)
                                DIM nEnd AS _UNSIGNED _BYTE: nEnd = StringFile_ReadByte(memFile)
                                DIM iVol AS _UNSIGNED _BYTE: iVol = StringFile_ReadByte(memFile)
                                ' Skip 11 remaining bytes (envelopes, pan, vibrato)
                                StringFile_Seek memFile, StringFile_GetPosition(memFile) + 11

                                IF smpM < 16 THEN
                                    insMapSmp(iNum, smpM) = sID
                                    insMapNote(iNum, smpM) = nEnd
                                    insMapVol(iNum, smpM) = iVol
                                END IF
                            NEXT smpM
                        ELSE
                            StringFile_Seek memFile, StringFile_GetPosition(memFile) + CLNG(numSmps) * 14
                        END IF
                    NEXT insIdx
                END IF

            CASE "IS" ' Sample Infoblocks
                IF chunkLen >= 1 THEN
                    totalSamples = StringFile_ReadByte(memFile)
                    DIM sIdx AS LONG
                    FOR sIdx = 1 TO totalSamples
                        DIM entryLen AS LONG: entryLen = 59
                        IF version = 0 THEN entryLen = 57

                        IF StringFile_GetPosition(memFile) + entryLen > nextChunk THEN EXIT FOR

                        DIM sID2 AS _UNSIGNED _BYTE: sID2 = StringFile_ReadByte(memFile)
                        DIM smpName AS STRING: smpName = _TRIM$(StringFile_ReadString(memFile, 32))
                        StringFile_Seek memFile, StringFile_GetPosition(memFile) + 8 ' Skip DOS filename

                        DIM c4spd AS _UNSIGNED LONG: c4spd = 8363
                        IF version = 0 THEN
                            c4spd = StringFile_ReadInteger(memFile)
                        ELSE
                            c4spd = StringFile_ReadLong(memFile)
                        END IF
                        IF c4spd = 0 THEN c4spd = 8363

                        DIM slen AS _UNSIGNED LONG: slen = StringFile_ReadLong(memFile)
                        DIM lstart AS _UNSIGNED LONG: lstart = StringFile_ReadLong(memFile)
                        DIM llen AS _UNSIGNED LONG: llen = StringFile_ReadLong(memFile)

                        DIM sVol AS _UNSIGNED _BYTE: sVol = 255
                        IF version = 0 THEN
                            sVol = StringFile_ReadByte(memFile)
                        ELSE
                            StringFile_Seek memFile, StringFile_GetPosition(memFile) + 1 ' Skip unused byte
                        END IF

                        DIM sFlags AS _UNSIGNED _BYTE: sFlags = StringFile_ReadByte(memFile)

                        IF sID2 <= __MDLLOADER_MAX_SAMPLES THEN
                            sampleCaption(sID2) = smpName
                            sampleC4Spd(sID2) = c4spd
                            sampleLength(sID2) = slen
                            sampleLoopStart(sID2) = lstart
                            sampleLoopLen(sID2) = llen
                            sampleVolume(sID2) = sVol

                            IF (sFlags AND 1) THEN
                                sampleBps(sID2) = 2
                            ELSE
                                sampleBps(sID2) = 1
                            END IF

                            sampleIsBidi(sID2) = ((sFlags AND 2) <> 0)
                            sampleIsLoop(sID2) = (llen > 0 AND slen > 0 AND lstart < slen)
                            samplePackMethod(sID2) = _SHR(sFlags, 2) AND 3

                            IF sID2 > maxSampleID THEN maxSampleID = sID2
                        END IF
                    NEXT sIdx
                END IF

            CASE "SA" ' Sample Audio Data
                DIM sScan AS LONG
                FOR sScan = 1 TO totalSamples
                    IF sScan > maxSampleID THEN EXIT FOR
                    DIM reqLen AS _UNSIGNED LONG: reqLen = sampleLength(sScan)
                    DIM pMethod AS _UNSIGNED _BYTE: pMethod = samplePackMethod(sScan)
                    DIM bPerSmp AS _UNSIGNED _BYTE: bPerSmp = sampleBps(sScan)

                    IF reqLen > 0 THEN
                        IF pMethod = 0 THEN
                            ' Uncompressed signed PCM
                            DIM rawBytes AS _UNSIGNED LONG: rawBytes = reqLen * CLNG(bPerSmp)
                            IF StringFile_GetPosition(memFile) + rawBytes <= StringFile_GetSize(memFile) THEN
                                samplePcm(sScan) = StringFile_ReadString(memFile, rawBytes)
                            ELSE
                                samplePcm(sScan) = StringFile_ReadString(memFile, StringFile_GetSize(memFile) - StringFile_GetPosition(memFile))
                            END IF
                        ELSEIF pMethod = 1 OR pMethod = 2 THEN
                            ' Huffman-delta compressed
                            IF StringFile_GetPosition(memFile) + 4 <= StringFile_GetSize(memFile) THEN
                                DIM packLen AS _UNSIGNED LONG: packLen = StringFile_ReadLong(memFile)
                                DIM pOffset AS _UNSIGNED LONG: pOffset = StringFile_GetPosition(memFile) + 1
                                samplePcm(sScan) = __MDLLoader_DecompressSample(buffer, pOffset, packLen, reqLen, (bPerSmp = 2))
                                StringFile_Seek memFile, StringFile_GetPosition(memFile) + packLen
                            END IF
                        END IF
                    END IF
                NEXT sScan
        END SELECT

        StringFile_Seek memFile, nextChunk
    LOOP

    ' Populate player structures
    __MODPlayer_InitializeSong player
    player.song.caption = songTitle
    player.song.comment = comments
    player.song.format = MODPLAYER_FORMAT_MDL

    SELECT CASE version
        CASE &H00: player.song.subtype = "MDL0"
        CASE &H10: player.song.subtype = "MDL1"
        CASE &H11: player.song.subtype = "MDL2"
    END SELECT

    IF activeChannels < 1 THEN activeChannels = 4
    IF activeChannels > __MDLLOADER_MAX_CHANNELS THEN activeChannels = __MDLLOADER_MAX_CHANNELS

    player.song.channels = activeChannels
    player.song.isStereo = _TRUE
    player.song.speed = defaultSpeed
    player.song.BPM = defaultBPM
    player.song.defaultSpeed = defaultSpeed
    player.song.defaultBPM = defaultBPM
    DIM gVol AS _UNSIGNED _BYTE
    gVol = _CLAMP((CLNG(mainVolume) * 64 + 128) \ 255, 0, 64)
    player.song.globalVolume = gVol
    player.song.defaultGlobalVolume = gVol
    SoftSynth_SetGlobalVolume player.synth, CSNG(gVol) / 64.0!

    ' Setup master gain and voices
    DIM pcmPreAmp AS LONG: pcmPreAmp = _CLAMP(256 \ player.song.channels, 32, 64)
    player.song.pcmMasterGain = CSNG(pcmPreAmp) / 128.0!
    SoftSynth_SetTotalVoices player.synth, player.song.channels

    player.song.orders = songLength
    player.song.endJumpOrder = songRepeat

    ' Setup channels
    REDIM player.channel(0 TO player.song.channels - 1) AS __MODPLAYERCHANNEL
    DIM cIdx AS LONG
    FOR cIdx = 0 TO player.song.channels - 1
        player.channel(cIdx).defaultPanning = channelPan(cIdx)
        player.channel(cIdx).panning = channelPan(cIdx)
        player.channel(cIdx).volume = 64
        player.channel(cIdx).channelVolume = __MODPLAYER_S3M_GLOBAL_VOLUME_MAX
        player.channel(cIdx).subtype = __MODPLAYER_INSTRUMENT_PCM
        __MODPlayer_SetChannelPanning player, cIdx, channelPan(cIdx)
    NEXT cIdx

    ' Setup orders
    REDIM player.order(0 TO player.song.orders - 1) AS _UNSIGNED INTEGER
    DIM ord AS LONG
    FOR ord = 0 TO player.song.orders - 1
        player.order(ord) = orders(ord)
    NEXT ord

    ' Setup instruments
    DIM finalInstrumentCount AS LONG: finalInstrumentCount = maxSampleID
    IF finalInstrumentCount < 1 THEN finalInstrumentCount = 1
    player.song.instruments = finalInstrumentCount

    REDIM player.instrument(0 TO player.song.instruments - 1) AS __MODPLAYERINSTRUMENT

    DIM insSetup AS LONG
    FOR insSetup = 0 TO player.song.instruments - 1
        DIM smpNum AS LONG: smpNum = insSetup + 1
        player.instrument(insSetup).caption = sampleCaption(smpNum)
        player.instrument(insSetup).c2Spd = sampleC4Spd(smpNum)
        player.instrument(insSetup).channels = 1
        player.instrument(insSetup).subtype = __MODPLAYER_INSTRUMENT_PCM

        DIM bps AS _UNSIGNED _BYTE: bps = sampleBps(smpNum)
        IF bps = 0 THEN bps = 1
        player.instrument(insSetup).bytesPerSample = bps

        DIM slenBytes AS _UNSIGNED LONG: slenBytes = sampleLength(smpNum) * CLNG(bps)
        player.instrument(insSetup).length = slenBytes

        IF sampleIsLoop(smpNum) THEN
            DIM lStartBytes AS _UNSIGNED LONG: lStartBytes = sampleLoopStart(smpNum) * CLNG(bps)
            DIM lEndBytes AS _UNSIGNED LONG: lEndBytes = _MIN(sampleLoopStart(smpNum) + sampleLoopLen(smpNum), sampleLength(smpNum)) * CLNG(bps)

            IF lEndBytes > lStartBytes THEN
                IF sampleIsBidi(smpNum) THEN
                    player.instrument(insSetup).playMode = SOFTSYNTH_VOICE_PLAY_BIDIRECTIONAL_LOOP
                ELSE
                    player.instrument(insSetup).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
                END IF
                player.instrument(insSetup).loopStart = lStartBytes
                player.instrument(insSetup).loopEnd = lEndBytes
            ELSE
                player.instrument(insSetup).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                player.instrument(insSetup).loopStart = 0
                player.instrument(insSetup).loopEnd = slenBytes
            END IF
        ELSE
            player.instrument(insSetup).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            player.instrument(insSetup).loopStart = 0
            player.instrument(insSetup).loopEnd = slenBytes
        END IF

        IF version = 0 THEN
            player.instrument(insSetup).volume = _CLAMP((CLNG(sampleVolume(smpNum)) * 64 + 128) \ 255, 0, 64)
        ELSE
            player.instrument(insSetup).volume = 64
        END IF

        IF LEN(samplePcm(smpNum)) > 0 THEN
            SoftSynth_LoadSound player.synth, insSetup, samplePcm(smpNum), bps, 1
        END IF
    NEXT insSetup

    ' Setup patterns
    IF numPatterns = 0 THEN numPatterns = 1
    player.song.patterns = numPatterns
    REDIM player.pattern(0 TO player.song.patterns - 1) AS __MODPLAYERPATTERN

    DIM patIdx AS LONG
    FOR patIdx = 0 TO player.song.patterns - 1
        DIM pRows AS LONG: pRows = patRows(patIdx)
        IF pRows < 1 THEN pRows = 64
        IF pRows > 256 THEN pRows = 256
        player.pattern(patIdx).rows = pRows

        REDIM player.pattern(patIdx).note(0 TO pRows - 1, 0 TO player.song.channels - 1) AS __MODPLAYERNOTE

        DIM r AS LONG
        FOR r = 0 TO pRows - 1
            FOR ch = 0 TO player.song.channels - 1
                player.pattern(patIdx).note(r, ch).note = __MODPLAYER_NOTE_NONE
                player.pattern(patIdx).note(r, ch).instrument = 0
                player.pattern(patIdx).note(r, ch).volume = __MODPLAYER_NOTE_NO_VOLUME
                player.pattern(patIdx).note(r, ch).effect = 0
                player.pattern(patIdx).note(r, ch).operand = 0
            NEXT ch
        NEXT r

        ' Populate channels from tracks
        FOR ch = 0 TO player.song.channels - 1
            DIM trkNum AS _UNSIGNED INTEGER: trkNum = patTracks(patIdx, ch)
            IF trkNum > 0 AND trkNum <= totalTracks THEN
                DIM tStr AS STRING: tStr = trackData(trkNum)
                DIM tNumRows AS _UNSIGNED LONG: tNumRows = trackRows(trkNum)

                FOR r = 0 TO pRows - 1
                    IF r < tNumRows THEN
                        DIM sOfs AS _UNSIGNED LONG: sOfs = r * 6 + 1
                        IF sOfs + 5 <= LEN(tStr) THEN
                            DIM rawNote AS _UNSIGNED _BYTE: rawNote = ASC(tStr, sOfs)
                            DIM rawIns AS _UNSIGNED _BYTE: rawIns = ASC(tStr, sOfs + 1)
                            DIM rawVol AS _UNSIGNED _BYTE: rawVol = ASC(tStr, sOfs + 2)
                            DIM fxByte AS _UNSIGNED _BYTE: fxByte = ASC(tStr, sOfs + 3)
                            DIM f1Cmd AS _UNSIGNED _BYTE: f1Cmd = fxByte AND 15
                            DIM f2Cmd AS _UNSIGNED _BYTE: f2Cmd = _SHR(fxByte, 4)
                            DIM f1Op AS _UNSIGNED _BYTE: f1Op = ASC(tStr, sOfs + 4)
                            DIM f2Op AS _UNSIGNED _BYTE: f2Op = ASC(tStr, sOfs + 5)

                            ' Note decoding: 1 = C-0 (index 0), 120 = B-9
                            DIM decNote AS _UNSIGNED _BYTE: decNote = __MODPLAYER_NOTE_NONE
                            IF rawNote >= 1 AND rawNote <= 120 THEN
                                decNote = rawNote - 1
                            ELSEIF rawNote = 255 THEN
                                decNote = __MODPLAYER_NOTE_KEY_OFF
                            END IF

                            ' Instrument resolution (multi-sample mapping if II is present)
                            DIM resolvedSmp AS LONG: resolvedSmp = rawIns
                            DIM insVolOverride AS _UNSIGNED _BYTE: insVolOverride = __MODPLAYER_NOTE_NO_VOLUME

                            IF version >= &H10 AND rawIns > 0 AND rawIns <= __MDLLOADER_MAX_INSTRUMENTS THEN
                                IF insMapCount(rawIns) > 0 THEN
                                    DIM mapIdx AS LONG
                                    resolvedSmp = insMapSmp(rawIns, 0)
                                    IF insMapVol(rawIns, 0) > 0 THEN
                                        insVolOverride = _CLAMP((CLNG(insMapVol(rawIns, 0)) * 64 + 128) \ 255, 0, 64)
                                    END IF

                                    FOR mapIdx = 0 TO insMapCount(rawIns) - 1
                                        IF decNote <= insMapNote(rawIns, mapIdx) THEN
                                            resolvedSmp = insMapSmp(rawIns, mapIdx)
                                            IF insMapVol(rawIns, mapIdx) > 0 THEN
                                                insVolOverride = _CLAMP((CLNG(insMapVol(rawIns, mapIdx)) * 64 + 128) \ 255, 0, 64)
                                            END IF
                                            EXIT FOR
                                        END IF
                                    NEXT mapIdx
                                END IF
                            END IF

                            DIM decIns AS _UNSIGNED INTEGER: decIns = 0
                            IF resolvedSmp > 0 AND resolvedSmp <= player.song.instruments THEN
                                decIns = resolvedSmp
                            END IF

                            ' Volume column
                            DIM decVol AS _UNSIGNED _BYTE: decVol = __MODPLAYER_NOTE_NO_VOLUME
                            IF rawVol > 0 THEN
                                decVol = _CLAMP((CLNG(rawVol) * 64 + 128) \ 255, 0, 64)
                            ELSEIF insVolOverride <= 64 THEN
                                decVol = insVolOverride
                            END IF

                            ' Effect translation
                            DIM eff1 AS _UNSIGNED _BYTE, op1 AS _UNSIGNED _BYTE, v1 AS _UNSIGNED _BYTE
                            DIM eff2 AS _UNSIGNED _BYTE, op2 AS _UNSIGNED _BYTE, v2 AS _UNSIGNED _BYTE

                            __MDLLoader_TranslateEffect f1Cmd, _FALSE, f1Op, eff1, op1, v1
                            __MDLLoader_TranslateEffect f2Cmd, _TRUE, f2Op, eff2, op2, v2

                            IF v1 <= 64 THEN decVol = v1
                            IF v2 <= 64 THEN decVol = v2

                            DIM decEff AS _UNSIGNED _BYTE: decEff = 0
                            DIM decOp AS _UNSIGNED _BYTE: decOp = 0
                            DIM extraEff AS _UNSIGNED _BYTE: extraEff = 0
                            DIM extraOp AS _UNSIGNED _BYTE: extraOp = 0

                            IF eff1 > 0 THEN
                                decEff = eff1
                                decOp = op1
                                IF eff2 > 0 THEN
                                    extraEff = eff2
                                    extraOp = op2
                                END IF
                            ELSEIF eff2 > 0 THEN
                                decEff = eff2
                                decOp = op2
                            END IF

                            player.pattern(patIdx).note(r, ch).note = decNote
                            player.pattern(patIdx).note(r, ch).instrument = decIns
                            player.pattern(patIdx).note(r, ch).volume = decVol
                            player.pattern(patIdx).note(r, ch).effect = decEff
                            player.pattern(patIdx).note(r, ch).operand = decOp

                            IF extraEff > 0 THEN
                                DIM altCh AS LONG
                                FOR altCh = 0 TO ch - 1
                                    IF player.pattern(patIdx).note(r, altCh).effect = 0 THEN
                                        player.pattern(patIdx).note(r, altCh).effect = extraEff
                                        player.pattern(patIdx).note(r, altCh).operand = extraOp
                                        EXIT FOR
                                    END IF
                                NEXT altCh
                            END IF
                        END IF
                    END IF
                NEXT r
            END IF
        NEXT ch
    NEXT patIdx

    __MODPlayer_LoadTables
    player.initialized = _TRUE

    MDLLoader_LoadFromMemory = _TRUE
END FUNCTION

''' @brief Parses and loads a Digitrakker (MDL) module directly from a disk file.
''' @param player The MOD player instance.
''' @param fileName File path of the MDL module.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION MDLLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    MDLLoader_LoadFromDisk = _FALSE
    DIM buf AS STRING: buf = File_LoadFromDisk(fileName)
    IF LEN(buf) = 0 THEN EXIT FUNCTION
    MDLLoader_LoadFromDisk = MDLLoader_LoadFromMemory(player, buf)
END FUNCTION
