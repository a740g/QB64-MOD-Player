/*
    A stereo floating-point audio mixer.
    by Benedict Henshaw (11/2017)

    Usage:
        Call mix_audio() with a pointer to your audio buffer, the number of
        samples you want to be written into it.

    New Features:
        - Stereo output.
        - Global gain control.
        - Sound looping.

    Limitations:
        - Only plays mono sources with panning.
        - Only 32-bit float sample format.
*/

// Holds everything we need to play some audio data.
typedef struct
{
    float *samples;   // The audio data itself.
    int sample_count; // Number of samples in the data.
    int sample_index; // Index of the next sample to be played.
    float left_gain;  // How loud to play the sound in the left channel.
    float right_gain; // Same for the right channel.
    int loop;         // If the sound should repeat.
} Mixer_Channel;

// The basic mixer (from 'basic_mixer.c') had a global array of channels.
// This time, lets move this to an object that we can pass into our functions.
typedef struct
{
    Mixer_Channel *channels;
    int channel_count;
    float gain;
} Mixer;

Mixer create_mixer(int channel_count, float gain)
{
    Mixer mixer = {};
    mixer.channels = calloc(channel_count, sizeof(Mixer_Channel));
    if (mixer.channels)
    {
        mixer.channel_count = channel_count;
        mixer.gain = gain;
    }
    return mixer;
}

// See 'basic_mixer.c' for more info on this function.
void mix_audio(Mixer *mixer, void *stream, int samples_requested)
{
    float *samples = (float *)stream;
    for (int sample_index = 0; sample_index <= samples_requested; ++sample_index)
    {
        // This time we have two samples to write: left channel and right channel.
        float final_left_sample = 0.0f;
        float final_right_sample = 0.0f;
        for (int channel_index = 0; channel_index < mixer->channel_count; ++channel_index)
        {
            Mixer_Channel *channel = &mixer->channels[channel_index];
            if (channel->samples)
            {
                if (channel->sample_index <= channel->sample_count)
                {
                    float new_left = channel->samples[channel->sample_index];
                    float new_right = channel->samples[channel->sample_index];

                    // Apply the gain to each channel.
                    new_left *= channel->left_gain;
                    new_right *= channel->right_gain;
                    // Also apply the global gain.
                    new_left *= mixer->gain;
                    new_right *= mixer->gain;

                    // Mix each channel individually.
                    final_left_sample += new_left;
                    final_right_sample += new_right;

                    channel->sample_index += 1;

                    // If the sound should loop reset sample_index back to zero.
                    // Next sample the sound will start again from the beginning.
                    if (channel->loop && channel->sample_index > channel->sample_count)
                    {
                        channel->sample_index = 0;
                    }
                }
                else
                {
                    *channel = (Mixer_Channel){};
                }
            }
        }
        // We write our left and right samples into the sample stream one after the other.
        // This is because the audio data is in left, right, left, right ordering.
        samples[sample_index] = final_left_sample;
        sample_index += 1;
        samples[sample_index] = final_right_sample;
    }
}

int play_audio(Mixer *mixer, void *stream, int sample_count,
               float left_gain, float right_gain, int loop)
{
    // Find the first empty channel and use that to play our sound.
    for (int i = 0; i < mixer->channel_count; ++i)
    {
        if (mixer->channels[i].samples == NULL)
        {
            mixer->channels[i].samples = stream;
            mixer->channels[i].sample_count = sample_count;
            mixer->channels[i].sample_index = 0;
            mixer->channels[i].left_gain = left_gain;
            mixer->channels[i].right_gain = right_gain;
            mixer->channels[i].loop = loop;
            return i;
        }
    }
    return -1;
}
