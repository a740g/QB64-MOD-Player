/*
    A stereo floating-point audio mixer.
    by Benedict Henshaw (11/2017)

    Usage:
        Call mix_audio() with a pointer to your audio buffer, the number of
        samples you want to be written into it.

    New Features:
        - Faster mixing.

    Limitations:
        - Only plays mono sources with panning.
        - Only 32-bit float sample format.
*/

// Our main data structures are identical to the stereo mixer.
typedef struct
{
    float *samples;   // The audio data itself.
    int sample_count; // Number of samples in the data.
    int sample_index; // Index of the next sample to be played.
    float left_gain;  // How loud to play the sound in the left channel.
    float right_gain; // Same for the right channel.
    int loop;         // If the sound should repeat.
} Mixer_Channel;

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

void mix_audio(Mixer *mixer, void *stream, int samples_requested)
{
    float *samples = (float *)stream;

    // A small change has been made here so that the mixer reads consecutive
    // samples from each channel, instead of one sample from each channel at a
    // time. Accessing adjacent memory is much faster than jumping to memory
    // that is further away. This is due to the way caching is done by the CPU.

    // We will need to zero our whole stream first so that, in the case where no
    // sound is playing or there isn't enough to fill all the requested samples,
    // we will not leave garbage data in the buffer.
    for (int sample_index = 0; sample_index < samples_requested; ++sample_index)
    {
        samples[sample_index] = 0.0f;
    }

    // This time we will go through each channel, then mix all of that channel's
    // samples into the output buffer in one go. Most of this should be familiar
    // if you have read the previous mixer examples.
    for (int channel_index = 0; channel_index < mixer->channel_count; ++channel_index)
    {
        Mixer_Channel *channel = &mixer->channels[channel_index];
        if (channel->samples)
        {
            for (int sample_index = 0;
                 sample_index < samples_requested &&
                 channel->sample_index < channel->sample_count;
                 ++sample_index)
            {
                float new_left = channel->samples[channel->sample_index];
                float new_right = channel->samples[channel->sample_index];

                new_left *= channel->left_gain;
                new_left *= mixer->gain;
                new_right *= channel->right_gain;
                new_right *= mixer->gain;

                samples[sample_index] += new_left;
                ++sample_index;
                samples[sample_index] += new_right;

                channel->sample_index += 1;
            }

            // This check can now be made after the main mixing loop.
            if (channel->sample_index >= channel->sample_count)
            {
                if (channel->loop)
                {
                    channel->sample_index = 0;
                }
                else
                {
                    *channel = (Mixer_Channel){};
                }
            }
        }
    }
}

int play_audio(Mixer *mixer, void *stream, int sample_count,
               float left_gain, float right_gain, int loop)
{
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
