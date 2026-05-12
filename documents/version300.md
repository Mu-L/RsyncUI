# Version 3.0.0 planning and codebase verification

Prepared: 2026-05-12

## Scope

This document verifies the current RsyncUI codebase and proposes the next set of updates for version 3.0.0. It builds on:

- `documents/ver293_ver297.md`
- `documents/planned.md`

The review focused on the current SwiftUI application code, Swift concurrency boundaries, storage/log persistence, scheduling, tests, and developer validation commands.

## Verification summary

The project is in a stable post-cleanup state. The major v2.9.x refactors described in `ver293_ver297.md` have mostly landed:

- JSON persistence is now routed through `SharedJSONStorageReader` and `SharedJSONStorageWriter`.
- Log table, chart, and delete behavior now route through `LogStoreService` / `LogChartService`.
- Thin actor wrappers were removed or replaced with intentional actors.
- The app-owned log-file actor is now centralized as `ActorLogToFile.shared`.
- Swift Testing coverage exists for validation, rsync argument generation, deeplinks, log-store behavior, chart reduction, and shared JSON storage.

Validation performed:

- `swift test` was attempted and failed because this checkout has no `Package.swift`.
- `xcodebuild -list -project RsyncUI.xcodeproj` succeeded and confirmed schemes `RsyncUI` and `WidgetEstimateExtension`.
- `xcodebuild test -project RsyncUI.xcodeproj -scheme RsyncUI -destination 'platform=macOS'` succeeded.
- The Xcode test run passed 46 tests in 7 suites.

The main issue is no longer basic correctness. The next version should focus on finishing architectural consolidation so future feature work does not rebuild the same storage, schedule, log, and loading flows in more places.

## Important documentation correction

The old docs should no longer say there is only one executable `Task.detached` site. The current shared JSON storage layer intentionally uses detached tasks internally:

- `RsyncUI/Model/Storage/SharedJSONStorageReader.swift`
- `RsyncUI/Model/Storage/SharedJSONStorageWriter.swift`

That is acceptable because the detached tasks are awaited and used to move blocking file I/O / JSON decoding off the main actor. The correct rule for version 3.0.0 should be:

> Avoid ad hoc fire-and-forget detached persistence. Detached work is acceptable only inside shared infrastructure when its result is awaited and errors propagate.

## Version 3.0.0 goals

Version 3.0.0 should be treated as a maintainability and architecture release, not a broad feature release. The suggested goals are:

1. Finish the remaining cleanup from `planned.md`.
2. Make the validation path accurate and repeatable.
3. Consolidate profile/configuration loading.
4. Complete the log-domain service boundary.
5. Separate scheduling computation, timer orchestration, wake recovery, and persistence.
6. Reduce large SwiftUI and execution types where they still mix state coordination with domain work.
7. Add focused Swift Testing coverage around the remaining shared services before large rewrites.

## Priority 1: Fix developer validation documentation

### Issue

`AGENTS.md` still documents `swift test`, but this repository is an Xcode project checkout and does not include `Package.swift`. Running `swift test` fails immediately.

### Suggested update

Document the real validation command:

```bash
xcodebuild test -project RsyncUI.xcodeproj -scheme RsyncUI -destination 'platform=macOS'
```

Keep `make debug` as the debug app build command, but do not present `swift test` as the primary test command unless a package manifest is added later.

### Motivation

New contributors and automation should run the same validation path that actually exercises the app target, widget dependency, Swift packages, and `RsyncUITests` bundle. Keeping an invalid command in docs wastes time and hides the real Xcode-based dependency graph.

## Priority 2: Create one profile/configuration loading service

### Current state

Configuration loading still appears in multiple entry points:

- `RsyncUI/Main/RsyncUIView.swift`
- `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift`
- `RsyncUI/Views/Configurations/ConfigurationsTableLoadDataView.swift`
- `RsyncUI/Model/Utils/ReadAllTasks.swift`

Each caller now uses the shared JSON reader indirectly, but the application flow still reconstructs profile resolution and configuration loading in several places.

### Suggested update

Add a small `ProfileConfigurationService` or `ConfigurationRepository` that owns:

- resolving profile name from `ProfilesnamesRecord.ID`
- loading one profile
- loading all profiles while preserving profile order
- applying rsync v3 filtering consistently
- returning empty arrays instead of forcing every view to choose its own nil/empty behavior

### Motivation

The existing storage consolidation fixed JSON mechanics, but not the application-level duplication. A shared loader will reduce profile-switch drift between startup, sidebar actions, mounted-volume events, and cross-profile reads.

## Priority 3: Replace sync initializer side effects in process interruption

### Current state

`RsyncUI/Model/Process/InterruptProcess.swift` performs work in an initializer and launches a `Task` to log and interrupt the active process.

### Suggested update

Replace initializer side effects with an explicit async API, for example:

```swift
enum ProcessInterruptService {
    @MainActor
    static func interruptCurrentProcess() async {
        let message = ["Interrupted: " + Date().long_localized_string_from_date()]
        await ActorLogToFile.shared.logOutput("Interrupted", message)
        SharedReference.shared.process?.interrupt()
        SharedReference.shared.process = nil
    }
}
```

Call sites can then use `Task { await ProcessInterruptService.interruptCurrentProcess() }` only where the caller is truly synchronous.

### Motivation

The current initializer hides work and makes ordering hard to see. Version 3.0.0 should continue the v2.9.x direction of replacing constructor side effects with named async operations.

## Priority 4: Complete the log-domain service boundary

### Current state

The read/filter/delete/chart side is much better now, but log-domain work remains split across:

- `LogStoreService`
- `LogChartService`
- `Logging`
- `SnapshotsView`
- `Snapshotlogsandcatalogs`

There is still duplicated log-result number parsing in `Logging` and `LogChartService`.

### Suggested update

Move these into shared log-domain helpers:

- log result parsing
- insert/update/persist log records
- snapshot log merge
- unused-log calculation
- visible-log and chart-entry loading policy

Keep `LogChartReducer` pure. Expand `LogStoreService` or introduce a single `LogRepository` only if the write side becomes too large for the current service.

### Motivation

The v2.9.x cleanup made the log table and chart testable. The remaining risk is write-side drift: scheduled logging, snapshot loading, and chart parsing still know too much about the log string shape. Central parsing and mutation APIs will make future rsync output changes safer.

## Priority 5: Refactor scheduling into separate responsibilities

### Current state

Scheduling still spans:

- `ObservableSchedules`
- `GlobalTimer`
- `ReadSchedule`
- `WriteSchedule`
- schedule SwiftUI views

`ObservableSchedules` computes future dates, mutates global timer state, validates schedule spacing, and bridges callback logging. `GlobalTimer` owns timer execution, wake recovery, missed schedules, and scheduled-profile triggers.

### Suggested update

Split scheduling into these boundaries:

- `SchedulePlanner`: pure future-date generation and validation.
- `ScheduleStore`: read/write schedule JSON through shared storage.
- `ScheduleRunner`: timer setup, callback execution, wake recovery.
- `ObservableSchedules`: thin observable adapter for SwiftUI state.

Add tests for:

- daily, weekly, and once schedule generation
- month-boundary behavior
- wake recovery ordering
- moving missed schedules forward
- duplicate prevention by task identity and scheduled date

### Motivation

Schedules affect unattended execution. Keeping date math, persistence, timer callbacks, and UI observation in the same model makes regressions hard to isolate. A pure planner plus tested runner boundary would make this part of the app much safer.

## Priority 6: Reduce large mixed-responsibility files

### Current hotspots

The largest remaining files are still carrying broad responsibilities:

- `RsyncUI/Model/Execution/EstimateExecute/Execute.swift`
- `RsyncUI/Views/Sidebar/SidebarMainView.swift`
- `RsyncUI/Views/Tasks/LogStatsChartView.swift`
- `RsyncUI/Views/Snapshots/SnapshotsView.swift`
- `RsyncUI/Views/Restore/RestoreTableView.swift`
- `RsyncUI/Views/Configurations/ConfigurationsTableDataMainView.swift`
- `RsyncUI/Model/Global/ObservableSchedules.swift`
- `RsyncUI/Model/Global/GlobalTimer.swift`

### Suggested update

Refactor only after the shared services above exist. Good first slices:

- Move `SnapshotsView.loadSnapshotData(for:)` and delete orchestration into a snapshot service.
- Move chart refresh policy out of `LogStatsChartView` after log service APIs are complete.
- Split `Execute` into process start, streaming callbacks, completion/persistence, and cleanup.
- Keep SwiftUI files focused on state binding, commands, and presentation.

### Motivation

The current large files are readable but fragile because they mix UI state, service calls, persistence, and process control. Splitting before service boundaries exist would only move duplication around; splitting after service boundaries should reduce code.

## Priority 7: Add tests before deeper cleanup

### Existing coverage

Current Swift Testing coverage is useful and passed in Xcode:

- `VerifyConfigurationTests`
- `VerifyConfigurationAdvancedTests`
- `ArgumentsSynchronizeTests`
- `DeeplinkURLTests`
- `LogStoreServiceTests`
- `LogChartReducerTests`
- `SharedJSONStorageTests`

### Suggested tests

Add focused tests for:

- profile/configuration loader behavior
- schedule planner behavior
- log result parsing shared by logging and charts
- snapshot log merge and unused-log calculation
- process interruption service state changes, using a controllable process abstraction if possible
- user settings persistence snapshots

### Motivation

The next cleanup targets touch user-visible workflows: scheduled execution, snapshot management, profile loading, and process interruption. Tests should lock down behavior before the code is moved.

## Priority 8: Clean up project settings drift

### Current state

The main app target uses Swift 6.0, while the test target and widget target still show Swift 5.0 in the Xcode project. The deployment targets also differ between app and tests.

### Suggested update

Review whether the test and widget targets should move to Swift 6 settings. If they cannot yet move, document why.

### Motivation

The app already depends on Swift 6-era concurrency and observation patterns. Project settings should either align or clearly explain why each target differs. This avoids surprising diagnostics when strict concurrency checking changes.

## Suggested version 3.0.0 execution order

1. Update validation documentation and remove the invalid `swift test` instruction.
2. Add tests for log parsing and schedule planning.
3. Extract shared log result parsing.
4. Build a profile/configuration loading service.
5. Replace `InterruptProcess` initializer side effects with a named async service.
6. Split schedule planner/store/runner responsibilities.
7. Move snapshot log assembly out of `SnapshotsView`.
8. Split `Execute.swift` only after completion/logging services are stable.
9. Re-run the Xcode test command and record results in release notes.

## Release-note themes

Version 3.0.0 can be described around these themes:

- More predictable profile loading across startup, sidebar, and mounted-volume flows.
- Better schedule reliability through isolated planning and timer logic.
- Cleaner snapshot/log handling with less duplicated parsing and persistence code.
- More explicit process interruption and execution completion behavior.
- Accurate Xcode-based validation documentation.
- Continued Swift Testing coverage for refactored domain services.

## Non-goals for version 3.0.0

Avoid broad UI redesign or new rsync feature work in the same release unless it is required by the cleanup. The codebase is close to having clean service boundaries; mixing feature expansion with these refactors would make regressions harder to diagnose.

