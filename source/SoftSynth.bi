'-----------------------------------------------------------------------------------------------------------------------
' Simple floating-point stereo PCM software synthesizer
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Math.bi'

$UNSTABLE:TYPEFIELDS

CONST SOFTSYNTH_VOICE_NO_SOUND = -1 ' used to unbind a sound from a voice
CONST SOFTSYNTH_VOICE_PLAY_FORWARD = 0 ' single-shot forward playback
CONST SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP = 1 ' forward-looping playback
CONST SOFTSYNTH_VOICE_VOLUME_MAX! = 1! ' maximum volume of any sample
CONST SOFTSYNTH_VOICE_VOLUME_MIN! = 0! ' minimum volume
CONST SOFTSYNTH_VOICE_PAN_LEFT! = -1! ' leftmost panning position
CONST SOFTSYNTH_VOICE_PAN_RIGHT! = 1! ' rightmost panning position
CONST SOFTSYNTH_VOICE_PAN_CENTER! = 0! ' center pan position
CONST SOFTSYNTH_GLOBAL_VOLUME_MAX! = 1! ' max global volume
CONST SOFTSYNTH_MASTER_VOLUME_MAX! = 1! ' max master volume
CONST SOFTSYNTH_SOUND_BUFFER_CHANNELS = 2 ' stereo
CONST SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE = _SIZE_OF_SINGLE ' 4 bytes (SINGLE)
CONST SOFTSYNTH_SOUND_BUFFER_FRAME_SIZE = SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE * SOFTSYNTH_SOUND_BUFFER_CHANNELS
CONST SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT! = 0.05! ' minimum buffered time before refill
CONST __SOFTSYNTH_QUARTER_PI! = _PI(0.25)
CONST __SOFTSYNTH_MULTIPLIER_32_TO_16! = 32768!
CONST __SOFTSYNTH_MULTIPLIER_32_TO_8! = 128!
CONST __SOFTSYNTH_MULTIPLIER_16_TO_32! = 1! / 32768!
CONST __SOFTSYNTH_MULTIPLIER_8_TO_32! = 1! / 128!

' A single mono sound stored as floating-point frames
TYPE __SoftSynthSoundType
    frames(0 TO 0) _DYNAMIC AS SINGLE ' mono fp32 sample frames, independently sized per sound
    length AS _UNSIGNED LONG ' number of valid frames
END TYPE

' A single playback voice with all its state
TYPE __SoftSynthVoiceType
    sound AS LONG ' index into sounds array, or SOFTSYNTH_VOICE_NO_SOUND
    frequency AS _UNSIGNED LONG ' playback frequency in Hz
    pitch AS SINGLE ' frequency / sampleRate — step rate through frames
    volume AS SINGLE ' voice volume (0.0 - 1.0)
    panPosition AS SINGLE ' stereo pan (-1.0 left, 0.0 center, 1.0 right)
    leftGain AS SINGLE ' left channel gain (computed from panPosition)
    rightGain AS SINGLE ' right channel gain (computed from panPosition)
    position AS SINGLE ' current fractional frame position in the sound buffer
    iPosition AS _UNSIGNED LONG ' integer part of position
    startPosition AS _UNSIGNED LONG ' loop start or playback start (in frames)
    endPosition AS _UNSIGNED LONG ' loop end or playback end (in frames)
    frame AS SINGLE ' current interpolated output frame
    oldFrame AS SINGLE ' previous frame (for smooth interpolation and anti-click)
    playMode AS LONG ' SOFTSYNTH_VOICE_PLAY_FORWARD or SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
END TYPE

' Main synthesizer state — holds all sounds and voices
TYPE __SoftSynthStateType
    sounds(0 TO 0) _DYNAMIC AS __SoftSynthSoundType ' managed sound slots
    voices(0 TO 0) _DYNAMIC AS __SoftSynthVoiceType ' managed voice slots
    sampleRate AS _UNSIGNED LONG ' mixer output sample rate
    activeVoices AS _UNSIGNED LONG ' count of currently active voices
    globalVolume AS SINGLE ' global volume multiplier (0.0 - 1.0)
    totalSounds AS LONG ' number of allocated sound slots
    totalVoices AS LONG ' number of allocated voice slots
    initialized AS _BYTE ' TRUE if initialized
END TYPE

' QB64 sound pipe management (separate from the synth engine)
TYPE __SoftSynthPipeType
    soundBufferFrames AS _UNSIGNED LONG ' size of the render buffer in frames
    soundBufferSamples AS _UNSIGNED LONG ' size of the render buffer in samples
    soundBufferBytes AS _UNSIGNED LONG ' size of the render buffer in bytes
    soundMasterVolume AS SINGLE ' QB64 sound pipe volume
    soundHandle AS LONG ' QB64 sound pipe handle
END TYPE

DIM __SoftSynth AS __SoftSynthStateType
DIM __SoftSynthPipe AS __SoftSynthPipeType
REDIM __SoftSynth_SoundBuffer(0 TO 0) AS SINGLE ' mixer buffer (stereo interleaved)

''' @brief Resets a voice structure to defaults (does NOT reset pan position).
''' @param voice Voice structure to reset.
SUB __SoftSynth_ResetVoice (voice AS __SoftSynthVoiceType)
    voice.sound = SOFTSYNTH_VOICE_NO_SOUND
    voice.volume = SOFTSYNTH_VOICE_VOLUME_MAX
    voice.frequency = 0
    voice.pitch = 0!
    voice.position = 0!
    voice.iPosition = 0
    voice.startPosition = 0
    voice.endPosition = 0
    voice.frame = 0!
    voice.oldFrame = 0!
    voice.playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
END SUB

''' @brief Computes pan gains for a voice using equal-power (-3 dB) pan law.
''' @param voice Voice structure to update.
''' @param pan Panning value from -1.0 (left) to 1.0 (right).
SUB __SoftSynth_SetPanPosition (voice AS __SoftSynthVoiceType, pan AS SINGLE)
    DIM p AS SINGLE
    DIM panMapped AS SINGLE

    p = _CLAMP(pan, SOFTSYNTH_VOICE_PAN_LEFT, SOFTSYNTH_VOICE_PAN_RIGHT)
    voice.panPosition = p

    ' Map [-1, 1] to [0, PI/2] then use cos/sin for equal-power panning
    panMapped = (p + 1!) * __SOFTSYNTH_QUARTER_PI
    voice.leftGain = COS(panMapped)
    voice.rightGain = SIN(panMapped)
END SUB

''' @brief Converts a byte count to audio sample frame count.
''' @param bytes Total number of bytes.
''' @param bytesPerSample Bytes per sample (1 for 8-bit, 2 for 16-bit, 4 for 32-bit).
''' @param channels Channel count (1 for mono, 2 for stereo).
''' @return Number of sample frames.
FUNCTION SoftSynth_ConvertBytesToFrames~& (bytes AS _UNSIGNED LONG, bytesPerSample AS _UNSIGNED _BYTE, channels AS _UNSIGNED _BYTE)
    IF bytesPerSample = 0 OR channels = 0 THEN
        SoftSynth_ConvertBytesToFrames = 0
    ELSE
        SoftSynth_ConvertBytesToFrames = bytes \ (CLNG(bytesPerSample) * CLNG(channels))
    END IF
END FUNCTION

''' @brief Checks whether the synthesizer engine is initialized.
''' @return _TRUE if initialized, _FALSE otherwise.
FUNCTION SoftSynth_IsInitialized%%
    SHARED __SoftSynth AS __SoftSynthStateType

    SoftSynth_IsInitialized = __SoftSynth.initialized
END FUNCTION

''' @brief Initializes the SoftSynth and allocates all required audio resources.
''' @return _TRUE on success, _FALSE on failure.
FUNCTION SoftSynth_Initialize%%
    SHARED __SoftSynth AS __SoftSynthStateType
    SHARED __SoftSynthPipe AS __SoftSynthPipeType
    SHARED __SoftSynth_SoundBuffer() AS SINGLE

    ' Return true if already initialized
    IF __SoftSynth.initialized THEN
        SoftSynth_Initialize = _TRUE
        EXIT FUNCTION
    END IF

    ' Allocate a QB64 sound pipe
    __SoftSynthPipe.soundHandle = _SNDOPENRAW
    IF __SoftSynthPipe.soundHandle < 1 THEN EXIT FUNCTION

    ' Initialize synth state
    __SoftSynth.sampleRate = _SNDRATE
    IF __SoftSynth.sampleRate = 0 THEN
        _SNDCLOSE __SoftSynthPipe.soundHandle
        EXIT FUNCTION
    END IF

    __SoftSynth.activeVoices = 0
    __SoftSynth.globalVolume = 1!
    __SoftSynth.totalSounds = 0
    __SoftSynth.totalVoices = 0

    __SoftSynthPipe.soundMasterVolume = SOFTSYNTH_MASTER_VOLUME_MAX

    ' Allocate a ~40 ms mixer buffer, rounded down to power of 2
    __SoftSynthPipe.soundBufferFrames = Math_RoundDownToPowerOf2(__SoftSynth.sampleRate * 0.04!)
    __SoftSynthPipe.soundBufferSamples = __SoftSynthPipe.soundBufferFrames * SOFTSYNTH_SOUND_BUFFER_CHANNELS
    __SoftSynthPipe.soundBufferBytes = __SoftSynthPipe.soundBufferSamples * SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE
    REDIM __SoftSynth_SoundBuffer(0 TO __SoftSynthPipe.soundBufferSamples - 1) AS SINGLE

    __SoftSynth.initialized = _TRUE
    SoftSynth_Initialize = _TRUE
END FUNCTION

''' @brief Finalizes the SoftSynth and frees all allocated sound and pipe resources.
SUB SoftSynth_Finalize
    SHARED __SoftSynth AS __SoftSynthStateType
    SHARED __SoftSynthPipe AS __SoftSynthPipeType

    IF __SoftSynth.initialized THEN
        _SNDRAWDONE __SoftSynthPipe.soundHandle
        _SNDCLOSE __SoftSynthPipe.soundHandle

        ' Release all sound data
        IF __SoftSynth.totalSounds > 0 THEN
            DIM i AS LONG
            FOR i = 0 TO __SoftSynth.totalSounds - 1
                ERASE __SoftSynth.sounds(i).frames
            NEXT
            ERASE __SoftSynth.sounds
        END IF

        ' Release all voices
        IF __SoftSynth.totalVoices > 0 THEN
            ERASE __SoftSynth.voices
        END IF

        __SoftSynth.totalSounds = 0
        __SoftSynth.totalVoices = 0
        __SoftSynth.initialized = _FALSE
    END IF
END SUB

''' @brief Gets the output sample rate of the synthesizer engine.
''' @return Sample rate in Hertz.
FUNCTION SoftSynth_GetSampleRate~&
    SHARED __SoftSynth AS __SoftSynthStateType

    SoftSynth_GetSampleRate = __SoftSynth.sampleRate
END FUNCTION

''' @brief Gets the total number of allocated sound slots.
''' @return Total sound slots count.
FUNCTION SoftSynth_GetTotalSounds~&
    SHARED __SoftSynth AS __SoftSynthStateType

    SoftSynth_GetTotalSounds = __SoftSynth.totalSounds
END FUNCTION

''' @brief Loads raw PCM audio sample data into a sound slot, converting to internal fp32 format.
''' @param snd Sound slot index (0-based).
''' @param buffer Raw audio sample data buffer.
''' @param bytesPerSample Bytes per sample (1 for 8-bit, 2 for 16-bit, 4 for 32-bit float).
''' @param channels Channel count (multi-channel sounds are flattened to mono).
SUB SoftSynth_LoadSound (snd AS LONG, buffer AS STRING, bytesPerSample AS _UNSIGNED _BYTE, channels AS _UNSIGNED _BYTE)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF snd < 0 THEN EXIT SUB
    IF channels < 1 THEN EXIT SUB
    IF bytesPerSample <> 1 AND bytesPerSample <> 2 AND bytesPerSample <> 4 THEN EXIT SUB

    DIM bytes AS _UNSIGNED LONG
    bytes = LEN(buffer)
    IF bytes = 0 THEN EXIT SUB

    ' Ensure sound slot exists — grow the sounds array if needed
    IF snd >= __SoftSynth.totalSounds THEN
        DIM newCount AS LONG
        newCount = snd + 1
        IF __SoftSynth.totalSounds = 0 THEN
            REDIM __SoftSynth.sounds(0 TO newCount - 1) AS __SOFTSYNTHSOUNDTYPE
        ELSE
            REDIM _PRESERVE __SoftSynth.sounds(0 TO newCount - 1) AS __SOFTSYNTHSOUNDTYPE
        END IF
        __SoftSynth.totalSounds = newCount
    END IF

    ' Calculate total frames (mono output)
    DIM totalFrames AS _UNSIGNED LONG
    totalFrames = SoftSynth_ConvertBytesToFrames(bytes, bytesPerSample, channels)
    IF totalFrames = 0 THEN EXIT SUB

    ' Allocate the frame buffer for this sound
    REDIM __SoftSynth.sounds(snd).frames(0 TO totalFrames - 1) AS SINGLE
    __SoftSynth.sounds(snd).length = totalFrames

    DIM bytePos AS _UNSIGNED LONG: bytePos = 1
    DIM f AS _UNSIGNED LONG
    DIM c AS _UNSIGNED _BYTE
    DIM monoSum AS SINGLE

    SELECT CASE bytesPerSample
        CASE 1 ' 8-bit signed
            FOR f = 0 TO totalFrames - 1
                monoSum = 0!
                FOR c = 1 TO channels
                    DIM rawByte AS _BYTE: rawByte = _CAST(_BYTE, ASC(buffer, bytePos))
                    monoSum = monoSum + CSNG(rawByte) * __SOFTSYNTH_MULTIPLIER_8_TO_32
                    bytePos = bytePos + 1
                NEXT
                __SoftSynth.sounds(snd).frames(f) = monoSum
            NEXT

        CASE 2 ' 16-bit signed (little-endian)
            FOR f = 0 TO totalFrames - 1
                monoSum = 0!
                FOR c = 1 TO channels
                    DIM rawInt AS INTEGER
                    rawInt = _CAST(INTEGER, _SHL(_CAST(LONG, ASC(buffer, bytePos + 1)), 8) OR ASC(buffer, bytePos))
                    monoSum = monoSum + CSNG(rawInt) * __SOFTSYNTH_MULTIPLIER_16_TO_32
                    bytePos = bytePos + 2
                NEXT
                __SoftSynth.sounds(snd).frames(f) = monoSum
            NEXT

        CASE 4 ' 32-bit float
            FOR f = 0 TO totalFrames - 1
                monoSum = 0!
                FOR c = 1 TO channels
                    DIM rawSingle AS SINGLE: rawSingle = CVS(MID$(buffer, bytePos, 4))
                    monoSum = monoSum + rawSingle
                    bytePos = bytePos + 4
                NEXT
                __SoftSynth.sounds(snd).frames(f) = monoSum
            NEXT
    END SELECT
END SUB

''' @brief Reads a single sample frame from a loaded sound as a 32-bit float.
''' @param snd Sound slot index.
''' @param position Sample frame index.
''' @return Normalized sample value (-1.0 to 1.0).
FUNCTION SoftSynth_PeekSoundFrameSingle! (snd AS LONG, position AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT FUNCTION
    IF snd < 0 OR snd >= __SoftSynth.totalSounds THEN EXIT FUNCTION
    IF position >= __SoftSynth.sounds(snd).length THEN EXIT FUNCTION

    SoftSynth_PeekSoundFrameSingle = __SoftSynth.sounds(snd).frames(position)
END FUNCTION

''' @brief Writes a single sample frame to a loaded sound as a 32-bit float.
''' @param snd Sound slot index.
''' @param position Sample frame index.
''' @param frame Normalized sample value (-1.0 to 1.0).
SUB SoftSynth_PokeSoundFrameSingle (snd AS LONG, position AS _UNSIGNED LONG, frame AS SINGLE)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF snd < 0 OR snd >= __SoftSynth.totalSounds THEN EXIT SUB
    IF position >= __SoftSynth.sounds(snd).length THEN EXIT SUB

    __SoftSynth.sounds(snd).frames(position) = frame
END SUB

''' @brief Reads a single sample frame from a loaded sound as a signed 16-bit integer.
''' @param snd Sound slot index.
''' @param position Sample frame index.
''' @return 16-bit signed sample value (-32768 to 32767).
FUNCTION SoftSynth_PeekSoundFrameInteger% (snd AS LONG, position AS _UNSIGNED LONG)
    SoftSynth_PeekSoundFrameInteger = _CAST(INTEGER, SoftSynth_PeekSoundFrameSingle(snd, position) * __SOFTSYNTH_MULTIPLIER_32_TO_16)
END FUNCTION

''' @brief Writes a single sample frame to a loaded sound as a signed 16-bit integer.
''' @param snd Sound slot index.
''' @param position Sample frame index.
''' @param frame 16-bit signed sample value (-32768 to 32767).
SUB SoftSynth_PokeSoundFrameInteger (snd AS LONG, position AS _UNSIGNED LONG, frame AS INTEGER)
    SoftSynth_PokeSoundFrameSingle snd, position, frame * __SOFTSYNTH_MULTIPLIER_16_TO_32
END SUB

''' @brief Reads a single sample frame from a loaded sound as a signed 8-bit byte.
''' @param snd Sound slot index.
''' @param position Sample frame index.
''' @return 8-bit signed sample value (-128 to 127).
FUNCTION SoftSynth_PeekSoundFrameByte%% (snd AS LONG, position AS _UNSIGNED LONG)
    SoftSynth_PeekSoundFrameByte = _CAST(_BYTE, SoftSynth_PeekSoundFrameSingle(snd, position) * __SOFTSYNTH_MULTIPLIER_32_TO_8)
END FUNCTION

''' @brief Writes a single sample frame to a loaded sound as a signed 8-bit byte.
''' @param snd Sound slot index.
''' @param position Sample frame index.
''' @param frame 8-bit signed sample value (-128 to 127).
SUB SoftSynth_PokeSoundFrameByte (snd AS LONG, position AS _UNSIGNED LONG, frame AS _BYTE)
    SoftSynth_PokeSoundFrameSingle snd, position, frame * __SOFTSYNTH_MULTIPLIER_8_TO_32
END SUB

''' @brief Gets the total number of allocated voice slots.
''' @return Number of voice slots.
FUNCTION SoftSynth_GetTotalVoices~&
    SHARED __SoftSynth AS __SoftSynthStateType

    SoftSynth_GetTotalVoices = __SoftSynth.totalVoices
END FUNCTION

''' @brief Sets total number of voice slots (re-allocates and clears all voices).
''' @param voices Number of voices to allocate.
SUB SoftSynth_SetTotalVoices (voices AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF voices < 1 THEN EXIT SUB

    REDIM __SoftSynth.voices(0 TO voices - 1) AS __SOFTSYNTHVOICETYPE
    __SoftSynth.totalVoices = voices

    ' Initialize all voices with defaults
    DIM v AS _UNSIGNED LONG
    FOR v = 0 TO voices - 1
        __SoftSynth_ResetVoice __SoftSynth.voices(v)
        __SoftSynth_SetPanPosition __SoftSynth.voices(v), SOFTSYNTH_VOICE_PAN_CENTER
    NEXT
END SUB

''' @brief Gets the active voice count updated during each audio mixing pass.
''' @return Number of active voices.
FUNCTION SoftSynth_GetActiveVoices~&
    SHARED __SoftSynth AS __SoftSynthStateType

    SoftSynth_GetActiveVoices = __SoftSynth.activeVoices
END FUNCTION

''' @brief Sets the volume for a specific voice.
''' @param voice Voice index (0-based).
''' @param volume Volume level (0.0 to 1.0).
SUB SoftSynth_SetVoiceVolume (voice AS _UNSIGNED LONG, volume AS SINGLE)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF voice >= __SoftSynth.totalVoices THEN EXIT SUB

    __SoftSynth.voices(voice).volume = _CLAMP(volume, SOFTSYNTH_VOICE_VOLUME_MIN, SOFTSYNTH_VOICE_VOLUME_MAX)
END SUB

''' @brief Gets the volume level of a voice.
''' @param voice Voice index (0-based).
''' @return Voice volume level (0.0 to 1.0).
FUNCTION SoftSynth_GetVoiceVolume! (voice AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT FUNCTION
    IF voice >= __SoftSynth.totalVoices THEN EXIT FUNCTION

    SoftSynth_GetVoiceVolume = __SoftSynth.voices(voice).volume
END FUNCTION

''' @brief Sets the stereo pan position for a voice.
''' @param voice Voice index (0-based).
''' @param balance Panning balance from -1.0 (left) to 1.0 (right).
SUB SoftSynth_SetVoiceBalance (voice AS _UNSIGNED LONG, balance AS SINGLE)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF voice >= __SoftSynth.totalVoices THEN EXIT SUB

    __SoftSynth_SetPanPosition __SoftSynth.voices(voice), balance
END SUB

''' @brief Gets the current stereo pan position of a voice.
''' @param voice Voice index (0-based).
''' @return Pan position from -1.0 (left) to 1.0 (right).
FUNCTION SoftSynth_GetVoiceBalance! (voice AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT FUNCTION
    IF voice >= __SoftSynth.totalVoices THEN EXIT FUNCTION

    SoftSynth_GetVoiceBalance = __SoftSynth.voices(voice).panPosition
END FUNCTION

''' @brief Sets the playback frequency of a voice in Hertz.
''' @param voice Voice index (0-based).
''' @param frequency Playback frequency in Hertz.
SUB SoftSynth_SetVoiceFrequency (voice AS _UNSIGNED LONG, frequency AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF voice >= __SoftSynth.totalVoices THEN EXIT SUB
    IF frequency = 0 THEN EXIT SUB

    __SoftSynth.voices(voice).frequency = frequency
    __SoftSynth.voices(voice).pitch = CSNG(frequency) / CSNG(__SoftSynth.sampleRate)
END SUB

''' @brief Gets the current playback frequency of a voice in Hertz.
''' @return Playback frequency in Hertz.
FUNCTION SoftSynth_GetVoiceFrequency~& (voice AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT FUNCTION
    IF voice >= __SoftSynth.totalVoices THEN EXIT FUNCTION

    SoftSynth_GetVoiceFrequency = __SoftSynth.voices(voice).frequency
END FUNCTION

''' @brief Stops playback on a voice and unbinds its sound.
''' @param voice Voice index (0-based).
SUB SoftSynth_StopVoice (voice AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF voice >= __SoftSynth.totalVoices THEN EXIT SUB

    __SoftSynth_ResetVoice __SoftSynth.voices(voice)
END SUB

''' @brief Starts playback of a sound on a voice with specified parameters and loop points.
''' @param voice Voice index (0-based).
''' @param snd Sound slot index.
''' @param position Initial playback position in sample frames.
''' @param mode Loop mode (SOFTSYNTH_VOICE_PLAY_FORWARD or SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP).
''' @param startPosition Loop start position in sample frames.
''' @param endPosition Loop end position in sample frames.
SUB SoftSynth_PlayVoice (voice AS _UNSIGNED LONG, snd AS LONG, position AS _UNSIGNED LONG, mode AS LONG, startPosition AS _UNSIGNED LONG, endPosition AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF voice >= __SoftSynth.totalVoices THEN EXIT SUB
    IF snd < 0 OR snd >= __SoftSynth.totalSounds THEN EXIT SUB

    DIM v AS __SoftSynthVoiceType
    v = __SoftSynth.voices(voice) ' work on local copy to preserve pan

    IF mode < SOFTSYNTH_VOICE_PLAY_FORWARD OR mode > SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP THEN
        v.playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
    ELSE
        v.playMode = mode
    END IF

    v.position = CSNG(position)
    v.iPosition = position
    v.startPosition = startPosition
    v.endPosition = endPosition
    v.sound = snd

    ' Pre-fetch initial frames to avoid clicks/pops at start
    IF position < __SoftSynth.sounds(snd).length THEN
        v.frame = __SoftSynth.sounds(snd).frames(position)
        v.oldFrame = v.frame
    ELSE
        v.frame = 0!
        v.oldFrame = 0!
    END IF

    __SoftSynth.voices(voice) = v
END SUB

''' @brief Sets the global volume multiplier applied across all voices.
''' @param volume Global volume level (0.0 to 1.0).
SUB SoftSynth_SetGlobalVolume (volume AS SINGLE)
    SHARED __SoftSynth AS __SoftSynthStateType

    __SoftSynth.globalVolume = _CLAMP(volume, 0!, SOFTSYNTH_GLOBAL_VOLUME_MAX)
END SUB

''' @brief Gets the current global software volume level.
''' @return Global volume level (0.0 to 1.0).
FUNCTION SoftSynth_GetGlobalVolume!
    SHARED __SoftSynth AS __SoftSynthStateType

    SoftSynth_GetGlobalVolume = __SoftSynth.globalVolume
END FUNCTION

''' @brief Sets the master sound pipe volume via the QB64 audio engine.
''' @param volume Master volume level (0.0 to 1.0).
SUB SoftSynth_SetMasterVolume (volume AS SINGLE)
    SHARED __SoftSynthPipe AS __SoftSynthPipeType

    __SoftSynthPipe.soundMasterVolume = _CLAMP(volume, 0!, SOFTSYNTH_MASTER_VOLUME_MAX)
    _SNDVOL __SoftSynthPipe.soundHandle, __SoftSynthPipe.soundMasterVolume
END SUB

''' @brief Gets the master sound pipe volume level.
''' @return Master volume level (0.0 to 1.0).
FUNCTION SoftSynth_GetMasterVolume!
    SHARED __SoftSynthPipe AS __SoftSynthPipeType

    SoftSynth_GetMasterVolume = __SoftSynthPipe.soundMasterVolume
END FUNCTION

''' @brief Gets the amount of queued unplayed audio time remaining in the sound pipe.
''' @return Remaining buffered audio duration in seconds.
FUNCTION SoftSynth_GetBufferedSoundTime#
    SHARED __SoftSynthPipe AS __SoftSynthPipeType

    SoftSynth_GetBufferedSoundTime = _SNDRAWLEN(__SoftSynthPipe.soundHandle)
END FUNCTION


''' @brief Mixes all active voices into the provided stereo interleaved SINGLE buffer.
''' @param buffer() Output stereo interleaved SINGLE buffer.
''' @param frames Number of sample frames to render.
SUB __SoftSynth_Update (buffer() AS SINGLE, frames AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType

    IF NOT __SoftSynth.initialized THEN EXIT SUB
    IF frames = 0 THEN EXIT SUB
    IF __SoftSynth.totalVoices = 0 THEN EXIT SUB

    DIM totalSamples AS _UNSIGNED LONG: totalSamples = frames * SOFTSYNTH_SOUND_BUFFER_CHANNELS

    ' Reset active voice counter
    __SoftSynth.activeVoices = 0

    ' Iterate through each voice completely
    DIM v AS _UNSIGNED LONG
    FOR v = 0 TO __SoftSynth.totalVoices - 1
        IF __SoftSynth.voices(v).sound = SOFTSYNTH_VOICE_NO_SOUND THEN _CONTINUE

        DIM sndIdx AS LONG: sndIdx = __SoftSynth.voices(v).sound
        IF sndIdx < 0 OR sndIdx >= __SoftSynth.totalSounds THEN
            __SoftSynth.voices(v).sound = SOFTSYNTH_VOICE_NO_SOUND
            _CONTINUE
        END IF

        DIM sndLen AS _UNSIGNED LONG: sndLen = __SoftSynth.sounds(sndIdx).length
        IF sndLen = 0 THEN
            __SoftSynth.voices(v).sound = SOFTSYNTH_VOICE_NO_SOUND
            _CONTINUE
        END IF

        __SoftSynth.activeVoices = __SoftSynth.activeVoices + 1

        DIM voicePos AS SINGLE: voicePos = __SoftSynth.voices(v).position
        DIM voiceIPos AS _UNSIGNED LONG: voiceIPos = __SoftSynth.voices(v).iPosition
        DIM voiceFrame AS SINGLE: voiceFrame = __SoftSynth.voices(v).frame
        DIM voiceOldFrame AS SINGLE: voiceOldFrame = __SoftSynth.voices(v).oldFrame
        DIM voicePitch AS SINGLE: voicePitch = __SoftSynth.voices(v).pitch
        DIM voiceVol AS SINGLE: voiceVol = __SoftSynth.voices(v).volume
        DIM voiceLGain AS SINGLE: voiceLGain = __SoftSynth.voices(v).leftGain
        DIM voiceRGain AS SINGLE: voiceRGain = __SoftSynth.voices(v).rightGain
        DIM voiceStartPos AS _UNSIGNED LONG: voiceStartPos = __SoftSynth.voices(v).startPosition
        DIM voiceEndPos AS _UNSIGNED LONG: voiceEndPos = __SoftSynth.voices(v).endPosition
        DIM voiceMode AS LONG: voiceMode = __SoftSynth.voices(v).playMode
        DIM voiceSound AS LONG: voiceSound = sndIdx

        DIM outIdx AS _UNSIGNED LONG: outIdx = 0

        DIM s AS _UNSIGNED LONG
        FOR s = 0 TO frames - 1
            IF voicePos > CSNG(voiceEndPos) THEN
                IF voiceMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP THEN
                    voicePos = CSNG(voiceStartPos) + (voicePos - CSNG(voiceEndPos))
                ELSE
                    voiceSound = SOFTSYNTH_VOICE_NO_SOUND
                    EXIT FOR
                END IF
            END IF

            DIM curIPos AS _UNSIGNED LONG: curIPos = _CAST(_UNSIGNED LONG, voicePos)
            IF curIPos <> voiceIPos THEN
                voiceOldFrame = voiceFrame
                voiceIPos = curIPos
                IF curIPos < sndLen THEN
                    voiceFrame = __SoftSynth.sounds(sndIdx).frames(curIPos)
                END IF
            END IF

            DIM outFrame AS SINGLE
            outFrame = (voiceOldFrame + (voiceFrame - voiceOldFrame) * (voicePos - CSNG(voiceIPos))) * voiceVol

            voicePos = voicePos + voicePitch

            buffer(outIdx) = buffer(outIdx) + outFrame * voiceLGain
            buffer(outIdx + 1) = buffer(outIdx + 1) + outFrame * voiceRGain
            outIdx = outIdx + 2
        NEXT

        __SoftSynth.voices(v).sound = voiceSound
        __SoftSynth.voices(v).position = voicePos
        __SoftSynth.voices(v).iPosition = voiceIPos
        __SoftSynth.voices(v).frame = voiceFrame
        __SoftSynth.voices(v).oldFrame = voiceOldFrame
    NEXT

    ' Apply global volume if not 1.0
    IF __SoftSynth.globalVolume <> 1! THEN
        DIM gVol AS SINGLE: gVol = __SoftSynth.globalVolume
        DIM si AS _UNSIGNED LONG
        FOR si = 0 TO totalSamples - 1
            buffer(si) = buffer(si) * gVol
        NEXT
    END IF
END SUB

''' @brief Renders audio frames and streams them to the QB64 raw sound pipe.
''' @param frames Number of frames to render and push.
SUB SoftSynth_Update (frames AS _UNSIGNED LONG)
    SHARED __SoftSynth AS __SoftSynthStateType
    SHARED __SoftSynthPipe AS __SoftSynthPipeType
    SHARED __SoftSynth_SoundBuffer() AS SINGLE

    IF NOT __SoftSynth.initialized THEN EXIT SUB

    ' Resize buffer if frame count changed
    IF __SoftSynthPipe.soundBufferFrames <> frames THEN
        __SoftSynthPipe.soundBufferFrames = frames
        __SoftSynthPipe.soundBufferSamples = frames * SOFTSYNTH_SOUND_BUFFER_CHANNELS
        __SoftSynthPipe.soundBufferBytes = __SoftSynthPipe.soundBufferSamples * SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE
        REDIM __SoftSynth_SoundBuffer(0 TO __SoftSynthPipe.soundBufferSamples - 1) AS SINGLE
    ELSE
        ' Zero the buffer before mixing
        DIM i AS _UNSIGNED LONG
        FOR i = 0 TO __SoftSynthPipe.soundBufferSamples - 1
            __SoftSynth_SoundBuffer(i) = 0!
        NEXT
    END IF

    ' Render samples into the buffer
    __SoftSynth_Update __SoftSynth_SoundBuffer(), frames

    ' Feed the rendered samples to the QB64 sound pipe
    _SNDRAWBATCH __SoftSynth_SoundBuffer(), SOFTSYNTH_SOUND_BUFFER_CHANNELS, __SoftSynthPipe.soundHandle
END SUB
