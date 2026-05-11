# Refactor Plan: Synchronize View

This document describes step-by-step UI refactoring for the Synchronize View (the main view users see when they select "Synchronize" in the sidebar). Each step is self-contained and testable before moving to the next.

---

## Current File Map

These are the files involved and their roles:

| File | Role |
|---|---|
| `Views/Sidebar/SidebarMainView.swift` | Root NavigationSplitView, sidebar list, profile picker, status footer |
| `Views/Sidebar/extensionSidebarMainView.swift` | URL handling, volume mount observers |
| `Views/Sidebar/SidebarStatusMessagesView.swift` | Status messages at bottom of sidebar (rsync version, new version, timer) |
| `Views/Tasks/SidebarTasksView.swift` | NavigationStack wrapper for TasksView + destination routing |
| `Views/Tasks/TasksView.swift` | Main Synchronize view: composes table + toolbar + sheets |
| `Views/Tasks/extensionTasksView.swift` | Toolbar content builder (all toolbar buttons) |
| `Views/Tasks/TasksListPanelView.swift` | Thin wrapper around ListofTasksMainView |
| `Views/Tasks/TasksFocusActionsView.swift` | Invisible trigger views for keyboard focus actions |
| `Views/Configurations/ListofTasksMainView.swift` | Wraps ConfigurationsTableDataMainView + searchable + delete |
| `Views/Configurations/ConfigurationsTableDataMainView.swift` | The actual `Table` with all columns (%, Num, ID, Action, Source, Dest, Server, Time, Date) |
| `Model/Global/SharedReference.swift` | Singleton with app-wide state (rsync version, feature flags) |

---

## Step 1: Sidebar — Add Section Grouping

**Goal:** Group sidebar items under labeled section headers (Actions, Tools, Management) instead of a flat list with manual Dividers.

**Files to change:**
- `Views/Sidebar/SidebarMainView.swift`

**What to do:**

1. Add a `sidebarSection` enum or use string constants for the three groups:
   - **Actions**: `synchronize`, `tasks`
   - **Tools**: `snapshots`, `restore`
   - **Management**: `profiles`

2. Replace the current `List(menuitems, selection: $selectedview)` block (lines 79-86) which uses manual `Divider()` after certain items. Instead, use `Section` views:

```swift
List(selection: $selectedview) {
    Section("Actions") {
        ForEach(menuitems.filter { $0.menuitem == .synchronize || $0.menuitem == .tasks }) { item in
            NavigationLinkWithHover(item: item, selectedview: $selectedview)
        }
    }
    
    let toolItems = menuitems.filter { $0.menuitem == .snapshots || $0.menuitem == .restore }
    if !toolItems.isEmpty {
        Section("Tools") {
            ForEach(toolItems) { item in
                NavigationLinkWithHover(item: item, selectedview: $selectedview)
            }
        }
    }
    
    Section("Management") {
        ForEach(menuitems.filter { $0.menuitem == .profiles }) { item in
            NavigationLinkWithHover(item: item, selectedview: $selectedview)
        }
    }
}
.listStyle(.sidebar)
.disabled(disablesidebarmeny)
```

3. Remove the manual `Divider()` logic (the `if item.menuitem == .tasks || ...` block).

**Test:** Launch the app. The sidebar should show three collapsible sections. Items should still be selectable. Snapshots section should hide when no snapshot tasks exist. Restore section should hide when no remote tasks exist.

---

## Step 2: Sidebar — Promote Profile Picker with Label

**Goal:** Make the profile picker always visible (even when only "Default" exists) with a clear "Profile" label above it, in its own visual section.

**Files to change:**
- `Views/Sidebar/SidebarMainView.swift`

**What to do:**

1. Find the profile picker block (lines 63-75). Currently it is conditionally shown only when `rsyncUIdata.validprofiles.isEmpty == false` and `selectedview != .profiles`.

2. Change it to always show, but display "Default" as the only option when no other profiles exist. Add a small uppercase label above:

```swift
VStack(alignment: .leading, spacing: 4) {
    Text("PROFILE")
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .padding(.leading, 4)
    
    Picker("", selection: $selectedprofileID) {
        Text("Default")
            .tag(nil as ProfilesnamesRecord.ID?)
        ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
            Text(profile.profilename)
                .tag(profile.id)
        }
    }
    .frame(width: 180)
    .disabled(disablesidebarmeny)
}
.padding(.horizontal, 12)
.padding(.vertical, 8)
```

3. Remove the condition `selectedview != .profiles` — the picker should be visible on all tabs so the user always knows which profile is active.

4. Keep the `Divider()` after the profile picker section.

**Test:** Launch with Default profile only — picker should still be visible showing "Default". Create another profile — both should appear. Switching profiles should reload data as before.

---

## Step 3: Sidebar — Add Count Badges

**Goal:** Show a badge count on the "Synchronize" sidebar item indicating how many tasks have data to synchronize (i.e., stale tasks).

**Files to change:**
- `Views/Sidebar/SidebarMainView.swift`
- `Views/Sidebar/SidebarMainView.swift` (the `SidebarRow` struct)

**What to do:**

1. Modify `SidebarRow` to accept an optional badge count:

```swift
struct SidebarRow: View {
    var sidebaritem: Sidebaritems
    var badgeCount: Int = 0

    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemImage(sidebaritem))
        .badge(badgeCount > 0 ? badgeCount : 0)
    }
}
```

2. In `NavigationLinkWithHover`, pass the badge count through. You'll need to add a `badgeCount` parameter.

3. Compute the badge: count configurations where `dateRun` is older than `SharedReference.shared.marknumberofdayssince` days, or where `dateRun` is nil. Pass this count when building the Synchronize menu item.

4. The badge uses SwiftUI's built-in `.badge()` modifier which renders natively in sidebar lists.

**Test:** If you have tasks that haven't been synced in a while, the Synchronize item should show a number badge. If all tasks are recent, no badge should appear.

---

## Step 4: Toolbar — Replace Icon-Only Buttons with Labeled Primary Buttons

**Goal:** Replace the current 8+ icon-only toolbar buttons with 3 labeled primary buttons (Estimate, Synchronize, Estimate & Sync) + 1 Reset button. Move secondary tools behind a toggle.

**Files to change:**
- `Views/Tasks/extensionTasksView.swift`

**What to do:**

1. Restructure the toolbar content builder. The current toolbar has these items spread across ~220 lines:
   - Estimate (wand.and.stars) — line 52
   - Synchronize (play.fill) — line 75
   - Reset estimates (clear) — line 105
   - Rsync output (text.magnifyingglass) — line 123
   - Quick synchronize (hare) — line 151
   - Charts (chart.bar.fill) — line 161
   - Schedule (calendar.circle.fill) — line 173
   - View logfile (doc.plaintext) — line 183
   - Save sync log (square.and.arrow.down.fill) — line 193
   - Estimate & Synchronize (bolt.shield.fill) — line 213

2. Reorganize into this structure:

```swift
@ToolbarContentBuilder
var taskviewtoolbarcontent: some ToolbarContent {
    // Profile picker when sidebar hidden (keep existing logic, lines 22-45)
    
    // Primary actions group — LEFT side
    ToolbarItemGroup(placement: .automatic) {
        Button {
            // existing estimate logic from line 53-66
        } label: {
            Label("Estimate", systemImage: "wand.and.stars")
                .labelStyle(.titleAndIcon)  // <-- KEY CHANGE: show text + icon
        }
        .help("Estimate (⌘E)")
        
        Button {
            // existing synchronize logic from line 77-96
        } label: {
            Label("Synchronize", systemImage: "play.fill")
                .labelStyle(.titleAndIcon)
        }
        .help("Synchronize (⌘R)")
        
        if allTasksAreHalted() == false {
            Button {
                // existing estimate & sync logic from line 214-225
            } label: {
                Label("Estimate & Sync", systemImage: "bolt.shield.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(Color(.yellow))
            }
            .help("Estimate & Synchronize")
        }
    }
    
    // Reset button — separate
    ToolbarItem {
        Button {
            selecteduuids.removeAll()
            reset()
        } label: {
            Label("Reset", systemImage: "clear")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(thereareestimates ? Color(.red) : .primary)
        }
        .help("Reset estimates")
    }
    
    // Secondary tools — keep behind showquicktask toggle
    // Keep existing Group { if showquicktask { ... } } logic
    // but these can stay as icon-only since they're secondary
}
```

3. The key change is `.labelStyle(.titleAndIcon)` on the three primary buttons. This shows both the icon and the text label in the toolbar.

4. Remove the duplicate `ToolbarItem { Spacer() }` entries (there are 3 spacers currently). Use `ToolbarItemGroup` placement instead.

**Test:** The toolbar should now show "Estimate", "Synchronize", and "Estimate & Sync" with both icon and text. They should be clearly readable. All button actions should work identically to before. Secondary tools (Charts, Schedule, Log) should still appear when the toolbox toggle is on.

---

## Step 5: Table — Replace Text "Action" Column with Status Dot

**Goal:** Replace the "Action" column (which shows "synchronize" text or a red stop icon) with a compact colored status dot. Show task type as an inline badge next to the task name only when it differs from "synchronize".

**Files to change:**
- `Views/Configurations/ConfigurationsTableDataMainView.swift`

**What to do:**

1. Remove the "Action" `TableColumn` (lines 105-134).

2. Add a new narrow "Status" column as the FIRST column:

```swift
TableColumn("") { data in
    if data.hiddenID == progressdetails.hiddenIDatwork, max > 0, progress <= max {
        // Active sync: show mini progress bar
        ProgressView(value: progress, total: max)
            .frame(width: 20)
            .scaleEffect(y: 1.5, anchor: .center)
    } else {
        Circle()
            .fill(statusColor(for: data))
            .frame(width: 8, height: 8)
    }
}
.width(min: 30, max: 36)
```

3. Add a helper function:

```swift
private func statusColor(for data: SynchronizeConfiguration) -> Color {
    if data.task == SharedReference.shared.halted {
        return .gray
    }
    guard let dateRun = data.dateRun else {
        return .orange  // never synced
    }
    let lastbackup = dateRun.en_date_from_string()
    let daysSince = lastbackup.timeIntervalSinceNow * -1 / (60 * 60 * 24)
    if daysSince > Double(SharedReference.shared.marknumberofdayssince) {
        return .orange  // stale
    }
    return .green  // recently synced
}
```

4. In the "Synchronize ID" column, add an inline badge for non-standard task types. After the `Text(data.backupID)` lines, add:

```swift
HStack(spacing: 4) {
    // existing Text(data.backupID) logic...
    
    if data.task == SharedReference.shared.snapshot {
        Text("snapshot")
            .font(.caption2)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.orange.opacity(0.15))
            .foregroundStyle(.orange)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    } else if data.task == SharedReference.shared.syncremote {
        Text("syncremote")
            .font(.caption2)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.blue.opacity(0.15))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
```

5. Move the halt toggle context menu to the "Synchronize ID" column (it was on the Action column).

**Test:** Each row should show a small colored dot on the left. Green = synced recently, orange = stale or never synced, grey = halted. Snapshot and syncremote tasks should show a small label badge next to their name. Right-click to halt/unhalt should still work.

---

## Step 6: Table — Merge Time/Date into Single "Last Sync" Column with Relative Time

**Goal:** Replace the two separate "Time last" and "Date last" columns with a single "Last Sync" column showing relative time ("15 hrs ago") as primary text and the absolute date below in smaller text.

**Files to change:**
- `Views/Configurations/ConfigurationsTableDataMainView.swift`

**What to do:**

1. Remove the "Time last" `TableColumn` (lines 148-163) and "Date last" `TableColumn` (lines 165-168).

2. Add a single "Last Sync" column:

```swift
TableColumn("Last Sync") { data in
    if data.hiddenID == progressdetails.hiddenIDatwork, max > 0, progress <= max {
        // Currently syncing
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(Int((progress / max) * 100))%")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.blue)
            Text("syncing...")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    } else if data.task == SharedReference.shared.halted {
        Text("halted")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    } else if let dateRun = data.dateRun {
        let lastbackup = dateRun.en_date_from_string()
        let seconds = lastbackup.timeIntervalSinceNow * -1
        let isStale = markConfig(seconds)
        
        VStack(alignment: .trailing, spacing: 2) {
            Text(seconds.latest())
                .font(.caption)
                .foregroundStyle(isStale ? .red : .primary)
            Text(dateRun)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    } else {
        Text("never")
            .font(.caption)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
.width(min: 80, max: 130)
```

3. Note: `seconds.latest()` already returns relative time strings like "15.4 hours" from the existing `Double` extension. You can keep using it, or create a cleaner version that returns "15 hrs ago", "3 days ago", etc.

**Test:** The table should now show a single "Last Sync" column on the right side. Relative time should be the prominent text. Absolute date should be smaller underneath. Tasks older than the configured threshold should show red text. Halted tasks should show "halted" in grey.

---

## Step 7: Table — Inline Progress (Remove Toggle Columns)

**Goal:** Replace the "%" and "Num" columns (which toggle visibility based on whether a sync is in progress) with inline progress indicators in the Status dot column and Last Sync column.

**Files to change:**
- `Views/Configurations/ConfigurationsTableDataMainView.swift`

**What to do:**

1. Remove the "%" `TableColumn` (lines 25-44) and "Num" `TableColumn` (lines 46-67).

2. Remove the `visibleProgress` computed property (lines 176-182) and the `max` parameter if no longer needed externally.

3. The progress display is now handled by:
   - **Status column** (from Step 5): shows a mini `ProgressView` instead of a dot when `data.hiddenID == progressdetails.hiddenIDatwork`
   - **Last Sync column** (from Step 6): shows percentage and "syncing..." instead of relative time

4. Clean up the `max` and `progress` bindings. They're still needed for the progress values but no longer control column visibility.

**Test:** Start an estimate or sync. The active row should show a progress indicator in the status column and a percentage in the last sync column. No columns should appear or disappear. The table layout should remain stable.

---

## Step 8: Table — Dim Halted Rows

**Goal:** When a task is halted, visually dim the entire row to make it immediately obvious which tasks are inactive.

**Files to change:**
- `Views/Configurations/ConfigurationsTableDataMainView.swift`

**What to do:**

1. SwiftUI `Table` doesn't support per-row opacity directly. Instead, apply opacity to each cell's content for halted tasks. In each `TableColumn` closure, wrap the content:

```swift
TableColumn("Synchronize ID") { data in
    HStack(spacing: 4) {
        // existing content...
    }
    .opacity(data.task == SharedReference.shared.halted ? 0.4 : 1.0)
}
```

2. Apply the same `.opacity()` modifier to the Source, Destination, and Server columns.

3. The Status dot column already handles this (grey dot from Step 5).

4. The Last Sync column already handles this ("halted" text from Step 6).

**Test:** Halt a task via right-click context menu. The entire row should appear visually dimmed. Un-halt it — it should return to full opacity.

---

## Step 9: Sidebar Footer — Clean Up Status Display

**Goal:** Make the rsync version display in the sidebar footer cleaner — show a small green dot + version string.

**Files to change:**
- `Views/Sidebar/SidebarStatusMessagesView.swift`

**What to do:**

1. The current view stacks multiple `MessageView` instances with negative padding. Simplify to a single `VStack`:

```swift
struct SidebarStatusMessagesView: View {
    let newVersionAvailable: Bool
    @Binding var mountingVolumeNow: Bool
    let timerIsActive: Bool
    let nextScheduleText: String
    let showNotExecutedAfterWake: Bool
    let rsyncVersionShort: String
    let clearNotExecutedAfterWake: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if newVersionAvailable {
                Label("Update available", systemImage: "arrow.down.circle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            
            if mountingVolumeNow {
                Label("Mounting volume...", systemImage: "externaldrive")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .onAppear {
                        Task {
                            try? await Task.sleep(seconds: 2)
                            mountingVolumeNow = false
                        }
                    }
            }
            
            if timerIsActive {
                Label(nextScheduleText, systemImage: "calendar.badge.clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if showNotExecutedAfterWake {
                Label("Scheduled tasks missed", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .onAppear {
                        Task {
                            try? await Task.sleep(seconds: 5)
                            clearNotExecutedAfterWake()
                        }
                    }
            }
            
            // Always show rsync version with green status dot
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text(rsyncVersionShort)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
```

2. Remove the `padding([.bottom], -30)` hacks — the VStack spacing handles layout now.

**Test:** The sidebar footer should show a clean green dot + rsync version. When a timer is active or an update is available, additional lines should appear above the version without overlapping.

---

## Step 10: Overall — Reduce Default Column Count

**Goal:** The Synchronize table should show 6 columns by default: Status dot, Synchronize ID, Source, Destination, Server, Last Sync. No columns should toggle visibility.

**Files to change:**
- `Views/Configurations/ConfigurationsTableDataMainView.swift`

**What to do:**

After Steps 5-7, verify the final column order is:

1. **""** (Status dot) — width: 30-36px
2. **"Synchronize ID"** — width: min 80, max 200
3. **"Source"** — width: min 120, max 300
4. **"Destination"** — width: min 120, max 300
5. **"Server"** — width: min 50, max 100
6. **"Last Sync"** — width: min 80, max 130, right-aligned

Adjust column widths so nothing truncates at 1200px window width. The key insight: removing "Action", "Time last", "Date last", "%", and "Num" columns frees ~400px of horizontal space.

Also consider renaming "Source folder" to "Source" and "Destination folder" to "Destination" for shorter column headers.

**Test:** At the default window size (1200px wide), all columns should be readable without truncation. Resize the window narrower — Source and Destination should truncate with ellipsis before other columns shrink.

---

## Summary of All Files Changed

| Step | File | Change |
|------|------|--------|
| 1 | `SidebarMainView.swift` | Section grouping in sidebar list |
| 2 | `SidebarMainView.swift` | Always-visible labeled profile picker |
| 3 | `SidebarMainView.swift` | Badge count on sidebar items |
| 4 | `extensionTasksView.swift` | Labeled primary toolbar buttons |
| 5 | `ConfigurationsTableDataMainView.swift` | Status dot column, remove Action column |
| 6 | `ConfigurationsTableDataMainView.swift` | Merged Last Sync column |
| 7 | `ConfigurationsTableDataMainView.swift` | Remove % and Num toggle columns |
| 8 | `ConfigurationsTableDataMainView.swift` | Dim halted row content |
| 9 | `SidebarStatusMessagesView.swift` | Clean sidebar footer |
| 10 | `ConfigurationsTableDataMainView.swift` | Final column width tuning |
