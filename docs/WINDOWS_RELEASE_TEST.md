# Windows standalone release test

Run before distributing a Windows build:

1. `flutter pub get`
2. `flutter analyze` and require `No issues found!`.
3. `flutter test` and require all tests to pass.
4. `flutter build windows --release`.
5. Copy the entire `build\\windows\\x64\\runner\\Release` directory to a Windows machine without Flutter or VS Code.
6. Start QuisquisLingo from the packaged executable.
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
29. With Animations enabled, switch from the current Course to a different Course that has a valid flag explicitly configured in its Course JSON. Verify that exact destination flag briefly covers the Learner Panel and fades away in under one second.
30. Verify no Course Entry Animation occurs when selecting the current Course again, returning from internal screens, or starting the app with a persisted Course. Disable Animations under Do Not Disturb and verify a different flagged Course switches immediately. Also verify that a Course without a valid configured JSON flag switches immediately without a generic or language-derived substitute.

This checklist complements automated tests. A release is not certified until the target-machine checks have been performed.
