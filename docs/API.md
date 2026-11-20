# QB64 MOD Player API Reference

This document provides the complete API reference for the QB64 MOD Player
libraries, including the Core Player, Dedicated Format Loaders, Software
Synthesizer / Sample Mixer, and Audio Spectrum Analyzer.

---

## Table of Contents

- [Core Player API (`MODPlayer.bi` & `MODPlayer.bm`)](#core-player-api-modplayerbi--modplayerbm)
  - [Types](#modplayer-types)
  - [Lifecycle Management](#modplayer-lifecycle-management)
  - [Module Loading (Unified Dispatcher)](#module-loading-unified-dispatcher)
  - [Playback Controls](#playback-controls)
  - [Song Information and Navigation](#song-information-and-navigation)
- [Dedicated Format Loaders API (`*Loader.bi`)](#dedicated-format-loaders-api-loaderbi)
  - [ProTracker Loader (`MODLoader.bi`)](#protracker-loader-modloaderbi)
  - [Scream Tracker 2 Loader (`STMLoader.bi`)](#scream-tracker-2-loader-stmloaderbi)
  - [Scream Tracker 3 Loader (`S3MLoader.bi`)](#scream-tracker-3-loader-s3mloaderbi)
  - [MultiTracker Loader (`MTMLoader.bi`)](#multitracker-loader-mtmloaderbi)
  - [Farandole Composer Loader (`FARLoader.bi`)](#farandole-composer-loader-farloaderbi)
  - [Composer 669 Loader (`C669Loader.bi`)](#composer-669-loader-c669loaderbi)
- [Software Synthesizer API (`SoftSynth.bi`)](#software-synthesizer-api-softsynthbi)
  - [Constants](#softsynth-constants)
  - [Types](#softsynth-types)
  - [Lifecycle Management](#softsynth-lifecycle-management)
  - [Audio Buffer and Playback Control](#softsynth-audio-buffer-and-playback-control)
  - [Voice Parameter Controls](#softsynth-voice-parameter-controls)
  - [Sound Frame Peeking and Poking](#softsynth-sound-frame-peeking-and-poking)
- [Audio Spectrum Analyzer API (`AudioAnalyzer.bi`)](#audio-spectrum-analyzer-api-audioanalyzerbi)
  - [Constants](#audioanalyzer-constants)
  - [Types](#audioanalyzer-types)
  - [Lifecycle and Calculation](#audioanalyzer-lifecycle-and-calculation)
  - [Metric Getters](#audioanalyzer-metric-getters)
- [Opal OPL2/OPL3 Emulator API (`Opal.bi` & `Opal.bm`)](#opal-opl2opl3-emulator-api-opalbi--opalbm)
  - [Constants](#opal-constants)
  - [Types](#opal-types)
  - [Lifecycle Management](#opal-lifecycle-management)
  - [Register Programming and I/O](#opal-register-programming-and-io)
  - [Audio Generation](#opal-audio-generation)

---

## Core Player API (`MODPlayer.bi` & `MODPlayer.bm`)

Include headers:

```vb
'$INCLUDE:'source/MODPlayer.bi'
'$INCLUDE:'source/MODPlayer.bm'
```

### MODPlayer Types

```vb
TYPE __MODPlayerPattern
    rows AS _UNSIGNED INTEGER
    note(0 TO 0, 0 TO 0) _DYNAMIC AS __MODPlayerNote
END TYPE

TYPE MODPlayer
    song AS __MODPlayerSong
    synth AS SoftSynth
    opl AS Opal
    order(0 TO 0) _DYNAMIC AS _UNSIGNED INTEGER
    pattern(0 TO 0) _DYNAMIC AS __MODPlayerPattern
    instrument(0 TO 0) _DYNAMIC AS __MODPlayerInstrument
    channel(0 TO 0) _DYNAMIC AS __MODPlayerChannel
    initialized AS _BYTE
END TYPE
```

### MODPlayer Lifecycle Management

#### `MODPlayer_Initialize%%`

```vb
FUNCTION MODPlayer_Initialize%% (player AS MODPlayer)
```

- **Description**: Initializes an instance of the MOD player, ensuring shared
  lookup tables are ready, resetting song properties, and initializing the
  underlying software synthesizer context.
- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: `_TRUE` on success; `_FALSE` on failure.

#### `MODPlayer_Finalize`

```vb
SUB MODPlayer_Finalize (player AS MODPlayer)
```

- **Description**: Stops active playback, releases voices and mixer buffers in
  the software synthesizer, and resets the player context.
- **Parameters**:
  - `player`: Target MOD player instance.

#### `MODPlayer_IsInitialized%%`

```vb
FUNCTION MODPlayer_IsInitialized%% (player AS MODPlayer)
```

- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: `_TRUE` if initialized; `_FALSE` otherwise.

---

### Module Loading (Unified Dispatcher)

#### `MODPlayer_LoadFromDisk%%`

```vb
FUNCTION MODPlayer_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
```

- **Description**: Loads and parses a tracker module file from disk.
  Automatically identifies the file format (S3M, MTM, or MOD), auto-detects
  any StarTrekker companion instrument files (`.mod.nt`, `.nt`, `.as`), and
  delegates parsing to the appropriate format loader.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `fileName`: Path to the module file.
- **Returns**: `_TRUE` (-1) if successfully loaded; `_FALSE` (0) otherwise.

#### `MODPlayer_LoadFromMemory%%`

```vb
FUNCTION MODPlayer_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Description**: Parses a tracker module from an in-memory binary string.
  Automatically tries registered loaders (S3M, MTM, MOD) in sequence.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `buffer`: In-memory binary representation of the module file.
- **Returns**: `_TRUE` (-1) on success; `_FALSE` (0) on failure.

#### `MODPlayer_LoadWithCompanion%%`

```vb
FUNCTION MODPlayer_LoadWithCompanion%% (player AS MODPlayer, _
    buffer AS STRING, companionBuffer AS STRING)
```

- **Description**: Parses a tracker module from an in-memory binary string with
  optional companion data (such as StarTrekker `.mod.nt` / `.as` AM synth files).
- **Parameters**:
  - `player`: Target MOD player instance.
  - `buffer`: In-memory binary representation of the module file.
  - `companionBuffer`: In-memory companion file data, or empty string.
- **Returns**: `_TRUE` (-1) on success; `_FALSE` (0) on failure.

---

### Playback Controls

#### `MODPlayer_Play`

```vb
SUB MODPlayer_Play (player AS MODPlayer)
```

- **Description**: Starts or resumes song playback from the current position.
- **Parameters**:
  - `player`: Target MOD player instance.

#### `MODPlayer_Stop`

```vb
SUB MODPlayer_Stop (player AS MODPlayer)
```

- **Description**: Stops song playback, resets voice outputs, and rewinds
  position to the beginning (order 0, row 0).
- **Parameters**:
  - `player`: Target MOD player instance.

#### `MODPlayer_Pause`

```vb
SUB MODPlayer_Pause (player AS MODPlayer, state AS _BYTE)
```

- **Description**: Sets the pause state of the player.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `state`: Pass `_TRUE` to pause playback, or `_FALSE` to unpause.

#### `MODPlayer_IsPlaying%%`

```vb
FUNCTION MODPlayer_IsPlaying%% (player AS MODPlayer)
```

- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: `_TRUE` if playback is currently active; `_FALSE` otherwise.

#### `MODPlayer_IsPaused%%`

```vb
FUNCTION MODPlayer_IsPaused%% (player AS MODPlayer)
```

- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: `_TRUE` if the player is currently paused; `_FALSE` otherwise.

#### `MODPlayer_Loop`

```vb
SUB MODPlayer_Loop (player AS MODPlayer, state AS _BYTE)
```

- **Description**: Enables or disables song-level looping when reaching the end
  of the order list.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `state`: `_TRUE` to enable looping; `_FALSE` to stop at end of song.

#### `MODPlayer_IsLooping%%`

```vb
FUNCTION MODPlayer_IsLooping%% (player AS MODPlayer)
```

- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: `_TRUE` if song looping is active; `_FALSE` otherwise.

#### `MODPlayer_Update`

```vb
SUB MODPlayer_Update (player AS MODPlayer, bufferTimeSecs AS SINGLE)
```

- **Description**: Drives tracker tick sequencing and generates PCM audio
  frames to keep the hardware audio pipe filled. Call this periodically within
  your main application loop (e.g. 60 Hz).
- **Parameters**:
  - `player`: Target MOD player instance.
  - `bufferTimeSecs`: Desired buffered audio length in seconds (e.g. `0.05` for
    50 ms).

---

### Song Information and Navigation

#### `MODPlayer_GetName$`

```vb
FUNCTION MODPlayer_GetName$ (player AS MODPlayer)
```

- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: The song title or caption string extracted from the module
  header.

#### `MODPlayer_GetType$`

```vb
FUNCTION MODPlayer_GetType$ (player AS MODPlayer)
```

- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: The detected format identifier or subtype string (e.g.
  `"M.K."`, `"SCRM"`, `"MTM1"`, `"4CHN"`).

#### `MODPlayer_GetPosition&`

```vb
FUNCTION MODPlayer_GetPosition& (player AS MODPlayer)
```

- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: Current 0-based order playback position index.

#### `MODPlayer_GetOrders~%`

```vb
FUNCTION MODPlayer_GetOrders~% (player AS MODPlayer)
```

- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: Total number of orders in the song sequence table.

#### `MODPlayer_GetPatternRows~%`

```vb
FUNCTION MODPlayer_GetPatternRows~% (player AS MODPlayer, _
    patternIndex AS _UNSIGNED INTEGER)
```

- **Parameters**:
  - `player`: Target MOD player instance.
  - `patternIndex`: 0-based pattern index.
- **Returns**: Total number of rows in the pattern, or 0 if `patternIndex` is
  invalid.

#### `MODPlayer_SetPosition`

```vb
SUB MODPlayer_SetPosition (player AS MODPlayer, position AS _UNSIGNED INTEGER)
```

- **Description**: Jumps playback directly to the specified 0-based order index.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `position`: Target order index (clamped to available orders).

#### `MODPlayer_GoToNextPosition`

```vb
SUB MODPlayer_GoToNextPosition (player AS MODPlayer)
```

- **Description**: Advances playback immediately to the next order in sequence.
- **Parameters**:
  - `player`: Target MOD player instance.

#### `MODPlayer_GoToPreviousPosition`

```vb
SUB MODPlayer_GoToPreviousPosition (player AS MODPlayer)
```

- **Description**: Rewinds playback immediately to the preceding order in
  sequence.
- **Parameters**:
  - `player`: Target MOD player instance.

---

## Dedicated Format Loaders API (`*Loader.bi`)

Each loader can be called directly when the format is known ahead of time or
when building custom loader dispatch pipelines.

### ProTracker Loader (`MODLoader.bi`)

```vb
FUNCTION MODLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION MODLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
FUNCTION MODLoader_LoadWithCompanion%% (player AS MODPlayer, _
    buffer AS STRING, companionBuffer AS STRING)
```

- **Supported Formats**: ProTracker, SoundTracker, NoiseTracker, StarTrekker,
  FastTracker MOD variants (1 to 99 channels, 15 or 31 samples, FLT8, EXO4,
  EXO8, etc.) with StarTrekker 1.2/1.3 and AudioSculpture synthesized AM
  instrument companion files.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `fileName`: Path to the module file (companion files automatically detected).
  - `buffer`: In-memory binary representation of the module file.
  - `companionBuffer`: In-memory companion file data, or empty string.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

### Scream Tracker 3 Loader (`S3MLoader.bi`)

```vb
FUNCTION S3MLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION S3MLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: Scream Tracker 3 (`SCRM` signature) modules with
  mono/stereo panning, variable sample rates, and uncompressed 8-bit PCM or
  ADPCM-4 samples.
- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

### MultiTracker Loader (`MTMLoader.bi`)

```vb
FUNCTION MTMLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION MTMLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: MultiTracker Module (`MTM` signature) files with track
  sequencing matrices and 8-bit PCM samples.
- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

### Scream Tracker 2 Loader (`STMLoader.bi`)

```vb
FUNCTION STMLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION STMLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: Scream Tracker 2 (`!Scream!` and compatible) modules
  with 4 channels, 31 instruments, signed 8-bit PCM samples, ST2 tempo timing,
  and ST2 effect commands.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `fileName`: Path to the module file.
  - `buffer`: In-memory binary representation of the module file.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

### Farandole Composer Loader (`FARLoader.bi`)

```vb
FUNCTION FARLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION FARLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: Farandole Composer (`FAR\xFE` signature) modules with up
  to 16 channels, variable rows per pattern, custom tempo, channel panning, and
  8-bit signed PCM samples.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `fileName`: Path to the module file.
  - `buffer`: In-memory binary representation of the module file.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

### Composer 669 Loader (`C669Loader.bi`)

```vb
FUNCTION C669Loader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION C669Loader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: Composer 669 (`if` signature) and Extended UNIS 669 (`JN` signature)
  modules with 8 channels, 64 rows per pattern, up to 64 samples (8-bit unsigned PCM),
  per-pattern tempo lists, break lengths, and standard/extended 669 effect commands.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `fileName`: Path to the module file.
  - `buffer`: In-memory binary representation of the module file.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

---

## Software Synthesizer API (`SoftSynth.bi`)

Include header:

```vb
'$INCLUDE:'source/SoftSynth.bi'
```

### SoftSynth Constants

```vb
CONST SOFTSYNTH_VOICE_NO_SOUND = -1
CONST SOFTSYNTH_VOICE_PLAY_FORWARD = 0
CONST SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP = 1
CONST SOFTSYNTH_VOICE_VOLUME_MAX! = 1!
CONST SOFTSYNTH_VOICE_VOLUME_MIN! = 0!
CONST SOFTSYNTH_VOICE_PAN_LEFT! = -1!
CONST SOFTSYNTH_VOICE_PAN_RIGHT! = 1!
CONST SOFTSYNTH_VOICE_PAN_CENTER! = 0!
CONST SOFTSYNTH_GLOBAL_VOLUME_MAX! = 1!
CONST SOFTSYNTH_MASTER_VOLUME_MAX! = 1!
CONST SOFTSYNTH_SOUND_BUFFER_CHANNELS = 2 ' Stereo output
CONST SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT! = 0.05! ' 50 ms default refill
```

### SoftSynth Types

```vb
TYPE SoftSynth
    sounds(0 TO 0) _DYNAMIC AS __SoftSynthSound
    voices(0 TO 0) _DYNAMIC AS __SoftSynthVoice
    sampleRate AS _UNSIGNED LONG
    activeVoices AS _UNSIGNED LONG
    globalVolume AS SINGLE
    totalSounds AS LONG
    totalVoices AS LONG
    initialized AS _BYTE
    soundBufferFrames AS _UNSIGNED LONG
    soundBufferSamples AS _UNSIGNED LONG
    soundBufferBytes AS _UNSIGNED LONG
    soundMasterVolume AS SINGLE
    soundHandle AS LONG
    soundBuffer(0 TO 0) _DYNAMIC AS SINGLE
END TYPE
```

### SoftSynth Lifecycle Management

#### `SoftSynth_Initialize%%`

```vb
FUNCTION SoftSynth_Initialize%% (ctx AS SoftSynth)
```

- **Description**: Initializes an instance of the software synthesizer, opens
  the hardware sound pipe (`_SNDOPENRAW`), and allocates mix buffers.
- **Returns**: `_TRUE` on success; `_FALSE` on failure.

#### `SoftSynth_Finalize`

```vb
SUB SoftSynth_Finalize (ctx AS SoftSynth)
```

- **Description**: Closes sound handles, unbinds voices, frees sample memory,
  and resets the context.

#### `SoftSynth_IsInitialized%%`

```vb
FUNCTION SoftSynth_IsInitialized%% (ctx AS SoftSynth)
```

- **Returns**: `_TRUE` if the context has been initialized; `_FALSE` otherwise.

---

### SoftSynth Audio Buffer and Playback Control

#### `SoftSynth_LoadSound`

<!-- markdownlint-disable MD013 -->
```vb
SUB SoftSynth_LoadSound (ctx AS SoftSynth, snd AS LONG, buffer AS STRING, bytesPerSample AS _UNSIGNED _BYTE, channels AS _UNSIGNED _BYTE)
```
<!-- markdownlint-enable MD013 -->

- **Description**: Loads raw PCM sample data into a sound slot. Automatically
  converts 8-bit/16-bit signed PCM data into mono single-precision float frames.
- **Parameters**:
  - `ctx`: Synthesizer context.
  - `snd`: Sound slot index (0-based).
  - `buffer`: Raw PCM sample byte string.
  - `bytesPerSample`: Frame byte depth (1 for S8, 2 for S16).
  - `channels`: Channels in input data (1 for mono, 2 for stereo interleaved).

#### `SoftSynth_PlayVoice`

<!-- markdownlint-disable MD013 -->
```vb
SUB SoftSynth_PlayVoice (ctx AS SoftSynth, voice AS _UNSIGNED LONG, snd AS LONG, position AS _UNSIGNED LONG, mode AS LONG, startPosition AS _UNSIGNED LONG, endPosition AS _UNSIGNED LONG)
```
<!-- markdownlint-enable MD013 -->

- **Description**: Binds a sound to a voice and begins playback.
- **Parameters**:
  - `voice`: Target voice index (0-based).
  - `snd`: Sound slot index to play.
  - `position`: Initial frame position to start playing from.
  - `mode`: `SOFTSYNTH_VOICE_PLAY_FORWARD` or
    `SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP`.
  - `startPosition`: Loop restart frame boundary (or playback start).
  - `endPosition`: Loop ending frame boundary.

#### `SoftSynth_StopVoice`

```vb
SUB SoftSynth_StopVoice (ctx AS SoftSynth, voice AS _UNSIGNED LONG)
```

- **Description**: Immediately stops and silences the specified voice.

#### `SoftSynth_Render`

```vb
SUB SoftSynth_Render (ctx AS SoftSynth, frames AS _UNSIGNED LONG)
```

- **Description**: Renders PCM audio frames from all active voices into the
  internal mix buffer without pushing to the QB64 hardware sound pipe.

#### `SoftSynth_PushAudio`

```vb
SUB SoftSynth_PushAudio (ctx AS SoftSynth)
```

- **Description**: Streams the rendered audio samples currently in the internal
  mix buffer to the QB64 raw sound pipe (`_SNDRAWBATCH`).

#### `SoftSynth_MixInterleavedI16`

<!-- markdownlint-disable MD013 -->
```vb
SUB SoftSynth_MixInterleavedI16 (ctx AS SoftSynth, samples() AS INTEGER, frames AS _UNSIGNED LONG)
```
<!-- markdownlint-enable MD013 -->

- **Description**: Accumulates 16-bit interleaved stereo PCM frames (e.g. from
  the Opal FM emulator) directly into the internal 32-bit floating-point mix
  buffer with global volume scaling.
- **Parameters**:
  - `ctx`: Software synthesizer context.
  - `samples()`: Interleaved 16-bit signed stereo PCM samples (`L, R, L, R...`).
  - `frames`: Number of stereo frames to mix.

#### `SoftSynth_GetBufferedSoundTime#`

```vb
FUNCTION SoftSynth_GetBufferedSoundTime# (ctx AS SoftSynth)
```

- **Returns**: Estimated duration in seconds of unprocessed audio currently
  queued in the output sound pipe (`_SNDRAWLEN`).

---

### SoftSynth Voice Parameter Controls

<!-- markdownlint-disable MD013 -->
```vb
FUNCTION SoftSynth_GetActiveVoices~& (ctx AS SoftSynth)
FUNCTION SoftSynth_GetTotalVoices~& (ctx AS SoftSynth)
SUB SoftSynth_SetTotalVoices (ctx AS SoftSynth, voices AS _UNSIGNED LONG)
FUNCTION SoftSynth_GetTotalSounds~& (ctx AS SoftSynth)
FUNCTION SoftSynth_GetSampleRate~& (ctx AS SoftSynth)
FUNCTION SoftSynth_GetMasterVolume! (ctx AS SoftSynth)
SUB SoftSynth_SetMasterVolume (ctx AS SoftSynth, volume AS SINGLE)
FUNCTION SoftSynth_GetGlobalVolume! (ctx AS SoftSynth)
SUB SoftSynth_SetGlobalVolume (ctx AS SoftSynth, volume AS SINGLE)
FUNCTION SoftSynth_GetVoiceVolume! (ctx AS SoftSynth, voice AS _UNSIGNED LONG)
SUB SoftSynth_SetVoiceVolume (ctx AS SoftSynth, voice AS _UNSIGNED LONG, volume AS SINGLE)
FUNCTION SoftSynth_GetVoiceBalance! (ctx AS SoftSynth, voice AS _UNSIGNED LONG)
SUB SoftSynth_SetVoiceBalance (ctx AS SoftSynth, voice AS _UNSIGNED LONG, balance AS SINGLE)
FUNCTION SoftSynth_GetVoiceFrequency~& (ctx AS SoftSynth, voice AS _UNSIGNED LONG)
SUB SoftSynth_SetVoiceFrequency (ctx AS SoftSynth, voice AS _UNSIGNED LONG, frequency AS _UNSIGNED LONG)
```
<!-- markdownlint-enable MD013 -->

- **Panning**: Voice balance ranges from `-1.0` (hard left) to `+1.0` (hard
  right), using constant-power (-3 dB) cosine/sine pan laws.
- **Volume**: Volumes range from `0.0` (silent) to `1.0` (maximum amplitude).

---

### SoftSynth Sound Frame Peeking and Poking

Direct frame access functions allow inspecting and dynamically synthesizing
sound samples:

<!-- markdownlint-disable MD013 -->
```vb
FUNCTION SoftSynth_PeekSoundFrameByte%% (ctx AS SoftSynth, snd AS LONG, position AS _UNSIGNED LONG)
FUNCTION SoftSynth_PeekSoundFrameInteger% (ctx AS SoftSynth, snd AS LONG, position AS _UNSIGNED LONG)
FUNCTION SoftSynth_PeekSoundFrameSingle! (ctx AS SoftSynth, snd AS LONG, position AS _UNSIGNED LONG)
SUB SoftSynth_PokeSoundFrameByte (ctx AS SoftSynth, snd AS LONG, position AS _UNSIGNED LONG, frame AS _BYTE)
SUB SoftSynth_PokeSoundFrameInteger (ctx AS SoftSynth, snd AS LONG, position AS _UNSIGNED LONG, frame AS INTEGER)
SUB SoftSynth_PokeSoundFrameSingle (ctx AS SoftSynth, snd AS LONG, position AS _UNSIGNED LONG, frame AS SINGLE)
```
<!-- markdownlint-enable MD013 -->

---

## Audio Spectrum Analyzer API (`AudioAnalyzer.bi`)

Include header:

```vb
'$INCLUDE:'source/AudioAnalyzer.bi'
```

### AudioAnalyzer Constants

```vb
CONST AUDIO_ANALYZER_MAX_BIT_DEPTH = 11
CONST AUDIO_ANALYZER_MAX_SAMPLES = 2 ^ AUDIO_ANALYZER_MAX_BIT_DEPTH ' 2048
CONST AUDIO_ANALYZER_MAX_BINS = AUDIO_ANALYZER_MAX_SAMPLES \ 2      ' 1024
```

### AudioAnalyzer Types

```vb
TYPE AudioAnalyzer
    fftBuffer(0 TO 2 * AUDIO_ANALYZER_MAX_SAMPLES - 1) AS LONG
    averageIntensity AS SINGLE
    peakAmplitude AS _UNSIGNED INTEGER
    peakBin AS LONG
    initialized AS _BYTE
END TYPE
```

### AudioAnalyzer Lifecycle and Calculation

#### `AudioAnalyzer_Initialize%%`

```vb
FUNCTION AudioAnalyzer_Initialize%% (analyzer AS AudioAnalyzer)
```

- **Description**: Initializes an `AudioAnalyzer` instance and populates
  shared trigonometric and bit-reversal lookup tables if not already loaded.
- **Returns**: `_TRUE` on success; `_FALSE` on failure.

#### `AudioAnalyzer_Finalize`

```vb
SUB AudioAnalyzer_Finalize (analyzer AS AudioAnalyzer)
```

- **Description**: Clears internal FFT buffers and resets metrics.

#### `AudioAnalyzer_IsInitialized%%`

```vb
FUNCTION AudioAnalyzer_IsInitialized%% (analyzer AS AudioAnalyzer)
```

- **Returns**: `_TRUE` if initialized; `_FALSE` otherwise.

#### `AudioAnalyzer_CalculateFFT`

<!-- markdownlint-disable MD013 -->
```vb
SUB AudioAnalyzer_CalculateFFT (analyzer AS AudioAnalyzer, amplitudeArray() AS _UNSIGNED INTEGER, sampleDataArray() AS SINGLE, sampleOffset AS LONG, sampleIncrement AS LONG, bitDepth AS LONG)
```
<!-- markdownlint-enable MD013 -->

- **Description**: Computes radix-2 Fast Fourier Transform frequency bins from
  input audio sample data using an in-place decimation-in-time algorithm. Also
  computes average signal intensity, peak amplitude, and peak frequency bin.
- **Parameters**:
  - `analyzer`: Audio analyzer instance context.
  - `amplitudeArray()`: Output array sized to at least `2 ^ (bitDepth - 1)`
    bins to receive magnitude values.
  - `sampleDataArray()`: Input array of floating-point audio frames (e.g. from
    SoftSynth).
  - `sampleOffset`: Starting index in `sampleDataArray()`.
  - `sampleIncrement`: Stride between samples (e.g. 2 for stereo interleaved
    left/right).
  - `bitDepth`: Transform power-of-two exponent (typically 7 to 11 for 128 to
    2048 samples).

---

### AudioAnalyzer Metric Getters

#### `AudioAnalyzer_GetAverageIntensity!`

```vb
FUNCTION AudioAnalyzer_GetAverageIntensity! (analyzer AS AudioAnalyzer)
```

- **Returns**: Average spectrum bin intensity scaled to `[0.0, 1.0]`. Useful
  for driving VU meters, bass pulses, and visual effects.

#### `AudioAnalyzer_GetRMS!`

```vb
FUNCTION AudioAnalyzer_GetRMS! (analyzer AS AudioAnalyzer)
```

- **Returns**: Root-Mean-Square energy of the spectrum magnitude scaled to
  `[0.0, 1.0]`.

#### `AudioAnalyzer_GetPeakAmplitude~%`

```vb
FUNCTION AudioAnalyzer_GetPeakAmplitude~% (analyzer AS AudioAnalyzer)
```

- **Returns**: Maximum magnitude among all computed frequency bins.

#### `AudioAnalyzer_GetPeakBin&`

```vb
FUNCTION AudioAnalyzer_GetPeakBin& (analyzer AS AudioAnalyzer)
```

- **Returns**: Zero-based bin index containing the peak amplitude.

---

## Opal OPL2/OPL3 Emulator API (`Opal.bi` & `Opal.bm`)

Include headers:

```vb
'$INCLUDE:'source/Opal.bi'
'$INCLUDE:'source/Opal.bm'
```

### Opal Constants

```vb
CONST OPAL_OPL3_SAMPLE_RATE = 49716 ' Native OPL3 clock sample rate
CONST OPAL_CHANNEL_COUNT = 18       ' 18 channels (OPL3) or 9 channels (OPL2)
CONST OPAL_OPERATOR_COUNT = 36      ' 36 operators (OPL3) or 18 operators (OPL2)
CONST OPAL_WRITEBUF_SIZE = 4096     ' Internal register write queue capacity
CONST OPAL_WRITEBUF_DELAY = 2       ' Write queue delay in sample clocks
```

### Opal Types

```vb
TYPE Opal
    sampleRate AS LONG
    sampleAccum AS LONG
    lastOutput(0 TO 1) _STATIC AS INTEGER
    currOutput(0 TO 1) _STATIC AS INTEGER
    chan(0 TO 17) _STATIC AS __OpalChannel
    op(0 TO 35) _STATIC AS __OpalOperator
    timer(0 TO 1) _STATIC AS _UNSIGNED _BYTE
    timerControl AS _UNSIGNED _BYTE
    timerCount(0 TO 1) _STATIC AS _UNSIGNED INTEGER
    status AS _UNSIGNED _BYTE
    newMode AS _UNSIGNED _BYTE
    pairEnable AS _UNSIGNED _BYTE
    rhythmMode AS _UNSIGNED _BYTE
    noteSelect AS _UNSIGNED _BYTE
    tremoloDepth AS _UNSIGNED _BYTE
    vibratoDepth AS _UNSIGNED _BYTE
    waveSelectEnable AS _UNSIGNED _BYTE
    compositeSine AS _UNSIGNED _BYTE
    tremoloPosition AS _UNSIGNED _BYTE
    tremoloLevel AS _UNSIGNED _BYTE
    sampleCounter AS _UNSIGNED INTEGER
    hiHatPhase AS _UNSIGNED INTEGER
    cymbalPhase AS _UNSIGNED INTEGER
    noise AS _UNSIGNED LONG
    pendingRight AS LONG
    chipSamples AS _UNSIGNED _INTEGER64
    lastDue AS _UNSIGNED _INTEGER64
    queueHead AS _UNSIGNED INTEGER
    queueCount AS _UNSIGNED INTEGER
    queue(0 TO 4095) _STATIC AS __OpalQueuedWrite
END TYPE
```

---

### Opal Lifecycle Management

#### `Opal_Initialize`

```vb
SUB Opal_Initialize (self AS Opal, sampleRate AS LONG)
```

- **Description**: Initializes an Opal emulator instance, resets all channel
  and operator states, zeroes registers, and configures the target output sample
  rate with internal linear resampling.
- **Parameters**:
  - `self`: Opal instance context.
  - `sampleRate`: Target playback sample rate (e.g. 44100 or 48000 Hz).

#### `Opal_SetSampleRate`

```vb
SUB Opal_SetSampleRate (self AS Opal, sampleRate AS LONG)
```

- **Description**: Updates the output sample rate and resets internal
  resampling accumulators.
- **Parameters**:
  - `self`: Opal instance context.
  - `sampleRate`: New output sample rate.

---

### Opal Register Programming and I/O

#### `Opal_Write`

<!-- markdownlint-disable MD013 -->
```vb
SUB Opal_Write (self AS Opal, regNum AS _UNSIGNED INTEGER, valByte AS _UNSIGNED _BYTE)
```
<!-- markdownlint-enable MD013 -->

- **Description**: Writes directly to an OPL2/OPL3 register. Primary registers
  use `&H00..&HFF`; secondary OPL3 bank registers use `&H100..&H1FF`.
- **Parameters**:
  - `self`: Opal instance context.
  - `regNum`: 9-bit register index (`0x000` - `0x1FF`).
  - `valByte`: 8-bit register data byte.

#### `Opal_WriteBuffered`

<!-- markdownlint-disable MD013 -->
```vb
SUB Opal_WriteBuffered (self AS Opal, regNum AS _UNSIGNED INTEGER, valByte AS _UNSIGNED _BYTE)
```
<!-- markdownlint-enable MD013 -->

- **Description**: Enqueues a register write into the internal write buffer
  with a slight sample clock delay, emulating ISA bus timing.
- **Parameters**:
  - `self`: Opal instance context.
  - `regNum`: Register index.
  - `valByte`: Register data byte.

#### `Opal_FlushWriteBuffer`

```vb
SUB Opal_FlushWriteBuffer (self AS Opal)
```

- **Description**: Immediately executes all queued register writes without
  waiting for clock delays.

#### `Opal_ReadStatus~%%`

```vb
FUNCTION Opal_ReadStatus~%% (self AS Opal)
```

- **Returns**: Current 8-bit chip status byte (including timer flag bits 7, 6,
  5).

#### `Opal_SetPan`

<!-- markdownlint-disable MD013 -->
```vb
SUB Opal_SetPan (self AS Opal, channel AS _UNSIGNED INTEGER, pan AS _UNSIGNED _BYTE)
```
<!-- markdownlint-enable MD013 -->

- **Description**: Configures stereo panning attenuation for an OPL channel
  (`0` = hard left, `64` = center, `127` = hard right).
- **Parameters**:
  - `self`: Opal instance context.
  - `channel`: Zero-based channel index (`0` - `17`).
  - `pan`: Pan position byte (`0` - `127`).

---

### Opal Audio Generation

#### `Opal_GenerateSample`

```vb
SUB Opal_GenerateSample (self AS Opal, left AS INTEGER, right AS INTEGER)
```

- **Description**: Generates a single stereo 16-bit PCM output sample frame
  resampled to the configured output sample rate.
- **Parameters**:
  - `self`: Opal instance context.
  - `left`: Output variable receiving signed 16-bit left channel sample.
  - `right`: Output variable receiving signed 16-bit right channel sample.
