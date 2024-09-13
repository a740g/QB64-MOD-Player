# Audio Mixer Tutorial

*A series of straightforward audio mixers written in **C** for educational
purposes.*

If you are interested in playing multiple sounds at once you will need some way to mix the audio together. Here are some examples of how one could write an audio mixer. Each example builds on the previous, and they are best understood by reading them in order. Each mixer also has a corresponding example program that demonstrates its usage.

- **basic_mixer.c** - Very basic mono mixer. *Start Here!*
- **stereo_mixer.c** - Adds panning and looping.
- **faster_mixer.c** - Some slight adjustments to improve performance.

## More Info

### About This Code

- Only some basic knowledge of **C** is expected. There are also some explanations for those new to **C**.
- The mixers have no dependencies, but the examples that use them rely on **SDL2** for audio device access.
- These examples could be easily converted to **C++** with little or no modification.
- The example programs also attempt to describe how to use some of the audio features of **SDL2**.
- See ["Releases"](https://github.com/benhenshaw/mixer_tutorial/releases/tag/1.0) for the audio files used.

### About Audio

- Sound is represented in a computer as a series of samples (just numbers).
- The value of this sample is the amplitude of the sound.
- To mix two sounds together, you only need to add their samples together.
- The resulting samples will appear to our ears to have both sounds playing in it.

I hope you find this useful. Feedback is very welcome!

\- Ben (2017-11-23, updated: 2018-02-22)
