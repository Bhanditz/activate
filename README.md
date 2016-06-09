# activate

![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)
[![Build Status](https://git.itch.ovh/itchio/activate/badges/master/build.svg)](https://git.itch.ovh/itchio/activate/builds)

Simple command-line tool to run Mac executables and, if they turn out to
be a GUI app, activate them (bring them to front).

Used by [itch][] to run apps isolated on Mac, because:

  * `open -W Something.app` behaves correctly (correct icon in Dock, 
  app activates naturally) but swallows stdout, and cannot be used in
  conjunction with `sandbox-exec`
  * `sandbox-exec` requires path to the actual executable (even if it's
  within an app bundle), so it won't launch GUI applications properly
  (wrong icon in Dock + app doesn't activate, ie. window stays in background)

activate fixes one of these — still looking into the icon thing.

[itch]: https://github.com/itchio/itch

Also obeys these commands:

  * `--print-library-paths`: print Library paths (like `/Users/abc/Library`), one per line
  * `--print-bundle-executable-path /path/to/Foobar.app` print executable path (like `/path/to/Foobar.app/Contents/MacOS/foobar`)

### License

activate is released under the MIT license, see `LICENSE.txt` for details
