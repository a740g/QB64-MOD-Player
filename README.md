# QB64 MOD Player

A ProTracker (and compatible) MOD player written in QB64

## Goals:

- No dependency on 3rd party libraries
- Support all MOD types (1 - 99 channels, 31 samples etc.) - WIP
- Support all effects - WIP
- No mixing code - depend on QB64 internal sound engine mixer - FAIL [No _NEWSOUND in QB64]
- Easy plug-n-play API - WIP

## Bibliography:

- [MOD Player Tutorial](https://github.com/a740g/QB64-MOD-Player/blob/main/FMODDOC.TXT) by FireLight
- [Digital Audio Mixing Techniques](https://github.com/a740g/QB64-MOD-Player/blob/main/FSBDOC.TXT) by jedi / oxygen

## FAQ

### Why a MOD player in QB64?

Just for learning and fun!

### Will you add S3M, XM, IT support?

No. But you are free to fork and do it yourself.

### Can this be used in a game / demo?

Absolutely. With little effort. But I have not tried integrating this into anything else myself.
