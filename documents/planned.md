# Planned cleanup

This document consolidates the previous cleanup planning files: `cleanup.md`, `phase1.md`, `phase3.md`, and `phase4.md`.


## Cleanup plan

## Problem statement

RsyncUI has accumulated a mix of custom actors, `Task` usage, `@MainActor` file I/O, duplicated storage helpers, and large view/model types that make the code harder to reason about than necessary. The requested cleanup is to remove unnecessary concurrency machinery, keep concurrency only where it is truly justified, consolidate duplicate code, and simplify complex flows without changing user-visible behavior.

## Current-state findings

### Concurrency and isolation

- The app defines **five custom actors**:
  - `Model/Storage/Actors/ActorLogToFile.swift`
  - `Model/Storage/Actors/ActorReadLogRecordsJSON.swift`
  - `Model/Storage/Actors/ActorLogChartsData.swift`
  - `Model/Output/ActorCreateOutputforView.swift`
  - `Model/Newversion/ActorGetversionofRsyncUI.swift`
- Only the **log-data actors** clearly align with the desired retained-concurrency scope:
  - `ActorLogToFile`
  - `ActorReadLogRecordsJSON`
  - `ActorLogChartsData`
- Two actors are likely unnecessary and should be strong candidates for removal or conversion to plain services:
  - `ActorCreateOutputforView` mostly maps arrays into view models and delegates to other work.
  - `ActorGetversionofRsyncUI` is a thin wrapper around one fetch/filter operation.
- A number of storage helpers are annotated `@MainActor` while performing synchronous file-system work:
  - `ReadSynchronizeConfigurationJSON`
  - `ReadUserConfigurationJSON`
  - `ReadSchedule`
  - `WriteUserConfigurationJSON`
  - `WriteSchedule`
  - `WriteExportConfigurationsJSON`
  - `WriteWidgetsURLStringsJSON`
- `WriteLogRecordsJSON` and `WriteSynchronizeConfigurationJSON` use `Task.detached` fire-and-forget writes. That reduces main-thread blocking, but it also makes persistence ordering and error surfacing harder to reason about.
- `Execute.swift`, `CreateStreamingHandlers.swift`, and several SwiftUI views use many unstructured `Task {}` blocks. Some are appropriate UI/task-bound launches, but others are wrappers around small synchronous operations and should be reviewed for simplification.

### Duplication and structural complexity

- The storage layer repeats the same responsibilities in many places: build path, encode/decode JSON, write/read file, propagate error.
- Duplicate or near-duplicate call flows exist in:
  - startup/profile loading (`RsyncUIView`, `SidebarMainView`, `extensionSidebarMainView`, `ConfigurationsTableLoadDataView`)
  - log record reload/filter/delete (`Logging`, `LogRecordsTabView`, `SnapshotsView`, `ObservableChartData`)
  - export/import/widget/user-config persistence helpers
- Several large hotspot files are carrying mixed responsibilities and should be split or reduced before deeper cleanup:
  - `Model/Execution/EstimateExecute/Execute.swift` (335 lines)
  - `Views/Snapshots/SnapshotsView.swift` (299 lines)
  - `Views/Tasks/LogStatsChartView.swift` (293 lines)
  - `Views/Restore/RestoreTableView.swift` (272 lines)
  - `Views/Sidebar/SidebarMainView.swift` (268 lines)
  - `Model/Global/ObservableSchedules.swift` (263 lines)
  - `Model/Global/GlobalTimer.swift` (258 lines)

### Issues discovered during review

- The repository root contains `RsyncUI.xcodeproj`, but **does not contain `Package.swift`**, so the documented `swift test` command is not valid in this checkout.
- The current architecture documentation says storage runs on actors, but the codebase is already in a mixed state where some storage is actor-based, some is `@MainActor`, and some is detached-task based.
- Configuration/profile loading is implemented in multiple entry points instead of one shared loader, which increases the chance of behavior drift.
- Log filtering/sorting/deletion logic is repeated between inspector and snapshot flows instead of being centralized into one log-data service.

## Proposed approach

1. Establish an explicit concurrency boundary:
   - keep concurrency only where data volume or serialization warrants it
   - remove thin actors and accidental async wrappers
   - preserve necessary async behavior around rsync process streaming and UI lifecycle work
2. Consolidate storage code behind shared read/write helpers before removing wrappers one by one.
3. Centralize log-data operations so the remaining concurrency is concentrated in one place.
4. Refactor large mixed-responsibility types after shared services exist, so simplification reduces code instead of moving duplication around.
5. Update documentation and validation commands to match the actual Xcode-based project layout.

## Todo plan

### Phase 1 - Inventory and safety rails ✅

- ✅ Build a full matrix of (see **Phase 1 inventory and safety rails** below):
  - every actor
  - every `Task {}` / `Task.detached`
  - every `@MainActor` storage/helper type
  - every persistence entry point
- ✅ Classify each item as:
  - keep
  - convert to synchronous service
  - convert to async function without actor
  - centralize behind shared infrastructure
- ✅ Confirm which async paths are mandatory for correctness:
  - rsync process streaming
  - process termination callbacks
  - log-data read/write/sort pipeline
  - any UI-driven debounce/cancellation flows

### Phase 2 - Storage consolidation ✅

- ✅ Introduce a shared storage abstraction for local JSON persistence (`SharedJSONStorageWriter` / `SharedJSONStorageReader`):
  - path building
  - encode/decode
  - file write/read
  - uniform error propagation
- ✅ Migrate these helpers onto the shared storage layer:
  - `ReadSynchronizeConfigurationJSON`
  - `WriteSynchronizeConfigurationJSON`
  - `ReadUserConfigurationJSON`
  - `WriteUserConfigurationJSON`
  - `ReadSchedule`
  - `WriteSchedule`
  - import/export/widget persistence helpers
- ✅ Remove duplicated filename/path creation logic from individual helpers.
- ✅ Decide case-by-case whether the remaining API should be plain sync or async, but avoid detached fire-and-forget persistence unless it is explicitly needed.

### Phase 3 - Concurrency cleanup 🟡 Partial

- ✅ Keep and harden log-data concurrency (now reduced to a single app-owned domain actor — `ActorLogToFile` — alongside the shared JSON read/write singletons; `ActorLogChartsData` was removed in favour of `LogChartService`, and `ActorReadLogRecords` was inlined into `LogStoreService.loadStore` and deleted in `c6bda5c0`):
  - `ActorLogToFile` (singleton)
  - `ActorReadLogRecordsJSON` *(removed; succeeded by `ActorReadLogRecords`, now also removed)*
  - `ActorLogChartsData` *(removed)*
- ✅ Review whether each retained actor really needs actor isolation or whether one log-data service actor is enough.
- ✅ Remove or replace thin actors:
  - `ActorCreateOutputforView` *(replaced by plain helper `CreateOutputforView`)*
  - `ActorGetversionofRsyncUI` *(replaced by plain helper, then re-promoted to a deliberate actor singleton `GetversionofRsyncUI.shared` with a per-session cache in `c6bda5c0` to coalesce the remote JSON fetch across views)*
- 🟡 Reduce unstructured `Task` usage in views and models where the work is:
  - immediate
  - non-cancellable
  - already on the main actor
  - simple synchronous mapping
- ✅ Replace ad hoc `Task.detached` writes with structured persistence where possible.

### Phase 4 - Log-data service unification 🟡 Partial

- 🟡 Create one shared log-data domain service responsible for (`LogStoreService` and `LogChartService` cover most of these; snapshot merge still outside):
  - load
  - filter
  - sort
  - merge
  - delete
  - persist
  - chart preparation
- 🟡 Move duplicate logic out of:
  - `Logging`
  - `LogRecordsTabView`
  - `SnapshotsView`
  - `ObservableChartData`
  - `LogStatsChartView`
- 🟡 Keep UI views focused on state and presentation instead of storage mutations and log transforms.

### Phase 5 - High-value structural refactors 🟡 Partial

- 🟡 Split `Execute.swift` into smaller components (`Execute.start(...)`, `releaseStreamingReferences()`, `completeExecution()` landed; broader split still pending):
  - task queue/stack orchestration
  - process start
  - termination handling
  - log/config persistence
- ❌ Simplify schedule handling by separating:
  - schedule generation
  - timer orchestration
  - wake recovery
  - persistence
- 🟡 Reduce duplication in profile/configuration loading across:
  - `RsyncUIView`
  - `SidebarMainView`
  - `extensionSidebarMainView`
  - `ConfigurationsTableLoadDataView`
- ❌ Extract reusable helpers from large SwiftUI views where code is mixing state coordination with data access.

### Phase 6 - Validation and documentation 🟡 Partial

- 🟡 Run the real Xcode-based validation path for the repo and record the correct commands in docs.
- ✅ Update `CLAUDE.md` or other directly relevant documentation so it matches the actual project/test setup and the new storage/concurrency architecture.
- ✅ Add or update tests around refactored log-data and configuration-loading behavior before large removals of duplication (`LogStoreServiceTests`, `LogChartReducerTests`, `SharedJSONStorageTests` added).

## Recommended execution order

1. Inventory and classify concurrency/storage usage.
2. Consolidate storage helpers.
3. Unify log-data service.
4. Remove thin actors and simplify `Task` usage.
5. Refactor `Execute`, scheduling, and profile-loading hotspots.
6. Refresh validation/docs.

## Risks and considerations

- The rsync execution and streaming pipeline should not be simplified blindly; some async behavior is essential even if the app-owned actor count is reduced.
- Removing detached persistence without replacing it carefully may expose UI blocking or ordering assumptions that are currently hidden.
- Centralizing storage and log-data code first should reduce risk because later cleanups can become mostly mechanical call-site updates.
- Scope is limited to code in this repository, including local app targets such as the main app, widget, tests, and XPC code when touched by the cleanup. External rsyncOSX packages are out of scope for this plan.


## Phase 1 inventory and safety rails

This section expands the cleanup plan's Phase 1 with a concrete inventory of the current concurrency and persistence boundaries. The goal of Phase 1 is not to change behavior yet, but to map exactly **what must stay async**, **what should stop being actor-isolated**, and **where later refactors should land**.

## 1. Current-state summary

- ✅ **1A. Actor ownership inventory:** Only one app-owned domain actor remains:
  - `RsyncUI/Model/Storage/Actors/ActorLogToFile.swift:23`
  - (`ActorReadLogRecords` was inlined into `LogStoreService.loadStore` and deleted in `c6bda5c0`. Two new actor singletons exist outside this directory: `RsyncUI/Model/Storage/SharedJSONStorageReader.swift` and `RsyncUI/Model/Storage/SharedJSONStorageWriter.swift` provide the shared JSON read/write boundary, and `GetversionofRsyncUI` was promoted to an actor singleton with a per-session cache in `c6bda5c0`.)
- ✅ **1B. Thin actor removal:** Thin actor removals already landed:
  - `RsyncUI/Model/Output/CreateOutputforView.swift:10`
  - `RsyncUI/Model/Newversion/GetversionofRsyncUI.swift:11`
- ✅ **1D. Explicit detached exception:** The only executable `Task.detached` site is:
  - `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift:92-95`
- ✅ **1C. Detached JSON writes:** The shared async JSON write boundary already exists:
  - `RsyncUI/Model/Storage/SharedJSONStorageWriter.swift:9-18`
  - `RsyncUI/Model/Storage/WriteSynchronizeConfigurationJSON.swift:12-38`
  - `RsyncUI/Model/Storage/WriteLogRecordsJSON.swift:12-38`
- ✅ **1E. Async caller propagation:** The storage layer is now split across:
  - `@MainActor` read/write helpers that still build paths and encode/decode
  - actor-based log persistence and logfile serialization
  - one shared awaited JSON writer for configuration/log-store writes
- Profile/configuration loading is duplicated across:
  - `RsyncUI/Main/RsyncUIView.swift:52-74`
  - `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift:157-179`
  - `RsyncUI/Views/Configurations/ConfigurationsTableLoadDataView.swift:61-81`
  - `RsyncUI/Model/Utils/ReadAllTasks.swift:13-82` *(now parallelized via `withTaskGroup` with indexed gathering — `c6bda5c0` / `d2e91a31`; each loop still calls `ReadSynchronizeConfigurationJSON` once per profile, so the shared profile/config-loader refactor target is unchanged)*
- Phase 4 groundwork already exists:
  - `RsyncUI/Model/Loggdata/LogStoreService.swift:10-32`
  - `hiddenIDs`, `hiddenID(for:)`, and `backupID(for:)` are already centralized there.

🟡 **1F. Post-removal adapter cleanup (Partial):** The actor removals are landed, but several downstream `Task` bridges that call `CreateOutputforView` still remain and are cataloged below in the task inventory and refactor seams.

## 2. Actor matrix

| Type | Current location | What it owns today | Status | Notes |
|---|---|---|---|---|
| `ActorLogToFile` | `RsyncUI/Model/Storage/Actors/ActorLogToFile.swift:23-150` | Cached `Homepath`, serialized logfile append/read/reset, file-size checks, error propagation | ✅ | This is the intended serialized logfile boundary, now exposed as `ActorLogToFile.shared` with a private `init()`. All call sites (`Execute`, `Estimate`, `SshKeys`, `ObservableSchedules`, `InterruptProcess`, `LogfileView`, `CreateOutputforView`) route through the singleton, so reads and writes serialize against one actor instance. |
| `ActorReadLogRecords` | *(removed)* | Previously read persisted log JSON and filtered by valid IDs | ✅ | Inlined into `LogStoreService.loadStore` in `c6bda5c0`; the file was deleted. Decode is owned by `SharedJSONStorageReader.shared`; the post-decode `validHiddenIDs` filter and path construction now live directly in `LogStoreService`. |
| `ActorCreateOutputforView` | `RsyncUI/Model/Output/CreateOutputforView.swift:10-57` | Replaced by a plain helper that maps rsync/logfile output into view models and still delegates logfile reads to `ActorLogToFile` | ✅ | The actor was removed. Remaining follow-up work is downstream task-adapter cleanup in views/models that still call the helper asynchronously. |
| `ActorGetversionofRsyncUI` | `RsyncUI/Model/Newversion/GetversionofRsyncUI.swift:11-52` | Now an actor singleton (`GetversionofRsyncUI.shared`) with a per-session `cached: [VersionsofRsyncUI]?` field; `getversionsofrsyncui()` and `downloadlinkofrsyncui()` both consult `matchingVersions()`, which fetches once and caches on success | ✅ | `c6bda5c0` re-introduced the actor boundary deliberately to coalesce the remote JSON fetch across `SidebarMainView` and `AboutView`. Both call sites now use `.shared`. |

## 3. `Task.detached` matrix

| Location | Current status | Verification | Notes |
|---|---|---|---|
| `RsyncUI/Model/Storage/WriteSynchronizeConfigurationJSON.swift` | ✅ | `WriteSynchronizeConfigurationJSON.write(...)` now awaits `SharedJSONStorageWriter.shared.write(...)`; no `Task.detached` remains in the file. | The detached configuration write is removed. Ordering and error propagation now flow through an explicit async boundary. |
| `RsyncUI/Model/Storage/WriteLogRecordsJSON.swift` | ✅ | `WriteLogRecordsJSON.write(...)` now awaits `SharedJSONStorageWriter.shared.write(...)`; no `Task.detached` remains in the file. | The detached log-store write is removed for the same reason as configuration writes. |
| `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift:92-95` | ✅ | Repository-wide search shows this is now the only executable `Task.detached` site. | This remains the documented exception because it intentionally sheds main-actor isolation for the debug-only threading assertion. |

Phase 1 landing for the first two rows is complete: both JSON writes route through one shared actor-backed file writer, path building and encoding stay on the main actor, and `WriteSynchronizeConfigurationJSON.write` / `WriteLogRecordsJSON.write` are the awaited entry points. Sync UI actions may still bridge with `Task`, but persistence itself is no longer fire-and-forget detached work.

This means both **1C** ✅ and **1D** ✅ are landed in the detailed matrix above.

## 4. `@MainActor` storage and helper types

These are the main-actor boundaries that most directly shape later cleanup work.

| Type | Location | Why it matters in Phase 1 | Classification | Where to refactor |
|---|---|---|---|---|
| `Homepath` | `RsyncUI/Model/FilesAndCatalogs/Homepath.swift:18-120` | Path creation, root directory creation, and error propagation are central to every persistence helper | **Centralize first** | Shared storage work should start here, because almost every read/write helper rebuilds paths from `Homepath`. |
| `ReadSynchronizeConfigurationJSON` | `RsyncUI/Model/Storage/ReadSynchronizeConfigurationJSON.swift:12-51` | Main configuration read path, reused in several loaders | **Centralize behind storage infrastructure** | Refactor into a shared JSON reader plus task-specific decode/filter logic. |
| `WriteSynchronizeConfigurationJSON` | `RsyncUI/Model/Storage/WriteSynchronizeConfigurationJSON.swift:12-38` | Main configuration write path, now routed through the shared awaited writer | **Centralize behind storage infrastructure** | The detached initializer side effect is gone; the remaining Phase 2 work is moving more JSON path/encode logic behind the same shared storage layer. |
| `ReadUserConfigurationJSON` | `RsyncUI/Model/Storage/Userconfiguration/ReadUserConfigurationJSON.swift:12-35` | Reads user config and mutates `UserConfiguration` side effects | **Centralize** | ✅ Done. Decode and apply are now separate: `UserConfiguration(_ data:)` only populates fields; the caller invokes `.setuserconfigdata()` to mutate `SharedReference.shared`. |
| `WriteUserConfigurationJSON` | `RsyncUI/Model/Storage/Userconfiguration/WriteUserConfigurationJSON.swift:12-50` | Direct sync write on main actor | **Centralize** | Move path building, encoding, and write into shared storage helpers. |
| `ReadSchedule` | `RsyncUI/Model/Storage/ReadSchedule.swift:12-48` | Reads schedule JSON and filters invalid/expired rows | **Centralize** | Keep schedule-specific filtering, but move decode/path logic into shared storage. |
| `WriteSchedule` | `RsyncUI/Model/Storage/WriteSchedule.swift:8-44` | Direct sync write on main actor | **Centralize** | Same shared write layer as other JSON persistence. |
| `ReadImportConfigurationsJSON` | `RsyncUI/Model/Storage/ExportImport/ReadImportConfigurationsJSON.swift:12-45` | Decodes import file and rewrites IDs in one object | **Convert to helper over shared storage** | Keep ID-rewrite logic, remove dedicated storage wrapper. |
| `WriteExportConfigurationsJSON` | `RsyncUI/Model/Storage/ExportImport/WriteExportConfigurationsJSON.swift:12-62` | Encodes and writes export bundle directly on main actor | **Convert to helper over shared storage** | Shared JSON export writer should own encode/write; export service should own only export-specific decisions. |
| `WriteWidgetsURLStringsJSON` | `RsyncUI/Model/Storage/Widgets/WriteWidgetsURLStringsJSON.swift:13-61` | Writes widget URL strings to the widget container and validates deeplinks | **Split responsibilities** | Keep deeplink validation, but move encode/write path logic into shared storage infrastructure. |
| `ReadAllTasks` | `RsyncUI/Model/Utils/ReadAllTasks.swift:11-82` | Repeats configuration loading across every profile (now in parallel) | **Centralize** | `c6bda5c0` / `d2e91a31` parallelized both loops via `withTaskGroup` with indexed gathering that preserves input profile order. The remaining target is still a shared profile/config loader so the per-profile read isn't reconstructed in two places. |
| `UpdateConfigurations` | `RsyncUI/Model/Storage/Basic/UpdateConfigurations.swift:10-172` | Mutates configurations in memory and persists them immediately | **Keep temporarily, then shrink** | Once writes are centralized, this should become an in-memory mutation helper or a service method, not a persistence owner. |
| `Logging` | `RsyncUI/Model/Loggdata/Logging.swift:16-170` | Mixes config date stamping, log formatting, log insertion, snapshot numbering, and persistence | **Centralize behind log-data service** | This is a major later refactor target because it still owns both domain logic and persistence side effects. |

### Supporting model annotations that currently force main-actor storage paths

- `RsyncUI/Model/Storage/Basic/UserConfiguration.swift:10-11`
- `RsyncUI/Model/Storage/Basic/WidgetURLstrings.swift:10-11`

Both models are `@MainActor Codable`, which means Phase 2 must review whether the model isolation is intentional or whether the storage layer is carrying unnecessary main-actor constraints upward into encoding and decoding.

## 5. Persistence entry points and duplicate call paths

| Responsibility | Entry point | Current callers that reveal duplication | Refactor target |
|---|---|---|---|
| Read task configurations | `ReadSynchronizeConfigurationJSON.readjsonfilesynchronizeconfigurations` | `RsyncUIView.swift:71-73`, `extensionSidebarMainView.swift:170-172`, `ConfigurationsTableLoadDataView.swift:66-79`, `ReadAllTasks.swift:22` and `62` (both inside `withTaskGroup` child tasks) | One shared profile/config loader used by startup, profile switching, and cross-profile scans |
| Write task configurations | `WriteSynchronizeConfigurationJSON.write` | `Logging.swift`, `UpdateConfigurations.swift`, `ConfigurationsTableDataMainView.swift` | Shared async storage writer with explicit await |
| Read user configuration | `ReadUserConfigurationJSON.readuserconfiguration` | `RsyncUIView.swift:40-51` | ✅ Done — load and apply are now separate steps; the read helper calls `UserConfiguration(_ data:).setuserconfigdata()` explicitly. |
| Write user configuration | `WriteUserConfigurationJSON.init` | `Environmentsettings.swift:16`, `Logsettings.swift:20`, `RsyncandPathsettings.swift:16`, `Sshsettings.swift:18` | Shared settings persistence helper |
| Read schedules | `ReadSchedule.readjsonfilecalendar` | `SidebarMainView.swift:117-120` | Shared schedule repository / loader |
| Write schedules | `WriteSchedule.init` | `AddSchedule.swift:88`, `CalendarMonthView.swift:77` | Shared schedule repository / writer |
| Read log store | `LogStoreService.loadStore` (inlined path/decode/filter — no longer wraps an actor since `c6bda5c0`; decode is owned by `SharedJSONStorageReader.shared`) | `Logging.swift:27-30`, `LogRecordsTabView.swift:156-160` and `183-187`, `SnapshotsView.swift:217-223` | One log-data service / repository |
| Write log store | `WriteLogRecordsJSON.write` | `Logging.swift`, `LogRecordsTabView.swift`, `SnapshotsView.swift` | Same log-data service actor / repository |
| Import configurations | `ReadImportConfigurationsJSON.init` | `ImportView.swift:125` | Import service over shared JSON storage |
| Export configurations | `WriteExportConfigurationsJSON.init` | `ExportView.swift:72` | Export service over shared JSON storage |
| Widget deeplink persistence | `WriteWidgetsURLStringsJSON.init` | `extensionAddTaskView.swift:49` | Widget settings writer over shared JSON storage |

## 6. Task inventory: what must stay async vs what should be simplified

### A. Task sites that are justified by correctness

| File and lines | Why it exists | Classification | Refactor note |
|---|---|---|---|
| `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift:34-36`, `70-72` | Hops streaming callback errors back to main-actor alert state | **Keep** | Could disappear only if the callback type itself becomes main-actor isolated. |
| `RsyncUI/Model/Execution/EstimateExecute/Estimate.swift:162-204` | Continues estimation flow after async output mapping from a termination callback | **Keep for now** | Later convert the termination pipeline itself into an async function so the callback does not need to spawn a task. |
| `RsyncUI/Model/Execution/EstimateExecute/Execute.swift:65-68`, `250-269`, `307-323` | Bridges rsync termination callbacks into async logging and persistence completion work | **Keep for now** | These are mandatory async boundaries today because process termination callbacks are synchronous. |
| `RsyncUI/Model/Global/GlobalTimer.swift:156-158`, `211-213` | Bridges `Timer` and workspace wake notifications back into main-actor schedule state | **Keep** | This is a legitimate sync-callback to async/main-actor bridge. |
| `RsyncUI/Model/Global/ObservableSchedules.swift:188-192` | Logs schedule execution asynchronously from a schedule callback | **Keep** | Safe to keep until logfile writes are fully centralized. |
| `RsyncUI/Views/Restore/RestoreTableView.swift:51-59` | Debounced restore filtering with cancellation | **Keep** | This is a valid UI debounce/cancellation pattern. |
| `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:84-94` | Debounced log filtering and profile reload cancellation | **Keep** | Good candidate for a reusable debouncer later, but the async behavior is required. |
| `RsyncUI/Views/Configurations/ListofTasksMainView.swift:63-75` | Debounced multi-select filter behavior | **Keep** | UI debounce task is acceptable. |
| `RsyncUI/Views/Sidebar/SidebarStatusMessagesView.swift:22-25`, `38-41` | Auto-dismiss transient UI notices | **Keep** | Simple delay task; not a concurrency problem. |
| `RsyncUI/Views/Quicktask/QuicktaskFormView.swift:35-41` | Delay before clearing fields after task-type change | **Keep** | Another valid UI delay task. |
| `RsyncUI/Views/Modifiers/ButtonStyles.swift:143-146` | Press-animation hold duration | **Keep** | Pure UI timing task. |
| `RsyncUI/Views/Tasks/CompletedView.swift:31-34` | One-second completion banner timeout | **Keep** | Pure UI timing task. |
| `RsyncUI/Views/Detailsview/SummarizedDetailsContentView.swift:173-176` | Delayed clearing of preselected task state | **Keep** | Pure UI timing task. |

### B. Task sites that are mostly sync-to-async adapters and should shrink later

This section is where **1F** remains **partially done**: the thin actors are gone, but these adapter-style `Task` bridges still need cleanup.

| File and lines | What the task is compensating for | Classification | Where to refactor |
|---|---|---|---|
| `RsyncUI/Model/Process/InterruptProcess.swift:12-17` | Sync initializer uses `Task` only to log through `ActorLogToFile` before interrupting process state | **Convert** | Make interruption an explicit async function or hide logfile write inside a dedicated interruption service. |
| `RsyncUI/Model/Global/SharedReference.swift:111-114` | Delayed kill after `terminate()` | **Keep but isolate** | This is valid process-control timing, but it should live in a clearly named async termination helper instead of inline task creation. |
| `RsyncUI/Model/Global/ObservableRestore.swift:36-39` | Async output mapping after restore completes | **Convert** | `CreateOutputforView` is already a plain helper, so this is now a downstream adapter-cleanup task rather than an actor-removal dependency. |
| `RsyncUI/Views/Restore/RestoreTableView.swift:191-196` | Async output mapping inside a main-actor view callback | **Convert** | Same post-actor-removal cleanup target. |
| `RsyncUI/Views/Detailsview/OneTaskDetailsView.swift:154-173` | Async output mapping for presented estimate results | **Convert** | Remove the actor wrapper and call helper directly. |
| `RsyncUI/Views/InspectorViews/VerifyTask/VerifyTaskTabView.swift:170-173` | Async output mapping for verify results | **Convert** | Same output-helper cleanup. |
| `RsyncUI/Views/Quicktask/extensionQuickTaskView.swift:120-138` | Main-actor UI updates after async output conversion and progress updates | **Convert** | Output conversion should stop requiring actor hops. |
| `RsyncUI/Views/LogView/LogfileView.swift:44-47` | Sync button action wraps async logfile reset/read | **Convert partly** | Keep logfile read async, but remove the extra output-conversion actor layer. |
| `RsyncUI/Views/Configurations/ConfigurationsTableLoadDataView.swift:71-80` | `onChange` creates a task to re-read configurations | **Convert** | Replace with `.task(id:)` only, or centralize profile loading so both `.task(id:)` and `onChange` are not needed. |
| `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift:63-83` | External deeplink flows launch tasks to await profile loading before navigation | **Convert later** | Move profile-loading flow into one async API instead of inline task creation. |
| `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift:94-112` | Workspace mount/unmount notification closures create tasks to await profile reload checks | **Keep for callback bridge, but centralize** | The async bridge is valid; the duplicated load/check logic should move into one notification handler service. |
| `RsyncUI/Views/Snapshots/SnapshotsView.swift:216-224` | Snapshot/log merge is launched from a sync view method | **Convert later** | Prefer `.task(id:)` or one async `loadSnapshotData` entry point owned by the snapshot model/service. |
| `RsyncUI/Views/Snapshots/SnapshotsView.swift:269-271` | Two-second delay after updating snapshot plan, with no follow-up work | **Remove** | This task currently does not protect any real async dependency. |
| `RsyncUI/Views/Snapshots/SnapshotsView.swift:275-289` | Sync delete action wraps async log-store deletion | **Convert** | Once log-data persistence is unified, this becomes one awaited service call. |
| `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:53-56` | Delete action wraps async log-store deletion | **Convert** | Same future log-data service boundary as `SnapshotsView`. |
| `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:192-198` | Selection changes launch a task only to call actor filter/update methods | **Convert** | Removing actor ownership from pure filtering will make this synchronous again. |
| `RsyncUI/Views/Settings/Sshsettings.swift:82-86` | Delay before re-reading generated SSH keys | **Keep if UX needs the delay, otherwise convert** | Prefer an explicit async key-generation result instead of polling after sleep if possible. |

## 7. Mandatory async paths to preserve while refactoring

These are the safety rails for later phases. If any of these are removed too early, cleanup will likely change behavior.

1. **Rsync process streaming and termination callbacks**
   - `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift`
   - `RsyncUI/Model/Execution/EstimateExecute/Estimate.swift`
   - `RsyncUI/Model/Execution/EstimateExecute/Execute.swift`
   - `RsyncUI/Views/Restore/RestoreTableView.swift:218-230`

2. **Process termination / interrupt timing**
   - `RsyncUI/Model/Global/SharedReference.swift:103-116`
   - `RsyncUI/Model/Process/InterruptProcess.swift:8-19`

3. **Log-data read/write serialization**
   - `RsyncUI/Model/Storage/Actors/ActorLogToFile.swift` (singleton)
   - `RsyncUI/Model/Loggdata/LogStoreService.swift` (read path; was `ActorReadLogRecords` until `c6bda5c0`)
   - `RsyncUI/Model/Storage/WriteLogRecordsJSON.swift`
   - `RsyncUI/Model/Loggdata/Logging.swift`

4. **UI debounce and cancellation flows**
   - `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift`
   - `RsyncUI/Views/Restore/RestoreTableView.swift`
   - `RsyncUI/Views/Configurations/ListofTasksMainView.swift`
   - `RsyncUI/Views/Sidebar/SidebarStatusMessagesView.swift`
   - `RsyncUI/Views/Quicktask/QuicktaskFormView.swift`
   - `RsyncUI/Views/Modifiers/ButtonStyles.swift`

5. **Timer and workspace-notification bridges**
   - `RsyncUI/Model/Global/GlobalTimer.swift`
   - `RsyncUI/Model/Global/ObservableSchedules.swift`
   - `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift:86-153`

## 8. Highest-value refactor seams for Phase 2 and Phase 3

1. **Shared JSON storage layer**
   - Start at `Homepath.swift`
   - Replace duplicated encode/decode/path/write code in:
     - `ReadSynchronizeConfigurationJSON.swift`
     - `WriteSynchronizeConfigurationJSON.swift`
     - `ReadUserConfigurationJSON.swift`
     - `WriteUserConfigurationJSON.swift`
     - `ReadSchedule.swift`
     - `WriteSchedule.swift`
     - `ReadImportConfigurationsJSON.swift`
     - `WriteExportConfigurationsJSON.swift`
     - `WriteWidgetsURLStringsJSON.swift`

2. **Post-removal adapter cleanup**
   - `CreateOutputforView.swift` and `GetversionofRsyncUI.swift` are already plain helpers.
   - The remaining work is simplifying task adapters in:
     - `OneTaskDetailsView.swift`
     - `VerifyTaskTabView.swift`
     - `ObservableRestore.swift`
     - `LogfileView.swift`
     - `extensionQuickTaskView.swift`

3. **Profile/configuration loader unification**
   - Consolidate read paths in:
     - `RsyncUIView.swift`
     - `extensionSidebarMainView.swift`
     - `ConfigurationsTableLoadDataView.swift`
     - `ReadAllTasks.swift`

4. **Log-data service completion**
   - Finish moving view-owned log mutations out of:
     - `LogRecordsTabView.swift`
     - `SnapshotsView.swift`
     - `Logging.swift`
   - Use `LogStoreService.swift` as the current destination instead of introducing a second parallel log abstraction.

## 9. Phase 1 checkpoints

- There is a documented owner for every actor.
- Every executable `Task.detached` site is either removed or explicitly justified.
- Every storage read/write path is mapped to one later shared storage API.
- Every `Task {}` site is classified as:
  - required callback bridge
  - valid UI debounce/delay
  - temporary sync-to-async adapter
  - removable
- No later phase should introduce a second configuration loader or a second log-data service while these inventories still point to existing shared seams.

The first three execution edits from this file are now landed:

1. ✅ `GetversionofRsyncUI` is a plain async service,
2. ✅ `CreateOutputforView` is a plain helper instead of an actor, and
3. ✅ `WriteSynchronizeConfigurationJSON` / `WriteLogRecordsJSON` now write through one awaited shared storage writer.


## Phase 3 concurrency cleanup

This section expands the cleanup plan's Phase 3 with current progress from the codebase and recent git history. The goal of Phase 3 is to remove accidental concurrency, keep only correctness-critical async boundaries, and reduce the log-data pipeline to a smaller set of actors and helpers that are easier to reason about.

## 1. Current-state summary

- ✅ **3A. Log-data actor reduction:** the original cleanup plan kept three log-data actors: `ActorLogToFile`, `ActorReadLogRecordsJSON`, and `ActorLogChartsData`. The intermediate state had two (`ActorLogToFile.swift` and `ActorReadLogRecords.swift`); after `c6bda5c0` the read wrapper was inlined into `LogStoreService.loadStore` and deleted, so only `ActorLogToFile.swift` remains as an app-owned domain actor. Chart preparation lives in `LogChartService` / `LogStoreService`, SwiftUI views call `LogStoreService` only, and the actual JSON decode is owned by `SharedJSONStorageReader.shared`.
- ✅ **3B. Thin actor removal:** `ActorCreateOutputforView` was replaced by the plain helper `CreateOutputforView.swift`. `ActorGetversionofRsyncUI` first became the plain helper `GetversionofRsyncUI.swift`, then in `c6bda5c0` was promoted to an actor singleton (`GetversionofRsyncUI.shared`) with a per-session cache to coalesce the remote JSON fetch across `SidebarMainView` and `AboutView`.
- ✅ **3C. Detached persistence replacement:** `WriteSynchronizeConfigurationJSON.write(...)` and `WriteLogRecordsJSON.write(...)` now await `SharedJSONStorageWriter.shared.write(...)` instead of launching detached fire-and-forget writes.
- 🟡 **3D. Unstructured `Task` cleanup (Partial):** current search now finds 50 `Task {}` sites. The first downstream cleanup slice landed: pure `CreateOutputforView` mapping calls in quick task, verify/details, restore-after-execute, logfile reload, and estimate flows no longer need adapter-style helper tasks. Several valid callback bridges, debounce flows, and UI timing delays still remain, along with a smaller set of view-owned orchestration tasks.
- 🟡 **3E. Single log-data boundary review (Partial):** chart loading is centralized behind `LogStoreService.chartEntries(...)`, log filtering/delete/selection resolve through `LogStoreService`, and snapshot loading now funnels through one `loadSnapshotData(for:)` entry point in `SnapshotsView`. Snapshot assembly and some write-side log-domain work are still split between `LogStoreService`, `Logging`, `SnapshotsView`, and snapshot helpers.

## 2. Git-backed cleanup matrix

| Area | Current location / git evidence | Status | Notes |
|---|---|---|---|
| 3A. Log-data actor reduction | `3960220e` deleted `ActorLogChartsData.swift` and replaced `ActorReadLogRecordsJSON.swift` with `ActorReadLogRecords.swift`; `7ce54ce1` deleted `ObservableChartData.swift` and added `LogChartService.swift`; `c6bda5c0` inlined `ActorReadLogRecords` into `LogStoreService.loadStore` and deleted the actor file | ✅ | Only `ActorLogToFile.swift` remains as an app-owned log-domain actor. Views call `LogStoreService`; decode is owned by `SharedJSONStorageReader.shared`. |
| 3B. Thin actor removal | `a51d53cf` renamed `ActorCreateOutputforView.swift` to `CreateOutputforView.swift`; `2db9ac26` renamed `ActorGetversionofRsyncUI.swift` to `GetversionofRsyncUI.swift`; `c6bda5c0` promoted `GetversionofRsyncUI` back to an actor singleton (`.shared`) for cross-view fetch coalescing | ✅ | The original "wrapper actor with no isolation value" is gone. The current actor exists deliberately to cache the remote JSON across `SidebarMainView` and `AboutView`. |
| 3C. Detached persistence replacement | `d35aac7f` started logfile concurrency cleanup; `e7830374` added `SharedJSONStorageWriter.swift` and updated both JSON writers | ✅ | Detached persistence is removed from configuration and log-store writes. |
| 3D. Unstructured `Task` cleanup | Current search shows 50 `Task {}` sites; `ActorReadLogRecords(...)` call sites are 0 (actor deleted in `c6bda5c0`); 7 `CreateOutputforView()` call sites; `GetversionofRsyncUI` call sites now use `.shared` | 🟡 Partial | The first adapter-cleanup slice is landed and the read wrapper is gone, but several orchestration and sync-entry wrapper tasks remain. |
| 3E. Single log-data boundary review | `LogStoreService.swift`, `LogChartService.swift`, `LogRecordsTabView.swift:140-204`, `SnapshotsView.swift:192-280` | 🟡 Partial | Chart entry creation is centralized, delete/filter/select flows live behind `LogStoreService`, and snapshot reload now goes through `loadSnapshotData(for:)`, but snapshot assembly is still initiated from the view and write-side log-domain work is still split. |

## 3. Detailed cleanup areas

### A. Log-data actor reduction ✅

The original Phase 3 plan kept three log-data actors. Current git updates already removed one actor layer and collapsed another:

- `3960220e` deleted `ActorLogChartsData.swift`.
- `3960220e` also replaced `ActorReadLogRecordsJSON.swift` with `ActorReadLogRecords.swift`.
- `7ce54ce1` deleted `ObservableChartData.swift` and introduced `LogChartService.swift`, moving chart preparation into pure reducers behind `LogStoreService.chartEntries(...)`.
- `c6bda5c0` inlined `ActorReadLogRecords.readjsonfilelogrecords(...)` into `LogStoreService.loadStore(...)` and deleted `ActorReadLogRecords.swift`. Path construction and the post-decode `validHiddenIDs` filter now live directly in `LogStoreService`; the decode itself is owned by `SharedJSONStorageReader.shared`.

This item is ✅ for Phase 3A: the actor surface is smaller, chart preparation is no longer actor-owned, and the remaining actor is no longer called directly from SwiftUI views for selection/filter/delete work.

What is already cleaner:

- `ActorLogToFile` is the serialized logfile boundary for execution logging, schedule logging, SSH key logging, and logfile reset/read. It is now a singleton (`ActorLogToFile.shared`, with a private `init()`), so all callers serialize against one actor instance — previously each call site allocated its own `ActorLogToFile()`, which meant concurrent writes did not actor-isolate against each other.
- `LogStoreService.loadStore(...)` is now the shared read entry point for persisted log records.
- `LogStoreService.visibleLogs(...)` now owns selection, merge, sort, and filter work for log presentation.
- `LogStoreService.deleteLogs(...)` now owns delete-and-persist orchestration for log-store mutations.
- `LogStoreService.chartEntries(...)` resolves chart data through `LogChartReducer` without reintroducing a chart actor.
- `ActorReadLogRecords` was deleted in `c6bda5c0`; `LogStoreService.loadStore(...)` now does path construction + decode (via `SharedJSONStorageReader.shared`) + the `validHiddenIDs` filter directly, with no wrapper actor in between.

What still remains after 3A:

- `SnapshotsView.getData()` still launches a view-owned `Task {}`, but it now funnels through `loadSnapshotData(for:)` instead of inlining both `LogStoreService.loadStore(...)` and `Snapshotlogsandcatalogs(...)` in the view body.
- `Logging` still owns store mutation for scheduled log insertion instead of sharing a fuller write-side service API.
- Snapshot-specific merge and "unused log" calculations still live outside `LogStoreService`.

### B. Thin actor removal ✅

The cleanup plan called for removing or replacing `ActorCreateOutputforView` and `ActorGetversionofRsyncUI`.

Git shows the actor wrappers were replaced in place:

- `a51d53cf` renamed `ActorCreateOutputforView.swift` to `CreateOutputforView.swift`.
- `2db9ac26` renamed `ActorGetversionofRsyncUI.swift` to `GetversionofRsyncUI.swift`.

Current replacements:

- `CreateOutputforView.swift` is now a plain helper struct. The pure output-mapping helpers are synchronous, while the logfile and restore-list helpers stay async where they still cross storage or trimming boundaries.
- `GetversionofRsyncUI.swift` is now an actor singleton (`GetversionofRsyncUI.shared`) with a per-session cache of matching versions; `getversionsofrsyncui()` and `downloadlinkofrsyncui()` both consult the cache so the remote JSON is fetched at most once per session (`c6bda5c0`).

Current direct helper use shows the actor removal is landed:

- `Estimate.swift`, `ObservableRestore.swift`, `OneTaskDetailsView.swift`, `VerifyTaskTabView.swift`, `RestoreTableView.swift`, `extensionQuickTaskView.swift`, and `LogfileView.swift` all still call `CreateOutputforView()` directly, but the pure-mapping call sites no longer need `await`.
- `SidebarMainView.swift:164` and `AboutView.swift:148` both call `GetversionofRsyncUI.shared`.

The remaining work here is the smaller set of true async helper/service entry points, not bringing the actors back.

### C. Detached persistence replacement ✅

The detached-write part of the old concurrency model is already removed.

Recent history and current code line up:

- `d35aac7f` started the logfile/concurrency write cleanup.
- `e7830374` introduced `SharedJSONStorageWriter.swift`.
- `WriteSynchronizeConfigurationJSON.swift:12-38` now encodes data and awaits `SharedJSONStorageWriter.shared.write(...)`.
- `WriteLogRecordsJSON.swift:12-38` now does the same for log-store writes.

The only remaining executable `Task.detached` site is the debug-only threading assertion in `CreateStreamingHandlers.swift:89-95`. `git grep` finds two `Task.detached` text matches, but one is the explanatory comment directly above the single executable call.

That means the Phase 3 persistence outcome is already in place:

- configuration writes are no longer fire-and-forget detached work
- log-store writes are no longer fire-and-forget detached work
- ordering and error propagation now pass through one explicit async write boundary

### D. Unstructured `Task` cleanup 🟡 Partial

The repo is no longer using actors and detached writes as generic wrappers, and the first helper-wrapper cleanup slice is landed, but the repo still contains many `Task {}` sites.

#### `Task` sites that still look justified

| File and lines | Why it still makes sense | Status |
|---|---|---|
| `CreateStreamingHandlers.swift:34-36`, `70-72` | Callback bridge back to main-actor alert state | **Keep** |
| `Estimate.swift:155-170`, `Execute.swift:50-57`, `238-323` | Rsync termination callbacks still need async follow-up work | **Keep for now** |
| `GlobalTimer.swift:155-158`, `211-213` | `Timer` and wake-notification callbacks must bridge back to main-actor state | **Keep** |
| `RestoreTableView.swift:49-59`, `LogRecordsTabView.swift:84-94`, `ListofTasksMainView.swift:61-75` | Debounce/cancellation behavior is intentional UI logic | **Keep** |
| `ObservableRestore.swift:51-60`, `OneTaskDetailsView.swift:66-70`, `VerifyTaskTabView.swift:125-130`, `extensionQuickTaskView.swift:86-92`, `LogfileView.swift:28-53`, `extensionSidebarMainView.swift:80-106` | Callback or button-entry bridges that now wrap the sync/async boundary directly instead of wrapping helper work | **Keep** |
| `SidebarStatusMessagesView.swift`, `QuicktaskFormView.swift`, `ButtonStyles.swift`, `CompletedView.swift`, `SummarizedDetailsContentView.swift` | Simple UI timing and auto-dismiss behavior | **Keep** |

#### `Task` sites that remain cleanup targets

| File and lines | What the task is still compensating for | Status |
|---|---|---|
| `ConfigurationsTableLoadDataView.swift:71-80` | Profile reload is still wrapped in an ad hoc task instead of one loader path | ❌ Not done |
| `SnapshotsView.swift:214-215` | Snapshot loading now goes through `loadSnapshotData(for:)`, but the view still owns the task that kicks off snapshot assembly | 🟡 Partial |
| `InterruptProcess.swift:12-17` | Interrupt logging still depends on a task launched from a sync initializer | ❌ Not done |

The clearest sign of unfinished work is no longer the pure `CreateOutputforView` mapping path. Those call sites are now simplified. The remaining Phase 3 cleanup targets are the view-owned orchestration tasks and older sync-entry wrappers such as profile reload and interrupt logging.

### E. Single log-data boundary review 🟡 Partial

Chart entry creation now resolves through one shared service call, and the log table plus snapshot delete path now use the same log-store boundary:

```swift
let entries = await LogStoreService.chartEntries(
    profile: rsyncUIdata.profile,
    configurations: rsyncUIdata.configurations,
    configurationID: selecteduuids.first,
    metric: metric,
    limit: limit
)
```

That is real progress, and the shared configuration helpers in `LogStoreService.swift` already centralize:

- `hiddenIDs`
- `hiddenID(for:)`
- `backupID(for:)`

What is still incomplete:

- `SnapshotsView.getData()` still launches a `Task {}`, but the actual load path is now centralized in `loadSnapshotData(for:)`.
- `Logging` still mutates and persists log-store state directly for scheduled inserts instead of going through a fuller write-side service API.
- Snapshot-related merge and "unused log" calculations are still outside the service boundary.

Phase 3 therefore now has the filter/delete side of the boundary in much better shape, and snapshot reload is less ad hoc than before, while snapshot assembly and write-side log-domain work remain the next cleanup targets.

## 4. Suggested target structure after current Phase 3 work

One reasonable end state is now visible in the code:

### Keep

- `ActorLogToFile` as the serialized logfile boundary
- one log-store actor or repository boundary for persisted log JSON
- callback-owned `Task {}` bridges in execution, timer, and notification code
- debounce/cancellation tasks in SwiftUI views where they model UI behavior

### Avoid reintroducing

- actor wrappers for simple mapping helpers
- actor wrappers for simple fetch/filter helpers
- detached persistence writes
- chart-specific actors now that `LogChartService` and `LogChartReducer` exist

### Finish collapsing

- ✅ `ActorReadLogRecords` is gone; `LogStoreService.loadStore` is the single read entry point (`c6bda5c0`).
- keep `LogChartService` pure and reusable
- simplify `CreateOutputforView` call sites so the helper can stay plain without extra adapter tasks

## 5. Practical cleanup order

1. ✅ Remove thin actors by keeping `CreateOutputforView` and `GetversionofRsyncUI` as plain helpers.
2. ✅ Keep JSON persistence on one awaited writer instead of detached tasks.
3. 🟡 Partial - Keep chart preparation behind `LogStoreService.chartEntries(...)` and `LogChartReducer`.
4. 🟡 Partial - Continue collapsing the remaining async entry points around `CreateOutputforView` and related view callbacks. The pure-mapping helper wrappers are already cleaned up.
5. ✅ Move `ActorReadLogRecords` filtering, selection, and delete calls behind `LogStoreService`.
6. 🟡 Partial - Convert the remaining view-owned snapshot task flow into a clearer service boundary; `SnapshotsView` now has a single `loadSnapshotData(for:)` entry point but still owns the kickoff task.
7. ❌ Not done - Recheck the remaining `Task {}` inventory so only callback bridges, debounce tasks, and real UI timing tasks remain.

## 6. Phase 3 checkpoints

- ✅ Thin actor wrappers stay removed.
- ✅ No persistence path uses `Task.detached`.
- ✅ Chart preparation no longer depends on `ActorLogChartsData` or `ObservableChartData`.
- 🟡 Partial - `Task {}` sites are reduced to 50, and the first helper-wrapper cleanup slice is landed, but several adapter/orchestration tasks still remain.
- ✅ `ActorReadLogRecords` was deleted in `c6bda5c0`; `LogStoreService.loadStore` is the only read entry point and decode runs through `SharedJSONStorageReader.shared`.
- ✅ No SwiftUI view directly owns log delete/filter logic.
- ❌ Not done - The remaining `Task {}` sites are not yet fully reduced to callback bridges, debounce flows, or intentional timing delays.

If you use this file as the execution checklist, the next Phase 3 wins are `ConfigurationsTableLoadDataView` and `InterruptProcess` first, then collapsing the last snapshot-load kickoff task and remaining write-side log-domain work behind the same log-store boundary.


## Phase 4 log-data service unification

This section expands the cleanup plan's Phase 4 with concrete duplicate paths in the current code. The main issue is no longer direct view-to-actor coupling; after the latest Phase 3A work, log-data behavior is still split across `LogStoreService`, `Logging`, snapshot-specific code, and a few remaining view-owned orchestration paths.

## 1. Current duplication map

| Responsibility | Current duplicate locations | Notes |
|---|---|---|
| Load log store from JSON | `RsyncUI/Model/Loggdata/Logging.swift:27-30`, `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:156-159`, `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:186-189`, `RsyncUI/Views/Snapshots/SnapshotsView.swift:219-222`, `RsyncUI/Model/Loggdata/LogChartService.swift` | The read path is now shared through `LogStoreService.loadStore(...)`, but loading is still initiated from several layers. |
| Build `validhiddenIDs` | `LogStoreService.loadStore(...)`, `LogChartService.chartEntries(...)`, `Logging.create(...)` | The low-level loop is centralized, but multiple service/model entry points still trigger log-store loading separately. |
| Resolve selected task `hiddenID` | `LogStoreService.visibleLogs(...)`, `LogChartService.chartEntries(...)` | Selection resolution is now shared by helper APIs, but the log-domain still has separate read-side entry points for visible logs and chart data. |
| Merge/sort logs for one task or all tasks | `RsyncUI/Model/Loggdata/LogStoreService.swift`, `RsyncUI/Model/Snapshots/Snapshotlogsandcatalogs.swift:89-104` | General log presentation moved into `LogStoreService`, but snapshot-specific "unused log" calculation still flattens log data separately. |
| Delete logs and persist | `RsyncUI/Model/Loggdata/LogStoreService.swift`, callers in `LogRecordsTabView.swift` and `SnapshotsView.swift` | The mutation path is centralized now; remaining work is reducing caller-owned reset/orchestration and extending the same model to other write-side log flows. |
| Log result number parsing | `RsyncUI/Model/Loggdata/Logging.swift:103-116`, `RsyncUI/Model/Loggdata/LogChartService.swift:128-140` | The same regex-based number extraction still exists twice. |
| Chart preparation | `RsyncUI/Model/Loggdata/LogChartService.swift`, `RsyncUI/Views/Tasks/LogStatsChartView.swift:252-269` | The chart pipeline is much smaller now, but parsing/reduction still lives in a chart service while the view still owns refresh policy and selection state. |
| Snapshot/log merge | `RsyncUI/Views/Snapshots/SnapshotsView.swift:225-232`, `RsyncUI/Model/Snapshots/Snapshotlogsandcatalogs.swift:47-104` | Snapshot data assembly is driven from the view and the helper keeps its own copy of loaded log records. |

## 2. Detailed duplicate paths

### A. Shared loading boundary ✅

Before the refactor, these entry points all performed the same domain step: read persisted log records for a profile, restricted to valid task IDs.

- `Logging.create(...)` loads the store during scheduled log insertion (`Logging.swift:32-50`).
- `LogRecordsTabView.loadInitialLogs()` loads it for the log table (`LogRecordsTabView.swift:163-172`).
- `LogRecordsTabView.reloadLogsForProfile()` reloads the exact same store after a profile change (`LogRecordsTabView.swift:184-196`).
- `SnapshotsView.getData()` loads the same store before snapshot/catalog merging (`SnapshotsView.swift:225-232`).
- `LogStoreService.chartEntries(...)` now loads the same store before chart parsing (`LogChartService.swift:144-161`).

`LogStoreService.loadStore(...)` is now the shared read entry point used by `Logging`, `LogRecordsTabView`, `SnapshotsView`, and chart loading.

Phase 4A lands as one shared loading boundary:

```swift
typealias LogStore = [LogRecords]

enum LogStoreService {
    static func loadStore(
        profile: String?,
        configurations: [SynchronizeConfiguration]?
    ) async -> LogStore
}
```

That keeps `Logging.create(...)`, `LogRecordsTabView`, `SnapshotsView`, and chart loading on the same entry point even before the broader log-domain service exists.

### B. Shared configuration helper ✅

All four implementations do this:

```swift
var temp = Set<Int>()
if let configurations = configurations {
    for config in configurations {
        temp.insert(config.hiddenID)
    }
}
return temp
```

Before the refactor, the repeated copies were:

- `Logging.validhiddenIDs`
- `LogRecordsTabView.validhiddenIDs`
- `SnapshotsView.validhiddenIDs`
- `LogStatsChartView.validhiddenIDs`

`Collection<SynchronizeConfiguration>` now provides `hiddenIDs`, `hiddenID(for:)`, and `backupID(for:)`.

Phase 4B uses one shared configuration helper:

```swift
extension Collection where Element == SynchronizeConfiguration {
    var hiddenIDs: Set<Int> { ... }
    func hiddenID(for configurationID: SynchronizeConfiguration.ID?) -> Int? { ... }
    func backupID(for configurationID: SynchronizeConfiguration.ID?) -> String? { ... }
}
```

That removes the repeated `validhiddenIDs` loop and also centralizes selection-to-configuration lookups that already drifted into the same views.

### C. Selection-to-log resolution ✅

The UI repeatedly converts `selecteduuids.first` into a `hiddenID`:

- `LogRecordsTabView.loadInitialLogs()` now resolves through `LogStoreService.visibleLogs(...)`.
- `LogRecordsTabView.updateLogsForSelection()` now resolves through `LogStoreService.visibleLogs(...)`.
- `LogStatsChartView` already resolves chart data through `LogStoreService.chartEntries(...)`.

For the current read-side boundary: selection-to-log resolution is now owned by `LogStoreService` APIs instead of being reimplemented inside the log table view.

That mapping is not presentation logic; it is domain selection logic. A service API should accept either:

```swift
func logs(for configurationID: SynchronizeConfiguration.ID?) -> [Log]
```

or:

```swift
func hiddenID(for configurationID: SynchronizeConfiguration.ID?) -> Int?
```

That still leaves separate service entry points for visible logs and chart entries, but the configuration lookup itself is no longer duplicated in the view layer.

### D. Delete-and-persist service ✅

For the current service boundary: `LogRecordsTabView` and `SnapshotsView` now delete through `LogStoreService.deleteLogs(...)`.

#### `LogRecordsTabView.deleteLogs`

1. Calls `LogStoreService.deleteLogs(uuids, profile: rsyncUIdata.profile, in: logrecords)`
2. Refreshes visible logs with `LogStoreService.visibleLogs(...)`
3. Clears UI selection

#### `SnapshotsView.deleteLogs`

1. Calls `LogStoreService.deleteLogs(uuids, profile: rsyncUIdata.profile, in: records)`
2. Clears snapshot-specific local state

The data mutation part now lives behind one service call:

```swift
static func deleteLogs(
    _ ids: Set<Log.ID>,
    profile: String?,
    in store: LogStore
) async -> LogStore?
```

Each view still owns its presentation reset logic, which is fine for now; the remaining Phase 4 work is to reduce the amount of view-owned orchestration around the delete flow, not to move deletion back out of the service.

### E. Shared log-result parser 🟡 Partial

The old actor-level chart parser is gone, but parsing is still duplicated between `Logging` and `LogChartService`.

Both files define:

- `extractnumbersasdoubles(from:)`
- `extractNumbersAsStrings(from:)`
- `numberRegex`

Current copies:

- `Logging.swift:103-116`
- `LogChartService.swift`

This is risky because scheduled log insertion validates log format in one place, while chart parsing interprets the same format elsewhere. If the log string format changes, both sites must change together.

Move this into one shared parser, for example:

```swift
enum ParsedLogResult {
    case sync(files: Int, transferredMB: Double, seconds: Double)
    case snapshot(snapshotNumber: Int, files: Int, transferredMB: Double, seconds: Double)
}

func parseLogResult(_ result: String) -> ParsedLogResult?
```

Then:

- `Logging` uses it for validation before insert.
- Chart preparation uses it for `LogEntry`.
- Snapshot-related code can inspect snapshot number explicitly instead of relying on raw string format.

### F. Unified chart preparation ✅

`ObservableChartData` is gone, `LogStatsChartView` now asks `LogStoreService` for chart entries, and `LogChartReducer` has test coverage.

The current chart path is much cleaner, but it still mixes domain reduction and UI refresh policy:

1. `LogStoreService.chartEntries(...)` loads the store and resolves the selected configuration (`LogChartService.swift:144-161`).
2. `LogChartReducer` parses raw log results and applies the requested reduction (`LogChartService.swift:34-142`).
3. `LogStatsChartView.reloadChartData()` still owns refresh timing and selected-point cleanup (`LogStatsChartView.swift:252-269`).

That split is awkward for two reasons:

- the view decides domain policy (`files` vs `transferredMB`, max-per-day vs top-N)
- chart-specific parsing still duplicates log-result parsing already used by `Logging`

After the refactor, the chart pipeline should collapse into one service request that returns chart-ready data, with the view only choosing presentation state:

```swift
enum LogChartMetric {
    case files
    case transferredMB
}

enum LogChartLimit {
    case maxPerDay
    case topNPerDay(Int)
}

func chartEntries(
    for configurationID: SynchronizeConfiguration.ID?,
    metric: LogChartMetric,
    limit: LogChartLimit
) async throws -> [LogEntry]
```

That boundary should own the full sequence:

1. resolve `configurationID -> hiddenID`
2. load/select the relevant logs
3. parse `resultExecuted` into typed values
4. reduce the parsed records into the requested chart series

With that split:

- `LogStatsChartView` keeps only UI state such as metric toggles, chart style, and selected point
- `LogStatsChartView` can stay focused on refresh policy and presentation state instead of carrying more chart-domain decisions
- the remaining parser duplication between `Logging` and `LogChartService` becomes easier to remove

### G. Snapshot/log merge service ❌ Not done

`Snapshotlogsandcatalogs` still owns merge logic and still stores raw `readlogrecordsfromfile` for later delete.

`Snapshotlogsandcatalogs` merges all logs again to compute `notmappedloguuids`:

- `Snapshotlogsandcatalogs.swift:89-104`

That repeats the "flatten all task logs into `[Log]`" behavior now owned by:

- `LogStoreService.visibleLogs(from:hiddenID:filterString:)` with `hiddenID == -1`

The snapshot flow also keeps its own raw `logrecords` copy and stores it into `ObservableSnapshotData.readlogrecordsfromfile` for later cleanup (`Snapshotlogsandcatalogs.swift:82-85`), which is another sign that the snapshot UI is compensating for missing service-level store ownership even after delete-and-persist moved into `LogStoreService`.

A unified service should expose snapshot-specific helpers on top of the same loaded store:

```swift
func snapshotRecords(
    for config: SynchronizeConfiguration,
    remoteCatalogs: [SnapshotFolder]
) -> SnapshotLogData
```

where `SnapshotLogData` contains:

- merged `[LogRecordSnapshot]`
- `unusedLogIDs`
- original store identity if later delete/persist is needed

## 3. Types that currently mix UI and domain work

### `LogRecordsTabView`

Should keep:

- filter text state
- selection state
- confirmation dialog state
- rendering

Should stop doing directly:

- loading persisted logs
- mapping configuration IDs to `hiddenID`
- filtering logs through storage actor calls
- deleting and persisting logs

### `SnapshotsView`

Should keep:

- selected configuration
- tagging options (`snaplast`, `snapdayofweek`)
- dialog and toolbar state

Should stop doing directly:

- loading persisted logs
- launching domain merge of snapshot logs + remote catalogs
- deleting log records from permanent storage

### `LogStatsChartView`

Should keep:

- metric toggle
- chart type toggle
- selected data point
- rendering

Should stop doing directly:

- loading/parsing logs
- deciding which actor aggregation methods to call
- rebuilding `validhiddenIDs`
- resolving `hiddenID`

### `Logging`

Should likely shrink to one write-focused use case, or disappear into the unified service. Right now it owns:

- loading persisted log records
- validating log format
- updating existing entries
- creating new entries
- formatting snapshot log strings
- persisting logs
- mutating configuration `dateRun` / `snapshotnum`

That is already broader than "logging".

## 4. Suggested target structure

One reasonable split is:

### `LogDataService` actor

Owns:

- reading/writing log JSON
- caching/holding loaded `[LogRecords]`
- selecting task/all-task logs
- filtering/sorting
- delete operations
- chart entry preparation
- snapshot/log merge helpers if you want all log-domain logic in one place

### Small pure helpers

- `LogResultParser`
- `LogChartReducer`
- `LogRecordSelectors`
- `SnapshotLogMerger` if snapshot merging feels too specific for the service actor itself

That keeps actor isolation around persistence and shared store access, while moving transformation logic into testable pure functions.

## 5. Practical cleanup order

1. 🟡 Partial - Extract the shared log-result parser from `Logging` and `LogChartService` (regex parsing is still duplicated; the read-side actor was deleted in `c6bda5c0`, so the historical second copy is now folded into `LogStoreService`).
2. ✅ Extract configuration helpers for `hiddenIDs` and `selected hiddenID`.
3. 🟡 Partial - Create a store-oriented service that wraps the JSON read (now inlined in `LogStoreService.loadStore` via `SharedJSONStorageReader.shared`) and `WriteLogRecordsJSON`.
4. 🟡 Partial - Move `LogRecordsTabView` to the service first; it has the simplest read/filter/delete path.
5. ✅ Move chart preparation next by replacing `ObservableChartData` + `LogStatsChartView.readAndSortLogData()` with one service call.
6. ❌ Not done - Move snapshot merge/delete flow last, because it combines local logs with remote catalog discovery.
7. 🟡 Partial - Reduce `Logging` into either:
   - a thin facade over `LogDataService`, or
   - a write use case nested inside the new log-data domain.

## 6. Refactor checkpoints to verify while cleaning up

- ✅ There is only one place that reads log JSON from disk.
- ❌ Not done - There is only one place that writes log JSON to disk.
- ❌ Not done - There is only one parser for `resultExecuted`.
- ✅ No SwiftUI view directly calls `ActorReadLogRecords` — the actor was deleted in `c6bda5c0` and views go through `LogStoreService`.
- ✅ `ObservableChartData` is either removed or reduced to plain UI state.
- ❌ Not done - `SnapshotsView` no longer stores raw `readlogrecordsfromfile` just to support delete.
- ✅ `validhiddenIDs` is not reimplemented in view files.

If you use this file as the execution checklist, the highest-value deletions are the duplicate loading paths and the duplicated regex parser first; those are the easiest wins and reduce the risk of divergence immediately.
