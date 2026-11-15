'-----------------------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

$UNSTABLE:TYPEFIELDS

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

TYPE __MODPlayerNote
    note AS _UNSIGNED _BYTE ' contains info on 1 note
    instrument AS _UNSIGNED _BYTE ' instrument number to play
    volume AS _UNSIGNED _BYTE ' volume value. Not used for MODs. 255 = no volume
    effect AS _UNSIGNED _BYTE ' effect number
    operand AS _UNSIGNED _BYTE ' effect parameters
END TYPE

TYPE __MODPlayerPattern
    rows AS _UNSIGNED INTEGER ' number of rows in this pattern (typically 64, but can be 1 to 256 for XM, etc.)
    note(0 TO 0, 0 TO 0) _DYNAMIC AS __MODPlayerNote ' note matrix: (0 TO rows - 1, 0 TO channels - 1)
END TYPE

TYPE __MODPlayerInstrument
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

TYPE __MODPlayerChannel
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

TYPE __MODPlayerSong
    caption AS STRING ' song name
    subtype AS STRING * 4 ' 4 char MOD type - use this to find out what tracker was used
    comment AS STRING ' song comment / message (if any)
    channels AS _UNSIGNED LONG ' number of channels in the song
    instruments AS _UNSIGNED LONG ' number of instruments in the song
    orders AS _UNSIGNED INTEGER ' song length in orders
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

TYPE MODPlayer
    song AS __MODPlayerSong
    synth AS SoftSynth
    order(0 TO 0) _DYNAMIC AS _UNSIGNED INTEGER
    pattern(0 TO 0) _DYNAMIC AS __MODPlayerPattern
    instrument(0 TO 0) _DYNAMIC AS __MODPlayerInstrument
    channel(0 TO 0) _DYNAMIC AS __MODPlayerChannel
    initialized AS _BYTE
END TYPE

REDIM __MODPlayer_PeriodTable(0 TO 0) AS _UNSIGNED INTEGER ' Amiga period table
REDIM __MODPlayer_SineTable(0 TO 0) AS _UNSIGNED _BYTE ' sine table used for effects
REDIM __MODPlayer_InvertLoopSpeedTable(0 TO 0) AS _UNSIGNED _BYTE ' invert loop speed table for EFx
DIM __MODPlayer_tablesInitialized AS _BYTE

SUB __MODPlayer_LoadTables
    SHARED __MODPlayer_PeriodTable() AS _UNSIGNED INTEGER
    SHARED __MODPlayer_SineTable() AS _UNSIGNED _BYTE
    SHARED __MODPlayer_InvertLoopSpeedTable() AS _UNSIGNED _BYTE
    SHARED __MODPlayer_tablesInitialized AS _BYTE

    IF __MODPlayer_tablesInitialized THEN EXIT SUB

    ' Load the period table
    RESTORE PeriodTab
    DIM periodCount AS LONG: READ periodCount
    REDIM __MODPlayer_PeriodTable(0 TO periodCount - 1) AS _UNSIGNED INTEGER ' allocate size elements
    ' Now read size values
    DIM i AS LONG: FOR i = 0 TO periodCount - 1
        READ __MODPlayer_PeriodTable(i)
    NEXT

    ' Load the sine table
    RESTORE SineTab
    DIM s AS LONG: READ s
    REDIM __MODPlayer_SineTable(0 TO s - 1) AS _UNSIGNED _BYTE
    FOR i = 0 TO s - 1
        READ __MODPlayer_SineTable(i)
    NEXT

    ' Load the invert loop table
    RESTORE ILSpdTab
    READ s
    REDIM __MODPlayer_InvertLoopSpeedTable(0 TO s - 1) AS _UNSIGNED _BYTE
    FOR i = 0 TO s - 1
        READ __MODPlayer_InvertLoopSpeedTable(i)
    NEXT

    __MODPlayer_tablesInitialized = _TRUE
    EXIT SUB

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
''' @brief Checks whether a player instance is initialized.
''' @param player The MOD player instance.
''' @return _TRUE if initialized, _FALSE otherwise.
FUNCTION MODPlayer_IsInitialized%% (player AS MODPlayer)
    MODPlayer_IsInitialized = player.initialized
END FUNCTION


''' @brief Initializes a MOD player instance and its software synthesizer.
''' @param player The MOD player instance.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION MODPlayer_Initialize%% (player AS MODPlayer)
    IF player.initialized THEN
        MODPlayer_Initialize = _TRUE
        EXIT FUNCTION
    END IF

    __MODPlayer_LoadTables

    IF NOT SoftSynth_Initialize(player.synth) THEN EXIT FUNCTION

    __MODPlayer_InitializeSong player

    player.initialized = _TRUE
    MODPlayer_Initialize = _TRUE
END FUNCTION


''' @brief Finalizes a MOD player instance, stopping playback and freeing resources.
''' @param player The MOD player instance.
SUB MODPlayer_Finalize (player AS MODPlayer)
    IF player.initialized THEN
        MODPlayer_Stop player
        SoftSynth_Finalize player.synth
        REDIM player.order(0 TO 0) AS _UNSIGNED INTEGER
        DIM p AS LONG
        FOR p = 0 TO UBOUND(player.pattern)
            REDIM player.pattern(p).note(0 TO 0, 0 TO 0) AS __MODPlayerNote
            player.pattern(p).rows = 0
        NEXT
        REDIM player.pattern(0 TO 0) AS __MODPlayerPattern
        REDIM player.instrument(0 TO 0) AS __MODPlayerInstrument
        REDIM player.channel(0 TO 0) AS __MODPlayerChannel
        __MODPlayer_InitializeSong player
        player.initialized = _FALSE
    END IF
END SUB


''' @brief Resets all song properties to default values for a clean load state.
SUB __MODPlayer_InitializeSong (player AS MODPlayer)
    player.song.caption = _STR_EMPTY
    player.song.subtype = _STR_EMPTY
    player.song.comment = _STR_EMPTY
    player.song.channels = NULL
    player.song.instruments = NULL
    player.song.orders = NULL
    player.song.endJumpOrder = NULL
    player.song.patterns = NULL
    player.song.orderPosition = NULL
    player.song.patternRow = NULL
    player.song.tickPattern = NULL
    player.song.tickPatternRow = NULL
    player.song.isLooping = _FALSE
    player.song.isPlaying = _FALSE
    player.song.isPaused = _FALSE
    player.song.patternDelay = NULL
    player.song.speed = NULL
    player.song.BPM = NULL
    player.song.defaultSpeed = __SONG_SPEED_DEFAULT ' set this to default MOD speed
    player.song.defaultBPM = __SONG_BPM_DEFAULT ' set this to default MOD BPM
    player.song.tick = NULL
    player.song.tempoTimerValue = NULL
    player.song.framesPerTick = NULL
    player.song.activeChannels = NULL
    player.song.useAmigaLPF = _FALSE
    player.song.useST2Vibrato = _FALSE
    player.song.useST2Tempo = _FALSE
    player.song.useAmigaSlides = _FALSE
    player.song.useVolumeOptimization = _FALSE
    player.song.useAmigaLimits = _FALSE
    player.song.useFilterSFX = _FALSE
    player.song.useST300VolumeSlides = _FALSE
    player.song.hasSpecialCustomData = _FALSE
END SUB



''' @brief Prepares channels, initializes the audio mixer, and begins song playback.
SUB MODPlayer_Play (player AS MODPlayer)
    IF NOT player.initialized THEN EXIT SUB

    ' Initialize some important stuff
    player.song.tempoTimerValue = (SoftSynth_GetSampleRate(player.synth) * __SONG_BPM_DEFAULT) \ 50
    player.song.orderPosition = NULL
    player.song.patternRow = NULL
    player.song.speed = player.song.defaultSpeed
    player.song.tick = player.song.speed
    player.song.isPaused = _FALSE

    ' Set default BPM
    __MODPlayer_SetBPM player, player.song.defaultBPM

    player.song.isPlaying = _TRUE
END SUB


''' @brief Stops playback, mutes voices, and frees player and synthesizer resources.
SUB MODPlayer_Stop (player AS MODPlayer)
    IF NOT player.initialized THEN EXIT SUB

    SoftSynth_Finalize player.synth

    player.song.isPlaying = _FALSE
END SUB


''' @brief Ticks the tracker sequencer and renders audio frames to keep the buffer filled.
''' @param bufferTimeSecs Target duration of audio buffer in seconds (e.g. 0.05).
SUB MODPlayer_Update (player AS MODPlayer, bufferTimeSecs AS SINGLE)
    IF NOT player.initialized THEN EXIT SUB

    ' Keep feeding the buffer until it is filled to our specified upper limit
    DO WHILE SoftSynth_GetBufferedSoundTime(player.synth) < bufferTimeSecs
        ' Check conditions for which we should just exit and not process anything
        ' 1. Song is done and we are not looping
        ' 2. Playback was not requested
        ' 3. Playback is paused
        IF _NEGATE player.song.isPlaying _ORELSE player.song.orderPosition >= player.song.orders _ORELSE player.song.isPaused THEN EXIT SUB

        IF player.song.tick >= player.song.speed THEN
            ' Reset song tick
            player.song.tick = 0

            ' Process pattern row if pattern delay is over
            IF player.song.patternDelay = 0 THEN
                ' Skip marker pattern
                WHILE __PATTERN_MARKER = player.order(player.song.orderPosition)
                    player.song.orderPosition = player.song.orderPosition + 1
                    player.song.patternRow = 0

                    ' Check if we need to loop or stop
                    IF player.song.orderPosition >= player.song.orders THEN
                        IF player.song.isLooping THEN
                            player.song.orderPosition = player.song.endJumpOrder
                            player.song.speed = player.song.defaultSpeed
                            player.song.tick = player.song.speed
                        ELSE
                            player.song.isPlaying = _FALSE
                            EXIT SUB ' bail
                        END IF
                    END IF
                WEND

                ' Check for end of song marker
                IF __PATTERN_END = player.order(player.song.orderPosition) THEN
                    IF player.song.isLooping THEN
                        player.song.orderPosition = player.song.endJumpOrder
                        player.song.speed = player.song.defaultSpeed
                        player.song.tick = player.song.speed
                    ELSE
                        player.song.isPlaying = _FALSE
                        EXIT SUB ' bail
                    END IF
                END IF

                ' Save the pattern and row for __MODPlayer_UpdateTick()
                ' The pattern that we are playing is always player.song.tickPattern
                player.song.tickPattern = player.order(player.song.orderPosition)
                player.song.tickPatternRow = player.song.patternRow

                ' Process the row
                __MODPlayer_UpdateRow player

                ' Increment the row counter
                ' Note __MODPlayer_UpdateTick() should pickup stuff using tickPattern & tickPatternRow
                ' This is because we are already at a new row not processed by __MODPlayer_UpdateRow()
                player.song.patternRow = player.song.patternRow + 1

                ' Check if we have finished the pattern and then move to the next one
                DIM currentPatternRows AS _UNSIGNED INTEGER
                IF player.song.tickPattern < player.song.patterns THEN
                    currentPatternRows = player.pattern(player.song.tickPattern).rows
                END IF
                IF currentPatternRows = 0 THEN currentPatternRows = __MOD_S3M_ROWS ' fallback safe default

                IF player.song.patternRow >= currentPatternRows THEN
                    player.song.orderPosition = player.song.orderPosition + 1
                    player.song.patternRow = 0

                    ' Check if we need to loop or stop
                    IF player.song.orderPosition >= player.song.orders THEN
                        IF player.song.isLooping THEN
                            player.song.orderPosition = player.song.endJumpOrder
                            player.song.speed = player.song.defaultSpeed
                            player.song.tick = player.song.speed
                        ELSE
                            player.song.isPlaying = _FALSE ' we'll not bail here to allow any remaining samples to mix and play below
                        END IF
                    END IF
                END IF
            ELSE
                player.song.patternDelay = player.song.patternDelay - 1
            END IF
        ELSE
            __MODPlayer_UpdateTick player
        END IF

        ' Mix the current tick
        SoftSynth_Update player.synth, player.song.framesPerTick

        ' Increment song tick on each update
        player.song.tick = player.song.tick + 1
    LOOP
END SUB


''' @brief Processes the current pattern row at tick 0 and sets up note triggers and effects.
SUB __MODPlayer_UpdateRow (player AS MODPlayer)
SHARED __MODPlayer_PeriodTable() AS _UNSIGNED INTEGER
    DIM AS _UNSIGNED _BYTE nChannel, nNote, nInstrument, nVolume, nEffect, nOperand, nOpX, nOpY
    ' The effect flags below are set to true when a pattern jump effect and pattern break effect are triggered
    DIM AS _BYTE jumpEffectFlag, breakEffectFlag, noFrequency

    ' Set the active channel count to zero
    player.song.activeChannels = 0

    ' Process all channels
    FOR nChannel = 0 TO player.song.channels - 1
        nNote = player.pattern(player.song.tickPattern).note(player.song.tickPatternRow, nChannel).note
        nInstrument = player.pattern(player.song.tickPattern).note(player.song.tickPatternRow, nChannel).instrument
        nVolume = player.pattern(player.song.tickPattern).note(player.song.tickPatternRow, nChannel).volume
        nEffect = player.pattern(player.song.tickPattern).note(player.song.tickPatternRow, nChannel).effect
        nOperand = player.pattern(player.song.tickPattern).note(player.song.tickPatternRow, nChannel).operand
        nOpX = _SHR(nOperand, 4)
        nOpY = nOperand AND &HF
        noFrequency = _FALSE

        ' Set volume. We never play if sample number is zero. Our sample array is 1 based
        ' ONLY RESET VOLUME IF THERE IS A SAMPLE NUMBER
        IF nInstrument THEN
            player.channel(nChannel).instrument = nInstrument - 1
            player.channel(nChannel).startPosition = 0 ' reset sample offset if sample changes

            ' Don't get the volume if delay note, set it when the delay note actually happens
            IF nEffect <> __MOD_FX_EXTENDED _ORELSE nOpX <> __MOD_FX_EXTENDED_NOTE_DELAY THEN
                player.channel(nChannel).volume = player.instrument(player.channel(nChannel).instrument).volume
            END IF
        END IF

        IF nNote < __NOTE_NONE THEN
            player.channel(nChannel).lastPeriod = (8363 * __MODPlayer_PeriodTable(nNote)) \ player.instrument(player.channel(nChannel).instrument).c2Spd
            player.channel(nChannel).note = nNote
            player.channel(nChannel).restart = _TRUE
            player.song.activeChannels = nChannel

            ' Retrigger tremolo and vibrato waveforms
            IF player.channel(nChannel).waveControl AND &HF < 4 THEN player.channel(nChannel).vibratoPosition = 0
            IF _SHR(player.channel(nChannel).waveControl, 4) < 4 THEN player.channel(nChannel).tremoloPosition = 0

            ' ONLY RESET FREQUENCY IF THERE IS A NOTE VALUE AND PORTA NOT SET
            IF nEffect <> __MOD_FX_PORTAMENTO _ANDALSO nEffect <> __MOD_FX_PORTAMENTO_VOLUME_SLIDE _ANDALSO nEffect <> __MOD_FX_PORTAMENTO_VOLUME_FINE_SLIDE THEN
                player.channel(nChannel).period = player.channel(nChannel).lastPeriod
            END IF
        ELSE
            player.channel(nChannel).restart = _FALSE
        END IF

        IF nVolume <= __INSTRUMENT_VOLUME_MAX THEN player.channel(nChannel).volume = nVolume
        IF nNote = __NOTE_KEY_OFF THEN player.channel(nChannel).volume = 0

        ' Process tick 0 effects
        SELECT CASE nEffect
            CASE __MOD_FX_PORTAMENTO
                IF nOperand THEN player.channel(nChannel).portamentoSpeed = nOperand
                player.channel(nChannel).portamentoTo = player.channel(nChannel).lastPeriod
                player.channel(nChannel).restart = _FALSE

            CASE __MOD_FX_PORTAMENTO_VOLUME_SLIDE
                player.channel(nChannel).portamentoTo = player.channel(nChannel).lastPeriod
                player.channel(nChannel).restart = _FALSE

            CASE __MOD_FX_VIBRATO
                IF nOpX THEN player.channel(nChannel).vibratoSpeed = nOpX
                IF nOpY THEN player.channel(nChannel).vibratoDepth = nOpY

            CASE __MOD_FX_TREMOLO
                IF nOpX THEN player.channel(nChannel).tremoloSpeed = nOpX
                IF nOpY THEN player.channel(nChannel).tremoloDepth = nOpY

            CASE __MOD_FX_PANNING_8
                ' Don't care about DMP panning BS. We are doing this Fasttracker style
                SoftSynth_SetVoiceBalance player.synth, nChannel, (nOperand / 255!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = ((x / 255) * 2) - 1

            CASE __MOD_FX_SAMPLE_OFFSET
                player.channel(nChannel).startPosition = _SHL(nOperand, 8)
                IF player.channel(nChannel).startPosition > player.instrument(player.channel(nChannel).instrument).length THEN
                    player.channel(nChannel).startPosition = player.instrument(player.channel(nChannel).instrument).length
                END IF

            CASE __MOD_FX_POSITION_JUMP
                player.song.orderPosition = nOperand
                IF player.song.orderPosition >= player.song.orders THEN player.song.orderPosition = player.song.endJumpOrder
                player.song.patternRow = -1 ' This will increment right after & we will start at 0
                jumpEffectFlag = _TRUE

            CASE __MOD_FX_VOLUME
                player.channel(nChannel).volume = nOperand ' Operand can never be -ve cause it is unsigned. So we only clip for max below
                IF player.channel(nChannel).volume > __INSTRUMENT_VOLUME_MAX THEN player.channel(nChannel).volume = __INSTRUMENT_VOLUME_MAX

            CASE __MOD_FX_PATTERN_BREAK
                player.song.patternRow = (nOpX * 10) + nOpY - 1
                IF NOT breakEffectFlag _ANDALSO NOT jumpEffectFlag THEN
                    player.song.orderPosition = player.song.orderPosition + 1
                    IF player.song.orderPosition >= player.song.orders THEN player.song.orderPosition = player.song.endJumpOrder
                END IF
                IF player.song.orderPosition < player.song.orders THEN
                    DIM targetPat AS LONG: targetPat = player.order(player.song.orderPosition)
                    IF targetPat < player.song.patterns THEN
                        IF player.song.patternRow >= player.pattern(targetPat).rows THEN player.song.patternRow = -1
                    END IF
                END IF
                breakEffectFlag = _TRUE

            CASE __MOD_FX_EXTENDED
                SELECT CASE nOpX
                    CASE __MOD_FX_EXTENDED_FILTER
                        player.song.useAmigaLPF = (nOpY <> _FALSE)

                    CASE __MOD_FX_EXTENDED_PORTAMENTO_FINE_UP
                        player.channel(nChannel).period = player.channel(nChannel).period - _SHL(nOpY, 2)

                    CASE __MOD_FX_EXTENDED_PORTAMENTO_FINE_DOWN
                        player.channel(nChannel).period = player.channel(nChannel).period + _SHL(nOpY, 2)

                    CASE __MOD_FX_EXTENDED_GLISSANDO_CONTROL
                        player.channel(nChannel).useGlissando = (nOpY <> _FALSE)

                    CASE __MOD_FX_EXTENDED_VIBRATO_WAVEFORM
                        player.channel(nChannel).waveControl = player.channel(nChannel).waveControl AND &HF0
                        player.channel(nChannel).waveControl = player.channel(nChannel).waveControl OR nOpY

                    CASE __MOD_FX_EXTENDED_FINETUNE
                        player.instrument(player.channel(nChannel).instrument).c2Spd = __MODPlayer_GetC2Spd(nOpY)

                    CASE __MOD_FX_EXTENDED_PATTERN_LOOP
                        IF nOpY = 0 THEN
                            player.channel(nChannel).patternLoopRow = player.song.tickPatternRow
                        ELSE
                            IF player.channel(nChannel).patternLoopRowCounter = 0 THEN
                                player.channel(nChannel).patternLoopRowCounter = nOpY
                            ELSE
                                player.channel(nChannel).patternLoopRowCounter = player.channel(nChannel).patternLoopRowCounter - 1
                            END IF
                            IF player.channel(nChannel).patternLoopRowCounter THEN
                                player.song.patternRow = player.channel(nChannel).patternLoopRow - 1
                            END IF
                        END IF

                    CASE __MOD_FX_EXTENDED_TREMOLO_WAVEFORM
                        player.channel(nChannel).waveControl = player.channel(nChannel).waveControl AND &HF
                        player.channel(nChannel).waveControl = player.channel(nChannel).waveControl OR _SHL(nOpY, 4)

                    CASE __MOD_FX_EXTENDED_PANNING_4
                        IF nOpY > 15 THEN nOpY = 15
                        SoftSynth_SetVoiceBalance player.synth, nChannel, (nOpY / 15!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1

                    CASE __MOD_FX_EXTENDED_VOLUME_FINE_SLIDE_UP
                        player.channel(nChannel).volume = player.channel(nChannel).volume + nOpY
                        IF player.channel(nChannel).volume > __INSTRUMENT_VOLUME_MAX THEN player.channel(nChannel).volume = __INSTRUMENT_VOLUME_MAX

                    CASE __MOD_FX_EXTENDED_VOLUME_FINE_SLIDE_DOWN
                        player.channel(nChannel).volume = player.channel(nChannel).volume - nOpY
                        IF player.channel(nChannel).volume < 0 THEN player.channel(nChannel).volume = 0

                    CASE __MOD_FX_EXTENDED_NOTE_DELAY
                        player.channel(nChannel).restart = _FALSE
                        noFrequency = _TRUE

                    CASE __MOD_FX_EXTENDED_PATTERN_DELAY
                        player.song.patternDelay = nOpY

                    CASE __MOD_FX_EXTENDED_INVERT_LOOP
                        player.channel(nChannel).invertLoopSpeed = nOpY
                END SELECT

            CASE __MOD_FX_SPEED_TEMPO
                IF nOperand < 32 THEN
                    player.song.speed = nOperand
                ELSE
                    __MODPlayer_SetBPM player, nOperand
                END IF

            CASE __MOD_FX_SPEED
                IF nOperand THEN player.song.speed = nOperand

            CASE __MOD_FX_VOLUME_FINE_SLIDE
                IF nOperand THEN player.channel(nChannel).lastVolumeSlide = nOperand
                ' DFF is classed as a slide up so it gets priority
                IF nOpY = &HF THEN
                    player.channel(nChannel).volume = player.channel(nChannel).volume + nOpX
                ELSEIF nOpX = &HF THEN
                    player.channel(nChannel).volume = player.channel(nChannel).volume - nOpY
                END IF
                ' Perform an extra slide if using old fast vol slides!
                IF player.song.useST300VolumeSlides THEN
                    IF nOpY = 0 THEN player.channel(nChannel).volume = player.channel(nChannel).volume + nOpX
                    IF nOpX = 0 THEN player.channel(nChannel).volume = player.channel(nChannel).volume - nOpY
                END IF
                IF player.channel(nChannel).volume > __INSTRUMENT_VOLUME_MAX THEN player.channel(nChannel).volume = __INSTRUMENT_VOLUME_MAX
                IF player.channel(nChannel).volume < 0 THEN player.channel(nChannel).volume = 0

            CASE __MOD_FX_PORTAMENTO_EXTRA_FINE_DOWN
                IF nOperand THEN player.channel(nChannel).lastPortamento = nOperand
                IF nOpX = &HF THEN
                    player.channel(nChannel).period = player.channel(nChannel).period + _SHL(nOpY, 2)
                ELSEIF nOpX = &HE THEN
                    player.channel(nChannel).period = player.channel(nChannel).period + nOpY
                END IF

            CASE __MOD_FX_PORTAMENTO_EXTRA_FINE_UP
                IF nOperand THEN player.channel(nChannel).lastPortamento = nOperand
                IF nOpX = &HF THEN
                    player.channel(nChannel).period = player.channel(nChannel).period - _SHL(nOpY, 2)
                ELSEIF nOpX = &HE THEN
                    player.channel(nChannel).period = player.channel(nChannel).period - nOpY
                END IF

            CASE __MOD_FX_TREMOR
                IF nOperand THEN player.channel(nChannel).tremorParameters = (_SHL(nOpX, 4) + 1) + (nOpY + 1)
                __MODPlayer_DoS3MTremor player, nChannel

            CASE __MOD_FX_VIBRATO_VOLUME_FINE_SLIDE
                IF nOperand THEN player.channel(nChannel).lastVolumeSlide = nOperand
                noFrequency = _TRUE

            CASE __MOD_FX_PORTAMENTO_VOLUME_FINE_SLIDE
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_CHANNEL_VOLUME
                IF nOperand <= __S3M_GLOBAL_VOLUME_MAX THEN player.channel(nChannel).volume = nOperand

            CASE __MOD_FX_CHANNEL_VOLUME_SLIDE
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_PANNING_FINE_SLIDE
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_NOTE_RETRIGGER_VOLUME_SLIDE
                IF nOperand THEN
                    player.channel(nChannel).retriggerVolumeSlide = nOpX
                    player.channel(nChannel).retriggerTickCount = nOpY
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
                IF nOperand THEN __MODPlayer_SetBPM player, nOperand

            CASE __MOD_FX_VIBRATO_FINE
                IF nOpX THEN player.channel(nChannel).vibratoSpeed = nOpX
                IF nOpY THEN player.channel(nChannel).vibratoDepth = nOpY

            CASE __MOD_FX_GLOBAL_VOLUME
                ' ST3 ignores out-of-range values
                IF nOperand <= __S3M_GLOBAL_VOLUME_MAX THEN SoftSynth_SetGlobalVolume player.synth, nOperand / __S3M_GLOBAL_VOLUME_MAX

            CASE __MOD_FX_GLOBAL_VOLUME_SLIDE
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_PANBRELLO
                ERROR _ERR_FEATURE_UNAVAILABLE

            CASE __MOD_FX_MIDI_MACRO
                ERROR _ERR_FEATURE_UNAVAILABLE

        END SELECT

        __MODPlayer_DoInvertLoop player, nChannel ' called every row

        IF NOT noFrequency THEN
            IF nEffect <> __MOD_FX_TREMOLO THEN
                SoftSynth_SetVoiceVolume player.synth, nChannel, player.channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
            END IF
            IF player.channel(nChannel).period > 0 THEN
                SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(player.channel(nChannel).period)
            END IF
        END IF
    NEXT

    ' Now play all samples that needs to be played
    FOR nChannel = 0 TO player.song.activeChannels
        IF player.channel(nChannel).restart THEN
            SoftSynth_PlayVoice player.synth, nChannel, player.channel(nChannel).instrument, SoftSynth_ConvertBytesToFrames(player.channel(nChannel).startPosition, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels), player.instrument(player.channel(nChannel).instrument).playMode, SoftSynth_ConvertBytesToFrames(player.instrument(player.channel(nChannel).instrument).loopStart, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels), SoftSynth_ConvertBytesToFrames(player.instrument(player.channel(nChannel).instrument).loopEnd, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels)
        END IF
    NEXT
END SUB


''' @brief Processes tick-based modulation effects (vibrato, tremolo, slides, retrigger) on ticks > 0.
SUB __MODPlayer_UpdateTick (player AS MODPlayer)
SHARED __MODPlayer_PeriodTable() AS _UNSIGNED INTEGER
    DIM AS _UNSIGNED _BYTE nChannel, nVolume, nEffect, nOperand, nOpX, nOpY

    ' Process all channels
    FOR nChannel = 0 TO player.song.channels - 1
        ' Only process if we have a period set
        IF player.channel(nChannel).period > 0 THEN
            ' We are not processing a new row but tick 1+ effects
            ' So we pick these using tickPattern and tickPatternRow
            nVolume = player.pattern(player.song.tickPattern).note(player.song.tickPatternRow, nChannel).volume
            nEffect = player.pattern(player.song.tickPattern).note(player.song.tickPatternRow, nChannel).effect
            nOperand = player.pattern(player.song.tickPattern).note(player.song.tickPatternRow, nChannel).operand
            nOpX = _SHR(nOperand, 4)
            nOpY = nOperand AND &HF

            __MODPlayer_DoInvertLoop player, nChannel ' called every tick

            SELECT CASE nEffect
                CASE __MOD_FX_ARPEGGIO
                    IF nOperand THEN
                        SELECT CASE player.song.tick MOD 3
                            CASE 0
                                SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(player.channel(nChannel).period)
                            CASE 1
                                SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__MODPlayer_PeriodTable(player.channel(nChannel).note + nOpX))
                            CASE 2
                                SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(__MODPlayer_PeriodTable(player.channel(nChannel).note + nOpY))
                        END SELECT
                    END IF

                CASE __MOD_FX_PORTAMENTO_UP
                    player.channel(nChannel).period = player.channel(nChannel).period - _SHL(nOperand, 2)
                    IF player.channel(nChannel).period < 1 THEN player.channel(nChannel).period = 1 ' clamp to avoid division by zero
                    SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(player.channel(nChannel).period)

                CASE __MOD_FX_PORTAMENTO_DOWN
                    player.channel(nChannel).period = player.channel(nChannel).period + _SHL(nOperand, 2)
                    SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(player.channel(nChannel).period)

                CASE __MOD_FX_PORTAMENTO
                    __MODPlayer_DoPortamento player, nChannel

                CASE __MOD_FX_VIBRATO
                    __MODPlayer_DoVibrato player, nChannel, _TRUE ' true here means not fine vibrato

                CASE __MOD_FX_PORTAMENTO_VOLUME_SLIDE
                    __MODPlayer_DoPortamento player, nChannel
                    __MODPlayer_DoVolumeSlide player, nChannel, nOpX, nOpY, _TRUE ' true here means not fine volume slide

                CASE __MOD_FX_VIBRATO_VOLUME_SLIDE
                    __MODPlayer_DoVibrato player, nChannel, _TRUE ' true here means not fine vibrato
                    __MODPlayer_DoVolumeSlide player, nChannel, nOpX, nOpY, _TRUE ' true here means not fine volume slide

                CASE __MOD_FX_TREMOLO
                    __MODPlayer_DoTremolo player, nChannel

                CASE __MOD_FX_VOLUME_SLIDE
                    __MODPlayer_DoVolumeSlide player, nChannel, nOpX, nOpY, _TRUE ' true here means not fine volume slide

                CASE __MOD_FX_EXTENDED
                    SELECT CASE nOpX
                        CASE __MOD_FX_EXTENDED_NOTE_RETRIGGER
                            IF nOpY <> 0 THEN
                                IF player.song.tick MOD nOpY = 0 THEN
                                    SoftSynth_PlayVoice player.synth, nChannel, player.channel(nChannel).instrument, SoftSynth_ConvertBytesToFrames(player.channel(nChannel).startPosition, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels), player.instrument(player.channel(nChannel).instrument).playMode, SoftSynth_ConvertBytesToFrames(player.instrument(player.channel(nChannel).instrument).loopStart, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels), SoftSynth_ConvertBytesToFrames(player.instrument(player.channel(nChannel).instrument).loopEnd, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels)
                                END IF
                            END IF

                        CASE __MOD_FX_EXTENDED_NOTE_CUT
                            IF player.song.tick = nOpY THEN
                                player.channel(nChannel).volume = 0
                                SoftSynth_SetVoiceVolume player.synth, nChannel, player.channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                            END IF

                        CASE __MOD_FX_EXTENDED_NOTE_DELAY
                            IF player.song.tick = nOpY THEN
                                player.channel(nChannel).volume = player.instrument(player.channel(nChannel).instrument).volume
                                IF nVolume <= __INSTRUMENT_VOLUME_MAX THEN player.channel(nChannel).volume = nVolume
                                SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(player.channel(nChannel).period)
                                SoftSynth_SetVoiceVolume player.synth, nChannel, player.channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                                SoftSynth_PlayVoice player.synth, nChannel, player.channel(nChannel).instrument, SoftSynth_ConvertBytesToFrames(player.channel(nChannel).startPosition, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels), player.instrument(player.channel(nChannel).instrument).playMode, SoftSynth_ConvertBytesToFrames(player.instrument(player.channel(nChannel).instrument).loopStart, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels), SoftSynth_ConvertBytesToFrames(player.instrument(player.channel(nChannel).instrument).loopEnd, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels)
                            END IF
                    END SELECT

                CASE __MOD_FX_VOLUME_FINE_SLIDE
                    __MODPlayer_DoVolumeSlide player, nChannel, _SHR(player.channel(nChannel).lastVolumeSlide, 4), player.channel(nChannel).lastVolumeSlide AND &HF, _FALSE ' false here means fine volume slide

                CASE __MOD_FX_PORTAMENTO_EXTRA_FINE_DOWN
                    IF player.channel(nChannel).lastPortamento < &HE0 THEN player.channel(nChannel).period = player.channel(nChannel).period + _SHL(player.channel(nChannel).lastPortamento, 2)
                    SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(player.channel(nChannel).period)

                CASE __MOD_FX_PORTAMENTO_EXTRA_FINE_UP
                    IF player.channel(nChannel).lastPortamento < &HE0 THEN player.channel(nChannel).period = player.channel(nChannel).period - _SHL(player.channel(nChannel).lastPortamento, 2)
                    SoftSynth_SetVoiceFrequency player.synth, nChannel, __MODPlayer_GetFrequencyFromPeriod(player.channel(nChannel).period)

                CASE __MOD_FX_TREMOR
                    __MODPlayer_DoS3MTremor player, nChannel

                CASE __MOD_FX_VIBRATO_VOLUME_FINE_SLIDE
                    __MODPlayer_DoVibrato player, nChannel, _TRUE ' true here means not fine vibrato
                    __MODPlayer_DoVolumeSlide player, nChannel, _SHR(player.channel(nChannel).lastVolumeSlide, 4), player.channel(nChannel).lastVolumeSlide AND &HF, _FALSE ' false here means fine volume slide

                CASE __MOD_FX_PORTAMENTO_VOLUME_FINE_SLIDE
                    ERROR _ERR_FEATURE_UNAVAILABLE

                CASE __MOD_FX_NOTE_RETRIGGER_VOLUME_SLIDE
                    IF player.channel(nChannel).retriggerTickCount THEN
                        IF player.song.tick MOD player.channel(nChannel).retriggerTickCount = 0 THEN
                            IF player.channel(nChannel).retriggerVolumeSlide THEN
                                'Parameter  Effect              Parameter   Effect
                                '0          No volume change    8           No volume change
                                '1          Volume - 1          9           Volume + 1
                                '2          Volume - 2          A           Volume + 2
                                '3          Volume - 4          B           Volume + 4
                                '4          Volume - 8          C           Volume + 8
                                '5          Volume - 16         D           Volume + 16
                                '6          Volume x 2/3        E           Volume x 1.5
                                '7          Volume x 1/2        F           Volume x 2
                                SELECT CASE player.channel(nChannel).retriggerVolumeSlide
                                    CASE &H1
                                        player.channel(nChannel).volume = player.channel(nChannel).volume - 1

                                    CASE &H2
                                        player.channel(nChannel).volume = player.channel(nChannel).volume - 2

                                    CASE &H3
                                        player.channel(nChannel).volume = player.channel(nChannel).volume - 4

                                    CASE &H4
                                        player.channel(nChannel).volume = player.channel(nChannel).volume - 8

                                    CASE &H5
                                        player.channel(nChannel).volume = player.channel(nChannel).volume - 16

                                    CASE &H6
                                        player.channel(nChannel).volume = player.channel(nChannel).volume * (2! / 3!)

                                    CASE &H7
                                        player.channel(nChannel).volume = _SHR(player.channel(nChannel).volume, 1)

                                    CASE &H9
                                        player.channel(nChannel).volume = player.channel(nChannel).volume + 1

                                    CASE &HA
                                        player.channel(nChannel).volume = player.channel(nChannel).volume + 2

                                    CASE &HB
                                        player.channel(nChannel).volume = player.channel(nChannel).volume + 4

                                    CASE &HC
                                        player.channel(nChannel).volume = player.channel(nChannel).volume + 8

                                    CASE &HD
                                        player.channel(nChannel).volume = player.channel(nChannel).volume + 16

                                    CASE &HE
                                        player.channel(nChannel).volume = player.channel(nChannel).volume * (3! / 2!)

                                    CASE &HF
                                        player.channel(nChannel).volume = _SHL(player.channel(nChannel).volume, 1)

                                END SELECT

                                player.channel(nChannel).volume = _CLAMP(player.channel(nChannel).volume, 0, __INSTRUMENT_VOLUME_MAX)

                                SoftSynth_SetVoiceVolume player.synth, nChannel, player.channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                            END IF

                            SoftSynth_PlayVoice player.synth, nChannel, player.channel(nChannel).instrument, SoftSynth_ConvertBytesToFrames(player.channel(nChannel).startPosition, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels), player.instrument(player.channel(nChannel).instrument).playMode, SoftSynth_ConvertBytesToFrames(player.instrument(player.channel(nChannel).instrument).loopStart, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels), SoftSynth_ConvertBytesToFrames(player.instrument(player.channel(nChannel).instrument).loopEnd, player.instrument(player.channel(nChannel).instrument).bytesPerSample, player.instrument(player.channel(nChannel).instrument).channels)
                        END IF
                    END IF

                CASE __MOD_FX_VIBRATO_FINE
                    __MODPlayer_DoVibrato player, nChannel, _FALSE ' false here means fine vibrato

            END SELECT
        END IF
    NEXT
END SUB


''' @brief Sets sequencer tempo (Beats Per Minute) and recalculates timing parameters.
''' @param player The MOD player instance.
''' @param nBPM Tempo in BPM (32 to 255).
SUB __MODPlayer_SetBPM (player AS MODPlayer, nBPM AS _UNSIGNED _BYTE)
    IF nBPM = 0 THEN EXIT SUB

    player.song.BPM = nBPM

    IF player.song.tempoTimerValue = 0 THEN
        player.song.tempoTimerValue = (SoftSynth_GetSampleRate(player.synth) * __SONG_BPM_DEFAULT) \ 50
    END IF

    ' Calculate the number of samples we have to mix per tick
    player.song.framesPerTick = player.song.tempoTimerValue \ nBPM
END SUB


''' @brief Finds the closest period table entry to a given period value.
''' @param target Target period value.
''' @return The closest matched period.
FUNCTION __MODPlayer_GetClosestPeriod& (target AS LONG)
    SHARED __MODPlayer_PeriodTable() AS _UNSIGNED INTEGER

    DIM AS LONG startPos, endPos, midPos, leftVal, rightVal

    IF target > 27392 THEN
        __MODPlayer_GetClosestPeriod = target
        EXIT FUNCTION
    ELSEIF target < 14 THEN
        __MODPlayer_GetClosestPeriod = target
        EXIT FUNCTION
    END IF

    startPos = 0
    endPos = UBOUND(__MODPlayer_PeriodTable)
    WHILE startPos + 1 < endPos
        midPos = startPos + (endPos - startPos) \ 2
        IF __MODPlayer_PeriodTable(midPos) <= target THEN
            endPos = midPos
        ELSE
            startPos = midPos
        END IF
    WEND

    rightVal = ABS(__MODPlayer_PeriodTable(startPos) - target)
    leftVal = ABS(__MODPlayer_PeriodTable(endPos) - target)

    IF leftVal <= rightVal THEN
        __MODPlayer_GetClosestPeriod = __MODPlayer_PeriodTable(endPos)
    ELSE
        __MODPlayer_GetClosestPeriod = __MODPlayer_PeriodTable(startPos)
    END IF
END FUNCTION


''' @brief Performs tone portamento calculation towards destination note period for a channel.
''' @param chan Channel index (0-based).
SUB __MODPlayer_DoPortamento (player AS MODPlayer, chan AS _UNSIGNED _BYTE)
' Slide up/down and clamp to destination
    IF player.channel(chan).period < player.channel(chan).portamentoTo THEN
        player.channel(chan).period = player.channel(chan).period + _SHL(player.channel(chan).portamentoSpeed, 2)
        IF player.channel(chan).period > player.channel(chan).portamentoTo THEN
            player.channel(chan).period = player.channel(chan).portamentoTo
        END IF
    ELSEIF player.channel(chan).period > player.channel(chan).portamentoTo THEN
        player.channel(chan).period = player.channel(chan).period - _SHL(player.channel(chan).portamentoSpeed, 2)
        IF player.channel(chan).period < player.channel(chan).portamentoTo THEN
            player.channel(chan).period = player.channel(chan).portamentoTo
        END IF
    END IF

    IF player.channel(chan).useGlissando THEN
        SoftSynth_SetVoiceFrequency player.synth, chan, __MODPlayer_GetFrequencyFromPeriod(__MODPlayer_GetClosestPeriod(player.channel(chan).period))
    ELSE
        SoftSynth_SetVoiceFrequency player.synth, chan, __MODPlayer_GetFrequencyFromPeriod(player.channel(chan).period)
    END IF
END SUB


''' @brief Performs volume slide up or down calculation on a channel.
''' @param chan Channel index (0-based).
''' @param x Upward slide amount nibble.
''' @param y Downward slide amount nibble.
''' @param isNotFine _TRUE for regular volume slide, _FALSE for fine volume slide.
SUB __MODPlayer_DoVolumeSlide (player AS MODPlayer, chan AS _UNSIGNED _BYTE, x AS _UNSIGNED _BYTE, y AS _UNSIGNED _BYTE, isNotFine AS _BYTE)
IF isNotFine THEN
        player.channel(chan).volume = player.channel(chan).volume + x - y
    ELSE
        IF y = 0 THEN player.channel(chan).volume = player.channel(chan).volume + x
        IF x = 0 THEN player.channel(chan).volume = player.channel(chan).volume - y
    END IF

    IF player.channel(chan).volume > __INSTRUMENT_VOLUME_MAX THEN player.channel(chan).volume = __INSTRUMENT_VOLUME_MAX
    IF player.channel(chan).volume < 0 THEN player.channel(chan).volume = 0

    SoftSynth_SetVoiceVolume player.synth, chan, player.channel(chan).volume / __INSTRUMENT_VOLUME_MAX
END SUB


''' @brief Processes Scream Tracker 3 tremor effect on a channel.
''' @param chan Channel index (0-based).
SUB __MODPlayer_DoS3MTremor (player AS MODPlayer, chan AS _UNSIGNED _BYTE)
player.channel(chan).tremorPosition = player.channel(chan).tremorPosition MOD (_SHR(player.channel(chan).tremorParameters, 4) + (player.channel(chan).tremorParameters AND &HF))

    IF player.channel(chan).tremorPosition < _SHR(player.channel(chan).tremorParameters, 4) THEN
        SoftSynth_SetVoiceVolume player.synth, chan, player.channel(chan).volume / __INSTRUMENT_VOLUME_MAX
    ELSE
        SoftSynth_SetVoiceVolume player.synth, chan, 0
    END IF

    player.channel(chan).tremorPosition = player.channel(chan).tremorPosition + 1
END SUB


''' @brief Calculates and applies pitch vibrato oscillation on a channel.
''' @param chan Channel index (0-based).
''' @param isNotFine _TRUE for standard vibrato, _FALSE for fine vibrato.
SUB __MODPlayer_DoVibrato (player AS MODPlayer, chan AS _UNSIGNED _BYTE, isNotFine AS _BYTE)
SHARED __MODPlayer_SineTable() AS _UNSIGNED _BYTE
    DIM delta AS _UNSIGNED INTEGER
    DIM temp AS _UNSIGNED _BYTE

    temp = player.channel(chan).vibratoPosition AND 31

    SELECT CASE player.channel(chan).waveControl AND 3
        CASE 0 ' Sine
            delta = __MODPlayer_SineTable(temp)

        CASE 1 ' Saw down
            temp = _SHL(temp, 3)
            IF player.channel(chan).vibratoPosition < 0 THEN temp = 255 - temp
            delta = temp

        CASE 2 ' Square
            delta = 255

        CASE 3 ' Random
            delta = RND * 255!
    END SELECT

    delta = _SHR(delta * player.channel(chan).vibratoDepth, 7)
    IF isNotFine THEN delta = _SHL(delta, 2) ' make vibrato 4 times bigger

    IF player.channel(chan).vibratoPosition >= 0 THEN
        SoftSynth_SetVoiceFrequency player.synth, chan, __MODPlayer_GetFrequencyFromPeriod(player.channel(chan).period + delta)
    ELSE
        SoftSynth_SetVoiceFrequency player.synth, chan, __MODPlayer_GetFrequencyFromPeriod(player.channel(chan).period - delta)
    END IF

    player.channel(chan).vibratoPosition = player.channel(chan).vibratoPosition + player.channel(chan).vibratoSpeed
    IF player.channel(chan).vibratoPosition > 31 THEN
        player.channel(chan).vibratoPosition = player.channel(chan).vibratoPosition - 64
    END IF
END SUB


''' @brief Calculates and applies volume tremolo oscillation on a channel.
''' @param chan Channel index (0-based).
SUB __MODPlayer_DoTremolo (player AS MODPlayer, chan AS _UNSIGNED _BYTE)
SHARED __MODPlayer_SineTable() AS _UNSIGNED _BYTE
    DIM delta AS _UNSIGNED INTEGER
    DIM temp AS _UNSIGNED _BYTE

    temp = player.channel(chan).tremoloPosition AND 31

    SELECT CASE _SHR(player.channel(chan).waveControl, 4) AND 3
        CASE 0 ' Sine
            delta = __MODPlayer_SineTable(temp)

        CASE 1 ' Saw down
            temp = _SHL(temp, 3)
            IF player.channel(chan).tremoloPosition < 0 THEN temp = 255 - temp
            delta = temp

        CASE 2 ' Square
            delta = 255

        CASE 3 ' Random
            delta = RND * 255!
    END SELECT

    delta = _SHR(delta * player.channel(chan).tremoloDepth, 6)

    IF player.channel(chan).tremoloPosition >= 0 THEN
        IF player.channel(chan).volume + delta > __INSTRUMENT_VOLUME_MAX THEN delta = __INSTRUMENT_VOLUME_MAX - player.channel(chan).volume
        SoftSynth_SetVoiceVolume player.synth, chan, (player.channel(chan).volume + delta) / __INSTRUMENT_VOLUME_MAX
    ELSE
        IF player.channel(chan).volume - delta < 0 THEN delta = player.channel(chan).volume
        SoftSynth_SetVoiceVolume player.synth, chan, (player.channel(chan).volume - delta) / __INSTRUMENT_VOLUME_MAX
    END IF

    player.channel(chan).tremoloPosition = player.channel(chan).tremoloPosition + player.channel(chan).tremoloSpeed
    IF player.channel(chan).tremoloPosition > 31 THEN player.channel(chan).tremoloPosition = player.channel(chan).tremoloPosition - 64
END SUB


''' @brief Processes ProTracker EFx funk / invert loop effect on a channel.
''' @param chan Channel index (0-based).
SUB __MODPlayer_DoInvertLoop (player AS MODPlayer, chan AS _UNSIGNED _BYTE)
SHARED __MODPlayer_InvertLoopSpeedTable() AS _UNSIGNED _BYTE
    player.channel(chan).invertLoopDelay = player.channel(chan).invertLoopDelay + __MODPlayer_InvertLoopSpeedTable(player.channel(chan).invertLoopSpeed)

    DIM sampleNumber AS _UNSIGNED _BYTE: sampleNumber = player.channel(chan).instrument ' cache the sample number case we'll use this often below

    IF player.channel(chan).invertLoopDelay >= 128 _ANDALSO SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP = player.instrument(sampleNumber).playMode THEN
        player.channel(chan).invertLoopDelay = 0 ' reset delay
        IF player.channel(chan).invertLoopPosition < player.instrument(sampleNumber).loopStart THEN
            player.channel(chan).invertLoopPosition = player.instrument(sampleNumber).loopStart
        END IF
        player.channel(chan).invertLoopPosition = player.channel(chan).invertLoopPosition + 1 ' increment position by 1
        IF player.channel(chan).invertLoopPosition >= player.instrument(sampleNumber).loopEnd THEN
            player.channel(chan).invertLoopPosition = player.instrument(sampleNumber).loopStart
        END IF

        ' Yeah I know, this is weird. QB64 NOT is bitwise and not logical
        DIM p AS _UNSIGNED LONG: p = SoftSynth_ConvertBytesToFrames(player.channel(chan).invertLoopPosition, player.instrument(sampleNumber).bytesPerSample, player.instrument(sampleNumber).channels)
        SoftSynth_PokeSoundFrameByte player.synth, sampleNumber, p, NOT SoftSynth_PeekSoundFrameByte(player.synth, sampleNumber, p)
    END IF
END SUB


''' @brief Calculates audio playback frequency in Hertz from an Amiga period value.
''' @param period Amiga period value.
''' @return Frequency in Hertz.
FUNCTION __MODPlayer_GetFrequencyFromPeriod~& (period AS LONG)
    __MODPlayer_GetFrequencyFromPeriod = 14317056 \ period
END FUNCTION


''' @brief Calculates middle-C playback speed in Hertz for a ProTracker finetune nibble.
''' @param ft Signed finetune nibble (0-15).
''' @return C2 playback speed in Hertz.
FUNCTION __MODPlayer_GetC2Spd~% (ft AS _UNSIGNED _BYTE)
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
END FUNCTION


''' @brief Gets the title name of the currently loaded tune.
''' @return Tune name string.
FUNCTION MODPlayer_GetName$ (player AS MODPlayer)
    MODPlayer_GetName = player.song.caption
END FUNCTION


''' @brief Gets the format descriptor or magic tag of the currently loaded tune.
''' @param player The MOD player instance.
''' @return Format string (e.g. "M.K.", "SCRM", "MTM1").
FUNCTION MODPlayer_GetType$ (player AS MODPlayer)
    MODPlayer_GetType = player.song.subtype
END FUNCTION


''' @brief Checks whether a song is actively playing.
''' @param player The MOD player instance.
''' @return _TRUE if playing, _FALSE otherwise.
FUNCTION MODPlayer_IsPlaying%% (player AS MODPlayer)
    MODPlayer_IsPlaying = player.song.isPlaying
END FUNCTION


''' @brief Pauses or unpauses song playback.
''' @param player The MOD player instance.
''' @param state _TRUE to pause playback, _FALSE to resume.
SUB MODPlayer_Pause (player AS MODPlayer, state AS _BYTE)
    player.song.isPaused = state
END SUB


''' @brief Checks whether song playback is currently paused.
''' @param player The MOD player instance.
''' @return _TRUE if paused, _FALSE otherwise.
FUNCTION MODPlayer_IsPaused%% (player AS MODPlayer)
    MODPlayer_IsPaused = player.song.isPaused
END FUNCTION


''' @brief Sets continuous song looping mode.
''' @param player The MOD player instance.
''' @param state _TRUE to loop continuously, _FALSE to stop at song end.
SUB MODPlayer_Loop (player AS MODPlayer, state AS _BYTE)
    player.song.isLooping = state
END SUB


''' @brief Checks whether continuous song looping is enabled.
''' @param player The MOD player instance.
''' @return _TRUE if looping is enabled, _FALSE otherwise.
FUNCTION MODPlayer_IsLooping%% (player AS MODPlayer)
    MODPlayer_IsLooping = player.song.isLooping
END FUNCTION


''' @brief Advances playback position to the next pattern order, wrapping at song end if looping.
''' @param player The MOD player instance.
SUB MODPlayer_GoToNextPosition (player AS MODPlayer)
    IF player.song.isLooping THEN ' if we are looping
        player.song.orderPosition = player.song.orderPosition + 1 ' move to the next order
        IF player.song.orderPosition >= player.song.orders THEN player.song.orderPosition = 0 ' wrap to first order if we have reached the end
        player.song.patternRow = 0 ' reset row position
    ELSEIF player.song.orderPosition < player.song.orders - 1 THEN ' else only if have not reached the last order
        player.song.orderPosition = player.song.orderPosition + 1
        player.song.patternRow = 0 ' reset row position
    END IF
END SUB


''' @brief Rewinds playback position to the previous pattern order, wrapping if looping.
''' @param player The MOD player instance.
SUB MODPlayer_GoToPreviousPosition (player AS MODPlayer)
    IF player.song.isLooping THEN ' if we are looping
        player.song.orderPosition = player.song.orderPosition - 1 ' move to the previous order
        IF player.song.orderPosition < 0 THEN player.song.orderPosition = player.song.orders - 1 ' wrap to the last order if we have crossed the beginning
        player.song.patternRow = 0 ' reset row position
    ELSEIF player.song.orderPosition > 0 THEN ' else only if have not reached the first order
        player.song.orderPosition = player.song.orderPosition - 1 ' move to the previous order
        player.song.patternRow = 0 ' reset row position
    END IF
END SUB


''' @brief Sets the current pattern order playback position.
''' @param player The MOD player instance.
''' @param position Target order position index (0-based).
SUB MODPlayer_SetPosition (player AS MODPlayer, position AS _UNSIGNED INTEGER)
    IF position < player.song.orders THEN
        player.song.orderPosition = position
        player.song.patternRow = 0
    END IF
END SUB


''' @brief Gets the current pattern order playback position index.
''' @param player The MOD player instance.
''' @return Current order position index (0-based).
FUNCTION MODPlayer_GetPosition& (player AS MODPlayer)
    MODPlayer_GetPosition = player.song.orderPosition
END FUNCTION


''' @brief Gets the total number of pattern orders in the loaded tune.
''' @param player The MOD player instance.
''' @return Total order count.
FUNCTION MODPlayer_GetOrders~% (player AS MODPlayer)
    MODPlayer_GetOrders = player.song.orders
END FUNCTION


''' @brief Gets the number of rows in a specific pattern.
''' @param player The MOD player instance.
''' @param patternIndex Pattern index (0-based).
''' @return Number of rows in the pattern (0 if invalid pattern index).
FUNCTION MODPlayer_GetPatternRows~% (player AS MODPlayer, patternIndex AS _UNSIGNED INTEGER)
    IF patternIndex < player.song.patterns THEN
        MODPlayer_GetPatternRows = player.pattern(patternIndex).rows
    END IF
END FUNCTION


'$INCLUDE:'S3MLoader.bi'
'$INCLUDE:'MTMLoader.bi'
'$INCLUDE:'MODLoader.bi'

''' @brief Loads a tracker module from a memory buffer, auto-detecting the format across registered loaders.
''' @param player The MOD player instance.
''' @param buffer In-memory binary representation of the module file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION MODPlayer_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
    IF NOT MODPlayer_IsInitialized(player) THEN
        IF NOT MODPlayer_Initialize(player) THEN EXIT FUNCTION
    END IF

    IF S3MLoader_LoadFromMemory(player, buffer) THEN
        MODPlayer_LoadFromMemory = _TRUE
        EXIT FUNCTION
    END IF

    IF MTMLoader_LoadFromMemory(player, buffer) THEN
        MODPlayer_LoadFromMemory = _TRUE
        EXIT FUNCTION
    END IF

    IF MODLoader_LoadFromMemory(player, buffer) THEN
        MODPlayer_LoadFromMemory = _TRUE
        EXIT FUNCTION
    END IF
END FUNCTION


''' @brief Loads a tracker module from a disk file, auto-detecting the format across registered loaders.
''' @param player The MOD player instance.
''' @param fileName Path to the module file.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION MODPlayer_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
    DIM buffer AS STRING: buffer = File_LoadFromDisk(fileName)
    IF LEN(buffer) = 0 THEN EXIT FUNCTION
    MODPlayer_LoadFromDisk = MODPlayer_LoadFromMemory(player, buffer)
END FUNCTION
