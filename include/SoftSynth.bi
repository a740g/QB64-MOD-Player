'---------------------------------------------------------------------------------------------------------
' A really simple sample-based software synthesizer
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'$Include:'CRTLib.bi'
'---------------------------------------------------------------------------------------------------------

$If SOFTSYNTH_BI = UNDEFINED Then
    $Let SOFTSYNTH_BI = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-----------------------------------------------------------------------------------------------------
    Const SAMPLE_VOLUME_MAX = 64 ' This is the maximum volume of any sample
    Const SAMPLE_PAN_LEFT = 0 ' Leftmost pannning position
    Const SAMPLE_PAN_RIGHT = 255 ' Rightmost pannning position
    Const SAMPLE_PAN_CENTER = (SAMPLE_PAN_RIGHT - SAMPLE_PAN_LEFT) / 2 ' Center panning position
    Const SAMPLE_PLAY_SINGLE = 0 ' Single-shot playback
    Const SAMPLE_PLAY_LOOP = 1 ' Forward-looping playback
    Const GLOBAL_VOLUME_MAX = 255 ' Max global volume
    Const SOUND_TIME_MIN = 0.2 ' We will check that we have this amount of time left in the playback buffer
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-----------------------------------------------------------------------------------------------------
    Type SoftSynthType
        voices As Unsigned Byte ' Number of mixer voices requested
        samples As Unsigned Byte ' Number of samples slots requested
        mixerRate As Long ' This is always set by QB64 internal audio engine
        soundHandle As Long ' QB64 sound pipe that we will use to stream the mixed audio
        volume As Single ' Global volume (0 - 255) (fp32)
        useHQMixer As Byte ' If this is set to true, then we are using linear interpolation mixing
        activeVoices As Unsigned Byte ' Just a count of voices we really mixed
    End Type

    Type VoiceType
        sample As Integer ' Sample number to be mixed. This is set to -1 once the mixer is done with the sample
        volume As Single ' Voice volume (0 - 64) (fp32)
        panning As Single ' Position 0 is leftmost ... 255 is rightmost (fp32)
        pitch As Single ' Sample pitch. The mixer code uses this to step through the sample correctly (fp32)
        position As Single ' Where are we in the sample buffer (fp32)
        playType As Unsigned Byte ' How should the sample be played
        startPosition As Single ' Start poistion. This can be loop start or just start depending on play type
        endPosition As Single ' End position. This can be loop end or just end depending on play type
    End Type
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-----------------------------------------------------------------------------------------------------
    Dim SoftSynth As SoftSynthType
    ReDim SampleData(0 To 0) As String ' Sample data array
    ReDim Voice(0 To 0) As VoiceType ' Voice info array
    ReDim MixerBufferLeft(0 To 0) As Single ' Left channel mixer buffer
    ReDim MixerBufferRight(0 To 0) As Single ' Right channel mixer buffer
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------

