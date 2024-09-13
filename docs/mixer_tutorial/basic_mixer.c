/*
    A simple single-channel floating-point audio mixer.
    by Benedict Henshaw (2017/11)

    Usage:
        Call mix_audio() with a pointer to your audio buffer, the number of
        samples you want to be written into it, and the gain of your sound.

    Limitations:
        - Mono only.
        - Fixed number of sounds playing at once.
        - No master controls (volume, etc.).
        - Only 32-bit float sample format.
        - No consideration of multi-threading.
        - No consideration of memory management.
*/

// A channel holds everything we need to play some audio data.
typedef struct
{
    float *samples;   // The audio data itself.
    int sample_count; // Number of samples in the data.
    int sample_index; // Index of the next sample to be played.
    float gain;       // How loud to play the sound.
} Mixer_Channel;

// Our mixer has a maximum number of channels, which in turn means there is
// a maximum number of sounds we can play at once.
#define CHANNEL_COUNT 8
Mixer_Channel mixer_channels[CHANNEL_COUNT];

void mix_audio(void *stream, int samples_requested)
{
    // stream is a void* for convenience, but the data it points to should be
    // in 32-bit float format, so lets use a pointer of the correct type.
    float *samples = (float *)stream;
    // The main mixer loop that will write out each sample.
    for (int sample_index = 0; sample_index <= samples_requested; ++sample_index)
    {
        // The sample starts at zero; if nothing is playing there will be silence.
        float final_sample = 0.0f;
        // Mix the sample from each mixer channel into the our final_sample.
        for (int channel_index = 0; channel_index < CHANNEL_COUNT; ++channel_index)
        {
            // Skip the channel if it does not hold valid audio data.
            if (mixer_channels[channel_index].samples)
            {
                Mixer_Channel *channel = &mixer_channels[channel_index];
                if (channel->sample_index <= channel->sample_count)
                {
                    // We still have audio data left to play.
                    float new_sample = channel->samples[channel->sample_index];
                    // Adjust the sample by its gain.
                    new_sample *= channel->gain;
                    // Here is the mixing of the signals.
                    final_sample += new_sample;
                    // Move the channel to the next sample.
                    channel->sample_index += 1;
                }
                else
                {
                    // There's no audio data left in this channel, so clear it.
                    *channel = (Mixer_Channel){};
                }
            }
        }
        // Write our sample into the given audio stream.
        samples[sample_index] = final_sample;
    }
}

// To play some sound we can use this function to select an empty channel
// and fill it with our audio data.
// Returns the index of the channel holding the given sample data.
// Returns -1 if no free channel could be found.
int play_audio(void *samples, int sample_count, float gain)
{
    // Find the first empty channel and use that to play our sound.
    for (int i = 0; i < CHANNEL_COUNT; ++i)
    {
        if (mixer_channels[i].samples == NULL)
        {
            mixer_channels[i].samples = (float *)samples;
            mixer_channels[i].sample_count = sample_count;
            mixer_channels[i].sample_index = 0;
            mixer_channels[i].gain = gain;
            return i;
        }
    }
    return -1;
}
