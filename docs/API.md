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
  - [Channel Mute and Solo Controls](#channel-mute-and-solo-controls)
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
- [Immediate-Mode TUI API (`TUI.bi`)](#immediate-mode-tui-api-tuibi)
  - [Constants](#tui-constants)
  - [Types](#tui-types)
  - [Frame Lifecycle Management](#tui-frame-lifecycle-management)
  - [Immediate Widgets](#tui-immediate-widgets)
- [Playlist Management API (`Playlist.bi`)](#playlist-management-api-playlistbi)
  - [Constants](#playlist-constants)
  - [Types](#playlist-types)
  - [Queue Management and Navigation](#playlist-queue-management-and-navigation)
  - [M3U File I/O](#playlist-m3u-file-io)
- [Background Visual Animation API (`Background.bi`)](#background-visual-animation-api-backgroundbi)
  - [Constants and Modes](#background-constants-and-modes)
  - [Types](#background-types)
  - [Lifecycle and Rendering](#background-lifecycle-and-rendering)
  - [Mode Control and Queries](#background-mode-control-and-queries)

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
    _DYNAMIC note(0 TO 0, 0 TO 0) AS __MODPlayerNote
END TYPE

TYPE MODPlayer
    song AS __MODPlayerSong
    synth AS SoftSynth
    opl AS Opal
    _DYNAMIC order(0 TO 0) AS _UNSIGNED INTEGER
    _DYNAMIC pattern(0 TO 0) AS __MODPlayerPattern
    _DYNAMIC instrument(0 TO 0) AS __MODPlayerInstrument
    _DYNAMIC channel(0 TO 0) AS __MODPlayerChannel
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

### Channel Mute and Solo Controls

#### `MODPlayer_MuteChannel`

```vb
SUB MODPlayer_MuteChannel (player AS MODPlayer, nChannel AS LONG, isMuted AS _BYTE)
```

- **Description**: Sets the mute state of a channel. Immediately attenuates the
  channel's volume output to zero (for PCM, AM synth, and OPL2 FM channels) when
  muted, or restores channel playback volume when unmuted.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `nChannel`: Channel index (0-based).
  - `isMuted`: `_TRUE` to mute, `_FALSE` to unmute.

#### `MODPlayer_ToggleChannelMute`

```vb
SUB MODPlayer_ToggleChannelMute (player AS MODPlayer, nChannel AS LONG)
```

- **Description**: Inverts the current mute state of the specified channel.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `nChannel`: Channel index (0-based).

#### `MODPlayer_IsChannelMuted%%`

```vb
FUNCTION MODPlayer_IsChannelMuted%% (player AS MODPlayer, nChannel AS LONG)
```

- **Parameters**:
  - `player`: Target MOD player instance.
  - `nChannel`: Channel index (0-based).
- **Returns**: `_TRUE` if the channel is currently muted; `_FALSE` otherwise.

#### `MODPlayer_SoloChannel`

```vb
SUB MODPlayer_SoloChannel (player AS MODPlayer, soloChannel AS LONG)
```

- **Description**: Solos the specified channel by muting all other channels while
  unmuting the selected channel. If the target channel is already soloed, calling
  this again toggles solo off and unmutes all channels.
- **Parameters**:
  - `player`: Target MOD player instance.
  - `soloChannel`: Channel index (0-based) to solo.

#### `MODPlayer_IsChannelSoloed%%`

```vb
FUNCTION MODPlayer_IsChannelSoloed%% (player AS MODPlayer, nChannel AS LONG)
```

- **Parameters**:
  - `player`: Target MOD player instance.
  - `nChannel`: Channel index (0-based).
- **Returns**: `_TRUE` if the channel is unmuted and every other channel in the
  song is muted; `_FALSE` otherwise.

#### `MODPlayer_UnmuteAllChannels`

```vb
SUB MODPlayer_UnmuteAllChannels (player AS MODPlayer)
```

- **Description**: Unmutes all channels in the currently loaded tune.
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
    _DYNAMIC sounds(0 TO 0) AS __SoftSynthSound
    _DYNAMIC voices(0 TO 0) AS __SoftSynthVoice
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
    _DYNAMIC soundBuffer(0 TO 0) AS SINGLE
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
- `FUNCTION Bounds2f_GetDiscreteWidth! (b AS Bounds2f)`: Returns the discrete / inclusive width including both edges (`1 + rb.x - lt.x`).
- `FUNCTION Bounds2f_GetDiscreteHeight! (b AS Bounds2f)`: Returns the discrete / inclusive height including both edges (`1 + rb.y - lt.y`).
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
- `SUB Input_ConsumeKeyboardKey`: Explicitly consumes the current keyboard key and resets navigation action flags.
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

---

## Immediate-Mode TUI API (`TUI.bi`)

Include headers:

```vb
'$INCLUDE:'source/TUI.bi'
```

### TUI Constants

#### Channel Action Codes

Returned in `outAction` by `TUI_ChannelBadge`:

```vb
CONST TUI_CHANNEL_ACTION_NONE%% = 0%%
CONST TUI_CHANNEL_ACTION_MUTE%% = 1%%
CONST TUI_CHANNEL_ACTION_SOLO%% = 2%%
```

#### Rate-Limiting Constants

```vb
CONST TUI_SCRUB_COOLOFF_SECS# = 0.08# ' 80 ms cool-off interval for seek scrubbing
```

#### Text Mode Color Constants

```vb
CONST TUI_COLOR_BLACK& = 0&
CONST TUI_COLOR_BLUE& = 1&
CONST TUI_COLOR_GREEN& = 2&
CONST TUI_COLOR_CYAN& = 3&
CONST TUI_COLOR_RED& = 4&
CONST TUI_COLOR_MAGENTA& = 5&
CONST TUI_COLOR_BROWN& = 6&
CONST TUI_COLOR_WHITE& = 7&
CONST TUI_COLOR_GRAY& = 8&
CONST TUI_COLOR_LIGHT_BLUE& = 9&
CONST TUI_COLOR_LIGHT_GREEN& = 10&
CONST TUI_COLOR_LIGHT_CYAN& = 11&
CONST TUI_COLOR_LIGHT_RED& = 12&
CONST TUI_COLOR_LIGHT_MAGENTA& = 13&
CONST TUI_COLOR_YELLOW& = 14&
CONST TUI_COLOR_BRIGHT_WHITE& = 15&
```

---

### TUI Types

#### `__TUI_Context`

Internal context maintaining minimal persistent state across frames:

```vb
TYPE __TUI_Context
    initialized AS _BYTE
    inFrame AS _BYTE
    widgetCount AS LONG                 ' Current frame auto-incremented widget counter
    totalWidgets AS LONG                ' Total interactive widgets from previous frame
    focusedId AS LONG                   ' Currently focused widget ID (1..totalWidgets)
    hotId AS LONG                       ' Currently hovered widget ID
    activeId AS LONG                    ' Widget currently being pressed or dragged
    mousePos AS Vector2f                ' Current mouse position (character column/row)
    mouseClickedL AS _BYTE              ' Left mouse button clicked this frame
    mouseDownL AS _BYTE                 ' Left mouse button held down this frame
    mouseClickedR AS _BYTE              ' Right mouse button clicked this frame
    navNext AS _BYTE                    ' Advance focus (Tab, Gamepad RB)
    navPrev AS _BYTE                    ' Retreat focus (Shift+Tab, Gamepad LB)
    navConfirm AS _BYTE                 ' Trigger focused widget (Enter, Space, Gamepad A)
    navSolo AS _BYTE                    ' Trigger channel solo (S, Shift+Enter, Gamepad Y/X)
    hasNavFocus AS _BYTE                ' True when keyboard/gamepad focus indicator is active
    lastScrubTime AS DOUBLE             ' Uptime timestamp of last seek scrub
    prevMousePos AS Vector2f            ' Previous frame mouse position
END TYPE
```

---

### TUI Frame Lifecycle Management

#### `TUI_Begin`

```vb
SUB TUI_Begin
```

- **Description**: Begins a new Immediate-Mode TUI frame. Gathers input state
  from `Input_*`, detects navigation cycling (Tab / Shift+Tab / Gamepad bumpers),
  advances or wraps the active focused widget ID, and resets transient frame counters.

#### `TUI_End`

```vb
SUB TUI_End
```

- **Description**: Concludes the Immediate-Mode TUI frame. Updates `totalWidgets`,
  clamps `focusedId` to the valid widget range, and resets the frame state.

---

### TUI Immediate Widgets

#### `TUI_Button%%`

```vb
FUNCTION TUI_Button%% (x AS LONG, y AS LONG, w AS LONG, text AS STRING)
```

- **Description**: Renders an interactive 3-line tall VB-DOS style 3D push button
  using in-boundary directional lighting (no drop shadows). In normal raised
  state, top and left borders are highlighted (`Bright White`) while bottom and
  right borders are in shadow (`Black`). When clicked and held down by the mouse
  or during keyboard confirmation, lighting inverts to simulate physical button
  depression without shifting the centered interior label. Action triggers on
  mouse button release while hovering over the button. The currently focused
  button is rendered with a double-line border
  (`CHR$(201)`, `CHR$(205)`, `CHR$(187)`, `CHR$(186)`, `CHR$(200)`, `CHR$(188)`),
  while non-focused buttons use a single-line border
  (`CHR$(218)`, `CHR$(196)`, `CHR$(191)`, `CHR$(179)`, `CHR$(192)`, `CHR$(217)`).
- **Parameters**:
  - `x`: 1-based character column coordinate of top-left corner.
  - `y`: 1-based character row coordinate of top-left corner.
  - `w`: Total width in characters including borders.
  - `text`: Display label string.
- **Returns**: `_TRUE` if clicked (mouse release inside bounds) or confirmed via
  keyboard / controller while focused; `_FALSE` otherwise.

#### `TUI_ToggleButton%%`

```vb
FUNCTION TUI_ToggleButton%% (x AS LONG, y AS LONG, w AS LONG, text AS STRING, isToggled AS _BYTE)
```

- **Description**: Renders an interactive 3-line tall VB-DOS style 3D toggle
  button with raised / sunken visual states and directional lighting (no drop
  shadows). Displays sunken in green when `isToggled` is true without shifting
  interior label text. When pressed and held, it visibly depresses. The currently
  focused button is rendered with a double-line border, while non-focused
  buttons use a single-line border.
- **Parameters**:
  - `x`: 1-based character column coordinate of top-left corner.
  - `y`: 1-based character row coordinate of top-left corner.
  - `w`: Total width in characters including borders.
  - `text`: Display label string.
  - `isToggled`: `_TRUE` if active / sunken, `_FALSE` if raised.
- **Returns**: `_TRUE` if clicked/triggered to toggle state; `_FALSE` otherwise.

#### `TUI_ChannelBadge%%`

```vb
FUNCTION TUI_ChannelBadge%% (x AS LONG, y AS LONG, ch AS LONG, _
    badgeText AS STRING, isMuted AS _BYTE, isSoloed AS _BYTE, outAction AS _BYTE)
```

- **Description**: Renders an interactive tracker channel badge with live Mute
  (`[MUT]`) and Solo (`[SLO]`) indicators.
- **Parameters**:
  - `x`: Character column coordinate.
  - `y`: Character row coordinate.
  - `ch`: Channel index (0-based).
  - `badgeText`: Subtype text (e.g. `"PCM"`, `"AM "`, `"FMm"`, `"FMd"`).
  - `isMuted`: `_TRUE` if channel is muted.
  - `isSoloed`: `_TRUE` if channel is soloed.
  - `outAction`: Output parameter set to `TUI_CHANNEL_ACTION_MUTE` or
    `TUI_CHANNEL_ACTION_SOLO`.
- **Returns**: `_TRUE` if an action was triggered; `_FALSE` otherwise.

#### `TUI_ProgressBar&`

```vb
FUNCTION TUI_ProgressBar& (x AS LONG, y AS LONG, w AS LONG, curVal AS LONG, maxVal AS LONG)
```

- **Description**: Renders an interactive progress / seek bar. Supports real-time
  scrubbing with an ~80 ms rate-limiting cool-off interval to prevent rapid order
  jumping.
- **Parameters**:
  - `x`: Character column coordinate.
  - `y`: Character row coordinate.
  - `w`: Total width in characters including bracket delimiters.
  - `curVal`: Current numeric value.
  - `maxVal`: Maximum value.
- **Returns**: Target position index if clicked, dragged, or nudged; or `-1` if
  no interaction occurred.

#### `TUI_Slider!`

```vb
FUNCTION TUI_Slider! (x AS LONG, y AS LONG, w AS LONG, curVal AS SINGLE, _
    minVal AS SINGLE, maxVal AS SINGLE, label AS STRING)
```

- **Description**: Renders an interactive floating-point slider bar with
  percentage readout.
- **Parameters**:
  - `x`: Character column coordinate.
  - `y`: Character row coordinate.
  - `w`: Slider bar character width.
  - `curVal`: Current value.
  - `minVal`: Minimum value boundary.
  - `maxVal`: Maximum value boundary.
  - `label`: Label prefix string (e.g. `"VOL"`).
- **Returns**: Updated single-precision value if adjusted; or `curVal` if
  unadjusted.

#### `TUI_Label`

```vb
SUB TUI_Label (x AS LONG, y AS LONG, text AS STRING, fgColor AS LONG, bgColor AS LONG)
```

- **Description**: Renders a non-interactive styled text label at the specified
  character coordinates.
- **Parameters**:
  - `x`: Character column coordinate.
  - `y`: Character row coordinate.
  - `text`: Text string.
  - `fgColor`: Foreground color index (`TUI_COLOR_*`).
  - `bgColor`: Background color index (`TUI_COLOR_*`).

#### `TUI_PanelEx`

```vb
SUB TUI_PanelEx (x AS LONG, y AS LONG, w AS LONG, h AS LONG, title AS STRING, isDoubleBorder AS _BYTE, isOpaque AS _BYTE)
```

- **Description**: Renders a beveled container panel frame with an optional title string embedded into the top border, supporting double/single border styling and selectable opacity.
- **Parameters**:
  - `x`: Column coordinate of the top-left corner.
  - `y`: Row coordinate of the top-left corner.
  - `w`: Width in characters.
  - `h`: Height in characters.
  - `title`: Header caption displayed in the top border.
  - `isDoubleBorder`: Nonzero for double-line border style, zero for single-line style.
  - `isOpaque`: Nonzero to clear interior with background color spaces (opaque), zero to leave interior transparent.

#### `TUI_Panel`

```vb
SUB TUI_Panel (x AS LONG, y AS LONG, w AS LONG, h AS LONG, title AS STRING, isDoubleBorder AS _BYTE)
```

- **Description**: Renders an opaque beveled container panel frame with an optional title string embedded into the top border (calls `TUI_PanelEx` with `isOpaque = _TRUE`).
- **Parameters**:
  - `x`: Column coordinate of the top-left corner.
  - `y`: Row coordinate of the top-left corner.
  - `w`: Width in characters.
  - `h`: Height in characters.
  - `title`: Header caption displayed in the top border.
  - `isDoubleBorder`: Nonzero for double-line border style, zero for single-line style.

#### `TUI_TabBar%%`

```vb
FUNCTION TUI_TabBar%% (x AS LONG, y AS LONG, tabCaptions() AS STRING, tabCount AS LONG, selectedIdx AS LONG)
```

- **Description**: Renders a horizontal bar of tabs. Clicking or triggering an inactive tab updates `selectedIdx` and returns `_TRUE`.
- **Parameters**:
  - `x`: Column coordinate of the start of the tab bar.
  - `y`: Row coordinate.
  - `tabCaptions()`: Array of tab caption strings.
  - `tabCount`: Total number of tabs in the array.
  - `selectedIdx`: In/Out 1-based index of the currently active tab.
- **Return Value**: `_TRUE` if tab selection changed this frame, `_FALSE` otherwise.

#### `TUI_VUMeter`

```vb
SUB TUI_VUMeter (x AS LONG, y AS LONG, h AS LONG, level AS SINGLE, peak AS SINGLE, isMuted AS _BYTE)
```

- **Description**: Renders a vertical 1-column VU meter with 3-color graduation (green, yellow, red), peak hold indicator, and muted state support.
- **Parameters**:
  - `x`: Column coordinate.
  - `y`: Top row coordinate.
  - `h`: Height in character rows.
  - `level`: Normalized volume level (0.0 to 1.0).
  - `peak`: Normalized peak volume level (0.0 to 1.0).
  - `isMuted`: Nonzero to render in muted gray tone.

#### `TUI_ScrollList&`

```vb
FUNCTION TUI_ScrollList& (x AS LONG, y AS LONG, w AS LONG, h AS LONG, items() AS STRING, totalItems AS LONG, selectedIdx AS LONG, scrollOffset AS LONG)
```

- **Description**: Renders a scrollable selection list with item hover, click selection, scrollbar track, thumb, and mouse wheel navigation.
- **Parameters**:
  - `x`: Column coordinate of the top-left corner.
  - `y`: Row coordinate of the top-left corner.
  - `w`: Total list width in characters.
  - `h`: Total visible line height.
  - `items()`: Array of item strings.
  - `totalItems`: Valid item count in the array.
  - `selectedIdx`: In/Out 1-based index of currently selected item.
  - `scrollOffset`: In/Out 1-based index of top visible item.
- **Return Value**: 1-based index of item clicked this frame, or 0 if none.

---

## Playlist Management API (`Playlist.bi`)

Include header:

```vb
'$INCLUDE:'source/Playlist.bi'
```

### Playlist Constants

```vb
CONST PLAYLIST_REPEAT_NONE%% = 0%%
CONST PLAYLIST_REPEAT_ALL%% = 1%%
CONST PLAYLIST_REPEAT_ONE%% = 2%%
```

### Playlist Types

#### `PlaylistEntry`

```vb
TYPE PlaylistEntry
    filePath AS STRING
    title AS STRING
    duration AS DOUBLE
END TYPE
```

#### `Playlist`

```vb
TYPE Playlist
    _DYNAMIC entries(0 TO 0) AS PlaylistEntry
    count AS LONG
    currentIndex AS LONG
    isShuffle AS _BYTE
    repeatMode AS _BYTE
    _DYNAMIC shuffleOrder(0 TO 0) AS LONG
    shufflePos AS LONG
END TYPE
```

### Playlist Queue Management and Navigation

#### `Playlist_Initialize` / `Playlist_Clear`

```vb
SUB Playlist_Initialize (pl AS Playlist)
SUB Playlist_Clear (pl AS Playlist)
```

- **Description**: Resets or clears a playlist structure to empty state.

#### `Playlist_Add`

```vb
FUNCTION Playlist_Add%% (pl AS Playlist, filePath AS STRING, title AS STRING, duration AS DOUBLE)
SUB Playlist_Add (pl AS Playlist, filePath AS STRING, title AS STRING, duration AS DOUBLE)
```

- **Description**: Appends a file to the playlist queue. If `title` is empty, the file name is automatically extracted.

#### `Playlist_Remove`

```vb
FUNCTION Playlist_Remove%% (pl AS Playlist, index AS LONG)
SUB Playlist_Remove (pl AS Playlist, index AS LONG)
```

- **Description**: Removes an entry by 1-based index and shifts remaining entries.

#### `Playlist_Shuffle` / `Playlist_SetShuffle`

```vb
SUB Playlist_Shuffle (pl AS Playlist)
SUB Playlist_SetShuffle (pl AS Playlist, enable AS _BYTE)
```

- **Description**: Generates a Fisher-Yates randomized permutation of playlist entries for non-repeating shuffle playback.

#### `Playlist_SetRepeatMode`

```vb
SUB Playlist_SetRepeatMode (pl AS Playlist, mode AS _BYTE)
```

- **Description**: Sets repeat behavior (`PLAYLIST_REPEAT_NONE`, `PLAYLIST_REPEAT_ALL`, or `PLAYLIST_REPEAT_ONE`).

#### `Playlist_GetNext&` / `Playlist_GetPrevious&`

```vb
FUNCTION Playlist_GetNext& (pl AS Playlist)
FUNCTION Playlist_GetPrevious& (pl AS Playlist)
```

- **Description**: Advances or retreats through the queue according to shuffle and repeat modes. Returns 0 when the end of a non-repeating playlist is reached.

### Playlist M3U File I/O

#### `Playlist_LoadM3U`

```vb
FUNCTION Playlist_LoadM3U%% (pl AS Playlist, m3uFilePath AS STRING)
SUB Playlist_LoadM3U (pl AS Playlist, m3uFilePath AS STRING)
```

- **Description**: Loads entries and `#EXTINF` metadata from an `.m3u` or `.m3u8` playlist file.

#### `Playlist_SaveM3U`

```vb
FUNCTION Playlist_SaveM3U%% (pl AS Playlist, m3uFilePath AS STRING)
SUB Playlist_SaveM3U (pl AS Playlist, m3uFilePath AS STRING)
```

- **Description**: Exports the current playlist queue and metadata to an `.m3u` file.

---

## Background Visual Animation API (`Background.bi`)

Include header:

```vb
'$INCLUDE:'Background.bi'
```

Provides retro visual animation effects for the player workstation during idle playback or ambient mode. Supports 7 distinct background modes: 3D Starfield Warp, Kinetic Bouncing Snakes, Launching Fireworks, Retro Cellular Fire, Demoscene Plasma, Bouncing Kinetic Balls, and Digital Matrix Rain.

### Background Constants and Modes

```vb
CONST BACKGROUND_MODE_NONE& = 0&
CONST BACKGROUND_MODE_STARS& = 1&
CONST BACKGROUND_MODE_SNAKES& = 2&
CONST BACKGROUND_MODE_FIREWORKS& = 3&
CONST BACKGROUND_MODE_FIRE& = 4&
CONST BACKGROUND_MODE_PLASMA& = 5&
CONST BACKGROUND_MODE_BALLS& = 6&
CONST BACKGROUND_MODE_MATRIX& = 7&
CONST BACKGROUND_MODE_FIRST& = BACKGROUND_MODE_STARS
CONST BACKGROUND_MODE_LAST& = BACKGROUND_MODE_MATRIX
```

### Background Types

#### `Background`

Unified context encapsulating all background visual simulation states:

- `starfield`: Star positions, angles, velocities, and 3D depth buffers.
- `snakes`: Kinetic snake positions, turn rates, velocities, and occupancy grid.
- `fireworks`: Rocket trajectory, explosion spark particles, and gravity simulation.
- `fire`: Cellular automata heat grid with upward propagation and cooling decay.
- `plasma`: Fast 512-entry precomputed sine LUT and multi-frequency wave phase ticks.
- `balls`: Kinetic bouncing balls with gravity, wall rebounds, and elastic ball-to-ball collisions.
- `matrix`: Falling code stream columns with glowing leading heads, green trails, and character mutation.
- `mode`: Active `BACKGROUND_MODE_*` constant.
- `size`: Vector2f screen dimensions in characters.

### Background Lifecycle and Rendering

#### `Background_InitializeEx`

```vb
SUB Background_InitializeEx (ctx AS Background, viewport AS Bounds2f)
```

- **Description**: Allocates and initializes all 7 background effect engines constrained within the specified rectangular `viewport` bounding box. Calculates width and height, sets up all simulation grids/buffers, and selects an initial random background mode.

#### `Background_Initialize`

```vb
SUB Background_Initialize (ctx AS Background)
```

- **Description**: Simplified initializer that defaults the viewport to full-screen bounds `(0, 0) - (_WIDTH, _HEIGHT)` and delegates to `Background_InitializeEx`. Selects an initial random background mode.

#### `Background_UpdateAndDraw`

```vb
SUB Background_UpdateAndDraw (ctx AS Background)
```

- **Description**: Advances the simulation state of the currently active background mode by one frame and renders it directly to the active screen buffer.

### Background Mode Control and Queries

#### `Background_SetRandomMode`

```vb
SUB Background_SetRandomMode (ctx AS Background)
```

- **Description**: Randomly selects an active background mode from the 7 available modes (`BACKGROUND_MODE_FIRST` to `BACKGROUND_MODE_LAST`).

#### `Background_CycleMode`

```vb
SUB Background_CycleMode (ctx AS Background)
```

- **Description**: Advances to the next sequential background effect mode, wrapping around from `BACKGROUND_MODE_LAST` back to `BACKGROUND_MODE_FIRST`. Typically bound to hotkey `B`.

#### `Background_GetModeName$`

```vb
FUNCTION Background_GetModeName$ (mode AS LONG)
```

- **Description**: Returns the human-readable display name for the given mode ID (`"Starfield"`, `"Kinetic Snakes"`, `"Fireworks"`, `"Retro Fire"`, `"Demoscene Plasma"`, `"Bouncing Balls"`, `"Digital Matrix Rain"`).
