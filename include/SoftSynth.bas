'---------------------------------------------------------------------------------------------------------
' A really simple sample-based software synthesizer
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'SoftSynth.bi'
'---------------------------------------------------------------------------------------------------------

$If SOFTSYNTH_BAS = UNDEFINED Then
    $Let SOFTSYNTH_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------
    ' Initialize the sample mixer
    ' This allocates all required resources
    Sub InitializeMixer (nVoices As Unsigned Byte)
        ' Save the number of voices
        SoftSynth.voices = nVoices

        ' Resize the voice array
        ReDim Voice(0 To nVoices - 1) As VoiceType

        ' Set the mix rate to match that of the system
        SoftSynth.mixerRate = SndRate

        ' Allocate a QB64 sound pipe
        SoftSynth.qb64SoundPipe = SndOpenRaw

        ' Reset the global volume
        SoftSynth.volume = GLOBAL_VOLUME_MAX
    End Sub


    ' This initialized the sample manager
    ' All previous samples will be lost!
    Sub InitializeSampleManager (nSamples As Unsigned Byte)
        ' Save the number of samples
        SoftSynth.samples = nSamples

        ' Resize the sample data array
        ReDim SampleData(0 To nSamples - 1) As String
    End Sub


    ' Increase the number of mixer voices
    Sub AddVoices (nCount As Unsigned Byte)
        ' Increment the number of voices
        SoftSynth.voices = SoftSynth.voices + nCount

        ' Resize the voice array preserving elements
        ReDim Preserve Voice(0 To SoftSynth.voices - 1) As VoiceType
    End Sub


    ' Increase the number of samples slots
    Sub AddSamples (nCount As Unsigned Byte)
        ' Increment the number of samples
        SoftSynth.samples = SoftSynth.samples + nCount

        ' Resize the sample data array preserving elements
        ReDim Preserve SampleData(0 To SoftSynth.samples - 1) As String
    End Sub


    ' Close the mixer - free all allocated resources
    Sub FinalizeMixer
        SndRawDone SoftSynth.qb64SoundPipe ' Sumbit whatever is remaining in the raw buffer for playback
        SndClose SoftSynth.qb64SoundPipe ' Close QB64 sound pipe
    End Sub


    ' This can be used to queue in silence effectively pausing playback
    Sub UpdateMixerSilence (nSamples As Unsigned Integer)
        Dim i As Unsigned Integer
        For i = 1 To nSamples
            SndRaw NULL, NULL, SoftSynth.qb64SoundPipe
        Next
    End Sub


    ' This should be called by code using the mixer at regular intervals
    ' All mixing calculations are done using floating-point math (it's 2022 :)
    Sub UpdateMixer (nSamples As Unsigned Integer)
        Dim As Long v, i, nSample, nPos, nVolume, nLength, isLooping, nLoopStart, nLoopEnd
        Dim As Single fPan, fPos, fSam, fPitch
        Dim As Byte bSam1, bSam2

        ' Allocate a temporary mixer buffer that will hold sample data for both channels
        ' This is conveniently zeroed by QB64, so that is nice. We don't have to do it
        ' Here 1 is the left channnel and 2 is the right channel
        Dim mixerBuffer(1 To 2, 1 To nSamples) As Single

        ' Set the active voice count to zero
        SoftSynth.activeVoices = 0

        ' We will iterate through each channel completely rather than jumping from channel to channel
        ' We are doing this because it is easier for the CPU to access adjacent memory rather than something far away
        ' Also because we do not have to fetch stuff from multiple arrays too many times
        For v = 0 To SoftSynth.voices - 1
            nSample = Voice(v).sample
            ' Only proceed if we have a valid sample number (>= 0)
            If nSample >= 0 Then
                ' Increment the active voices
                SoftSynth.activeVoices = SoftSynth.activeVoices + 1

                ' Get some values we need frequently during the mixing interation below
                ' Note that these do not change at all during the mixing process
                nVolume = Voice(v).volume
                fPan = Voice(v).panning
                fPitch = Voice(v).pitch
                isLooping = Voice(v).isLooping
                nLength = Voice(v).length
                nLoopStart = Voice(v).loopStart
                nLoopEnd = Voice(v).loopEnd

                ' Next we go through the channel sample data and mix it to our mixerBuffer
                For i = 1 To nSamples
                    ' We need these too many times
                    ' And this is inside the loop becuase "position" changes
                    fPos = Voice(v).position

                    ' Check if we are looping
                    If isLooping Then
                        ' Reset loop position if we reached the end of the loop
                        If fPos >= nLoopEnd Then
                            fPos = nLoopStart
                        End If
                    Else
                        ' For non-looping sample simply set the isplayed flag as false if we reached the end
                        If fPos >= nLength Then
                            StopVoice v
                            ' Exit the for mixing loop as we have no more samples to mix for this channel
                            Exit For
                        End If
                    End If

                    ' We don't want anything below 0
                    If fPos < 0 Then fPos = 0

                    ' Samples are stored in a string and strings are 1 based
                    If SoftSynth.useHQMixer Then
                        ' Apply interpolation
                        nPos = Fix(fPos)
                        bSam1 = Asc(SampleData(nSample), 1 + nPos) ' This will convert the unsigned byte (the way it is stored) to signed byte
                        bSam2 = Asc(SampleData(nSample), 2 + nPos) ' This will convert the unsigned byte (the way it is stored) to signed byte
                        fSam = bSam1 + (bSam2 - bSam1) * (fPos - nPos)
                    Else
                        bSam1 = Asc(SampleData(nSample), 1 + fPos) ' This will convert the unsigned byte (the way it is stored) to signed byte
                        fSam = bSam1
                    End If

                    ' The following two lines mixes the sample and also does volume & stereo panning
                    ' The below expressions were simplified and rearranged to reduce the number of divisions
                    mixerBuffer(1, i) = mixerBuffer(1, i) + (fSam * nVolume * (SAMPLE_PAN_RIGHT - fPan)) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)
                    mixerBuffer(2, i) = mixerBuffer(2, i) + (fSam * nVolume * fPan) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)

                    ' Move to the next sample position based on the pitch
                    Voice(v).position = fPos + fPitch
                Next
            End If
        Next

        Dim As Single fsamLT, fsamRT
        ' Feed the samples to the QB64 sound pipe
        For i = 1 To nSamples
            ' Apply global volume and scale sample to QB64 sound pipe specs
            fSam = SoftSynth.volume / (256 * GLOBAL_VOLUME_MAX) ' TODO: 256? Is this right?
            fsamLT = mixerBuffer(1, i) * fSam
            fsamRT = mixerBuffer(2, i) * fSam

            ' Clip samples to QB64 range
            If fsamLT < -1 Then fsamLT = -1
            If fsamLT > 1 Then fsamLT = 1
            If fsamRT < -1 Then fsamRT = -1
            If fsamRT > 1 Then fsamRT = 1

            ' Feed the samples to the QB64 sound pipe
            SndRaw fsamLT, fsamRT, SoftSynth.qb64SoundPipe
        Next
    End Sub


    ' Stores a sample in the sample data array
    ' Note this will also add some silence samples at the end
    Sub StoreSample (nSample As Unsigned Byte, sData As String)
        ' Allocate 32 bytes more than needed for mixer runoff
        SampleData(nSample) = sData + String$(32, NULL)
    End Sub


    ' Set the volume for a voice (0 - 64)
    Sub SetVoiceVolume (nVoice As Unsigned Byte, nVolume As Integer)
        If nVolume < 0 Then
            Voice(nVoice).volume = 0
        ElseIf nVolume > SAMPLE_VOLUME_MAX Then
            Voice(nVoice).volume = SAMPLE_VOLUME_MAX
        Else
            Voice(nVoice).volume = nVolume
        End If
    End Sub


    ' Set panning for a voice (0 - 255)
    Sub SetVoicePanning (nVoice As Unsigned Byte, nPanning As Single)
        If nPanning < SAMPLE_PAN_LEFT Then
            Voice(nVoice).panning = SAMPLE_PAN_LEFT
        ElseIf nPanning > SAMPLE_PAN_RIGHT Then
            Voice(nVoice).panning = SAMPLE_PAN_RIGHT
        Else
            Voice(nVoice).panning = nPanning
        End If
    End Sub


    ' Set a frequency for a voice
    ' This will be responsible for correctly setting the mixer sample pitch
    Sub SetVoiceFrequency (nVoice As Unsigned Byte, nFrequency As Long)
        Voice(nVoice).pitch = nFrequency / SoftSynth.mixerRate
    End Sub


    ' Stops playback for a voice
    Sub StopVoice (nVoice As Unsigned Byte)
        Voice(nVoice).sample = -1
        Voice(nVoice).pitch = 0
        Voice(nVoice).volume = SAMPLE_VOLUME_MAX
        Voice(nVoice).position = 0
        Voice(nVoice).length = 0
        Voice(nVoice).isLooping = FALSE
        Voice(nVoice).loopStart = 0
        Voice(nVoice).loopEnd = 0
    End Sub


    ' Starts playback of a sample
    ' The sample will just play once
    ' This can be used to playback a sample from a particular offset
    Sub PlayVoice (nVoice As Unsigned Byte, nSample As Unsigned Byte, nStart As Unsigned Long, nEnd As Unsigned Long)
        Voice(nVoice).sample = nSample
        Voice(nVoice).position = nStart
        Voice(nVoice).length = nEnd
        Voice(nVoice).isLooping = FALSE
        Voice(nVoice).loopStart = nStart
        Voice(nVoice).loopEnd = nEnd
    End Sub

    ' Loops a sample
    ' The sample will loop forever until StopVoice or another PlayVoice or LoopVoice is used
    Sub LoopVoice (nVoice As Unsigned Byte, nSample As Unsigned Byte, nStart As Unsigned Long, nLoopStart As Unsigned Long, nLoopEnd As Unsigned Long)
        Voice(nVoice).sample = nSample
        Voice(nVoice).position = nStart
        Voice(nVoice).length = nLoopEnd
        Voice(nVoice).isLooping = TRUE
        Voice(nVoice).loopStart = nLoopStart
        Voice(nVoice).loopEnd = nLoopEnd
    End Sub

    ' Set the global volume for a voice (0 - 255)
    Sub SetGlobalVolume (nVolume As Integer)
        If nVolume < 0 Then
            SoftSynth.volume = 0
        ElseIf nVolume > GLOBAL_VOLUME_MAX Then
            SoftSynth.volume = GLOBAL_VOLUME_MAX
        Else
            SoftSynth.volume = nVolume
        End If
    End Sub


    ' Enables or disable HQ mixer
    Sub EnableHQMixer (nFlag As Byte)
        SoftSynth.useHQMixer = Not (nFlag = FALSE) ' This will accept all kinds of garbage :)
    End Sub
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------

