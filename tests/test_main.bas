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
'$INCLUDE:'../source/STMLoader.bi'
'$INCLUDE:'../source/Vector2f.bi'
'$INCLUDE:'../source/Vector3f.bi'
'$INCLUDE:'../source/Background.bi'

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

''' @brief Tests for String.bi string manipulation and tokenization routines.
SUB Test_String
    TEST_CASE_BEGIN "String: String_ConvertToBStr"
    TEST_CHECK String_ConvertToBStr("Hello" + _CHR_NUL + "World") = "Hello", "Extracts prefix before null"
    TEST_CHECK String_ConvertToBStr(_CHR_NUL + "World") = _STR_EMPTY, "Prefix before leading null is empty"
    TEST_CHECK String_ConvertToBStr("NoNullHere") = "NoNullHere", "Returns full string when no null is present"
    TEST_CHECK String_ConvertToBStr(_STR_EMPTY) = _STR_EMPTY, "Empty string returns empty string"
    TEST_CASE_END

    TEST_CASE_BEGIN "String: String_ConvertToCStr"
    DIM cStrResult AS STRING
    cStrResult = String_ConvertToCStr("Hello")
    TEST_CHECK LEN(cStrResult) = 6, "Appended null character increases length by 1"
    TEST_CHECK RIGHT$(cStrResult, 1) = _CHR_NUL, "Last character is null byte"
    TEST_CHECK LEFT$(cStrResult, 5) = "Hello", "Prefix matches original string"
    TEST_CASE_END

    TEST_CASE_BEGIN "String: String_MakePrintable"
    DIM rawStr AS STRING
    rawStr = "Track" + CHR$(0) + CHR$(1) + "Name" + CHR$(31) + "!" + CHR$(127)
    DIM cleanStr AS STRING
    cleanStr = String_MakePrintable(rawStr)
    TEST_CHECK cleanStr = "Track  Name ! ", "Control characters < 32 and 127 are replaced by spaces"
    TEST_CHECK String_MakePrintable("CleanText 123") = "CleanText 123", "Already printable text is unchanged"
    TEST_CHECK String_MakePrintable(_STR_EMPTY) = _STR_EMPTY, "Empty string remains empty"
    TEST_CASE_END

    TEST_CASE_BEGIN "String: String_Tokenize"
    REDIM tokens(0) AS STRING
    DIM tokCount AS LONG

    ' Basic splitting
    tokCount = String_Tokenize("alpha|beta|gamma|delta", "|", _STR_EMPTY, _FALSE, tokens())
    TEST_CHECK tokCount = 4, "Token count is 4 for pipe-delimited list"
    TEST_CHECK tokens(0) = "alpha", "Token 0 is 'alpha'"
    TEST_CHECK tokens(1) = "beta", "Token 1 is 'beta'"
    TEST_CHECK tokens(2) = "gamma", "Token 2 is 'gamma'"
    TEST_CHECK tokens(3) = "delta", "Token 3 is 'delta'"

    ' Consecutive delimiters
    tokCount = String_Tokenize("foo,,bar", ",", _STR_EMPTY, _FALSE, tokens())
    TEST_CHECK tokCount = 2, "Consecutive delimiters do not produce empty tokens"
    TEST_CHECK tokens(0) = "foo", "Token 0 is 'foo'"
    TEST_CHECK tokens(1) = "bar", "Token 1 is 'bar'"

    ' Symmetric quotes
    tokCount = String_Tokenize("'hello world', unquoted, 'another quote'", ", ", "''", _FALSE, tokens())
    TEST_CHECK tokCount = 3, "Quote-enclosed text with spaces is preserved as single token"
    TEST_CHECK tokens(0) = "hello world", "Token 0 is 'hello world'"
    TEST_CHECK tokens(1) = "unquoted", "Token 1 is 'unquoted'"
    TEST_CHECK tokens(2) = "another quote", "Token 2 is 'another quote'"

    ' Asymmetric quotes (e.g. parentheses)
    tokCount = String_Tokenize("(bracketed text) and plain", " ", "()", _FALSE, tokens())
    TEST_CHECK tokCount = 3, "Asymmetric quotes handle opening and closing correctly"
    TEST_CHECK tokens(0) = "bracketed text", "Token 0 is 'bracketed text'"
    TEST_CHECK tokens(1) = "and", "Token 1 is 'and'"
    TEST_CHECK tokens(2) = "plain", "Token 2 is 'plain'"

    ' Return delimiters
    tokCount = String_Tokenize("a+b", "+", _STR_EMPTY, _TRUE, tokens())
    TEST_CHECK tokCount = 3, "returnDelims returns tokens and delimiter"
    TEST_CHECK tokens(0) = "a", "Token 0 is 'a'"
    TEST_CHECK tokens(1) = "+", "Token 1 is '+'"
    TEST_CHECK tokens(2) = "b", "Token 2 is 'b'"

    ' Empty string
    tokCount = String_Tokenize(_STR_EMPTY, ",", _STR_EMPTY, _FALSE, tokens())
    TEST_CHECK tokCount = 0, "Empty string returns 0 tokens"
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
    TEST_CHECK MODPlayer_GetOrders(player) = 78, "Order count is 78"
    TEST_CHECK player.song.channels = 19, "Channel count is 19"
    TEST_CHECK player.song.instruments = 31, "Instrument count is 31"
    TEST_CHECK player.song.patterns = 49, "Pattern count is 49"
    TEST_CHECK INSTR(player.song.comment, "inspekdah") > 0, "Comment contains author text"
    TEST_CHECK INSTR(player.song.comment, CHR$(13) + CHR$(10)) > 0, "Comment is formatted with linebreaks"
    TEST_CHECK player.channel(0).panning = player.channel(0).defaultPanning, "Channel panning matches default"

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
    TEST_CHECK INSTR(player.song.comment, CHR$(13) + CHR$(10)) > 0, "M31 comment contains linebreaks"
    TEST_CHECK INSTR(player.song.comment, "S-U-P-E-R-H-O-U-S-E") > 0, "M31 comment text contains S-U-P-E-R-H-O-U-S-E"
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

''' @brief Tests for dedicated STMLoader.
SUB Test_STMLoader
    TEST_CASE_BEGIN "STMLoader: Load Scream Tracker 2 module directly"
    DIM player AS MODPlayer
    TEST_REQUIRE STMLoader_LoadFromDisk(player, "mods/OXYGENE.STM"), "STMLoader loads OXYGENE.STM"
    TEST_CHECK INSTR(UCASE$(MODPlayer_GetName(player)), "OXYGENE") > 0, "Song caption matches oxygene"
    TEST_CHECK MODPlayer_GetType(player) = "STM", "Song subtype is STM"
    TEST_CHECK player.song.channels = 4, "STM has 4 channels"
    TEST_CHECK player.song.instruments = 31, "STM has 31 instruments"
    TEST_CHECK MODPlayer_GetOrders(player) = 47, "Order count is 47"
    TEST_CHECK player.song.patterns = 16, "Pattern count is 16"
    TEST_CHECK player.song.defaultSpeed = 6, "Default speed is 6"
    TEST_CHECK player.song.defaultBPM = 125, "Default BPM is 125"
    TEST_CHECK ABS(player.song.pcmMasterGain - (48.0! / 128.0!)) < 0.001!, "PCM master gain matches OpenMPT 48/128"
    TEST_CHECK MODPlayer_IsStereo(player), "STM is stereo"
    TEST_CHECK player.song.isS3M = _TRUE, "STM uses S3M playback engine"
    TEST_CHECK player.song.useST2Tempo = _TRUE, "STM sets useST2Tempo flag"
    TEST_CHECK player.song.useST2Vibrato = _TRUE, "STM sets useST2Vibrato flag"
    TEST_CHECK MODPlayer_GetPatternRows(player, 0) = 64, "Pattern 0 has 64 rows"
    TEST_CHECK MODPlayer_GetPatternRows(player, 15) = 64, "Pattern 15 has 64 rows"

    ' Channel panning LRRL (64, 192, 192, 64)
    TEST_CHECK player.channel(0).panning = 64, "Ch 0 panning is 64"
    TEST_CHECK player.channel(1).panning = 192, "Ch 1 panning is 192"
    TEST_CHECK player.channel(2).panning = 192, "Ch 2 panning is 192"
    TEST_CHECK player.channel(3).panning = 64, "Ch 3 panning is 64"

    ' Instrument checks (instrument 0 is hihat.014)
    TEST_CHECK INSTR(LCASE$(player.instrument(0).caption), "hihat") > 0, "Instrument 0 is hihat"
    TEST_CHECK player.instrument(0).length = 1826, "Instrument 0 length is 1826"
    TEST_CHECK player.instrument(0).volume = 64, "Instrument 0 volume is 64"
    TEST_CHECK player.instrument(0).c2Spd = 8448, "Instrument 0 c2Spd is 8448"
    TEST_CHECK player.instrument(0).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD, "Instrument 0 is non-looping"
    TEST_CHECK player.instrument(0).loopEnd = 1826, "Instrument 0 loopEnd equals length for non-looping sample"

    ' Instrument 1 (shallbas.048)
    TEST_CHECK INSTR(LCASE$(player.instrument(1).caption), "shallbas") > 0, "Instrument 1 is shallbas"
    TEST_CHECK player.instrument(1).length = 10498, "Instrument 1 length is 10498"
    TEST_CHECK player.instrument(1).volume = 43, "Instrument 1 volume is 43"

    ' Row 0 notes: Ch 0 has C-4 (note 48), inst 2, effect Speed (A) operand &H40 (from 0x40)
    TEST_CHECK player.pattern(0).note(0, 0).note = 48, "Pat 0 Row 0 Ch 0 note is 48 (C-4)"
    TEST_CHECK player.pattern(0).note(0, 0).instrument = 2, "Pat 0 Row 0 Ch 0 inst is 2"
    TEST_CHECK player.pattern(0).note(0, 0).effect = __MODPLAYER_FX_SPEED, "Pat 0 Row 0 Ch 0 effect is SPEED"
    TEST_CHECK player.pattern(0).note(0, 0).operand = &H40, "Pat 0 Row 0 Ch 0 speed operand is &H40"
    TEST_CHECK player.pattern(0).note(0, 1).note = 60, "Pat 0 Row 0 Ch 1 note is 60 (C-5)"
    TEST_CHECK player.pattern(0).note(0, 2).note = 36, "Pat 0 Row 0 Ch 2 note is 36 (C-3)"
    TEST_CHECK player.pattern(0).note(0, 3).note = 36, "Pat 0 Row 0 Ch 3 note is 36 (C-3)"
    TEST_CASE_END

    TEST_CASE_BEGIN "STMLoader: Load from memory"
    DIM stmBuf AS STRING: stmBuf = File_LoadFromDisk("mods/OXYGENE.STM")
    TEST_REQUIRE STMLoader_LoadFromMemory(player, stmBuf), "STMLoader loads from memory"
    TEST_CHECK MODPlayer_GetType(player) = "STM", "Subtype is STM"
    TEST_CHECK player.song.orders = 47, "Orders is 47"
    TEST_CHECK player.song.patterns = 16, "Patterns is 16"
    TEST_CASE_END

    TEST_CASE_BEGIN "STMLoader: Unified dispatcher auto-detection"
    DIM pAuto AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pAuto, "mods/OXYGENE.STM"), "MODPlayer_LoadFromDisk auto-detects STM"
    TEST_CHECK MODPlayer_GetType(pAuto) = "STM", "Auto-detected subtype is STM"
    TEST_CHECK pAuto.song.channels = 4, "Auto-detected channels is 4"
    MODPlayer_Finalize pAuto
    TEST_CASE_END

    TEST_CASE_BEGIN "STMLoader: Playback and teardown"
    MODPlayer_Play player
    TEST_CHECK MODPlayer_IsPlaying(player), "STM is playing"
    MODPlayer_Update player, 0.05
    TEST_CHECK MODPlayer_IsPlaying(player), "STM continues playing after update"
    MODPlayer_Stop player
    TEST_CHECK_FALSE MODPlayer_IsPlaying(player), "STM stopped"
    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "STMLoader: Reject incompatible formats"
    TEST_CHECK_FALSE STMLoader_LoadFromDisk(player, "mods/Enigma.mod"), "STMLoader rejects MOD"
    TEST_CHECK_FALSE STMLoader_LoadFromDisk(player, "mods/A Touch of Spring.s3m"), "STMLoader rejects S3M"
    TEST_CHECK_FALSE STMLoader_LoadFromDisk(player, "mods/cougarstory-ii.mtm"), "STMLoader rejects MTM"
    TEST_CHECK_FALSE STMLoader_LoadFromDisk(player, "mods/M31.far"), "STMLoader rejects FAR"
    DIM emptyBuf AS STRING: emptyBuf = STRING$(100, 0)
    TEST_CHECK_FALSE STMLoader_LoadFromMemory(player, emptyBuf), "STMLoader rejects undersized buffer"
    MODPlayer_Finalize player
    TEST_CASE_END
END SUB

''' @brief Tests for Composer 669 / UNIS 669 format loader.
SUB Test_C669Loader
    TEST_CASE_BEGIN "C669Loader: Load Composer 669 module directly"
    DIM player AS MODPlayer
    TEST_REQUIRE C669Loader_LoadFromDisk(player, "mods/crystals.669"), "C669Loader loads crystals.669"
    TEST_CHECK INSTR(UCASE$(MODPlayer_GetName(player)), "CRYSTALS") > 0, "Song caption matches crystals"
    TEST_CHECK MODPlayer_GetType(player) = "669", "Song subtype is 669"
    TEST_CHECK player.song.channels = 8, "Channels count is 8"
    TEST_CHECK player.song.instruments = 1, "Instruments count is 1"
    TEST_CHECK player.song.patterns = 11, "Patterns count is 11"
    TEST_CHECK player.song.orders > 0, "Orders count > 0"
    TEST_CHECK player.song.BPM = 78, "Default BPM is 78"
    TEST_CHECK player.song.speed = 5, "Initial speed from pattern 0 is 5"
    TEST_CHECK player.song.isStereo, "Stereo flag is true"
    TEST_CHECK player.instrument(0).length > 0, "Sample 0 has length"
    TEST_CHECK player.instrument(0).channels = 1, "Sample 0 channels is 1"
    TEST_CHECK player.instrument(0).c2Spd = 8363, "Sample 0 c2Spd is 8363"
    TEST_CHECK player.channel(0).panning = 48, "Channel 0 is Left (48)"
    TEST_CHECK player.channel(1).panning = 208, "Channel 1 is Right (208)"
    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "C669Loader: Load from memory"
    DIM buf AS STRING: buf = File_Load("mods/crystals.669")
    TEST_REQUIRE LEN(buf) > 0, "Read crystals.669 into buffer"
    DIM pMem AS MODPlayer
    TEST_REQUIRE C669Loader_LoadFromMemory(pMem, buf), "C669Loader loads from memory"
    TEST_CHECK MODPlayer_GetType(pMem) = "669", "Memory load subtype is 669"
    TEST_CHECK pMem.song.channels = 8, "Memory load channels is 8"
    TEST_CHECK pMem.song.patterns = 11, "Memory load patterns is 11"
    MODPlayer_Finalize pMem
    TEST_CASE_END

    TEST_CASE_BEGIN "C669Loader: Unified dispatcher auto-detection"
    DIM pAuto AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pAuto, "mods/crystals.669"), "MODPlayer_LoadFromDisk auto-detects 669"
    TEST_CHECK MODPlayer_GetType(pAuto) = "669", "Auto-detected subtype is 669"
    TEST_CHECK pAuto.song.channels = 8, "Auto-detected channels is 8"
    MODPlayer_Finalize pAuto
    TEST_CASE_END

    TEST_CASE_BEGIN "C669Loader: Playback and teardown"
    DIM pPlay AS MODPlayer
    TEST_REQUIRE C669Loader_LoadFromDisk(pPlay, "mods/crystals.669"), "Reload crystals for playback test"
    MODPlayer_Play pPlay
    TEST_CHECK MODPlayer_IsPlaying(pPlay), "669 is playing"
    MODPlayer_Update pPlay, 0.05
    TEST_CHECK MODPlayer_IsPlaying(pPlay), "669 continues playing after update"
    TEST_CHECK SoftSynth_GetActiveVoices(pPlay.synth) > 0, "669 has active voices sounding"
    TEST_CHECK pPlay.channel(0).period > 0, "669 channel 0 period is non-zero"
    MODPlayer_Stop pPlay
    TEST_CHECK_FALSE MODPlayer_IsPlaying(pPlay), "669 stopped"
    MODPlayer_Finalize pPlay
    TEST_CASE_END

    TEST_CASE_BEGIN "C669Loader: Reject incompatible formats"
    DIM pRej AS MODPlayer
    TEST_CHECK_FALSE C669Loader_LoadFromDisk(pRej, "mods/Enigma.mod"), "C669Loader rejects MOD"
    TEST_CHECK_FALSE C669Loader_LoadFromDisk(pRej, "mods/A Touch of Spring.s3m"), "C669Loader rejects S3M"
    TEST_CHECK_FALSE C669Loader_LoadFromDisk(pRej, "mods/cougarstory-ii.mtm"), "C669Loader rejects MTM"
    TEST_CHECK_FALSE C669Loader_LoadFromDisk(pRej, "mods/M31.far"), "C669Loader rejects FAR"
    TEST_CHECK_FALSE C669Loader_LoadFromDisk(pRej, "mods/OXYGENE.STM"), "C669Loader rejects STM"
    DIM emptyBuf2 AS STRING: emptyBuf2 = STRING$(100, 0)
    TEST_CHECK_FALSE C669Loader_LoadFromMemory(pRej, emptyBuf2), "C669Loader rejects undersized buffer"
    MODPlayer_Finalize pRej
    TEST_CASE_END
END SUB

''' @brief Tests for 669 effect decoding and synthetic module parsing.
SUB Test_C669_Effects
    TEST_CASE_BEGIN "C669 Effects: Synthetic 669 Module Loading and Effect Translation"
    DIM b AS STRING
    b = "if" ' Magic
    b = b + "Synthetic 669 Test Song" + STRING$(108 - LEN("Synthetic 669 Test Song"), 0) ' Song message (108 bytes)
    b = b + CHR$(1) ' 1 sample
    b = b + CHR$(1) ' 1 pattern
    b = b + CHR$(0) ' Restart pos 0

    ' Orders (128 bytes)
    b = b + CHR$(0) + STRING$(127, 255)
    ' Tempo list (128 bytes) - Pattern 0 speed = 6
    b = b + CHR$(6) + STRING$(127, 0)
    ' Breaks list (128 bytes) - Pattern 0 break = 63
    b = b + CHR$(63) + STRING$(127, 0)

    ' Sample header (25 bytes)
    b = b + "TEST.SMP" + STRING$(5, 0) ' 13 bytes filename
    b = b + MKL$(16) ' Length 16
    b = b + MKL$(0) ' Loop start 0
    b = b + MKL$(0) ' Loop end 0

    ' Pattern 0 (1536 bytes): 64 rows * 8 channels * 3 bytes
    DIM patData AS STRING
    DIM r AS LONG, c AS LONG
    FOR r = 0 TO 63
        FOR c = 0 TO 7
            IF r = 0 THEN
                SELECT CASE c
                    CASE 0 ' Note 12 (C-1 -> note 48), instr 0 (sample 1), vol 15 (vol 64), Effect 0 param 3 (Porta Up)
                        patData = patData + CHR$(_SHL(12, 2) OR 0) + CHR$(_SHL(0, 4) OR 15) + CHR$(_SHL(0, 4) OR 3)
                    CASE 1 ' Note 24 (C-2 -> note 60), instr 0, vol 10 (vol (10*64+8)\15 = 43), Effect 1 param 5 (Porta Down)
                        patData = patData + CHR$(_SHL(24, 2) OR 0) + CHR$(_SHL(0, 4) OR 10) + CHR$(_SHL(1, 4) OR 5)
                    CASE 2 ' Note 0 (C-0 -> note 36), instr 0, vol 0 (vol 0), Effect 2 param 8 (Tone Porta)
                        patData = patData + CHR$(_SHL(0, 2) OR 0) + CHR$(_SHL(0, 4) OR 0) + CHR$(_SHL(2, 4) OR 8)
                    CASE 3 ' Note FE (no note, vol change), vol 7 (vol (7*64+8)\15 = 30), Effect 3 param 2 (Freq adjust)
                        patData = patData + CHR$(&HFE) + CHR$(_SHL(0, 4) OR 7) + CHR$(_SHL(3, 4) OR 2)
                    CASE 4 ' Note FF (no note, no vol), Effect 4 param 4 (Vibrato)
                        patData = patData + CHR$(&HFF) + CHR$(&HFF) + CHR$(_SHL(4, 4) OR 4)
                    CASE 5 ' Note FF, Effect 5 param 7 (Set speed)
                        patData = patData + CHR$(&HFF) + CHR$(&HFF) + CHR$(_SHL(5, 4) OR 7)
                    CASE ELSE
                        patData = patData + CHR$(&HFF) + CHR$(&HFF) + CHR$(&HFF)
                END SELECT
            ELSE
                patData = patData + CHR$(&HFF) + CHR$(&HFF) + CHR$(&HFF)
            END IF
        NEXT c
    NEXT r
    b = b + patData

    ' Sample payload (16 bytes of unsigned PCM, center 128)
    b = b + STRING$(16, 128)

    DIM player AS MODPlayer
    TEST_REQUIRE C669Loader_LoadFromMemory(player, b), "Synthetic 669 module loaded"
    TEST_CHECK player.song.channels = 8, "8 channels"
    TEST_CHECK player.song.patterns = 1, "1 pattern"
    TEST_CHECK player.song.instruments = 1, "1 instrument"
    TEST_CHECK player.song.speed = 6, "Initial speed is 6"

    ' Channel 0: Note 48, Instrument 1, Volume 64, Effect 1, Operand 3
    TEST_CHECK player.pattern(0).note(0, 0).note = 48, "Ch 0 note is 48"
    TEST_CHECK player.pattern(0).note(0, 0).instrument = 1, "Ch 0 instrument is 1"
    TEST_CHECK player.pattern(0).note(0, 0).volume = 64, "Ch 0 volume is 64"
    TEST_CHECK player.pattern(0).note(0, 0).effect = 1, "Ch 0 effect is 1 (Porta Up)"
    TEST_CHECK player.pattern(0).note(0, 0).operand = 3, "Ch 0 operand is 3"

    ' Channel 1: Note 60, Instrument 1, Volume 43, Effect 2, Operand 5
    TEST_CHECK player.pattern(0).note(0, 1).note = 60, "Ch 1 note is 60"
    TEST_CHECK player.pattern(0).note(0, 1).volume = 43, "Ch 1 volume is 43"
    TEST_CHECK player.pattern(0).note(0, 1).effect = 2, "Ch 1 effect is 2 (Porta Down)"
    TEST_CHECK player.pattern(0).note(0, 1).operand = 5, "Ch 1 operand is 5"

    ' Channel 2: Note 36, Volume 0, Effect 3, Operand 8
    TEST_CHECK player.pattern(0).note(0, 2).note = 36, "Ch 2 note is 36"
    TEST_CHECK player.pattern(0).note(0, 2).volume = 0, "Ch 2 volume is 0"
    TEST_CHECK player.pattern(0).note(0, 2).effect = 3, "Ch 2 effect is 3 (Tone Porta)"
    TEST_CHECK player.pattern(0).note(0, 2).operand = 8, "Ch 2 operand is 8"

    ' Channel 3: Note none, Volume 30, Effect &H0E, Operand &H12
    TEST_CHECK player.pattern(0).note(0, 3).note = __MODPLAYER_NOTE_NONE, "Ch 3 has no note"
    TEST_CHECK player.pattern(0).note(0, 3).volume = 30, "Ch 3 volume is 30"
    TEST_CHECK player.pattern(0).note(0, 3).effect = &H0E, "Ch 3 effect is &H0E (Fine Porta)"
    TEST_CHECK player.pattern(0).note(0, 3).operand = &H12, "Ch 3 operand is &H12"

    ' Channel 4: Vibrato effect 4
    TEST_CHECK player.pattern(0).note(0, 4).effect = 4, "Ch 4 effect is 4 (Vibrato)"
    TEST_CHECK player.pattern(0).note(0, 4).operand = &H44, "Ch 4 operand is &H44"

    ' Channel 5: Set speed effect &H0F
    TEST_CHECK player.pattern(0).note(0, 5).effect = &H0F, "Ch 5 effect is &H0F (Set Speed)"
    TEST_CHECK player.pattern(0).note(0, 5).operand = 7, "Ch 5 operand is 7"

    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "C669 Effects: Extended UNIS 669 Effects (JN)"
    ' Build extended UNIS module
    MID$(b, 1, 2) = "JN"
    ' In pattern row 0: channel 6 = Effect 6 param 0 (balance left), channel 7 = Effect 7 param 4 (slot retrig)
    DIM ch6Pos AS LONG: ch6Pos = __C669LOADER_HEADER_SIZE + 25 + 6 * 3 + 1
    MID$(b, ch6Pos, 3) = CHR$(&HFF) + CHR$(&HFF) + CHR$(_SHL(6, 4) OR 0)
    DIM ch7Pos AS LONG: ch7Pos = __C669LOADER_HEADER_SIZE + 25 + 7 * 3 + 1
    MID$(b, ch7Pos, 3) = CHR$(&HFF) + CHR$(&HFF) + CHR$(_SHL(7, 4) OR 4)

    DIM pExt AS MODPlayer
    TEST_REQUIRE C669Loader_LoadFromMemory(pExt, b), "Extended UNIS 669 loaded"
    TEST_CHECK pExt.pattern(0).note(0, 6).effect = &H18, "Ch 6 balance effect is &H18 (panning)"
    TEST_CHECK pExt.pattern(0).note(0, 6).operand = 0, "Ch 6 operand is 0 (pan left)"
    TEST_CHECK pExt.pattern(0).note(0, 7).effect = &H0E, "Ch 7 slot retrig effect is &H0E"
    TEST_CHECK pExt.pattern(0).note(0, 7).operand = &H94, "Ch 7 operand is &H94 (retrig)"
    MODPlayer_Finalize pExt
    TEST_CASE_END
END SUB

''' @brief Tests for Reality Adlib Tracker (RAD) v1.0 loader.
SUB Test_RADLoader
    TEST_CASE_BEGIN "RADLoader: Load RAD v1.0 module from disk"
    DIM player AS MODPlayer
    TEST_REQUIRE RADLoader_LoadFromDisk(player, "mods/ALLOYRUN.RAD"), "RADLoader loads ALLOYRUN.RAD"
    TEST_CHECK MODPlayer_GetType(player) = "RAD", "Song subtype is RAD"
    TEST_CHECK player.song.isRAD, "isRAD flag is true"
    TEST_CHECK player.song.channels = 9, "RAD song has 9 channels"
    TEST_CHECK player.song.instruments > 0, "RAD song has instruments"
    TEST_CHECK player.song.orders > 0, "RAD song has orders"
    TEST_CHECK player.song.patterns > 0, "RAD song has patterns"
    TEST_CHECK player.song.BPM > 0, "RAD song has BPM"
    TEST_CHECK player.song.speed > 0, "RAD song has speed"
    TEST_CHECK player.song.hasFMChannels, "Song has FM channels flag set"
    TEST_CHECK player.channel(0).subtype = __MODPLAYER_INSTRUMENT_FM_MELODY, "Channel 0 is FM melody"
    TEST_CHECK player.channel(8).subtype = __MODPLAYER_INSTRUMENT_FM_MELODY, "Channel 8 is FM melody"
    TEST_CHECK player.channel(0).oplChannel = 0, "Channel 0 mapped to OPL channel 0"
    TEST_CHECK player.channel(8).oplChannel = 8, "Channel 8 mapped to OPL channel 8"
    TEST_CHECK player.instrument(0).subtype = __MODPLAYER_INSTRUMENT_FM_MELODY, "Instrument 0 is FM melody"
    TEST_CHECK player.instrument(0).c2Spd = 8363, "Instrument 0 c2Spd is 8363"
    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "RADLoader: Load from memory"
    DIM buf AS STRING: buf = File_Load("mods/ADLIBSP.RAD")
    TEST_REQUIRE LEN(buf) > 0, "Read ADLIBSP.RAD into buffer"
    DIM pMem AS MODPlayer
    TEST_REQUIRE RADLoader_LoadFromMemory(pMem, buf), "RADLoader loads from memory"
    TEST_CHECK MODPlayer_GetType(pMem) = "RAD", "Memory load subtype is RAD"
    TEST_CHECK pMem.song.channels = 9, "Memory load channels is 9"
    TEST_CHECK pMem.song.isRAD, "Memory load isRAD is true"
    MODPlayer_Finalize pMem
    TEST_CASE_END

    TEST_CASE_BEGIN "RADLoader: Unified dispatcher auto-detection"
    DIM pAuto AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pAuto, "mods/ALLOYRUN.RAD"), "Unified loader loads ALLOYRUN.RAD"
    TEST_CHECK MODPlayer_GetType(pAuto) = "RAD", "Auto-detected subtype is RAD"
    TEST_CHECK pAuto.song.channels = 9, "Auto-detected channels count is 9"
    MODPlayer_Finalize pAuto
    TEST_CASE_END

    TEST_CASE_BEGIN "RADLoader: Rejection of invalid data and v2"
    DIM pFail AS MODPlayer
    DIM dummyBuf AS STRING: dummyBuf = STRING$(100, 0)
    TEST_CHECK_FALSE RADLoader_LoadFromMemory(pFail, dummyBuf), "Rejects invalid header magic"

    ' Header with "RAD by REALiTY!!" but version 0x21 (v2)
    DIM v2Buf AS STRING: v2Buf = "RAD by REALiTY!!" + CHR$(&H21) + STRING$(100, 0)
    TEST_CHECK_FALSE RADLoader_LoadFromMemory(pFail, v2Buf), "Rejects version 0x21 (v2)"
    MODPlayer_Finalize pFail
    TEST_CASE_END
END SUB

''' @brief Tests for RAD v1.0 playback and audio rendering.
SUB Test_RAD_Playback
    TEST_CASE_BEGIN "RAD: Playback and audio synthesis"
    DIM player AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(player, "mods/ALLOYRUN.RAD"), "Load ALLOYRUN.RAD for playback test"
    MODPlayer_Play player
    TEST_CHECK player.song.isPlaying, "Player is in playing state"
    TEST_CHECK Opal_GetChipType(player.opl) = OPAL_CHIP_TYPE_OPL2, "Chip type is OPL2 during RAD playback"

    ' Update player across multiple rows to allow notes to trigger
    DIM u AS LONG
    FOR u = 1 TO 200
        MODPlayer_Update player, 0.05
    NEXT u

    ' Verify non-zero synthesized audio frames in soundBuffer
    DIM hasAudio AS _BYTE: hasAudio = _FALSE
    DIM i AS LONG
    FOR i = 0 TO UBOUND(player.synth.soundBuffer)
        IF player.synth.soundBuffer(i) <> 0! THEN
            hasAudio = _TRUE
            EXIT FOR
        END IF
    NEXT i
    TEST_CHECK hasAudio, "Synthesized audible OPL audio during RAD playback"

    MODPlayer_Stop player
    TEST_CHECK_FALSE player.song.isPlaying, "Player stopped"
    MODPlayer_Finalize player
    TEST_CASE_END

    TEST_CASE_BEGIN "RAD: Load and playback all bundled RAD files"
    DIM radFiles(0 TO 12) AS STRING
    radFiles(0) = "mods/ADLIBSP.RAD"
    radFiles(1) = "mods/ALLOYRUN.RAD"
    radFiles(2) = "mods/CRYSTAL2.RAD"
    radFiles(3) = "mods/HANGOVER.RAD"
    radFiles(4) = "mods/HUBBARD.RAD"
    radFiles(5) = "mods/NEOINTRO.RAD"
    radFiles(6) = "mods/RASTER.RAD"
    radFiles(7) = "mods/REVENGE.RAD"
    radFiles(8) = "mods/SHOOT.RAD"
    radFiles(9) = "mods/SMJOOP.RAD"
    radFiles(10) = "mods/SP2.RAD"
    radFiles(11) = "mods/TERRANIA.RAD"
    radFiles(12) = "mods/WVCHILD.RAD"

    DIM rIdx AS LONG
    FOR rIdx = 0 TO 12
        DIM radPlayer AS MODPlayer
        TEST_REQUIRE MODPlayer_LoadFromDisk(radPlayer, radFiles(rIdx)), "Load " + radFiles(rIdx)
        TEST_CHECK MODPlayer_GetType(radPlayer) = "RAD", "Subtype is RAD: " + radFiles(rIdx)
        TEST_CHECK radPlayer.song.isRAD, "isRAD flag is true: " + radFiles(rIdx)
        TEST_CHECK radPlayer.song.channels = 9, "Channel count is 9: " + radFiles(rIdx)
        TEST_CHECK radPlayer.song.instruments > 0, "Has instruments: " + radFiles(rIdx)
        TEST_CHECK radPlayer.song.orders > 0, "Has orders: " + radFiles(rIdx)
        TEST_CHECK radPlayer.song.patterns > 0, "Has patterns: " + radFiles(rIdx)

        MODPlayer_Play radPlayer
        TEST_CHECK radPlayer.song.isPlaying, "Is playing: " + radFiles(rIdx)
        DIM tickU AS LONG
        FOR tickU = 1 TO 20
            MODPlayer_Update radPlayer, 0.05
        NEXT tickU
        MODPlayer_Stop radPlayer
        TEST_CHECK_FALSE radPlayer.song.isPlaying, "Stopped: " + radFiles(rIdx)
        MODPlayer_Finalize radPlayer
    NEXT rIdx
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

''' @brief Tests for Opal OPL2 and OPL3 mode controls, bank aliasing rejection, and waveform gating.
SUB Test_Opal_OPL2_OPL3_Modes
    TEST_CASE_BEGIN "Opal: OPL2 vs OPL3 mode differentiation and bank isolation"
    DIM chip AS Opal
    Opal_Initialize chip, 49716

    TEST_CHECK Opal_GetChipType(chip) = OPAL_CHIP_TYPE_OPL3, "Default chip type is OPL3"
    TEST_CHECK_FALSE Opal_IsOPL3(chip), "Chip starts in OPL2 compatibility mode (newMode = 0)"

    ' Write to Bank 0 operator 0 multiple = 1
    Opal_Write chip, &H20, 1
    TEST_CHECK chip.op(0).multiple = 1, "Bank 0 operator 0 MULT is 1"

    ' While in OPL2 compatibility mode (newMode = 0), write to Bank 1 (&H120).
    ' On real hardware, writes to Bank 1 registers (>= 0x100) must be ignored and MUST NOT overwrite Bank 0.
    Opal_Write chip, &H120, 7
    TEST_CHECK chip.op(0).multiple = 1, "Bank 1 write was rejected and did NOT overwrite Bank 0 operator 0"
    TEST_CHECK chip.op(18).multiple = 0, "Bank 1 operator 18 was not modified in OPL2 mode"

    ' Set strict OPL2 chip mode
    Opal_SetChipType chip, OPAL_CHIP_TYPE_OPL2
    TEST_CHECK Opal_GetChipType(chip) = OPAL_CHIP_TYPE_OPL2, "Chip type set to OPAL_CHIP_TYPE_OPL2"

    ' In strict OPL2 mode, writes to &H105 must be rejected
    Opal_Write chip, &H105, 1
    TEST_CHECK_FALSE Opal_IsOPL3(chip), "Strict OPL2 mode rejects &H105 write and stays in OPL2 mode"

    ' Test waveform gating by waveSelectEnable (reg 0x01 bit 5) in OPL2 mode
    Opal_Write chip, &HE0, 2 ' Operator 0 waveform = 2
    TEST_CHECK chip.op(0).waveform = 2, "Operator 0 waveform register set to 2"

    ' Ensure waveSelectEnable is 0
    Opal_Write chip, &H01, 0
    TEST_CHECK chip.waveSelectEnable = 0, "waveSelectEnable is 0"

    ' Set waveSelectEnable = 1
    Opal_Write chip, &H01, &H20
    TEST_CHECK chip.waveSelectEnable = 1, "waveSelectEnable set to 1 via reg 0x01 bit 5"

    ' Switch back to OPL3 mode and activate newMode
    Opal_SetChipType chip, OPAL_CHIP_TYPE_OPL3
    Opal_Write chip, &H105, 1
    TEST_CHECK Opal_IsOPL3(chip), "OPL3 mode activated via reg 0x105"

    ' Now Bank 1 writes should be accepted
    Opal_Write chip, &H120, 7
    TEST_CHECK chip.op(18).multiple = 7, "Bank 1 operator 18 MULT is now 7 in OPL3 mode"
    TEST_CHECK chip.op(0).multiple = 1, "Bank 0 operator 0 MULT unchanged at 1"

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

    TEST_CASE_BEGIN "MODPlayer: AM envelope step & stage progression"
    DIM pEnv AS MODPlayer
    TEST_REQUIRE MODPlayer_Initialize(pEnv), "Init player for envelope test"
    REDIM pEnv.channel(0 TO 0) AS __MODPLAYERCHANNEL
    
    ' Case A: rate = 0 and curLevel = target -> advances immediately
    pEnv.channel(0).amLevel = 100
    pEnv.channel(0).amStage = __MODPLAYER_AM_STAGE_ATTACK1
    __MODPlayer_TickAMEnvelope pEnv, 0, 100, 0, __MODPLAYER_AM_STAGE_ATTACK2
    TEST_CHECK pEnv.channel(0).amStage = __MODPLAYER_AM_STAGE_ATTACK2, "Rate 0 at target advances to ATTACK2"
    TEST_CHECK pEnv.channel(0).amLevel = 100, "Level unchanged at 100"

    ' Case B: rate = 0 and curLevel <> target -> holds indefinitely
    __MODPlayer_TickAMEnvelope pEnv, 0, 200, 0, __MODPLAYER_AM_STAGE_DECAY
    TEST_CHECK pEnv.channel(0).amStage = __MODPLAYER_AM_STAGE_ATTACK2, "Rate 0 below target holds stage"
    TEST_CHECK pEnv.channel(0).amLevel = 100, "Level unchanged at 100"

    ' Case C: linear upward step
    __MODPlayer_TickAMEnvelope pEnv, 0, 120, 15, __MODPLAYER_AM_STAGE_DECAY
    TEST_CHECK pEnv.channel(0).amLevel = 115, "Linear step up +15 reaches 115"
    TEST_CHECK pEnv.channel(0).amStage = __MODPLAYER_AM_STAGE_ATTACK2, "Not yet at target 120"
    __MODPlayer_TickAMEnvelope pEnv, 0, 120, 15, __MODPLAYER_AM_STAGE_DECAY
    TEST_CHECK pEnv.channel(0).amLevel = 120, "Linear step up clamps to target 120"
    TEST_CHECK pEnv.channel(0).amStage = __MODPLAYER_AM_STAGE_DECAY, "Target reached advances to DECAY"

    ' Case D: linear downward step
    __MODPlayer_TickAMEnvelope pEnv, 0, 50, 40, __MODPLAYER_AM_STAGE_SUSTAIN
    TEST_CHECK pEnv.channel(0).amLevel = 80, "Linear step down -40 reaches 80"
    __MODPlayer_TickAMEnvelope pEnv, 0, 50, 40, __MODPLAYER_AM_STAGE_SUSTAIN
    TEST_CHECK pEnv.channel(0).amLevel = 50, "Linear step down clamps to 50"
    TEST_CHECK pEnv.channel(0).amStage = __MODPLAYER_AM_STAGE_SUSTAIN, "Target reached advances to SUSTAIN"
    MODPlayer_Finalize pEnv
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: AM voice silencing on instrument change and cut"
    DIM pSil AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pSil, "mods/amsyntdemo.mod"), "Load amsyntdemo for cut test"
    ' Trigger instrument 0 on channel 0
    pSil.channel(0).instrument = 0
    __MODPlayer_PlayPCMChannelVoice pSil, 0
    TEST_CHECK pSil.channel(0).subtype = __MODPLAYER_INSTRUMENT_AM_SYNTH, "Channel 0 is AM synth"
    TEST_CHECK pSil.channel(0).amStage = __MODPLAYER_AM_STAGE_ATTACK2, "Inst 1 startLevel=256=A1L advances to ATTACK2"
    TEST_CHECK pSil.synth.voices(0).sound <> SOFTSYNTH_VOICE_NO_SOUND, "Voice 0 is assigned and playing"

    ' Simulate instrument number without note on AM channel -> cuts voice
    pSil.channel(0).instrument = 1 ' new instrument
    IF pSil.channel(0).subtype = __MODPLAYER_INSTRUMENT_AM_SYNTH _ORELSE pSil.instrument(1).subtype = __MODPLAYER_INSTRUMENT_AM_SYNTH THEN
        pSil.channel(0).amLevel = 0
        pSil.channel(0).amStage = __MODPLAYER_AM_STAGE_IDLE
        SoftSynth_StopVoice pSil.synth, 0
        SoftSynth_SetVoiceVolume pSil.synth, 0, 0!
    END IF
    TEST_CHECK pSil.synth.voices(0).sound = SOFTSYNTH_VOICE_NO_SOUND, "Voice 0 is stopped on ins # without note"
    TEST_CHECK pSil.channel(0).amStage = __MODPLAYER_AM_STAGE_IDLE, "AM stage is IDLE"
    TEST_CHECK pSil.channel(0).amLevel = 0, "AM level is 0"
    MODPlayer_Finalize pSil
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: __MODPlayer_IsFMChannel predicate"
    TEST_CHECK_FALSE __MODPlayer_IsFMChannel(__MODPLAYER_INSTRUMENT_PCM), "PCM is not FM"
    TEST_CHECK_FALSE __MODPlayer_IsFMChannel(__MODPLAYER_INSTRUMENT_AM_SYNTH), "AM synth is not FM"
    TEST_CHECK_FALSE __MODPlayer_IsFMChannel(__MODPLAYER_INSTRUMENT_NONE), "None is not FM"
    TEST_CHECK __MODPlayer_IsFMChannel(__MODPLAYER_INSTRUMENT_FM_MELODY), "FM Melody is FM"
    TEST_CHECK __MODPlayer_IsFMChannel(__MODPLAYER_INSTRUMENT_FM_BASSDRUM), "FM Bass Drum is FM"
    TEST_CHECK __MODPlayer_IsFMChannel(__MODPLAYER_INSTRUMENT_FM_HIHAT), "FM HiHat is FM"
    TEST_CASE_END

    TEST_CASE_BEGIN "MODPlayer: AM tick progression and decay during playback"
    DIM pDecay AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pDecay, "mods/amsyntdemo.mod"), "Load amsyntdemo for decay test"
    MODPlayer_Play pDecay
    __MODPlayer_UpdateRow pDecay
    DIM initialStage AS _UNSIGNED _BYTE: initialStage = pDecay.channel(0).amStage
    DIM initialLevel AS LONG: initialLevel = pDecay.channel(0).amLevel
    DIM tickIdx AS LONG
    FOR tickIdx = 1 TO pDecay.song.speed - 1
        pDecay.song.tick = tickIdx
        __MODPlayer_UpdateTick pDecay
    NEXT tickIdx
    pDecay.song.tick = 0
    pDecay.song.patternRow = pDecay.song.patternRow + 1
    __MODPlayer_UpdateRow pDecay
    FOR tickIdx = 1 TO pDecay.song.speed - 1
        pDecay.song.tick = tickIdx
        __MODPlayer_UpdateTick pDecay
    NEXT tickIdx
    TEST_CHECK pDecay.channel(0).amLevel < initialLevel _ORELSE pDecay.channel(0).amStage > initialStage, "AM envelope progresses/decays on ticks > 0"
    MODPlayer_Stop pDecay
    MODPlayer_Finalize pDecay
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

''' @brief Unit tests for classic ProTracker .MOD effect implementations and OpenMPT/libxmp crosschecks.
SUB Test_MOD_Effects
    TEST_CASE_BEGIN "MOD Effects: Sample Offset (9xx and 900 recall)"
    DIM pOff AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pOff, "mods/Enigma.mod"), "Load Enigma.mod"
    ' Simulate row tick with 902 (offset = 512 bytes)
    pOff.pattern(0).note(0, 0).effect = __MODPLAYER_FX_SAMPLE_OFFSET
    pOff.pattern(0).note(0, 0).operand = 2
    pOff.pattern(0).note(0, 0).note = 36 ' C-3
    pOff.pattern(0).note(0, 0).instrument = 1
    pOff.song.tickPattern = 0
    pOff.song.tickPatternRow = 0
    __MODPlayer_UpdateRow pOff
    TEST_CHECK pOff.channel(0).lastSampleOffset = 2, "902 sets lastSampleOffset to 2"
    TEST_CHECK pOff.channel(0).startPosition = 512, "902 sets startPosition to 512"

    ' Now test 900 recalls previous offset
    pOff.pattern(0).note(1, 0).effect = __MODPLAYER_FX_SAMPLE_OFFSET
    pOff.pattern(0).note(1, 0).operand = 0
    pOff.pattern(0).note(1, 0).note = 36
    pOff.pattern(0).note(1, 0).instrument = 1
    pOff.song.tickPatternRow = 1
    __MODPlayer_UpdateRow pOff
    TEST_CHECK pOff.channel(0).startPosition = 512, "900 recalls offset memory (512 bytes)"
    MODPlayer_Finalize pOff
    TEST_CASE_END

    TEST_CASE_BEGIN "MOD Effects: Note Cut (EC0 on tick 0)"
    DIM pCut AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pCut, "mods/Enigma.mod"), "Load Enigma.mod"
    pCut.pattern(0).note(0, 0).note = 36
    pCut.pattern(0).note(0, 0).instrument = 1
    pCut.pattern(0).note(0, 0).effect = __MODPLAYER_FX_EXT
    pCut.pattern(0).note(0, 0).operand = &HC0 ' EC0
    pCut.song.tickPattern = 0
    pCut.song.tickPatternRow = 0
    __MODPlayer_UpdateRow pCut
    TEST_CHECK pCut.channel(0).volume = 0, "EC0 silences channel volume immediately on tick 0"
    MODPlayer_Finalize pCut
    TEST_CASE_END

    TEST_CASE_BEGIN "MOD Effects: Speed 0 protection (F00 does not clear speed)"
    DIM pSpd AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pSpd, "mods/Enigma.mod"), "Load Enigma.mod"
    DIM origSpeed AS LONG: origSpeed = pSpd.song.speed
    DIM chClear AS LONG
    FOR chClear = 0 TO pSpd.song.channels - 1
        pSpd.pattern(0).note(0, chClear).effect = 0
        pSpd.pattern(0).note(0, chClear).operand = 0
    NEXT chClear
    pSpd.pattern(0).note(0, 0).effect = __MODPLAYER_FX_SPEED_TEMPO
    pSpd.pattern(0).note(0, 0).operand = 0 ' F00
    pSpd.song.tickPattern = 0
    pSpd.song.tickPatternRow = 0
    __MODPlayer_UpdateRow pSpd
    TEST_CHECK pSpd.song.speed = origSpeed, "F00 is guarded and does not set speed to 0"
    MODPlayer_Finalize pSpd
    TEST_CASE_END

    TEST_CASE_BEGIN "MOD Effects: Amiga LED Filter (E00 on, E01 off)"
    DIM pFlt AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pFlt, "mods/Enigma.mod"), "Load Enigma.mod"
    ' E00 turns filter on
    pFlt.pattern(0).note(0, 0).effect = __MODPLAYER_FX_EXT
    pFlt.pattern(0).note(0, 0).operand = &H00 ' E00
    pFlt.song.tickPattern = 0
    pFlt.song.tickPatternRow = 0
    __MODPlayer_UpdateRow pFlt
    TEST_CHECK pFlt.song.useAmigaLPF, "E00 sets useAmigaLPF = _TRUE"

    ' E01 turns filter off
    pFlt.pattern(0).note(0, 0).operand = &H01 ' E01
    __MODPlayer_UpdateRow pFlt
    TEST_CHECK_FALSE pFlt.song.useAmigaLPF, "E01 sets useAmigaLPF = _FALSE"
    MODPlayer_Finalize pFlt
    TEST_CASE_END

    TEST_CASE_BEGIN "MOD Effects: Fine Portamento Up underflow clamp (E1F)"
    DIM pFine AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pFine, "mods/Enigma.mod"), "Load Enigma.mod"
    pFine.channel(0).period = 10 ' very small period
    pFine.pattern(0).note(0, 0).note = __MODPLAYER_NOTE_NONE
    pFine.pattern(0).note(0, 0).instrument = 0
    pFine.pattern(0).note(0, 0).effect = __MODPLAYER_FX_EXT
    pFine.pattern(0).note(0, 0).operand = &H1F ' E1F (subtract 15 * 4 = 60)
    pFine.song.tickPattern = 0
    pFine.song.tickPatternRow = 0
    __MODPlayer_UpdateRow pFine
    TEST_CHECK pFine.channel(0).period >= 1, "E1F clamps period to >= 1 and prevents underflow"
    MODPlayer_Finalize pFine
    TEST_CASE_END
END SUB

''' @brief Tests for MultiTracker MTM specific effects and playback features.
SUB Test_MTM_Effects
    TEST_CASE_BEGIN "MTM Effects: Pattern Break Dxx is Hexadecimal"
    DIM pBreak AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pBreak, "mods/cougarstory-ii.mtm"), "Load MTM base for pattern break test"
    ' Clear effects on row 0 across channels
    DIM ch AS LONG: FOR ch = 0 TO pBreak.song.channels - 1
        pBreak.pattern(0).note(0, ch).effect = 0
        pBreak.pattern(0).note(0, ch).operand = 0
    NEXT ch
    ' Put D10 on channel 0 (row 16 in hex)
    pBreak.song.orderPosition = 0
    pBreak.song.patternRow = 0
    pBreak.song.tickPattern = 0
    pBreak.song.tickPatternRow = 0
    pBreak.pattern(0).note(0, 0).effect = __MODPLAYER_FX_PATTERN_BREAK
    pBreak.pattern(0).note(0, 0).operand = &H10 ' Hex 16
    __MODPlayer_UpdateRow pBreak
    pBreak.song.patternRow = pBreak.song.patternRow + 1
    TEST_CHECK pBreak.song.orderPosition = 1, "Order advances to 1 on D10"
    TEST_CHECK pBreak.song.patternRow = 16, "D10 jumps to hex row 16 (not decimal row 10)"

    ' Put D1A on channel 0 (row 26 in hex)
    pBreak.song.orderPosition = 0
    pBreak.song.patternRow = 0
    pBreak.song.tickPattern = 0
    pBreak.song.tickPatternRow = 0
    pBreak.pattern(0).note(0, 0).operand = &H1A ' Hex 26
    __MODPlayer_UpdateRow pBreak
    pBreak.song.patternRow = pBreak.song.patternRow + 1
    TEST_CHECK pBreak.song.patternRow = 26, "D1A jumps to hex row 26"
    MODPlayer_Finalize pBreak
    TEST_CASE_END

    TEST_CASE_BEGIN "MTM Effects: MultiTracker Tempo Mode vs Standard Mode"
    DIM pTempo AS MODPlayer
    TEST_REQUIRE MODPlayer_LoadFromDisk(pTempo, "mods/cougarstory-ii.mtm"), "Load MTM base for tempo test"
    ' Clear row 0 effects
    FOR ch = 0 TO pTempo.song.channels - 1
        pTempo.pattern(0).note(0, ch).effect = 0
        pTempo.pattern(0).note(0, ch).operand = 0
    NEXT ch

    ' Enable MTM tempo mode
    pTempo.song.useMTMTempoMode = _TRUE
    pTempo.song.speed = 3
    pTempo.song.BPM = 140
    ' Set speed 5 -> should reset BPM to 125
    pTempo.pattern(0).note(0, 0).effect = __MODPLAYER_FX_SPEED_TEMPO
    pTempo.pattern(0).note(0, 0).operand = 5
    pTempo.song.tickPattern = 0
    pTempo.song.tickPatternRow = 0
    __MODPlayer_UpdateRow pTempo
    TEST_CHECK pTempo.song.speed = 5, "F05 sets speed to 5"
    TEST_CHECK pTempo.song.BPM = 125, "F05 in MTM mode resets BPM to 125"

    ' Set tempo 150 -> should reset speed to 6
    pTempo.pattern(0).note(0, 0).operand = 150
    __MODPlayer_UpdateRow pTempo
    TEST_CHECK pTempo.song.BPM = 150, "F96 sets BPM to 150"
    TEST_CHECK pTempo.song.speed = 6, "F96 in MTM mode resets speed to 6"

    ' Disable MTM tempo mode (DMP mode)
    pTempo.song.useMTMTempoMode = _FALSE
    pTempo.pattern(0).note(0, 0).operand = 4
    __MODPlayer_UpdateRow pTempo
    TEST_CHECK pTempo.song.speed = 4, "F04 in DMP mode sets speed to 4"
    TEST_CHECK pTempo.song.BPM = 150, "F04 in DMP mode leaves BPM at 150"

    MODPlayer_Finalize pTempo
    TEST_CASE_END

    TEST_CASE_BEGIN "MTM Effects: 16-bit Unsigned Sample Conversion"
    ' Synthesize a 16-bit unsigned buffer: 0x0000 (min) and 0x8000 (mid)
    DIM u16Data AS STRING
    u16Data = CHR$(0) + CHR$(0) + CHR$(0) + CHR$(&H80)
    AudioConv_ConvertU16ToS16 u16Data
    ' 0x0000 unsigned should become 0x8000 signed (-32768)
    ' 0x8000 unsigned should become 0x0000 signed (0)
    DIM sample1 AS INTEGER: sample1 = CVI(MID$(u16Data, 1, 2))
    DIM sample2 AS INTEGER: sample2 = CVI(MID$(u16Data, 3, 2))
    TEST_CHECK sample1 = -32768, "0x0000 unsigned 16-bit converts to -32768 signed"
    TEST_CHECK sample2 = 0, "0x8000 unsigned 16-bit converts to 0 signed"
    TEST_CASE_END
END SUB

SUB Test_FAR_Effects
    TEST_CASE_BEGIN "FAR Effects: Synthetic FAR Module Loading and Effect Translation"
    DIM farData AS STRING: farData = _STR_EMPTY

    ' Header (869 + msgLen bytes)
    farData = farData + "FAR" + CHR$(254) ' Magic (4 bytes)
    farData = farData + "FAR Effects Test" + SPACE$(24) ' Song Title (40 bytes)
    farData = farData + CHR$(13) + CHR$(10) + CHR$(26) ' EOF chars (3 bytes)

    DIM msgLen AS LONG: msgLen = 264
    DIM headerLen AS LONG: headerLen = 869 + msgLen
    farData = farData + MKI$(headerLen) ' Header length (2 bytes)
    farData = farData + CHR$(&H10) ' Version (1 byte)

    ' Channel on/off map (16 bytes): channel 15 muted (0), channels 0..14 active (1)
    DIM ch AS LONG
    FOR ch = 0 TO 14: farData = farData + CHR$(1): NEXT ch
    farData = farData + CHR$(0) ' channel 15 muted

    farData = farData + STRING$(9, 0) ' 9 bytes editing state
    farData = farData + CHR$(4) ' Default speed (4)

    ' Channel panning map (16 bytes)
    farData = farData + CHR$(0) ' channel 0 = left (0)
    farData = farData + CHR$(15) ' channel 1 = right (15)
    farData = farData + CHR$(8) ' channel 2 = center (8)
    FOR ch = 3 TO 15: farData = farData + CHR$(8): NEXT ch

    farData = farData + STRING$(4, 0) ' 4 bytes editing area / marked block

    farData = farData + MKI$(msgLen) ' Song text length (2 bytes)

    ' 2 lines of 132 chars (264 bytes)
    DIM line1 AS STRING: line1 = "First Line" + SPACE$(122)
    DIM line2 AS STRING: line2 = "Second Line" + STRING$(121, 0)
    farData = farData + line1 + line2

    ' Orders (256 bytes)
    farData = farData + CHR$(0) + STRING$(255, 0)
    farData = farData + CHR$(1) ' numPatterns
    farData = farData + CHR$(1) ' numOrders
    farData = farData + CHR$(0) ' restartPos

    ' Pattern sizes (256 integers = 512 bytes)
    DIM pat0Size AS LONG: pat0Size = 2 + 64 * 16 * 4
    farData = farData + MKI$(pat0Size)
    FOR ch = 1 TO 255: farData = farData + MKI$(0): NEXT ch

    ' Pattern 0 data
    farData = farData + CHR$(10) ' breakRow = 10 (targetBreakRow = 11)
    farData = farData + CHR$(0) ' tempoUnused

    ' Row 0 (16 channels * 4 bytes = 64 bytes)
    ' Ch 0: note=1, inst=0, vol=16, fx=&H12 (Fine porta up 2)
    farData = farData + CHR$(1) + CHR$(0) + CHR$(16) + CHR$(&H12)
    ' Ch 1: note=2, inst=0, vol=1, fx=&H23 (Fine porta down 3)
    farData = farData + CHR$(2) + CHR$(0) + CHR$(1) + CHR$(&H23)
    ' Ch 2: note=13, inst=0, vol=0, fx=&H34 (Tone porta 4 -> 60\4=15)
    farData = farData + CHR$(13) + CHR$(0) + CHR$(0) + CHR$(&H34)
    ' Ch 3: note=25, inst=0, vol=&H28, fx=&H42 (Retrig 2 -> 6\3+1=3)
    farData = farData + CHR$(25) + CHR$(0) + CHR$(&H28) + CHR$(&H42)
    ' Ch 4: note=0, inst=0, vol=0, fx=&H56 (Vibrato depth 6)
    farData = farData + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(&H56)
    ' Ch 5: note=37, inst=0, vol=0, fx=&H64 (Vibrato speed 4 -> &H40)
    farData = farData + CHR$(37) + CHR$(0) + CHR$(0) + CHR$(&H64)
    ' Ch 6: note=0, inst=0, vol=0, fx=&H72 (Volume slide up 2 -> &H20)
    farData = farData + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(&H72)
    ' Ch 7: note=0, inst=0, vol=0, fx=&H83 (Volume slide down 3 -> &H03)
    farData = farData + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(&H83)
    ' Ch 8: note=0, inst=0, vol=0, fx=&H95 (Sustained vibrato speed 5 -> &H50)
    farData = farData + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(&H95)
    ' Ch 9: note=0, inst=0, vol=0, fx=&HA7 (Set volume 7 -> 32)
    farData = farData + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(&HA7)
    ' Ch 10: note=0, inst=0, vol=0, fx=&HB4 (Panning 4 -> 68)
    farData = farData + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(&HB4)
    ' Ch 11: note=1, inst=0, vol=0, fx=&HC1 (Note delay 1 -> &HD4)
    farData = farData + CHR$(1) + CHR$(0) + CHR$(0) + CHR$(&HC1)
    ' Ch 12: note=0, inst=0, vol=0, fx=&HF5 (Set speed 5)
    farData = farData + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(&HF5)
    ' Ch 13: note=0, inst=5, vol=0, fx=0 (Instrument without note: should be ignored)
    farData = farData + CHR$(0) + CHR$(5) + CHR$(0) + CHR$(0)
    ' Ch 14: note=0, inst=0, vol=0, fx=0
    farData = farData + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(0)
    ' Ch 15: note=1, inst=0, vol=16, fx=&H12 (Muted channel: should be cleared)
    farData = farData + CHR$(1) + CHR$(0) + CHR$(16) + CHR$(&H12)

    ' Rows 1..63 (63 * 64 bytes = 4032 bytes empty)
    farData = farData + STRING$(63 * 64, 0)

    ' Sample map (8 bytes): sample 0 active
    farData = farData + CHR$(1) + STRING$(7, 0)

    ' Sample 0 header (48 bytes)
    farData = farData + "Test Sample" + SPACE$(21) ' 32 bytes name
    farData = farData + MKL$(16) ' Length 16 bytes
    farData = farData + CHR$(0) ' Finetune
    farData = farData + CHR$(16) ' Volume (16 * 4 = 64)
    farData = farData + MKL$(0) ' Repeat start
    farData = farData + MKL$(16) ' Repeat end
    farData = farData + CHR$(0) ' 8-bit
    farData = farData + CHR$(&H08) ' Loop mode (looped)

    ' Sample data (16 signed bytes)
    farData = farData + STRING$(16, 0)

    DIM pSynth AS MODPlayer
    TEST_REQUIRE FARLoader_LoadFromMemory(pSynth, farData), "Synthetic FAR module loaded successfully"

    ' Verify comment formatting
    DIM expectedComment AS STRING
    expectedComment = "First Line" + CHR$(13) + CHR$(10) + "Second Line"
    TEST_CHECK pSynth.song.comment = expectedComment, "FAR comment formatted to multi-line with nulls converted to spaces"

    ' Verify Note and Effect translations on Row 0
    ' Ch 0: note 1 -> 36, vol 16 -> 64, effect E12 (fine porta up 2)
    TEST_CHECK pSynth.pattern(0).note(0, 0).note = 36, "Ch 0 note 1 mapped to 36 (C-3)"
    TEST_CHECK pSynth.pattern(0).note(0, 0).volume = 64, "Ch 0 vol 16 mapped to 64"
    TEST_CHECK pSynth.pattern(0).note(0, 0).effect = __MODPLAYER_FX_EXT, "Ch 0 effect is FX_EXT"
    TEST_CHECK pSynth.pattern(0).note(0, 0).operand = &H12, "Ch 0 operand is &H12 (E12 fine porta up)"

    ' Ch 1: note 2 -> 37, vol 1 -> 0, effect E23 (fine porta down 3)
    TEST_CHECK pSynth.pattern(0).note(0, 1).note = 37, "Ch 1 note 2 mapped to 37 (C#3)"
    TEST_CHECK pSynth.pattern(0).note(0, 1).volume = 0, "Ch 1 vol 1 mapped to 0"
    TEST_CHECK pSynth.pattern(0).note(0, 1).effect = __MODPLAYER_FX_EXT, "Ch 1 effect is FX_EXT"
    TEST_CHECK pSynth.pattern(0).note(0, 1).operand = &H23, "Ch 1 operand is &H23 (E23 fine porta down)"

    ' Ch 2: note 13 -> 48, effect 3xx (Tone porta 4 -> operand 15)
    TEST_CHECK pSynth.pattern(0).note(0, 2).note = 48, "Ch 2 note 13 mapped to 48"
    TEST_CHECK pSynth.pattern(0).note(0, 2).effect = __MODPLAYER_FX_PORTAMENTO, "Ch 2 effect is tone portamento"
    TEST_CHECK pSynth.pattern(0).note(0, 2).operand = 15, "Ch 2 operand is 15 (60 \ 4)"

    ' Ch 3: note 25 -> 60, vol &H28 -> 29, effect E93 (Retrigger every 3 ticks)
    TEST_CHECK pSynth.pattern(0).note(0, 3).note = 60, "Ch 3 note 25 mapped to 60"
    TEST_CHECK pSynth.pattern(0).note(0, 3).volume = 29, "Ch 3 vol &H28 major adjust mapped to 29"
    TEST_CHECK pSynth.pattern(0).note(0, 3).effect = __MODPLAYER_FX_EXT, "Ch 3 effect is FX_EXT"
    TEST_CHECK pSynth.pattern(0).note(0, 3).operand = &H93, "Ch 3 operand is &H93 (E93 retrigger 3 ticks)"

    ' Ch 4: Vibrato depth 6 -> FX_VIBRATO operand 6
    TEST_CHECK pSynth.pattern(0).note(0, 4).effect = __MODPLAYER_FX_VIBRATO, "Ch 4 effect is vibrato"
    TEST_CHECK pSynth.pattern(0).note(0, 4).operand = 6, "Ch 4 operand is 6 (vibrato depth)"

    ' Ch 5: Vibrato speed 4 -> FX_VIBRATO operand &H40
    TEST_CHECK pSynth.pattern(0).note(0, 5).effect = __MODPLAYER_FX_VIBRATO, "Ch 5 effect is vibrato"
    TEST_CHECK pSynth.pattern(0).note(0, 5).operand = &H40, "Ch 5 operand is &H40 (vibrato speed 4)"

    ' Ch 6: Volume slide up 2 -> FX_VOLUME_SLIDE operand &H20
    TEST_CHECK pSynth.pattern(0).note(0, 6).effect = __MODPLAYER_FX_VOLUME_SLIDE, "Ch 6 effect is volume slide"
    TEST_CHECK pSynth.pattern(0).note(0, 6).operand = &H20, "Ch 6 operand is &H20 (volume slide up 2)"

    ' Ch 7: Volume slide down 3 -> FX_VOLUME_SLIDE operand &H03
    TEST_CHECK pSynth.pattern(0).note(0, 7).effect = __MODPLAYER_FX_VOLUME_SLIDE, "Ch 7 effect is volume slide"
    TEST_CHECK pSynth.pattern(0).note(0, 7).operand = &H03, "Ch 7 operand is &H03 (volume slide down 3)"

    ' Ch 8: Sustained vibrato speed 5 -> FX_VIBRATO operand &H50
    TEST_CHECK pSynth.pattern(0).note(0, 8).effect = __MODPLAYER_FX_VIBRATO, "Ch 8 effect is vibrato"
    TEST_CHECK pSynth.pattern(0).note(0, 8).operand = &H50, "Ch 8 operand is &H50 (sustained vibrato speed 5)"

    ' Ch 9: Slide to volume / set volume 7 -> vol = _MIN(7*4+4, 64) = 32
    TEST_CHECK pSynth.pattern(0).note(0, 9).volume = 32, "Ch 9 volume set to 32"
    TEST_CHECK pSynth.pattern(0).note(0, 9).effect = 0, "Ch 9 effect is 0"

    ' Ch 10: Panning 4 -> FX_PANNING_8 operand 68 (4 * 17)
    TEST_CHECK pSynth.pattern(0).note(0, 10).effect = __MODPLAYER_FX_PANNING_8, "Ch 10 effect is panning 8"
    TEST_CHECK pSynth.pattern(0).note(0, 10).operand = 68, "Ch 10 operand is 68 (4 * 17)"

    ' Ch 11: Note delay 1 -> FX_EXT operand &HD4 (6\2 + 1 = 4 ticks delay)
    TEST_CHECK pSynth.pattern(0).note(0, 11).effect = __MODPLAYER_FX_EXT, "Ch 11 effect is FX_EXT"
    TEST_CHECK pSynth.pattern(0).note(0, 11).operand = &HD4, "Ch 11 operand is &HD4 (ED4 note delay)"

    ' Ch 12: Set speed 5 -> FX_SPEED_TEMPO operand 5
    TEST_CHECK pSynth.pattern(0).note(0, 12).effect = __MODPLAYER_FX_SPEED_TEMPO, "Ch 12 effect is speed/tempo"
    TEST_CHECK pSynth.pattern(0).note(0, 12).operand = 5, "Ch 12 operand is 5"

    ' Ch 13: Instrument without note is ignored
    TEST_CHECK pSynth.pattern(0).note(0, 13).note = __MODPLAYER_NOTE_NONE, "Ch 13 note is none"
    TEST_CHECK pSynth.pattern(0).note(0, 13).instrument = 0, "Ch 13 instrument without note is 0"

    ' Ch 15: Muted channel
    TEST_CHECK pSynth.pattern(0).note(0, 15).note = __MODPLAYER_NOTE_NONE, "Muted channel 15 note is none"
    TEST_CHECK pSynth.pattern(0).note(0, 15).effect = 0, "Muted channel 15 effect is 0"
    TEST_CHECK pSynth.channel(15).channelVolume = 0, "Muted channel 15 channelVolume is 0"

    ' Pattern Break at row 11 (breakRow = 10 -> row 11)
    TEST_CHECK pSynth.pattern(0).note(11, 0).effect = __MODPLAYER_FX_PATTERN_BREAK, "Row 11 has pattern break injected"
    TEST_CHECK pSynth.pattern(0).note(11, 0).operand = 0, "Row 11 pattern break operand is 0"

    ' Channel and Sample settings
    TEST_CHECK pSynth.channel(0).panning = 0, "Ch 0 panning is 0 (left)"
    TEST_CHECK pSynth.channel(1).panning = 255, "Ch 1 panning is 255 (right)"
    TEST_CHECK pSynth.channel(2).panning = 136, "Ch 2 panning is 136 (center)"
    TEST_CHECK pSynth.channel(0).vibratoDepth = 4, "Ch 0 default vibrato depth is 4"
    TEST_CHECK pSynth.song.defaultSpeed = 4, "Song default speed is 4"
    TEST_CHECK pSynth.song.defaultBPM = 80, "Song default BPM is 80"
    TEST_CHECK pSynth.instrument(0).length = 16, "Sample 0 length is 16"
    TEST_CHECK pSynth.instrument(0).volume = 64, "Sample 0 volume is 64"
    TEST_CHECK pSynth.instrument(0).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP, "Sample 0 is looped"
    TEST_CHECK pSynth.instrument(0).c2Spd = 16726, "Sample 0 c2Spd is 16726"

    ' Playback and silence on muted channel
    MODPlayer_Play pSynth
    TEST_CHECK pSynth.channel(0).vibratoDepth = 4, "Ch 0 vibratoDepth is 4 after MODPlayer_Play"
    MODPlayer_Update pSynth, 0.05
    TEST_CHECK MODPlayer_IsPlaying(pSynth), "Synthetic FAR plays without error"
    MODPlayer_Stop pSynth
    MODPlayer_Finalize pSynth
    TEST_CASE_END
END SUB

''' @brief Tests for Scream Tracker 2 effect translations and quirk handling.
SUB Test_STM_Effects
    TEST_CASE_BEGIN "STM Effects: Synthetic STM Module Loading and Effect Translation"
    DIM stmData AS STRING: stmData = _STR_EMPTY

    ' Header (48 bytes)
    stmData = stmData + "Synthetic STM" + SPACE$(7) ' Title (20 bytes)
    stmData = stmData + "!Scream!" ' Tracker (8 bytes)
    stmData = stmData + CHR$(&H1A) ' EOF (1 byte)
    stmData = stmData + CHR$(2) ' File type: module (1 byte)
    stmData = stmData + CHR$(2) ' Major version (1 byte)
    stmData = stmData + CHR$(21) ' Minor version 2.21 (1 byte)
    stmData = stmData + CHR$(&H60) ' Init tempo (1 byte)
    stmData = stmData + CHR$(1) ' Number of patterns (1 byte)
    stmData = stmData + CHR$(64) ' Global volume (1 byte)
    stmData = stmData + STRING$(13, 0) ' Reserved (13 bytes)

    ' Instruments (31 * 32 = 992 bytes)
    ' Instrument 0 (32 bytes)
    DIM paraOffset AS _UNSIGNED INTEGER: paraOffset = 137 ' (48 + 992 + 128 + 1024) \ 16 = 2192 \ 16 = 137
    stmData = stmData + "TestSample" + SPACE$(2) ' 12 bytes name
    stmData = stmData + CHR$(0) ' zero byte
    stmData = stmData + CHR$(0) ' disk byte
    stmData = stmData + MKI$(paraOffset) ' paragraph offset
    stmData = stmData + MKI$(16) ' length (16 bytes)
    stmData = stmData + MKI$(0) ' loop start
    stmData = stmData + MKI$(16) ' loop end
    stmData = stmData + CHR$(64) ' volume
    stmData = stmData + CHR$(0) ' reserved2
    stmData = stmData + MKI$(8363) ' c2spd
    stmData = stmData + MKL$(0) ' reserved3
    stmData = stmData + MKI$(1) ' paralen

    ' Instruments 1..30 (960 bytes)
    stmData = stmData + STRING$(960, 0)

    ' Orders (128 bytes)
    stmData = stmData + CHR$(0) + STRING$(127, 99)

    ' Pattern 0 (1024 bytes = 64 rows * 4 channels * 4 bytes)
    ' Row 0 (16 bytes)
    ' Ch 0: note=0 (C-3 -> 36), inst=1, vol=64, cmd=1 (A), op=&H50 -> speed 5
    stmData = stmData + CHR$(0) + CHR$(8) + CHR$(&H81) + CHR$(&H50)
    ' Ch 1: note=1 (C#3 -> 37), inst=1, vol=40, cmd=2 (B), op=3 -> pos jump 3
    stmData = stmData + CHR$(1) + CHR$(8) + CHR$(&H52) + CHR$(3)
    ' Ch 2: note=2 (D-3 -> 38), inst=1, vol=20, cmd=3 (C), op=0 -> pat break 0
    stmData = stmData + CHR$(2) + CHR$(12) + CHR$(&H23) + CHR$(0)
    ' Ch 3: note=3 (D#3 -> 39), inst=1, vol=10, cmd=4 (D), op=2 -> vol slide down 2
    stmData = stmData + CHR$(3) + CHR$(10) + CHR$(&H14) + CHR$(2)

    ' Row 1 (16 bytes)
    ' Ch 0: vol slide up 3 (D30)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF4) + CHR$(&H30)
    ' Ch 1: portamento down 5 (E05)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF5) + CHR$(5)
    ' Ch 2: portamento up 4 (F04)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF6) + CHR$(4)
    ' Ch 3: tone portamento 8 (G08)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF7) + CHR$(8)

    ' Row 2 (16 bytes)
    ' Ch 0: vibrato &H45 (H45)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF8) + CHR$(&H45)
    ' Ch 1: tremor &H32 (I32)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF9) + CHR$(&H32)
    ' Ch 2: arpeggio &H12 (J12)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HFA) + CHR$(&H12)
    ' Ch 3: volume slide 0 -> operand 0 suppressed (ST2 has no effect memory)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF4) + CHR$(0)

    ' Row 3 (16 bytes)
    ' Ch 0: key off (&HFE)
    stmData = stmData + CHR$(&HFE) + CHR$(8) + CHR$(&HF0) + CHR$(0)
    ' Ch 1: no note (&HFF)
    stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF0) + CHR$(0)
    ' Ch 2: octave 1 semitone 0 -> note 48 (C-4)
    stmData = stmData + CHR$(&H10) + CHR$(8) + CHR$(&HF0) + CHR$(0)
    ' Ch 3: octave 2 semitone 1 -> note 61 (C#5)
    stmData = stmData + CHR$(&H21) + CHR$(8) + CHR$(&HF0) + CHR$(0)

    ' Rows 4..63 (60 rows * 16 bytes = 960 bytes)
    DIM r AS LONG
    FOR r = 4 TO 63
        stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF0) + CHR$(0)
        stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF0) + CHR$(0)
        stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF0) + CHR$(0)
        stmData = stmData + CHR$(&HFF) + CHR$(0) + CHR$(&HF0) + CHR$(0)
    NEXT r

    ' Sample data (16 signed bytes)
    stmData = stmData + STRING$(16, 0)

    DIM pSynth AS MODPlayer
    TEST_REQUIRE STMLoader_LoadFromMemory(pSynth, stmData), "Synthetic STM module loaded successfully"

    ' Song and Instrument checks
    TEST_CHECK INSTR(pSynth.song.caption, "Synthetic STM") > 0, "Song caption matches"
    TEST_CHECK pSynth.song.channels = 4, "STM has 4 channels"
    TEST_CHECK pSynth.song.defaultSpeed = 6, "Default speed is 6"
    TEST_CHECK pSynth.song.defaultBPM = 125, "Default BPM is 125"
    TEST_CHECK pSynth.song.isS3M = _TRUE, "isS3M is _TRUE"
    TEST_CHECK pSynth.instrument(0).length = 16, "Sample 0 length is 16"
    TEST_CHECK pSynth.instrument(0).volume = 64, "Sample 0 volume is 64"
    TEST_CHECK pSynth.instrument(0).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP, "Sample 0 is looped"

    ' Row 0: Note and Effect translations
    TEST_CHECK pSynth.pattern(0).note(0, 0).note = 24, "Row 0 Ch 0 note is 24 (C-2)"
    TEST_CHECK pSynth.pattern(0).note(0, 0).instrument = 1, "Row 0 Ch 0 inst is 1"
    TEST_CHECK pSynth.pattern(0).note(0, 0).volume = 64, "Row 0 Ch 0 vol is 64"
    TEST_CHECK pSynth.pattern(0).note(0, 0).effect = __MODPLAYER_FX_SPEED, "Row 0 Ch 0 effect is SPEED"
    TEST_CHECK pSynth.pattern(0).note(0, 0).operand = &H50, "Row 0 Ch 0 operand is &H50"

    TEST_CHECK pSynth.pattern(0).note(0, 1).note = 25, "Row 0 Ch 1 note is 25 (C#2)"
    TEST_CHECK pSynth.pattern(0).note(0, 1).volume = 40, "Row 0 Ch 1 vol is 40"
    TEST_CHECK pSynth.pattern(0).note(0, 1).effect = __MODPLAYER_FX_POSITION_JUMP, "Row 0 Ch 1 effect is POSITION_JUMP"
    TEST_CHECK pSynth.pattern(0).note(0, 1).operand = 3, "Row 0 Ch 1 operand is 3"

    TEST_CHECK pSynth.pattern(0).note(0, 2).note = 26, "Row 0 Ch 2 note is 26 (D-2)"
    TEST_CHECK pSynth.pattern(0).note(0, 2).volume = 20, "Row 0 Ch 2 vol is 20"
    TEST_CHECK pSynth.pattern(0).note(0, 2).effect = __MODPLAYER_FX_PATTERN_BREAK, "Row 0 Ch 2 effect is PATTERN_BREAK"
    TEST_CHECK pSynth.pattern(0).note(0, 2).operand = 0, "Row 0 Ch 2 operand is 0"

    TEST_CHECK pSynth.pattern(0).note(0, 3).note = 27, "Row 0 Ch 3 note is 27 (D#2)"
    TEST_CHECK pSynth.pattern(0).note(0, 3).volume = 10, "Row 0 Ch 3 vol is 10"
    TEST_CHECK pSynth.pattern(0).note(0, 3).effect = __MODPLAYER_FX_VOLUME_SLIDE, "Row 0 Ch 3 effect is VOLUME_SLIDE"
    TEST_CHECK pSynth.pattern(0).note(0, 3).operand = 2, "Row 0 Ch 3 operand is 2 (slide down 2)"

    ' Row 1: Slides
    TEST_CHECK pSynth.pattern(0).note(1, 0).effect = __MODPLAYER_FX_VOLUME_SLIDE, "Row 1 Ch 0 effect is VOLUME_SLIDE"
    TEST_CHECK pSynth.pattern(0).note(1, 0).operand = &H30, "Row 1 Ch 0 operand is &H30 (slide up 3)"
    TEST_CHECK pSynth.pattern(0).note(1, 1).effect = __MODPLAYER_FX_PORTAMENTO_DOWN, "Row 1 Ch 1 effect is PORTAMENTO_DOWN"
    TEST_CHECK pSynth.pattern(0).note(1, 1).operand = 5, "Row 1 Ch 1 operand is 5"
    TEST_CHECK pSynth.pattern(0).note(1, 2).effect = __MODPLAYER_FX_PORTAMENTO_UP, "Row 1 Ch 2 effect is PORTAMENTO_UP"
    TEST_CHECK pSynth.pattern(0).note(1, 2).operand = 4, "Row 1 Ch 2 operand is 4"
    TEST_CHECK pSynth.pattern(0).note(1, 3).effect = __MODPLAYER_FX_PORTAMENTO, "Row 1 Ch 3 effect is PORTAMENTO"
    TEST_CHECK pSynth.pattern(0).note(1, 3).operand = 8, "Row 1 Ch 3 operand is 8"

    ' Row 2: Vibrato, Tremor, Arpeggio, Zero Operand Suppression
    TEST_CHECK pSynth.pattern(0).note(2, 0).effect = __MODPLAYER_FX_VIBRATO, "Row 2 Ch 0 effect is VIBRATO"
    TEST_CHECK pSynth.pattern(0).note(2, 0).operand = &H45, "Row 2 Ch 0 operand is &H45"
    TEST_CHECK pSynth.pattern(0).note(2, 1).effect = __MODPLAYER_FX_TREMOR, "Row 2 Ch 1 effect is TREMOR"
    TEST_CHECK pSynth.pattern(0).note(2, 1).operand = &H32, "Row 2 Ch 1 operand is &H32"
    TEST_CHECK pSynth.pattern(0).note(2, 2).effect = __MODPLAYER_FX_ARPEGGIO, "Row 2 Ch 2 effect is ARPEGGIO"
    TEST_CHECK pSynth.pattern(0).note(2, 2).operand = &H12, "Row 2 Ch 2 operand is &H12"
    TEST_CHECK pSynth.pattern(0).note(2, 3).effect = 0, "Row 2 Ch 3 zero operand suppresses effect"
    TEST_CHECK pSynth.pattern(0).note(2, 3).operand = 0, "Row 2 Ch 3 operand is 0"

    ' Row 3: Special Notes
    TEST_CHECK pSynth.pattern(0).note(3, 0).note = __MODPLAYER_NOTE_KEY_OFF, "Row 3 Ch 0 is KEY_OFF"
    TEST_CHECK pSynth.pattern(0).note(3, 1).note = __MODPLAYER_NOTE_NONE, "Row 3 Ch 1 is NOTE_NONE"
    TEST_CHECK pSynth.pattern(0).note(3, 2).note = 36, "Row 3 Ch 2 is note 36 (C-3)"
    TEST_CHECK pSynth.pattern(0).note(3, 3).note = 49, "Row 3 Ch 3 is note 49 (C#4)"

    ' Playback and teardown
    MODPlayer_Play pSynth
    MODPlayer_Update pSynth, 0.05
    TEST_CHECK MODPlayer_IsPlaying(pSynth), "Synthetic STM plays without error"
    MODPlayer_Stop pSynth
    MODPlayer_Finalize pSynth
    TEST_CASE_END

    TEST_CASE_BEGIN "STM Effects: Decimal tempo conversion for ST2 version < 2.21"
    ' Modify header to version 2.20 with decimal tempo 60 (which translates to 0x60 / speed 6, factor 0)
    DIM stmVer220 AS STRING: stmVer220 = stmData
    MID$(stmVer220, 32, 1) = CHR$(20) ' verMinor = 20
    MID$(stmVer220, 33, 1) = CHR$(60) ' initTempo = 60 (decimal)
    ' In row 0, ch 0: op was &H50 (80 decimal) -> for ver < 2.21: 80 \ 10 = 8 speed
    MID$(stmVer220, 48 + 992 + 128 + 4, 1) = CHR$(80)
    DIM pVer AS MODPlayer
    TEST_REQUIRE STMLoader_LoadFromMemory(pVer, stmVer220), "Load version 2.20 STM module"
    TEST_CHECK pVer.song.defaultSpeed = 6, "Decimal tempo 60 yields speed 6"
    TEST_CHECK pVer.song.defaultBPM = 125, "Decimal tempo 60 yields 125 BPM"
    TEST_CHECK pVer.pattern(0).note(0, 0).operand = &H80, "Decimal op 80 in ver 2.20 yields tempoByte &H80"
    MODPlayer_Finalize pVer
    TEST_CASE_END
END SUB

''' @brief Tests for Vector2f 2D floating-point vector math functions.
SUB Test_Vector2f
    TEST_CASE_BEGIN "Vector2f: Initialize, Set, IsNull, IsEqual"
    DIM a AS Vector2f, b AS Vector2f, c AS Vector2f
    Vector2f_Initialize 3.5!, -2.5!, a
    TEST_CHECK a.x = 3.5! _ANDALSO a.y = -2.5!, "Vector2f_Initialize sets components correctly"
    TEST_CHECK Vector2f_IsNull(a) = _FALSE, "a is not null"
    Vector2f_Set 0!, 0!, b
    TEST_CHECK Vector2f_IsNull(b) = _TRUE, "b is null"
    Vector2f_Set 3.5!, -2.5!, c
    TEST_CHECK Vector2f_IsEqual(a, c) = _TRUE, "a equals c"
    TEST_CHECK Vector2f_IsEqual(a, b) = _FALSE, "a does not equal b"
    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2f: Arithmetic operations"
    Vector2f_Set 10!, 20!, a
    Vector2f_Set 3!, 5!, b
    Vector2f_Add a, b, c
    TEST_CHECK c.x = 13! _ANDALSO c.y = 25!, "Add: (10,20) + (3,5) = (13,25)"
    Vector2f_AddXY a, -2!, 4!, c
    TEST_CHECK c.x = 8! _ANDALSO c.y = 24!, "AddXY: (10,20) + (-2,4) = (8,24)"
    Vector2f_Subtract a, b, c
    TEST_CHECK c.x = 7! _ANDALSO c.y = 15!, "Subtract: (10,20) - (3,5) = (7,15)"
    Vector2f_Multiply a, b, c
    TEST_CHECK c.x = 30! _ANDALSO c.y = 100!, "Multiply: (10,20) * (3,5) = (30,100)"
    Vector2f_Scale a, 2.5!, c
    TEST_CHECK c.x = 25! _ANDALSO c.y = 50!, "Scale: (10,20) * 2.5 = (25,50)"
    Vector2f_Divide a, 2!, c
    TEST_CHECK c.x = 5! _ANDALSO c.y = 10!, "Divide: (10,20) / 2 = (5,10)"
    Vector2f_Divide a, 0!, c
    TEST_CHECK c.x = 0! _ANDALSO c.y = 0!, "Divide by zero yields zero"
    Vector2f_Negate a, c
    TEST_CHECK c.x = -10! _ANDALSO c.y = -20!, "Negate: -(10,20) = (-10,-20)"
    Vector2f_FlipHorizontal a, c
    TEST_CHECK c.x = -10! _ANDALSO c.y = 20!, "FlipHorizontal: (-10,20)"
    Vector2f_FlipVertical a, c
    TEST_CHECK c.x = 10! _ANDALSO c.y = -20!, "FlipVertical: (10,-20)"
    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2f: Geometry and Trig"
    Vector2f_Set 3!, 4!, a
    TEST_CHECK Vector2f_LengthSquared(a) = 25!, "LengthSquared: 3^2 + 4^2 = 25"
    TEST_CHECK ABS(Vector2f_Length(a) - 5!) < 0.0001!, "Length: 5"
    Vector2f_Set 6!, 8!, b
    TEST_CHECK Vector2f_DistanceSquared(a, b) = 25!, "DistanceSquared: (3-6)^2 + (4-8)^2 = 25"
    TEST_CHECK ABS(Vector2f_Distance(a, b) - 5!) < 0.0001!, "Distance: 5"
    Vector2f_Set 2!, 3!, a
    Vector2f_Set 4!, 5!, b
    TEST_CHECK Vector2f_DotProduct(a, b) = 23!, "DotProduct: 2*4 + 3*5 = 23"
    TEST_CHECK Vector2f_CrossProduct(a, b) = -2!, "CrossProduct: 2*5 - 3*4 = -2"
    Vector2f_Set 0!, 10!, a
    Vector2f_Normalize a, c
    TEST_CHECK c.x = 0! _ANDALSO ABS(c.y - 1!) < 0.0001!, "Normalize (0,10) -> (0,1)"
    Vector2f_Set 0!, 0!, a
    Vector2f_Normalize a, c
    TEST_CHECK Vector2f_IsNull(c) = _TRUE, "Normalize (0,0) -> (0,0)"
    Vector2f_Set 0!, 0!, a
    Vector2f_Set 10!, 20!, b
    Vector2f_Lerp a, b, 0.5!, c
    TEST_CHECK ABS(c.x - 5!) < 0.0001! _ANDALSO ABS(c.y - 10!) < 0.0001!, "Lerp at t=0.5"
    Vector2f_Set 1!, 0!, a
    Vector2f_Rotate a, _PI / 2!, c
    TEST_CHECK ABS(c.x) < 0.0001! _ANDALSO ABS(c.y - 1!) < 0.0001!, "Rotate (1,0) by 90 deg -> (0,1)"
    Vector2f_Set 1!, -1!, a
    Vector2f_Set 0!, 1!, b
    Vector2f_Reflect a, b, c
    TEST_CHECK ABS(c.x - 1!) < 0.0001! _ANDALSO ABS(c.y - 1!) < 0.0001!, "Reflect (1,-1) off normal (0,1) -> (1,1)"
    Vector2f_FromAngle 0!, 5!, c
    TEST_CHECK ABS(c.x - 5!) < 0.0001! _ANDALSO ABS(c.y) < 0.0001!, "FromAngle(0, 5) -> (5,0)"
    TEST_CHECK ABS(Vector2f_Angle(c)) < 0.0001!, "Angle of (5,0) is 0"
    Vector2f_Set 6!, 8!, a
    Vector2f_ClampLength a, 5!, c
    TEST_CHECK ABS(Vector2f_Length(c) - 5!) < 0.0001!, "ClampLength clamps magnitude to 5"
    TEST_CASE_END
END SUB

''' @brief Tests for Vector3f 3D floating-point vector math functions.
SUB Test_Vector3f
    TEST_CASE_BEGIN "Vector3f: Initialize, Set, IsNull, IsEqual"
    DIM a AS Vector3f, b AS Vector3f, c AS Vector3f
    Vector3f_Initialize 1.5!, -2.5!, 3.5!, a
    TEST_CHECK a.x = 1.5! _ANDALSO a.y = -2.5! _ANDALSO a.z = 3.5!, "Vector3f_Initialize sets components correctly"
    TEST_CHECK Vector3f_IsNull(a) = _FALSE, "a is not null"
    Vector3f_Set 0!, 0!, 0!, b
    TEST_CHECK Vector3f_IsNull(b) = _TRUE, "b is null"
    Vector3f_Set 1.5!, -2.5!, 3.5!, c
    TEST_CHECK Vector3f_IsEqual(a, c) = _TRUE, "a equals c"
    TEST_CHECK Vector3f_IsEqual(a, b) = _FALSE, "a does not equal b"
    TEST_CASE_END

    TEST_CASE_BEGIN "Vector3f: Arithmetic operations"
    Vector3f_Set 10!, 20!, 30!, a
    Vector3f_Set 2!, 4!, 5!, b
    Vector3f_Add a, b, c
    TEST_CHECK c.x = 12! _ANDALSO c.y = 24! _ANDALSO c.z = 35!, "Add: (10,20,30) + (2,4,5) = (12,24,35)"
    Vector3f_AddXYZ a, -1!, 2!, -3!, c
    TEST_CHECK c.x = 9! _ANDALSO c.y = 22! _ANDALSO c.z = 27!, "AddXYZ: (9,22,27)"
    Vector3f_Subtract a, b, c
    TEST_CHECK c.x = 8! _ANDALSO c.y = 16! _ANDALSO c.z = 25!, "Subtract: (10,20,30) - (2,4,5) = (8,16,25)"
    Vector3f_Multiply a, b, c
    TEST_CHECK c.x = 20! _ANDALSO c.y = 80! _ANDALSO c.z = 150!, "Multiply: component-wise product"
    Vector3f_Scale a, 0.5!, c
    TEST_CHECK c.x = 5! _ANDALSO c.y = 10! _ANDALSO c.z = 15!, "Scale: (10,20,30) * 0.5 = (5,10,15)"
    Vector3f_Divide a, 2!, c
    TEST_CHECK c.x = 5! _ANDALSO c.y = 10! _ANDALSO c.z = 15!, "Divide: (10,20,30) / 2 = (5,10,15)"
    Vector3f_Divide a, 0!, c
    TEST_CHECK c.x = 0! _ANDALSO c.y = 0! _ANDALSO c.z = 0!, "Divide by zero yields zero"
    Vector3f_Negate a, c
    TEST_CHECK c.x = -10! _ANDALSO c.y = -20! _ANDALSO c.z = -30!, "Negate: -(10,20,30)"
    TEST_CASE_END

    TEST_CASE_BEGIN "Vector3f: Geometry and Vector Math"
    Vector3f_Set 2!, 3!, 6!, a
    TEST_CHECK Vector3f_LengthSquared(a) = 49!, "LengthSquared: 2^2 + 3^2 + 6^2 = 49"
    TEST_CHECK ABS(Vector3f_Length(a) - 7!) < 0.0001!, "Length: 7"
    Vector3f_Set 1!, 1!, 1!, a
    Vector3f_Set 3!, 4!, 7!, b
    TEST_CHECK Vector3f_DistanceSquared(a, b) = 49!, "DistanceSquared: 2^2 + 3^2 + 6^2 = 49"
    TEST_CHECK ABS(Vector3f_Distance(a, b) - 7!) < 0.0001!, "Distance: 7"
    Vector3f_Set 1!, 2!, 3!, a
    Vector3f_Set 4!, 5!, 6!, b
    TEST_CHECK Vector3f_DotProduct(a, b) = 32!, "DotProduct: 1*4 + 2*5 + 3*6 = 32"
    Vector3f_Set 1!, 0!, 0!, a
    Vector3f_Set 0!, 1!, 0!, b
    Vector3f_CrossProduct a, b, c
    TEST_CHECK c.x = 0! _ANDALSO c.y = 0! _ANDALSO ABS(c.z - 1!) < 0.0001!, "CrossProduct: (1,0,0) x (0,1,0) = (0,0,1)"
    Vector3f_Set 0!, 0!, 5!, a
    Vector3f_Normalize a, c
    TEST_CHECK c.x = 0! _ANDALSO c.y = 0! _ANDALSO ABS(c.z - 1!) < 0.0001!, "Normalize (0,0,5) -> (0,0,1)"
    Vector3f_Set 0!, 0!, 0!, a
    Vector3f_Normalize a, c
    TEST_CHECK Vector3f_IsNull(c) = _TRUE, "Normalize (0,0,0) -> (0,0,0)"
    Vector3f_Set 0!, 0!, 0!, a
    Vector3f_Set 10!, 20!, 30!, b
    Vector3f_Lerp a, b, 0.5!, c
    TEST_CHECK ABS(c.x - 5!) < 0.0001! _ANDALSO ABS(c.y - 10!) < 0.0001! _ANDALSO ABS(c.z - 15!) < 0.0001!, "Lerp at t=0.5"
    Vector3f_Set 1!, -1!, 0!, a
    Vector3f_Set 0!, 1!, 0!, b
    Vector3f_Reflect a, b, c
    TEST_CHECK ABS(c.x - 1!) < 0.0001! _ANDALSO ABS(c.y - 1!) < 0.0001! _ANDALSO ABS(c.z) < 0.0001!, "Reflect (1,-1,0) off normal (0,1,0) -> (1,1,0)"
    Vector3f_Set 4!, 6!, 12!, a
    Vector3f_ClampLength a, 7!, c
    TEST_CHECK ABS(Vector3f_Length(c) - 7!) < 0.0001!, "ClampLength clamps magnitude to 7"
    TEST_CASE_END
END SUB

''' @brief Tests for Background.bi starfield and snake animation logic.
SUB Test_Background
    TEST_CASE_BEGIN "Background: Starfield initialization"
    DIM sf AS BackgroundStarfield
    Background_InitializeStars sf, 64
    TEST_CHECK sf.count = 64, "Starfield count is 64"
    TEST_CHECK sf.stars(1).p.z = 4096!, "Star 1 initialized with z depth 4096"
    TEST_CHECK sf.stars(1).c >= 9 AND sf.stars(1).c <= 15, "Star 1 has valid color [9..15]"
    TEST_CHECK sf.stars(64).p.z = 4096!, "Last star initialized with z depth 4096"
    TEST_CASE_END

    TEST_CASE_BEGIN "Background: Snakes initialization"
    DIM sn AS BackgroundSnakes
    Background_InitializeSnakes sn, 24
    TEST_CHECK sn.count = 24, "Snakes count is 24"
    TEST_CHECK sn.snakes(1).speed >= 0.2! AND sn.snakes(1).speed <= 0.6!, "Snake 1 speed in [0.2..0.6]"
    TEST_CHECK sn.snakes(1).c >= 1 AND sn.snakes(1).c <= 8, "Snake 1 color in [1..8]"
    DIM lSq AS SINGLE: lSq = Vector2f_LengthSquared(sn.snakes(1).direction)
    TEST_CHECK ABS(lSq - 1!) < 0.001!, "Snake 1 direction is unit vector"
    TEST_CHECK LEN(sn.snakes(1).p) >= 10, "Snake 1 body buffer has valid length"

    ' Ensure initial spawn heads are not overlapping
    DIM overlaps AS LONG: overlaps = 0
    DIM i AS LONG, j AS LONG
    FOR i = 1 TO sn.count - 1
        DIM hx AS LONG: hx = ASC(sn.snakes(i).p, 1)
        DIM hy AS LONG: hy = ASC(sn.snakes(i).p, 2)
        FOR j = i + 1 TO sn.count
            IF hx = ASC(sn.snakes(j).p, 1) AND hy = ASC(sn.snakes(j).p, 2) THEN
                overlaps = overlaps + 1
            END IF
        NEXT j
    NEXT i
    TEST_CHECK overlaps = 0, "Initial snake head placements have zero overlaps"
    TEST_CASE_END

    TEST_CASE_BEGIN "Background: Unified context management"
    DIM bg AS Background
    Background_Initialize bg
    TEST_CHECK bg.starfield.count = BACKGROUND_STAR_COUNT, "Default starfield count allocated"
    TEST_CHECK bg.snakes.count = BACKGROUND_SNAKE_COUNT, "Default snakes count allocated"
    TEST_CHECK bg.mode = BACKGROUND_MODE_STARS, "Default mode is stars"
    Background_UpdateAndDraw bg
    bg.mode = BACKGROUND_MODE_SNAKES
    Background_UpdateAndDraw bg
    TEST_CHECK bg.snakes.gridW > 0 AND bg.snakes.gridH > 0, "Snakes grid resized dynamically"
    TEST_CASE_END
END SUB

''' @brief Tests type promotions for instrument, c2Spd, endJumpOrder, and BPM beyond 8-bit and 16-bit limits.
SUB Test_MODPlayer_TypePromotions
    TEST_CASE_BEGIN "Type Promotions: Instrument indices beyond 8-bit (255)"
    DIM pType AS MODPlayer
    TEST_REQUIRE MODPlayer_Initialize(pType), "Initialize player"
    REDIM pType.instrument(0 TO 300) AS __MODPLAYERINSTRUMENT
    REDIM pType.channel(0 TO 3) AS __MODPLAYERCHANNEL
    REDIM pType.pattern(0 TO 0) AS __MODPLAYERPATTERN
    pType.pattern(0).rows = 64
    REDIM pType.pattern(0).note(0 TO 63, 0 TO 3) AS __MODPLAYERNOTE

    ' Instrument index > 255 in note
    pType.pattern(0).note(0, 0).instrument = 256
    TEST_CHECK pType.pattern(0).note(0, 0).instrument = 256, "Note instrument 256 does not wrap to 0"
    pType.pattern(0).note(0, 1).instrument = 1000
    TEST_CHECK pType.pattern(0).note(0, 1).instrument = 1000, "Note instrument 1000 is preserved"

    ' Instrument index > 255 in channel and delayedInstrument
    pType.channel(0).instrument = 256
    TEST_CHECK pType.channel(0).instrument = 256, "Channel instrument 256 does not wrap to 0"
    pType.channel(0).delayedInstrument = 500
    TEST_CHECK pType.channel(0).delayedInstrument = 500, "Delayed instrument 500 is preserved"
    TEST_CASE_END

    TEST_CASE_BEGIN "Type Promotions: c2Spd sample rates beyond 16-bit (65535 Hz)"
    ' 96 kHz and 192 kHz sample rates exceed 65,535
    pType.instrument(0).c2Spd = 96000
    TEST_CHECK pType.instrument(0).c2Spd = 96000, "Instrument c2Spd 96000 does not wrap to 30464"
    pType.instrument(1).c2Spd = 192000
    TEST_CHECK pType.instrument(1).c2Spd = 192000, "Instrument c2Spd 192000 is preserved"

    pType.channel(0).c2Spd = 96000
    TEST_CHECK pType.channel(0).c2Spd = 96000, "Channel c2Spd 96000 does not wrap"
    TEST_CASE_END

    TEST_CASE_BEGIN "Type Promotions: endJumpOrder beyond 8-bit (255)"
    pType.song.orders = 500
    pType.song.endJumpOrder = 300
    TEST_CHECK pType.song.endJumpOrder = 300, "endJumpOrder 300 does not wrap to 44"
    TEST_CASE_END

    TEST_CASE_BEGIN "Type Promotions: BPM and defaultBPM beyond 8-bit (255)"
    pType.song.defaultBPM = 350
    TEST_CHECK pType.song.defaultBPM = 350, "defaultBPM 350 does not wrap to 94"

    __MODPlayer_SetBPM pType, 300
    TEST_CHECK pType.song.BPM = 300, "SetBPM sets 300 BPM without wrapping"
    TEST_CHECK pType.song.framesPerTick > 0, "framesPerTick calculated correctly for 300 BPM"

    __MODPlayer_SetBPM pType, 512
    TEST_CHECK pType.song.BPM = 512, "SetBPM sets 512 BPM without wrapping"

    MODPlayer_Finalize pType
    TEST_CASE_END
END SUB

IF _DIREXISTS("../mods") THEN CHDIR ".."

' Run all test suites
TEST_BEGIN_ALL

Test_Vector2f
Test_Vector3f
Test_Background
Test_AudioConv
Test_SoftSynth
Test_StringFile
Test_String
Test_AudioAnalyzer
Test_Opal_Lifecycle
Test_Opal_SoundGeneration
Test_Opal_RhythmMode
Test_Opal_OPL2_OPL3_Modes
Test_MODPlayer_Lifecycle
Test_MODPlayer_MOD
Test_MODPlayer_Startrekker_AM
Test_MOD_Effects
Test_MODPlayer_S3M
Test_MODPlayer_S3M_Packed
Test_MODPlayer_S3M_AdLib
Test_MODPlayer_S3M_FMDrums
Test_S3M_Markers
Test_S3M_Effects
Test_MODPlayer_Stereo
Test_MODPlayer_ChannelBadges
Test_MODPlayer_MTM
Test_MTM_Effects
Test_MODPlayer_Memory
Test_MODLoader
Test_S3MLoader
Test_MTMLoader
Test_FARLoader
Test_FAR_Effects
Test_STMLoader
Test_STM_Effects
Test_C669Loader
Test_C669_Effects
Test_RADLoader
Test_RAD_Playback
Test_MODPlayer_MultiInstance
Test_MODPlayer_PatternRows
Test_MODPlayer_TypePromotions
Test_MODPlayer_Errors

TEST_END_ALL
