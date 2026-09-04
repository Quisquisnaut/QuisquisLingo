#!/usr/bin/env python3
"""Compatibility entry point for the unified Course Model v6 generator.

Course Model v5 generation is intentionally unavailable after the Build 225.02
clean format boundary. The historical filename invokes the v6 pipeline so it
cannot rewrite production assets into an unsupported format.
"""

from regenerate_bundled_courses_225_02 import main


if __name__ == "__main__":
    raise SystemExit(main())
