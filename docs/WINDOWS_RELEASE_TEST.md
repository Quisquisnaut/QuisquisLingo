# Windows standalone release test

Run before distributing a Windows build:

1. `flutter pub get`
2. `flutter analyze` and require `No issues found!`.
3. `flutter test` and require all tests to pass.
4. `flutter build windows --release`.
5. Copy the entire `build\\windows\\x64\\runner\\Release` directory to a Windows machine without Flutter or VS Code.
6. Start QuisquisLingo from the packaged executable.
7. Test an installed Italian voice and an installed English voice.
8. Test a course locale for which no compatible voice is installed. The app must fail gracefully and remain usable.
9. Test System, Female and Male voice preferences. Unsupported preferences must fall back to a compatible installed voice.
10. Complete a TTS exercise and verify no native-thread crash or data loss.
11. Disable TTS exercises and verify a zero-error round receives the TTS-skipped mark, not a laurel crown.
12. Verify existing learner progress survives startup and remains isolated by profile and course.
13. Verify language XP, learner-global Weekly XP and its per-course breakdown survive restart.
14. Open Course Editor and confirm it starts normally.
15. Import or open a course through the established flow and confirm it remains data-only and playable.
16. Complete at least one playable Round and confirm its established completion/progress behavior.
17. Restart the standalone app and recheck progress, XP, settings and selected-course persistence.

This checklist complements automated tests. A release is not certified until the target-machine checks have been performed.
