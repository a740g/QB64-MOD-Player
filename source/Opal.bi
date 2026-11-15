'=============================================================================================================
' OPAL OPL3 EMULATOR FOR QB64-PE
'=============================================================================================================
' Ported from the public-domain Opal C11 implementation by RealBitdancer.
' Original: github.com/RealBitdancer/opal (MIT License)
'
' This QB64-PE conversion provides a native, pure-BASIC OPL2/OPL3 emulator suitable
' for powering S3M FM instrument playback. For S3M use, keep NEW mode clear (the default)
' to operate in OPL2-compatible mode (9 melodic channels, waveforms 0-3).
'
' Requires QB64-PE with $UNSTABLE:TYPEFIELDS support for array members in TYPEs.
'
' Public API:
' OpalInit chip, sampleRate%& - Initialize / reset the emulator
' OpalSetSampleRate chip, sampleRate%& - Change output sample rate
' OpalWriteReg chip, regNum~%, value~%% - Write a register immediately
' OpalWriteRegBuffered chip, regNum~%, value~%% - Queue a register write
' OpalFlushWriteBuf chip - Flush all queued writes
' OpalSample chip, left%, right% - Generate one stereo PCM sample
' OpalPan chip, channel~%, pan~%% - Set channel panning
' OpalReadStatus& (chip) - Read the status register
'=============================================================================================================

OPTION _EXPLICIT

$UNSTABLE:TYPEFIELDS

CONST OPAL_VERSION_MAJOR = 3
CONST OPAL_VERSION_MINOR = 0
CONST OPAL_VERSION_PATCH = 0

CONST OPAL_OPL3_SAMPLE_RATE = 49716
CONST OPAL_CHANNEL_COUNT = 18
CONST OPAL_OPERATOR_COUNT = 36

CONST OPAL_WRITEBUF_SIZE = 4096
CONST OPAL_WRITEBUF_DELAY = 2

' Sentinel values
CONST OPAL_OP_NONE = &HFF
CONST OPAL_MOD_OWN_FB = &HFE
CONST OPAL_CH_NONE = &HFF

' Envelope stages
CONST OPAL_ENVELOPE_STAGE_OFF = -1
CONST OPAL_ENVELOPE_STAGE_ATTACK = 0
CONST OPAL_ENVELOPE_STAGE_DECAY = 1
CONST OPAL_ENVELOPE_STAGE_SUSTAIN = 2
CONST OPAL_ENVELOPE_STAGE_RELEASE = 3

' Channel types
CONST OPAL_CHANNEL_TYPE_2OP = 0
CONST OPAL_CHANNEL_TYPE_4OP = 1
CONST OPAL_CHANNEL_TYPE_4OP2 = 2
CONST OPAL_CHANNEL_TYPE_DRUM = 3

' Internal constants
CONST OPAL_CHANNELS_PER_BANK = 9
CONST OPAL_OPERATORS_PER_BANK = 18
CONST OPAL_PAIRS_PER_BANK = 3
CONST OPAL_VOICE_STRIDE = 3
CONST OPAL_BASS_DRUM_CHANNEL = 6
CONST OPAL_RHYTHM_FIRST_SLOT = 12
CONST OPAL_HI_HAT_SLOT = 13
CONST OPAL_SNARE_SLOT = 16
CONST OPAL_CYMBAL_SLOT = 17
CONST OPAL_HI_HAT_PHASE_NOISY = &HD0~%
CONST OPAL_HI_HAT_PHASE_QUIET = &H34~%
CONST OPAL_CYMBAL_PHASE = &H80~%
CONST OPAL_NEW_REGISTER = &H105~%
CONST OPAL_FOUR_OP_REGISTER = &H104~%
CONST OPAL_RHYTHM_REGISTER = &HBD~%
CONST OPAL_PAIR_ENABLE_MASK = &H3F~%
CONST OPAL_OUTPUT_BOTH_SIDES = 3
CONST OPAL_WAVEFORM_MASK_NEW = 7
CONST OPAL_WAVEFORM_MASK_OPL2 = 3
CONST OPAL_ENVELOPE_SILENT = 511
CONST OPAL_ENVELOPE_OFF_ZONE = 504
CONST OPAL_RATE_FAST = 48
CONST OPAL_RATE_INSTANT = 60
CONST OPAL_TREMOLO_STEPS = 210
CONST OPAL_TREMOLO_PEAK = 105
CONST OPAL_AUDIBLE_LEVEL_LIMIT = 3072
CONST OPAL_FULL_GAIN = 256

' Algorithm indices
CONST OPAL_ALGORITHM_FM = 0
CONST OPAL_ALGORITHM_ADDITIVE = 1
CONST OPAL_ALGORITHM_CHAIN = 2
CONST OPAL_ALGORITHM_TWO_PAIRS = 3
CONST OPAL_ALGORITHM_SOLO_CHAIN = 4
CONST OPAL_ALGORITHM_SOLO_PAIR = 5
CONST OPAL_ALGORITHM_KICK_FM = 6
CONST OPAL_ALGORITHM_KICK_DIRECT = 7
CONST OPAL_ALGORITHM_PERCUSSION = 8
CONST OPAL_ALGORITHM_COUNT = 9

' ============================================================================================================
' TYPE DEFINITIONS
' ============================================================================================================

TYPE OpalOperator
    envelopeStage AS LONG
    egOut AS _UNSIGNED INTEGER
    key AS _UNSIGNED _BYTE
    modSource AS _UNSIGNED _BYTE
    out AS INTEGER
    prevOut AS INTEGER
    phase AS _UNSIGNED LONG
    envelope AS _UNSIGNED INTEGER
    tremolo AS _UNSIGNED _BYTE
    vibrato AS _UNSIGNED _BYTE
    sustainHold AS _UNSIGNED _BYTE
    keyScaleRate AS _UNSIGNED _BYTE
    multiple AS _UNSIGNED _BYTE
    keyScaleLevel AS _UNSIGNED _BYTE
    totalLevel AS _UNSIGNED _BYTE
    attackRate AS _UNSIGNED _BYTE
    decayRate AS _UNSIGNED _BYTE
    sustainLevel AS _UNSIGNED _BYTE
    releaseRate AS _UNSIGNED _BYTE
    waveform AS _UNSIGNED _BYTE
END TYPE

TYPE OpalChannel
    opSlot(0 TO 3) _STATIC AS _UNSIGNED _BYTE
    pairIndex AS _UNSIGNED _BYTE
    outSource(0 TO 3) _STATIC AS _UNSIGNED _BYTE
    chanType AS LONG
    leftPan AS _UNSIGNED INTEGER
    rightPan AS _UNSIGNED INTEGER
    fNumber AS _UNSIGNED INTEGER
    block AS _UNSIGNED _BYTE
    latchedKeyScaleNumber AS _UNSIGNED _BYTE
    feedback AS _UNSIGNED _BYTE
    connection AS _UNSIGNED _BYTE
    outputEnable AS _UNSIGNED _BYTE
    algorithm AS _UNSIGNED _BYTE
END TYPE

TYPE OpalQueuedWrite
    due AS _UNSIGNED _INTEGER64
    regNum AS _UNSIGNED INTEGER
    value AS _UNSIGNED _BYTE
END TYPE

TYPE OpalState
    sampleRate AS LONG
    sampleAccum AS LONG
    lastOutput(0 TO 1) _STATIC AS INTEGER
    currOutput(0 TO 1) _STATIC AS INTEGER
    chan(0 TO 17) _STATIC AS OpalChannel
    op(0 TO 35) _STATIC AS OpalOperator
    timer(0 TO 1) _STATIC AS _UNSIGNED _BYTE
    timerControl AS _UNSIGNED _BYTE
    timerCount(0 TO 1) _STATIC AS _UNSIGNED INTEGER
    status AS _UNSIGNED _BYTE
    newMode AS _UNSIGNED _BYTE
    pairEnable AS _UNSIGNED _BYTE
    rhythmMode AS _UNSIGNED _BYTE
    noteSelect AS _UNSIGNED _BYTE
    tremoloDepth AS _UNSIGNED _BYTE
    vibratoDepth AS _UNSIGNED _BYTE
    waveSelectEnable AS _UNSIGNED _BYTE
    compositeSine AS _UNSIGNED _BYTE
    tremoloPosition AS _UNSIGNED _BYTE
    tremoloLevel AS _UNSIGNED _BYTE
    sampleCounter AS _UNSIGNED INTEGER
    hiHatPhase AS _UNSIGNED INTEGER
    cymbalPhase AS _UNSIGNED INTEGER
    noise AS _UNSIGNED LONG
    pendingRight AS LONG
    chipSamples AS _UNSIGNED _INTEGER64
    lastDue AS _UNSIGNED _INTEGER64
    queueHead AS _UNSIGNED INTEGER
    queueCount AS _UNSIGNED INTEGER
    queue(0 TO 4095) _STATIC AS OpalQueuedWrite
END TYPE

' Algorithm descriptor (used by lookup table)
TYPE OpalAlgorithmDesc
    operatorCount AS _UNSIGNED _BYTE
    chainMask AS _UNSIGNED _BYTE
    carrierMask AS _UNSIGNED _BYTE
    gain AS _UNSIGNED _BYTE
    selfFeedback AS _BYTE ' boolean
END TYPE

' Vibrato step descriptor
TYPE OpalVibratoStepDesc
    halves AS _UNSIGNED _BYTE
    negative AS _BYTE ' boolean
END TYPE

' ============================================================================================================
' MODULE-LEVEL LOOKUP TABLES (initialized by OpalInitTables)
' ============================================================================================================
DIM SHARED opalTablesReady AS _BYTE

' Decapped OPL2/OPL3 log-sin ROM (256 entries)
DIM SHARED opalLogSinTable(0 TO 255) AS _UNSIGNED INTEGER

' Decapped OPL2/OPL3 exponent ROM (256 entries)
DIM SHARED opalExponentRom(0 TO 255) AS _UNSIGNED INTEGER

' Frequency multiplier x2 table (16 entries)
DIM SHARED opalMulTimes2(0 TO 15) AS _UNSIGNED INTEGER

' Operator-to-owning-channel mapping (36 entries)
DIM SHARED opalOperatorOwner(0 TO 35) AS _UNSIGNED _BYTE

' Rhythm key bit positions (6 entries)
DIM SHARED opalRhythmKeyBit(0 TO 5) AS _UNSIGNED _BYTE

' Vibrato steps (8 entries)
DIM SHARED opalVibratoSteps(0 TO 7) AS OpalVibratoStepDesc

' Algorithm descriptors (9 entries)
DIM SHARED opalAlgorithms(0 TO 8) AS OpalAlgorithmDesc

' Slot mapping table: channel index -> first operator slot
DIM SHARED opalSlotMap(0 TO 17) AS _UNSIGNED _BYTE

' KSL (Key Scale Level) attenuation table (16 entries, in 0.1875 dB units)
DIM SHARED opalKslTable(0 TO 15) AS _UNSIGNED _BYTE

' ============================================================================================================
' TABLE INITIALIZATION
' ============================================================================================================
SUB OpalInitTables
    IF opalTablesReady THEN EXIT SUB

    ' --- Log-Sin Table (quarter-wave, 256 entries) ---
    ' Stores -log2(|sin(x)|) * 256 in fixed point, used for waveform generation
    DIM i AS LONG
    RESTORE OpalLogSinData
    FOR i = 0 TO 255
        READ opalLogSinTable(i)
    NEXT

    ' --- Exponent ROM (256 entries) ---
    ' Stores 2^x lookup for converting log-domain back to linear
    RESTORE OpalExponentData
    FOR i = 0 TO 255
        READ opalExponentRom(i)
    NEXT

    ' --- Frequency multiplier x2 ---
    RESTORE OpalMulData
    FOR i = 0 TO 15
        READ opalMulTimes2(i)
    NEXT

    ' --- Operator owner table ---
    RESTORE OpalOwnerData
    FOR i = 0 TO 35
        READ opalOperatorOwner(i)
    NEXT

    ' --- Rhythm key bits ---
    RESTORE OpalRhythmKeyData
    FOR i = 0 TO 5
        READ opalRhythmKeyBit(i)
    NEXT

    ' --- Vibrato steps ---
    RESTORE OpalVibratoData
    FOR i = 0 TO 7
        READ opalVibratoSteps(i).halves
        READ opalVibratoSteps(i).negative
    NEXT

    ' --- Algorithm descriptors ---
    RESTORE OpalAlgorithmData
    FOR i = 0 TO 8
        READ opalAlgorithms(i).operatorCount
        READ opalAlgorithms(i).chainMask
        READ opalAlgorithms(i).carrierMask
        READ opalAlgorithms(i).gain
        READ opalAlgorithms(i).selfFeedback
    NEXT

    ' --- Slot map: channel -> first operator slot ---
    RESTORE OpalSlotMapData
    FOR i = 0 TO 17
        READ opalSlotMap(i)
    NEXT

    ' --- KSL table ---
    RESTORE OpalKslData
    FOR i = 0 TO 15
        READ opalKslTable(i)
    NEXT

    opalTablesReady = -1 ' TRUE
END SUB

' ============================================================================================================
' DATA STATEMENTS FOR LOOKUP TABLES
' ============================================================================================================

OpalLogSinData:
DATA 2137,1731,1543,1419,1326,1252,1190,1137,1091,1050,1013,979,949,920,894,869
DATA 846,825,804,785,767,749,732,717,701,687,672,659,646,633,621,609
DATA 598,587,576,566,556,546,536,527,518,509,501,492,484,476,468,461
DATA 453,446,439,432,425,418,411,405,399,392,386,380,375,369,363,358
DATA 352,347,341,336,331,326,321,316,311,307,302,297,293,289,284,280
DATA 276,271,267,263,259,255,251,248,244,240,236,233,229,226,222,219
DATA 215,212,209,205,202,199,196,193,190,187,184,181,178,175,172,169
DATA 167,164,161,159,156,153,151,148,146,143,141,138,136,134,131,129
DATA 127,125,122,120,118,116,114,112,110,108,106,104,102,100,98,96
DATA 94,92,91,89,87,85,83,82,80,78,77,75,74,72,70,69
DATA 67,66,64,63,62,60,59,57,56,55,53,52,51,49,48,47
DATA 46,45,43,42,41,40,39,38,37,36,35,34,33,32,31,30
DATA 29,28,27,26,25,24,23,23,22,21,20,20,19,18,17,17
DATA 16,15,15,14,13,13,12,12,11,10,10,9,9,8,8,7
DATA 7,7,6,6,5,5,5,4,4,4,3,3,3,2,2,2
DATA 2,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0

OpalExponentData:
DATA 0,3,6,8,11,14,17,20,22,25,28,31,34,37,40,42
DATA 45,48,51,54,57,60,63,66,69,72,75,78,81,84,87,90
DATA 93,96,99,102,105,108,111,114,117,120,123,126,130,133,136,139
DATA 142,145,148,152,155,158,161,164,168,171,174,177,181,184,187,190
DATA 194,197,200,204,207,210,214,217,220,224,227,231,234,237,241,244
DATA 248,251,255,258,262,265,268,272,276,279,283,286,290,293,297,300
DATA 304,308,311,315,318,322,326,329,333,337,340,344,348,352,355,359
DATA 363,367,370,374,378,382,385,389,393,397,401,405,409,412,416,420
DATA 424,428,432,436,440,444,448,452,456,460,464,468,472,476,480,484
DATA 488,492,496,501,505,509,513,517,521,526,530,534,538,542,547,551
DATA 555,560,564,568,572,577,581,585,590,594,599,603,607,612,616,621
DATA 625,630,634,639,643,648,652,657,661,666,670,675,680,684,689,693
DATA 698,703,708,712,717,722,726,731,736,741,745,750,755,760,765,770
DATA 774,779,784,789,794,799,804,809,814,819,824,829,834,839,844,849
DATA 854,859,864,869,874,880,885,890,895,900,906,911,916,921,927,932
DATA 937,942,948,953,958,964,969,974,980,985,991,996,1002,1007,1013,1018

OpalMulData:
DATA 1,2,4,6,8,10,12,14,16,18,20,20,24,24,30,30

OpalOwnerData:
DATA 0,1,2,0,1,2,3,4,5,3,4,5,6,7,8,6,7,8
DATA 9,10,11,9,10,11,12,13,14,12,13,14,15,16,17,15,16,17

OpalRhythmKeyData:
DATA 4,0,2,4,3,1

OpalVibratoData:
' halves, negative (0=false, -1=true)
DATA 0,0,1,0,2,0,1,0,0,0,1,-1,2,-1,1,-1

OpalAlgorithmData:
' operatorCount, chainMask, carrierMask, gain, selfFeedback
DATA 2,2,2,1,-1
DATA 2,0,3,1,-1
DATA 4,14,8,1,-1
DATA 4,10,10,1,-1
DATA 4,12,9,1,-1
DATA 4,4,13,1,-1
DATA 2,2,2,2,-1
DATA 2,0,2,2,-1
DATA 2,0,3,2,0

OpalSlotMapData:
DATA 0,1,2,6,7,8,12,13,14,18,19,20,24,25,26,30,31,32

OpalKslData:
' KSL attenuation for fNumber high nibble (in 0.1875 dB steps, pre-shifted)
DATA 0,32,40,45,48,51,53,55,56,58,59,60,61,62,63,64

' ============================================================================================================
' HELPER FUNCTIONS (PRIVATE)
' ============================================================================================================

FUNCTION OpalSaturate% (sum AS LONG)
    IF sum > 32767 THEN
        OpalSaturate% = 32767
    ELSEIF sum < -32768 THEN
        OpalSaturate% = -32768
    ELSE
        OpalSaturate% = sum
    END IF
END FUNCTION

FUNCTION OpalInterpolate% (last AS INTEGER, curr AS INTEGER, fract AS LONG)
    DIM diff AS LONG
    diff = curr - last
    OpalInterpolate% = last + ((fract * diff) \ 65536)
END FUNCTION

FUNCTION OpalFloorShift& (value AS LONG, bits AS _UNSIGNED LONG)
    IF value >= 0 THEN
        OpalFloorShift& = value \ (2 ^ bits)
    ELSE
        ' Arithmetic right shift for negative values
        OpalFloorShift& = NOT (NOT value \ (2 ^ bits))
    END IF
END FUNCTION

FUNCTION OpalChannelIsPairTail%% (ch AS _UNSIGNED LONG)
    OpalChannelIsPairTail%% = ((ch MOD OPAL_CHANNELS_PER_BANK) \ OPAL_PAIRS_PER_BANK = 1)
END FUNCTION

FUNCTION OpalChannelPairBit~& (ch AS _UNSIGNED LONG)
    OpalChannelPairBit~& = (ch \ OPAL_CHANNELS_PER_BANK) * OPAL_PAIRS_PER_BANK + (ch MOD OPAL_PAIRS_PER_BANK)
END FUNCTION

FUNCTION OpalChannelIsRhythm%% (chip AS OpalState, ch AS _UNSIGNED LONG)
    IF chip.rhythmMode = 0 THEN
        OpalChannelIsRhythm%% = 0
        EXIT FUNCTION
    END IF
    OpalChannelIsRhythm%% = (ch >= 6 AND ch <= 8)
END FUNCTION

FUNCTION OpalChannelIsPaired%% (chip AS OpalState, ch AS _UNSIGNED LONG)
    DIM pairBit AS _UNSIGNED LONG
    pairBit = OpalChannelPairBit~&(ch)
    OpalChannelIsPaired%% = ((chip.pairEnable AND (2 ^ pairBit)) <> 0)
END FUNCTION

FUNCTION OpalChannelSpansPair%% (chip AS OpalState, ch AS _UNSIGNED LONG)
    ' A channel "spans a pair" if it is the lead of a 4-op pair
    IF NOT OpalChannelIsPaired%%(chip, ch) THEN
        OpalChannelSpansPair%% = 0
        EXIT FUNCTION
    END IF
    OpalChannelSpansPair%% = NOT OpalChannelIsPairTail%%(ch)
END FUNCTION

FUNCTION OpalChannelBorrowsPitch%% (chip AS OpalState, ch AS _UNSIGNED LONG)
    ' The tail half of a 4-op pair borrows pitch from the lead
    IF NOT OpalChannelIsPaired%%(chip, ch) THEN
        OpalChannelBorrowsPitch%% = 0
        EXIT FUNCTION
    END IF
    OpalChannelBorrowsPitch%% = OpalChannelIsPairTail%%(ch)
END FUNCTION

FUNCTION OpalAlgorithmFeedsBack%% (alg AS OpalAlgorithmDesc, position AS _UNSIGNED LONG)
    OpalAlgorithmFeedsBack%% = (alg.selfFeedback <> 0 AND position = 0)
END FUNCTION

FUNCTION OpalAlgorithmChains%% (alg AS OpalAlgorithmDesc, position AS _UNSIGNED LONG)
    IF position = 0 THEN
        OpalAlgorithmChains%% = 0
        EXIT FUNCTION
    END IF
    OpalAlgorithmChains%% = ((alg.chainMask AND (2 ^ position)) <> 0)
END FUNCTION

FUNCTION OpalAlgorithmIsCarrier%% (alg AS OpalAlgorithmDesc, position AS _UNSIGNED LONG)
    OpalAlgorithmIsCarrier%% = ((alg.carrierMask AND (2 ^ position)) <> 0)
END FUNCTION

' Get the algorithm descriptor index for a channel
FUNCTION OpalChannelAlgorithmIndex~%% (chip AS OpalState, ch AS _UNSIGNED LONG)
    DIM chanRef AS _UNSIGNED LONG
    chanRef = ch

    ' For rhythm channels, use special algorithms
    IF OpalChannelIsRhythm%%(chip, chanRef) THEN
        IF chanRef = OPAL_BASS_DRUM_CHANNEL THEN
            IF chip.chan(chanRef).connection THEN
                OpalChannelAlgorithmIndex~%% = OPAL_ALGORITHM_KICK_DIRECT
            ELSE
                OpalChannelAlgorithmIndex~%% = OPAL_ALGORITHM_KICK_FM
            END IF
        ELSE
            OpalChannelAlgorithmIndex~%% = OPAL_ALGORITHM_PERCUSSION
        END IF
        EXIT FUNCTION
    END IF

    ' For 4-op channels, map connection bits to algorithm
    IF OpalChannelIsPaired%%(chip, chanRef) THEN
        IF OpalChannelIsPairTail%%(chanRef) THEN
            chanRef = chanRef - 3 ' use lead channel
        END IF
        DIM leadConn AS _UNSIGNED _BYTE, tailConn AS _UNSIGNED _BYTE
        leadConn = chip.chan(chanRef).connection
        tailConn = chip.chan(chanRef + 3).connection
        OpalChannelAlgorithmIndex~%% = OPAL_ALGORITHM_CHAIN + leadConn * 2 + tailConn
        EXIT FUNCTION
    END IF

    ' Standard 2-op: FM or additive
    OpalChannelAlgorithmIndex~%% = chip.chan(chanRef).connection ' 0=FM, 1=additive
END FUNCTION

' Get operator voice position within the channel
FUNCTION OpalOperatorVoicePosition~& (chip AS OpalState, slot AS _UNSIGNED LONG)
    DIM ch AS _UNSIGNED LONG
    DIM position AS _UNSIGNED LONG
    ch = opalOperatorOwner(slot)

    IF slot = chip.chan(ch).opSlot(0) THEN
        position = 0
    ELSE
        position = 1
    END IF

    IF OpalChannelSpansPair%%(chip, ch) AND OpalChannelIsPairTail%%(ch) THEN
        position = position + 2
    END IF

    OpalOperatorVoicePosition~& = position
END FUNCTION

' Get the pitch channel for an operator (may differ from owner for 4-op tails)
FUNCTION OpalOperatorPitchChannel~& (chip AS OpalState, slot AS _UNSIGNED LONG)
    DIM ch AS _UNSIGNED LONG
    ch = opalOperatorOwner(slot)
    IF OpalChannelBorrowsPitch%%(chip, ch) THEN
        OpalOperatorPitchChannel~& = ch - 3
    ELSE
        OpalOperatorPitchChannel~& = ch
    END IF
END FUNCTION

' Compute KSL attenuation for an operator
FUNCTION OpalOperatorKeyScaleLevel~% (chip AS OpalState, slot AS _UNSIGNED LONG)
    DIM op AS OpalOperator
    DIM pitchCh AS _UNSIGNED LONG
    DIM fHigh AS _UNSIGNED LONG
    DIM kslVal AS LONG

    op = chip.op(slot)
    pitchCh = OpalOperatorPitchChannel~&(chip, slot)

    IF op.keyScaleLevel = 0 THEN
        OpalOperatorKeyScaleLevel~% = 0
        EXIT FUNCTION
    END IF

    fHigh = chip.chan(pitchCh).fNumber \ 512 ' top 4 bits (fNumber >> 9... actually top nibble >> 6)
    ' Actually: fNumber is 10 bits, high nibble = fNumber >> 6, giving 4-bit index
    fHigh = (chip.chan(pitchCh).fNumber \ 64) AND 15

    kslVal = opalKslTable(fHigh) - 16 * (7 - chip.chan(pitchCh).block)
    IF kslVal < 0 THEN kslVal = 0

    ' KSL field: 0=0dB, 1=6dB/oct, 2=3dB/oct (>>1), 3=1.5dB/oct (>>2)
    SELECT CASE op.keyScaleLevel
        CASE 1: OpalOperatorKeyScaleLevel~% = kslVal
        CASE 2: OpalOperatorKeyScaleLevel~% = kslVal \ 2
        CASE 3: OpalOperatorKeyScaleLevel~% = kslVal \ 4
    END SELECT
END FUNCTION

' Compute the phase increment for an operator
FUNCTION OpalOperatorIncrement~& (chip AS OpalState, slot AS _UNSIGNED LONG)
    DIM op AS OpalOperator
    DIM pitchCh AS _UNSIGNED LONG
    DIM fNumber AS LONG
    DIM fNumberHigh AS LONG, depthShift AS LONG
    DIM position AS _UNSIGNED LONG, magnitude AS LONG
    DIM oplBase AS _UNSIGNED LONG

    op = chip.op(slot)
    pitchCh = OpalOperatorPitchChannel~&(chip, slot)

    fNumber = chip.chan(pitchCh).fNumber

    ' Apply vibrato if enabled
    IF op.vibrato THEN
        fNumberHigh = fNumber \ 128
        IF chip.vibratoDepth THEN depthShift = 0 ELSE depthShift = 1
        position = (chip.sampleCounter \ 1024) AND 7
        magnitude = ((fNumberHigh * opalVibratoSteps(position).halves) \ 2)
        magnitude = magnitude \ (2 ^ depthShift)
        IF opalVibratoSteps(position).negative THEN
            fNumber = fNumber - magnitude
        ELSE
            fNumber = fNumber + magnitude
        END IF
    END IF

    oplBase = (_SHL(fNumber, chip.chan(pitchCh).block)) \ 2
    OpalOperatorIncrement~& = (oplBase * opalMulTimes2(op.multiple)) \ 2
END FUNCTION

' Compute waveform output from phase and attenuation
FUNCTION OpalWaveformOutput% (waveform AS _UNSIGNED _BYTE, phase AS _UNSIGNED LONG, attenuation AS _UNSIGNED LONG)
    DIM phaseIndex AS _UNSIGNED LONG
    DIM quarterPhase AS _UNSIGNED LONG
    DIM logAtten AS _UNSIGNED LONG
    DIM expIndex AS _UNSIGNED LONG
    DIM expShift AS _UNSIGNED LONG
    DIM outVal AS LONG
    DIM isNegative AS _BYTE
    DIM isSilent AS _BYTE

    ' Reduce phase to 10 bits
    phaseIndex = phase AND &H3FF

    ' Determine waveform behavior
    isNegative = 0
    isSilent = 0

    SELECT CASE waveform
        CASE 0 ' Sine
            IF phaseIndex >= 512 THEN isNegative = -1
        CASE 1 ' Half-sine
            IF phaseIndex >= 512 THEN isSilent = -1
        CASE 2 ' Absolute sine
            ' No negation, no silence
        CASE 3 ' Quarter sine (pulse)
            IF (phaseIndex AND 256) THEN isSilent = -1
        CASE 4 ' Alternating sine
            IF phaseIndex >= 512 THEN isNegative = -1
            phaseIndex = (phaseIndex * 2) AND &H3FF
            IF phaseIndex >= 512 THEN isSilent = -1
        CASE 5 ' Camelback
            phaseIndex = (phaseIndex * 2) AND &H3FF
            IF phaseIndex >= 512 THEN isSilent = -1
        CASE 6 ' Square
            IF phaseIndex >= 512 THEN
                isNegative = -1
            END IF
            ' Attenuation is 0 (max volume square)
            IF NOT isSilent THEN
                IF attenuation >= OPAL_ENVELOPE_SILENT THEN
                    OpalWaveformOutput% = 0
                    EXIT FUNCTION
                END IF
                ' Square: output is +/- max based on attenuation only
                expIndex = attenuation AND 255
                expShift = attenuation \ 256
                outVal = (opalExponentRom(expIndex) OR &H400) \ (2 ^ (expShift + 1))
                IF isNegative THEN outVal = -outVal
                OpalWaveformOutput% = OpalSaturate%(outVal)
                EXIT FUNCTION
            END IF
            OpalWaveformOutput% = 0
            EXIT FUNCTION
        CASE 7 ' Derived log sawtooth
            IF phaseIndex >= 512 THEN
                isNegative = -1
                phaseIndex = &H3FF - phaseIndex
            END IF
            ' Sawtooth-like: attenuation ramp
            IF phaseIndex >= 256 THEN
                isSilent = -1
            END IF
    END SELECT

    IF isSilent THEN
        OpalWaveformOutput% = 0
        EXIT FUNCTION
    END IF

    ' Map phase to quarter-wave lookup
    quarterPhase = phaseIndex AND 255
    IF phaseIndex AND 256 THEN
        quarterPhase = 255 - quarterPhase
    END IF

    ' Look up log-sin attenuation and add envelope attenuation
    logAtten = opalLogSinTable(quarterPhase) + attenuation * 8

    IF logAtten >= 8192 THEN ' way past silent
        OpalWaveformOutput% = 0
        EXIT FUNCTION
    END IF

    ' Convert from log domain to linear via exponent ROM
    expIndex = logAtten AND 255
    expShift = logAtten \ 256

    IF expShift > 13 THEN
        OpalWaveformOutput% = 0
        EXIT FUNCTION
    END IF

    outVal = (opalExponentRom(255 - expIndex) OR &H400) \ (2 ^ (expShift + 1))

    IF isNegative THEN outVal = -outVal

    OpalWaveformOutput% = OpalSaturate%(outVal)
END FUNCTION

' ============================================================================================================
' ENVELOPE GENERATOR
' ============================================================================================================
SUB OpalOperatorEnvelope (chip AS OpalState, slot AS _UNSIGNED LONG, oddSample AS _BYTE)
    DIM op AS OpalOperator
    DIM pitchCh AS _UNSIGNED LONG
    DIM ksn AS _UNSIGNED LONG
    DIM rate AS _UNSIGNED LONG
    DIM effectiveRate AS _UNSIGNED LONG
    DIM rateHigh AS _UNSIGNED LONG
    DIM rateLow AS _UNSIGNED LONG
    DIM stepSize AS LONG
    DIM level AS LONG

    op = chip.op(slot)
    pitchCh = OpalOperatorPitchChannel~&(chip, slot)

    level = op.envelope

    SELECT CASE op.envelopeStage
        CASE OPAL_ENVELOPE_STAGE_ATTACK
            IF op.attackRate = 0 THEN
                ' No attack, stay where we are
            ELSE
                ' Calculate effective rate
                IF op.keyScaleRate THEN
                    ksn = chip.chan(pitchCh).latchedKeyScaleNumber
                ELSE
                    ksn = chip.chan(pitchCh).latchedKeyScaleNumber \ 4
                END IF
                effectiveRate = op.attackRate * 4 + ksn
                IF effectiveRate > 63 THEN effectiveRate = 63

                rateHigh = effectiveRate \ 4
                rateLow = effectiveRate AND 3

                IF effectiveRate >= OPAL_RATE_INSTANT THEN
                    ' Instant attack
                    level = 0
                    op.envelopeStage = OPAL_ENVELOPE_STAGE_DECAY
                ELSEIF rateHigh >= 12 THEN
                    ' Fast attack
                    stepSize = 4 \ (2 ^ (15 - rateHigh))
                    IF stepSize < 1 THEN stepSize = 1
                    level = level - (level \ (2 ^ (3 - rateLow))) - 1
                    IF level <= 0 THEN
                        level = 0
                        op.envelopeStage = OPAL_ENVELOPE_STAGE_DECAY
                    END IF
                ELSE
                    ' Normal attack: decrement based on counter alignment
                    DIM mask AS _UNSIGNED _INTEGER64
                    mask = (2 ^ (13 - rateHigh)) - 1
                    IF (chip.chipSamples AND mask) = 0 THEN
                        stepSize = 4 + rateLow
                        level = level - (level \ 8) - 1
                        IF level <= 0 THEN
                            level = 0
                            op.envelopeStage = OPAL_ENVELOPE_STAGE_DECAY
                        END IF
                    END IF
                END IF
            END IF

        CASE OPAL_ENVELOPE_STAGE_DECAY
            IF op.decayRate = 0 THEN
                ' No decay
            ELSE
                IF op.keyScaleRate THEN
                    ksn = chip.chan(pitchCh).latchedKeyScaleNumber
                ELSE
                    ksn = chip.chan(pitchCh).latchedKeyScaleNumber \ 4
                END IF
                effectiveRate = op.decayRate * 4 + ksn
                IF effectiveRate > 63 THEN effectiveRate = 63

                rateHigh = effectiveRate \ 4
                rateLow = effectiveRate AND 3

                DIM decMask AS _UNSIGNED _INTEGER64
                IF rateHigh < 13 THEN
                    decMask = (2 ^ (13 - rateHigh)) - 1
                ELSE
                    decMask = 0
                END IF

                IF (chip.chipSamples AND decMask) = 0 OR rateHigh >= 12 THEN
                    stepSize = 1
                    IF rateHigh >= 13 THEN stepSize = 2 ^ (rateHigh - 13)
                    level = level + stepSize
                END IF
            END IF

            ' Check if we've reached sustain level
            DIM susTarget AS LONG
            IF op.sustainLevel = 15 THEN
                susTarget = OPAL_ENVELOPE_SILENT
            ELSE
                susTarget = op.sustainLevel * 32 ' Each sustain step = 3dB = 32 units of 0.09375dB
            END IF

            IF level >= susTarget THEN
                level = susTarget
                IF op.sustainHold THEN
                    op.envelopeStage = OPAL_ENVELOPE_STAGE_SUSTAIN
                ELSE
                    op.envelopeStage = OPAL_ENVELOPE_STAGE_RELEASE
                END IF
            END IF

        CASE OPAL_ENVELOPE_STAGE_SUSTAIN
            ' Sustain: level held until key-off

        CASE OPAL_ENVELOPE_STAGE_RELEASE
            IF op.releaseRate = 0 THEN
                ' No release
            ELSE
                IF op.keyScaleRate THEN
                    ksn = chip.chan(pitchCh).latchedKeyScaleNumber
                ELSE
                    ksn = chip.chan(pitchCh).latchedKeyScaleNumber \ 4
                END IF
                effectiveRate = op.releaseRate * 4 + ksn
                IF effectiveRate > 63 THEN effectiveRate = 63

                rateHigh = effectiveRate \ 4
                DIM relMask AS _UNSIGNED _INTEGER64
                IF rateHigh < 13 THEN
                    relMask = (2 ^ (13 - rateHigh)) - 1
                ELSE
                    relMask = 0
                END IF

                IF (chip.chipSamples AND relMask) = 0 OR rateHigh >= 12 THEN
                    stepSize = 1
                    IF rateHigh >= 13 THEN stepSize = 2 ^ (rateHigh - 13)
                    level = level + stepSize
                END IF
            END IF

            IF level >= OPAL_ENVELOPE_SILENT THEN level = OPAL_ENVELOPE_SILENT
    END SELECT

    IF level > OPAL_ENVELOPE_SILENT THEN level = OPAL_ENVELOPE_SILENT
    IF level < 0 THEN level = 0

    op.envelope = level
    chip.op(slot) = op
END SUB

' Key-on: restart envelope
SUB OpalOperatorKeyOn (chip AS OpalState, slot AS _UNSIGNED LONG)
    chip.op(slot).envelopeStage = OPAL_ENVELOPE_STAGE_ATTACK
    chip.op(slot).phase = 0
END SUB

' Key-off: enter release
SUB OpalOperatorKeyOff (chip AS OpalState, slot AS _UNSIGNED LONG)
    IF chip.op(slot).envelopeStage <> OPAL_ENVELOPE_STAGE_RELEASE THEN
        chip.op(slot).envelopeStage = OPAL_ENVELOPE_STAGE_RELEASE
    END IF
END SUB

' ============================================================================================================
' OPERATOR TICK (process one sample for one operator)
' ============================================================================================================
SUB OpalOperatorTurn (chip AS OpalState, slot AS _UNSIGNED LONG)
    DIM op AS OpalOperator
    DIM pitchCh AS _UNSIGNED LONG
    DIM attenuation AS _UNSIGNED LONG
    DIM ch AS _UNSIGNED LONG
    DIM algIdx AS _UNSIGNED _BYTE
    DIM position AS _UNSIGNED LONG
    DIM modInput AS LONG
    DIM phaseWithMod AS _UNSIGNED LONG
    DIM outputSample AS INTEGER

    op = chip.op(slot)
    pitchCh = OpalOperatorPitchChannel~&(chip, slot)
    ch = opalOperatorOwner(slot)

    ' Calculate total attenuation
    attenuation = op.envelope + 4 * op.totalLevel + OpalOperatorKeyScaleLevel~%(chip, slot)
    IF op.tremolo THEN
        attenuation = attenuation + chip.tremoloLevel
    END IF
    IF attenuation > OPAL_ENVELOPE_SILENT THEN attenuation = OPAL_ENVELOPE_SILENT
    op.egOut = attenuation

    ' Process envelope
    OpalOperatorEnvelope chip, slot, ((chip.chipSamples AND 1) <> 0)

    ' Determine modulation input
    algIdx = OpalChannelAlgorithmIndex~%%(chip, ch)
    position = OpalOperatorVoicePosition~&(chip, slot)
    modInput = 0

    IF OpalAlgorithmFeedsBack%%(opalAlgorithms(algIdx), position) THEN
        ' Self-feedback
        IF chip.chan(ch).feedback > 0 THEN
            modInput = OpalFloorShift&(op.out + op.prevOut, 9 - chip.chan(ch).feedback)
        END IF
    ELSEIF OpalAlgorithmChains%%(opalAlgorithms(algIdx), position) THEN
        ' Chain from previous operator
        IF slot >= OPAL_VOICE_STRIDE THEN
            modInput = chip.op(slot - OPAL_VOICE_STRIDE).out
        END IF
    END IF

    ' Advance phase
    op.prevOut = op.out
    op.phase = (op.phase + OpalOperatorIncrement~&(chip, slot)) AND &HFFFFF ' 20-bit phase

    ' Compute waveform output
    phaseWithMod = ((op.phase \ 512) + modInput) AND &H3FF
    op.out = OpalWaveformOutput%(op.waveform, phaseWithMod, attenuation)

    chip.op(slot) = op
END SUB

' ============================================================================================================
' CHANNEL OUTPUT MIXING
' ============================================================================================================
SUB OpalChannelOutput (chip AS OpalState, ch AS _UNSIGNED LONG, leftSum AS LONG, rightSum AS LONG)
    DIM algIdx AS _UNSIGNED _BYTE
    DIM alg AS OpalAlgorithmDesc
    DIM i AS LONG
    DIM slotIdx AS _UNSIGNED _BYTE
    DIM position AS _UNSIGNED LONG
    DIM sample AS LONG
    DIM gainShift AS _UNSIGNED LONG

    ' Skip 4-op tail channels (their output is mixed by the lead)
    IF OpalChannelIsPairTail%%(ch) AND OpalChannelIsPaired%%(chip, ch) THEN
        EXIT SUB
    END IF

    algIdx = OpalChannelAlgorithmIndex~%%(chip, ch)
    alg = opalAlgorithms(algIdx)

    sample = 0

    ' Sum carrier outputs
    FOR i = 0 TO alg.operatorCount - 1
        IF OpalAlgorithmIsCarrier%%(alg, i) THEN
            DIM opCount AS LONG
            ' Find which slot this position maps to
            IF i < 2 THEN
                slotIdx = chip.chan(ch).opSlot(i)
            ELSE
                ' Positions 2,3 are on the paired (tail) channel
                IF chip.chan(ch).pairIndex <> OPAL_CH_NONE THEN
                    slotIdx = chip.chan(chip.chan(ch).pairIndex).opSlot(i - 2)
                ELSE
                    slotIdx = OPAL_OP_NONE
                END IF
            END IF

            IF slotIdx <> OPAL_OP_NONE AND slotIdx < OPAL_OPERATOR_COUNT THEN
                sample = sample + chip.op(slotIdx).out
            END IF
        END IF
    NEXT

    ' Apply gain
    IF alg.gain > 1 THEN
        sample = sample \ alg.gain
    END IF

    ' Apply panning and output enable
    IF chip.chan(ch).outputEnable AND 1 THEN ' Left enabled
        leftSum = leftSum + (sample * chip.chan(ch).leftPan) \ OPAL_FULL_GAIN
    END IF
    IF chip.chan(ch).outputEnable AND 2 THEN ' Right enabled
        rightSum = rightSum + (sample * chip.chan(ch).rightPan) \ OPAL_FULL_GAIN
    END IF
END SUB

' ============================================================================================================
' CHIP TICK (one OPL3-rate sample)
' ============================================================================================================
SUB OpalChipTick (chip AS OpalState)
    DIM slot AS _UNSIGNED LONG
    DIM ch AS _UNSIGNED LONG
    DIM leftSum AS LONG, rightSum AS LONG

    ' Update tremolo LFO
    DIM tremoloPos AS _UNSIGNED LONG
    tremoloPos = chip.tremoloPosition
    IF tremoloPos < OPAL_TREMOLO_PEAK THEN
        chip.tremoloLevel = tremoloPos
    ELSE
        chip.tremoloLevel = OPAL_TREMOLO_STEPS - tremoloPos
    END IF
    IF chip.tremoloDepth = 0 THEN
        chip.tremoloLevel = chip.tremoloLevel \ 4
    END IF

    ' Advance tremolo
    IF (chip.chipSamples AND 63) = 0 THEN
        chip.tremoloPosition = (chip.tremoloPosition + 1) MOD OPAL_TREMOLO_STEPS
    END IF

    ' Update noise generator (23-bit LFSR)
    IF chip.noise AND 1 THEN
        chip.noise = (chip.noise XOR &H800302~&) \ 2 OR &H400000~&
    ELSE
        chip.noise = chip.noise \ 2
    END IF

    ' Tick all operators
    FOR slot = 0 TO OPAL_OPERATOR_COUNT - 1
        OpalOperatorTurn chip, slot
    NEXT

    ' Update hi-hat and cymbal phase accumulators for rhythm mode
    IF chip.rhythmMode THEN
        IF OPAL_HI_HAT_SLOT < OPAL_OPERATOR_COUNT THEN
            chip.hiHatPhase = chip.op(OPAL_HI_HAT_SLOT).phase \ 512
        END IF
        IF OPAL_CYMBAL_SLOT < OPAL_OPERATOR_COUNT THEN
            chip.cymbalPhase = chip.op(OPAL_CYMBAL_SLOT).phase \ 512
        END IF
    END IF

    ' Mix channel outputs
    leftSum = 0
    rightSum = 0
    FOR ch = 0 TO OPAL_CHANNEL_COUNT - 1
        OpalChannelOutput chip, ch, leftSum, rightSum
    NEXT

    ' Tick timers (Timer 1 ticks every 4th sample of 80 us period)
    IF (chip.chipSamples AND 3) = 0 THEN
        OpalTickTimer chip, 0
    END IF
    ' Timer 2 ticks every 16th sample
    IF (chip.chipSamples AND 15) = 0 THEN
        OpalTickTimer chip, 1
    END IF

    chip.sampleCounter = chip.sampleCounter + 1
    chip.chipSamples = chip.chipSamples + 1

    ' Store output
    chip.lastOutput(0) = chip.currOutput(0)
    chip.lastOutput(1) = chip.currOutput(1)
    chip.currOutput(0) = OpalSaturate%(leftSum)
    chip.currOutput(1) = OpalSaturate%(rightSum)
END SUB

SUB OpalTickTimer (chip AS OpalState, t AS LONG)
    IF (chip.timerControl AND (2 ^ t)) = 0 THEN EXIT SUB

    chip.timerCount(t) = chip.timerCount(t) + 1
    IF chip.timerCount(t) > 255 THEN
        DIM flag AS _UNSIGNED _BYTE
        IF t = 0 THEN flag = &H40 ELSE flag = &H20
        chip.timerCount(t) = chip.timer(t)
        IF (chip.timerControl AND flag) = 0 THEN
            chip.status = chip.status OR (flag OR &H80)
        END IF
    END IF
END SUB

' ============================================================================================================
' REGISTER WRITE DISPATCH
' ============================================================================================================
SUB OpalWrite (chip AS OpalState, regNum AS _UNSIGNED INTEGER, value AS _UNSIGNED _BYTE)
    DIM bank AS _UNSIGNED LONG
    DIM regLow AS _UNSIGNED _BYTE
    DIM ch AS _UNSIGNED LONG
    DIM slot AS _UNSIGNED LONG
    DIM opOffset AS _UNSIGNED LONG

    ' Determine bank
    IF regNum >= &H100 THEN
        bank = 1
        ' In OPL2 mode, only register 0x105 goes to bank 1
        IF chip.newMode = 0 AND regNum <> OPAL_NEW_REGISTER THEN
            bank = 0
        END IF
    ELSE
        bank = 0
    END IF

    regLow = regNum AND &HFF

    ' Special registers
    SELECT CASE regNum
        CASE OPAL_NEW_REGISTER ' 0x105 - NEW bit
            chip.newMode = value AND 1
            EXIT SUB
        CASE OPAL_FOUR_OP_REGISTER ' 0x104 - 4-op enable
            chip.pairEnable = value AND OPAL_PAIR_ENABLE_MASK
            ' Refresh channel routing
            OpalRefreshRouting chip
            EXIT SUB
    END SELECT

    SELECT CASE regLow
        ' --- Timer and control registers ---
        CASE &H02 ' Timer 1 value
            chip.timer(0) = value
        CASE &H03 ' Timer 2 value
            chip.timer(1) = value
        CASE &H04 ' Timer control / IRQ
            IF value AND &H80 THEN
                ' Reset IRQ and flags
                chip.status = 0
            ELSE
                chip.timerControl = value AND &H3F
            END IF

        CASE &H08 ' CSW / Note-Sel
            chip.compositeSine = (value AND &H40) \ &H40
            chip.noteSelect = (value AND &H40) \ &H40 ' Note select = bit 6

            ' --- Operator registers ---
            ' 0x20-0x35: Tremolo / Vibrato / Sustain / KSR / Multiplier
        CASE &H20 TO &H35
            slot = OpalRegToSlot~&(regLow - &H20, bank)
            IF slot < OPAL_OPERATOR_COUNT THEN
                chip.op(slot).tremolo = (value AND &H80) \ &H80
                chip.op(slot).vibrato = (value AND &H40) \ &H40
                chip.op(slot).sustainHold = (value AND &H20) \ &H20
                chip.op(slot).keyScaleRate = (value AND &H10) \ &H10
                chip.op(slot).multiple = value AND &HF
            END IF

            ' 0x40-0x55: Key Scale Level / Total Level
        CASE &H40 TO &H55
            slot = OpalRegToSlot~&(regLow - &H40, bank)
            IF slot < OPAL_OPERATOR_COUNT THEN
                chip.op(slot).keyScaleLevel = (value AND &HC0) \ &H40
                chip.op(slot).totalLevel = value AND &H3F
            END IF

            ' 0x60-0x75: Attack Rate / Decay Rate
        CASE &H60 TO &H75
            slot = OpalRegToSlot~&(regLow - &H60, bank)
            IF slot < OPAL_OPERATOR_COUNT THEN
                chip.op(slot).attackRate = (value AND &HF0) \ &H10
                chip.op(slot).decayRate = value AND &HF
            END IF

            ' 0x80-0x95: Sustain Level / Release Rate
        CASE &H80 TO &H95
            slot = OpalRegToSlot~&(regLow - &H80, bank)
            IF slot < OPAL_OPERATOR_COUNT THEN
                chip.op(slot).sustainLevel = (value AND &HF0) \ &H10
                chip.op(slot).releaseRate = value AND &HF
            END IF

            ' 0xE0-0xF5: Waveform Select
        CASE &HE0 TO &HF5
            slot = OpalRegToSlot~&(regLow - &HE0, bank)
            IF slot < OPAL_OPERATOR_COUNT THEN
                IF chip.newMode THEN
                    chip.op(slot).waveform = value AND OPAL_WAVEFORM_MASK_NEW
                ELSE
                    chip.op(slot).waveform = value AND OPAL_WAVEFORM_MASK_OPL2
                END IF
            END IF

            ' --- Channel registers ---
            ' 0xA0-0xA8: Frequency Number (low 8 bits)
        CASE &HA0 TO &HA8
            ch = (regLow - &HA0) + bank * OPAL_CHANNELS_PER_BANK
            IF ch < OPAL_CHANNEL_COUNT THEN
                chip.chan(ch).fNumber = (chip.chan(ch).fNumber AND &H300) OR value
                OpalChannelLatchKeyScale chip, ch
            END IF

            ' 0xB0-0xB8: Key-On / Block / Frequency (high 2 bits)
        CASE &HB0 TO &HB8
            ch = (regLow - &HB0) + bank * OPAL_CHANNELS_PER_BANK
            IF ch < OPAL_CHANNEL_COUNT THEN
                DIM keyOn AS _UNSIGNED _BYTE
                keyOn = (value AND &H20) \ &H20

                chip.chan(ch).fNumber = (chip.chan(ch).fNumber AND &HFF) OR _SHL(value AND 3, 8)
                chip.chan(ch).block = (value AND &H1C) \ 4

                OpalChannelLatchKeyScale chip, ch

                ' Key on/off the channel's operators
                DIM slotCount AS LONG
                IF OpalChannelSpansPair%%(chip, ch) THEN slotCount = 4 ELSE slotCount = 2

                DIM si AS LONG
                FOR si = 0 TO slotCount - 1
                    DIM sIdx AS _UNSIGNED _BYTE
                    sIdx = chip.chan(ch).opSlot(si)
                    IF sIdx <> OPAL_OP_NONE AND sIdx < OPAL_OPERATOR_COUNT THEN
                        DIM prevKey AS _UNSIGNED _BYTE
                        prevKey = chip.op(sIdx).key AND 1
                        chip.op(sIdx).key = (chip.op(sIdx).key AND 2) OR keyOn
                        IF keyOn AND (prevKey = 0) THEN
                            OpalOperatorKeyOn chip, sIdx
                        ELSEIF (keyOn = 0) AND prevKey THEN
                            OpalOperatorKeyOff chip, sIdx
                        END IF
                    END IF
                NEXT
            END IF

            ' 0xBD: Rhythm / Tremolo Depth / Vibrato Depth
        CASE &HBD
            IF bank = 0 THEN
                chip.tremoloDepth = (value AND &H80) \ &H80
                chip.vibratoDepth = (value AND &H40) \ &H40

                DIM prevRhythm AS _UNSIGNED _BYTE
                prevRhythm = chip.rhythmMode
                chip.rhythmMode = (value AND &H20) \ &H20

                IF chip.rhythmMode <> prevRhythm THEN
                    OpalRefreshRouting chip
                END IF

                ' Handle rhythm key-on bits (BD=bit4, SD=bit3, TT=bit2, CY=bit1, HH=bit0)
                IF chip.rhythmMode THEN
                    DIM ri AS LONG
                    FOR ri = 6 TO 8
                        DIM rsi AS LONG
                        FOR rsi = 0 TO 1
                            DIM rsIdx AS _UNSIGNED _BYTE
                            rsIdx = chip.chan(ri).opSlot(rsi)
                            IF rsIdx <> OPAL_OP_NONE AND rsIdx < OPAL_OPERATOR_COUNT THEN
                                DIM rhythmBit AS _UNSIGNED _BYTE
                                ' Map channel+slot to rhythm instrument bit
                                DIM instrIdx AS LONG
                                instrIdx = (ri - 6) * 2 + rsi
                                IF instrIdx <= 5 THEN
                                    rhythmBit = opalRhythmKeyBit(instrIdx)
                                    DIM rKeyOn AS _UNSIGNED _BYTE
                                    rKeyOn = (value AND (2 ^ rhythmBit)) \ (2 ^ rhythmBit)
                                    DIM rPrevKey AS _UNSIGNED _BYTE
                                    rPrevKey = (chip.op(rsIdx).key AND 2) \ 2
                                    chip.op(rsIdx).key = (chip.op(rsIdx).key AND 1) OR (rKeyOn * 2)
                                    IF rKeyOn AND (rPrevKey = 0) THEN
                                        OpalOperatorKeyOn chip, rsIdx
                                    ELSEIF (rKeyOn = 0) AND rPrevKey THEN
                                        OpalOperatorKeyOff chip, rsIdx
                                    END IF
                                END IF
                            END IF
                        NEXT
                    NEXT
                END IF
            END IF

            ' 0xC0-0xC8: Feedback / Connection / Output Enable
        CASE &HC0 TO &HC8
            ch = (regLow - &HC0) + bank * OPAL_CHANNELS_PER_BANK
            IF ch < OPAL_CHANNEL_COUNT THEN
                chip.chan(ch).feedback = (value AND &H0E) \ 2
                chip.chan(ch).connection = value AND 1

                IF chip.newMode THEN
                    chip.chan(ch).outputEnable = (value AND &H30) \ &H10
                ELSE
                    chip.chan(ch).outputEnable = OPAL_OUTPUT_BOTH_SIDES
                END IF
            END IF
    END SELECT
END SUB

' Map a register offset (0x00-0x15 range) + bank to an operator slot index
FUNCTION OpalRegToSlot~& (offset AS _UNSIGNED _BYTE, bank AS _UNSIGNED LONG)
    DIM result AS _UNSIGNED LONG

    ' OPL3 register-to-slot mapping:
    ' Offsets 0x00-0x05 map to slots 0-5
    ' Offsets 0x08-0x0D map to slots 6-11
    ' Offsets 0x10-0x15 map to slots 12-17
    ' Other offsets are invalid

    DIM group AS _UNSIGNED LONG
    DIM member AS _UNSIGNED LONG
    group = offset \ 8
    member = offset AND 7

    IF member > 5 THEN
        OpalRegToSlot~& = OPAL_OPERATOR_COUNT ' invalid
        EXIT FUNCTION
    END IF
    IF group > 2 THEN
        OpalRegToSlot~& = OPAL_OPERATOR_COUNT ' invalid
        EXIT FUNCTION
    END IF

    result = group * 6 + member + bank * OPAL_OPERATORS_PER_BANK
    OpalRegToSlot~& = result
END FUNCTION

' Latch key-scale number for a channel
SUB OpalChannelLatchKeyScale (chip AS OpalState, ch AS _UNSIGNED LONG)
    DIM noteBit AS _UNSIGNED LONG
    IF chip.noteSelect THEN
        noteBit = (chip.chan(ch).fNumber \ 256) AND 1
    ELSE
        noteBit = (chip.chan(ch).fNumber \ 512) AND 1
    END IF
    chip.chan(ch).latchedKeyScaleNumber = 2 * chip.chan(ch).block + noteBit
END SUB

' Refresh all channel type/routing after pair enable or rhythm mode change
SUB OpalRefreshRouting (chip AS OpalState)
    DIM ch AS _UNSIGNED LONG
    FOR ch = 0 TO OPAL_CHANNEL_COUNT - 1
        IF OpalChannelIsRhythm%%(chip, ch) THEN
            chip.chan(ch).chanType = OPAL_CHANNEL_TYPE_DRUM
        ELSEIF OpalChannelIsPaired%%(chip, ch) THEN
            IF OpalChannelIsPairTail%%(ch) THEN
                chip.chan(ch).chanType = OPAL_CHANNEL_TYPE_4OP2
            ELSE
                chip.chan(ch).chanType = OPAL_CHANNEL_TYPE_4OP
            END IF
        ELSE
            chip.chan(ch).chanType = OPAL_CHANNEL_TYPE_2OP
        END IF
    NEXT
END SUB

' ============================================================================================================
' BUFFERED WRITE SUPPORT
' ============================================================================================================
SUB OpalProcessQueue (chip AS OpalState)
    DO WHILE chip.queueCount > 0
        DIM idx AS _UNSIGNED INTEGER
        idx = chip.queueHead
        IF chip.queue(idx).due > chip.chipSamples THEN EXIT DO
        OpalWrite chip, chip.queue(idx).regNum, chip.queue(idx).value
        chip.queueHead = (chip.queueHead + 1) AND (OPAL_WRITEBUF_SIZE - 1)
        chip.queueCount = chip.queueCount - 1
    LOOP
END SUB

' ============================================================================================================
' PUBLIC API
' ============================================================================================================

' Initialize / reset the Opal emulator
SUB OpalInit (chip AS OpalState, sampleRate AS LONG)
    OpalInitTables

    DIM ch AS _UNSIGNED LONG
    DIM slot AS _UNSIGNED LONG
    DIM localCh AS _UNSIGNED LONG
    DIM first AS _UNSIGNED LONG
    DIM leads AS _BYTE

    ' Zero out the entire structure
    chip.sampleRate = 0
    chip.sampleAccum = 0
    chip.lastOutput(0) = 0: chip.lastOutput(1) = 0
    chip.currOutput(0) = 0: chip.currOutput(1) = 0
    chip.timer(0) = 0: chip.timer(1) = 0
    chip.timerControl = 0
    chip.timerCount(0) = 0: chip.timerCount(1) = 0
    chip.status = 0
    chip.newMode = 0
    chip.pairEnable = 0
    chip.rhythmMode = 0
    chip.noteSelect = 0
    chip.tremoloDepth = 0
    chip.vibratoDepth = 0
    chip.waveSelectEnable = 0
    chip.compositeSine = 0
    chip.tremoloPosition = 0
    chip.tremoloLevel = 0
    chip.sampleCounter = 0
    chip.hiHatPhase = 0
    chip.cymbalPhase = 0
    chip.pendingRight = 0
    chip.chipSamples = 0
    chip.lastDue = 0
    chip.queueHead = 0
    chip.queueCount = 0

    ' Initialize channels
    FOR ch = 0 TO OPAL_CHANNEL_COUNT - 1
        localCh = ch MOD OPAL_CHANNELS_PER_BANK
        first = opalSlotMap(ch)
        leads = (localCh < OPAL_PAIRS_PER_BANK)

        chip.chan(ch).opSlot(0) = first
        chip.chan(ch).opSlot(1) = first + 3
        IF leads THEN
            chip.chan(ch).opSlot(2) = first + 6
            chip.chan(ch).opSlot(3) = first + 9
        ELSE
            chip.chan(ch).opSlot(2) = OPAL_OP_NONE
            chip.chan(ch).opSlot(3) = OPAL_OP_NONE
        END IF

        IF leads THEN
            chip.chan(ch).pairIndex = ch + 3
        ELSEIF localCh < 6 THEN
            chip.chan(ch).pairIndex = ch - 3
        ELSE
            chip.chan(ch).pairIndex = OPAL_CH_NONE
        END IF

        chip.chan(ch).leftPan = OPAL_FULL_GAIN
        chip.chan(ch).rightPan = OPAL_FULL_GAIN
        chip.chan(ch).outputEnable = OPAL_OUTPUT_BOTH_SIDES
        chip.chan(ch).chanType = OPAL_CHANNEL_TYPE_2OP
        chip.chan(ch).fNumber = 0
        chip.chan(ch).block = 0
        chip.chan(ch).latchedKeyScaleNumber = 0
        chip.chan(ch).feedback = 0
        chip.chan(ch).connection = 0
        chip.chan(ch).algorithm = 0
        chip.chan(ch).outSource(0) = OPAL_OP_NONE
        chip.chan(ch).outSource(1) = OPAL_OP_NONE
        chip.chan(ch).outSource(2) = OPAL_OP_NONE
        chip.chan(ch).outSource(3) = OPAL_OP_NONE
    NEXT

    ' Initialize operators
    FOR slot = 0 TO OPAL_OPERATOR_COUNT - 1
        chip.op(slot).envelopeStage = OPAL_ENVELOPE_STAGE_RELEASE
        chip.op(slot).egOut = OPAL_ENVELOPE_SILENT
        chip.op(slot).envelope = OPAL_ENVELOPE_SILENT
        chip.op(slot).key = 0
        chip.op(slot).modSource = OPAL_OP_NONE
        chip.op(slot).out = 0
        chip.op(slot).prevOut = 0
        chip.op(slot).phase = 0
        chip.op(slot).tremolo = 0
        chip.op(slot).vibrato = 0
        chip.op(slot).sustainHold = 0
        chip.op(slot).keyScaleRate = 0
        chip.op(slot).multiple = 0
        chip.op(slot).keyScaleLevel = 0
        chip.op(slot).totalLevel = 63 ' silent
        chip.op(slot).attackRate = 0
        chip.op(slot).decayRate = 0
        chip.op(slot).sustainLevel = 0
        chip.op(slot).releaseRate = 0
        chip.op(slot).waveform = 0
    NEXT

    chip.noise = 1

    OpalRefreshRouting chip
    OpalSetSampleRate chip, sampleRate
END SUB

' Change the output sample rate
SUB OpalSetSampleRate (chip AS OpalState, sampleRate AS LONG)
    DIM sr AS LONG
    sr = sampleRate
    IF sr <= 0 THEN sr = OPAL_OPL3_SAMPLE_RATE
    IF sr > 2147483647 - OPAL_OPL3_SAMPLE_RATE THEN sr = 2147483647 - OPAL_OPL3_SAMPLE_RATE
    chip.sampleRate = sr
    chip.sampleAccum = 0
END SUB

' Write a register immediately
SUB OpalWriteReg (chip AS OpalState, regNum AS _UNSIGNED INTEGER, value AS _UNSIGNED _BYTE)
    OpalWrite chip, regNum, value
END SUB

' Queue a register write with minimum spacing
SUB OpalWriteRegBuffered (chip AS OpalState, regNum AS _UNSIGNED INTEGER, value AS _UNSIGNED _BYTE)
    DIM due AS _UNSIGNED _INTEGER64
    due = chip.chipSamples + OPAL_WRITEBUF_DELAY
    IF due <= chip.lastDue THEN
        due = chip.lastDue + OPAL_WRITEBUF_DELAY
    END IF
    chip.lastDue = due

    IF chip.queueCount >= OPAL_WRITEBUF_SIZE THEN
        ' Queue full, flush and write immediately
        OpalFlushWriteBuf chip
        OpalWrite chip, regNum, value
        EXIT SUB
    END IF

    DIM idx AS _UNSIGNED INTEGER
    idx = (chip.queueHead + chip.queueCount) AND (OPAL_WRITEBUF_SIZE - 1)
    chip.queue(idx).due = due
    chip.queue(idx).regNum = regNum
    chip.queue(idx).value = value
    chip.queueCount = chip.queueCount + 1
END SUB

' Flush all queued writes
SUB OpalFlushWriteBuf (chip AS OpalState)
    DO WHILE chip.queueCount > 0
        DIM idx AS _UNSIGNED INTEGER
        idx = chip.queueHead
        OpalWrite chip, chip.queue(idx).regNum, chip.queue(idx).value
        chip.queueHead = (chip.queueHead + 1) AND (OPAL_WRITEBUF_SIZE - 1)
        chip.queueCount = chip.queueCount - 1
    LOOP
END SUB

' Generate one stereo 16-bit PCM sample
SUB OpalSample (chip AS OpalState, left AS INTEGER, right AS INTEGER)
    ' Process queued writes that are due
    OpalProcessQueue chip

    ' Generate OPL3-rate chip samples until we have enough for the output rate
    DO WHILE chip.sampleAccum >= chip.sampleRate
        chip.sampleAccum = chip.sampleAccum - chip.sampleRate
        OpalChipTick chip
    LOOP

    ' Interpolate between last and current chip output
    DIM fract AS LONG
    IF chip.sampleRate > 0 THEN
        fract = (chip.sampleAccum * 65536) \ chip.sampleRate
    ELSE
        fract = 0
    END IF

    left = OpalInterpolate%(chip.lastOutput(0), chip.currOutput(0), fract)
    right = OpalInterpolate%(chip.lastOutput(1), chip.currOutput(1), fract)

    chip.sampleAccum = chip.sampleAccum + OPAL_OPL3_SAMPLE_RATE
END SUB

' Set channel panning
SUB OpalPan (chip AS OpalState, channel AS _UNSIGNED INTEGER, pan AS _UNSIGNED _BYTE)
    DIM chanNum AS _UNSIGNED INTEGER
    chanNum = (channel AND &HFF)
    IF channel AND &H100 THEN chanNum = chanNum + 9

    IF chanNum >= OPAL_CHANNEL_COUNT THEN EXIT SUB

    DIM p AS _UNSIGNED _BYTE
    p = pan
    IF p > 127 THEN p = 127

    ' Convert 0-127 pan to left/right gain (0-256)
    chip.chan(chanNum).rightPan = p * 2
    chip.chan(chanNum).leftPan = (127 - p) * 2
END SUB

' Read the status register
FUNCTION OpalReadStatus~%% (chip AS OpalState)
    OpalReadStatus~%% = chip.status
END FUNCTION
