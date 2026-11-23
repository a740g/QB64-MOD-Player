/*
    An example of using the stereo audio mixer.
    by Benedict Henshaw (2017/11)

    Uses SDL2: https://libsdl.org/
*/

#include <SDL2/SDL.h>

#include "stereo_mixer.c"
// The faster mixer provides exactly the same functionality, so
// comment out the above line and uncomment this one to test it.
// #include "faster_mixer.c"

// This time our example runs on the audio callback.
// This function will be called whenever the output audio buffer needs more data.
void audio_callback(void *data, Uint8 *stream, int byte_count)
{
    // We know that this points to a Mixer, so cast it to a Mixer.
    Mixer *mixer = data;
    int sample_count = byte_count / sizeof(float);
    // Fill the buffer with our mixed audio.
    mix_audio(mixer, stream, sample_count);
}

int main(int argc, char **argv)
{
    // For more info on handling an SDL2 audio device see 'basic_mixer.c'.
    SDL_Init(SDL_INIT_AUDIO);

    Mixer mixer = create_mixer(32, 1.0f);

    // Our audio device request now specifies a callback function.
    SDL_AudioSpec request = {};
    request.freq = 48000;
    request.format = AUDIO_F32;
    request.channels = 2; // Now we want two channels for stereo audio.
    request.samples = 64;
    // The function that will be called when audio data is needed.
    request.callback = audio_callback;
    // A pointer that will be passed into the callback.
    request.userdata = &mixer;

    SDL_AudioDeviceID audio_device = SDL_OpenAudioDevice(NULL, 0, &request, NULL, 0);
    SDL_assert(audio_device);

    // This time we multiply by two because we have two channels.
    int sample_count = 48000 * 60 * 2;
    int byte_count = sample_count * sizeof(float);
    float *samples = SDL_malloc(byte_count);
    SDL_assert(samples);

    Uint8 *first_sound = NULL;
    Uint32 first_sound_byte_count = 0;
    SDL_assert(SDL_LoadWAV("drums.wav",
                           &request, &first_sound, &first_sound_byte_count));
    int first_sound_sample_count = first_sound_byte_count / sizeof(float);
    // Here we keep hold of the index that is returned so that we can
    // access that channel later.
    int sound_index = play_audio(&mixer,
                                 first_sound, first_sound_sample_count, 0.0f, 1.0f, 1);

    Uint8 *second_sound = NULL;
    Uint32 second_sound_byte_count = 0;
    SDL_assert(SDL_LoadWAV("Gymnopedie.wav",
                           &request, &second_sound, &second_sound_byte_count));
    int second_sound_sample_count = second_sound_byte_count / sizeof(float);
    play_audio(&mixer, second_sound, second_sound_sample_count, 1.0f, 0.0f, 0);

    Uint8 *third_sound = NULL;
    Uint32 third_sound_byte_count = 0;
    SDL_assert(SDL_LoadWAV("Fantasie.wav",
                           &request, &third_sound, &third_sound_byte_count));
    int third_sound_sample_count = third_sound_byte_count / sizeof(float);
    play_audio(&mixer, third_sound, third_sound_sample_count, 0.0f, 1.0f, 0);

    SDL_PauseAudioDevice(audio_device, 0);

    while (1)
    {
        float time = SDL_GetTicks() * 0.0015f;
        SDL_LockAudioDevice(audio_device);
        // We'll update the paning with some values that smoothly transition
        // to get a nice panning effect.
        mixer.channels[sound_index].left_gain = sinf(time);
        mixer.channels[sound_index].right_gain = cosf(time);
        SDL_UnlockAudioDevice(audio_device);
        SDL_Delay(10);
    }
}
