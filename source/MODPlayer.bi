'-----------------------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

$UNSTABLE:TYPEFIELDS

'$INCLUDE:'SoftSynth.bi'
'$INCLUDE:'Opal.bi'

' Tracker format identifiers
CONST MODPLAYER_FORMAT_NONE~% = 0~%
CONST MODPLAYER_FORMAT_MOD~% = 1~% ' ProTracker / NoiseTracker / SoundTracker / FastTracker 1 (.MOD, .STK, .M15)
CONST MODPLAYER_FORMAT_STM~% = 2~%
CONST MODPLAYER_FORMAT_S3M~% = 3~%
CONST MODPLAYER_FORMAT_669~% = 4~%
CONST MODPLAYER_FORMAT_MTM~% = 5~%
CONST MODPLAYER_FORMAT_FAR~% = 6~%
CONST MODPLAYER_FORMAT_RAD~% = 7~%
CONST MODPLAYER_FORMAT_ULT~% = 8~%
CONST MODPLAYER_FORMAT_MDL~% = 9~%
CONST MODPLAYER_FORMAT_AMF~% = 10~%

CONST __MODPLAYER_NOTE_NONE~%% = 132~%% ' Note will be set to this when there is nothing
CONST __MODPLAYER_NOTE_KEY_OFF~%% = 133~%% ' We'll use this in a future version
CONST __MODPLAYER_NOTE_NO_VOLUME~%% = 255~%% ' When a note has no volume, then it will be set to this
CONST __MODPLAYER_MOD_S3M_ROWS~%% = 64~%% ' number of rows in a MOD / S3M pattern
CONST __MODPLAYER_MOD_MTM_ORDER_MAX~%% = 127~%% ' maximum position in a MOD / MTM order table
CONST __MODPLAYER_INSTRUMENT_VOLUME_MAX~%% = 64~%% ' this is the maximum volume of any MOD instrument
CONST __MODPLAYER_INSTRUMENT_NONE~%% = 0~%% ' no instrument
CONST __MODPLAYER_INSTRUMENT_PCM~%% = 1~%% ' good old digital PCM instrument
CONST __MODPLAYER_INSTRUMENT_FM_MELODY~%% = 2~%% ' FM melody instrument
CONST __MODPLAYER_INSTRUMENT_FM_BASSDRUM~%% = 3~%% ' FM bass drum instrument
CONST __MODPLAYER_INSTRUMENT_FM_SNAREDRUM~%% = 4~%% ' FM snare instrument
CONST __MODPLAYER_INSTRUMENT_FM_TOMTOM~%% = 5~%% ' FM tom-tom instrument
CONST __MODPLAYER_INSTRUMENT_FM_CYMBAL~%% = 6~%% ' FM cymbal instrument
CONST __MODPLAYER_INSTRUMENT_FM_HIHAT~%% = 7~%% ' FM hi-hat instrument
CONST __MODPLAYER_INSTRUMENT_AM_SYNTH~%% = 8~%% ' StarTrekker synthesized AM instrument
CONST __MODPLAYER_AM_STAGE_IDLE~%% = 0~%% ' AM envelope idle
CONST __MODPLAYER_AM_STAGE_ATTACK1~%% = 1~%% ' AM envelope attack stage 1
CONST __MODPLAYER_AM_STAGE_ATTACK2~%% = 2~%% ' AM envelope attack stage 2
CONST __MODPLAYER_AM_STAGE_DECAY~%% = 3~%% ' AM envelope decay stage
CONST __MODPLAYER_AM_STAGE_SUSTAIN~%% = 4~%% ' AM envelope sustain hold stage
CONST __MODPLAYER_AM_STAGE_RELEASE~%% = 5~%% ' AM envelope release stage
CONST __MODPLAYER_PATTERN_MARKER~%% = 254~%% ' S3M marker pattern
CONST __MODPLAYER_PATTERN_END~%% = 255~%% ' S3M end-of-song
CONST __MODPLAYER_STEREO_SEPARATION! = 0.5! ' 100% stereo separation sounds bad on headphones
CONST __MODPLAYER_MTM_S3M_CHANNEL_MAX~%% = 31~%% ' maximum channel number supported by MTM / S3M
CONST __MODPLAYER_S3M_GLOBAL_VOLUME_MAX~%% = 64~%% ' S3M global volume maximum value
CONST __MODPLAYER_SONG_SPEED_DEFAULT~%% = 6~%% ' This is the default speed for song where it is not specified
CONST __MODPLAYER_SONG_BPM_DEFAULT~%% = 125~%% ' Default song BPM when it is not specified

' These are the effects support by the player (basically these are Protracker effects + extras)
CONST __MODPLAYER_FX_ARPEGGIO~%% = 0~%%
CONST __MODPLAYER_FX_PORTAMENTO_UP~%% = 1~%%
CONST __MODPLAYER_FX_PORTAMENTO_DOWN~%% = 2~%%
CONST __MODPLAYER_FX_PORTAMENTO~%% = 3~%%
CONST __MODPLAYER_FX_VIBRATO~%% = 4~%%
CONST __MODPLAYER_FX_PORTAMENTO_VOLUME_SLIDE~%% = 5~%%
CONST __MODPLAYER_FX_VIBRATO_VOLUME_SLIDE~%% = 6~%%
CONST __MODPLAYER_FX_TREMOLO~%% = 7~%%
CONST __MODPLAYER_FX_PANNING_8~%% = 8~%%
CONST __MODPLAYER_FX_SAMPLE_OFFSET~%% = 9~%%
CONST __MODPLAYER_FX_VOLUME_SLIDE~%% = 10~%%
CONST __MODPLAYER_FX_POSITION_JUMP~%% = 11~%%
CONST __MODPLAYER_FX_VOLUME~%% = 12~%%
CONST __MODPLAYER_FX_PATTERN_BREAK~%% = 13~%%
CONST __MODPLAYER_FX_EXT~%% = 14~%%
CONST __MODPLAYER_FX_EXT_FILTER~%% = 0~%%
CONST __MODPLAYER_FX_EXT_PORTAMENTO_FINE_UP~%% = 1~%%
CONST __MODPLAYER_FX_EXT_PORTAMENTO_FINE_DOWN~%% = 2~%%
CONST __MODPLAYER_FX_EXT_GLISSANDO_CONTROL~%% = 3~%%
CONST __MODPLAYER_FX_EXT_VIBRATO_WAVEFORM~%% = 4~%%
CONST __MODPLAYER_FX_EXT_FINETUNE~%% = 5~%%
CONST __MODPLAYER_FX_EXT_PATTERN_LOOP~%% = 6~%%
CONST __MODPLAYER_FX_EXT_TREMOLO_WAVEFORM~%% = 7~%%
CONST __MODPLAYER_FX_EXT_PANNING_4~%% = 8~%%
CONST __MODPLAYER_FX_EXT_NOTE_RETRIGGER~%% = 9~%%
CONST __MODPLAYER_FX_EXT_VOL_FINE_SLIDE_UP~%% = 10~%%
CONST __MODPLAYER_FX_EXT_VOL_FINE_SLIDE_DOWN~%% = 11~%%
CONST __MODPLAYER_FX_EXT_NOTE_CUT~%% = 12~%%
CONST __MODPLAYER_FX_EXT_NOTE_DELAY~%% = 13~%%
CONST __MODPLAYER_FX_EXT_PATTERN_DELAY~%% = 14~%%
CONST __MODPLAYER_FX_EXT_INVERT_LOOP~%% = 15~%%
CONST __MODPLAYER_FX_SPEED_TEMPO~%% = 15~%%
CONST __MODPLAYER_FX_SPEED~%% = 16~%%
CONST __MODPLAYER_FX_VOLUME_FINE_SLIDE~%% = 17~%%
CONST __MODPLAYER_FX_PORTA_EXTRA_FINE_DOWN~%% = 18~%%
CONST __MODPLAYER_FX_PORTA_EXTRA_FINE_UP~%% = 19~%%
CONST __MODPLAYER_FX_TREMOR~%% = 20~%%
CONST __MODPLAYER_FX_VIBRATO_VOL_FINE_SLIDE~%% = 21~%%
CONST __MODPLAYER_FX_PORTA_VOL_FINE_SLIDE~%% = 22~%%
CONST __MODPLAYER_FX_CHANNEL_VOLUME~%% = 23~%%
CONST __MODPLAYER_FX_CHANNEL_VOLUME_SLIDE~%% = 24~%%
CONST __MODPLAYER_FX_PANNING_FINE_SLIDE~%% = 25~%%
CONST __MODPLAYER_FX_NOTE_RETRIGGER_VOL_SLIDE~%% = 26~%%
CONST __MODPLAYER_FX_PANBRELLO_WAVEFORM~%% = 27~%%
CONST __MODPLAYER_FX_PATTERN_FINE_DELAY~%% = 28~%%
CONST __MODPLAYER_FX_SOUND_CONTROL~%% = 29~%%
CONST __MODPLAYER_FX_HIGH_OFFSET~%% = 30~%%
CONST __MODPLAYER_FX_TEMPO~%% = 31~%%
CONST __MODPLAYER_FX_VIBRATO_FINE~%% = 32~%%
CONST __MODPLAYER_FX_GLOBAL_VOLUME~%% = 33~%%
CONST __MODPLAYER_FX_GLOBAL_VOLUME_SLIDE~%% = 34~%%
CONST __MODPLAYER_FX_PANBRELLO~%% = 35~%%
CONST __MODPLAYER_FX_MIDI_MACRO~%% = 36~%%
CONST __MODPLAYER_FX_STEREO_CONTROL~%% = 37~%% ' Legacy S3M SAx channel panning

TYPE __MODPlayerNote
    note AS _UNSIGNED _BYTE ' contains info on 1 note
    instrument AS _UNSIGNED INTEGER ' instrument number to play
    volume AS _UNSIGNED _BYTE ' volume value. Not used for MODs. 255 = no volume
    effect AS _UNSIGNED _BYTE ' effect number
    operand AS _UNSIGNED _BYTE ' effect parameters
END TYPE

TYPE __MODPlayerPattern
    rows AS _UNSIGNED INTEGER ' number of rows in this pattern (typically 64, but can be 1 to 256 for XM, etc.)
    _DYNAMIC note(0 TO 0, 0 TO 0) AS __MODPlayerNote ' note matrix: (0 TO rows - 1, 0 TO channels - 1)
END TYPE

TYPE __MODPlayerAMInfo
    isAM AS _BYTE ' whether this instrument has synthesized AM parameters
    startLevel AS _UNSIGNED INTEGER ' start envelope level (0-256)
    attack1Level AS _UNSIGNED INTEGER ' attack 1 level (0-256)
    attack1Speed AS _UNSIGNED INTEGER ' attack 1 transition speed
    attack2Level AS _UNSIGNED INTEGER ' attack 2 level (0-256)
    attack2Speed AS _UNSIGNED INTEGER ' attack 2 transition speed
    sustainLevel AS _UNSIGNED INTEGER ' sustain level (0-256)
    decaySpeed AS _UNSIGNED INTEGER ' decay transition speed
    sustainTime AS _UNSIGNED INTEGER ' sustain hold time in ticks
    releaseSpeed AS _UNSIGNED INTEGER ' release transition speed
    waveform AS _UNSIGNED _BYTE ' 0=sine, 1=saw, 2=square, 3=noise
    pitchFall AS INTEGER ' signed pitch fall rate per tick
    vibAmp AS _UNSIGNED _BYTE ' vibrato depth
    vibSpeed AS _UNSIGNED _BYTE ' vibrato rate
    octave AS _UNSIGNED _BYTE ' octave transpose (0=high, 5=low)
END TYPE

TYPE __MODPlayerInstrument
    caption AS STRING ' instrument name or message
    subtype AS _UNSIGNED _BYTE ' what kind of instrument is this? (PCM, FM melody, FM drum, etc.)
    length AS _UNSIGNED LONG ' sample length in bytes
    c2Spd AS _UNSIGNED LONG ' sample finetune is converted to c2spd
    volume AS _UNSIGNED _BYTE ' volume: 0 - 64
    loopStart AS _UNSIGNED LONG ' loop start (or just start; usually 0) in bytes
    loopEnd AS _UNSIGNED LONG ' loop end (or just end; usually length) in bytes
    playMode AS LONG ' the playack mode (supported by SoftSynth)
    bytesPerSample AS _UNSIGNED _BYTE ' 1 for 8-bit, 2 for 16-bit, 4 for 32-bit etc. (SoftSynth will convert sounds to 32-bit floating point)
    channels AS _UNSIGNED _BYTE ' number of channels per frame (SoftSynth will flatten sounds to mono)
    adlib(0 TO 11) AS _UNSIGNED _BYTE ' 12 AdLib instrument parameter bytes (D00..D0B)
    am AS __MODPlayerAMInfo ' StarTrekker AM synthesizer parameters
END TYPE

TYPE __MODPlayerChannel
    instrument AS _UNSIGNED INTEGER ' instrument number to be mixed
    subtype AS _UNSIGNED _BYTE ' channel synthesis mode: PCM, AM synth, FM melody, FM drum (see __MODPLAYER_INSTRUMENT_*)
    volume AS INTEGER ' channel volume. This is a signed int because we need -ve values & to clip properly
    restart AS _BYTE ' set this to true to retrigger the sample
    note AS _UNSIGNED _BYTE ' last note set in channel
    period AS LONG ' this is the period of the playing sample used by various effects
    lastPeriod AS LONG ' last period set in channel
    startPosition AS _UNSIGNED LONG ' this is starting position of the sample. Usually zero else value from sample offset effect
    channelVolume AS _UNSIGNED _BYTE ' S3M channel volume (Mxx), independent of sample volume
    defaultPanning AS _UNSIGNED _BYTE ' initial 8-bit S3M pan used when playback restarts
    panning AS _UNSIGNED _BYTE ' current 8-bit S3M pan position
    c2Spd AS _UNSIGNED LONG ' per-channel C2SPD, including S2x finetune
    lastSampleOffset AS _UNSIGNED _BYTE ' S3M Oxx effect memory
    lastPanningSlide AS _UNSIGNED _BYTE ' S3M Pxy effect memory
    lastChannelVolumeSlide AS _UNSIGNED _BYTE ' S3M Nxy effect memory
    lastGlobalVolumeSlide AS _UNSIGNED _BYTE ' S3M Wxy effect memory
    lastTempo AS _UNSIGNED _BYTE ' S3M Txx effect memory
    lastArpeggio AS _UNSIGNED _BYTE ' S3M Jxy effect memory
    tremorOnTicks AS _UNSIGNED _BYTE ' S3M Ixy on-time, including the encoded +1
    tremorOffTicks AS _UNSIGNED _BYTE ' S3M Ixy off-time, including the encoded +1
    panbrelloPosition AS _UNSIGNED _BYTE ' S3M Yxy phase
    panbrelloSpeed AS _UNSIGNED _BYTE ' S3M Yxy speed
    panbrelloDepth AS _UNSIGNED _BYTE ' S3M Yxy depth
    panbrelloWaveform AS _UNSIGNED _BYTE ' S3M S5x waveform
    panbrelloBasePanning AS _UNSIGNED _BYTE ' fixed pan center while Yxy oscillates
    panbrelloActive AS _BYTE ' current S3M panbrello row
    noteDelayPending AS _BYTE ' a delayed note is waiting for its tick
    noteDelayTick AS _UNSIGNED _BYTE ' S3M SDx tick to trigger the pending note
    delayedNote AS _UNSIGNED _BYTE ' pending note number
    delayedInstrument AS _UNSIGNED INTEGER ' pending instrument index
    delayedHasInstrument AS _BYTE ' whether the delayed row changes instrument
    delayedVolume AS _UNSIGNED _BYTE ' pending S3M volume-column value
    delayedPeriod AS LONG ' pending note period
    delayedStartPosition AS _UNSIGNED LONG ' pending sample start in bytes
    tremorMuted AS _BYTE ' current S3M tremor gate
    isMuted AS _BYTE ' whether channel is user-muted
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
    oplChannel AS _UNSIGNED _BYTE ' mapped OPL2 channel (0-8 for melody, or drum channel index)
    oplFNum AS _UNSIGNED INTEGER ' current F-Number sent to OPL
    oplBlock AS _UNSIGNED _BYTE ' current octave block sent to OPL
    oplKeyOn AS _BYTE ' whether key is active on OPL
    oplCarrierTotalLevel AS _UNSIGNED _BYTE ' current carrier total level
    amStage AS _UNSIGNED _BYTE ' current AM envelope stage (0-5)
    amLevel AS LONG ' current AM envelope level (0-256)
    amSustainCounter AS LONG ' remaining ticks in sustain stage
    amVibratoPos AS LONG ' AM vibrato phase position
    amPitchDelta AS LONG ' cumulative pitch fall offset
    amBasePeriod AS LONG ' base note period including octave transpose
END TYPE

TYPE __MODPlayerSong
    caption AS STRING ' song name
    subtype AS STRING * 4 ' 4 char MOD type - use this to find out what tracker was used
    format AS _UNSIGNED INTEGER ' tracker module format (MODPLAYER_FORMAT_*)
    comment AS STRING ' song comment / message (if any)
    channels AS _UNSIGNED LONG ' number of channels in the song
    instruments AS _UNSIGNED LONG ' number of instruments in the song
    orders AS _UNSIGNED INTEGER ' song length in orders
    endJumpOrder AS _UNSIGNED INTEGER ' this is used for jumping to an order if global looping is on
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
    BPM AS _UNSIGNED INTEGER ' current song BPM
    defaultSpeed AS _UNSIGNED _BYTE ' default song speed
    defaultBPM AS _UNSIGNED INTEGER ' default song BPM
    tick AS _UNSIGNED INTEGER ' current song tick (may exceed 255 with S6x fine pattern delay)
    rowTickDelay AS _UNSIGNED INTEGER ' accumulated S3M S6x extra ticks on the current row
    globalVolume AS _UNSIGNED _BYTE ' current S3M Vxx global volume (0-64)
    defaultGlobalVolume AS _UNSIGNED _BYTE ' S3M header global volume (0-64)
    tempoTimerValue AS _UNSIGNED LONG ' (mixer_sample_rate * default_bpm) / 50
    framesPerTick AS _UNSIGNED LONG ' this is the amount of sample frames we have to mix per tick based on mixerRate & bpm
    activeChannels AS _UNSIGNED LONG ' just a count of channels that are "active"
    useAmigaLPF AS _BYTE ' use Amiga 12 dB/oct Butterworth low-pass filter
    useST2Vibrato AS _BYTE ' use Scream Tracker 2 vibrato
    useST2Tempo AS _BYTE ' use Scream Tracker 2 tempo behavior
    useMTMTempoMode AS _BYTE ' MultiTracker Fxx tempo/speed reset behavior (reset tempo to 125 on speed, reset speed to 6 on tempo)
    useAmigaSlides AS _BYTE ' use volume slides similar to Amiga hardware
    useVolumeOptimization AS _BYTE ' turn off looping notes which have a zero volume for more than 2 rows
    useAmigaLimits AS _BYTE ' use Amiga limits (limit periods to confine to 113 <= x <= 856)
    useFilterSFX AS _BYTE ' enable filter / sfx with SB
    useST300VolumeSlides AS _BYTE ' ST3.00 volume slides (automatically enabled if tracker version is <= 0x1300) - if enabled, all volume slides occur every tick
    hasSpecialCustomData AS _BYTE ' special custom data in file (uses "Special" field)
    hasFMChannels AS _BYTE ' true if song contains AdLib FM channels
    isStereo AS _BYTE ' true if song uses stereo panning, false for mono
    pcmMasterGain AS SINGLE ' S3M master volume and channel attenuation multiplier for PCM channels
    fmMasterGain AS SINGLE ' OPL FM mixer gain multiplier (attenuated for mono)
END TYPE

TYPE MODPlayer
    song AS __MODPlayerSong
    synth AS SoftSynth
    opl AS Opal
    _DYNAMIC order(0 TO 0) AS _UNSIGNED INTEGER
    _DYNAMIC pattern(0 TO 0) AS __MODPlayerPattern
    _DYNAMIC instrument(0 TO 0) AS __MODPlayerInstrument
    _DYNAMIC channel(0 TO 0) AS __MODPlayerChannel
    initialized AS _BYTE
END TYPE

REDIM __MODPlayer_PeriodTable(0 TO 0) AS _UNSIGNED INTEGER ' Amiga period table
REDIM __MODPlayer_SineTable(0 TO 0) AS _UNSIGNED _BYTE ' sine table used for effects
REDIM __MODPlayer_InvertLoopSpeedTable(0 TO 0) AS _UNSIGNED _BYTE ' invert loop speed table for EFx
DIM __MODPlayer_TablesInitialized AS _BYTE
