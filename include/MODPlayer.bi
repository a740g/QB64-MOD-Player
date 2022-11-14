'---------------------------------------------------------------------------------------------------------
' QB64 MOD Player Library
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$include:'./SoftSynth.bi'
'---------------------------------------------------------------------------------------------------------

$If MODPLAYER_BI = UNDEFINED Then
    $Let MODPLAYER_BI = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-----------------------------------------------------------------------------------------------------
    Const PATTERN_ROW_MAX = 63 ' Max row number in a pattern
    Const NOTE_NONE = 132 ' Note will be set to this when there is nothing
    Const NOTE_KEY_OFF = 133 ' We'll use this in a future version
    Const NOTE_NO_VOLUME = 255 ' When a note has no volume, then it will be set to this
    Const ORDER_TABLE_MAX = 127 ' Max position in the order table
    Const SONG_SPEED_DEFAULT = 6 ' This is the default speed for song where it is not specified
    Const SONG_BPM_DEFAULT = 125 ' Default song BPM
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-----------------------------------------------------------------------------------------------------
    Type NoteType
        note As Unsigned Byte ' Contains info on 1 note
        sample As Unsigned Byte ' Sample number to play
        volume As Unsigned Byte ' Volume value. Not used for MODs. 255 = no volume
        effect As Unsigned Byte ' Effect number
        operand As Unsigned Byte ' Effect parameters
    End Type

    Type SampleType
        sampleName As String * 22 ' Sample name or message
        length As Long ' Sample length in bytes
        c2Spd As Unsigned Integer ' Sample finetune is converted to c2spd
        volume As Unsigned Byte ' Volume: 0 - 64
        loopStart As Long ' Loop start in bytes
        loopLength As Long ' Loop length in bytes
        loopEnd As Long ' Loop end in bytes
    End Type

    Type ChannelType
        sample As Unsigned Byte ' Sample number to be mixed
        volume As Integer ' Channel volume. This is a signed int because we need -ve values & to clip properly
        restart As Byte ' Set this to true to retrigger the sample
        note As Unsigned Byte ' Last note set in channel
        period As Long ' This is the period of the playing sample used by various effects
        lastPeriod As Long ' Last period set in channel
        startPosition As Long ' This is starting position of the sample. Usually zero else value from sample offset effect
        patternLoopRow As Integer ' This (signed) is the beginning of the loop in the pattern for effect E6x
        patternLoopRowCounter As Unsigned Byte ' This is a loop counter for effect E6x
        portamentoTo As Long ' Frequency to porta to value for E3x
        portamentoSpeed As Unsigned Byte ' Porta speed for E3x
        vibratoPosition As Byte ' Vibrato position in the sine table for E4x (signed)
        vibratoSpeed As Unsigned Byte ' Vibrato speed
        vibratoDepth As Unsigned Byte ' Vibrato depth
        tremoloPosition As Byte ' Tremolo position in the sine table (signed)
        tremoloSpeed As Unsigned Byte ' Tremolo speed
        tremoloDepth As Unsigned Byte ' Tremolo depth
        waveControl As Unsigned Byte ' Waveform type for vibrato and tremolo (4 bits each)
        useGlissando As Byte ' Flag to enable glissando (E3x) for subsequent porta-to-note effect
        invertLoopSpeed As Unsigned Byte ' Invert loop speed for EFx
        invertLoopDelay As Unsigned Integer ' Invert loop delay for EFx
        invertLoopPosition As Long ' Position in the sample where we are for the invert loop effect
    End Type

    Type SongType
        songName As String * 20 ' Song name
        subtype As String * 4 ' 4 char MOD type - use this to find out what tracker was used
        channels As Unsigned Byte ' Number of channels in the song - can be any number depending on the MOD file
        samples As Unsigned Byte ' Number of samples in the song - can be 15 or 31 depending on the MOD file
        orders As Unsigned Byte ' Song length in orders
        endJumpOrder As Unsigned Byte ' This is used for jumping to an order if global looping is on
        highestPattern As Unsigned Byte ' The highest pattern number read from the MOD file
        orderPosition As Integer ' The position in the order list. Signed so that we can properly wrap
        patternRow As Integer ' Points to the pattern row to be played. This is signed because sometimes we need to set it to -1
        tickPattern As Unsigned Byte ' Pattern number for UpdateMODRow() & UpdateMODTick()
        tickPatternRow As Integer ' Pattern row number for UpdateMODRow() & UpdateMODTick() (signed)
        isLooping As Byte ' Set this to true to loop the song once we reach the max order specified in the song
        isPlaying As Byte ' This is set to true as long as the song is playing
        isPaused As Byte ' Set this to true to pause playback
        patternDelay As Unsigned Byte ' Number of times to delay pattern for effect EE
        periodTableMax As Unsigned Byte ' We need this for searching through the period table for E3x
        speed As Unsigned Byte ' Current song speed
        bpm As Unsigned Byte ' Current song BPM
        tick As Unsigned Byte ' Current song tick
        tempoTimerValue As Unsigned Long ' (mixer_sample_rate * default_bpm) / 50
        samplesPerTick As Unsigned Long ' This is the amount of samples we have to mix per tick based on mixerRate & bpm
        activeChannels As Unsigned Byte ' Just a count of channels that are "active"
    End Type
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-----------------------------------------------------------------------------------------------------
    Dim Song As SongType
    Dim Order(0 To ORDER_TABLE_MAX) As Unsigned Byte ' Order list
    ReDim Pattern(0 To 0, 0 To 0, 0 To 0) As NoteType ' Pattern data strored as (pattern, row, channel)
    ReDim Sample(0 To 0) As SampleType ' Sample info array
    ReDim Channel(0 To 0) As ChannelType ' Channel info array
    ReDim PeriodTable(0 To 0) As Unsigned Integer ' Amiga period table
    ReDim SineTable(0 To 0) As Unsigned Byte ' Sine table used for effects
    ReDim InvertLoopSpeedTable(0 To 0) As Unsigned Byte ' Invert loop speed table for EFx
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------

