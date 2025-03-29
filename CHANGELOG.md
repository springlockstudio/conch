# Changelog

All notable changes to this project will be documented in this file.

--------------------------------------------------------------------------------

## 0.2.1 conch-ast - 2025-03-25

- Fix comments causing an infinite loop

## 0.2.1 conch-analysis - 2025-03-25

- Fix comments causing an infinite loop
- Implement optional arguments

## 0.2.2 conch-compiler - 2025-03-25

- Output all values from the stack
- Fix valid number literals not converting (0x, 0b, _)

## 0.2.1 conch-vm - 2025-03-25

- `vm.run` now returns how many results and the remaining values on the stack

## 0.2.4 conch-ui - 2025-03-25

- Append existing startup with how to close the UI
- Add a `close-ui` command  
- Fix UI not closing when pressing the bound key
- Implement optional arguments

## 0.2.1 conch-types 2025-03-29

- Add optional arguments to analysis types

## 0.2.4 conch - 2025-03-25

- When executing a command, automatically log all results into the output
- Implement optional arguments with `conch.args.opt` and `conch.args.optional`

--------------------------------------------------------------------------------

## 0.2.1 conch-compiler - 2025-03-05

### Fixed

- Fix for loops storing values in reverse

## 0.2.3 conch-ui - 2025-03-05

### Fixed

- Fix issue with cursor going behind while typing in immediate mode

## 0.2.3 conch - 2025-03-05

### Added

- Add `conch.on_execution` as a callback that executes after a command completes
- Add `conch.on_command_run` as a callback that executes after a command has been ran. When used on the server, only runs after the client calls a server command.

--------------------------------------------------------------------------------

## 0.2.2 conch & conch-ui - 2025-02-25

### Changes

- Remove patch version specifier from conch-ui startup message

### Fixed

- Fix accidental renaming of `enum_new`

--------------------------------------------------------------------------------

## 0.2.1 conch & conch-ui - 2025-02-25

### Added

- Add replication for the command description from the server

### Fixed

- Fix components not being included inside pesde

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
