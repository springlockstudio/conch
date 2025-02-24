# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

--------------------------------------------------------------------------------

## [0.2.0] - 2025-02-24

### Added

- Add `@` as a valid symbol for identifiers
- Add server argument replication
- Refactor how developers add arguments
- Add `glue.register_type`
- Add `license` as a default command
- Add `ui.bind_to` and `ui.mount` to bind opening to an input and mount the ui.
- Add `glue.set_var`
- Add analysis for variables
- Add vector syntax as `[x, y, z]`
- Add autofill through tab in UI
- Add general iteration

### Changes

- Prevent textbox from capturing focus before the menu opens by @synpixel in https://github.com/alicesaidhi/conch/pull/12
- Update UI to be more visually distinct

### Fixes

- Fixed error in analysis when no arguments are provided
- Fix positioning of suggestions
- Fix lune release script for Wally
- Fix for loops

--------------------------------------------------------------------------------

## [0.1.6] - 2025-02-05

- Initial Wally release

--------------------------------------------------------------------------------

## [0.1.0] - 2025-02-04

- Initial release
