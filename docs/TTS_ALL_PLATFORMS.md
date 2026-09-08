# Text-to-speech

Updated for the current alpha

**Settings > Audio Settings** contains exactly these controls, in order:

1. **Enable Audio Exercises**
2. **Text-to-speech**
3. **TTS voice**: System default, Female or Male, followed by **Test Voice**

Enable Audio Exercises and Text-to-speech are stored per opaque learner profile and initialize Off. TTS voice is also per learner and initializes System. While Enable Audio Exercises is Off, learner Round and Duel queues exclude recorded MP3, TTS and hybrid audio exercises before initializing playback infrastructure. While On, actual source availability and course audio configuration apply. Text-to-speech controls only TTS availability; a valid recorded source remains usable while it is Off. This is a clean cut: previous shared and negative audio-setting values remain untouched and unread. Authoring Preview ignores learner Audio Settings and preserves its no-write behavior. Test Voice remains available when Text-to-speech is On; it opens with an empty field, prevents blank playback, and sends the exact user-entered text through voice resolution for the selected course language. It does not infer, translate, replace, or use the UI locale to choose the speech language.

The gender setting is a preference rather than a guarantee. Platform voice metadata varies. If the preferred gender is unavailable, QuisquisLingo uses another compatible voice in the same language rather than remaining silent.

## Windows

QuisquisLingo first searches installed voices in the requested locale, then within the same language family. This means a course requesting `en-GB` may use an installed `en-US` English voice when no British voice is available. It must not silently fall back to Italian or another unrelated language.

The diagnostic log records the requested language and voice preference. The native backend selects an exact locale first, then another voice in the same language family.

## Android / iOS / macOS / Web

The `flutter_tts` platform engine is used. Available voices depend on the operating system/browser. The app can prefer an exposed gender-compatible voice but does not block speech if the platform does not expose one.

## Linux

The Flutter TTS plugin used by QuisquisLingo does not provide the Linux backend used here. QuisquisLingo invokes a locally installed `espeak-ng` or `espeak`, then plays generated WAV audio with `aplay` when available. This can be disabled like all other TTS.

Linux discovery does not use a shell command. Known executables are located on PATH and launched with separate argument arrays.

## Windows backend in 0.5.0

Windows now uses `System.Speech` through a dedicated PowerShell process instead
of calling `flutter_tts` for speech. This avoids the platform-thread error seen
with current Flutter/flutter_tts Windows combinations. Locale, voice preference and rate are passed through a fixed child-process environment. Spoken text is UTF-8/Base64 encoded before it enters that environment. No course text is interpolated into PowerShell source.

The Windows backend first looks for an exact requested locale, then another
installed voice in the same language family. Female/Male is a preference; when
no matching gender exists, another voice in the correct language family is
used. The same preference is selected under Settings > Audio Settings.

When **Enable Audio Exercises** is Off, every audio-dependent exercise is removed
from learner Rounds and Duels before audio source or player initialization. A zero-error
Round attempt in which audio content was skipped cannot earn a new laurel crown.
It receives the established separate leaf-style completion mark instead. A
later full zero-error attempt can still earn the permanent laurel.

TTS and recorded playback write bounded, correlation-ID-based lifecycle events
to the existing Diagnostic and Crash Logs. Those events exclude spoken text,
answers, course content and full personal file paths.

In learner Rounds, a listening exercise immediately after **Before you start**
may be prepared and checked for audio eligibility while the introduction is
visible, but automatic TTS or recorded playback waits until **Continue to
Round** makes that exercise active. Ordinary Rounds without an introduction
and Editor Preview retain their established playback timing.
