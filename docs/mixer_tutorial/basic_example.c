/*
    An example of using the basic audio mixer.
    by Benedict Henshaw (2017/11)

    Uses SDL2: https://libsdl.org/
*/

#include <SDL2/SDL.h>
#include "basic_mixer.c"

int main(int argc, char **argv)
{
    // Initialise the audio component of SDL.
    // It will give us easy access to the audio device.
    SDL_Init(SDL_INIT_AUDIO);

    // We need to open our audio device, and tell it what format we will send our
    // audio data in. The device will be paused when we first get access to it.
    SDL_AudioSpec request = {};
    request.freq = 48000;       // 48KHz
    request.format = AUDIO_F32; // samples are floats in range -1.0 to 1.0
    request.channels = 1;       // mono (one channel)
    // Request the default audio device to be opened.
    SDL_AudioDeviceID audio_device = SDL_OpenAudioDevice(NULL, 0, &request, NULL, 0);
    // audio_device will be zero if the request failed.
    SDL_assert(audio_device);

    // Let's play audio for 60 seconds.
    // We need to make a buffer to fill with that audio
    // Our frequency is 48KHz, so there will be 48000 samples in one second of audio.
    int sample_count = 48000 * 60;
    // Each sample is a float value, so to allocate memory for that we will need to
    // multiply our sample count by the size of one float, giving us the total size
    // in bytes of our audio data.
    int byte_count = sample_count * sizeof(float);
    // Allocate memory for our audio data.
    float *samples = SDL_malloc(byte_count);
    // Ensure that the allocation succeeded.
    SDL_assert(samples);

    // Load some audio to play.
    // These variables will be filled in by SDL_LoadWAV.
    Uint8 *first_sound = NULL;
    Uint32 first_sound_byte_count = 0;
    SDL_assert(SDL_LoadWAV("Gnossienne.wav",
                           &request, &first_sound, &first_sound_byte_count));
    int first_sound_sample_count = first_sound_byte_count / sizeof(float);
    play_audio(first_sound, first_sound_sample_count, 1.0f);

    // Do the same for a second sound.
    Uint8 *second_sound = NULL;
    Uint32 second_sound_byte_count = 0;
    SDL_assert(SDL_LoadWAV("Gymnopedie.wav",
                           &request, &second_sound, &second_sound_byte_count));
    int second_sound_sample_count = second_sound_byte_count / sizeof(float);
    play_audio(second_sound, second_sound_sample_count, 1.0f);

    // And a third.
    Uint8 *third_sound = NULL;
    Uint32 third_sound_byte_count = 0;
    SDL_assert(SDL_LoadWAV("Fantasie.wav",
                           &request, &third_sound, &third_sound_byte_count));
    int third_sound_sample_count = third_sound_byte_count / sizeof(float);
    play_audio(third_sound, third_sound_sample_count, 1.0f);

    // Give our empty samples array to our mixer to fill.
    mix_audio(samples, sample_count);
    // Send our audio samples off to the audio device for playback.
    SDL_QueueAudio(audio_device, samples, byte_count);
    // Un-pause the audio device.
    SDL_PauseAudioDevice(audio_device, 0);

    // Wait one minute (60000ms). Audio should be playing.
    SDL_Delay(60000);

    // Then quit.
    SDL_Quit();
    return 0;
}
