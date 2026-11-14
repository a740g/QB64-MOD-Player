'-----------------------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'SoftSynth.bi'
'$INCLUDE:'Math.bi'
'$INCLUDE:'String.bi'
'$INCLUDE:'AudioConv.bi'
'$INCLUDE:'StringFile.bi'
'$INCLUDE:'File.bi'

CONST __NOTE_NONE~%% = 132~%% ' Note will be set to this when there is nothing
CONST __NOTE_KEY_OFF~%% = 133~%% ' We'll use this in a future version
CONST __NOTE_NO_VOLUME~%% = 255~%% ' When a note has no volume, then it will be set to this
CONST __MOD_S3M_ROWS~%% = 64~%% ' number of rows in a MOD / S3M pattern
CONST __MOD_MTM_ORDER_MAX~%% = 127~%% ' maximum position in a MOD / MTM order table
CONST __INSTRUMENT_VOLUME_MAX~%% = 64~%% ' this is the maximum volume of any MOD instrument
CONST __INSTRUMENT_NONE~%% = 0~%% ' no instrument
CONST __INSTRUMENT_PCM~%% = 1~%% ' good old digital PCM instrument
CONST __INSTRUMENT_FM_MELODY~%% = 2~%% ' FM melody instrument
CONST __INSTRUMENT_FM_BASSDRUM~%% = 3~%% ' FM bass drum instrument
CONST __INSTRUMENT_FM_SNAREDRUM~%% = 4~%% ' FM snare instrument
CONST __INSTRUMENT_FM_TOMTOM~%% = 5~%% ' FM tom-tom instrument
CONST __INSTRUMENT_FM_CYMBAL~%% = 6~%% ' FM cymbal instrument
CONST __INSTRUMENT_FM_HIHAT~%% = 7~%% ' FM hi-hat instrument
CONST __PATTERN_MARKER~%% = 254~%% ' S3M marker pattern
CONST __PATTERN_END~%% = 255~%% ' S3M end-of-song
CONST __CHANNEL_STEREO_SEPARATION! = 0.5! ' 100% stereo separation sounds bad on headphones
CONST __MTM_S3M_CHANNEL_MAX~%% = 31~%% ' maximum channel number supported by MTM / S3M
CONST __S3M_GLOBAL_VOLUME_MAX~%% = 64~%% ' S3M global volume maximum value
CONST __SONG_SPEED_DEFAULT~%% = 6~%% ' This is the default speed for song where it is not specified
CONST __SONG_BPM_DEFAULT~%% = 125~%% ' Default song BPM when it is not specified
' These are the effects support by the player (basically these are Protracker effects + extras)
CONST __MOD_FX_ARPEGGIO~%% = 0~%%
CONST __MOD_FX_PORTAMENTO_UP~%% = 1~%%
CONST __MOD_FX_PORTAMENTO_DOWN~%% = 2~%%
CONST __MOD_FX_PORTAMENTO~%% = 3~%%
CONST __MOD_FX_VIBRATO~%% = 4~%%
CONST __MOD_FX_PORTAMENTO_VOLUME_SLIDE~%% = 5~%%
CONST __MOD_FX_VIBRATO_VOLUME_SLIDE~%% = 6~%%
CONST __MOD_FX_TREMOLO~%% = 7~%%
CONST __MOD_FX_PANNING_8~%% = 8~%%
CONST __MOD_FX_SAMPLE_OFFSET~%% = 9~%%
CONST __MOD_FX_VOLUME_SLIDE~%% = 10~%%
CONST __MOD_FX_POSITION_JUMP~%% = 11~%%
CONST __MOD_FX_VOLUME~%% = 12~%%
CONST __MOD_FX_PATTERN_BREAK~%% = 13~%%
CONST __MOD_FX_EXTENDED~%% = 14~%%
CONST __MOD_FX_EXTENDED_FILTER~%% = 0~%%
CONST __MOD_FX_EXTENDED_PORTAMENTO_FINE_UP~%% = 1~%%
CONST __MOD_FX_EXTENDED_PORTAMENTO_FINE_DOWN~%% = 2~%%
CONST __MOD_FX_EXTENDED_GLISSANDO_CONTROL~%% = 3~%%
CONST __MOD_FX_EXTENDED_VIBRATO_WAVEFORM~%% = 4~%%
CONST __MOD_FX_EXTENDED_FINETUNE~%% = 5~%%
CONST __MOD_FX_EXTENDED_PATTERN_LOOP~%% = 6~%%
CONST __MOD_FX_EXTENDED_TREMOLO_WAVEFORM~%% = 7~%%
CONST __MOD_FX_EXTENDED_PANNING_4~%% = 8~%%
CONST __MOD_FX_EXTENDED_NOTE_RETRIGGER~%% = 9~%%
CONST __MOD_FX_EXTENDED_VOLUME_FINE_SLIDE_UP~%% = 10~%%
CONST __MOD_FX_EXTENDED_VOLUME_FINE_SLIDE_DOWN~%% = 11~%%
CONST __MOD_FX_EXTENDED_NOTE_CUT~%% = 12~%%
CONST __MOD_FX_EXTENDED_NOTE_DELAY~%% = 13~%%
CONST __MOD_FX_EXTENDED_PATTERN_DELAY~%% = 14~%%
CONST __MOD_FX_EXTENDED_INVERT_LOOP~%% = 15~%%
CONST __MOD_FX_SPEED_TEMPO~%% = 15~%%
CONST __MOD_FX_SPEED~%% = 16~%%
CONST __MOD_FX_VOLUME_FINE_SLIDE~%% = 17~%%
CONST __MOD_FX_PORTAMENTO_EXTRA_FINE_DOWN~%% = 18~%%
CONST __MOD_FX_PORTAMENTO_EXTRA_FINE_UP~%% = 19~%%
CONST __MOD_FX_TREMOR~%% = 20~%%
CONST __MOD_FX_VIBRATO_VOLUME_FINE_SLIDE~%% = 21~%%
CONST __MOD_FX_PORTAMENTO_VOLUME_FINE_SLIDE~%% = 22~%%
CONST __MOD_FX_CHANNEL_VOLUME~%% = 23~%%
CONST __MOD_FX_CHANNEL_VOLUME_SLIDE~%% = 24~%%
CONST __MOD_FX_PANNING_FINE_SLIDE~%% = 25~%%
CONST __MOD_FX_NOTE_RETRIGGER_VOLUME_SLIDE~%% = 26~%%
CONST __MOD_FX_PANBRELLO_WAVEFORM~%% = 27~%%
CONST __MOD_FX_PATTERN_FINE_DELAY~%% = 28~%%
CONST __MOD_FX_SOUND_CONTROL~%% = 29~%%
CONST __MOD_FX_HIGH_OFFSET~%% = 30~%%
CONST __MOD_FX_TEMPO~%% = 31~%%
CONST __MOD_FX_VIBRATO_FINE~%% = 32~%%
CONST __MOD_FX_GLOBAL_VOLUME~%% = 33~%%
CONST __MOD_FX_GLOBAL_VOLUME_SLIDE~%% = 34~%%
CONST __MOD_FX_PANBRELLO~%% = 35~%%
CONST __MOD_FX_MIDI_MACRO~%% = 36~%%

TYPE __NoteType
    note AS _UNSIGNED _BYTE ' contains info on 1 note
    instrument AS _UNSIGNED _BYTE ' instrument number to play
    volume AS _UNSIGNED _BYTE ' volume value. Not used for MODs. 255 = no volume
    effect AS _UNSIGNED _BYTE ' effect number
    operand AS _UNSIGNED _BYTE ' effect parameters
END TYPE

TYPE __InstrumentType
    caption AS STRING ' instrument name or message
    subtype AS _UNSIGNED _BYTE ' what kind of instrument is this? (PCM, FM melody, FM drum, etc.)
    length AS _UNSIGNED LONG ' sample length in bytes
    c2Spd AS _UNSIGNED INTEGER ' sample finetune is converted to c2spd
    volume AS _UNSIGNED _BYTE ' volume: 0 - 64
    loopStart AS _UNSIGNED LONG ' loop start (or just start; usually 0) in bytes
    loopEnd AS _UNSIGNED LONG ' loop end (or just end; usually length) in bytes
    playMode AS LONG ' the playack mode (supported by SoftSynth)
    bytesPerSample AS _UNSIGNED _BYTE ' 1 for 8-bit, 2 for 16-bit, 4 for 32-bit etc. (SoftSynth will convert sounds to 32-bit floating point)
    channels AS _UNSIGNED _BYTE ' number of channels per frame (SoftSynth will flatten sounds to mono)
END TYPE

TYPE __ChannelType
    instrument AS _UNSIGNED _BYTE ' instrument number to be mixed
    subtype AS _UNSIGNED _BYTE ' what kind of channel is this? (PCM, FM melody, FM drum, etc.) TODO: Do we really need this?
    volume AS INTEGER ' channel volume. This is a signed int because we need -ve values & to clip properly
    restart AS _BYTE ' set this to true to retrigger the sample
    note AS _UNSIGNED _BYTE ' last note set in channel
    period AS LONG ' this is the period of the playing sample used by various effects
    lastPeriod AS LONG ' last period set in channel
    startPosition AS _UNSIGNED LONG ' this is starting position of the sample. Usually zero else value from sample offset effect
    patternLoopRow AS INTEGER ' this (signed) is the beginning of the loop in the pattern for effect E6x
    patternLoopRowCounter AS _UNSIGNED _BYTE ' this is a loop counter for effect E6x
    portamentoTo AS LONG ' frequency to porta to value for E3x
    portamentoSpeed AS _UNSIGNED _BYTE ' porta speed for E3x
    vibratoPosition AS _BYTE ' vibrato position in the sine table for E4x (signed)
    vibratoSpeed AS _UNSIGNED _BYTE ' vibrato speed
    vibratoDepth AS _UNSIGNED _BYTE ' vibrato depth
    tremoloPosition AS _BYTE ' tremolo position in the sine table (signed)
    tremoloSpeed AS _UNSIGNED _BYTE ' tremolo speed
    tremoloDepth AS _UNSIGNED _BYTE ' tremolo depth
    waveControl AS _UNSIGNED _BYTE ' waveform type for vibrato and tremolo (4 bits each)
    useGlissando AS _BYTE ' flag to enable glissando (E3x) for subsequent porta-to-note effect
    invertLoopSpeed AS _UNSIGNED _BYTE ' invert loop speed for EFx
    invertLoopDelay AS _UNSIGNED INTEGER ' invert loop delay for EFx
    invertLoopPosition AS _UNSIGNED LONG ' position in the sample where we are for the invert loop effect
    lastVolumeSlide AS _UNSIGNED _BYTE ' last S3M volume slide value
    lastPortamento AS _UNSIGNED _BYTE ' last S3M portamento up or down value
    tremorPosition AS _UNSIGNED _BYTE ' tremor position
    tremorParameters AS _UNSIGNED _BYTE ' tremor parameters
    retriggerVolumeSlide AS _UNSIGNED _BYTE ' last retrigger volume slide
    retriggerTickCount AS _UNSIGNED _BYTE ' last retrigger tick count
END TYPE

TYPE __SongType
    caption AS STRING ' song name
    subtype AS STRING * 4 ' 4 char MOD type - use this to find out what tracker was used
    comment AS STRING ' song comment / message (if any)
    channels AS _UNSIGNED LONG ' number of channels in the song
    instruments AS _UNSIGNED LONG ' number of instruments in the song
    orders AS _UNSIGNED INTEGER ' song length in orders
    rows AS _UNSIGNED _BYTE ' number of rows in each pattern
    endJumpOrder AS _UNSIGNED _BYTE ' this is used for jumping to an order if global looping is on
    patterns AS _UNSIGNED INTEGER ' number of patterns in the song
    orderPosition AS LONG ' the position in the order list. Signed so that we can properly wrap
    patternRow AS INTEGER ' points to the pattern row to be played. This is signed because sometimes we need to set it to -1
    tickPattern AS _UNSIGNED INTEGER ' pattern number for UpdateMODRow() & UpdateMODTick()
    tickPatternRow AS INTEGER ' pattern row number for UpdateMODRow() & UpdateMODTick() (signed)
    isLooping AS _BYTE ' set this to true to loop the song once we reach the max order specified in the song
    isPlaying AS _BYTE ' this is set to true as long as the song is playing
    isPaused AS _BYTE ' set this to true to pause playback
    patternDelay AS _UNSIGNED _BYTE ' number of times to delay pattern for effect EE
    periodTableMax AS _UNSIGNED _BYTE ' we need this for searching through the period table for E3x
    speed AS _UNSIGNED _BYTE ' current song speed
    BPM AS _UNSIGNED _BYTE ' current song BPM
    defaultSpeed AS _UNSIGNED _BYTE ' default song speed
    defaultBPM AS _UNSIGNED _BYTE ' default song BPM
    tick AS _UNSIGNED _BYTE ' current song tick
    tempoTimerValue AS _UNSIGNED LONG ' (mixer_sample_rate * default_bpm) / 50
    framesPerTick AS _UNSIGNED LONG ' this is the amount of sample frames we have to mix per tick based on mixerRate & bpm
    activeChannels AS _UNSIGNED LONG ' just a count of channels that are "active"
    useAmigaLPF AS _BYTE ' use Amiga 12 dB/oct Butterworth low-pass filter
    useST2Vibrato AS _BYTE ' use Scream Tracker 2 vibrato
    useST2Tempo AS _BYTE ' use Scream Tracker 2 tempo behavior
    useAmigaSlides AS _BYTE ' use volume slides similar to Amiga hardware
    useVolumeOptimization AS _BYTE ' turn off looping notes which have a zero volume for more than 2 rows
    useAmigaLimits AS _BYTE ' use Amiga limits (limit periods to confine to 113 <= x <= 856)
    useFilterSFX AS _BYTE ' enable filter / sfx with SB
    useST300VolumeSlides AS _BYTE ' ST3.00 volume slides (automatically enabled if tracker version is <= 0x1300) - if enabled, all volume slides occur every tick
    hasSpecialCustomData AS _BYTE ' special custom data in file (uses "Special" field)
END TYPE

DIM __Song AS __SongType ' tune specific data
DIM __MODPlayer_Synth AS SoftSynthType ' softsynth instance for MOD playback
REDIM __Order(0 TO 0) AS _UNSIGNED INTEGER ' order list
REDIM __Pattern(0 TO 0, 0 TO 0, 0 TO 0) AS __NoteType ' pattern data strored as (pattern, row, channel)
REDIM __Instrument(0 TO 0) AS __InstrumentType ' instrument info array
REDIM __Channel(0 TO 0) AS __ChannelType ' channel info array
REDIM __PeriodTable(0 TO 0) AS _UNSIGNED INTEGER ' Amiga period table
REDIM __SineTable(0 TO 0) AS _UNSIGNED _BYTE ' sine table used for effects
REDIM __InvertLoopSpeedTable(0 TO 0) AS _UNSIGNED _BYTE ' invert loop speed table for EFx

'-----------------------------------------------------------------------------------------------------------------------
' Small test code for debugging the library
'-----------------------------------------------------------------------------------------------------------------------
'$CONSOLE
'$DEBUG
'$ASSERTS:CONSOLE

'DO
'    DIM fileName AS STRING: fileName = _OPENFILEDIALOG$("Open", , "*.mod|*.MOD|*.mtm|*.MTM|*.s3m|*.S3M", "Music Module Files")
'    IF NOT _FILEEXISTS(fileName) THEN EXIT DO

'    DIM AS _BYTE pause, repeat

'    IF MODPlayer_LoadFromDisk(fileName) THEN
'        MODPlayer_Play

'        DIM k AS LONG

'        DO
'            MODPlayer_Update SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT

'            k = _KEYHIT

'            SELECT CASE k
'                CASE 32
'                    pause = NOT pause
'                    MODPlayer_Pause pause
'                    _KEYCLEAR

'                CASE 108, 76
'                    repeat = NOT repeat
'                    MODPlayer_Loop repeat
'                    _KEYCLEAR

'            END SELECT

'            LOCATE 1, 1
'            PRINT USING "Order: ### / ###    Pattern: ### / ###    Row: ## / 63    BPM: ###    Speed: ###"; MODPlayer_GetPosition; MODPlayer_GetOrders - 1; __Order(__Song.orderPosition); __Song.patterns - 1; __Song.patternRow; __Song.BPM; __Song.speed
'            PRINT USING "Buffer Time: #####ms    Loop: ##"; SoftSynth_GetBufferedSoundTime * 1000; repeat;

'            _LIMIT 60
'        LOOP WHILE k <> 27 AND MODPlayer_IsPlaying

'        MODPlayer_Stop
'    END IF
'LOOP

'END
'-----------------------------------------------------------------------------------------------------------------------

''' @brief Initializes pitch tables, vibrato waveforms, and lookup tables.
SUB __MODPlayer_LoadTables
    SHARED __Song AS __SongType
    SHARED __PeriodTable() AS _UNSIGNED INTEGER
    SHARED __SineTable() AS _UNSIGNED _BYTE
    SHARED __InvertLoopSpeedTable() AS _UNSIGNED _BYTE

    ' Load the period table
    RESTORE PeriodTab
    READ __Song.periodTableMax ' read the size
    __Song.periodTableMax = __Song.periodTableMax - 1 ' change to ubound
    REDIM __PeriodTable(0 TO __Song.periodTableMax) AS _UNSIGNED INTEGER ' allocate size elements
    ' Now read size values
    DIM i AS LONG: FOR i = 0 TO __Song.periodTableMax
        READ __PeriodTable(i)
    NEXT

    ' Load the sine table
    RESTORE SineTab
    DIM s AS LONG: READ s
    REDIM __SineTable(0 TO s - 1) AS _UNSIGNED _BYTE
    FOR i = 0 TO s - 1
        READ __SineTable(i)
    NEXT

    ' Load the invert loop table
    RESTORE ILSpdTab
    READ s
    REDIM __InvertLoopSpeedTable(0 TO s - 1) AS _UNSIGNED _BYTE
    FOR i = 0 TO s - 1
        READ __InvertLoopSpeedTable(i)
    NEXT

    ' Amiga period table data for 11 octaves
    PeriodTab:
    DATA 134
    DATA 27392,25856,24384,23040,21696,20480,19328,18240,17216,16256,15360,14496
    DATA 13696,12928,12192,11520,10848,10240,9664,9120,8608,8128,7680,7248
    DATA 6848,6464,6096,5760,5424,5120,4832,4560,4304,4064,3840,3624
    DATA 3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1812
    DATA 1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906
    DATA 856,808,762,720,678,640,604,570,538,508,480,453
    DATA 428,404,381,360,339,320,302,285,269,254,240,226
    DATA 214,202,190,180,170,160,151,143,135,127,120,113
    DATA 107,101,95,90,85,80,75,71,67,63,60,56
    DATA 53,50,47,45,42,40,37,35,33,31,30,28
    DATA 26,25,23,22,21,20,18,17,16,15,15,14
    DATA 0,0
    DATA NaN

    ' Sine table data for tremolo & vibrato
    SineTab:
    DATA 32
    DATA 0,24,49,74,97,120,141,161,180,197,212,224,235,244,250,253
    DATA 255,253,250,244,235,224,212,197,180,161,141,120,97,74,49,24
    DATA NaN

    ' Invert loop speed table data for EFx
    ILSpdTab:
    DATA 16
    DATA 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128
    DATA NaN
END SUB


''' @brief Resets all song properties to default values for a clean load state.
SUB __MODPlayer_InitializeSong
    SHARED __Song AS __SongType

    __Song.caption = _STR_EMPTY
    __Song.subtype = _STR_EMPTY
    __Song.comment = _STR_EMPTY
    __Song.channels = NULL
    __Song.instruments = NULL
    __Song.orders = NULL
    __Song.rows = NULL
    __Song.endJumpOrder = NULL
    __Song.patterns = NULL
    __Song.orderPosition = NULL
    __Song.patternRow = NULL
    __Song.tickPattern = NULL
    __Song.tickPatternRow = NULL
    __Song.isLooping = _FALSE
    __Song.isPlaying = _FALSE
    __Song.isPaused = _FALSE
    __Song.patternDelay = NULL
    __Song.periodTableMax = NULL
    __Song.speed = NULL
    __Song.BPM = NULL
    __Song.defaultSpeed = __SONG_SPEED_DEFAULT ' set this to default MOD speed
    __Song.defaultBPM = __SONG_BPM_DEFAULT ' set this to default MOD BPM
    __Song.tick = NULL
    __Song.tempoTimerValue = NULL
    __Song.framesPerTick = NULL
    __Song.activeChannels = NULL
    __Song.useAmigaLPF = _FALSE
    __Song.useST2Vibrato = _FALSE
    __Song.useST2Tempo = _FALSE
    __Song.useAmigaSlides = _FALSE
    __Song.useVolumeOptimization = _FALSE
    __Song.useAmigaLimits = _FALSE
    __Song.useFilterSFX = _FALSE
    __Song.useST300VolumeSlides = _FALSE
    __Song.hasSpecialCustomData = _FALSE
END SUB



''' @brief Prepares channels, initializes the audio mixer, and begins song playback.
SUB MODPlayer_Play
    SHARED __Song AS __SongType
    SHARED __MODPlayer_Synth AS SoftSynthType

    ' Initialize some important stuff
    __Song.tempoTimerValue = (SoftSynth_GetSampleRate(__MODPlayer_Synth) * __SONG_BPM_DEFAULT) \ 50
    __Song.orderPosition = NULL
    __Song.patternRow = NULL
    __Song.speed = __Song.defaultSpeed
    __Song.tick = __Song.speed
    __Song.isPaused = _FALSE

    ' Set default BPM
    __MODPlayer_SetBPM __Song.defaultBPM

    __Song.isPlaying = _TRUE
END SUB


''' @brief Stops playback, mutes voices, and frees player and synthesizer resources.
SUB MODPlayer_Stop
    SHARED __Song AS __SongType
    SHARED __MODPlayer_Synth AS SoftSynthType

    ' Tell softsynth we are done
    SoftSynth_Finalize __MODPlayer_Synth

    __Song.isPlaying = _FALSE
END SUB


''' @brief Ticks the tracker sequencer and renders audio frames to keep the buffer filled.
''' @param bufferTimeSecs Target duration of audio buffer in seconds (e.g. 0.05).
SUB MODPlayer_Update (bufferTimeSecs AS SINGLE)
    SHARED __Song AS __SongType
    SHARED __Order() AS _UNSIGNED INTEGER
    SHARED __MODPlayer_Synth AS SoftSynthType

    ' Keep feeding the buffer until it is filled to our specified upper limit
    DO WHILE SoftSynth_GetBufferedSoundTime(__MODPlayer_Synth) < bufferTimeSecs
        ' Check conditions for which we should just exit and not process anything
        ' 1. Song is done and we are not looping
        ' 2. Playback was not requested
        ' 3. Playback is paused
        IF _NEGATE __Song.isPlaying _ORELSE __Song.orderPosition >= __Song.orders _ORELSE __Song.isPaused THEN EXIT SUB

        IF __Song.tick >= __Song.speed THEN
            ' Reset song tick
            __Song.tick = 0

            ' Process pattern row if pattern delay is over
            IF __Song.patternDelay = 0 THEN
                ' Skip marker pattern
                WHILE __PATTERN_MARKER = __Order(__Song.orderPosition)
                    __Song.orderPosition = __Song.orderPosition + 1
                    __Song.patternRow = 0

                    ' Check if we need to loop or stop
                    IF __Song.orderPosition >= __Song.orders THEN
                        IF __Song.isLooping THEN
                            __Song.orderPosition = __Song.endJumpOrder
                            __Song.speed = __Song.defaultSpeed
                            __Song.tick = __Song.speed
                        ELSE
                            __Song.isPlaying = _FALSE
                            EXIT SUB ' bail
                        END IF
                    END IF
                WEND

                ' Check for end of song marker
                IF __PATTERN_END = __Order(__Song.orderPosition) THEN
                    IF __Song.isLooping THEN
                        __Song.orderPosition = __Song.endJumpOrder
                        __Song.speed = __Song.defaultSpeed
                        __Song.tick = __Song.speed
                    ELSE
                        __Song.isPlaying = _FALSE
                        EXIT SUB ' bail
                    END IF
                END IF

                ' Save the pattern and row for __MODPlayer_UpdateTick()
                ' The pattern that we are playing is always __Song.tickPattern
                __Song.tickPattern = __Order(__Song.orderPosition)
                __Song.tickPatternRow = __Song.patternRow

                ' Process the row
                __MODPlayer_UpdateRow

                ' Increment the row counter
                ' Note __MODPlayer_UpdateTick() should pickup stuff using tickPattern & tickPatternRow
                ' This is because we are already at a new row not processed by __MODPlayer_UpdateRow()
                __Song.patternRow = __Song.patternRow + 1

                ' Check if we have finished the pattern and then move to the next one
                IF __Song.patternRow >= __Song.rows THEN
                    __Song.orderPosition = __Song.orderPosition + 1
                    __Song.patternRow = 0

                    ' Check if we need to loop or stop
                    IF __Song.orderPosition >= __Song.orders THEN
                        IF __Song.isLooping THEN
                            __Song.orderPosition = __Song.endJumpOrder
                            __Song.speed = __Song.defaultSpeed
                            __Song.tick = __Song.speed
                        ELSE
                            __Song.isPlaying = _FALSE ' we'll not bail here to allow any remaining samples to mix and play below
                        END IF
                    END IF
                END IF
            ELSE
                __Song.patternDelay = __Song.patternDelay - 1
            END IF
        ELSE
            __MODPlayer_UpdateTick
        END IF

        ' Mix the current tick
        SoftSynth_Update __MODPlayer_Synth, __Song.framesPerTick

        ' Increment song tick on each update
        __Song.tick = __Song.tick + 1
    LOOP
END SUB


''' @brief Processes the current pattern row at tick 0 and sets up note triggers and effects.
SUB __MODPlayer_UpdateRow
    SHARED __Song AS __SongType
    SHARED __Pattern() AS __NoteType
    SHARED __Instrument() AS __InstrumentType
    SHARED __Channel() AS __ChannelType
    SHARED __PeriodTable() AS _UNSIGNED INTEGER
    SHARED __MODPlayer_Synth AS SoftSynthType

    DIM AS _UNSIGNED _BYTE nChannel, nNote, nInstrument, nVolume, nEffect, nOperand, nOpX, nOpY
    ' The effect flags below are set to true when a pattern jump effect and pattern break effect are triggered
    DIM AS _BYTE jumpEffectFlag, breakEffectFlag, noFrequency

    ' Set the active channel count to zero
    __Song.activeChannels = 0

    ' Process all channels
    FOR nChannel = 0 TO __Song.channels - 1
        nNote = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).note
        nInstrument = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).instrument
        nVolume = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).volume
        nEffect = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).effect
        nOperand = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).operand
        nOpX = _SHR(nOperand, 4)
        nOpY = nOperand AND &HF
        noFrequency = _FALSE

        ' Set volume. We never play if sample number is zero. Our sample array is 1 based
        ' ONLY RESET VOLUME IF THERE IS A SAMPLE NUMBER
        IF nInstrument THEN
            __Channel(nChannel).instrument = nInstrument - 1
            __Channel(nChannel).startPosition = 0 ' reset sample offset if sample changes

            ' Don't get the volume if delay note, set it when the delay note actually happens
            IF nEffect <> __MOD_FX_EXTENDED _ORELSE nOpX <> __MOD_FX_EXTENDED_NOTE_DELAY THEN
                __Channel(nChannel).volume = __Instrument(__Channel(nChannel).instrument).volume
            END IF
        END IF

        IF nNote < __NOTE_NONE THEN
            __Channel(nChannel).lastPeriod = (8363 * __PeriodTable(nNote)) \ __Instrument(__Channel(nChannel).instrument).c2Spd
            __Channel(nChannel).note = nNote
            __Channel(nChannel).restart = _TRUE
            __Song.activeChannels = nChannel

            ' Retrigger tremolo and vibrato waveforms
            IF __Channel(nChannel).waveControl AND &HF < 4 THEN __Channel(nChannel).vibratoPosition = 0
            IF _SHR(__Channel(nChannel).waveControl, 4) < 4 THEN __Channel(nChannel).tremoloPosition = 0

            ' ONLY RESET FREQUENCY IF THERE IS A NOTE VALUE AND PORTA NOT SET
            IF nEffect <> __MOD_FX_PORTAMENTO _ANDALSO nEffect <> __MOD_FX_PORTAMENTO_VOLUME_SLIDE _ANDALSO nEffect <> __MOD_FX_PORTAMENTO_VOLUME_FINE_SLIDE THEN
                __Channel(nChannel).period = __Channel(nChannel).lastPeriod
            END IF
        ELSE
            __Channel(nChannel).restart = _FALSE
        END IF

        IF nVolume <= __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = nVolume
        IF nNote = __NOTE_KEY_OFF THEN __Channel(nChannel).volume = 0

        ' Process tick 0 effects
        SELECT CASE nEffect
            CASE __MOD_FX_PORTAMENTO
                IF nOperand THEN __Channel(nChannel).portamentoSpeed = nOperand
                __Channel(nChannel).portamentoTo = __Channel(nChannel).lastPeriod
                __Channel(nChannel).restart = _FALSE

            CASE __MOD_FX_PORTAMENTO_VOLUME_SLIDE
                __Channel(nChannel).portamentoTo = __Channel(nChannel).lastPeriod
                __Channel(nChannel).restart = _FALSE

            CASE __MOD_FX_VIBRATO
                IF nOpX THEN __Channel(nChannel).vibratoSpeed = nOpX
                IF nOpY THEN __Channel(nChannel).vibratoDepth = nOpY

            CASE __MOD_FX_TREMOLO
                IF nOpX THEN __Channel(nChannel).tremoloSpeed = nOpX
                IF nOpY THEN __Channel(nChannel).tremoloDepth = nOpY

            CASE __MOD_FX_PANNING_8
                ' Don't care about DMP panning BS. We are doing this Fasttracker style
                SoftSynth_SetVoiceBalance __MODPlayer_Synth, nChannel, (nOperand / 255!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = ((x / 255) * 2) - 1

            CASE __MOD_FX_SAMPLE_OFFSET
                __Channel(nChannel).startPosition = _SHL(nOperand, 8)
                IF __Channel(nChannel).startPosition > __Instrument(__Channel(nChannel).instrument).length THEN
                    __Channel(nChannel).startPosition = __Instrument(__Channel(nChannel).instrument).length
                END IF

            CASE __MOD_FX_POSITION_JUMP
                __Song.orderPosition = nOperand
                IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = __Song.endJumpOrder
                __Song.patternRow = -1 ' This will increment right after & we will start at 0
                jumpEffectFlag = _TRUE

            CASE __MOD_FX_VOLUME
                __Channel(nChannel).volume = nOperand ' Operand can never be -ve cause it is unsigned. So we only clip for max below
                IF __Channel(nChannel).volume > __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = __INSTRUMENT_VOLUME_MAX

            CASE __MOD_FX_PATTERN_BREAK
                __Song.patternRow = (nOpX * 10) + nOpY - 1
                IF __Song.patternRow >= __Song.rows THEN __Song.patternRow = -1
                IF NOT breakEffectFlag _ANDALSO NOT jumpEffectFlag THEN
                    __Song.orderPosition = __Song.orderPosition + 1
                    IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = __Song.endJumpOrder
                END IF
                breakEffectFlag = _TRUE

            CASE __MOD_FX_EXTENDED
                SELECT CASE nOpX
                    CASE __MOD_FX_EXTENDED_FILTER
                        __Song.useAmigaLPF = (nOpY <> _FALSE)

                    CASE __MOD_FX_EXTENDED_PORTAMENTO_FINE_UP
                        __Channel(nChannel).period = __Channel(nChannel).period - _SHL(nOpY, 2)

                    CASE __MOD_FX_EXTENDED_PORTAMENTO_FINE_DOWN
                        __Channel(nChannel).period = __Channel(nChannel).period + _SHL(nOpY, 2)

                    CASE __MOD_FX_EXTENDED_GLISSANDO_CONTROL
                        __Channel(nChannel).useGlissando = (nOpY <> _FALSE)

                    CASE __MOD_FX_EXTENDED_VIBRATO_WAVEFORM
                        __Channel(nChannel).waveControl = __Channel(nChannel).waveControl AND &HF0
                        __Channel(nChannel).waveControl = __Channel(nChannel).waveControl OR nOpY

                    CASE __MOD_FX_EXTENDED_FINETUNE
                        __Instrument(__Channel(nChannel).instrument).c2Spd = __MODPlayer_GetC2Spd(nOpY)

                    CASE __MOD_FX_EXTENDED_PATTERN_LOOP
                        IF nOpY = 0 THEN
                            __Channel(nChannel).patternLoopRow = __Song.tickPatternRow
                        ELSE
                            IF __Channel(nChannel).patternLoopRowCounter = 0 THEN
                                __Channel(nChannel).patternLoopRowCounter = nOpY
                            ELSE
                                __Channel(nChannel).patternLoopRowCounter = __Channel(nChannel).patternLoopRowCounter - 1
                            END IF
                            IF __Channel(nChannel).patternLoopRowCounter THEN
                                __Song.patternRow = __Channel(nChannel).patternLoopRow - 1
                            END IF
                        END IF

                    CASE __MOD_FX_EXTENDED_TREMOLO_WAVEFORM
                        __Channel(nChannel).waveControl = __Channel(nChannel).waveControl AND &HF
                        __Channel(nChannel).waveControl = __Channel(nChannel).waveControl OR _SHL(nOpY, 4)

                    CASE __MOD_FX_EXTENDED_PANNING_4
                        IF nOpY > 15 THEN nOpY = 15
                        SoftSynth_SetVoiceBalance __MODPlayer_Synth, nChannel, (nOpY / 15!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1

                    CASE __MOD_FX_EXTENDED_VOLUME_FINE_SLIDE_UP
                        __Channel(nChannel).volume = __Channel(nChannel).volume + nOpY
                        IF __Channel(nChannel).volume > __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = __INSTRUMENT_VOLUME_MAX

                    CASE __MOD_FX_EXTENDED_VOLUME_FINE_SLIDE_DOWN
                        __Channel(nChannel).volume = __Channel(nChannel).volume - nOpY
                        IF __Channel(nChannel).volume < 0 THEN __Channel(nChannel).volume = 0

                    CASE __MOD_FX_EXTENDED_NOTE_DELAY
                        __Channel(nChannel).restart = _FALSE
                        noFrequency = _TRUE

                    CASE __MOD_FX_EXTENDED_PATTERN_DELAY
                        __Song.patternDelay = nOpY

                    CASE __MOD_FX_EXTENDED_INVERT_LOOP
                        __Channel(nChannel).invertLoopSpeed = nOpY
                END SELECT

            CASE __MOD_FX_SPEED_TEMPO
                IF nOperand < 32 THEN
                    __Song.speed = nOperand
                ELSE
                    __MODPlayer_SetBPM nOperand
                END IF

            CASE __MOD_FX_SPEED
                IF nOperand THEN __Song.speed = nOperand

            CASE __MOD_FX_VOLUME_FINE_SLIDE
                IF nOperand THEN __Channel(nChannel).lastVolumeSlide = nOperand
                ' DFF is classed as a slide up so it gets priority
                IF nOpY = &HF THEN
                    __Channel(nChannel).volume = __Channel(nChannel).volume + nOpX
                ELSEIF nOpX = &HF THEN
                    __Channel(nChannel).volume = __Channel(nChannel).volume - nOpY
                END IF
                ' Perform an extra slide if using old fast vol slides!
                IF __Song.useST300VolumeSlides THEN
                    IF nOpY = 0 THEN __Channel(nChannel).volume = __Channel(nChannel).volume + nOpX
                    IF nOpX = 0 THEN __Channel(nChannel).volume = __Channel(nChannel).volume - nOpY
                END IF
                IF __Channel(nChannel).volume > __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = __INSTRUMENT_VOLUME_MAX
                IF __Channel(nChannel).volume < 0 THEN __Channel(nChannel).volume = 0

            CASE __MOD_FX_PORTAMENTO_EXTRA_FINE_DOWN
                IF nOperand THEN __Channel(nChannel).lastPortamento = nOperand
                IF nOpX = &HF THEN
                    __Channel(nChannel).period = __Channel(nChannel).period + _SHL(nOpY, 2)
                ELSEIF nOpX = &HE THEN
                    __Channel(nChannel).period = __Channel(nChannel).period + nOpY
                END IF

            CASE __MOD_FX_PORTAMENTO_EXTRA_FINE_UP
                IF nOperand THEN __Channel(nChannel).lastPortamento = nOperand
                IF nOpX = &HF THEN
                    __Channel(nChannel).period = __Channel(nChannel).period - _SHL(nOpY, 2)
                ELSEIF nOpX = &HE THEN
                    __Channel(nChannel).period = __Channel(nChannel).period - nOpY
                END IF

            CASE __MOD_FX_TREMOR
                IF nOperand THEN __Channel(nChannel).tremorParameters = (_SHL(nOpX, 4) + 1) + (nOpY + 1)
                __MODPlayer_DoS3MTremor nChannel

            CASE __MOD_FX_VIBRATO_VOLUME_FINE_SLIDE
                IF nOperand THEN __Channel(nChannel).lastVolumeSlide = nOperand
                noFrequency = _TRUE

            CASE __MOD_FX_PORTAMENTO_VOLUME_FINE_SLIDE
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_CHANNEL_VOLUME
                IF nOperand <= __S3M_GLOBAL_VOLUME_MAX THEN __Channel(nChannel).volume = nOperand

            CASE __MOD_FX_CHANNEL_VOLUME_SLIDE
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_PANNING_FINE_SLIDE
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_NOTE_RETRIGGER_VOLUME_SLIDE
                IF nOperand THEN
                    __Channel(nChannel).retriggerVolumeSlide = nOpX
                    __Channel(nChannel).retriggerTickCount = nOpY
                END IF

            CASE __MOD_FX_PANBRELLO_WAVEFORM
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_PATTERN_FINE_DELAY
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_SOUND_CONTROL
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_HIGH_OFFSET
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_TEMPO
                IF nOperand THEN __MODPlayer_SetBPM nOperand

            CASE __MOD_FX_VIBRATO_FINE
                IF nOpX THEN __Channel(nChannel).vibratoSpeed = nOpX
                IF nOpY THEN __Channel(nChannel).vibratoDepth = nOpY

            CASE __MOD_FX_GLOBAL_VOLUME
                ' ST3 ignores out-of-range values
                IF nOperand <= __S3M_GLOBAL_VOLUME_MAX THEN SoftSynth_SetGlobalVolume __MODPlayer_Synth, nOperand / __S3M_GLOBAL_VOLUME_MAX

            CASE __MOD_FX_GLOBAL_VOLUME_SLIDE
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_PANBRELLO
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_MIDI_MACRO
                ERROR _ERR_FEATURE_UNAVAILABLE

        END SELECT

        __MODPlayer_DoInvertLoop nChannel ' called every row

        IF NOT noFrequency THEN
            IF nEffect <> __MOD_FX_TREMOLO THEN
                SoftSynth_SetVoiceVolume __MODPlayer_Synth, nChannel, __Channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
            END IF
            IF __Channel(nChannel).period > 0 THEN
                SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)
            END IF
        END IF
    NEXT

    ' Now play all samples that needs to be played
    FOR nChannel = 0 TO __Song.activeChannels
        IF __Channel(nChannel).restart THEN
            SoftSynth_PlayVoice __MODPlayer_Synth, nChannel, __Channel(nChannel).instrument, SoftSynth_ConvertBytesToFrames(__Channel(nChannel).startPosition, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), __Instrument(__Channel(nChannel).instrument).playMode, SoftSynth_ConvertBytesToFrames(__Instrument(__Channel(nChannel).instrument).loopStart, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), SoftSynth_ConvertBytesToFrames(__Instrument(__Channel(nChannel).instrument).loopEnd, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels)
        END IF
    NEXT
END SUB


''' @brief Processes tick-based modulation effects (vibrato, tremolo, slides, retrigger) on ticks > 0.
SUB __MODPlayer_UpdateTick
    SHARED __Song AS __SongType
    SHARED __Pattern() AS __NoteType
    SHARED __Instrument() AS __InstrumentType
    SHARED __Channel() AS __ChannelType
    SHARED __PeriodTable() AS _UNSIGNED INTEGER
    SHARED __MODPlayer_Synth AS SoftSynthType

    DIM AS _UNSIGNED _BYTE nChannel, nVolume, nEffect, nOperand, nOpX, nOpY

    ' Process all channels
    FOR nChannel = 0 TO __Song.channels - 1
        ' Only process if we have a period set
        IF __Channel(nChannel).period > 0 THEN
            ' We are not processing a new row but tick 1+ effects
            ' So we pick these using tickPattern and tickPatternRow
            nVolume = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).volume
            nEffect = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).effect
            nOperand = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).operand
            nOpX = _SHR(nOperand, 4)
            nOpY = nOperand AND &HF

            __MODPlayer_DoInvertLoop nChannel ' called every tick

            SELECT CASE nEffect
                CASE __MOD_FX_ARPEGGIO
                    IF nOperand THEN
                        SELECT CASE __Song.tick MOD 3
                            CASE 0
                                SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)
                            CASE 1
                                SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpX))
                            CASE 2
                                SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpY))
                        END SELECT
                    END IF

                CASE __MOD_FX_PORTAMENTO_UP
                    __Channel(nChannel).period = __Channel(nChannel).period - _SHL(nOperand, 2)
                    IF __Channel(nChannel).period < 1 THEN __Channel(nChannel).period = 1 ' clamp to avoid division by zero
                    SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)

                CASE __MOD_FX_PORTAMENTO_DOWN
                    __Channel(nChannel).period = __Channel(nChannel).period + _SHL(nOperand, 2)
                    SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)

                CASE __MOD_FX_PORTAMENTO
                    __MODPlayer_DoPortamento nChannel

                CASE __MOD_FX_VIBRATO
                    __MODPlayer_DoVibrato nChannel, _TRUE ' true here means not fine vibrato

                CASE __MOD_FX_PORTAMENTO_VOLUME_SLIDE
                    __MODPlayer_DoPortamento nChannel
                    __MODPlayer_DoVolumeSlide nChannel, nOpX, nOpY, _TRUE ' true here means not fine volume slide

                CASE __MOD_FX_VIBRATO_VOLUME_SLIDE
                    __MODPlayer_DoVibrato nChannel, _TRUE ' true here means not fine vibrato
                    __MODPlayer_DoVolumeSlide nChannel, nOpX, nOpY, _TRUE ' true here means not fine volume slide

                CASE __MOD_FX_TREMOLO
                    __MODPlayer_DoTremolo nChannel

                CASE __MOD_FX_VOLUME_SLIDE
                    __MODPlayer_DoVolumeSlide nChannel, nOpX, nOpY, _TRUE ' true here means not fine volume slide

                CASE __MOD_FX_EXTENDED
                    SELECT CASE nOpX
                        CASE __MOD_FX_EXTENDED_NOTE_RETRIGGER
                            IF nOpY <> 0 THEN
                                IF __Song.tick MOD nOpY = 0 THEN
                                    SoftSynth_PlayVoice __MODPlayer_Synth, nChannel, __Channel(nChannel).instrument, SoftSynth_ConvertBytesToFrames(__Channel(nChannel).startPosition, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), __Instrument(__Channel(nChannel).instrument).playMode, SoftSynth_ConvertBytesToFrames(__Instrument(__Channel(nChannel).instrument).loopStart, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), SoftSynth_ConvertBytesToFrames(__Instrument(__Channel(nChannel).instrument).loopEnd, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels)
                                END IF
                            END IF

                        CASE __MOD_FX_EXTENDED_NOTE_CUT
                            IF __Song.tick = nOpY THEN
                                __Channel(nChannel).volume = 0
                                SoftSynth_SetVoiceVolume __MODPlayer_Synth, nChannel, __Channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                            END IF

                        CASE __MOD_FX_EXTENDED_NOTE_DELAY
                            IF __Song.tick = nOpY THEN
                                __Channel(nChannel).volume = __Instrument(__Channel(nChannel).instrument).volume
                                IF nVolume <= __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = nVolume
                                SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)
                                SoftSynth_SetVoiceVolume __MODPlayer_Synth, nChannel, __Channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                                SoftSynth_PlayVoice __MODPlayer_Synth, nChannel, __Channel(nChannel).instrument, SoftSynth_ConvertBytesToFrames(__Channel(nChannel).startPosition, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), __Instrument(__Channel(nChannel).instrument).playMode, SoftSynth_ConvertBytesToFrames(__Instrument(__Channel(nChannel).instrument).loopStart, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), SoftSynth_ConvertBytesToFrames(__Instrument(__Channel(nChannel).instrument).loopEnd, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels)
                            END IF
                    END SELECT

                CASE __MOD_FX_VOLUME_FINE_SLIDE
                    __MODPlayer_DoVolumeSlide nChannel, _SHR(__Channel(nChannel).lastVolumeSlide, 4), __Channel(nChannel).lastVolumeSlide AND &HF, _FALSE ' false here means fine volume slide

                CASE __MOD_FX_PORTAMENTO_EXTRA_FINE_DOWN
                    IF __Channel(nChannel).lastPortamento < &HE0 THEN __Channel(nChannel).period = __Channel(nChannel).period + _SHL(__Channel(nChannel).lastPortamento, 2)
                    SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)

                CASE __MOD_FX_PORTAMENTO_EXTRA_FINE_UP
                    IF __Channel(nChannel).lastPortamento < &HE0 THEN __Channel(nChannel).period = __Channel(nChannel).period - _SHL(__Channel(nChannel).lastPortamento, 2)
                    SoftSynth_SetVoiceFrequency __MODPlayer_Synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)

                CASE __MOD_FX_TREMOR
                    __MODPlayer_DoS3MTremor nChannel

                CASE __MOD_FX_VIBRATO_VOLUME_FINE_SLIDE
                    __MODPlayer_DoVibrato nChannel, _TRUE ' true here means not fine vibrato
                    __MODPlayer_DoVolumeSlide nChannel, _SHR(__Channel(nChannel).lastVolumeSlide, 4), __Channel(nChannel).lastVolumeSlide AND &HF, _FALSE ' false here means fine volume slide

                CASE __MOD_FX_PORTAMENTO_VOLUME_FINE_SLIDE
                    ERROR _ERR_FEATURE_UNAVAILABLE

                CASE __MOD_FX_NOTE_RETRIGGER_VOLUME_SLIDE
                    IF __Channel(nChannel).retriggerTickCount THEN
                        IF __Song.tick MOD __Channel(nChannel).retriggerTickCount = 0 THEN
                            IF __Channel(nChannel).retriggerVolumeSlide THEN
                                'Parameter  Effect              Parameter   Effect
                                '0          No volume change    8           No volume change
                                '1          Volume - 1          9           Volume + 1
                                '2          Volume - 2          A           Volume + 2
                                '3          Volume - 4          B           Volume + 4
                                '4          Volume - 8          C           Volume + 8
                                '5          Volume - 16         D           Volume + 16
                                '6          Volume x 2/3        E           Volume x 1.5
                                '7          Volume x 1/2        F           Volume x 2
                                SELECT CASE __Channel(nChannel).retriggerVolumeSlide
                                    CASE &H1
                                        __Channel(nChannel).volume = __Channel(nChannel).volume - 1

                                    CASE &H2
                                        __Channel(nChannel).volume = __Channel(nChannel).volume - 2

                                    CASE &H3
                                        __Channel(nChannel).volume = __Channel(nChannel).volume - 4

                                    CASE &H4
                                        __Channel(nChannel).volume = __Channel(nChannel).volume - 8

                                    CASE &H5
                                        __Channel(nChannel).volume = __Channel(nChannel).volume - 16

                                    CASE &H6
                                        __Channel(nChannel).volume = __Channel(nChannel).volume * (2! / 3!)

                                    CASE &H7
                                        __Channel(nChannel).volume = _SHR(__Channel(nChannel).volume, 1)

                                    CASE &H9
                                        __Channel(nChannel).volume = __Channel(nChannel).volume + 1

                                    CASE &HA
                                        __Channel(nChannel).volume = __Channel(nChannel).volume + 2

                                    CASE &HB
                                        __Channel(nChannel).volume = __Channel(nChannel).volume + 4

                                    CASE &HC
                                        __Channel(nChannel).volume = __Channel(nChannel).volume + 8

                                    CASE &HD
                                        __Channel(nChannel).volume = __Channel(nChannel).volume + 16

                                    CASE &HE
                                        __Channel(nChannel).volume = __Channel(nChannel).volume * (3! / 2!)

                                    CASE &HF
                                        __Channel(nChannel).volume = _SHL(__Channel(nChannel).volume, 1)

                                END SELECT

                                __Channel(nChannel).volume = _CLAMP(__Channel(nChannel).volume, 0, __INSTRUMENT_VOLUME_MAX)

                                SoftSynth_SetVoiceVolume __MODPlayer_Synth, nChannel, __Channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                            END IF

                            SoftSynth_PlayVoice __MODPlayer_Synth, nChannel, __Channel(nChannel).instrument, SoftSynth_ConvertBytesToFrames(__Channel(nChannel).startPosition, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), __Instrument(__Channel(nChannel).instrument).playMode, SoftSynth_ConvertBytesToFrames(__Instrument(__Channel(nChannel).instrument).loopStart, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), SoftSynth_ConvertBytesToFrames(__Instrument(__Channel(nChannel).instrument).loopEnd, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels)
                        END IF
                    END IF

                CASE __MOD_FX_VIBRATO_FINE
                    __MODPlayer_DoVibrato nChannel, _FALSE ' false here means fine vibrato

            END SELECT
        END IF
    NEXT
END SUB


''' @brief Sets sequencer tempo (Beats Per Minute) and recalculates timing parameters.
''' @param nBPM Tempo in BPM (32 to 255).
SUB __MODPlayer_SetBPM (nBPM AS _UNSIGNED _BYTE)
    $CHECKING:OFF
    SHARED __Song AS __SongType

    __Song.BPM = nBPM

    ' Calculate the number of samples we have to mix per tick
    __Song.framesPerTick = __Song.tempoTimerValue \ nBPM
    $CHECKING:ON
END SUB


''' @brief Finds the closest period table entry to a given period value.
''' @param target Target period value.
''' @return The closest matched period.
FUNCTION __MODPlayer_GetClosestPeriod& (target AS LONG)
    SHARED __Song AS __SongType
    SHARED __Channel() AS __ChannelType
    SHARED __PeriodTable() AS _UNSIGNED INTEGER

    DIM AS LONG startPos, endPos, midPos, leftVal, rightVal

    IF target > 27392 THEN
        __MODPlayer_GetClosestPeriod = target
        EXIT FUNCTION
    ELSEIF target < 14 THEN
        __MODPlayer_GetClosestPeriod = target
        EXIT FUNCTION
    END IF

    startPos = 0
    endPos = __Song.periodTableMax
    WHILE startPos + 1 < endPos
        midPos = startPos + (endPos - startPos) \ 2
        IF __PeriodTable(midPos) <= target THEN
            endPos = midPos
        ELSE
            startPos = midPos
        END IF
    WEND

    rightVal = ABS(__PeriodTable(startPos) - target)
    leftVal = ABS(__PeriodTable(endPos) - target)

    IF leftVal <= rightVal THEN
        __MODPlayer_GetClosestPeriod = __PeriodTable(endPos)
    ELSE
        __MODPlayer_GetClosestPeriod = __PeriodTable(startPos)
    END IF
END FUNCTION


''' @brief Performs tone portamento calculation towards destination note period for a channel.
''' @param chan Channel index (0-based).
SUB __MODPlayer_DoPortamento (chan AS _UNSIGNED _BYTE)
    SHARED __Channel() AS __ChannelType
    SHARED __MODPlayer_Synth AS SoftSynthType

    ' Slide up/down and clamp to destination
    IF __Channel(chan).period < __Channel(chan).portamentoTo THEN
        __Channel(chan).period = __Channel(chan).period + _SHL(__Channel(chan).portamentoSpeed, 2)
        IF __Channel(chan).period > __Channel(chan).portamentoTo THEN
            __Channel(chan).period = __Channel(chan).portamentoTo
        END IF
    ELSEIF __Channel(chan).period > __Channel(chan).portamentoTo THEN
        __Channel(chan).period = __Channel(chan).period - _SHL(__Channel(chan).portamentoSpeed, 2)
        IF __Channel(chan).period < __Channel(chan).portamentoTo THEN
            __Channel(chan).period = __Channel(chan).portamentoTo
        END IF
    END IF

    IF __Channel(chan).useGlissando THEN
        SoftSynth_SetVoiceFrequency __MODPlayer_Synth, chan, __MODPlayer_GetFrequencyFromPeriod(__MODPlayer_GetClosestPeriod(__Channel(chan).period))
    ELSE
        SoftSynth_SetVoiceFrequency __MODPlayer_Synth, chan, __MODPlayer_GetFrequencyFromPeriod(__Channel(chan).period)
    END IF
END SUB


''' @brief Performs volume slide up or down calculation on a channel.
''' @param chan Channel index (0-based).
''' @param x Upward slide amount nibble.
''' @param y Downward slide amount nibble.
''' @param isNotFine _TRUE for regular volume slide, _FALSE for fine volume slide.
SUB __MODPlayer_DoVolumeSlide (chan AS _UNSIGNED _BYTE, x AS _UNSIGNED _BYTE, y AS _UNSIGNED _BYTE, isNotFine AS _BYTE)
    SHARED __Channel() AS __ChannelType
    SHARED __MODPlayer_Synth AS SoftSynthType

    IF isNotFine THEN
        __Channel(chan).volume = __Channel(chan).volume + x - y
    ELSE
        IF y = 0 THEN __Channel(chan).volume = __Channel(chan).volume + x
        IF x = 0 THEN __Channel(chan).volume = __Channel(chan).volume - y
    END IF

    IF __Channel(chan).volume > __INSTRUMENT_VOLUME_MAX THEN __Channel(chan).volume = __INSTRUMENT_VOLUME_MAX
    IF __Channel(chan).volume < 0 THEN __Channel(chan).volume = 0

    SoftSynth_SetVoiceVolume __MODPlayer_Synth, chan, __Channel(chan).volume / __INSTRUMENT_VOLUME_MAX
END SUB


''' @brief Processes Scream Tracker 3 tremor effect on a channel.
''' @param chan Channel index (0-based).
SUB __MODPlayer_DoS3MTremor (chan AS _UNSIGNED _BYTE)
    SHARED __Channel() AS __ChannelType
    SHARED __MODPlayer_Synth AS SoftSynthType

    __Channel(chan).tremorPosition = __Channel(chan).tremorPosition MOD (_SHR(__Channel(chan).tremorParameters, 4) + (__Channel(chan).tremorParameters AND &HF))

    IF __Channel(chan).tremorPosition < _SHR(__Channel(chan).tremorParameters, 4) THEN
        SoftSynth_SetVoiceVolume __MODPlayer_Synth, chan, __Channel(chan).volume / __INSTRUMENT_VOLUME_MAX
    ELSE
        SoftSynth_SetVoiceVolume __MODPlayer_Synth, chan, 0
    END IF

    __Channel(chan).tremorPosition = __Channel(chan).tremorPosition + 1
END SUB


''' @brief Calculates and applies pitch vibrato oscillation on a channel.
''' @param chan Channel index (0-based).
''' @param isNotFine _TRUE for standard vibrato, _FALSE for fine vibrato.
SUB __MODPlayer_DoVibrato (chan AS _UNSIGNED _BYTE, isNotFine AS _BYTE)
    SHARED __Channel() AS __ChannelType
    SHARED __SineTable() AS _UNSIGNED _BYTE
    SHARED __MODPlayer_Synth AS SoftSynthType

    DIM delta AS _UNSIGNED INTEGER
    DIM temp AS _UNSIGNED _BYTE

    temp = __Channel(chan).vibratoPosition AND 31

    SELECT CASE __Channel(chan).waveControl AND 3
        CASE 0 ' Sine
            delta = __SineTable(temp)

        CASE 1 ' Saw down
            temp = _SHL(temp, 3)
            IF __Channel(chan).vibratoPosition < 0 THEN temp = 255 - temp
            delta = temp

        CASE 2 ' Square
            delta = 255

        CASE 3 ' Random
            delta = RND * 255!
    END SELECT

    delta = _SHR(delta * __Channel(chan).vibratoDepth, 7)
    IF isNotFine THEN delta = _SHL(delta, 2) ' make vibrato 4 times bigger

    IF __Channel(chan).vibratoPosition >= 0 THEN
        SoftSynth_SetVoiceFrequency __MODPlayer_Synth, chan, __MODPlayer_GetFrequencyFromPeriod(__Channel(chan).period + delta)
    ELSE
        SoftSynth_SetVoiceFrequency __MODPlayer_Synth, chan, __MODPlayer_GetFrequencyFromPeriod(__Channel(chan).period - delta)
    END IF

    __Channel(chan).vibratoPosition = __Channel(chan).vibratoPosition + __Channel(chan).vibratoSpeed
    IF __Channel(chan).vibratoPosition > 31 THEN
        __Channel(chan).vibratoPosition = __Channel(chan).vibratoPosition - 64
    END IF
END SUB


''' @brief Calculates and applies volume tremolo oscillation on a channel.
''' @param chan Channel index (0-based).
SUB __MODPlayer_DoTremolo (chan AS _UNSIGNED _BYTE)
    SHARED __Channel() AS __ChannelType
    SHARED __SineTable() AS _UNSIGNED _BYTE
    SHARED __MODPlayer_Synth AS SoftSynthType

    DIM delta AS _UNSIGNED INTEGER
    DIM temp AS _UNSIGNED _BYTE

    temp = __Channel(chan).tremoloPosition AND 31

    SELECT CASE _SHR(__Channel(chan).waveControl, 4) AND 3
        CASE 0 ' Sine
            delta = __SineTable(temp)

        CASE 1 ' Saw down
            temp = _SHL(temp, 3)
            IF __Channel(chan).tremoloPosition < 0 THEN temp = 255 - temp
            delta = temp

        CASE 2 ' Square
            delta = 255

        CASE 3 ' Random
            delta = RND * 255!
    END SELECT

    delta = _SHR(delta * __Channel(chan).tremoloDepth, 6)

    IF __Channel(chan).tremoloPosition >= 0 THEN
        IF __Channel(chan).volume + delta > __INSTRUMENT_VOLUME_MAX THEN delta = __INSTRUMENT_VOLUME_MAX - __Channel(chan).volume
        SoftSynth_SetVoiceVolume __MODPlayer_Synth, chan, (__Channel(chan).volume + delta) / __INSTRUMENT_VOLUME_MAX
    ELSE
        IF __Channel(chan).volume - delta < 0 THEN delta = __Channel(chan).volume
        SoftSynth_SetVoiceVolume __MODPlayer_Synth, chan, (__Channel(chan).volume - delta) / __INSTRUMENT_VOLUME_MAX
    END IF

    __Channel(chan).tremoloPosition = __Channel(chan).tremoloPosition + __Channel(chan).tremoloSpeed
    IF __Channel(chan).tremoloPosition > 31 THEN __Channel(chan).tremoloPosition = __Channel(chan).tremoloPosition - 64
END SUB


''' @brief Processes ProTracker EFx funk / invert loop effect on a channel.
''' @param chan Channel index (0-based).
SUB __MODPlayer_DoInvertLoop (chan AS _UNSIGNED _BYTE)
    SHARED __Channel() AS __ChannelType
    SHARED __Instrument() AS __InstrumentType
    SHARED __InvertLoopSpeedTable() AS _UNSIGNED _BYTE
    SHARED __MODPlayer_Synth AS SoftSynthType

    __Channel(chan).invertLoopDelay = __Channel(chan).invertLoopDelay + __InvertLoopSpeedTable(__Channel(chan).invertLoopSpeed)

    DIM sampleNumber AS _UNSIGNED _BYTE: sampleNumber = __Channel(chan).instrument ' cache the sample number case we'll use this often below

    IF __Channel(chan).invertLoopDelay >= 128 _ANDALSO SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP = __Instrument(sampleNumber).playMode THEN
        __Channel(chan).invertLoopDelay = 0 ' reset delay
        IF __Channel(chan).invertLoopPosition < __Instrument(sampleNumber).loopStart THEN
            __Channel(chan).invertLoopPosition = __Instrument(sampleNumber).loopStart
        END IF
        __Channel(chan).invertLoopPosition = __Channel(chan).invertLoopPosition + 1 ' increment position by 1
        IF __Channel(chan).invertLoopPosition >= __Instrument(sampleNumber).loopEnd THEN
            __Channel(chan).invertLoopPosition = __Instrument(sampleNumber).loopStart
        END IF

        ' Yeah I know, this is weird. QB64 NOT is bitwise and not logical
        DIM p AS _UNSIGNED LONG: p = SoftSynth_ConvertBytesToFrames(__Channel(chan).invertLoopPosition, __Instrument(sampleNumber).bytesPerSample, __Instrument(sampleNumber).channels)
        SoftSynth_PokeSoundFrameByte __MODPlayer_Synth, sampleNumber, p, NOT SoftSynth_PeekSoundFrameByte(__MODPlayer_Synth, sampleNumber, p)
    END IF
END SUB


''' @brief Calculates audio playback frequency in Hertz from an Amiga period value.
''' @param period Amiga period value.
''' @return Frequency in Hertz.
FUNCTION __MODPlayer_GetFrequencyFromPeriod~& (period AS LONG)
    $CHECKING:OFF
    __MODPlayer_GetFrequencyFromPeriod = 14317056 \ period
    $CHECKING:ON
END FUNCTION


''' @brief Calculates middle-C playback speed in Hertz for a ProTracker finetune nibble.
''' @param ft Signed finetune nibble (0-15).
''' @return C2 playback speed in Hertz.
FUNCTION __MODPlayer_GetC2Spd~% (ft AS _UNSIGNED _BYTE)
    $CHECKING:OFF
    SELECT CASE ft
        CASE 0
            __MODPlayer_GetC2Spd = 8363
        CASE 1
            __MODPlayer_GetC2Spd = 8413
        CASE 2
            __MODPlayer_GetC2Spd = 8463
        CASE 3
            __MODPlayer_GetC2Spd = 8529
        CASE 4
            __MODPlayer_GetC2Spd = 8581
        CASE 5
            __MODPlayer_GetC2Spd = 8651
        CASE 6
            __MODPlayer_GetC2Spd = 8723
        CASE 7
            __MODPlayer_GetC2Spd = 8757
        CASE 8
            __MODPlayer_GetC2Spd = 7895
        CASE 9
            __MODPlayer_GetC2Spd = 7941
        CASE 10
            __MODPlayer_GetC2Spd = 7985
        CASE 11
            __MODPlayer_GetC2Spd = 8046
        CASE 12
            __MODPlayer_GetC2Spd = 8107
        CASE 13
            __MODPlayer_GetC2Spd = 8169
        CASE 14
            __MODPlayer_GetC2Spd = 8232
        CASE 15
            __MODPlayer_GetC2Spd = 8280
        CASE ELSE
            __MODPlayer_GetC2Spd = 8363
    END SELECT
    $CHECKING:ON
END FUNCTION


''' @brief Gets the title name of the currently loaded tune.
''' @return Tune name string.
FUNCTION MODPlayer_GetName$
    $CHECKING:OFF
    SHARED __Song AS __SongType

    MODPlayer_GetName = __Song.caption
    $CHECKING:ON
END FUNCTION


''' @brief Gets the format descriptor or magic tag of the currently loaded tune.
''' @return Format string (e.g. "M.K.", "SCRM", "MTM1").
FUNCTION MODPlayer_GetType$
    $CHECKING:OFF
    SHARED __Song AS __SongType

    MODPlayer_GetType = __Song.subtype
    $CHECKING:ON
END FUNCTION


''' @brief Checks whether a song is actively playing.
''' @return _TRUE if playing, _FALSE otherwise.
FUNCTION MODPlayer_IsPlaying%%
    $CHECKING:OFF
    SHARED __Song AS __SongType

    MODPlayer_IsPlaying = __Song.isPlaying
    $CHECKING:ON
END FUNCTION


''' @brief Pauses or unpauses song playback.
''' @param state _TRUE to pause playback, _FALSE to resume.
SUB MODPlayer_Pause (state AS _BYTE)
    SHARED __Song AS __SongType

    __Song.isPaused = state
END SUB


''' @brief Checks whether song playback is currently paused.
''' @return _TRUE if paused, _FALSE otherwise.
FUNCTION MODPlayer_IsPaused%%
    $CHECKING:OFF
    SHARED __Song AS __SongType

    MODPlayer_IsPaused = __Song.isPaused
    $CHECKING:ON
END FUNCTION


''' @brief Sets continuous song looping mode.
''' @param state _TRUE to loop continuously, _FALSE to stop at song end.
SUB MODPlayer_Loop (state AS _BYTE)
    SHARED __Song AS __SongType

    __Song.isLooping = state
END SUB


''' @brief Checks whether continuous song looping is enabled.
''' @return _TRUE if looping is enabled, _FALSE otherwise.
FUNCTION MODPlayer_IsLooping%%
    $CHECKING:OFF
    SHARED __Song AS __SongType

    MODPlayer_IsLooping = __Song.isLooping
    $CHECKING:ON
END FUNCTION


''' @brief Advances playback position to the next pattern order, wrapping at song end if looping.
SUB MODPlayer_GoToNextPosition
    SHARED __Song AS __SongType

    IF __Song.isLooping THEN ' if we are looping
        __Song.orderPosition = __Song.orderPosition + 1 ' move to the next order
        IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = 0 ' wrap to first order if we have reached the end
        __Song.patternRow = 0 ' reset row position
    ELSEIF __Song.orderPosition < __Song.orders - 1 THEN ' else only if have not reached the last order
        __Song.orderPosition = __Song.orderPosition + 1
        __Song.patternRow = 0 ' reset row position
    END IF
END SUB


''' @brief Rewinds playback position to the previous pattern order, wrapping if looping.
SUB MODPlayer_GoToPreviousPosition
    SHARED __Song AS __SongType

    IF __Song.isLooping THEN ' if we are looping
        __Song.orderPosition = __Song.orderPosition - 1 ' move to the previous order
        IF __Song.orderPosition < 0 THEN __Song.orderPosition = __Song.orders - 1 ' wrap to the last order if we have crossed the beginning
        __Song.patternRow = 0 ' reset row position
    ELSEIF __Song.orderPosition > 0 THEN ' else only if have not reached the first order
        __Song.orderPosition = __Song.orderPosition - 1 ' move to the previous order
        __Song.patternRow = 0 ' reset row position
    END IF
END SUB


''' @brief Sets the current pattern order playback position.
''' @param position Target order position index (0-based).
SUB MODPlayer_SetPosition (position AS _UNSIGNED INTEGER)
    SHARED __Song AS __SongType

    IF position < __Song.orders THEN
        __Song.orderPosition = position
        __Song.patternRow = 0
    END IF
END SUB


''' @brief Gets the current pattern order playback position index.
''' @return Current order position index (0-based).
FUNCTION MODPlayer_GetPosition&
    $CHECKING:OFF
    SHARED __Song AS __SongType

    MODPlayer_GetPosition = __Song.orderPosition
    $CHECKING:ON
END FUNCTION


''' @brief Gets the total number of pattern orders in the loaded tune.
''' @return Total order count.
FUNCTION MODPlayer_GetOrders~%
    $CHECKING:OFF
    SHARED __Song AS __SongType

    MODPlayer_GetOrders = __Song.orders
    $CHECKING:ON
END FUNCTION

'$INCLUDE:'S3MLoader.bi'
'$INCLUDE:'MTMLoader.bi'
'$INCLUDE:'MODLoader.bi'

''' @brief Automatically detects module format and loads a tune from a memory buffer.
''' @param buffer Binary string containing the module file contents.
''' @return _TRUE if the module was recognized and loaded, _FALSE otherwise.
FUNCTION MODPlayer_LoadFromMemory%% (buffer AS STRING)
    IF LEN(buffer) = 0 THEN EXIT FUNCTION

    IF S3MLoader_LoadFromMemory(buffer) THEN
        MODPlayer_LoadFromMemory = _TRUE
        EXIT FUNCTION
    ELSEIF MTMLoader_LoadFromMemory(buffer) THEN
        MODPlayer_LoadFromMemory = _TRUE
        EXIT FUNCTION
    ELSEIF MODLoader_LoadFromMemory(buffer) THEN
        MODPlayer_LoadFromMemory = _TRUE
        EXIT FUNCTION
    END IF
END FUNCTION

''' @brief Loads a module file from local disk or URL into memory and initializes playback.
''' @param fileName File path or URL to load.
''' @return _TRUE if the module was loaded, _FALSE otherwise.
FUNCTION MODPlayer_LoadFromDisk%% (fileName AS STRING)
    ' TODO: Startrekker .mod + .nt support. Startrekker module instrument files must have the same name as the module itself, followed by either ".nt" or ".as".
    IF NOT _FILEEXISTS(fileName) THEN EXIT FUNCTION
    MODPlayer_LoadFromDisk = MODPlayer_LoadFromMemory(File_Load(fileName))
END FUNCTION
