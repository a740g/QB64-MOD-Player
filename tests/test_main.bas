'-----------------------------------------------------------------------------------------------------------------------
' QB64 MOD Player Test Suite
' Uses Catch.bi test framework for QB64-PE
'-----------------------------------------------------------------------------------------------------------------------

$LET TEST_STRICT = TRUE
$LET TEST_CONSOLE_ONLY = TRUE

'$INCLUDE:'../source/Catch.bi'
'$INCLUDE:'../source/File.bi'
'$INCLUDE:'../source/StringFile.bi'
'$INCLUDE:'../source/AudioConv.bi'
'$INCLUDE:'../source/SoftSynth.bi'
'$INCLUDE:'../source/AudioAnalyzer.bi'
'$INCLUDE:'../source/MODPlayer.bi'
'$INCLUDE:'../source/MODPlayer.bm'
'$INCLUDE:'../source/MODLoader.bi'
'$INCLUDE:'../source/S3MLoader.bi'
'$INCLUDE:'../source/MTMLoader.bi'
'$INCLUDE:'../source/FARLoader.bi'

''' @brief Tests for AudioConv.bi audio conversion functions.
SUB Test_AudioConv
    TEST_CASE_BEGIN "AudioConv: U8 to S8 in-place conversion"
    DIM s AS STRING: s = CHR$(0) + CHR$(128) + CHR$(255)
    AudioConv_ConvertU8ToS8 s
    TEST_CHECK ASC(s, 1) = 128, "U8(0) -> S8 byte &H80"
    TEST_CHECK ASC(s, 2) = 0, "U8(128) -> S8 byte 0"
    TEST_CHECK ASC(s, 3) = 127, "U8(255) -> S8 byte 127"

    ' Applying XOR &H80 again restores original unsigned values
    AudioConv_ConvertU8ToS8 s
    TEST_CHECK ASC(s, 1) = 0, "Second pass restores byte 0"
    TEST_CHECK ASC(s, 2) = 128, "Second pass restores byte 128"
    TEST_CHECK ASC(s, 3) = 255, "Second pass restores byte 255"
    TEST_CASE_END

    TEST_CASE_BEGIN "AudioConv: U16 to S16 in-place conversion"
    ' Two 16-bit little-endian samples: 0 and 32768 (&H8000)
    DIM u16 AS STRING: u16 = CHR$(0) + CHR$(0) + CHR$(0) + CHR$(128)
    AudioConv_ConvertU16ToS16 u16
    ' Sample 1: 0 (U16) -> high byte XOR &H80 = -32768 (S16)
    TEST_CHECK ASC(u16, 1) = 0, "Sample 1 low byte unchanged"
    TEST_CHECK ASC(u16, 2) = 128, "Sample 1 high byte toggled to 128"
    ' Sample 2: 32768 (U16) -> high byte 128 XOR 128 = 0 -> 0 (S16)
    TEST_CHECK ASC(u16, 3) = 0, "Sample 2 low byte unchanged"
    TEST_CHECK ASC(u16, 4) = 0, "Sample 2 high byte toggled to 0"

    ' Second pass restores
    AudioConv_ConvertU16ToS16 u16
    TEST_CHECK ASC(u16, 2) = 0, "Second pass restores Sample 1 high byte"
    TEST_CHECK ASC(u16, 4) = 128, "Second pass restores Sample 2 high byte"
    TEST_CASE_END

    TEST_CASE_BEGIN "AudioConv: Dual Mono to Stereo S8"
    ' 4-byte buffer: Left channel [10, 20], Right channel [30, 40]
    DIM mono8 AS STRING: mono8 = CHR$(10) + CHR$(20) + CHR$(30) + CHR$(40)
    DIM stereo8 AS STRING: stereo8 = AudioConv_ConvertDualMonoToStereoS8(mono8)
    TEST_REQUIRE LEN(stereo8) = 4, "Output length matches input length"
    TEST_CHECK ASC(stereo8, 1) = 10, "Frame 0 Left = 10"
    TEST_CHECK ASC(stereo8, 2) = 30, "Frame 0 Right = 30"
    TEST_CHECK ASC(stereo8, 3) = 20, "Frame 1 Left = 20"
    TEST_CHECK ASC(stereo8, 4) = 40, "Frame 1 Right = 40"
    TEST_CASE_END

    TEST_CASE_BEGIN "AudioConv: Dual Mono to Stereo S16"
    ' 8-byte buffer: Left = 2 words (L0, L1), Right = 2 words (R0, R1)
    ' L0 = (1, 2), L1 = (3, 4)
    ' R0 = (5, 6), R1 = (7, 8)
    DIM mono16 AS STRING
    mono16 = CHR$(1) + CHR$(2) + CHR$(3) + CHR$(4) + CHR$(5) + CHR$(6) + CHR$(7) + CHR$(8)
    DIM stereo16 AS STRING: stereo16 = AudioConv_ConvertDualMonoToStereoS16(mono16)
    TEST_REQUIRE LEN(stereo16) = 8, "Output length matches input length"
    ' Interleaved frames: (L0, R0), (L1, R1)
    TEST_CHECK ASC(stereo16, 1) = 1, "Frame 0 Left low"
    TEST_CHECK ASC(stereo16, 2) = 2, "Frame 0 Left high"
    TEST_CHECK ASC(stereo16, 3) = 5, "Frame 0 Right low"
    TEST_CHECK ASC(stereo16, 4) = 6, "Frame 0 Right high"
    TEST_CHECK ASC(stereo16, 5) = 3, "Frame 1 Left low"
    TEST_CHECK ASC(stereo16, 6) = 4, "Frame 1 Left high"
    TEST_CHECK ASC(stereo16, 7) = 7, "Frame 1 Right low"
    TEST_CHECK ASC(stereo16, 8) = 8, "Frame 1 Right high"
    TEST_CASE_END

    TEST_CASE_BEGIN "AudioConv: ADPCM4 to S8 decompression"
    DIM compTab AS STRING: compTab = SPACE$(16)
    DIM k AS LONG
    FOR k = 1 TO 16
        ASC(compTab, k) = k - 1 ' simple linear delta table: 0, 1, 2, ..., 15
    NEXT k

    ' Input 1 byte: lower nibble = 2, upper nibble = 3 -> raw byte = &H32
    DIM adpcmIn AS STRING: adpcmIn = CHR$(&H32)
    DIM adpcmOut AS STRING: adpcmOut = AudioConv_ConvertADPCM4ToS8(adpcmIn, compTab)
    TEST_REQUIRE LEN(adpcmOut) = 2, "1 ADPCM byte decodes to 2 signed 8-bit samples"
    ' Sample 1: delta 0 + table(2) = 2
    TEST_CHECK ASC(adpcmOut, 1) = 2, "Decoded sample 1 = 2"
    ' Sample 2: delta 2 + table(3) = 5
    TEST_CHECK ASC(adpcmOut, 2) = 5, "Decoded sample 2 = 5"
    TEST_CASE_END
END SUB

''' @brief Tests for SoftSynth.bi software synthesizer and mixer.
SUB Test_SoftSynth
    TEST_CASE_BEGIN "SoftSynth: Lifecycle and default state"
    DIM ctx AS SoftSynth
    TEST_CHECK_FALSE SoftSynth_IsInitialized(ctx), "Context uninitialized before SoftSynth_Initialize"

    TEST_REQUIRE SoftSynth_Initialize(ctx), "SoftSynth_Initialize should succeed"
    TEST_CHECK SoftSynth_IsInitialized(ctx), "Context initialized after SoftSynth_Initialize"
    TEST_CHECK SoftSynth_GetTotalSounds(ctx) = 0, "Default total sounds is 0"
    TEST_CHECK SoftSynth_GetActiveVoices(ctx) = 0, "Default active voices is 0"
    TEST_CHECK SoftSynth_GetSampleRate(ctx) > 0, "Default sample rate is positive"

    SoftSynth_Finalize ctx
    TEST_CHECK_FALSE SoftSynth_IsInitialized(ctx), "Context uninitialized after SoftSynth_Finalize"
    TEST_CASE_END

    TEST_CASE_BEGIN "SoftSynth: Frame conversion helper"
    TEST_CHECK SoftSynth_ConvertBytesToFrames(44100, 2, 2) = 11025, "44100 bytes of 16-bit stereo = 11025 frames"
    TEST_CHECK SoftSynth_ConvertBytesToFrames(100, 1, 1) = 100, "100 bytes of 8-bit mono = 100 frames"
    TEST_CHECK SoftSynth_ConvertBytesToFrames(0, 2, 2) = 0, "0 bytes = 0 frames"
    TEST_CHECK SoftSynth_ConvertBytesToFrames(100, 0, 1) = 0, "0 bytesPerSample returns 0"
    TEST_CHECK SoftSynth_ConvertBytesToFrames(100, 1, 0) = 0, "0 channels returns 0"
    TEST_CASE_END

    TEST_CASE_BEGIN "SoftSynth: Sound loading and frame peek/poke"
    DIM synth AS SoftSynth
    TEST_REQUIRE SoftSynth_Initialize(synth), "Initialize synth"

    ' Create 4 signed 8-bit mono PCM sample frames: 0, 64, -64 (192), 0
    DIM rawPcm AS STRING: rawPcm = CHR$(0) + CHR$(64) + CHR$(192) + CHR$(0)
    SoftSynth_LoadSound synth, 0, rawPcm, 1, 1
    TEST_CHECK SoftSynth_GetTotalSounds(synth) = 1, "Total sounds should now be 1"

    ' Peek signed byte frames
    TEST_CHECK SoftSynth_PeekSoundFrameByte(synth, 0, 0) = 0, "Frame 0 byte = 0"
    TEST_CHECK SoftSynth_PeekSoundFrameByte(synth, 0, 1) = 64, "Frame 1 byte = 64"
    TEST_CHECK SoftSynth_PeekSoundFrameByte(synth, 0, 2) = -64, "Frame 2 byte = -64"

    ' Peek normalized single (-1.0 to 1.0)
    TEST_CHECK SoftSynth_PeekSoundFrameSingle(synth, 0, 0) = 0!, "Frame 0 single = 0.0"
    TEST_CHECK ABS(SoftSynth_PeekSoundFrameSingle(synth, 0, 1) - (64! / 128!)) < 0.01!, "Frame 1 single ~ 0.5"

    ' Poke and re-peek
    SoftSynth_PokeSoundFrameByte synth, 0, 0, 32
    TEST_CHECK SoftSynth_PeekSoundFrameByte(synth, 0, 0) = 32, "Poked frame 0 byte = 32"

    SoftSynth_PokeSoundFrameSingle synth, 0, 0, 1.0!
    TEST_CHECK SoftSynth_PeekSoundFrameSingle(synth, 0, 0) = 1.0!, "Poked frame 0 single = 1.0"

    SoftSynth_Finalize synth
    TEST_CASE_END

    TEST_CASE_BEGIN "SoftSynth: Voices and playback parameters"
    DIM synth2 AS SoftSynth
    TEST_REQUIRE SoftSynth_Initialize(synth2), "Initialize synth2"

    SoftSynth_SetTotalVoices synth2, 8
    TEST_CHECK SoftSynth_GetTotalVoices(synth2) = 8, "Total voices set to 8"

    ' Test Master and Global volume
    SoftSynth_SetMasterVolume synth2, 0.75!
    TEST_CHECK ABS(SoftSynth_GetMasterVolume(synth2) - 0.75!) < 0.001!, "Master volume = 0.75"

    SoftSynth_SetGlobalVolume synth2, 0.5!
    TEST_CHECK ABS(SoftSynth_GetGlobalVolume(synth2) - 0.5!) < 0.001!, "Global volume = 0.5"

    ' Test Voice parameters
    SoftSynth_SetVoiceVolume synth2, 0, 0.8!
    TEST_CHECK ABS(SoftSynth_GetVoiceVolume(synth2, 0) - 0.8!) < 0.001!, "Voice 0 volume = 0.8"

    SoftSynth_SetVoiceBalance synth2, 0, -0.5!
    TEST_CHECK ABS(SoftSynth_GetVoiceBalance(synth2, 0) - (-0.5!)) < 0.001!, "Voice 0 balance = -0.5"

    SoftSynth_SetVoiceFrequency synth2, 0, 22050
    TEST_CHECK SoftSynth_GetVoiceFrequency(synth2, 0) = 22050, "Voice 0 frequency = 22050"

    ' Load a dummy sound and trigger voice
    DIM dummySnd AS STRING: dummySnd = STRING$(100, 0)
    SoftSynth_LoadSound synth2, 0, dummySnd, 1, 1
    SoftSynth_PlayVoice synth2, 0, 0, 0, SOFTSYNTH_VOICE_PLAY_FORWARD, 0, 100
    SoftSynth_Render synth2, 10
    SoftSynth_PushAudio synth2
    TEST_CHECK SoftSynth_GetActiveVoices(synth2) = 1, "Active voices should be 1 after play and update"

    SoftSynth_StopVoice synth2, 0
    SoftSynth_Render synth2, 10
    SoftSynth_PushAudio synth2
    TEST_CHECK SoftSynth_GetActiveVoices(synth2) = 0, "Active voices should be 0 after stop and update"

    SoftSynth_Finalize synth2
    TEST_CASE_END

    TEST_CASE_BEGIN "SoftSynth: Multi-instance context isolation"
    DIM ctxA AS SoftSynth, ctxB AS SoftSynth
    TEST_REQUIRE SoftSynth_Initialize(ctxA), "Initialize ctxA"
    TEST_REQUIRE SoftSynth_Initialize(ctxB), "Initialize ctxB"

    SoftSynth_SetMasterVolume ctxA, 0.25!
    SoftSynth_SetMasterVolume ctxB, 0.85!
    TEST_CHECK ABS(SoftSynth_GetMasterVolume(ctxA) - 0.25!) < 0.001!, "ctxA master volume is 0.25"
    TEST_CHECK ABS(SoftSynth_GetMasterVolume(ctxB) - 0.85!) < 0.001!, "ctxB master volume is 0.85"

    SoftSynth_SetTotalVoices ctxA, 4
    SoftSynth_SetTotalVoices ctxB, 16
    TEST_CHECK SoftSynth_GetTotalVoices(ctxA) = 4, "ctxA voice count = 4"
    TEST_CHECK SoftSynth_GetTotalVoices(ctxB) = 16, "ctxB voice count = 16"

    SoftSynth_Finalize ctxA
    TEST_CHECK_FALSE SoftSynth_IsInitialized(ctxA), "ctxA finalized"
    TEST_CHECK SoftSynth_IsInitialized(ctxB), "ctxB remains initialized"

    SoftSynth_Finalize ctxB
    TEST_CHECK_FALSE SoftSynth_IsInitialized(ctxB), "ctxB finalized"
    TEST_CASE_END
END SUB

''' @brief Tests for StringFile.bi in-memory file I/O operations.
SUB Test_StringFile
    TEST_CASE_BEGIN "StringFile: Write, Seek, and Read"
    DIM mf AS StringFile
    StringFile_Create mf, ""

    StringFile_WriteByte mf, 42
    StringFile_WriteInteger mf, 12345
    StringFile_WriteLong mf, 987654321
    StringFile_WriteString mf, "QB64"

    TEST_CHECK StringFile_GetSize(mf) = 1 + 2 + 4 + 4, "Total bytes written matches expected size"

    ' Seek back to start and read
    StringFile_Seek mf, 0
    TEST_CHECK StringFile_ReadByte(mf) = 42, "Read byte matches 42"
    TEST_CHECK StringFile_ReadInteger(mf) = 12345, "Read integer matches 12345"
    TEST_CHECK StringFile_ReadLong(mf) = 987654321, "Read long matches 987654321"
    TEST_CHECK StringFile_ReadString(mf, 4) = "QB64", "Read string matches 'QB64'"
    TEST_CHECK StringFile_IsEOF(mf), "StringFile should be at EOF"

    TEST_CASE_END

    TEST_CASE_BEGIN "StringFile: Resize and GetSize"
    DIM mf2 AS StringFile
    StringFile_Create mf2, "Hello World"
    TEST_CHECK StringFile_GetSize(mf2) = 11, "Initial size matches input string length"

    StringFile_Resize mf2, 20
    TEST_CHECK StringFile_GetSize(mf2) = 20, "Size after expansion is 20"

    StringFile_Resize mf2, 5
    TEST_CHECK StringFile_GetSize(mf2) = 5, "Size after truncation is 5"
    TEST_CASE_END
END SUB

''' @brief Tests for AudioAnalyzer.bi multi-instance audio spectrum analyzer.
SUB Test_AudioAnalyzer
    TEST_CASE_BEGIN "AudioAnalyzer: Lifecycle and initialization"
    DIM analyzer AS AudioAnalyzer
    TEST_CHECK_FALSE AudioAnalyzer_IsInitialized(analyzer), "Analyzer uninitialized before AudioAnalyzer_Initialize"

    TEST_REQUIRE AudioAnalyzer_Initialize(analyzer), "AudioAnalyzer_Initialize should succeed"
    TEST_CHECK AudioAnalyzer_IsInitialized(analyzer), "Analyzer initialized after AudioAnalyzer_Initialize"
    TEST_CHECK AudioAnalyzer_GetAverageIntensity(analyzer) = 0!, "Initial average intensity is 0"
    TEST_CHECK AudioAnalyzer_GetRMS(analyzer) = 0!, "Initial RMS is 0"
    TEST_CHECK AudioAnalyzer_GetPeakAmplitude(analyzer) = 0, "Initial peak amplitude is 0"
    TEST_CHECK AudioAnalyzer_GetPeakBin(analyzer) = 0, "Initial peak bin is 0"

    AudioAnalyzer_Finalize analyzer
    TEST_CHECK_FALSE AudioAnalyzer_IsInitialized(analyzer), "Analyzer uninitialized after AudioAnalyzer_Finalize"
    TEST_CASE_END

    TEST_CASE_BEGIN "AudioAnalyzer: FFT calculation, intensity, RMS and peak detection"
    DIM aa AS AudioAnalyzer
    DIM bitDepth AS LONG: bitDepth = 8 ' 256 samples
    DIM numSamples AS LONG: numSamples = _SHL(1, bitDepth) ' 256
    DIM halfSamples AS LONG: halfSamples = numSamples \ 2 ' 128
    REDIM amps(0 TO halfSamples - 1) AS _UNSIGNED INTEGER
    REDIM silence(0 TO numSamples - 1) AS SINGLE

    ' FFT on pure silence
    AudioAnalyzer_CalculateFFT aa, amps(), silence(), 0, 1, bitDepth
    TEST_CHECK AudioAnalyzer_GetAverageIntensity(aa) = 0!, "Silence has 0 average intensity"
    TEST_CHECK AudioAnalyzer_GetRMS(aa) = 0!, "Silence has 0 RMS level"
    TEST_CHECK AudioAnalyzer_GetPeakAmplitude(aa) = 0, "Silence produces 0 peak amplitude"
    TEST_CHECK amps(0) = 0, "Silence produces 0 amplitude at DC/bin 0"

    ' FFT on a constant DC signal 0.5
    REDIM dcSignal(0 TO numSamples - 1) AS SINGLE
    DIM k AS LONG
    FOR k = 0 TO numSamples - 1
        dcSignal(k) = 0.5!
    NEXT k

    AudioAnalyzer_CalculateFFT aa, amps(), dcSignal(), 0, 1, bitDepth
    TEST_CHECK ABS(AudioAnalyzer_GetAverageIntensity(aa) - 0.25!) < 0.001!, "Intensity of 0.5 amplitude signal is 0.25"
    TEST_CHECK ABS(AudioAnalyzer_GetRMS(aa) - 0.5!) < 0.001!, "RMS of 0.5 amplitude signal is 0.5"
    TEST_CHECK AudioAnalyzer_IsInitialized(aa), "Auto-initialized if called directly"
    TEST_CASE_END

    TEST_CASE_BEGIN "AudioAnalyzer: Safety bounds validation"
    DIM safeAa AS AudioAnalyzer
    TEST_REQUIRE AudioAnalyzer_Initialize(safeAa), "Init safeAa"
    REDIM smallAmps(0 TO 3) AS _UNSIGNED INTEGER
    REDIM testSignal(0 TO 255) AS SINGLE

    ' Bit depth exceeding AUDIO_ANALYZER_MAX_BIT_DEPTH
    AudioAnalyzer_CalculateFFT safeAa, smallAmps(), testSignal(), 0, 1, 15
    TEST_CHECK AudioAnalyzer_GetAverageIntensity(safeAa) = 0!, "Invalid bitDepth > 11 safely rejected"

    ' Bit depth < 1
    AudioAnalyzer_CalculateFFT safeAa, smallAmps(), testSignal(), 0, 1, 0
    TEST_CHECK AudioAnalyzer_GetAverageIntensity(safeAa) = 0!, "Invalid bitDepth < 1 safely rejected"

    ' Destination array too small for requested bit depth (8 requires 128 bins, only 4 provided)
    AudioAnalyzer_CalculateFFT safeAa, smallAmps(), testSignal(), 0, 1, 8
    TEST_CHECK AudioAnalyzer_GetAverageIntensity(safeAa) = 0!, "Undersized destination array safely rejected"

    AudioAnalyzer_Finalize safeAa
    TEST_CASE_END

    TEST_CASE_BEGIN "AudioAnalyzer: Multi-instance isolation"
    DIM aa1 AS AudioAnalyzer, aa2 AS AudioAnalyzer
    TEST_REQUIRE AudioAnalyzer_Initialize(aa1), "Init aa1"
    TEST_REQUIRE AudioAnalyzer_Initialize(aa2), "Init aa2"

    REDIM amps1(0 TO 63) AS _UNSIGNED INTEGER
    REDIM amps2(0 TO 63) AS _UNSIGNED INTEGER
    REDIM sig1(0 TO 127) AS SINGLE
    REDIM sig2(0 TO 127) AS SINGLE

    ' sig1 has silence, sig2 has an alternating +/-1.0 AC square wave
    FOR k = 0 TO 127
        sig1(k) = 0!
        sig2(k) = _IIF(k MOD 2 = 0, 1.0!, -1.0!)
    NEXT k

    AudioAnalyzer_CalculateFFT aa1, amps1(), sig1(), 0, 1, 7
    AudioAnalyzer_CalculateFFT aa2, amps2(), sig2(), 0, 1, 7

    TEST_CHECK AudioAnalyzer_GetAverageIntensity(aa1) = 0!, "aa1 calculates 0 intensity for silence"
    TEST_CHECK AudioAnalyzer_GetRMS(aa1) = 0!, "aa1 calculates 0 RMS for silence"
    TEST_CHECK ABS(AudioAnalyzer_GetAverageIntensity(aa2) - 1.0!) < 0.001!, "aa2 calculates 1.0 intensity for full-scale signal"
    TEST_CHECK ABS(AudioAnalyzer_GetRMS(aa2) - 1.0!) < 0.001!, "aa2 calculates 1.0 RMS for full-scale signal"
    TEST_CHECK amps1(10) = 0, "aa1 bins are 0"
    TEST_CHECK AudioAnalyzer_GetPeakAmplitude(aa1) = 0, "aa1 peak amplitude is 0"
    TEST_CHECK AudioAnalyzer_GetPeakAmplitude(aa2) > 0, "aa2 peak amplitude > 0"
    TEST_CHECK_FALSE AudioAnalyzer_GetPeakAmplitude(aa1) = AudioAnalyzer_GetPeakAmplitude(aa2), "Instances maintain independent peak metrics"
    TEST_CHECK amps1(aa2.peakBin) = 0, "aa1 amplitude at aa2 peak bin is 0"
    TEST_CHECK amps2(aa2.peakBin) > 0, "aa2 amplitude at peak bin is positive"

    AudioAnalyzer_Finalize aa1
    AudioAnalyzer_Finalize aa2
    TEST_CHECK_FALSE AudioAnalyzer_IsInitialized(aa1), "aa1 finalized"
    TEST_CHECK_FALSE AudioAnalyzer_IsInitialized(aa2), "aa2 finalized"
    TEST_CASE_END
END SUB

''' @brief Tests for ProTracker MOD loading and playback.
SUB Test_MODPlayer_Lifecycle
    TEST_CASE_BEGIN "MODPlayer: Lifecycle management"
    DIM player AS MODPlayer
    TEST_CHECK_FALSE MODPlayer_IsInitialized(player), "Not initialized initially"
    TEST_REQUIRE MODPlayer_Initialize(player), "Initialize player"
    TEST_CHECK MODPlayer_IsInitialized(player), "Player is initialized"
    MODPlayer_Finalize player
    TEST_CHECK_FALSE MODPlayer_IsInitialized(player), "Player finalized"
    TEST_CASE_END
END SUB

''' @brief Tests for ProTracker MOD loading and playback.
SUB Test_MODPlayer_MOD
    TEST_CASE_BEGIN "MODPlayer: ProTracker MOD (Enigma.mod)"
    DIM player AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player, "mods/Enigma.mod"), "Load Enigma.mod"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Enigma") > 0, "Song caption contains 'Enigma'"
    TEST_CHECK MODPlayer_GetType(player) = "M.K.", "Song subtype is M.K."
    TEST_CHECK ABS(player.song.pcmMasterGain - 0.5!) < 0.01!, "4-channel MOD pcmMasterGain is 0.5"
    TEST_CHECK MODPlayer_GetOrders(player) > 0, "Order count is greater than 0"
    TEST_CHECK MODPlayer_GetPosition(player) = 0, "Initial position is 0"

    ' Test loop toggle
    MODPlayer_Loop player, _TRUE
    TEST_CHECK MODPlayer_IsLooping(player), "Looping enabled"
    MODPlayer_Loop player, _FALSE
    TEST_CHECK_FALSE MODPlayer_IsLooping(player), "Looping disabled"

    ' Test position navigation
    MODPlayer_SetPosition player, 2
    TEST_CHECK MODPlayer_GetPosition(player) = 2, "Position set to 2"
    MODPlayer_GoToNextPosition player
    TEST_CHECK MODPlayer_GetPosition(player) = 3, "Position incremented to 3"
    MODPlayer_GoToPreviousPosition player
    TEST_CHECK MODPlayer_GetPosition(player) = 2, "Position decremented back to 2"

    ' Test playback
    MODPlayer_Play player
    TEST_CHECK MODPlayer_IsPlaying(player), "Player is playing"
    TEST_CHECK player.song.BPM = 125, "Default BPM is 125"
    TEST_CHECK player.song.framesPerTick = player.song.tempoTimerValue \ player.song.BPM, "framesPerTick matches tempo calculation"
    TEST_CHECK player.song.framesPerTick * 50 = SoftSynth_GetSampleRate(player.synth), "framesPerTick corresponds to 50Hz CIA timer at 125 BPM"

    ' Test pause/resume
    MODPlayer_Pause player, _TRUE
    TEST_CHECK MODPlayer_IsPaused(player), "Player is paused"
    MODPlayer_Pause player, _FALSE
    TEST_CHECK_FALSE MODPlayer_IsPaused(player), "Player is unpaused"

    ' Test audio update
    MODPlayer_Update player, 0.05
    TEST_CHECK MODPlayer_IsPlaying(player), "Still playing after update"

    MODPlayer_Stop player
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player), "Player stopped"
    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: ProTracker backwards rows (backwards.mod)"
    DIM playerBack AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(playerBack, "mods/backwards.mod"), "Load backwards.mod"
    TEST_CHECK INSTR(MODPlayer_GetName(playerBack), "backwards") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(playerBack) = "M.K.", "Song subtype is M.K."
    TEST_CHECK MODPlayer_GetOrders(playerBack) = 1, "Song has 1 order"
    MODPlayer_Play playerBack
    TEST_CHECK MODPlayer_IsPlaying(playerBack), "Playing backwards.mod"
    MODPlayer_Update playerBack, 0.05
    TEST_CHECK MODPlayer_IsPlaying(playerBack), "Still playing after update"
    MODPlayer_Stop playerBack
    MODPlayer_Finalize playerBack
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: 8-channel MOD attenuation (shop.mod)"
    DIM player8 AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player8, "mods/shop.mod"), "Load shop.mod"
    TEST_CHECK player8.song.channels = 8, "Song has 8 channels"
    TEST_CHECK ABS(player8.song.pcmMasterGain - 0.25!) < 0.01!, "8-channel MOD pcmMasterGain is 0.25"
    MODPlayer_Play player8
    TEST_CHECK MODPlayer_IsPlaying(player8), "Playing shop.mod"
    MODPlayer_Update player8, 0.05
    MODPlayer_Stop player8
    MODPlayer_Finalize player8
    TEST_CASE_END
END SUB

''' @brief Tests for Scream Tracker 3 S3M loading and playback.
SUB Test_MODPlayer_S3M
    TEST_CASE_BEGIN "MODPlayer: Scream Tracker 3 (A Touch of Spring.s3m)"
    DIM player AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player, "mods/A Touch of Spring.s3m"), "Load A Touch of Spring.s3m"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Touch of Spring") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(player) = "SCRM", "Song subtype is SCRM"
    TEST_CHECK MODPlayer_GetOrders(player) > 0, "Order count is greater than 0"

    MODPlayer_Play player
    TEST_CHECK MODPlayer_IsPlaying(player), "Playing S3M"
    MODPlayer_Update player, 0.05
    MODPlayer_Stop player
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player), "Stopped S3M"
    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: Scream Tracker 3 backwards pattern breaks (BACKWARD.S3M)"
    DIM playerS3MBack AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(playerS3MBack, "mods/BACKWARD.S3M"), "Load BACKWARD.S3M"
    TEST_CHECK INSTR(MODPlayer_GetName(playerS3MBack), "Backwards") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(playerS3MBack) = "SCRM", "Song subtype is SCRM"
    TEST_CHECK MODPlayer_GetOrders(playerS3MBack) = 13, "Song has 13 orders (trailing 255 trimmed)"
    TEST_CHECK playerS3MBack.song.patterns = 13, "Song has 13 patterns"

    ' Step 0 -> row 0 has C63 which advances order to 1 and breaks to row 63
    MODPlayer_Play playerS3MBack
    TEST_CHECK MODPlayer_IsPlaying(playerS3MBack), "Playing BACKWARD.S3M"
    playerS3MBack.song.tickPattern = playerS3MBack.order(playerS3MBack.song.orderPosition)
    playerS3MBack.song.tickPatternRow = playerS3MBack.song.patternRow
    __MODPlayer_UpdateRow playerS3MBack
    playerS3MBack.song.patternRow = playerS3MBack.song.patternRow + 1
    TEST_CHECK playerS3MBack.song.orderPosition = 1, "Order advances to 1 on C63"
    TEST_CHECK playerS3MBack.song.patternRow = 63, "Target row is 63"

    ' Step Order 1 row 63 -> has C62 which advances order to 2 and breaks to row 62
    playerS3MBack.song.tickPattern = playerS3MBack.order(playerS3MBack.song.orderPosition)
    playerS3MBack.song.tickPatternRow = playerS3MBack.song.patternRow
    __MODPlayer_UpdateRow playerS3MBack
    playerS3MBack.song.patternRow = playerS3MBack.song.patternRow + 1
    TEST_CHECK playerS3MBack.song.orderPosition = 2, "Order advances to 2 on C62"
    TEST_CHECK playerS3MBack.song.patternRow = 62, "Target row is 62"

    ' Step Order 12 row 52 -> has C51 which wraps order to 0 and breaks to row 51
    playerS3MBack.song.orderPosition = 12
    playerS3MBack.song.patternRow = 52
    playerS3MBack.song.tickPattern = playerS3MBack.order(12)
    playerS3MBack.song.tickPatternRow = 52
    __MODPlayer_UpdateRow playerS3MBack
    playerS3MBack.song.patternRow = playerS3MBack.song.patternRow + 1
    TEST_CHECK playerS3MBack.song.orderPosition = 0, "Order wraps to 0 on C51 at end of order list"
    TEST_CHECK playerS3MBack.song.patternRow = 51, "Target row is 51"

    MODPlayer_Stop playerS3MBack
    MODPlayer_Finalize playerS3MBack
    TEST_CASE_END
END SUB

''' @brief Tests for Scream Tracker 3 packed ADPCM sample module loading.
SUB Test_MODPlayer_S3M_Packed
    TEST_CASE_BEGIN "MODPlayer: S3M with ADPCM samples (walkaway_packed.S3M)"
    DIM player AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player, "mods/walkaway_packed.S3M"), "Load walkaway_packed.S3M"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Walkaway") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(player) = "SCRM", "Song subtype is SCRM"
    TEST_CHECK MODPlayer_GetOrders(player) > 0, "Order count is greater than 0"

    MODPlayer_Play player
    TEST_CHECK MODPlayer_IsPlaying(player), "Playing packed S3M"
    MODPlayer_Update player, 0.05
    MODPlayer_Stop player
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player), "Stopped packed S3M"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for MultiTracker MTM loading and playback.
SUB Test_MODPlayer_MTM
    TEST_CASE_BEGIN "MODPlayer: MultiTracker (cougarstory-ii.mtm)"
    DIM player AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player, "mods/cougarstory-ii.mtm"), "Load cougarstory-ii.mtm"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Cougar story") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(player) = "MTM1", "Song subtype is MTM1"
    TEST_CHECK ABS(player.song.pcmMasterGain - (48! / 128!)) < 0.01!, "MTM pcmMasterGain is 48/128"
    TEST_CHECK MODPlayer_GetOrders(player) > 0, "Order count is greater than 0"

    MODPlayer_Play player
    TEST_CHECK MODPlayer_IsPlaying(player), "Playing MTM"
    MODPlayer_Update player, 0.05
    MODPlayer_Stop player
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player), "Stopped MTM"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for in-memory module loading.
SUB Test_MODPlayer_Memory
    TEST_CASE_BEGIN "MODPlayer: Load from memory string"
    DIM player AS MODPlayer
    DIM modBuffer AS STRING
    modBuffer = File_LoadFromDisk("mods/Enigma.mod")
    TEST_REQUIRE LEN(modBuffer) > 0, "Loaded file into memory string"

    TEST_REQUIRE MODPlayer_LoadFromMemory(player, modBuffer), "Load module from memory buffer"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Enigma") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(player) = "M.K.", "Song subtype matches"

    MODPlayer_Play player
    TEST_CHECK MODPlayer_IsPlaying(player), "Playing from memory load"
    MODPlayer_Stop player
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player), "Stopped"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for dedicated MODLoader.
SUB Test_MODLoader
    TEST_CASE_BEGIN "MODLoader: Load ProTracker MOD directly"
    DIM player AS MODPlayer
    TEST_REQUIRE MODLoader_LoadFromDisk(player, "mods/Enigma.mod"), "MODLoader loads Enigma.mod"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Enigma") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(player) = "M.K.", "Song subtype is M.K."
    TEST_CHECK MODPlayer_GetOrders(player) > 0, "Order count is greater than 0"
    TEST_CASE_END

    TEST_CASE_BEGIN "MODLoader: Reject incompatible formats"
    TEST_CHECK_FALSE MODLoader_LoadFromDisk(player, "mods/A Touch of Spring.s3m"), "MODLoader rejects S3M"
    TEST_CHECK_FALSE MODLoader_LoadFromDisk(player, "mods/cougarstory-ii.mtm"), "MODLoader rejects MTM"
    TEST_CHECK_FALSE MODLoader_LoadFromDisk(player, "mods/M31.far"), "MODLoader rejects FAR"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for dedicated S3MLoader.
SUB Test_S3MLoader
    TEST_CASE_BEGIN "S3MLoader: Load Scream Tracker 3 directly"
    DIM player AS MODPlayer
    TEST_REQUIRE S3MLoader_LoadFromDisk(player, "mods/A Touch of Spring.s3m"), "S3MLoader loads S3M"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Touch of Spring") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(player) = "SCRM", "Song subtype is SCRM"
    TEST_CASE_END

    TEST_CASE_BEGIN "S3MLoader: Load packed S3M directly"
    TEST_REQUIRE S3MLoader_LoadFromDisk(player, "mods/walkaway_packed.S3M"), "S3MLoader loads packed S3M"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Walkaway") > 0, "Song caption matches"
    TEST_CASE_END

    TEST_CASE_BEGIN "S3MLoader: Load from memory"
    DIM s3mBuf AS STRING: s3mBuf = File_LoadFromDisk("mods/A Touch of Spring.s3m")
    TEST_REQUIRE S3MLoader_LoadFromMemory(player, s3mBuf), "S3MLoader loads from memory"
    TEST_CHECK MODPlayer_GetType(player) = "SCRM", "Subtype is SCRM"
    TEST_CASE_END

    TEST_CASE_BEGIN "S3MLoader: Reject incompatible formats"
    TEST_CHECK_FALSE S3MLoader_LoadFromDisk(player, "mods/Enigma.mod"), "S3MLoader rejects MOD"
    TEST_CHECK_FALSE S3MLoader_LoadFromDisk(player, "mods/cougarstory-ii.mtm"), "S3MLoader rejects MTM"
    TEST_CHECK_FALSE S3MLoader_LoadFromDisk(player, "mods/M31.far"), "S3MLoader rejects FAR"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for dedicated MTMLoader.
SUB Test_MTMLoader
    TEST_CASE_BEGIN "MTMLoader: Load MultiTracker directly"
    DIM player AS MODPlayer
    TEST_REQUIRE MTMLoader_LoadFromDisk(player, "mods/cougarstory-ii.mtm"), "MTMLoader loads MTM"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "Cougar story") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(player) = "MTM1", "Song subtype is MTM1"
    TEST_CASE_END

    TEST_CASE_BEGIN "MTMLoader: Load from memory"
    DIM mtmBuf AS STRING: mtmBuf = File_LoadFromDisk("mods/cougarstory-ii.mtm")
    TEST_REQUIRE MTMLoader_LoadFromMemory(player, mtmBuf), "MTMLoader loads from memory"
    TEST_CHECK MODPlayer_GetType(player) = "MTM1", "Subtype is MTM1"
    TEST_CASE_END

    TEST_CASE_BEGIN "MTMLoader: Reject incompatible formats"
    TEST_CHECK_FALSE MTMLoader_LoadFromDisk(player, "mods/Enigma.mod"), "MTMLoader rejects MOD"
    TEST_CHECK_FALSE MTMLoader_LoadFromDisk(player, "mods/A Touch of Spring.s3m"), "MTMLoader rejects S3M"
    TEST_CHECK_FALSE MTMLoader_LoadFromDisk(player, "mods/M31.far"), "MTMLoader rejects FAR"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for dedicated FARLoader.
SUB Test_FARLoader
    TEST_CASE_BEGIN "FARLoader: Load Farandole Composer directly"
    DIM player AS MODPlayer
    TEST_REQUIRE FARLoader_LoadFromDisk(player, "mods/M31.far"), "FARLoader loads M31.far"
    TEST_CHECK INSTR(MODPlayer_GetName(player), "M31") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType(player) = "FAR", "Song subtype is FAR"
    TEST_CHECK player.song.channels = 16, "FAR has 16 channels"
    TEST_CHECK ABS(player.song.pcmMasterGain - (32! / 128!)) < 0.01!, "FAR pcmMasterGain is 32/128"
    TEST_CHECK MODPlayer_IsStereo(player), "FAR is stereo"
    TEST_CHECK MODPlayer_GetOrders(player) = 12, "Order count is 12"
    TEST_CHECK MODPlayer_GetPatternRows(player, 0) = 64, "Pattern 0 has 64 rows"
    TEST_CHECK MODPlayer_GetPatternRows(player, 11) = 72, "Pattern 11 has 72 rows (variable rows!)"
    TEST_CASE_END

    TEST_CASE_BEGIN "FARLoader: Load from memory"
    DIM farBuf AS STRING: farBuf = File_LoadFromDisk("mods/M31.far")
    TEST_REQUIRE FARLoader_LoadFromMemory(player, farBuf), "FARLoader loads from memory"
    TEST_CHECK MODPlayer_GetType(player) = "FAR", "Subtype is FAR"
    TEST_CHECK MODPlayer_GetPatternRows(player, 11) = 72, "Pattern 11 has 72 rows from memory"
    TEST_CASE_END

    TEST_CASE_BEGIN "FARLoader: Variable pattern rows across modules"
    DIM pAmazon AS MODPlayer
    TEST_REQUIRE FARLoader_LoadFromDisk(pAmazon, "mods/Amazon Dawn.far"), "Load Amazon Dawn.far"
    TEST_CHECK MODPlayer_GetPatternRows(pAmazon, 0) = 64, "Amazon Dawn pattern 0 has 64 rows"
    TEST_CHECK MODPlayer_GetPatternRows(pAmazon, 1) = 14, "Amazon Dawn pattern 1 has 14 rows"
    MODPlayer_Finalize pAmazon

    DIM pJourney AS MODPlayer
    TEST_REQUIRE FARLoader_LoadFromDisk(pJourney, "mods/A Journey Into Sound.far"), "Load A Journey Into Sound.far"
    TEST_CHECK MODPlayer_GetPatternRows(pJourney, 0) = 99, "A Journey Into Sound pattern 0 has 99 rows"
    TEST_CHECK MODPlayer_GetPatternRows(pJourney, 1) = 60, "A Journey Into Sound pattern 1 has 60 rows"
    TEST_CHECK MODPlayer_GetPatternRows(pJourney, 2) = 16, "A Journey Into Sound pattern 2 has 16 rows"
    TEST_CHECK MODPlayer_GetPatternRows(pJourney, 5) = 10, "A Journey Into Sound pattern 5 has 10 rows"
    TEST_CHECK MODPlayer_GetPatternRows(pJourney, 7) = 64, "A Journey Into Sound pattern 7 has 64 rows"
    MODPlayer_Finalize pJourney
    TEST_CASE_END

    TEST_CASE_BEGIN "FARLoader: Channel on/off mute map"
    DIM pAurora AS MODPlayer
    TEST_REQUIRE FARLoader_LoadFromDisk(pAurora, "mods/Aurora.far"), "Load Aurora.far"
    TEST_CHECK pAurora.channel(0).channelVolume = 64, "Channel 0 active"
    TEST_CHECK pAurora.channel(13).channelVolume = 0, "Channel 13 muted"
    TEST_CHECK pAurora.channel(14).channelVolume = 0, "Channel 14 muted"
    TEST_CHECK pAurora.channel(15).channelVolume = 0, "Channel 15 muted"
    MODPlayer_Finalize pAurora
    TEST_CASE_END

    TEST_CASE_BEGIN "FARLoader: Playback and teardown"
    MODPlayer_Play player
    TEST_CHECK MODPlayer_IsPlaying(player), "FAR is playing"
    MODPlayer_Update player, 0.05
    TEST_CHECK MODPlayer_IsPlaying(player), "FAR continues playing after update"
    MODPlayer_Stop player
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player), "FAR stopped"
    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "FARLoader: Reject incompatible formats"
    TEST_CHECK_FALSE FARLoader_LoadFromDisk(player, "mods/Enigma.mod"), "FARLoader rejects MOD"
    TEST_CHECK_FALSE FARLoader_LoadFromDisk(player, "mods/A Touch of Spring.s3m"), "FARLoader rejects S3M"
    TEST_CHECK_FALSE FARLoader_LoadFromDisk(player, "mods/cougarstory-ii.mtm"), "FARLoader rejects MTM"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for multi-instance isolation and concurrent state handling.
SUB Test_MODPlayer_MultiInstance
    TEST_CASE_BEGIN "MODPlayer: Multi-instance independent playback"
    DIM player1 AS MODPlayer
    DIM player2 AS MODPlayer

    TEST_REQUIRE MODPlayer_LoadFromDisk(player1, "mods/Enigma.mod"), "Load Enigma into player1"
    TEST_REQUIRE MODPlayer_LoadFromDisk(player2, "mods/A Touch of Spring.s3m"), "Load S3M into player2"

    ' Assert independent song metadata
    TEST_CHECK player1.song.subtype = "M.K.", "Player1 format is M.K."
    TEST_CHECK player2.song.subtype = "SCRM", "Player2 format is SCRM"
    TEST_CHECK player1.song.channels = 4, "Player1 has 4 channels"
    TEST_CHECK player2.song.channels = 16, "Player2 has 16 channels"
    TEST_CHECK INSTR(MODPlayer_GetName(player1), "Enigma") > 0, "Player1 title is Enigma"
    TEST_CHECK INSTR(MODPlayer_GetName(player2), "Touch of Spring") > 0, "Player2 title is Touch of Spring"

    ' Assert independent playback states
    MODPlayer_Play player1
    TEST_CHECK MODPlayer_IsPlaying(player1), "Player1 is playing"
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player2), "Player2 is not playing"

    ' Test independent looping flag
    MODPlayer_Loop player2, _TRUE
    TEST_CHECK MODPlayer_IsLooping(player2), "Player2 is looping"
    TEST_CHECK_FALSE MODPlayer_IsLooping(player1), "Player1 is not looping"

    ' Test independent order navigation
    MODPlayer_SetPosition player1, 2
    TEST_CHECK MODPlayer_GetPosition(player1) = 2, "Player1 position is 2"
    TEST_CHECK MODPlayer_GetPosition(player2) = 0, "Player2 position remains 0"

    ' Test audio update on player1 does not disrupt player2
    MODPlayer_Update player1, 0.05
    TEST_CHECK MODPlayer_IsPlaying(player1), "Player1 still playing after update"
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player2), "Player2 still stopped"

    MODPlayer_Stop player1
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player1), "Player1 stopped"

    MODPlayer_Finalize player1
    MODPlayer_Finalize player2
    TEST_CHECK_FALSE MODPlayer_IsInitialized(player1), "Player1 finalized"
    TEST_CHECK_FALSE MODPlayer_IsInitialized(player2), "Player2 finalized"
    TEST_CASE_END
END SUB

''' @brief Tests for pattern structure and variable row counts.
SUB Test_MODPlayer_PatternRows
    TEST_CASE_BEGIN "MODPlayer: Pattern structure and row counts"
    DIM player AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player, "mods/Enigma.mod"), "Load Enigma.mod"

    ' MOD patterns have 64 rows
    TEST_CHECK MODPlayer_GetPatternRows(player, 0) = 64, "Pattern 0 has 64 rows"
    TEST_CHECK player.pattern(0).rows = 64, "Pattern 0 direct rows property is 64"
    TEST_CHECK MODPlayer_GetPatternRows(player, 9999) = 0, "Out-of-range pattern returns 0 rows"

    ' Validate note matrix indexing
    TEST_CHECK player.pattern(0).note(0, 0).note <= 108 _ORELSE player.pattern(0).note(0, 0).note = __MODPLAYER_NOTE_NONE, "Valid note value at (0, 0)"

    ' Test S3M pattern rows
    DIM s3mPlayer AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(s3mPlayer, "mods/A Touch of Spring.s3m"), "Load A Touch of Spring.s3m"
    TEST_CHECK MODPlayer_GetPatternRows(s3mPlayer, 0) = 64, "S3M pattern 0 has 64 rows"
    TEST_CHECK s3mPlayer.pattern(0).rows = 64, "S3M pattern 0 direct rows is 64"

    ' Test MTM pattern rows
    DIM mtmPlayer AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(mtmPlayer, "mods/cougarstory-ii.mtm"), "Load cougarstory-ii.mtm"
    TEST_CHECK MODPlayer_GetPatternRows(mtmPlayer, 0) = 64, "MTM pattern 0 has 64 rows"
    TEST_CHECK mtmPlayer.pattern(0).rows = 64, "MTM pattern 0 direct rows is 64"

    ' Test real FAR variable pattern rows loaded via auto-detection
    DIM farPlayer AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(farPlayer, "mods/M31.far"), "Load M31.far via auto-detection"
    TEST_CHECK MODPlayer_GetType(farPlayer) = "FAR", "Auto-detected FAR format"
    TEST_CHECK MODPlayer_GetPatternRows(farPlayer, 0) = 64, "M31 pattern 0 has 64 rows"
    TEST_CHECK MODPlayer_GetPatternRows(farPlayer, 11) = 72, "M31 pattern 11 has 72 rows"
    MODPlayer_Finalize farPlayer

    ' Test variable row support on custom pattern matrix
    DIM customPlayer AS MODPlayer
    TEST_REQUIRE MODPlayer_Initialize(customPlayer), "Initialize custom player"
    customPlayer.song.patterns = 2
    customPlayer.song.channels = 4
    customPlayer.song.orders = 2
    REDIM customPlayer.order(0 TO 1) AS _UNSIGNED INTEGER
    customPlayer.order(0) = 0
    customPlayer.order(1) = 1
    REDIM customPlayer.pattern(0 TO 1) AS __MODPLAYERPATTERN
    customPlayer.pattern(0).rows = 32
    REDIM customPlayer.pattern(0).note(0 TO 31, 0 TO 3) AS __MODPLAYERNOTE
    customPlayer.pattern(1).rows = 16
    REDIM customPlayer.pattern(1).note(0 TO 15, 0 TO 3) AS __MODPLAYERNOTE

    TEST_CHECK MODPlayer_GetPatternRows(customPlayer, 0) = 32, "Custom pattern 0 has 32 rows"
    TEST_CHECK MODPlayer_GetPatternRows(customPlayer, 1) = 16, "Custom pattern 1 has 16 rows"

    MODPlayer_Finalize player
    MODPlayer_Finalize s3mPlayer
    MODPlayer_Finalize mtmPlayer
    MODPlayer_Finalize customPlayer
    TEST_CASE_END
END SUB

''' @brief Tests for error handling and invalid inputs.
SUB Test_MODPlayer_Errors
    TEST_CASE_BEGIN "MODPlayer: Non-existent file"
    DIM player AS MODPlayer
    TEST_REQUIRE_FALSE MODPlayer_LoadFromDisk(player, "mods/non_existent_file_98765.mod"), "Should return FALSE for missing file"
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: Empty memory buffer"
    TEST_REQUIRE_FALSE MODPlayer_LoadFromMemory(player, ""), "Should return FALSE for empty buffer"
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: Corrupt/Invalid memory buffer"
    TEST_REQUIRE_FALSE MODPlayer_LoadFromMemory(player, "THIS IS NOT A VALID MODULE HEADER AT ALL"), "Should return FALSE for corrupt buffer"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for Opal emulator lifecycle and status.
SUB Test_Opal_Lifecycle
    TEST_CASE_BEGIN "Opal: Initialization and status"
    DIM chip AS Opal
    Opal_Initialize chip, 44100
    TEST_CHECK Opal_ReadStatus(chip) = 0, "Initial status register is 0"

    Opal_SetSampleRate chip, 48000
    TEST_CHECK chip.sampleRate = 48000, "Sample rate changed to 48000"

    ' Queue a write and verify flush
    Opal_WriteBuffered chip, &H105, 1
    TEST_CHECK chip.queueCount > 0, "Write is queued"
    Opal_FlushWriteBuffer chip
    TEST_CHECK chip.queueCount = 0, "Queue is empty after flush"
    TEST_CHECK chip.newMode = 1, "NEW mode was applied"
    TEST_CASE_END
END SUB

''' @brief Tests for Opal sound generation.
SUB Test_Opal_SoundGeneration
    TEST_CASE_BEGIN "Opal: 2-operator melodic note synthesis"
    DIM chip AS Opal
    Opal_Initialize chip, 49716

    ' Configure channel 0: modulator (slot 0) and carrier (slot 3)
    Opal_Write chip, &H20, &H01 ' Modulator MULT = 1
    Opal_Write chip, &H40, 0 ' Modulator TL = 0
    Opal_Write chip, &H60, &HF0 ' Modulator AR = 15, DR = 0
    Opal_Write chip, &H80, &H00 ' Modulator SL = 0, RR = 0
    Opal_Write chip, &H23, &H01 ' Carrier MULT = 1
    Opal_Write chip, &H43, 0 ' Carrier TL = 0
    Opal_Write chip, &H63, &HF0 ' Carrier AR = 15, DR = 0
    Opal_Write chip, &H83, &H00 ' Carrier SL = 0, RR = 0
    Opal_Write chip, &HA0, &H57 ' Frequency low
    Opal_Write chip, &HB0, &H31 ' Key on, Octave 4, freq high

    DIM samples(0 TO 399) AS SINGLE
    DIM AS SINGLE leftSample, rightSample
    DIM hasNonZero AS _BYTE: hasNonZero = _FALSE
    DIM i AS LONG
    FOR i = 0 TO 399: samples(i) = 0!: NEXT
    Opal_MixSamples chip, samples(), 200, 1!
    FOR i = 0 TO 199
        leftSample = samples(i * 2)
        rightSample = samples(i * 2 + 1)
        IF leftSample <> 0 _ORELSE rightSample <> 0 THEN hasNonZero = _TRUE
        TEST_CHECK leftSample >= -1! _ANDALSO leftSample <= 1!, "Left sample within bounds"
        TEST_CHECK rightSample >= -1! _ANDALSO rightSample <= 1!, "Right sample within bounds"
    NEXT i
    TEST_CHECK hasNonZero, "Synthesized non-zero audio samples"
    TEST_CASE_END
END SUB

''' @brief Tests for Opal rhythm mode percussion.
SUB Test_Opal_RhythmMode
    TEST_CASE_BEGIN "Opal: Rhythm mode trigger"
    DIM chip AS Opal
    Opal_Initialize chip, 49716

    ' Configure channel 6 operators for bass drum
    Opal_Write chip, &H30, &H01 ' Mod MULT = 1
    Opal_Write chip, &H50, 0 ' Mod TL = 0
    Opal_Write chip, &H70, &HF0 ' Mod AR = 15, DR = 0
    Opal_Write chip, &H90, &H00 ' Mod SL = 0, RR = 0

    Opal_Write chip, &H33, &H01 ' Car MULT = 1
    Opal_Write chip, &H53, 0 ' Car TL = 0
    Opal_Write chip, &H73, &HF0 ' Car AR = 15, DR = 0
    Opal_Write chip, &H93, &H00 ' Car SL = 0, RR = 0

    ' Frequency for Channel 6
    Opal_Write chip, &HA6, &H57
    Opal_Write chip, &HB6, &H11

    ' Enable rhythm mode and trigger bass drum (bit 4)
    Opal_Write chip, &HBD, &H20
    Opal_Write chip, &HBD, &H20 OR &H10

    DIM samples(0 TO 399) AS SINGLE
    DIM AS SINGLE leftSample, rightSample
    DIM hasSound AS _BYTE: hasSound = _FALSE
    DIM i AS LONG
    FOR i = 0 TO 399: samples(i) = 0!: NEXT
    Opal_MixSamples chip, samples(), 200, 1!
    FOR i = 0 TO 199
        leftSample = samples(i * 2)
        rightSample = samples(i * 2 + 1)
        IF leftSample <> 0 _ORELSE rightSample <> 0 THEN hasSound = _TRUE
    NEXT i
    TEST_CHECK hasSound, "Rhythm mode generated sound output"
    TEST_CASE_END
END SUB

''' @brief Tests for Scream Tracker 3 AdLib / FM modules.
SUB Test_MODPlayer_S3M_AdLib
    TEST_CASE_BEGIN "MODPlayer: S3M with AdLib instruments (adlibsp.s3m)"
    DIM player1 AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player1, "mods/adlibsp.s3m"), "Load adlibsp.s3m"
    TEST_CHECK INSTR(MODPlayer_GetName(player1), "StarPort") > 0, "Song title matches"
    TEST_CHECK MODPlayer_GetType(player1) = "SCRM", "Song subtype is SCRM"
    TEST_CHECK player1.song.hasFMChannels, "adlibsp.s3m marked as hasFMChannels"
    TEST_CHECK MODPlayer_GetOrders(player1) > 0, "Order count > 0"

    MODPlayer_Play player1
    TEST_CHECK MODPlayer_IsPlaying(player1), "Playing adlibsp.s3m"
    MODPlayer_Update player1, 0.05
    TEST_CHECK player1.channel(0).oplFNum = 856, "S3M E-3 note maps to the expected OPL F-number"
    TEST_CHECK player1.channel(0).oplBlock = 2, "S3M E-3 note maps to the expected OPL block"

    DIM hasFMOutput AS _BYTE: hasFMOutput = _FALSE
    DIM sampleIndex AS _UNSIGNED LONG
    IF player1.synth.soundBufferSamples > 0 THEN
        FOR sampleIndex = 0 TO player1.synth.soundBufferSamples - 1
            IF player1.synth.soundBuffer(sampleIndex) <> 0! THEN
                hasFMOutput = _TRUE
                EXIT FOR
            END IF
        NEXT sampleIndex
    END IF
    TEST_CHECK hasFMOutput, "FM-only S3M produces non-zero mixed audio"

    MODPlayer_Stop player1
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player1), "Stopped adlibsp.s3m"
    MODPlayer_Finalize player1
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: S3M with mixed PCM and AdLib (adlib.s3m)"
    DIM player2 AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player2, "mods/adlib.s3m"), "Load adlib.s3m"
    TEST_CHECK INSTR(MODPlayer_GetName(player2), "First Adlib Attempt") > 0, "Song title matches"
    TEST_CHECK MODPlayer_GetType(player2) = "SCRM", "Song subtype is SCRM"
    TEST_CHECK player2.song.hasFMChannels, "adlib.s3m marked as hasFMChannels"
    TEST_CHECK MODPlayer_GetOrders(player2) > 0, "Order count > 0"

    MODPlayer_Play player2
    TEST_CHECK MODPlayer_IsPlaying(player2), "Playing adlib.s3m"
    MODPlayer_Update player2, 0.05
    MODPlayer_Stop player2
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player2), "Stopped adlib.s3m"
    MODPlayer_Finalize player2
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: S3M mixed PCM and FM with master volume (Shrubbing.s3m)"
    DIM player3 AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player3, "mods/Shrubbing.s3m"), "Load Shrubbing.s3m"
    TEST_CHECK INSTR(MODPlayer_GetName(player3), "Shrubbing") > 0, "Song title matches"
    TEST_CHECK player3.song.hasFMChannels, "Shrubbing marked as hasFMChannels"
    TEST_CHECK player3.song.isStereo, "Shrubbing is stereo"
    TEST_CHECK ABS(player3.song.pcmMasterGain - (37! / 160!)) < 0.01!, "PCM master gain attenuated correctly"
    TEST_CHECK ABS(player3.song.fmMasterGain - 1.0!) < 0.01!, "FM master gain matches stereo factor"
    MODPlayer_Play player3
    TEST_CHECK MODPlayer_IsPlaying(player3), "Playing Shrubbing.s3m"
    MODPlayer_Update player3, 0.1
    DIM hasOutput3 AS _BYTE: hasOutput3 = _FALSE
    DIM sIdx3 AS _UNSIGNED LONG
    IF player3.synth.soundBufferSamples > 0 THEN
        FOR sIdx3 = 0 TO player3.synth.soundBufferSamples - 1
            IF player3.synth.soundBuffer(sIdx3) <> 0! THEN
                hasOutput3 = _TRUE
                EXIT FOR
            END IF
        NEXT sIdx3
    END IF
    TEST_CHECK hasOutput3, "Shrubbing produces non-zero mixed audio"
    MODPlayer_Stop player3
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player3), "Stopped Shrubbing.s3m"
    MODPlayer_Finalize player3
    TEST_CASE_END
END SUB

''' @brief Tests S3M OPL percussion pitch and independent drum key state.
SUB Test_MODPlayer_S3M_FMDrums
    TEST_CASE_BEGIN "MODPlayer: S3M FM percussion channel state"
    DIM player AS MODPlayer
    player.song.channels = 2
    player.song.instruments = 1
    REDIM player.channel(0 TO 1) AS __MODPLAYERCHANNEL
    REDIM player.instrument(0 TO 0) AS __MODPLAYERINSTRUMENT
    player.song.isStereo = _TRUE

    player.channel(0).subtype = __MODPLAYER_INSTRUMENT_FM_BASSDRUM
    player.channel(0).oplChannel = 6
    player.channel(1).subtype = __MODPLAYER_INSTRUMENT_FM_SNAREDRUM
    player.channel(1).oplChannel = 7

    player.instrument(0).subtype = __MODPLAYER_INSTRUMENT_FM_BASSDRUM
    player.instrument(0).volume = __MODPLAYER_INSTRUMENT_VOLUME_MAX
    player.instrument(0).c2Spd = 8363
    player.instrument(0).adlib(0) = &H01
    player.instrument(0).adlib(1) = &H01
    player.instrument(0).adlib(2) = &H00
    player.instrument(0).adlib(3) = &H00
    player.instrument(0).adlib(4) = &HF0
    player.instrument(0).adlib(5) = &HF0
    player.instrument(0).adlib(6) = &H00
    player.instrument(0).adlib(7) = &H00
    player.instrument(0).adlib(8) = &H00
    player.instrument(0).adlib(9) = &H00
    player.instrument(0).adlib(10) = &H00
    player.instrument(0).adlib(11) = &H00

    Opal_Initialize player.opl, 49716
    __MODPlayer_UpdateFMChannelRow player, 0, 48, 1, __MODPLAYER_NOTE_NO_VOLUME
    TEST_CHECK player.channel(0).oplFNum = 686, "Bass drum note uses linear semitone pitch"
    TEST_CHECK player.channel(0).oplBlock = 3, "Bass drum note sets the expected OPL block"
    TEST_CHECK player.opl.rhythmMode <> 0, "FM drum channel enables OPL rhythm mode"
    TEST_CHECK (player.opl.op(12).key AND 2) <> 0, "Bass drum key turns on"

    __MODPlayer_UpdateFMChannelRow player, 1, 48, 1, __MODPLAYER_NOTE_NO_VOLUME
    TEST_CHECK (player.opl.op(12).key AND 2) <> 0, "Snare trigger preserves the active bass drum"
    TEST_CHECK (player.opl.op(16).key AND 2) <> 0, "Snare key turns on"

    __MODPlayer_UpdateFMChannelRow player, 0, __MODPLAYER_NOTE_KEY_OFF, 0, __MODPLAYER_NOTE_NO_VOLUME
    TEST_CHECK (player.opl.op(12).key AND 2) = 0, "Bass drum key-off releases only the bass drum"
    TEST_CHECK (player.opl.op(16).key AND 2) <> 0, "Bass drum key-off preserves the active snare"

    ' Test Drum operator isolation (Hi-Hat on mod vs Snare on car)
    player.song.channels = 3
    player.song.instruments = 2
    REDIM _PRESERVE player.channel(0 TO 2) AS __MODPLAYERCHANNEL
    REDIM _PRESERVE player.instrument(0 TO 1) AS __MODPLAYERINSTRUMENT

    player.channel(1).subtype = __MODPLAYER_INSTRUMENT_FM_SNAREDRUM
    player.channel(1).oplChannel = 7
    player.channel(1).instrument = 0
    player.channel(1).volume = 64
    player.channel(2).subtype = __MODPLAYER_INSTRUMENT_FM_HIHAT
    player.channel(2).oplChannel = 7
    player.channel(2).instrument = 1
    player.channel(2).volume = 64

    player.instrument(0).subtype = __MODPLAYER_INSTRUMENT_FM_SNAREDRUM
    player.instrument(0).volume = 64
    player.instrument(0).adlib(3) = 15 ' Snare carrier TL = 15

    player.instrument(1).subtype = __MODPLAYER_INSTRUMENT_FM_HIHAT
    player.instrument(1).volume = 64
    player.instrument(1).adlib(2) = 25 ' Hi-Hat mod TL = 25

    __MODPlayer_TriggerFMPatch player, 1, 0
    __MODPlayer_TriggerFMPatch player, 2, 1

    ' Slot 13 is channel 7 mod (Hi-Hat), slot 16 is channel 7 car (Snare)
    TEST_CHECK player.opl.op(13).totalLevel = 25, "Hi-Hat patch sets modulator totalLevel"
    TEST_CHECK player.opl.op(16).totalLevel = 15, "Snare patch sets carrier totalLevel"

    ' Test FM Portamento Octave Crossing
    player.channel(0).subtype = __MODPLAYER_INSTRUMENT_FM_MELODY
    player.channel(0).oplChannel = 0
    player.channel(0).oplFNum = 1020
    player.channel(0).oplBlock = 3
    player.channel(0).oplKeyOn = -1
    __MODPlayer_FMDoPortamentoUp player, 0, 10
    TEST_CHECK player.channel(0).oplBlock = 4, "Portamento up crossed octave 3 to 4"
    TEST_CHECK player.channel(0).oplFNum = 515, "Portamento up recalculated FNum"

    player.channel(0).oplFNum = 514
    player.channel(0).oplBlock = 4
    __MODPlayer_FMDoPortamentoDown player, 0, 10
    TEST_CHECK player.channel(0).oplBlock = 3, "Portamento down crossed octave 4 to 3"
    TEST_CHECK player.channel(0).oplFNum = 1008, "Portamento down recalculated FNum"

    ' Test FM Panning
    __MODPlayer_SetChannelPanning player, 0, 0
    TEST_CHECK player.opl.chan(0).leftPan = 256, "Left pan full left"
    TEST_CHECK player.opl.chan(0).rightPan = 0, "Right pan zero on left"

    __MODPlayer_SetChannelPanning player, 0, 255
    TEST_CHECK player.opl.chan(0).leftPan = 0, "Left pan zero on right"
    TEST_CHECK player.opl.chan(0).rightPan = 256, "Right pan full right"

    __MODPlayer_SetChannelPanning player, 0, 128
    TEST_CHECK player.opl.chan(0).leftPan = 256, "Center pan left"
    TEST_CHECK player.opl.chan(0).rightPan = 256, "Center pan right"

    TEST_CASE_END
END SUB

''' @brief Tests for StarTrekker AM synthesizer instruments and companion file loading.
SUB Test_MODPlayer_Startrekker_AM
    TEST_CASE_BEGIN "MODPlayer: StarTrekker AM synth (amsyntdemo.mod)"
    DIM player1 AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player1, "mods/amsyntdemo.mod"), "Load amsyntdemo.mod with companion"
    TEST_CHECK MODPlayer_GetType(player1) = "EXO4", "Subtype is EXO4"
    TEST_CHECK player1.song.channels = 4, "Channel count is 4"
    TEST_CHECK player1.song.instruments = 31, "Instrument count is 31"
    TEST_CHECK player1.instrument(0).subtype = __MODPLAYER_INSTRUMENT_AM_SYNTH, "Inst 1 is AM synth"
    TEST_CHECK player1.instrument(0).am.isAM, "Inst 1 isAM flag is true"
    TEST_CHECK player1.instrument(0).length = 32, "Inst 1 waveform length is 32"
    TEST_CHECK player1.instrument(0).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP, "Inst 1 loops forward"
    TEST_CHECK player1.instrument(0).volume = 64, "Inst 1 volume forced to 64"

    MODPlayer_Play player1
    TEST_CHECK MODPlayer_IsPlaying(player1), "Playing amsyntdemo.mod"
    MODPlayer_Update player1, 0.05

    DIM hasAudioOutput AS _BYTE: hasAudioOutput = _FALSE
    DIM sIdx AS _UNSIGNED LONG
    IF player1.synth.soundBufferSamples > 0 THEN
        FOR sIdx = 0 TO player1.synth.soundBufferSamples - 1
            IF player1.synth.soundBuffer(sIdx) <> 0! THEN
                hasAudioOutput = _TRUE
                EXIT FOR
            END IF
        NEXT sIdx
    END IF
    TEST_CHECK hasAudioOutput, "Synthesized non-zero audio output"

    MODPlayer_Stop player1
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player1), "Stopped amsyntdemo.mod"
    MODPlayer_Finalize player1
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: Mixed PCM and AM synth (angel-station.mod)"
    DIM player2 AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player2, "mods/angel-station.mod"), "Load angel-station.mod with companion"
    TEST_CHECK MODPlayer_GetType(player2) = "FLT4", "Subtype is FLT4"
    TEST_CHECK player2.instrument(0).subtype = __MODPLAYER_INSTRUMENT_PCM, "Inst 1 is PCM sample"
    TEST_CHECK player2.instrument(0).length = 818, "Inst 1 PCM length is 818"
    TEST_CHECK player2.instrument(4).subtype = __MODPLAYER_INSTRUMENT_AM_SYNTH, "Inst 5 is AM synth"
    TEST_CHECK player2.instrument(4).am.isAM, "Inst 5 isAM is true"
    TEST_CHECK player2.instrument(4).length = 32, "Inst 5 wave length is 32"

    MODPlayer_Play player2
    TEST_CHECK MODPlayer_IsPlaying(player2), "Playing angel-station.mod"
    MODPlayer_Update player2, 0.05
    MODPlayer_Stop player2
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player2), "Stopped angel-station.mod"
    MODPlayer_Finalize player2
    TEST_CASE_END

    TEST_CASE_BEGIN "MODLoader: In-memory companion loading"
    DIM player3 AS MODPlayer
    DIM modData AS STRING: modData = File_Load("mods/amsyntdemo.mod")
    DIM compData AS STRING: compData = File_Load("mods/amsyntdemo.mod.nt")
    TEST_REQUIRE LEN(modData) > 0, "Read amsyntdemo.mod data"
    TEST_REQUIRE LEN(compData) > 0, "Read amsyntdemo.mod.nt data"

    ' Load without companion: instruments should not be AM
    TEST_CHECK MODLoader_LoadFromMemory(player3, modData), "Load without companion"
    TEST_CHECK player3.instrument(0).subtype = __MODPLAYER_INSTRUMENT_PCM, "Without companion inst 1 is PCM"
    MODPlayer_Finalize player3

    ' Load with companion: instruments should be AM synth
    TEST_CHECK MODLoader_LoadWithCompanion(player3, modData, compData), "Load with companion"
    TEST_CHECK player3.instrument(0).subtype = __MODPLAYER_INSTRUMENT_AM_SYNTH, "With companion inst 1 is AM"
    MODPlayer_Finalize player3
    TEST_CASE_END
END SUB

''' @brief Tests for S3M order list marker filtering (254 skip markers and 255 end-of-song markers).
SUB Test_S3M_Markers
    TEST_CASE_BEGIN "S3M Markers: Trailing 255 trimming"
    DIM pBack AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pBack, "mods/BACKWARD.S3M"), "Load BACKWARD.S3M"
    TEST_CHECK MODPlayer_GetOrders(pBack) = 13, "BACKWARD.S3M trimmed to 13 orders"
    TEST_CHECK pBack.order(12) = 12, "Last order is pattern 12"
    MODPlayer_Finalize pBack

    DIM pAryx AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pAryx, "mods/aryx.s3m"), "Load aryx.s3m"
    TEST_CHECK MODPlayer_GetOrders(pAryx) = 42, "aryx.s3m trimmed to 42 orders (from 44)"
    MODPlayer_Finalize pAryx
    TEST_CASE_END

    TEST_CASE_BEGIN "S3M Markers: 254 marker skipping during navigation (A94FINAL.S3M)"
    DIM pA94 AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pA94, "mods/A94FINAL.S3M"), "Load A94FINAL.S3M"
    ' Verify marker is preserved in order array for Bxx jump targeting
    TEST_CHECK pA94.order(2) = 2, "Order 2 is pattern 2"
    TEST_CHECK pA94.order(3) = __MODPLAYER_PATTERN_MARKER, "Order 3 is marker 254"
    TEST_CHECK pA94.order(4) = 4, "Order 4 is pattern 4"

    MODPlayer_Play pA94
    TEST_CHECK MODPlayer_GetPosition(pA94) = 0, "Initial position is 0"

    ' Navigate to order 2
    MODPlayer_SetPosition pA94, 2
    TEST_CHECK MODPlayer_GetPosition(pA94) = 2, "Position set to 2"

    ' GoToNextPosition should step over order 3 (254) directly to order 4
    MODPlayer_GoToNextPosition pA94
    TEST_CHECK MODPlayer_GetPosition(pA94) = 4, "GoToNextPosition stepped over 254 marker to order 4"

    ' GoToPreviousPosition should step back over order 3 (254) directly to order 2
    MODPlayer_GoToPreviousPosition pA94
    TEST_CHECK MODPlayer_GetPosition(pA94) = 2, "GoToPreviousPosition stepped back over 254 marker to order 2"

    ' SetPosition directly targeting order 3 should advance past marker to order 4
    MODPlayer_SetPosition pA94, 3
    TEST_CHECK MODPlayer_GetPosition(pA94) = 4, "SetPosition on marker 254 advances to order 4"

    ' Test Bxx position jump targeting marker order 3
    pA94.song.orderPosition = 0
    pA94.song.patternRow = 0
    pA94.song.tickPattern = pA94.order(pA94.song.orderPosition)
    pA94.song.tickPatternRow = 0
    ' Simulate B 03 effect in pattern note
    pA94.pattern(pA94.song.tickPattern).note(0, 0).effect = __MODPLAYER_FX_POSITION_JUMP
    pA94.pattern(pA94.song.tickPattern).note(0, 0).operand = 3
    __MODPlayer_UpdateRow pA94
    ' Bxx with target 3 should skip marker 3 and advance orderPosition to 4
    TEST_CHECK pA94.song.orderPosition = 4, "Bxx position jump to marker 3 advances to order 4"

    MODPlayer_Stop pA94
    MODPlayer_Finalize pA94
    TEST_CASE_END
END SUB

''' @brief Tests for S3M effects (Arpeggio memory, Cxx invalid row ignore, Zxx, XA4).
SUB Test_S3M_Effects
    SHARED __MODPlayer_PeriodTable() AS _UNSIGNED INTEGER
    TEST_CASE_BEGIN "S3M Effects: Arpeggio memory and c2Spd scaling"
    DIM player AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player, "mods/adlib.s3m"), "Load adlib.s3m base"
    player.channel(0).note = 36 ' C-3
    player.channel(0).period = 1000
    player.channel(0).c2Spd = 8363
    player.channel(0).lastArpeggio = 0

    ' Row has J37 (Arpeggio +3, +7)
    player.song.tickPattern = 0
    player.song.tickPatternRow = 0
    player.pattern(0).note(0, 0).note = __MODPLAYER_NOTE_NONE
    player.pattern(0).note(0, 0).effect = __MODPLAYER_FX_ARPEGGIO
    player.pattern(0).note(0, 0).operand = &H37
    __MODPlayer_UpdateRow player
    TEST_CHECK player.channel(0).lastArpeggio = &H37, "J37 sets lastArpeggio to &H37"

    ' Tick 1: should calculate frequency for note + 3 (36 + 3 = 39)
    player.song.tick = 1
    __MODPlayer_UpdateTick player
    DIM expectedPeriod1 AS LONG
    expectedPeriod1 = (8363 * __MODPlayer_PeriodTable(39)) \ 8363
    DIM expectedFreq1 AS _UNSIGNED LONG
    expectedFreq1 = __MODPlayer_GetFrequencyFromPeriod(expectedPeriod1)
    TEST_CHECK SoftSynth_GetVoiceFrequency(player.synth, 0) = expectedFreq1, "Tick 1 arpeggio frequency matches note+3"

    ' Now test J00 (recall memory)
    player.pattern(0).note(0, 0).operand = 0
    __MODPlayer_UpdateRow player
    TEST_CHECK player.channel(0).lastArpeggio = &H37, "J00 preserves lastArpeggio"
    player.song.tick = 2
    __MODPlayer_UpdateTick player
    DIM expectedPeriod2 AS LONG
    expectedPeriod2 = (8363 * __MODPlayer_PeriodTable(43)) \ 8363
    DIM expectedFreq2 AS _UNSIGNED LONG
    expectedFreq2 = __MODPlayer_GetFrequencyFromPeriod(expectedPeriod2)
    TEST_CHECK SoftSynth_GetVoiceFrequency(player.synth, 0) = expectedFreq2, "Tick 2 arpeggio with J00 recalls memory (note+7)"

    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "S3M Effects: Pattern Break Cxx ignores row >= 64"
    DIM playerPB AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(playerPB, "mods/BACKWARD.S3M"), "Load BACKWARD.S3M"
    MODPlayer_Play playerPB
    playerPB.song.orderPosition = 2
    playerPB.song.patternRow = 10
    playerPB.song.tickPattern = playerPB.order(2)
    playerPB.song.tickPatternRow = 10

    ' Simulate C64 (operand &H64 = 6*10 + 4 = 64) -> ST3 ignores row >= 64
    playerPB.pattern(playerPB.song.tickPattern).note(10, 0).effect = __MODPLAYER_FX_PATTERN_BREAK
    playerPB.pattern(playerPB.song.tickPattern).note(10, 0).operand = &H64
    __MODPlayer_UpdateRow playerPB
    TEST_CHECK playerPB.song.orderPosition = 2, "C64 does not advance order (ignored)"
    TEST_CHECK playerPB.song.patternRow = 10, "C64 does not change row (ignored)"

    MODPlayer_Stop playerPB
    MODPlayer_Finalize playerPB
    TEST_CASE_END

    TEST_CASE_BEGIN "S3M Effects: FM Arpeggio modulation"
    DIM playerFM AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(playerFM, "mods/adlib.s3m"), "Load adlib.s3m"
    MODPlayer_Play playerFM
    ' Channel 4 is FM melody
    playerFM.channel(4).note = 36
    playerFM.channel(4).oplKeyOn = -1
    playerFM.channel(4).lastArpeggio = &H47
    playerFM.song.tickPattern = playerFM.order(playerFM.song.orderPosition)
    playerFM.song.tickPatternRow = 0
    playerFM.pattern(playerFM.song.tickPattern).note(0, 4).effect = __MODPLAYER_FX_ARPEGGIO
    playerFM.pattern(playerFM.song.tickPattern).note(0, 4).operand = 0 ' J00

    ' Tick 1: arpeggio modulation
    playerFM.song.tick = 1
    __MODPlayer_UpdateFMChannelTick playerFM, 4, __MODPLAYER_FX_ARPEGGIO, 0
    TEST_CHECK playerFM.channel(4).oplKeyOn = -1, "FM voice remains active during arpeggio"
    TEST_CHECK playerFM.channel(4).lastArpeggio = &H47, "FM J00 memory intact"

    MODPlayer_Stop playerFM
    MODPlayer_Finalize playerFM
    TEST_CASE_END
END SUB

''' @brief Tests for S3M master stereo flag detection and mono centering.
SUB Test_MODPlayer_Stereo
    TEST_CASE_BEGIN "Stereo Flag: S3M Mono vs Stereo detection"
    DIM pMono AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pMono, "mods/adlib.s3m"), "Load adlib.s3m (mono)"
    TEST_CHECK_FALSE MODPlayer_IsStereo(pMono), "adlib.s3m is mono"
    DIM c AS LONG
    FOR c = 0 TO pMono.song.channels - 1
        TEST_CHECK pMono.channel(c).panning = 128, "Mono channel has center panning (128)"
    NEXT c
    MODPlayer_Finalize pMono

    DIM pStereo AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pStereo, "mods/A Touch of Spring.s3m"), "Load A Touch of Spring.s3m (stereo)"
    TEST_CHECK MODPlayer_IsStereo(pStereo), "A Touch of Spring.s3m is stereo"
    MODPlayer_Finalize pStereo
    TEST_CASE_END

    TEST_CASE_BEGIN "Stereo Flag: MOD, MTM, and FAR default to stereo"
    DIM pMod AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pMod, "mods/Enigma.mod"), "Load Enigma.mod"
    TEST_CHECK MODPlayer_IsStereo(pMod), "MOD is stereo"
    MODPlayer_Finalize pMod

    DIM pMtm AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pMtm, "mods/cougarstory-ii.mtm"), "Load cougarstory-ii.mtm"
    TEST_CHECK MODPlayer_IsStereo(pMtm), "MTM is stereo"
    MODPlayer_Finalize pMtm

    DIM pFar AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pFar, "mods/M31.far"), "Load M31.far"
    TEST_CHECK MODPlayer_IsStereo(pFar), "FAR is stereo"
    MODPlayer_Finalize pFar
    TEST_CASE_END
END SUB

''' @brief Tests for channel synthesis mode badges ([PCM], [AM ], [FMm], [FMd]).
SUB Test_MODPlayer_ChannelBadges
    TEST_CASE_BEGIN "Channel Badges: PCM channels in MOD"
    DIM pMod AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pMod, "mods/Enigma.mod"), "Load Enigma.mod"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pMod, 0) = "[PCM]", "Channel 0 is [PCM]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pMod, 1) = "[PCM]", "Channel 1 is [PCM]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pMod, 2) = "[PCM]", "Channel 2 is [PCM]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pMod, 3) = "[PCM]", "Channel 3 is [PCM]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pMod, 4) = "", "Channel out of bounds is empty string"
    MODPlayer_Finalize pMod
    TEST_CASE_END

    TEST_CASE_BEGIN "Channel Badges: FM Melody channels in adlib.s3m"
    DIM pFM AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pFM, "mods/adlib.s3m"), "Load adlib.s3m"
    ' adlib.s3m has channels 0..3 as PCM and 4..12 as AdLib FM Melody
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pFM, 0) = "[PCM]", "Channel 0 is [PCM]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pFM, 4) = "[FMm]", "Channel 4 is [FMm]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pFM, 12) = "[FMm]", "Channel 12 is [FMm]"
    MODPlayer_Finalize pFM
    TEST_CASE_END

    TEST_CASE_BEGIN "Channel Badges: FM Drum channels"
    DIM pDrum AS MODPlayer
    pDrum.song.channels = 5
    REDIM pDrum.channel(0 TO 4) AS __MODPLAYERCHANNEL
    pDrum.channel(0).subtype = __MODPLAYER_INSTRUMENT_FM_BASSDRUM
    pDrum.channel(1).subtype = __MODPLAYER_INSTRUMENT_FM_SNAREDRUM
    pDrum.channel(2).subtype = __MODPLAYER_INSTRUMENT_FM_TOMTOM
    pDrum.channel(3).subtype = __MODPLAYER_INSTRUMENT_FM_CYMBAL
    pDrum.channel(4).subtype = __MODPLAYER_INSTRUMENT_FM_HIHAT
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pDrum, 0) = "[FMd]", "Bass drum is [FMd]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pDrum, 1) = "[FMd]", "Snare drum is [FMd]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pDrum, 2) = "[FMd]", "Tom-tom is [FMd]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pDrum, 3) = "[FMd]", "Cymbal is [FMd]"
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pDrum, 4) = "[FMd]", "Hi-hat is [FMd]"
    TEST_CASE_END

    TEST_CASE_BEGIN "Channel Badges: AM Synth dynamic badge"
    DIM pAM AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pAM, "mods/amsyntdemo.mod"), "Load AM demo"
    ' Initially all channels are PCM before triggering
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pAM, 0) = "[PCM]", "Initial channel 0 is [PCM]"
    ' Simulate channel 0 playing an AM instrument
    pAM.channel(0).instrument = 0 ' inst 0 is AM synth
    __MODPlayer_PlayPCMChannelVoice pAM, 0
    TEST_CHECK MODPlayer_GetChannelSubtypeCaption(pAM, 0) = "[AM ]", "After triggering AM instrument, badge is [AM ]"
    MODPlayer_Finalize pAM
    TEST_CASE_END
END SUB

' Run all test suites
TEST_BEGIN_ALL

Test_AudioConv
Test_SoftSynth
Test_StringFile
Test_AudioAnalyzer
Test_Opal_Lifecycle
Test_Opal_SoundGeneration
Test_Opal_RhythmMode
Test_MODPlayer_Lifecycle
Test_MODPlayer_MOD
Test_MODPlayer_Startrekker_AM
Test_MODPlayer_S3M
Test_MODPlayer_S3M_Packed
Test_MODPlayer_S3M_AdLib
Test_MODPlayer_S3M_FMDrums
Test_S3M_Markers
Test_S3M_Effects
Test_MODPlayer_Stereo
Test_MODPlayer_ChannelBadges
Test_MODPlayer_MTM
Test_MODPlayer_Memory
Test_MODLoader
Test_S3MLoader
Test_MTMLoader
Test_FARLoader
Test_MODPlayer_MultiInstance
Test_MODPlayer_PatternRows
Test_MODPlayer_Errors

TEST_END_ALL
