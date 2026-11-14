'-----------------------------------------------------------------------------------------------------------------------
' QB64 MOD Player Test Suite
' Uses Catch.bi test framework for QB64-PE
'-----------------------------------------------------------------------------------------------------------------------

$LET TEST_STRICT = TRUE
$LET TEST_CONSOLE_ONLY = TRUE

'$INCLUDE:'../source/Catch.bi'
'$INCLUDE:'../source/File.bi'
'$INCLUDE:'../source/String.bi'
'$INCLUDE:'../source/StringFile.bi'
'$INCLUDE:'../source/Pathname.bi'
'$INCLUDE:'../source/AudioConv.bi'
'$INCLUDE:'../source/SoftSynth.bi'
'$INCLUDE:'../source/AudioAnalyzer.bi'
'$INCLUDE:'../source/MODPlayer.bi'

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
    DIM ctx AS SoftSynthType
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
    DIM synth AS SoftSynthType
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
    DIM synth2 AS SoftSynthType
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
    SoftSynth_Update synth2, 10
    TEST_CHECK SoftSynth_GetActiveVoices(synth2) = 1, "Active voices should be 1 after play and update"

    SoftSynth_StopVoice synth2, 0
    SoftSynth_Update synth2, 10
    TEST_CHECK SoftSynth_GetActiveVoices(synth2) = 0, "Active voices should be 0 after stop and update"

    SoftSynth_Finalize synth2
    TEST_CASE_END

    TEST_CASE_BEGIN "SoftSynth: Multi-instance context isolation"
    DIM ctxA AS SoftSynthType, ctxB AS SoftSynthType
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
    DIM analyzer AS AudioAnalyzerType
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
    DIM aa AS AudioAnalyzerType
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
    DIM safeAa AS AudioAnalyzerType
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
    DIM aa1 AS AudioAnalyzerType, aa2 AS AudioAnalyzerType
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
SUB Test_MODPlayer_MOD
    TEST_CASE_BEGIN "MODPlayer: ProTracker MOD (Enigma.mod)"
    TEST_REQUIRE MODPlayer_LoadFromDisk("mods/Enigma.mod"), "Load Enigma.mod"
    TEST_CHECK INSTR(MODPlayer_GetName, "Enigma") > 0, "Song caption contains 'Enigma'"
    TEST_CHECK MODPlayer_GetType = "M.K.", "Song subtype is M.K."
    TEST_CHECK MODPlayer_GetOrders > 0, "Order count is greater than 0"
    TEST_CHECK MODPlayer_GetPosition = 0, "Initial position is 0"

    ' Test loop toggle
    MODPlayer_Loop _TRUE
    TEST_CHECK MODPlayer_IsLooping, "Looping enabled"
    MODPlayer_Loop _FALSE
    TEST_CHECK_FALSE MODPlayer_IsLooping, "Looping disabled"

    ' Test position navigation
    MODPlayer_SetPosition 2
    TEST_CHECK MODPlayer_GetPosition = 2, "Position set to 2"
    MODPlayer_GoToNextPosition
    TEST_CHECK MODPlayer_GetPosition = 3, "Position incremented to 3"
    MODPlayer_GoToPreviousPosition
    TEST_CHECK MODPlayer_GetPosition = 2, "Position decremented back to 2"

    ' Test playback
    MODPlayer_Play
    TEST_CHECK MODPlayer_IsPlaying, "Player is playing"

    ' Test pause/resume
    MODPlayer_Pause _TRUE
    TEST_CHECK MODPlayer_IsPaused, "Player is paused"
    MODPlayer_Pause _FALSE
    TEST_CHECK_FALSE MODPlayer_IsPaused, "Player is unpaused"

    ' Test audio update
    MODPlayer_Update 0.05
    TEST_CHECK MODPlayer_IsPlaying, "Still playing after update"

    MODPlayer_Stop
    TEST_CHECK_FALSE MODPlayer_IsPlaying, "Player stopped"
    TEST_CASE_END
END SUB

''' @brief Tests for Scream Tracker 3 S3M loading and playback.
SUB Test_MODPlayer_S3M
    TEST_CASE_BEGIN "MODPlayer: Scream Tracker 3 (A Touch of Spring.s3m)"
    TEST_REQUIRE MODPlayer_LoadFromDisk("mods/A Touch of Spring.s3m"), "Load A Touch of Spring.s3m"
    TEST_CHECK INSTR(MODPlayer_GetName, "Touch of Spring") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType = "SCRM", "Song subtype is SCRM"
    TEST_CHECK MODPlayer_GetOrders > 0, "Order count is greater than 0"

    MODPlayer_Play
    TEST_CHECK MODPlayer_IsPlaying, "Playing S3M"
    MODPlayer_Update 0.05
    MODPlayer_Stop
    TEST_CHECK_FALSE MODPlayer_IsPlaying, "Stopped S3M"
    TEST_CASE_END
END SUB

''' @brief Tests for Scream Tracker 3 packed ADPCM sample module loading.
SUB Test_MODPlayer_S3M_Packed
    TEST_CASE_BEGIN "MODPlayer: S3M with ADPCM samples (walkaway_packed.S3M)"
    TEST_REQUIRE MODPlayer_LoadFromDisk("mods/walkaway_packed.S3M"), "Load walkaway_packed.S3M"
    TEST_CHECK INSTR(MODPlayer_GetName, "Walkaway") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType = "SCRM", "Song subtype is SCRM"
    TEST_CHECK MODPlayer_GetOrders > 0, "Order count is greater than 0"

    MODPlayer_Play
    TEST_CHECK MODPlayer_IsPlaying, "Playing packed S3M"
    MODPlayer_Update 0.05
    MODPlayer_Stop
    TEST_CHECK_FALSE MODPlayer_IsPlaying, "Stopped packed S3M"
    TEST_CASE_END
END SUB

''' @brief Tests for MultiTracker MTM loading and playback.
SUB Test_MODPlayer_MTM
    TEST_CASE_BEGIN "MODPlayer: MultiTracker (cougarstory-ii.mtm)"
    TEST_REQUIRE MODPlayer_LoadFromDisk("mods/cougarstory-ii.mtm"), "Load cougarstory-ii.mtm"
    TEST_CHECK INSTR(MODPlayer_GetName, "Cougar story") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType = "MTM1", "Song subtype is MTM1"
    TEST_CHECK MODPlayer_GetOrders > 0, "Order count is greater than 0"

    MODPlayer_Play
    TEST_CHECK MODPlayer_IsPlaying, "Playing MTM"
    MODPlayer_Update 0.05
    MODPlayer_Stop
    TEST_CHECK_FALSE MODPlayer_IsPlaying, "Stopped MTM"
    TEST_CASE_END
END SUB

''' @brief Tests for in-memory module loading.
SUB Test_MODPlayer_Memory
    TEST_CASE_BEGIN "MODPlayer: Load from memory string"
    DIM modBuffer AS STRING
    modBuffer = File_LoadFromDisk("mods/Enigma.mod")
    TEST_REQUIRE LEN(modBuffer) > 0, "Loaded file into memory string"

    TEST_REQUIRE MODPlayer_LoadFromMemory(modBuffer), "Load module from memory buffer"
    TEST_CHECK INSTR(MODPlayer_GetName, "Enigma") > 0, "Song caption matches"
    TEST_CHECK MODPlayer_GetType = "M.K.", "Song subtype matches"

    MODPlayer_Play
    TEST_CHECK MODPlayer_IsPlaying, "Playing from memory load"
    MODPlayer_Stop
    TEST_CHECK_FALSE MODPlayer_IsPlaying, "Stopped"
    TEST_CASE_END
END SUB

''' @brief Tests for error handling and invalid inputs.
SUB Test_MODPlayer_Errors
    TEST_CASE_BEGIN "MODPlayer: Non-existent file"
    TEST_REQUIRE_FALSE MODPlayer_LoadFromDisk("mods/non_existent_file_98765.mod"), "Should return FALSE for missing file"
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: Empty memory buffer"
    TEST_REQUIRE_FALSE MODPlayer_LoadFromMemory(""), "Should return FALSE for empty buffer"
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: Corrupt/Invalid memory buffer"
    TEST_REQUIRE_FALSE MODPlayer_LoadFromMemory("THIS IS NOT A VALID MODULE HEADER AT ALL"), "Should return FALSE for corrupt buffer"
    TEST_CASE_END
END SUB

' Run all test suites
TEST_BEGIN_ALL

Test_AudioConv
Test_SoftSynth
Test_StringFile
Test_AudioAnalyzer
Test_MODPlayer_MOD
Test_MODPlayer_S3M
Test_MODPlayer_S3M_Packed
Test_MODPlayer_MTM
Test_MODPlayer_Memory
Test_MODPlayer_Errors

TEST_END_ALL
