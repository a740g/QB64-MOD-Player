# References and Documentation

A curated collection of format specifications, player tutorials, audio mixing guides, and hardware emulation references used in developing this project.

Internal repository documentation is preferred and linked locally under `references/`. High-quality external specifications and wikis are included for supplementary reference.

---

## Table of Contents

- [Supported Module Formats](#supported-module-formats)
  - [ProTracker / SoundTracker / StarTrekker (.mod)](#protracker-soundtracker-startrekker-mod)
  - [Scream Tracker 3 (.s3m)](#scream-tracker-3-s3m)
  - [MultiTracker (.mtm)](#multitracker-mtm)
  - [Composer 669 (.669)](#composer-669-669)
  - [Farandole Composer (.far)](#farandole-composer-far)
  - [Scream Tracker 2 (.stm)](#scream-tracker-2-stm)
  - [Reality Adlib Tracker (.rad)](#reality-adlib-tracker-rad)
  - [UltraTracker (.ult)](#ultratracker-ult)
  - [Digitrakker (.mdl)](#digitrakker-mdl)
  - [Advanced Music Format (.amf)](#advanced-music-format-amf)
- [Tracker & Replayer Tutorials](#tracker-replayer-tutorials)
- [Audio Mixing, DSP & Software Synthesis](#audio-mixing-dsp-software-synthesis)
- [FM Synthesis & Hardware Emulation (OPL2 / OPL3)](#fm-synthesis-hardware-emulation-opl2-opl3)
- [Audio Spectrum Analysis (FFT)](#audio-spectrum-analysis-fft)
- [Tracker Compatibility & Effect Architecture](#tracker-compatibility-effect-architecture)

---

## Supported Module Formats

### ProTracker / SoundTracker / StarTrekker (.mod)

- [Noisetracker/Soundtracker/Protracker Module Format (Rev 4)](references/Pro-Noise-Soundtracker%20module%20format%20%28rev%204%29.txt) by *Andrew Scott*
- [Protracker Effects (MODFIL12.TXT)](references/Protracker%20effects%20%28MODFIL12.TXT%29%20%28.mod%29.txt) by *Thunder*
- [Protracker 2.3A & Miscellaneous Info](references/Protracker%202.3A%20%26%20miscellaneous%20info%20%28.mod%29.txt) by *Lars Hamre*
- [Protracker File Format Reference](references/Protracker%20%28.mod%29.txt) from *PC Demogroup Archives*
- [Ultimate Soundtracker Format](references/Ultimate%20Soundtracker%20%28.mod%29.txt) by *Michael Schwendt*
- [Startrekker MOD Format](references/Startrekker%20%28.mod%29.txt) by *Bjorn Wessen (Exterminator / Amiga Freelancers)*
- [Startrekker AM/FM Synthesized Instruments](references/Startrekker_AMFM.txt) by *Exterminator & Gluemaster*
- [MOD Format Specification](https://moddingwiki.shikadi.net/wiki/MOD_Format) from *ModdingWiki*
- [ProTracker](https://en.wikipedia.org/wiki/ProTracker) from *Wikipedia*

### Scream Tracker 3 (.s3m)

- [Scream Tracker 3.20 File Format](references/Scream%20Tracker%20v3.20%20%28.s3m%29.txt) by *PSI (Sami Tammilehto / Future Crew)*
- [Scream Tracker 3.20 Effects List](references/Scream%20Tracker%20v3.20%20effects%20%28.s3m%29.txt) by *Future Crew*
- [Scream Tracker 3.01b Technical Notes](references/Scream%20Tracker%20v3.01b%20%28.s3m%29.txt) by *Future Crew*
- [S3M Format Specification](https://moddingwiki.shikadi.net/wiki/S3M_Format) from *ModdingWiki*

### MultiTracker (.mtm)

- [MultiTracker Module (MTM) Format Specification](references/MultiTracker%20%28.mtm%29.txt) by *Renaissance*
- [MultiTracker Technical Notes #2](references/MultiTracker%20%28.mtm%29%20%232.txt) by *Renaissance*
- [MultiTracker Technical Notes #3](references/MultiTracker%20%28.mtm%29%20%233.txt) by *Renaissance (from FileFormats List)*

### Composer 669 (.669)

- [Composer 669 Module Specification](references/Composer%20669%20%28.669%29.txt) by *Max Maischein (from FileFormats List v1.50)*
- [Composer 669 and UNIS 669 Format](references/Composer%20669%2C%20Unis%20669%20%28.669%29.txt) by *Tomasz Kojm*
- [669 File Format Summary](references/669.txt) by *Simplet / FATAL DESIGN*

### Farandole Composer (.far)

- [Farandole Composer Format Specification](references/Farandole%20Composer%20%28.far%29.txt) by *Daniel Potter*
- [Farandole Composer Notes #2](references/Farandole%20Composer%20%28.far%29%20%232.txt) by *Daniel Potter (from FileFormats List)*

### Scream Tracker 2 (.stm)

- [Scream Tracker 1.0 & 2.xx File Format](references/Scream%20Tracker%20v1.0%20%28.stm%29.txt) by *Max Maischein (File Format List 2.0)*
- [STM Technical Reference](references/stm.txt) by *Sami Tammilehto / Future Crew*
- [STM Effects Reference](references/stm-effects.txt) by *Future Crew*
- [STMIK 1.1 Specification](references/STMIK%20v1.1%20%28.stx%29.txt) by *Claudio Matsuoka (Extended Module Player)*

### Reality Adlib Tracker (.rad)

- [Reality AdLib Tracker File Format](references/Reality%20AdLib%20Tracker%20%28.rad%29.txt) by *Reality (from FileFormats List)*
- [RAD Format Documentation](references/RAD.DOC) by *Shayde, Rogue & Void (Reality)*
- [RAD Format HTML Reference](references/RAD.HTML) by *Shayde, Rogue & Void (Reality)*
- [RAD Effects and Command Summary](references/rad.txt) by *Reality*

### UltraTracker (.ult)

- [UltraTracker 1.4-1.6 Module Format](references/Ultratracker%20v1.4-6%20%28.ult%29.txt) by *FreeJack (The Elven Nation) & MAS (Marc Andre Schallehn)*
- [UltraTracker 1.31 Module Format](references/Ultratracker%20v1.31%20%28.ult%29.txt) by *MAS (Marc Andre Schallehn)*

### Digitrakker (.mdl)

- [Digitrakker 1.1 File Format](references/Digitrakker%20v1.1%20%28.mdl%29.txt) by *n-Factor (from FileFormats List)*
- [Digitrakker Effects and Command Reference](references/mdl-effects.txt) by *n-Factor*

### Advanced Music Format (.amf)

- [Advanced Module Format Specification](references/Advanced%20Module%20Format%20%28.amf%29.txt) by *Miodrag Vallat & Otto Chrons (DSMI)*

---

## Tracker & Replayer Tutorials

- [MOD Player Tutorial](references/FireLight%20MOD%20Player%20Tutorial.txt) by *FireLight (Brett Paterson, founder of FMOD)*
- [S3M Player Tutorial](references/FireLight%20S3M%20Player%20Tutorial.txt) by *FireLight (Brett Paterson, founder of FMOD)*
- [Weasel Audio Library](https://weaselaudiolib.sourceforge.net/) by *Warren Willmey*

---

## Audio Mixing, DSP & Software Synthesis

- [Digital Audio Mixing Techniques](references/FSBDOC.TXT) by *jedi / oxygen*
- [Writing Mixing Routines](references/MIXING10.TXT) by *BYTERAVER/TNT*
- [Audio Mixer Tutorial](references/mixer_tutorial) by *Ben Henshaw (benhenshaw)*
- [Filter Algorithms and Audio DSP](references/filters.txt) by *Jeffrey Lim (Impulse Tracker)*

---

## FM Synthesis & Hardware Emulation (OPL2 / OPL3)

- [Opal OPL3 Sound Chip Emulator](https://github.com/RealBitdancer/opal) by *RealBitdancer*
- [Adlib Tracker File & Instrument Specs](references/Adlib%20Tracker%20%28.sng%2C%20.ins%29.txt) from *SubSonic Software (Adlib Tracker v1.0)*
- [Ken's Adlib Music File Specification](references/Ken%27S%20adlib%20Music%20File%20%28.ksm%29.txt) by *Ken Silverman*

---

## Audio Spectrum Analysis (FFT)

- [Cooley-Tukey Fast Fourier Transform Algorithm](https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm) from *Wikipedia*

---

## Tracker Compatibility & Effect Architecture

- [Tracker Differences for Coders](references/Tracker%20differences%20for%20Coders.txt) by *Hipolito Carraro Jr. & Claudio Matsuoka*
- [MOD Effect EF Quick Reference](references/MOD%20Effect%20EF.txt) from *OpenMPT Community Tracker Research*
- [Manual: Effect Reference](https://wiki.openmpt.org/Manual:_Effect_Reference) from *OpenMPT Wiki*
