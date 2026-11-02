//----------------------------------------------------------------------------------------------------------------------
// Simple audio conversion and resampling library
// Copyright (c) 2024 Samuel Gomes
//
// This includes heavily modified code from the following projects:
// https://github.com/cpuimage/resampler
// https://github.com/deftio/companders
// https://github.com/dystopiancode/pcm-g711
// https://web.archive.org/web/20120415044546/http://hazelware.luggle.com/tutorials/mulawcompression.html
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>
#include <cstdlib>

static const auto AUDIOCONV_S8_TO_F32_MULTIPLER = 1.0f / 128.0f;
static const auto AUDIOCONV_S16_TO_F32_MULTIPLER = 1.0f / 32768.0f;
static const auto AUDIOCONV_S32_TO_F32_MULTIPLER = 1.0f / 2147483648.0f;
static const auto AUDIOCONV_F32_TO_S8_MULTIPLIER = 127.0f;
static const auto AUDIOCONV_F32_TO_S16_MULTIPLIER = 32767.0f;
static const auto AUDIOCONV_F32_TO_S32_MULTIPLIER = 2147483647.0f;

/// @brief Converts unsigned 8-bit audio samples to signed 8-bit inplace.
/// @param source The input unsigned 8-bit sample frame buffer.
/// @param samples The number of samples in the sample frame buffer, where samples = frames * channels.
void AudioConv_ConvertU8ToS8(uintptr_t source, uint32_t samples) {
    if (!source or !samples)
        return;

    auto buffer = reinterpret_cast<uint8_t *>(source);

    for (size_t i = 0; i < samples; i++)
        buffer[i] ^= 0x80; // xor_eq
}

/// @brief Converts unsigned 16-bit audio samples to signed 16-bit inplace.
/// @param source The input unsigned 16-bit sample frame buffer.
/// @param samples The number of samples in the sample frame buffer, where samples = frames * channels.
void AudioConv_ConvertU16ToS16(uintptr_t source, uint32_t samples) {
    if (!source or !samples)
        return;

    auto buffer = reinterpret_cast<uint16_t *>(source);

    for (size_t i = 0; i < samples; i++)
        buffer[i] ^= 0x8000; // xor_eq
}

/// @brief Converts unsigned 8-bit audio samples to floating point.
/// @param src The input unsigned 8-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output floating point sample frame buffer. The buffer size must be at least samples * sizeof(float) bytes.
void AudioConv_ConvertU8ToF32(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const uint8_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = float(int8_t(srcBuffer[i] ^ 0x80)) * AUDIOCONV_S8_TO_F32_MULTIPLER;
}

/// @brief Converts signed 8-bit audio samples to floating point.
/// @param src The input signed 8-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output floating point sample frame buffer. The buffer size must be at least samples * sizeof(float) bytes.
void AudioConv_ConvertS8ToF32(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = (float)srcBuffer[i] * AUDIOCONV_S8_TO_F32_MULTIPLER;
}

/// @brief Converts unsigned 8-bit audio samples to signed 16-bit.
/// @param src The input unsigned 8-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output signed 16-bit sample frame buffer. The buffer size must be at least samples * sizeof(int16_t) bytes.
void AudioConv_ConvertU8ToS16(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const uint8_t *>(src);
    auto dstBuffer = reinterpret_cast<int16_t *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = int8_t(srcBuffer[i] ^ 0x80) << 8;
}

/// @brief Converts signed 8-bit audio samples to signed 16-bit.
/// @param src The input signed 8-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output signed 16-bit sample frame buffer. The buffer size must be at least samples * sizeof(int16_t) bytes.
void AudioConv_ConvertS8ToS16(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<int16_t *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = srcBuffer[i] << 8;
}

/// @brief Converts signed 16-bit audio samples to floating point.
/// @param src The input signed 16-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output floating point sample frame buffer. The buffer size must be at least samples * sizeof(float) bytes.
void AudioConv_ConvertS16ToF32(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int16_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = (float)srcBuffer[i] * AUDIOCONV_S16_TO_F32_MULTIPLER;
}

/// @brief Converts signed 32-bit audio samples to floating point.
/// @param src The input signed 32-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output floating point sample frame buffer. The buffer size must be at least samples * sizeof(float) bytes.
void AudioConv_ConvertS32ToF32(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int32_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = (float)srcBuffer[i] * AUDIOCONV_S32_TO_F32_MULTIPLER;
}

/// @brief Decodes an 8-bit signed integer using the A-Law.
/// @param number The number that will be decoded.
/// @return The decoded number.
static inline int16_t __AudioConv_DecodeALawSample(int8_t aLawByte) {
    const static int16_t ALawDecompressTable[256] = {
        -5504,  -5248,  -6016,  -5760,  -4480,  -4224,  -4992,  -4736,  -7552,  -7296,  -8064,  -7808,  -6528,  -6272,  -7040,  -6784,  -2752,  -2624,  -3008,
        -2880,  -2240,  -2112,  -2496,  -2368,  -3776,  -3648,  -4032,  -3904,  -3264,  -3136,  -3520,  -3392,  -22016, -20992, -24064, -23040, -17920, -16896,
        -19968, -18944, -30208, -29184, -32256, -31232, -26112, -25088, -28160, -27136, -11008, -10496, -12032, -11520, -8960,  -8448,  -9984,  -9472,  -15104,
        -14592, -16128, -15616, -13056, -12544, -14080, -13568, -344,   -328,   -376,   -360,   -280,   -264,   -312,   -296,   -472,   -456,   -504,   -488,
        -408,   -392,   -440,   -424,   -88,    -72,    -120,   -104,   -24,    -8,     -56,    -40,    -216,   -200,   -248,   -232,   -152,   -136,   -184,
        -168,   -1376,  -1312,  -1504,  -1440,  -1120,  -1056,  -1248,  -1184,  -1888,  -1824,  -2016,  -1952,  -1632,  -1568,  -1760,  -1696,  -688,   -656,
        -752,   -720,   -560,   -528,   -624,   -592,   -944,   -912,   -1008,  -976,   -816,   -784,   -880,   -848,   5504,   5248,   6016,   5760,   4480,
        4224,   4992,   4736,   7552,   7296,   8064,   7808,   6528,   6272,   7040,   6784,   2752,   2624,   3008,   2880,   2240,   2112,   2496,   2368,
        3776,   3648,   4032,   3904,   3264,   3136,   3520,   3392,   22016,  20992,  24064,  23040,  17920,  16896,  19968,  18944,  30208,  29184,  32256,
        31232,  26112,  25088,  28160,  27136,  11008,  10496,  12032,  11520,  8960,   8448,   9984,   9472,   15104,  14592,  16128,  15616,  13056,  12544,
        14080,  13568,  344,    328,    376,    360,    280,    264,    312,    296,    472,    456,    504,    488,    408,    392,    440,    424,    88,
        72,     120,    104,    24,     8,      56,     40,     216,    200,    248,    232,    152,    136,    184,    168,    1376,   1312,   1504,   1440,
        1120,   1056,   1248,   1184,   1888,   1824,   2016,   1952,   1632,   1568,   1760,   1696,   688,    656,    752,    720,    560,    528,    624,
        592,    944,    912,    1008,   976,    816,    784,    880,    848};

    return ALawDecompressTable[uint8_t(aLawByte)];
}

/// @brief Converts A-Law encoded audio samples to signed 16-bit samples.
/// @param src Pointer to the A-Law encoded audio samples buffer.
/// @param samples Number of samples in the buffer, where samples = frames * channels.
/// @param dst Pointer to the buffer where the signed 16-bit samples will be stored. The buffer size must be at least samples * sizeof(int16_t) bytes.
void AudioConv_ConvertALawToS16(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<int16_t *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = __AudioConv_DecodeALawSample(srcBuffer[i]);
}

/// @brief Converts A-Law encoded audio samples to floating point samples.
/// @param src Pointer to the A-Law encoded audio samples buffer.
/// @param frames Number of samples in the buffer.
/// @param dst Pointer to the buffer where the floating point samples will be stored. The buffer size must be at least samples * sizeof(float) bytes.
void AudioConv_ConvertALawToF32(uintptr_t src, uint32_t frames, uintptr_t dst) {
    if (!src or !dst or !frames)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < frames; i++)
        dstBuffer[i] = (float)__AudioConv_DecodeALawSample(srcBuffer[i]) * AUDIOCONV_S16_TO_F32_MULTIPLER;
}

/// @brief Decodes an 8-bit signed integer using the mu-Law.
/// @param number The number that will be decoded.
/// @return The decoded number.
static inline int16_t __AudioConv_DecodeMuLawSample(int8_t uLawByte) {
    static const int16_t MuLawDecompressTable[256] = {
        -32124, -31100, -30076, -29052, -28028, -27004, -25980, -24956, -23932, -22908, -21884, -20860, -19836, -18812, -17788, -16764, -15996, -15484, -14972,
        -14460, -13948, -13436, -12924, -12412, -11900, -11388, -10876, -10364, -9852,  -9340,  -8828,  -8316,  -7932,  -7676,  -7420,  -7164,  -6908,  -6652,
        -6396,  -6140,  -5884,  -5628,  -5372,  -5116,  -4860,  -4604,  -4348,  -4092,  -3900,  -3772,  -3644,  -3516,  -3388,  -3260,  -3132,  -3004,  -2876,
        -2748,  -2620,  -2492,  -2364,  -2236,  -2108,  -1980,  -1884,  -1820,  -1756,  -1692,  -1628,  -1564,  -1500,  -1436,  -1372,  -1308,  -1244,  -1180,
        -1116,  -1052,  -988,   -924,   -876,   -844,   -812,   -780,   -748,   -716,   -684,   -652,   -620,   -588,   -556,   -524,   -492,   -460,   -428,
        -396,   -372,   -356,   -340,   -324,   -308,   -292,   -276,   -260,   -244,   -228,   -212,   -196,   -180,   -164,   -148,   -132,   -120,   -112,
        -104,   -96,    -88,    -80,    -72,    -64,    -56,    -48,    -40,    -32,    -24,    -16,    -8,     -1,     32124,  31100,  30076,  29052,  28028,
        27004,  25980,  24956,  23932,  22908,  21884,  20860,  19836,  18812,  17788,  16764,  15996,  15484,  14972,  14460,  13948,  13436,  12924,  12412,
        11900,  11388,  10876,  10364,  9852,   9340,   8828,   8316,   7932,   7676,   7420,   7164,   6908,   6652,   6396,   6140,   5884,   5628,   5372,
        5116,   4860,   4604,   4348,   4092,   3900,   3772,   3644,   3516,   3388,   3260,   3132,   3004,   2876,   2748,   2620,   2492,   2364,   2236,
        2108,   1980,   1884,   1820,   1756,   1692,   1628,   1564,   1500,   1436,   1372,   1308,   1244,   1180,   1116,   1052,   988,    924,    876,
        844,    812,    780,    748,    716,    684,    652,    620,    588,    556,    524,    492,    460,    428,    396,    372,    356,    340,    324,
        308,    292,    276,    260,    244,    228,    212,    196,    180,    164,    148,    132,    120,    112,    104,    96,     88,     80,     72,
        64,     56,     48,     40,     32,     24,     16,     8,      0};

    return MuLawDecompressTable[uint8_t(uLawByte)];
}

/// @brief Converts mu-Law encoded audio samples to signed 16-bit samples.
/// @param src Pointer to the mu-Law encoded audio samples buffer.
/// @param samples Number of samples in the buffer, where samples = frames * channels.
/// @param dst Pointer to the buffer where the signed 16-bit samples will be stored. The buffer size must be at least samples * sizeof(int16_t) bytes.
void AudioConv_ConvertMuLawToS16(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<int16_t *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = __AudioConv_DecodeMuLawSample(srcBuffer[i]);
}

/// @brief Converts mu-Law encoded audio samples to floating point samples.
/// @param src Pointer to the mu-Law encoded audio samples buffer.
/// @param samples Number of samples in the buffer.
/// @param dst Pointer to the buffer where the floating point samples will be stored. The buffer size must be at least samples * sizeof(float) bytes.
void AudioConv_ConvertMuLawToF32(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = (float)__AudioConv_DecodeMuLawSample(srcBuffer[i]) * AUDIOCONV_S16_TO_F32_MULTIPLER;
}

/// @brief Converts 4-bit ADPCM compressed audio samples to 8-bit signed samples.
/// @param src Pointer to the ADPCM compressed audio samples buffer.
/// @param srcLen The number of bytes in the input buffer.
/// @param compTab Pointer to the compression table used to decode the ADPCM codes.
/// @param dst Pointer to the buffer where the 8-bit signed samples will be stored. The buffer size must be at least srcLen * 2 bytes.
void AudioConv_ConvertADPCM4ToS8(uintptr_t src, uint32_t srcLen, const char *compTab, uintptr_t dst) {
    auto srcBuffer = reinterpret_cast<const uint8_t *>(src);
    auto dstBuffer = reinterpret_cast<int8_t *>(dst);

    int8_t delta = 0;

    for (size_t i = 0; i < srcLen; i++) {
        delta += compTab[*srcBuffer & 0x0F];
        *(dstBuffer++) = delta;
        delta += compTab[(*srcBuffer >> 4) & 0x0F];
        *(dstBuffer++) = delta;
        srcBuffer++;
    }
}

/// @brief Converts a dual mono audio buffer to a stereo interleaved audio buffer.
/// @tparam T Data type of the audio samples.
/// @param src Pointer to the dual mono audio buffer.
/// @param samples Number of samples in the buffer.
/// @param dst Pointer to the buffer where the stereo interleaved audio samples will be stored. The buffer size must be at least samples * sizeof(T) bytes.
template <typename T> void AudioConv_ConvertDualMonoToStereo(uintptr_t src, uint32_t samples, uintptr_t dst) {
    if (!src || !dst || samples < 4)
        return;

    auto srcBuffer = reinterpret_cast<const T *>(src);
    auto dstBuffer = reinterpret_cast<T *>(dst);

    uint32_t halfLength = samples >> 1;

    for (size_t i = 0, j = 0; i < halfLength; i++, j += 2) {
        dstBuffer[j] = srcBuffer[i];
        dstBuffer[j + 1] = srcBuffer[halfLength + i];
    }
}

// Specializations of AudioConv_ConvertDualMonoToStereoInterleaved() for different data types
#define AudioConv_ConvertDualMonoToStereoS8(_src_, _samples_, _dst_) AudioConv_ConvertDualMonoToStereo<int8_t>(_src_, _samples_, _dst_)
#define AudioConv_ConvertDualMonoToStereoS16(_src_, _samples_, _dst_) AudioConv_ConvertDualMonoToStereo<int16_t>(_src_, _samples_, _dst_)
#define AudioConv_ConvertDualMonoToStereoF32(_src_, _samples_, _dst_) AudioConv_ConvertDualMonoToStereo<float>(_src_, _samples_, _dst_)

/// @brief Resamples an audio buffer. Set output to NULL to get the output buffer size in samples frames.
/// @tparam T The sample data type.
/// @param src The input sample frame buffer.
/// @param dst The output sample frame buffer.
/// @param inSampleRate The input sample rate.
/// @param outSampleRate The output sample rate.
/// @param inputSize The number of samples frames in the input.
/// @param channels The number of channels for both input and output.
/// @return The number of samples frames written to the output.
template <typename T> uint64_t AudioConv_Resample(uintptr_t src, uintptr_t dst, int inSampleRate, int outSampleRate, uint64_t inputSize, uint32_t channels) {
    auto input = reinterpret_cast<const T *>(src);

    if (!input)
        return 0;

    auto outputSize = (uint64_t)(inputSize * (double)outSampleRate / (double)inSampleRate);
    outputSize -= outputSize % channels;

    auto output = reinterpret_cast<T *>(dst);

    if (!output)
        return outputSize;

    auto stepDist = ((double)inSampleRate / (double)outSampleRate);
    const uint64_t fixedFraction = (1LL << 32);
    const double normFixed = (1.0 / (1LL << 32));
    auto step = ((uint64_t)(stepDist * fixedFraction + 0.5));
    uint64_t curOffset = 0;

    for (uint32_t i = 0; i < outputSize; i += 1) {
        for (uint32_t c = 0; c < channels; c += 1) {
            *output++ =
                static_cast<T>(input[c] + (input[c + channels] - input[c]) * ((double)(curOffset >> 32) + ((curOffset & (fixedFraction - 1)) * normFixed)));
        }
        curOffset += step;
        input += (curOffset >> 32) * channels;
        curOffset &= (fixedFraction - 1);
    }

    return outputSize;
}

// Specializations of AudioConv_Resample() for different data types
#define AudioConv_ResampleS16(_src_, _dst_, _src_sample_rate_, _dst_sample_rate_, _src_size_, _channels_)                                                      \
    AudioConv_Resample<int16_t>(_src_, _dst_, _src_sample_rate_, _dst_sample_rate_, _src_size_, _channels_)
#define AudioConv_ResampleS32(_src_, _dst_, _src_sample_rate_, _dst_sample_rate_, _src_size_, _channels_)                                                      \
    AudioConv_Resample<int32_t>(_src_, _dst_, _src_sample_rate_, _dst_sample_rate_, _src_size_, _channels_)
#define AudioConv_ResampleF32(_src_, _dst_, _src_sample_rate_, _dst_sample_rate_, _src_size_, _channels_)                                                      \
    AudioConv_Resample<float>(_src_, _dst_, _src_sample_rate_, _dst_sample_rate_, _src_size_, _channels_)
