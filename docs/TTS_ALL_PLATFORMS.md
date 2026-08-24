# Text-to-speech

Updated for the current alpha

TTS can be disabled from Settings > TTS Settings. A separate TTS voice preference offers **System default**, **Female**, and **Male**, plus **Test voice**.

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
used. Settings > TTS Settings includes **Test Voice**.

**Skip all TTS exercises** removes TTS-dependent exercises from learner rounds.
A zero-error attempt in which any TTS exercise was skipped cannot earn a new
laurel crown. It receives a separate leaf-style completion mark instead. A
later full zero-error attempt can still earn the permanent laurel.
