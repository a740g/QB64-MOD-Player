//----------------------------------------------------------------------------------------------------------------------
// Simple floating-point stereo PCM software synthesizer
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#define _USE_MATH_DEFINES

#include "../Core/Types.h"
#include "../Debug/Debug.h"
#include "../Math/Math.h"
#include <cstdint>
#include <memory>
#include <utility>
#include <vector>

struct SoftSynth {
    static constexpr auto VOLUME_MIN = 0.0f; // minimum volume
    static constexpr auto VOLUME_MAX = 1.0f; // maximum volume

    struct Voice {
        static const auto NO_SOUND = -1; // used to unbind a sound from a voice
        static constexpr auto MULTIPLIER_32_TO_16 = 32768.0f;
        static constexpr auto MULTIPLIER_32_TO_8 = 128.0f;
        static constexpr auto MULTIPLIER_16_TO_32 = 1.0f / MULTIPLIER_32_TO_16;
        static constexpr auto MULTIPLIER_8_TO_32 = 1.0f / MULTIPLIER_32_TO_8;
        static constexpr auto PAN_LEFT = -1.0f;                  // left-most pan position
        static constexpr auto PAN_RIGHT = 1.0f;                  // right-most pan position
        static constexpr auto PAN_CENTER = PAN_LEFT + PAN_RIGHT; // center pan position

        /// @brief Various playing modes
        enum PlayMode {
            FORWARD = 0,  // single-shot forward playback
            FORWARD_LOOP, // forward-looping playback
        };

        int32_t sound;                // the Sound to be mixed. This is set to -1 once the mixer is done with the Sound
        uint32_t frequency;           // the frequency of the sound
        float pitch;                  // the mixer uses this to step through the sound frames correctly
        float volume;                 // voice volume (0.0 - 1.0)
        float panPosition;            // stereo pan setting for (-1.0f - 0.0f - 1.0f)
        std::pair<float, float> gain; // left and right gain (calculated from panPosition)
        float position;               // sample frame position in the sound buffer
        uint32_t iPosition;           // sample frame position without the factional value
        uint32_t startPosition;       // this can be loop start or just start depending on play mode (in frames!)
        uint32_t endPosition;         // this can be loop end or just end depending on play mode (in frames!)
        int32_t mode;                 // how should the sound be played?
        float frame;                  // current frame
        float oldFrame;               // the previous frame

        /// @brief Initialized the voice (including pan position)
        Voice() {
            Reset();
            SetPanPosition(PAN_CENTER); // center the voice only when creating it the first time
        }

        /// @brief Resets the voice to defaults. Balance is intentionally left out so that we do not reset pan positions set by the user
        void Reset() {
            sound = NO_SOUND;
            volume = VOLUME_MAX;
            frequency = iPosition = startPosition = endPosition = 0;
            position = pitch = frame = oldFrame = 0.0f;
            mode = PlayMode::FORWARD;
        }

        void SetPanPosition(float value) {
            static constexpr auto QUARTER_PI = float(M_PI) / 4.0f;

            panPosition = std::clamp(value, PAN_LEFT, PAN_RIGHT); // clamp the value

            // Calculate the left and right channel gain values using pan law (-3.0dB pan depth)
            auto panMapped = (panPosition + 1.0f) * QUARTER_PI;
            gain.first = std::cos(panMapped);
            gain.second = std::sin(panMapped);
        }
    };

    std::vector<std::vector<float>> sounds; // managed sounds
    std::vector<Voice> voices;              // managed voices
    uint32_t sampleRate;                    // the mixer sampling rate
    uint32_t activeVoices;                  // active voices
    float volume;                           // global volume (0.0 - 1.0)
};

static std::unique_ptr<SoftSynth> g_SoftSynth; // global softynth object

static inline constexpr bool SoftSynth_IsChannelsValid(uint8_t channels) {
    return channels >= 1;
}

static inline constexpr bool SoftSynth_IsBytesPerSampleValid(uint8_t bytesPerSample) {
    return bytesPerSample == sizeof(int8_t) or bytesPerSample == sizeof(int16_t) or bytesPerSample == sizeof(float);
}

inline constexpr uint32_t SoftSynth_BytesToFrames(uint32_t bytes, uint8_t bytesPerSample, uint8_t channels) {
    return bytes / ((uint32_t)bytesPerSample * (uint32_t)channels);
}

/// @brief Initializes the SoftSynth object
/// @param sampleRate This should ideally be the device sampling rate
inline qb_bool __SoftSynth_Initialize(uint32_t sampleRate) {
    if (g_SoftSynth) {
        return QB_TRUE;
    }

    if (!sampleRate) {
        return QB_FALSE;
    }

    g_SoftSynth = std::make_unique<SoftSynth>();
    if (!g_SoftSynth) {
        return QB_FALSE;
    }

    g_SoftSynth->sampleRate = sampleRate;
    g_SoftSynth->activeVoices = 0;
    g_SoftSynth->volume = 1.0f;

    return QB_TRUE;
}

inline void __SoftSynth_Finalize() {
    g_SoftSynth.reset();
}

inline qb_bool SoftSynth_IsInitialized() {
    return TO_QB_BOOL(g_SoftSynth != nullptr);
}

uint32_t SoftSynth_GetSampleRate() {
    if (!g_SoftSynth) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_SoftSynth->sampleRate;
}

uint32_t SoftSynth_GetTotalSounds() {
    if (!g_SoftSynth) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return (uint32_t)g_SoftSynth->sounds.size();
}

uint32_t SoftSynth_GetTotalVoices() {
    if (!g_SoftSynth) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return (uint32_t)g_SoftSynth->voices.size();
}

void SoftSynth_SetTotalVoices(uint32_t voices) {
    if (!g_SoftSynth or voices < 1) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices.clear();
    g_SoftSynth->voices.resize(voices);
}

uint32_t SoftSynth_GetActiveVoices() {
    if (!g_SoftSynth) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_SoftSynth->activeVoices;
}

float SoftSynth_GetGlobalVolume() {
    if (!g_SoftSynth) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->volume;
}

void SoftSynth_SetGlobalVolume(float volume) {
    if (!g_SoftSynth) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->volume = std::clamp(volume, SoftSynth::VOLUME_MIN, SoftSynth::VOLUME_MAX);
}

/// @brief Copies and prepares the sound data in memory. Multi-channel sounds are flattened to mono.
/// All sample types are converted to 32-bit floating point. All integer based samples passed must be signed.
/// @param sound The sound slot / index
/// @param source A pointer to the raw sound data
/// @param bytes The size of the raw sound in bytes
/// @param bytesPerSample The bytes / samples (this can be 1 for 8-bit, 2 for 16-bit or 3 for 32-bit)
/// @param channels The number of channels (this must be 1 or more)
inline void __SoftSynth_LoadSound(int32_t sound, const char *const source, uint32_t bytes, uint8_t bytesPerSample, uint8_t channels) {
    if (!g_SoftSynth or sound < 0 or !source or !SoftSynth_IsBytesPerSampleValid(bytesPerSample) or !SoftSynth_IsChannelsValid(channels)) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    // Resize the vector to fit the number of sounds if needed
    if (sound >= g_SoftSynth->sounds.size()) {
        g_SoftSynth->sounds.resize(sound + 1);
    }

    auto frames = SoftSynth_BytesToFrames(bytes, bytesPerSample, channels);
    auto &data = g_SoftSynth->sounds[sound];

    data.clear(); // resize to zero frames

    if (!frames)
        return; // no need to proceed if we have no frames to load

    data.resize(frames); // resize the buffer

    switch (bytesPerSample) {
    case sizeof(int8_t): {
        auto src = reinterpret_cast<const int8_t *>(source);
        for (size_t i = 0; i < frames; i++) {
            // Flatten all channels to mono
            for (auto j = 0; j < channels; j++) {
                data[i] = std::fma(float(*src), SoftSynth::Voice::MULTIPLIER_8_TO_32, data[i]);
                ++src;
            }
        }
    } break;

    case sizeof(int16_t): {
        auto src = reinterpret_cast<const int16_t *>(source);
        for (size_t i = 0; i < frames; i++) {
            // Flatten all channels to mono
            for (auto j = 0; j < channels; j++) {
                data[i] = std::fma(float(*src), SoftSynth::Voice::MULTIPLIER_16_TO_32, data[i]);
                ++src;
            }
        }
    } break;

    case sizeof(float): {
        auto src = reinterpret_cast<const float *>(source);
        for (size_t i = 0; i < frames; i++) {
            // Flatten all channels to mono
            for (auto j = 0; j < channels; j++) {
                data[i] += *src;
                ++src;
            }
        }
    } break;

    default:
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
    }
}

/// @brief Gets a raw sound frame (in fp32 format)
/// @param sound The sound slot / index
/// @param position The frame position
/// @return A floating point sample frame
float SoftSynth_PeekSoundFrameSingle(int32_t sound, uint32_t position) {
    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->sounds[sound][position];
}

/// @brief Sets a raw sound frame (in fp32 format)
/// @param sound The sound slot / index
/// @param position The frame position
/// @param frame A floating point sample frame
void SoftSynth_PokeSoundFrameSingle(int32_t sound, uint32_t position, float frame) {
    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->sounds[sound][position] = frame;
}

inline int16_t SoftSynth_PeekSoundFrameInteger(int32_t sound, uint32_t position) {
    return SoftSynth_PeekSoundFrameSingle(sound, position) * SoftSynth::Voice::MULTIPLIER_32_TO_16;
}

inline void SoftSynth_PokeSoundFrameInteger(int32_t sound, uint32_t position, int16_t frame) {
    SoftSynth_PokeSoundFrameSingle(sound, position, SoftSynth::Voice::MULTIPLIER_16_TO_32 * frame);
}

inline int8_t SoftSynth_PeekSoundFrameByte(int32_t sound, uint32_t position) {
    return SoftSynth_PeekSoundFrameSingle(sound, position) * SoftSynth::Voice::MULTIPLIER_32_TO_8;
}

inline void SoftSynth_PokeSoundFrameByte(int32_t sound, uint32_t position, int8_t frame) {
    SoftSynth_PokeSoundFrameSingle(sound, position, SoftSynth::Voice::MULTIPLIER_8_TO_32 * frame);
}

float SoftSynth_GetVoiceVolume(uint32_t voice) {
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->voices[voice].volume;
}

void SoftSynth_SetVoiceVolume(uint32_t voice, float volume) {
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].volume = std::clamp(volume, SoftSynth::VOLUME_MIN, SoftSynth::VOLUME_MAX);
}

float SoftSynth_GetVoiceBalance(uint32_t voice) {
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->voices[voice].panPosition;
}

void SoftSynth_SetVoiceBalance(uint32_t voice, float balance) {
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].SetPanPosition(balance);
}

/// @brief Gets the voice frequency
/// @param voice The voice number to get the frequency for
/// @return The frequency value
uint32_t SoftSynth_GetVoiceFrequency(uint32_t voice) {
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->voices[voice].frequency;
}

/// @brief Sets the voice frequency
/// @param voice The voice number to set the frequency for
/// @param frequency The frequency to be set (must be > 0)
void SoftSynth_SetVoiceFrequency(uint32_t voice, uint32_t frequency) {
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size() or !frequency) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].frequency = frequency; // save this to avoid a division in GetVoiceFrequency()
    g_SoftSynth->voices[voice].pitch = (float)frequency / (float)g_SoftSynth->sampleRate;
}

void SoftSynth_StopVoice(uint32_t voice) {
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].Reset();
}

/// @brief Plays a sound using a voice
/// @param voice The voice to use to play the sound
/// @param sound The sound to play
/// @param position The position (in frames) in the sound where playback should start
/// @param mode The playback mode
/// @param start The playback start frame or loop start frame (based on playMode)
/// @param end The playback end frame or loop end frame (based on playMode)
void SoftSynth_PlayVoice(uint32_t voice, int32_t sound, uint32_t position, int32_t mode, uint32_t startPosition, uint32_t endPosition) {
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size() or sound < 0 or sound >= g_SoftSynth->sounds.size()) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].mode =
        mode < SoftSynth::Voice::PlayMode::FORWARD or mode > SoftSynth::Voice::PlayMode::FORWARD_LOOP ? SoftSynth::Voice::PlayMode::FORWARD : mode;
    g_SoftSynth->voices[voice].position = position;           // if this value is junk then the mixer should deal with it correctly
    g_SoftSynth->voices[voice].iPosition = position;          // if this value is junk then the mixer should deal with it correctly
    g_SoftSynth->voices[voice].startPosition = startPosition; // if this value is junk then the mixer should deal with it correctly
    g_SoftSynth->voices[voice].endPosition = endPosition;     // if this value is junk then the mixer should deal with it correctly
    g_SoftSynth->voices[voice].sound = sound;
    // These two need to be setup because both position are iPosition are the same when we start playback
    // Fetching the initial frame will help avoid clicks and pops
    g_SoftSynth->voices[voice].frame = position < g_SoftSynth->sounds[sound].size() ? g_SoftSynth->sounds[sound][position] : 0.0f;
    g_SoftSynth->voices[voice].oldFrame = g_SoftSynth->voices[voice].frame;
}

/// @brief This mixes and writes the mixed samples to "buffer"
/// @param buffer A buffer pointer that will receive the mixed samples (the buffer is not cleared before mixing)
/// @param frames The number of frames to mix
inline void __SoftSynth_Update(float *buffer, uint32_t frames) {
    if (!g_SoftSynth or !buffer or !frames) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    // Get the total voices we need to mix
    auto voiceCount = g_SoftSynth->voices.size();

    //  Set the active voice count to zero
    g_SoftSynth->activeVoices = 0;

    // We will iterate through each channel completely rather than jumping from channel to channel
    // We are doing this because it is easier for the CPU to access adjacent memory rather than something far away
    for (size_t v = 0; v < voiceCount; v++) {
        // Get the current voice we need to work with
        auto &voice = g_SoftSynth->voices[v];

        // Only proceed if we have a valid sound number (>= 0)
        if (voice.sound >= 0) {
            // Get the sample data we need to work with
            auto &soundData = g_SoftSynth->sounds[voice.sound];

            // Cache the total sound frames as we need to use this frequently inside the loop
            auto soundFrames = soundData.size();

            // Only proceed if we have something to play in the sound
            if (soundFrames > 0) {
                // Increment the active voices
                ++g_SoftSynth->activeVoices;

                // Copy the buffer address
                auto output = buffer;

                //  Next we go through the channel sample data and mix it to our mixer buffer
                for (uint32_t s = 0; s < frames; s++) {
                    // Check if we crossed the end of the sound and take action based on the playback mode
                    if (voice.position > voice.endPosition) {
                        if (SoftSynth::Voice::PlayMode::FORWARD_LOOP == voice.mode) {
                            // Reset loop position if we reached the end of the loop and preserve fractional position
                            voice.position = voice.startPosition + (voice.position - voice.endPosition);
                        } else {
                            // For non-looping sound simply stop playing if we reached the end
                            voice.sound = SoftSynth::Voice::NO_SOUND; // just invalidate the sound leaving other properties intact
                            break;                                    // exit the mixing loop as we have no more samples to mix for this channel
                        }
                    }

                    // Fetch the sample frame to mix
                    auto iPos = uint32_t(voice.position);
                    if (iPos != voice.iPosition) // only fetch a new frame if we have really crossed over to the new one
                    {
                        voice.oldFrame = voice.frame; // save the current frame first
                        voice.iPosition = iPos;       // save the new integer position

                        if (iPos < soundFrames) // this protects us from segfaults
                        {
                            voice.frame = soundData[iPos];
                        }
                    }

                    // Lerp & volume
                    auto outFrame = std::fma(voice.frame - voice.oldFrame, voice.position - voice.iPosition, voice.oldFrame) * voice.volume;

                    // Move to the next sample position based on the pitch
                    voice.position += voice.pitch;

                    // Mixing and panning
                    *output = std::fma(outFrame, voice.gain.first, *output); // left channel
                    ++output;
                    *output = std::fma(outFrame, voice.gain.second, *output); // right channel
                    ++output;
                }
            }
        }
    }

    // Make one more pass to apply global volume
    // TODO: Move this out to SoftSynth.bas so that we do the global volume only once after mixing FM, reverb and stuff
    // Or probably we can move this to it's own function that can mix several buffers in one go and apply global volume
    auto output = buffer;
    for (uint32_t s = 0; s < frames; s++) {
        *output *= g_SoftSynth->volume; // left channel
        ++output;
        *output *= g_SoftSynth->volume; // right channel
        ++output;
    }
}
