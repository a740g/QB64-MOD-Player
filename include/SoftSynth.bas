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
        Shared SoftSynth As SoftSynthType
        Shared Voice() As VoiceType

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
        Shared SoftSynth As SoftSynthType
        Shared SampleData() As String

        ' Save the number of samples
        SoftSynth.samples = nSamples

        ' Resize the sample data array
        ReDim SampleData(0 To nSamples - 1) As String
    End Sub


    ' Close the mixer - free all allocated resources
    Sub FinalizeMixer
        Shared SoftSynth As SoftSynthType

        SndRawDone SoftSynth.soundHandle ' Sumbit whatever is remaining in the raw buffer for playback
        SndClose SoftSynth.soundHandle ' Close QB64 sound pipe
    End Sub

    ' Returns true if more samples needs to be mixed
    Function NeedsSoundRefill%%
        $Checking:Off
        Shared SoftSynth As SoftSynthType

        NeedsSoundRefill = (SndRawLen(SoftSynth.soundHandle) < SOUND_TIME_MIN)
        $Checking:On
    End Function

    ' This should be called by code using the mixer at regular intervals
    ' All mixing calculations are done using floating-point math (it's 2022 :)
    Sub UpdateMixer (nSamples As Unsigned Integer)
        $Checking:Off
        Shared SoftSynth As SoftSynthType
        Shared SampleData() As String
        Shared Voice() As VoiceType
        Shared MixerBufferLeft() As Single
        Shared MixerBufferRight() As Single

        Dim As Long v, s, nSample, nPos, nPlayType, sLen
        Dim As Single fVolume, fPan, fPitch, fPos, fStartPos, fEndPos, fSam
        Dim As Byte bSam1, bSam2

        ' Reallocate the mixer buffers that will hold sample data for both channels
        ' This is conveniently zeroed by QB64, so that is nice. We don't have to do it
        ' Here 0 is the left channnel and 1 is the right channel
        ReDim MixerBufferLeft(0 To nSamples - 1) As Single
        ReDim MixerBufferRight(0 To nSamples - 1) As Single

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
                sLen = Len(SampleData(nSample)) ' real sample length

                ' Next we go through the channel sample data and mix it to our mixerBuffer
                For s = 0 To nSamples - 1
                    ' We need these too many times
                    ' And this is inside the loop because "position" changes
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
                    If SoftSynth.useHQMixer And fPos + 2 <= sLen Then
                        ' Apply interpolation
                        nPos = Fix(fPos)
                        bSam1 = Asc(SampleData(nSample), 1 + nPos) ' This will convert the unsigned byte (the way it is stored) to signed byte
                        bSam2 = Asc(SampleData(nSample), 2 + nPos) ' This will convert the unsigned byte (the way it is stored) to signed byte
                        fSam = bSam1 + (bSam2 - bSam1) * (fPos - nPos)
                    Else
                        If fPos + 1 <= sLen Then
                            bSam1 = Asc(SampleData(nSample), 1 + fPos) ' This will convert the unsigned byte (the way it is stored) to signed byte
                            fSam = bSam1
                        Else
                            fSam = 0
                        End If
                    End If

                    ' The following two lines mixes the sample and also does volume & stereo panning
                    ' The below expressions were simplified and rearranged to reduce the number of divisions. Divisions are slow
                    MixerBufferLeft(s) = MixerBufferLeft(s) + (fSam * fVolume * (SAMPLE_PAN_RIGHT - fPan)) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)
                    MixerBufferRight(s) = MixerBufferRight(s) + (fSam * fVolume * fPan) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)

                    ' Move to the next sample position based on the pitch
                    Voice(v).position = fPos + fPitch
                Next
            End If
        Next

        ' Feed the samples to the QB64 sound pipe
        For s = 0 To nSamples - 1
            ' Apply global volume and scale sample to FP32 sample spec.
            fSam = SoftSynth.volume / (128 * GLOBAL_VOLUME_MAX)
            MixerBufferLeft(s) = MixerBufferLeft(s) * fSam
            MixerBufferRight(s) = MixerBufferRight(s) * fSam

            ' We do not clip samples anymore because miniaudio does that for us. It makes no sense to clip samples twice
            ' Obviously, this means that the quality of OpenAL version will suffer. But that's ok, it is on it's way to sunset :)

            ' Feed the samples to the QB64 sound pipe
            SndRaw MixerBufferLeft(s), MixerBufferRight(s), SoftSynth.soundHandle
        Next
        $Checking:On
    End Sub


    ' Stores a sample in the sample data array. This will add some silence samples at the end
    ' If the sample is looping then it will anti-click by copying a couple of samples from the beginning to the end of the loop
    Sub LoadSample (nSample As Unsigned Byte, sData As String, isLooping As Byte, nLoopStart As Long, nLoopEnd As Long)
        Shared SampleData() As String

        Dim i As Long
        If nLoopEnd >= Len(sData) Then i = 32 + nLoopEnd - Len(sData) Else i = 32 ' We allocate 32 samples extra (minimum)
        SampleData(nSample) = sData + String$(i, NULL)

        ' If the sample is looping then make it anti-click by copying a few samples from loop start to loop end
        If isLooping Then
            ' We'll just copy 4 samples
            For i = 1 To 4
                Asc(SampleData(nSample), nLoopEnd + i) = Asc(SampleData(nSample), nLoopStart + i)
            Next
        End If
    End Sub


    ' Get a sample value for a sample from position
    Function PeekSample%% (nSample As Unsigned Byte, nPosition As Long)
        $Checking:Off
        Shared SampleData() As String

        PeekSample = Asc(SampleData(nSample), 1 + nPosition)
        $Checking:On
    End Function


    ' Writes a sample value to a sample at position
    ' Don't worry about the nValue being unsigned. Just feed signed 8-bit sample values to it
    ' It's unsigned to prevent Asc from throwing up XD
    Sub PokeSample (nSample As Unsigned Byte, nPosition As Long, nValue As Unsigned Byte)
        $Checking:Off
        Shared SampleData() As String

        Asc(SampleData(nSample), 1 + nPosition) = nValue
        $Checking:On
    End Sub


    ' Set the volume for a voice (0 - 64)
    Sub SetVoiceVolume (nVoice As Unsigned Byte, nVolume As Single)
        $Checking:Off
        Shared Voice() As VoiceType

        If nVolume < 0 Then
            Voice(nVoice).volume = 0
        ElseIf nVolume > SAMPLE_VOLUME_MAX Then
            Voice(nVoice).volume = SAMPLE_VOLUME_MAX
        Else
            Voice(nVoice).volume = nVolume
        End If
        $Checking:On
    End Sub


    ' Set panning for a voice (0 - 255)
    Sub SetVoicePanning (nVoice As Unsigned Byte, nPanning As Single)
        $Checking:Off
        Shared Voice() As VoiceType

        If nPanning < SAMPLE_PAN_LEFT Then
            Voice(nVoice).panning = SAMPLE_PAN_LEFT
        ElseIf nPanning > SAMPLE_PAN_RIGHT Then
            Voice(nVoice).panning = SAMPLE_PAN_RIGHT
        Else
            Voice(nVoice).panning = nPanning
        End If
        $Checking:On
    End Sub


    ' Set a frequency for a voice
    ' This will be responsible for correctly setting the mixer sample pitch
    Sub SetVoiceFrequency (nVoice As Unsigned Byte, nFrequency As Single)
        $Checking:Off
        Shared SoftSynth As SoftSynthType
        Shared Voice() As VoiceType

        Voice(nVoice).pitch = nFrequency / SoftSynth.mixerRate
        $Checking:On
    End Sub


    ' Stops playback for a voice
    Sub StopVoice (nVoice As Unsigned Byte)
        $Checking:Off
        Shared Voice() As VoiceType

        Voice(nVoice).sample = -1
        Voice(nVoice).volume = SAMPLE_VOLUME_MAX
        ' Voice(nVoice).panning is intentionally left out to respect the pan positions set by the loader
        Voice(nVoice).pitch = 0
        Voice(nVoice).position = 0
        Voice(nVoice).playType = SAMPLE_PLAY_SINGLE
        Voice(nVoice).startPosition = 0
        Voice(nVoice).endPosition = 0
        $Checking:On
    End Sub


    ' Starts playback of a sample
    ' This can be used to playback a sample from a particular offset or loop the sample
    Sub PlayVoice (nVoice As Unsigned Byte, nSample As Unsigned Byte, nPosition As Single, nPlayType As Unsigned Byte, nStart As Single, nEnd As Single)
        $Checking:Off
        Shared Voice() As VoiceType

        Voice(nVoice).sample = nSample
        Voice(nVoice).position = nPosition
        Voice(nVoice).playType = nPlayType
        Voice(nVoice).startPosition = nStart
        Voice(nVoice).endPosition = nEnd
        $Checking:On
    End Sub

    ' Set the global volume for a voice (0 - 255)
    Sub SetGlobalVolume (nVolume As Single)
        Shared SoftSynth As SoftSynthType

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
        Shared SoftSynth As SoftSynthType

        SoftSynth.useHQMixer = (nFlag <> FALSE) ' This will accept all kinds of garbage :)
    End Sub
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------

