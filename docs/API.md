# QB64 MOD Player API Reference

This document provides the complete API reference for the QB64 MOD Player
libraries, including the Core Player, Dedicated Format Loaders, Software
Synthesizer / Sample Mixer, and Audio Spectrum Analyzer.

---

## Table of Contents

- [Core Player API (`MODPlayer.bi` & `MODPlayer.bm`)](#core-player-api-modplayerbi--modplayerbm)
  - [Constants](#modplayer-constants)
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
  - [Reality Adlib Tracker Loader (`RADLoader.bi`)](#reality-adlib-tracker-loader-radloaderbi)
  - [UltraTracker Loader (`ULTLoader.bi`)](#ultratracker-loader-ultloaderbi)
  - [Digitrakker Loader (`MDLLoader.bi`)](#digitrakker-loader-mdlloaderbi)
  - [Advanced Music Format Loader (`AMFLoader.bi`)](#advanced-music-format-loader-amfloaderbi)
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
- [Geometry and Bounding Box API (`Bounds2f.bi`)](#geometry-and-bounding-box-api-bounds2fbi)
  - [Types](#bounds2f-types)
  - [Initialization and Sanitization](#bounds2f-initialization-and-sanitization)
  - [Geometric Queries](#bounds2f-geometric-queries)
- [Input Management API (`Input.bi`)](#input-management-api-inputbi)
  - [Constants](#input-constants)
  - [Frame Polling](#input-frame-polling)
  - [Keyboard APIs](#input-keyboard-apis)
  - [Mouse APIs](#input-mouse-apis)
  - [Game Controller APIs](#input-game-controller-apis)
  - [TUI Navigation Actions](#input-tui-navigation-actions)
  - [Window Event APIs](#input-window-event-apis)

---

## Core Player API (`MODPlayer.bi` & `MODPlayer.bm`)

Include headers:

```vb
'$INCLUDE:'source/MODPlayer.bi'
'$INCLUDE:'source/MODPlayer.bm'
```

### MODPlayer Constants

#### Format Constants

Format identifiers stored in `player.song.format` and returned by `MODPlayer_GetFormat~%`:

```vb
CONST MODPLAYER_FORMAT_NONE~% = 0~% ' Uninitialized / unknown format
CONST MODPLAYER_FORMAT_MOD~%  = 1~% ' ProTracker / NoiseTracker / SoundTracker / FastTracker 1 (.MOD, .STK, .M15)
CONST MODPLAYER_FORMAT_STM~%  = 2~% ' Scream Tracker 2 (.STM)
CONST MODPLAYER_FORMAT_S3M~%  = 3~% ' Scream Tracker 3 (.S3M)
CONST MODPLAYER_FORMAT_669~%  = 4~% ' Composer 669 / Extended 669 (.669)
CONST MODPLAYER_FORMAT_MTM~%  = 5~% ' MultiTracker Module (.MTM)
CONST MODPLAYER_FORMAT_FAR~%  = 6~% ' Farandole Composer (.FAR)
CONST MODPLAYER_FORMAT_RAD~%  = 7~% ' Reality Adlib Tracker (.RAD)
CONST MODPLAYER_FORMAT_ULT~%  = 8~% ' UltraTracker (.ULT)
CONST MODPLAYER_FORMAT_MDL~%  = 9~% ' Digitrakker (.MDL)
CONST MODPLAYER_FORMAT_AMF~%  = 10~% ' Advanced Music Format (.AMF / DSMI / Asylum)
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

#### `MODPlayer_GetFormat~%`

```vb
FUNCTION MODPlayer_GetFormat~% (player AS MODPlayer)
```

- **Description**: Returns the format constant of the currently loaded tune.
- **Parameters**:
  - `player`: Target MOD player instance.
- **Returns**: Format constant (e.g. `MODPLAYER_FORMAT_MOD`, `MODPLAYER_FORMAT_S3M`,
  `MODPLAYER_FORMAT_MDL`, etc.), or `MODPLAYER_FORMAT_NONE` if uninitialized.

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
  FastTracker MOD variants (.MOD, .STK, .M15; 1 to 99 channels, 15 or 31 samples,
  FLT8, EXO4, EXO8, etc.) with StarTrekker 1.2/1.3 and AudioSculpture synthesized AM
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

### Reality Adlib Tracker Loader (`RADLoader.bi`)

```vb
FUNCTION RADLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION RADLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: Reality Adlib Tracker v1.0 (`RAD by REALiTY!!`, version `0x10`) modules with
  song subtype `"RAD1"`, 9 OPL2 melody channels, 64 rows per pattern, up to 31 HSC 2-operator instruments, order lists
  up to 128 entries, slow-timer (~18.2 Hz) and standard (50 Hz) timing, and standard effects
  (portamento up/down, tone portamento, volume slide 1..99, set volume, pattern break, set speed).
- **Parameters**:
  - `player`: Target MOD player instance.
  - `fileName`: Path to the module file.
  - `buffer`: In-memory binary representation of the module file.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

### UltraTracker Loader (`ULTLoader.bi`)

```vb
FUNCTION ULTLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION ULTLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: UltraTracker (`MAS_UTrack_V001` through `MAS_UTrack_V004`) modules with
  song subtype `"ULT1"` through `"ULT4"`, 1 to 32 channels, 64 rows per pattern, up to 64 samples
  (8-bit and 16-bit signed PCM), per-channel panning tables, RLE track unpacking, and dual-effect
  command translation.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `fileName`: Path to the module file.
  - `buffer`: In-memory binary representation of the module file.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

### Digitrakker Loader (`MDLLoader.bi`)

```vb
FUNCTION MDLLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION MDLLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: Digitrakker (`DMDL` signature) modules across versions `0x00` (v0.0 / v2.0),
  `0x10` (v1.0 / v2.9 / v3.0 early), and `0x11` (v1.1 / v3.0+) with song subtypes `"MDL0"`, `"MDL1"`, and `"MDL2"`.
  Supports 4 to 32 channels, variable pattern lengths (1 to 256 rows), 8-bit and 16-bit signed PCM samples,
  entropy-coded Huffman delta sample decompression (packing methods 1 and 2), multi-sample instruments with note split maps,
  forward and bidirectional (ping-pong) looping, and dual-effect command translation.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `fileName`: Path to the module file.
  - `buffer`: In-memory binary representation of the module file.
- **Returns**: `_TRUE` on successful parse; `_FALSE` if incompatible or invalid.

### Advanced Music Format Loader (`AMFLoader.bi`)

```vb
FUNCTION AMFLoader_LoadFromDisk%% (player AS MODPlayer, fileName AS STRING)
FUNCTION AMFLoader_LoadFromMemory%% (player AS MODPlayer, buffer AS STRING)
```

- **Supported Formats**: Otto Chrons' Advanced Music Format (DSMI / DMP `.AMF` across revisions `v1.0` through `v1.4`, signatures `AMF\x01` and `AMF\x08` through `AMF\x0E`) and Asylum Music Format (`ASYLUM Music Format V1.0\0`). Supports 1 to 32 channels, track matrix mapping, per-channel panning, variable pattern rows (up to 256 rows in v1.4), 8-bit unsigned and signed PCM audio samples, and tracker effect translation.
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
CONST SOFTSYNTH_VOICE_PLAY_BIDIRECTIONAL_LOOP = 2
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
  - `mode`: `SOFTSYNTH_VOICE_PLAY_FORWARD`,
    `SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP`, or
    `SOFTSYNTH_VOICE_PLAY_BIDIRECTIONAL_LOOP`.
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

#### `Opal_GetChipType&`

```vb
FUNCTION Opal_GetChipType& (self AS Opal)
```

- **Description**: Returns the active chip mode constant (`OPAL_CHIP_TYPE_OPL2` = 0, `OPAL_CHIP_TYPE_OPL3` = 1). Following real Yamaha YMF262 (OPL3) hardware behavior, the chip powers up in backwards-compatible OPL2 mode by default, and enters OPL3 mode when register `0x105` bit 0 is written as 1.
- **Parameters**:
  - `self`: Opal instance context.
- **Returns**: Chip mode constant (`OPAL_CHIP_TYPE_OPL2` or `OPAL_CHIP_TYPE_OPL3`).

#### `Opal_SetChipType`

```vb
SUB Opal_SetChipType (self AS Opal, chipType AS LONG)
```

- **Description**: Configures OPL2 mode (`OPAL_CHIP_TYPE_OPL2`) or OPL3 mode (`OPAL_CHIP_TYPE_OPL3`). In OPL2 mode, writes to Bank 1 registers (>= 0x100) are ignored except register 0x105, 4-op register 0x104 is inactive, and waveforms are gated by register 0x01 bit 5 (`waveSelectEnable`).
- **Parameters**:
  - `self`: Opal instance context.
  - `chipType`: `OPAL_CHIP_TYPE_OPL2` or `OPAL_CHIP_TYPE_OPL3`.

#### `Opal_IsOPL3%%`

```vb
FUNCTION Opal_IsOPL3%% (self AS Opal)
```

- **Description**: Checks whether the emulator is currently operating in OPL3 mode (newMode <> 0).
- **Parameters**:
  - `self`: Opal instance context.
- **Returns**: `_TRUE` if active in OPL3 mode; `_FALSE` if in OPL2 mode.

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

---

## Geometry and Bounding Box API (`Bounds2f.bi`)

Include header:

```vb
'$INCLUDE:'source/Bounds2f.bi'
```

### Bounds2f Types

```vb
TYPE Bounds2f
    lt AS Vector2f ' Left-Top coordinate
    rb AS Vector2f ' Right-Bottom coordinate
END TYPE
```

### Bounds2f Initialization and Sanitization

- `SUB Bounds2f_Initialize (x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE, dst AS Bounds2f)`: Initializes a bounding box with coordinates.
- `SUB Bounds2f_InitializeWithVectors (lt AS Vector2f, rb AS Vector2f, dst AS Bounds2f)`: Initializes with two Vector2f corner points.
- `SUB Bounds2f_Set (x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE, dst AS Bounds2f)`: Sets box coordinates.
- `SUB Bounds2f_Sanitize (b AS Bounds2f)`: Ensures `lt.x <= rb.x` and `lt.y <= rb.y` by swapping if inverted.

### Bounds2f Geometric Queries

- `FUNCTION Bounds2f_GetWidth! (b AS Bounds2f)`: Returns the width (`rb.x - lt.x`).
- `FUNCTION Bounds2f_GetHeight! (b AS Bounds2f)`: Returns the height (`rb.y - lt.y`).
- `FUNCTION Bounds2f_ContainsPoint%% (b AS Bounds2f, pt AS Vector2f)`: Tests if point is inside or on the boundaries.
- `FUNCTION Bounds2f_ContainsPointXY%% (b AS Bounds2f, x AS SINGLE, y AS SINGLE)`: Tests if `(x, y)` is inside.
- `FUNCTION Bounds2f_Intersects%% (a AS Bounds2f, b AS Bounds2f)`: Tests if two bounding boxes overlap.

---

## Input Management API (`Input.bi`)

Unified frame-based input polling for keyboard, mouse, game controller, and window events with discrete TUI navigation actions.

Include header:

```vb
'$INCLUDE:'source/Input.bi'
```

### Input Constants

- **Mouse Buttons**: `MOUSE_BUTTON_LEFT` (1), `MOUSE_BUTTON_RIGHT` (2), `MOUSE_BUTTON_MIDDLE` / `MOUSE_BUTTON_CENTER` (3).
- **Gamepad Buttons**: `GAMEPAD_BUTTON_A` (1), `GAMEPAD_BUTTON_B` (2), `GAMEPAD_BUTTON_X` (3), `GAMEPAD_BUTTON_Y` (4), `GAMEPAD_BUTTON_LB` (5), `GAMEPAD_BUTTON_RB` (6), `GAMEPAD_BUTTON_LT` (7), `GAMEPAD_BUTTON_RT` (8), `GAMEPAD_BUTTON_BACK` (9), `GAMEPAD_BUTTON_START` (10).
- **Gamepad Axes**: `GAMEPAD_AXIS_LX` (1), `GAMEPAD_AXIS_LY` (2), `GAMEPAD_AXIS_RX` (3), `GAMEPAD_AXIS_RY` (4).
- **Deadzone**: `GAMEPAD_AXIS_DEADZONE_DEFAULT` (0.20 / 20%).
- **Modifier Keys**: `KEY_LSHIFT`, `KEY_RSHIFT`, `KEY_LCTRL`, `KEY_RCTRL`, `KEY_LALT`, `KEY_RALT`, `KEY_LSUPER`, `KEY_RSUPER`.
- **Navigation & Function Keys**: `KEY_SPACE`, `KEY_ENTER`, `KEY_ESCAPE`, `KEY_TAB`, `KEY_BACKSPACE`, `KEY_UP`, `KEY_DOWN`, `KEY_LEFT`, `KEY_RIGHT`, `KEY_PAGE_UP`, `KEY_PAGE_DOWN`, `KEY_HOME`, `KEY_END`, `KEY_INSERT`, `KEY_DELETE`, `KEY_F1` to `KEY_F12`.

### Input Frame Polling

- `SUB Input_Update`: Polls all input devices (keyboard, mouse, game controllers, window events) and computes frame deltas, transitions, and navigation actions. Call once per frame in the main application loop.
- `SUB Input_Poll`: Alias for `Input_Update`.
- `FUNCTION Input_HasEvent%%`: Returns `_TRUE` if any keyboard, mouse, window, or gamepad event is pending.

### Input Keyboard APIs

- `FUNCTION Input_HasKeyboardEvent%%`: Returns `_TRUE` if a key was pressed this frame.
- `FUNCTION Input_PeekKeyboardKey&`: Returns the last `_KEYHIT` key code without clearing it.
- `FUNCTION Input_GetKeyboardKey&`: Returns the last `_KEYHIT` key code and clears it.
- `FUNCTION Input_IsKeyDown%% (keyCode AS LONG)`: Returns `_TRUE` if the specified key is currently held down.
- `FUNCTION Input_IsKeyPressed%% (keyCode AS LONG)`: Alias for `Input_IsKeyDown`.
- `FUNCTION Input_IsShiftDown%%`: Returns `_TRUE` if either Left or Right Shift is held down.
- `FUNCTION Input_IsCtrlDown%%`: Returns `_TRUE` if either Left or Right Ctrl is held down.
- `FUNCTION Input_IsAltDown%%`: Returns `_TRUE` if either Left or Right Alt is held down.
- `FUNCTION Input_IsSuperDown%%`: Returns `_TRUE` if either Left or Right Windows/Command key is held down.

### Input Mouse APIs

- `FUNCTION Input_HasMouseEvent%%`: Returns `_TRUE` if mouse movement, wheel, or button activity occurred.
- `SUB Input_GetMousePosition (position AS Vector2f)`: Retrieves cursor position in a `Vector2f`.
- `SUB Input_GetMousePositionXY (x AS SINGLE, y AS SINGLE)`: Retrieves cursor position in scalar variables.
- `FUNCTION Input_GetMouseX! ()`: Returns current mouse X coordinate.
- `FUNCTION Input_GetMouseY! ()`: Returns current mouse Y coordinate.
- `SUB Input_GetMouseDelta (delta AS Vector2f)`: Retrieves mouse movement vector since previous frame.
- `SUB Input_GetMouseDeltaXY (dx AS SINGLE, dy AS SINGLE)`: Retrieves mouse movement delta in scalar variables.
- `FUNCTION Input_GetMouseDeltaX! ()`: Returns mouse X movement delta.
- `FUNCTION Input_GetMouseDeltaY! ()`: Returns mouse Y movement delta.
- `FUNCTION Input_GetMouseScrollWheelValue! ()`: Returns accumulated scroll wheel delta for the frame.
- `FUNCTION Input_GetMouseWheel! ()`: Alias for `Input_GetMouseScrollWheelValue`.
- `FUNCTION Input_IsMouseButtonDown%% (button AS LONG)`: Checks if a button is held down.
- `FUNCTION Input_IsMouseButtonPressed%% (button AS LONG)`: Alias for `Input_IsMouseButtonDown`.
- `FUNCTION Input_WasMouseButtonPressed%% (button AS LONG)`: Checks if a button transitioned from UP to DOWN this frame.
- `FUNCTION Input_GetMouseButtonPressed%% (button AS LONG)`: Checks button press transition and consumes it.
- `FUNCTION Input_WasMouseButtonClicked%% (button AS LONG)`: Checks if a button transitioned from DOWN to UP this frame.
- `FUNCTION Input_GetMouseButtonClicked%% (button AS LONG)`: Checks button release/click transition and consumes it.
- `SUB Input_GetMouseButtonDownPosition (button AS LONG, position AS Vector2f)`: Gets coordinate where button was pressed down.
- `SUB Input_GetMouseButtonUpPosition (button AS LONG, position AS Vector2f)`: Gets coordinate where button was released.
- `SUB Input_GetMouseButtonClickBounds (button AS LONG, bounds AS Bounds2f)`: Gets sanitized bounding box enclosing the click.
- `FUNCTION Input_IsMouseInRect%% (x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE)`: Tests if mouse cursor is within rectangle.
- `FUNCTION Input_IsMouseInBounds%% (bounds AS Bounds2f)`: Tests if mouse cursor is within bounding box.
- `FUNCTION Input_IsMouseClickInRect%% (button AS LONG, x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE)`: Tests if a button click occurred inside rectangle.
- `FUNCTION Input_IsMouseClickInBounds%% (button AS LONG, bounds AS Bounds2f)`: Tests if a button click occurred inside bounding box.
- `FUNCTION Input_IsMousePressInRect%% (button AS LONG, x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE)`: Tests if a button press occurred inside rectangle.
- `FUNCTION Input_IsMousePressInBounds%% (button AS LONG, bounds AS Bounds2f)`: Tests if a button press occurred inside bounding box.

### Input Game Controller APIs

- `FUNCTION Input_HasGamepadEvent%%`: Returns `_TRUE` if gamepad activity occurred this frame.
- `FUNCTION Input_IsGamepadConnected%% (gamepadIndex AS LONG)`: Checks if gamepad (1 or 2) is connected.
- `FUNCTION Input_GetGamepadStickLX! (gamepadIndex AS LONG)`: Returns normalized left stick X in range `[-1.0, 1.0]`.
- `FUNCTION Input_GetGamepadStickLY! (gamepadIndex AS LONG)`: Returns normalized left stick Y in range `[-1.0, 1.0]`.
- `FUNCTION Input_GetGamepadStickRX! (gamepadIndex AS LONG)`: Returns normalized right stick X in range `[-1.0, 1.0]`.
- `FUNCTION Input_GetGamepadStickRY! (gamepadIndex AS LONG)`: Returns normalized right stick Y in range `[-1.0, 1.0]`.
- `SUB Input_GetGamepadStickL (vec AS Vector2f, gamepadIndex AS LONG)`: Retrieves normalized left stick vector.
- `SUB Input_GetGamepadStickR (vec AS Vector2f, gamepadIndex AS LONG)`: Retrieves normalized right stick vector.
- `FUNCTION Input_GetGamepadAxis! (axisIndex AS LONG, gamepadIndex AS LONG)`: Queries stick axis by `GAMEPAD_AXIS_*` constant.
- `FUNCTION Input_IsGamepadButtonDown%% (buttonIndex AS LONG, gamepadIndex AS LONG)`: Checks if gamepad button is held down.
- `FUNCTION Input_WasGamepadButtonPressed%% (buttonIndex AS LONG, gamepadIndex AS LONG)`: Checks if button was pressed this frame.
- `FUNCTION Input_GetGamepadButtonPressed%% (buttonIndex AS LONG, gamepadIndex AS LONG)`: Checks button press transition and consumes it.
- `FUNCTION Input_WasGamepadButtonReleased%% (buttonIndex AS LONG, gamepadIndex AS LONG)`: Checks if button was released this frame.
- `SUB Input_SetGamepadDeadzone (deadzone AS SINGLE)`: Sets stick deadzone threshold (clamped to `[0.0, 0.99]`).
- `FUNCTION Input_GetGamepadDeadzone! ()`: Returns current analog stick deadzone.
- `FUNCTION Input_GetControllerAxis% (axis AS INTEGER)`: GlyphUI compatibility returning raw stick coordinate (1..254).
- `FUNCTION Input_IsControllerButtonPressed% (button AS INTEGER)`: GlyphUI compatibility returning button state for Gamepad 1.

### Input TUI Navigation Actions

Synthesizes discrete, edge-triggered navigation pulses combining Keyboard, Gamepad, and Mouse to prevent runaway scrolling:

- `FUNCTION Input_NavUp%%`: Returns `_TRUE` on Up Arrow, Keypad Up, or Gamepad Stick Up pulse.
- `FUNCTION Input_NavDown%%`: Returns `_TRUE` on Down Arrow, Keypad Down, or Gamepad Stick Down pulse.
- `FUNCTION Input_NavLeft%%`: Returns `_TRUE` on Left Arrow, Keypad Left, or Gamepad Stick Left pulse.
- `FUNCTION Input_NavRight%%`: Returns `_TRUE` on Right Arrow, Keypad Right, or Gamepad Stick Right pulse.
- `FUNCTION Input_NavConfirm%%`: Returns `_TRUE` on Enter, Space, or Gamepad Button A / Start.
- `FUNCTION Input_NavCancel%%`: Returns `_TRUE` on Escape or Gamepad Button B / Back.
- `FUNCTION Input_NavPageUp%%`: Returns `_TRUE` on Page Up or Gamepad Left Bumper.
- `FUNCTION Input_NavPageDown%%`: Returns `_TRUE` on Page Down or Gamepad Right Bumper.

### Input Window Event APIs

- `FUNCTION Input_HasWindowEvent%%`: Returns `_TRUE` if a window resize or exit request occurred.
- `FUNCTION Input_WindowShouldClose%%`: Returns `_TRUE` if the window close button (`_EXIT`) was clicked.
- `SUB Input_SetWindowShouldClose (shouldClose AS _BYTE)`: Programmatically sets the window close request state.
- `FUNCTION Input_WasWindowResized%%`: Returns `_TRUE` if the window was resized (`_RESIZE`) this frame.
- `FUNCTION Input_GetWindowResizeWidth! ()`: Returns new window width if resized.
- `FUNCTION Input_GetWindowResizeHeight! ()`: Returns new window height if resized.
- `SUB Input_GetWindowResizeSize (size AS Vector2f)`: Retrieves new window dimensions in a `Vector2f`.
