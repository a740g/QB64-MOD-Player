'---------------------------------------------------------------------------------------------------------
' A really simple sample-based software synthesizer
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
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
    Const GLOBAL_VOLUME_MAX = 255 ' Max song master volume
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-----------------------------------------------------------------------------------------------------
    Type VoiceType
        sample As Integer ' Sample number to be mixed. This is set to -1 once the mixer is done with the sample
        volume As Unsigned Byte ' Voice volume (0 - 64)
        panning As Single ' Position 0 is leftmost ... 255 is rightmost (fp32)
        pitch As Single ' Sample pitch. The mixer code uses this to step through the sample correctly (fp32)
        position As Single ' Where are we in the sample buffer (fp32)
        length As Unsigned Long ' "Play" length (at what point it should stop)
        isLooping As Byte ' Is the sample a looping sample
        loopStart As Unsigned Long ' Loop start point
        loopEnd As Unsigned Long ' Loop end point
    End Type

    Type SoftSynthType
        voices As Unsigned Integer ' Number of mixer voices requested
        samples As Unsigned Integer ' Number of samples slots requested
        mixerRate As Long ' This is always set by QB64 internal audio engine
        qb64SoundPipe As Long ' QB64 sound pipe that we will use to stream the mixed audio
        volume As Unsigned Byte ' Global volume (0 - 255)
        useHQMixer As Byte ' If this is set to true, then we are using linear interpolation mixing
        activeVoices As Unsigned Integer ' Just a count of voices we really mixed
    End Type

    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-----------------------------------------------------------------------------------------------------
    Dim Shared SoftSynth As SoftSynthType
    ReDim Shared SampleData(0 To 0) As String ' Sample data array
    ReDim Shared Voice(0 To 0) As VoiceType ' Voice info array
    ReDim Shared MixerBuffer(1 To 2, 1 To 1) As Single ' Sample data here can be used for visualization
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------

