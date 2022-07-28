'---------------------------------------------------------------------------------------------------------
' A really simple sample-based software synthesizer
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'./SoftSynth.bi'
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
        SoftSynth.soundHandle = SndOpenRaw

        ' Reset the global volume
        SoftSynth.volume = GLOBAL_VOLUME_MAX

        Dim i As Unsigned Byte

        ' Set all voice defaults
        For i = 0 To nVoices - 1
            Voice(i).sample = -1
            Voice(i).volume = SAMPLE_VOLUME_MAX
            Voice(i).panning = SAMPLE_PAN_CENTER
            Voice(i).pitch = 0
            Voice(i).position = 0
            Voice(i).playType = SAMPLE_PLAY_SINGLE
            Voice(i).startPosition = 0
            Voice(i).endPosition = 0
        Next
    End Sub


    ' This initialized the sample manager
    ' All previous samples will be lost!
    Sub InitializeSampleManager (nSamples As Unsigned Byte)
        ' Save the number of samples
        SoftSynth.samples = nSamples

        ' Resize the sample data array
        ReDim SampleData(0 To nSamples - 1) As String
    End Sub


    ' Close the mixer - free all allocated resources
    Sub FinalizeMixer
        SndRawDone SoftSynth.soundHandle ' Sumbit whatever is remaining in the raw buffer for playback
        SndClose SoftSynth.soundHandle ' Close QB64 sound pipe
    End Sub

    ' Returns true if more samples needs to be mixed
    Function NeedsSoundRefill%%
        NeedsSoundRefill = (SndRawLen(SoftSynth.soundHandle) < SOUND_TIME_MIN)
    End Function

    ' This should be called by code using the mixer at regular intervals
    ' All mixing calculations are done using floating-point math (it's 2022 :)
    Sub UpdateMixer (nSamples As Unsigned Integer)
        Dim As Long v, s, nSample, nPos, nPlayType
        Dim As Single fVolume, fPan, fPitch, fPos, fStartPos, fEndPos, fSam
        Dim As Byte bSam1, bSam2

        ' Reallocate the mixer buffer that will hold sample data for both channels
        ' This is conveniently zeroed by QB64, so that is nice. We don't have to do it
        ' Here 1 is the left channnel and 2 is the right channel
        ReDim MixerBuffer(1 To MIXER_CHANNELS, 1 To nSamples) As Single

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
                fVolume = Voice(v).volume
                fPan = Voice(v).panning
                fPitch = Voice(v).pitch
                nPlayType = Voice(v).playType
                fStartPos = Voice(v).startPosition
                fEndPos = Voice(v).endPosition

                ' Next we go through the channel sample data and mix it to our mixerBuffer
                For s = 1 To nSamples
                    ' We need these too many times
                    ' And this is inside the loop becuase "position" changes
                    fPos = Voice(v).position

                    ' Check if we are looping
                    If nPlayType = SAMPLE_PLAY_SINGLE Then
                        ' For non-looping sample simply set the isplayed flag as false if we reached the end
                        If fPos >= fEndPos Then
                            StopVoice v
                            ' Exit the for mixing loop as we have no more samples to mix for this channel
                            Exit For
                        End If
                    Else
                        ' Reset loop position if we reached the end of the loop
                        If fPos >= fEndPos Then
                            fPos = fStartPos
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
                    MixerBuffer(1, s) = MixerBuffer(1, s) + (fSam * fVolume * (SAMPLE_PAN_RIGHT - fPan)) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)
                    MixerBuffer(2, s) = MixerBuffer(2, s) + (fSam * fVolume * fPan) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)

                    ' Move to the next sample position based on the pitch
                    Voice(v).position = fPos + fPitch
                Next
            End If
        Next

        Dim As Single fsamLT, fsamRT
        ' Feed the samples to the QB64 sound pipe
        For s = 1 To nSamples
            ' Apply global volume and scale sample to FP32 sample spec.
            fSam = SoftSynth.volume / (128 * GLOBAL_VOLUME_MAX)
            fsamLT = MixerBuffer(1, s) * fSam
            fsamRT = MixerBuffer(2, s) * fSam

            ' Feed the samples to the QB64 sound pipe
            SndRaw fsamLT, fsamRT, SoftSynth.soundHandle
        Next
    End Sub


    ' Stores a sample in the sample data array
    ' Note this will also add some silence samples at the end
    ' TODO: LoadSample(nSample as Unsigned Byte, sData as string, nLength as long, nStart as long, nEnd as long, is16Bit as byte)
    '   Save more stuff like length, loop start and loop end
    '   If looping sample then anti-click by copying a couple of samples from the beginning to the end of the loop
    '   Convert all samples to 16-bit for internal use
    '   Samples will be stored using MEM
    '   Samples to be address using "sample unit" internally, i.e. 16-bits (integer) per sample unit
    Sub LoadSample (nSample As Unsigned Byte, sData As String)
        ' Allocate 32 bytes more than needed for mixer runoff
        SampleData(nSample) = sData + String$(32, NULL)
    End Sub


    ' Get a sample value for a sample from position
    'Function PeekSample% (nSample As Unsigned Byte, nPosition As Long)
    'End Function


    ' Writes a sample value to a sample at position
    'Sub PokeSample (nSample As Unsigned Byte, nPosition As Long, nValue As Integer)
    'End Sub


    ' Set the volume for a voice (0 - 64)
    Sub SetVoiceVolume (nVoice As Unsigned Byte, nVolume As Single)
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
    Sub SetVoiceFrequency (nVoice As Unsigned Byte, nFrequency As Single)
        Voice(nVoice).pitch = nFrequency / SoftSynth.mixerRate
    End Sub


    ' Stops playback for a voice
    Sub StopVoice (nVoice As Unsigned Byte)
        Voice(nVoice).sample = -1
        Voice(nVoice).volume = SAMPLE_VOLUME_MAX
        ' Voice(nVoice).panning is intentionally left out to respect the pan positions set by the loader
        Voice(nVoice).pitch = 0
        Voice(nVoice).position = 0
        Voice(nVoice).playType = SAMPLE_PLAY_SINGLE
        Voice(nVoice).startPosition = 0
        Voice(nVoice).endPosition = 0
    End Sub


    ' Starts playback of a sample
    ' This can be used to playback a sample from a particular offset or loop the sample
    Sub PlayVoice (nVoice As Unsigned Byte, nSample As Unsigned Byte, nPosition As Single, nPlayType As Unsigned Byte, nStart As Single, nEnd As Single)
        Voice(nVoice).sample = nSample
        Voice(nVoice).position = nPosition
        Voice(nVoice).playType = nPlayType
        Voice(nVoice).startPosition = nStart
        Voice(nVoice).endPosition = nEnd
    End Sub

    ' Set the global volume for a voice (0 - 255)
    Sub SetGlobalVolume (nVolume As Single)
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
        SoftSynth.useHQMixer = (nFlag <> FALSE) ' This will accept all kinds of garbage :)
    End Sub
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------

