# QuisquisLingo v0.6.8 platform bootstrap.
# Run only from the project root, with Flutter installed and available in PATH.
# Existing lib/, assets/ and course data are kept; Flutter creates missing
# platform runner folders for the selected targets.
flutter create --platforms=android,windows,linux,web .
