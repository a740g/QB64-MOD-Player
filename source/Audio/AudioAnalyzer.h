//----------------------------------------------------------------------------------------------------------------------
// FFT routines for audio spectrum analyzers
// Copyright (c) 2024 Samuel Gomes
// Copyright (c) 2004-2022 Stian Skjelstad
// Copyright (c) 1994-2005 Niklas Beisert
//
// This includes heavily modified code from Open Cubic Player:
// https://www.cubic.org/player/
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>

/// @brief FFT singleton class for audio spectrum analysis.
class AudioAnalyzerFFT {
  public:
    float DoFFT(uint16_t *amplitudeArray, const int16_t *sampleData, int sampleIncrement, int bitDepth) {
        const auto numSamples = std::min(1 << bitDepth, NUM_SAMPLES);
        const auto halfNumSamples = numSamples >> 1;
        auto averageIntensity = 0.0f;

        for (auto i = 0; i < numSamples; ++i) {
            auto sample = float(*sampleData) * S16_TO_F32_MULTIPLIER;
            fftBuffer[i][0] = int32_t(*sampleData) << 12;
            fftBuffer[i][1] = 0;
            averageIntensity += sample * sample;
            sampleData += sampleIncrement;
        }

        averageIntensity = averageIntensity / float(numSamples);

        PerformButterflyOperation(fftBuffer, bitDepth);

        for (auto i = 1; i <= halfNumSamples; ++i) {
            auto realPart = fftBuffer[bitReversalTable[i] >> (FFT_POWER - bitDepth)][0] >> 12;
            auto imagPart = fftBuffer[bitReversalTable[i] >> (FFT_POWER - bitDepth)][1] >> 12;
            amplitudeArray[i - 1] = uint16_t(std::sqrt((realPart * realPart + imagPart * imagPart) * i));
        }

        return averageIntensity;
    }

    float DoFFT(uint16_t *amplitudeArray, const float *sampleData, int sampleIncrement, int bitDepth) {
        const auto numSamples = std::min(1 << bitDepth, NUM_SAMPLES);
        const auto halfNumSamples = numSamples >> 1;
        auto averageIntensity = 0.0f;

        for (auto i = 0; i < numSamples; ++i) {
            auto sample = std::fmaxf(std::fminf(*sampleData, 1.0f), -1.0f);
            fftBuffer[i][0] = int32_t(sample * F32_TO_S16_MULTIPLIER) << 12;
            fftBuffer[i][1] = 0;
            averageIntensity += sample * sample;
            sampleData += sampleIncrement;
        }

        averageIntensity = averageIntensity / float(numSamples);

        PerformButterflyOperation(fftBuffer, bitDepth);

        for (auto i = 1; i <= halfNumSamples; ++i) {
            auto realPart = fftBuffer[bitReversalTable[i] >> (FFT_POWER - bitDepth)][0] >> 12;
            auto imagPart = fftBuffer[bitReversalTable[i] >> (FFT_POWER - bitDepth)][1] >> 12;
            amplitudeArray[i - 1] = uint16_t(std::sqrt((realPart * realPart + imagPart * imagPart) * i));
        }

        return averageIntensity;
    }

    static AudioAnalyzerFFT &Instance() {
        static AudioAnalyzerFFT instance;

        return instance;
    }

  private:
    static constexpr auto FFT_POWER = 11;
    static constexpr auto NUM_SAMPLES = 1 << FFT_POWER;
    static constexpr auto HALF_SAMPLES = NUM_SAMPLES >> 1;
    static constexpr auto QUARTER_SAMPLES = HALF_SAMPLES >> 1;
    static constexpr auto SCALE_FACTOR = 1 << 28;
    static constexpr auto S16_TO_F32_MULTIPLIER = 1.0f / 32768.0f;
    static constexpr auto F32_TO_S16_MULTIPLIER = 32767.0f;

    AudioAnalyzerFFT() {
        for (auto i = 0; i < QUARTER_SAMPLES; i++) {
            auto angle = (2.0 * M_PI * i) / (4.0 * QUARTER_SAMPLES);
            sinCosTable[i][0] = int32_t(std::cos(angle) * SCALE_FACTOR);
            sinCosTable[i][1] = int32_t(std::sin(angle) * SCALE_FACTOR);
        }

        auto reversedIndex = 0;
        auto step = 0;

        for (auto i = 0; i < NUM_SAMPLES; ++i) {
            bitReversalTable[i] = reversedIndex;
            for (step = HALF_SAMPLES; step && (step <= reversedIndex); step >>= 1)
                reversedIndex -= step;
            reversedIndex += step;
        }

        for (auto i = HALF_SAMPLES / 4 + 1; i <= HALF_SAMPLES / 2; ++i) {
            sinCosTable[i][0] = sinCosTable[HALF_SAMPLES / 2 - i][1];
            sinCosTable[i][1] = sinCosTable[HALF_SAMPLES / 2 - i][0];
        }

        for (auto i = HALF_SAMPLES / 2 + 1; i < HALF_SAMPLES; ++i) {
            sinCosTable[i][0] = -sinCosTable[HALF_SAMPLES - i][0];
            sinCosTable[i][1] = sinCosTable[HALF_SAMPLES - i][1];
        }
    }

    ~AudioAnalyzerFFT() = default;
    AudioAnalyzerFFT(const AudioAnalyzerFFT &) = delete;
    AudioAnalyzerFFT &operator=(const AudioAnalyzerFFT &) = delete;

    static inline constexpr int32_t MultiplyShift29(int32_t a, int32_t b) {
        return int32_t((int64_t(a) * int64_t(b)) >> 29);
    }

    static void CalculateFFT(int32_t *currentSample, int32_t *currentSinCos, uint32_t distance) {
        auto realPart = currentSample[0] - currentSample[distance + 0];
        currentSample[0] = (currentSample[0] + currentSample[distance + 0]) >> 1;

        auto imagPart = currentSample[1] - currentSample[distance + 1];
        currentSample[1] = (currentSample[1] + currentSample[distance + 1]) >> 1;

        currentSample[distance + 0] = MultiplyShift29(realPart, currentSinCos[0]) - MultiplyShift29(imagPart, currentSinCos[1]);
        currentSample[distance + 1] = MultiplyShift29(realPart, currentSinCos[1]) + MultiplyShift29(imagPart, currentSinCos[0]);
    }

    static void PerformButterflyOperation(int32_t (*data)[2], int stage) {
        auto lastStageData = data[1 << stage];
        int32_t currentSinCos[2];
        int32_t *currentSample;

        for (auto i = FFT_POWER - stage; i < FFT_POWER; ++i) {
            const auto stepSize = HALF_SAMPLES >> i;
            const auto distance = 2 * stepSize;

            for (auto j = 0; j < stepSize; ++j) {
                currentSinCos[0] = sinCosTable[j << i][0];
                currentSinCos[1] = sinCosTable[j << i][1];

                for (currentSample = data[j]; currentSample < lastStageData; currentSample += 2 * distance)
                    CalculateFFT(currentSample, currentSinCos, distance);
            }
        }
    }

    // Declare and define these inside the class.
    static inline uint16_t bitReversalTable[NUM_SAMPLES];
    static inline int32_t sinCosTable[HALF_SAMPLES][2];
    static inline int32_t fftBuffer[NUM_SAMPLES][2];
};

/// @brief FFT for 16-bit integer samples. This computes the amplitude spectrum for the positive frequencies only.
/// @param amplitudeArray The array where the resulting FFT amplitude data is stored.
/// @param sampleData An array of 16-bit samples.
/// @param sampleIncrement The number to use to get to the next sample in sampleData. For stereo interleaved samples use 2, else 1.
/// @param bitDepth The bit depth representing the number of samples. So if bitDepth = 9, then samples = 1 << 9 or 512.
/// @return Returns the average intensity level of the audio signal.
float AudioAnalyzerFFT_DoInteger(uint16_t *amplitudeArray, const int16_t *sampleData, int sampleIncrement, int bitDepth) {
    return AudioAnalyzerFFT::Instance().DoFFT(amplitudeArray, sampleData, sampleIncrement, bitDepth);
}

/// @brief FFT for floating-point samples. This computes the amplitude spectrum for the positive frequencies only.
/// @param amplitudeArray The array where the resulting FFT amplitude data is stored.
/// @param sampleData An array of floating-point (FP32) samples.
/// @param sampleIncrement The number to use to get to the next sample in sampleData. For stereo interleaved samples use 2, else 1.
/// @param bitDepth The bit depth representing the number of samples. So if bitDepth = 9, then samples = 1 << 9 or 512.
/// @return Returns the average intensity level of the audio signal.
float AudioAnalyzerFFT_DoSingle(uint16_t *amplitudeArray, const float *sampleData, int sampleIncrement, int bitDepth) {
    return AudioAnalyzerFFT::Instance().DoFFT(amplitudeArray, sampleData, sampleIncrement, bitDepth);
}
