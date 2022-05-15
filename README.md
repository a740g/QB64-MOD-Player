# QB64 MOD Player

A [ProTracker](https://en.wikipedia.org/wiki/ProTracker) (and compatible) [MOD](https://en.wikipedia.org/wiki/MOD_(file_format)) player written in [QB64](https://github.com/QB64-Phoenix-Edition/QB64pe)

## Goals

- No dependency on 3rd party libraries - OK
- No OS specific code in the Loader, Player & Mixer - OK
- Support all MOD types (1 - 99 channels, 31 samples etc.) - OK
- Support all effects - WIP
- Easy plug-&-play API - OK
- Play all the test MODs in the repository correctly - WIP
- Survive ode2ptk.mod & black_queen.mod - WIP

## Bibliography

- [MOD Player Tutorial](https://github.com/a740g/QB64-MOD-Player/blob/main/docs/FMODDOC.TXT) by FireLight
- [S3M Player Tutorial](https://github.com/a740g/QB64-MOD-Player/blob/main/docs/FS3MDOC.TXT) by FireLight
- [Noisetracker/Soundtracker/Protracker Module Format](https://github.com/a740g/QB64-MOD-Player/blob/main/docs/MOD-FORM.TXT) by Andrew Scott
- [MODFIL10.TXT](https://github.com/a740g/QB64-MOD-Player/blob/main/docs/MODFIL10.TXT) by Thunder
- [Protracker Module](https://wiki.multimedia.cx/index.php/Protracker_Module) by MultimediaWiki
- [Digital Audio Mixing Techniques](https://github.com/a740g/QB64-MOD-Player/blob/main/docs/FSBDOC.TXT) by jedi / oxygen
- [Writing Mixing Routines](https://github.com/a740g/QB64-MOD-Player/blob/main/docs/MIXING10.TXT) by BYTERAVER/TNT
- [Audio Mixer Tutorial](https://github.com/benhenshaw/mixer_tutorial) by benhenshaw

## FAQ

Why a MOD player in QB64?

    Just for learning and fun!

Will you add S3M, XM, IT support?

    No. But you are free to fork and do it yourself.

I found a bug. How can I help?

    There are probably many bugs now. This will change as the code matures. In the meantime, let me know using GitHub issues.

Can this be used in a game / demo?

    Absolutely. With little effort. But I have not tried integrating this into anything myself (yet).
