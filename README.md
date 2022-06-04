# QB64 MOD Player

A [ProTracker](https://en.wikipedia.org/wiki/ProTracker) (and compatible) [MOD](https://en.wikipedia.org/wiki/MOD_(file_format)) player library written entirely in [QB64](https://github.com/QB64-Phoenix-Edition/QB64pe). Yes, this does __not use any__ third party libraries!

![Screenshot](screenshots/qb64mp_mainscreen.png)
![Screenshot](screenshots/qb64mp_infoscreen.png)
![Screenshot](screenshots/qb64mp_patternscreen.png)

## Goals

- No dependency on third party libraries - OK
- No OS specific code in the Loader, Player & Mixer - OK
- Support all MOD types (1 - 99 channels, 31 samples etc.) - OK
- Support all MOD effects - WIP (2 remaining; E3 & EF)
- Easy plug-&-play API - OK
- Play all the test MODs in the repository correctly - WIP (dope.mod, fountain.mod, gslinger.mod, sgtitle.mod sounds awful)
- Survive ode2ptk.mod & black_queen.mod - OK
- Include a demo player to show how to use the library - OK

## API

```VB
Function LoadMODFile` (sFileName As String)
Sub StartMODPlayer
Sub StopMODPlayer
```

## Bibliography

- [MOD Player Tutorial](docs/FMODDOC.TXT) by FireLight
- [S3M Player Tutorial](docs/FS3MDOC.TXT) by FireLight
- [Noisetracker/Soundtracker/Protracker Module Format](docs/MOD-FORM.TXT) by Andrew Scott
- [MODFIL10.TXT](docs/MODFIL10.TXT) by Thunder
- [Protracker Module](https://wiki.multimedia.cx/index.php/Protracker_Module) from MultimediaWiki
- [MOD Effect Commands](https://wiki.openmpt.org/Manual:_Effect_Reference#MOD_Effect_Commands) from OpenMPT Wiki
- [Digital Audio Mixing Techniques](docs/FSBDOC.TXT) by jedi / oxygen
- [Writing Mixing Routines](docs/MIXING10.TXT) by BYTERAVER/TNT
- [Audio Mixer Tutorial](https://github.com/benhenshaw/mixer_tutorial) by benhenshaw

## Assets

- [Icon](https://iconarchive.com/artist/tsukasa-tux.html) by Tsukasa-Tux (Azrael Jackie Lockheart)

## FAQ

Why a MOD player in QB64?

- Just for learning and fun! Long answer: I have seen plenty of MOD players code and libraries in C & C++ but very little in other languages. I know about some JavaScript, Java and C# ones. But, I am not a fan of those languages. I learnt to code on DOS using QuickBASIC and then graduated to C & C++. So, QuickBASIC always had a special place in my heart. Then, I found QB64 on the internet and the rest is history. As far as I know this is the first of it's kind. Let me know if there are any other MOD players written in pure QB64.

Will you add S3M, XM, IT support?

- Not sure. Probably. This will require a lot of work. But you are free to fork and do it yourself.

I found a bug. How can I help?

- Let me know using GitHub issues or fix it yourself and let me know!

Can this be used in a game / demo?

- Absolutely. The player UI code included in a great example.
