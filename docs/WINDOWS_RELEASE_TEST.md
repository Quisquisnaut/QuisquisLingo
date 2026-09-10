# Windows standalone release test

## Bootstrap/package validation for frozen QQL 2.0.29+2293

This packaging-only change does not alter the Flutter application. The normal
packaged entry point is `QuisquisLingo.exe`; `quisquislingo_app.exe` remains the
unchanged internal app and can still be started directly to bypass preflight.
The package root also contains the unchanged external `QQL infographic.png`.

With an already validated `build\windows\x64\runner\Release` for QQL
`2.0.29+2293`, run:

```powershell
.\tools\package_windows_release.ps1
```

The script deliberately does not rebuild Flutter by default. It hashes every
existing QQL/Flutter Release file, builds and runs only the native launcher/test
targets, verifies the frozen file manifest did not change, verifies the staged
and independently extracted ZIP manifests byte-for-byte, and runs
`dumpbin /DEPENDENTS` against the built, staged and ZIP-extracted launchers. The
launcher must use `MultiThreaded` (`/MT`) for Release and import only the expected
Windows system DLLs, never `MSVCP140.dll`, `VCRUNTIME140.dll`,
`VCRUNTIME140_1.dll`, `flutter_windows.dll`, Dart or .NET.

Use `-RebuildFlutterApplication` only for a separately authorized future app
build. It is out of scope for this frozen 2293 packaging operation.

### Concise manual bootstrap checklist

1. Healthy Windows 10/11: start `QuisquisLingo.exe`; expect no warning and the
   unchanged QQL 2.0.29+2293 app.
2. Missing packaged VC DLL: in a disposable package copy remove one VC DLL;
   expect the launcher itself to start, one package-incomplete warning,
   re-download/re-extract guidance, and Continue anyway / Cancel.
3. Missing `MFPlat.dll`: on an appropriate disposable Windows environment,
   expect Windows Media Foundation/Media Feature Pack guidance and Continue
   anyway / Cancel.
4. Multiple recoverable issues: expect one consolidated dialog, not a warning
   cascade.
5. Missing `quisquislingo_app.exe`: in a disposable package copy remove it;
   expect an incomplete-package fatal dialog with Close only.
6. Older native Windows: expect a Windows 10-or-later compatibility warning with
   Continue anyway / Cancel, not a hard block.
7. Wine: expect Wine to be detected before version policy, no native
   old-Windows warning, Experimental status, and Wine-specific Media Foundation
   text when applicable.
8. Unicode path: place the full package under a path with spaces, accents and a
   non-Latin segment; start the bootstrap from another current directory.
9. Command-line forwarding: verify plain, spaced, quoted, Unicode and
   backslash/quote-sensitive arguments arrive unchanged.
10. Confirm `QQL infographic.png` opens externally and is byte-identical to the
    approved source; no QQL UI entry should reference it.

The native automated package tests exercise the missing-VC and missing-app
copies, exact dialog buttons, Continue/Cancel, child creation/failure, Unicode
package resolution, argument forwarding, current-directory inheritance and
environment inheritance. Wine and older-Windows machine validation remains
recommended on those actual runtimes.

## Existing QQL application validation

Run before distributing a Windows build:

1. `flutter pub get`
2. `flutter analyze` and require `No issues found!`.
3. `flutter test` and require all tests to pass.
4. `flutter build windows --release`.
5. Copy the entire `build\\windows\\x64\\runner\\Release` directory to a Windows machine without Flutter or VS Code.
6. Start QuisquisLingo from the packaged `QuisquisLingo.exe` bootstrap. Also
   confirm direct `quisquislingo_app.exe` execution still bypasses preflight.
7. Verify Settings is ordered Profile, App Info, Audio Settings, Do Not Disturb, Debug, Version and Build, Update. Verify Course Manager and User Data are absent there.
8. Verify Profile is ordered Avatar, Learner profiles, Gamification, Statistics, User Data, then Log out.
9. Open Statistics after studying more than one language. Verify Total Study Days counts shared dates once and each language shows its flag, name, canonical ID, Study Days, Current Streak and Max Streak.
10. Create a new learner, open Audio Settings and verify Enable Audio Exercises and Text-to-speech both start Off. Verify the order is Enable Audio Exercises, Text-to-speech, then TTS voice with the existing Test Voice action.
11. Open Test Voice for an Italian course and an English course. Verify the editable field starts empty, blank input cannot play, and the exact typed text is spoken with the selected course's voice language. Deliberately type Italian text for the English course and verify QQL does not translate or replace it.
12. Test a course locale for which no compatible voice is installed. The app must retain its specific missing-compatible-voice message and remain usable.
13. Test System default, Female and Male voice preferences. Unsupported preferences must fall back to a compatible installed voice.
14. Complete a TTS exercise and a recorded-MP3 exercise and verify no native-thread crash or data loss.
15. Leave Enable Audio Exercises Off for one learner. Verify all recorded, TTS and hybrid audio exercises are excluded before playback initialization, another learner still defaults Off, and a zero-error remaining Round receives the partial-audio mark rather than a laurel crown. Turn it On and verify available recorded audio and enabled TTS resume normally.
16. Disable Text-to-speech while retaining valid recorded audio. Verify TTS-only exercises are unavailable and recorded exercises remain playable.
17. Open an unsaved audio Exercise Preview while learner audio settings are restrictive. Verify Preview still plays, writes no learner state and does not mutate preferences.
18. Open a learner Round whose `Before you start` introduction is followed first by a TTS listening exercise, then repeat with a recorded-MP3 course. Verify preparation/source eligibility can complete without sound while the introduction remains visible, and each exercise plays once only after Continue makes it active. Recheck a listening Round without an introduction for unchanged automatic playback.
19. Create two learners with the same display name and verify their avatars, progress, XP, settings and active courses remain independent after switching and restart.
20. Verify language XP, learner-global Weekly XP and its per-course breakdown survive restart.
21. Unlock Course Manager through Version and Build, then open it from the learner Course Selector; confirm no Settings entry appears.
22. Import or open a course through the established flow and confirm it remains data-only and playable.
23. Complete at least one playable Round and confirm its established completion/progress behavior.
24. Restart the standalone app and recheck progress, XP, settings and selected-course persistence.
25. Hover over the Settings flag and verify the gentle wave. Confirm the tooltip is exactly `Tap tap... Flag Game`, then tap/click the Settings title or flag five times within three seconds and verify the unchanged Flag Game action.
26. Play Flag Game at 320, 375 and 430 logical-pixel widths in System, Light and Dark modes. Verify five answers fit, feedback advances automatically, all four references and all four Top 5 scorecards remain usable, and Back/Close returns to Settings.
27. Open Settings > Debug. Verify its Crash/Diagnostic reporting and privacy guidance is present and both log actions target `Documents/QuisquisLingo/Logs`. Reproduce the introduction/audio sequence and confirm the Diagnostic Log orders prepared `before_you_start`, source eligibility, not-active suppression, active exercise, and playback events using a stable technical target ID without spoken text, answers, course content or a full personal path.
28. Open Profile > User Data, export a learner backup, and verify preserve-ID restore, collision choices and an independent separate-copy import with both retained and changed display names.
29. With Animations enabled, switch from the current Course to a different Course that has a valid flag explicitly configured in its Course JSON. Verify that exact destination flag briefly covers the Learner Panel and completes its hold-and-fade transition in two seconds.
30. Verify no Course Entry Animation occurs when selecting the current Course again, returning from internal screens, or starting the app with a persisted Course. Disable Animations under Do Not Disturb and verify a different Course switches immediately. Re-enable Animations and verify that the two-second transition starts after the Course Selector closes, that a Course with no declared JSON flag uses its established course-code flag fallback, and that an invalid declared flag is not replaced by the fallback.
31. Under Do Not Disturb, verify Show one-time notices again is a tappable action rather than a switch and that using it confirms the reset. Under Update, run Check for updates against the current repository state and verify that the no-package result distinguishes the published source repository from the absence of a packaged GitHub Release.

This checklist complements automated tests. A release is not certified until the target-machine checks have been performed.
