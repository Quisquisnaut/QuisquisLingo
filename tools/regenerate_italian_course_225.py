#!/usr/bin/env python3
"""Compatibility entry point for the unified Build 225.02 generator.

Italian must not be regenerated independently after the v6 clean cut. Running
this historical tool name therefore regenerates all nine bundled courses using
the one authoritative deterministic pipeline.
"""

from regenerate_bundled_courses_225_02 import main


if __name__ == "__main__":
    raise SystemExit(main())
