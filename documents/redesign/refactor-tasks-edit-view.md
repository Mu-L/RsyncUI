# Refactor Plan: Tasks / Edit View

This document describes step-by-step UI refactoring for the Tasks / Edit View (the view users see when they select "Tasks" in the sidebar). Each step is self-contained and testable before moving to the next.

---

## Current File Map

These are the files involved and their roles:

| File | Role |
|---|---|
| `Views/InspectorViews/EditTabView.swift` | Root view: HStack with task list + `.inspector()` panel |
| `Views/InspectorViews/InspectorView.swift` | Inspector content: TabView with 4 tabs (Edit, Parameters, Log Records, Verify Task) |
| `Views/InspectorViews/Add/AddTaskView.swift` | Edit/Add tab: form fields for task configuration |
| `Views/InspectorViews/Add/AddTaskContentView.swift` | Layout template for the edit form (generic ViewBuilder composition) |
| `Views/InspectorViews/Add/extensionAddTaskView.swift` | Business logic: addConfig(), validateAndUpdate(), buttons |
| `Views/InspectorViews/Add/extensionAddTaskView+FormFields.swift` | Form field sections: synchronizeID, catalogs, remote params, trailing slash |
| `Views/InspectorViews/Add/extensionAddTaskView+ViewBuilders.swift` | catalogSectionView, addTaskSheetView |
| `Views/InspectorViews/Add/extensionAddTaskView+BusinessLogic.swift` | handleSelectionChange, handleSubmit, clearSelection, etc. |
| `Views/InspectorViews/Add/OpencatalogView.swift` | Folder picker button (opens NSOpenPanel) |
| `Views/InspectorViews/RsyncParameters/RsyncParametersView.swift` | Parameters tab: rsync parameter fields + SSH + --delete toggle |
| `Views/InspectorViews/RsyncParameters/extensionRsyncParametersView.swift` | Parameters tab helpers |
| `Views/InspectorViews/LogRecords/LogRecordsTabView.swift` | Log Records tab |
| `Views/InspectorViews/LogRecords/LogRecordsFooterView.swift` | Footer for log records |
| `Views/InspectorViews/VerifyTask/VerifyTaskTabView.swift` | Verify Task tab |
| `Views/InspectorViews/VerifyTask/RsyncCommandView.swift` | Shows rsync command preview |
| `Views/Configurations/ListofTasksAddView.swift` | Task list table for edit view (with copy/paste/delete) |
| `Views/Configurations/ConfigurationsTableDataView.swift` | The actual `Table` used in edit view (5 columns: ID, Action, Source, Dest, Server) |
| `Views/InspectorViews/AddFirstTask.swift` | Empty state view when no tasks exist |

---

## Step 1: Toolbar — Add Labeled "Add Task" Button

**Goal:** Replace the icon-only "+" toolbar button with a labeled "Add Task" button that is easier to discover.

**Files to change:**
- `Views/InspectorViews/EditTabView.swift`

**What to do:**

1. Find the toolbar content (lines 49-59). Currently it has a single icon-only button:

```swift
.toolbar(content: {
    ToolbarItem(placement: .navigation) {
        Button {
            showAddPopover.toggle()
        } label: {
            Label("Quick add task", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
        .help("Quick add task")
    }
})
```

2. Change `.labelStyle(.iconOnly)` to `.labelStyle(.titleAndIcon)` and update the label text:

```swift
.toolbar(content: {
    ToolbarItem(placement: .automatic) {
        Button {
            showAddPopover.toggle()
        } label: {
            Label("Add Task", systemImage: "plus")
                .labelStyle(.titleAndIcon)
        }
        .help("Add new task")
    }
})
```

**Test:** The toolbar should show "Add Task" with a "+" icon. Clicking it should open the Add Task sheet as before.

---

## Step 2: Inspector — Replace TabView with Picker (Segmented Control)

**Goal:** Replace the macOS TabView (which renders with large tab buttons and takes ~35px of header) with a compact `Picker` using `.segmented` style. This saves vertical space and looks more modern.

**Files to change:**
- `Views/InspectorViews/InspectorView.swift`

**What to do:**

1. The current code (lines 39-81) uses `TabView(selection: $selectedTab)` with `.tabItem` on each child view. Replace with a `VStack` containing a `Picker` and the content view:

```swift
var body: some View {
    if selecteduuids.count == 0 {
        ZStack {
            AddTaskView(rsyncUIdata: rsyncUIdata,
                        selectedTab: $selectedTab,
                        selecteduuids: $selecteduuids,
                        showAddPopover: $showAddPopover)
                .opacity(0)
                .allowsHitTesting(false)

            Text("No task\nselected")
                .font(.title2)
        }
    } else {
        VStack(spacing: 0) {
            // Segmented control at top
            Picker("Inspector Tab", selection: $selectedTab) {
                Text("Edit").tag(InspectorTab.edit)
                Text("Parameters").tag(InspectorTab.parameters)
                Text("Logs").tag(InspectorTab.logview)
                Text("Verify").tag(InspectorTab.verifytask)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Content area
            ScrollView {
                inspectorContent
            }
        }
        .navigationTitle("")
        .inspectorColumnWidth(min: 550, ideal: 600, max: 650)
    }
}

@ViewBuilder
private var inspectorContent: some View {
    switch selectedTab {
    case .edit:
        AddTaskView(rsyncUIdata: rsyncUIdata,
                    selectedTab: $selectedTab,
                    selecteduuids: $selecteduuids,
                    showAddPopover: $showAddPopover)
    case .parameters:
        RsyncParametersView(rsyncUIdata: rsyncUIdata,
                            selectedTab: $selectedTab,
                            selecteduuids: $selecteduuids)
    case .logview:
        LogRecordsTabView(
            rsyncUIdata: rsyncUIdata,
            selectedTab: $selectedTab,
            selecteduuids: $selecteduuids
        )
    case .verifytask:
        VerifyTaskTabView(
            rsyncUIdata: rsyncUIdata,
            selectedTab: $selectedTab,
            selecteduuids: $selecteduuids
        )
    }
}
```

2. Note: The segmented `Picker` uses shorter labels: "Edit", "Parameters", "Logs", "Verify" instead of the full "Log Records" and "Verify Task" to fit the inspector width.

3. Remove the `.padding()` from the outer container (line 82) since each tab view already has its own padding.

**Test:** The inspector should show a compact segmented control at the top. Clicking each segment should switch the content below. All four tabs should work as before. The vertical space saved should make the Edit form feel less cramped.

---

## Step 3: Edit Form — Add Section Headers with Visual Grouping

**Goal:** Group the edit form fields under clear section headers (Identity, Folders, Remote) with consistent styling. Currently the sections use `Section(header:)` with inconsistent font sizing.

**Files to change:**
- `Views/InspectorViews/Add/extensionAddTaskView+FormFields.swift`
- `Views/InspectorViews/Add/AddTaskContentView.swift`

**What to do:**

1. Create a reusable section header style. Add a small helper view (or just use a consistent pattern):

```swift
private func sectionHeader(_ title: String) -> some View {
    Text(title.uppercased())
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .tracking(0.5)
        .padding(.top, 4)
}
```

2. In `extensionAddTaskView+FormFields.swift`, update the section headers:

**synchronizeID** (line 14): Change from:
```swift
Section(header: Text("Synchronize ID").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold))
```
To:
```swift
Section(header: sectionHeader("Synchronize ID"))
```

**localandremotecatalog** (line 39): Change from:
```swift
Section(header: Text("Folder parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold))
```
To:
```swift
Section(header: sectionHeader("Folders"))
```

**remoteuserandserver** (line 89): Change from:
```swift
Section(header: Text("Remote parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold))
```
To:
```swift
Section(header: sectionHeader("Remote"))
```

3. In `AddTaskContentView.swift`, the layout is already a `VStack(alignment: .leading, spacing: 12)`. The updated section headers will be more compact and consistent.

**Test:** The inspector Edit tab should show clean, small uppercase section headers: "SYNCHRONIZE ID", "FOLDERS", "REMOTE". The form should feel less heavy than with `.title3` headers.

---

## Step 4: Edit Form — Better Folder Picker Affordance

**Goal:** Make the folder browse buttons next to path fields clearer and more consistent. Currently `OpencatalogView` renders as a blue square icon — make it look like a proper browse button.

**Files to change:**
- `Views/InspectorViews/Add/OpencatalogView.swift`

**What to do:**

1. Read the current `OpencatalogView` implementation. It likely uses an icon-only button. Update it to have a clearer visual treatment:

```swift
struct OpencatalogView: View {
    @Binding var selecteditem: String
    let catalogs: Bool
    
    var body: some View {
        Button {
            // existing NSOpenPanel logic
        } label: {
            Image(systemName: "folder")
                .font(.system(size: 12))
                .frame(width: 28, height: 22)
        }
        .buttonStyle(.bordered)
        .help("Browse...")
    }
}
```

2. The key change is using `.buttonStyle(.bordered)` instead of the current styling, and using the "folder" SF Symbol which is universally understood as "browse for a folder."

3. Ensure the button is vertically aligned with the text field by checking the HStack in `catalogField()` (line 68-86 of `extensionAddTaskView+FormFields.swift`).

**Test:** Each folder path field should have a small bordered button with a folder icon on the right. Clicking it should open the folder picker dialog as before.

---

## Step 5: Edit Form — Reorganize Update/Add Buttons

**Goal:** Move the Update and Add buttons to the bottom of the inspector panel as a persistent action bar, instead of having them at the top of the form.

**Files to change:**
- `Views/InspectorViews/InspectorView.swift`
- `Views/InspectorViews/Add/AddTaskContentView.swift`
- `Views/InspectorViews/Add/extensionAddTaskView.swift`

**What to do:**

1. In `AddTaskContentView.swift`, remove the `updateButton` and `trailingslash` from the top of the VStack (lines 16-19):

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        // Remove: HStack { updateButton; trailingslash }
        
        synchronizeID
        catalogSectionView
        VStack(alignment: .leading) { remoteuserandserver }
        if showSnapshot {
            VStack(alignment: .leading) { snapshotView }
        }
        saveURLSection
    }
    .padding()
}
```

2. In `InspectorView.swift`, add a persistent bottom action bar below the ScrollView (only for the Edit tab):

```swift
VStack(spacing: 0) {
    Picker(...) // segmented control
    Divider()
    ScrollView {
        inspectorContent
    }
    
    // Bottom action bar for Edit tab
    if selectedTab == .edit {
        Divider()
        HStack(spacing: 8) {
            // Update button (primary action)
            Button {
                // This needs to trigger validateAndUpdate() on AddTaskView
                // See note below about communication pattern
            } label: {
                Label("Update", systemImage: "arrow.down")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
            
            // Trailing slash picker (compact)
            // Move trailingslash picker here
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
```

3. **Communication note:** The Update action currently lives in `AddTaskView`. Since we're moving the button to `InspectorView`, you have two options:
   - **Option A (simpler):** Keep the Update button inside `AddTaskView` but position it at the bottom using a `Spacer()` + `safeAreaInset(edge: .bottom)`.
   - **Option B (cleaner):** Pass a callback from `AddTaskView` up to `InspectorView` via a binding or closure.

   **Recommended: Option A.** In `AddTaskContentView.swift`, wrap the content in a VStack with a Spacer, and use `.safeAreaInset(edge: .bottom)` for the action bar:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        synchronizeID
        catalogSectionView
        VStack(alignment: .leading) { remoteuserandserver }
        if showSnapshot {
            VStack(alignment: .leading) { snapshotView }
        }
        saveURLSection
    }
    .padding()
    .safeAreaInset(edge: .bottom) {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                updateButton
                Spacer()
                trailingslash
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}
```

**Test:** The Edit tab should show form fields in a scrollable area with a persistent action bar at the bottom containing the Update button and trailing slash picker. The action bar should not scroll away. Clicking Update should save changes as before.

---

## Step 6: Task List Table — Status Dot and Remove Action Column

**Goal:** Mirror the Synchronize view changes in the Tasks/Edit table. Replace the "Action" column with a status dot, since the edit view shares `ConfigurationsTableDataView`.

**Files to change:**
- `Views/Configurations/ConfigurationsTableDataView.swift`

**What to do:**

1. The current table (lines 16-59) has 5 columns: Synchronize ID, Action, Source folder, Destination folder, Server.

2. Remove the "Action" `TableColumn` (lines 38-46).

3. Add a status dot as the first column:

```swift
Table(configurations ?? [], selection: $selecteduuids) {
    TableColumn("") { data in
        Circle()
            .fill(data.task == SharedReference.shared.halted ? Color.gray : Color.green)
            .frame(width: 8, height: 8)
    }
    .width(min: 30, max: 36)
    
    TableColumn("Synchronize ID") { data in
        HStack(spacing: 4) {
            if data.parameter4?.isEmpty == false {
                Text(data.backupID.isEmpty ? "No ID set" : data.backupID)
                    .foregroundStyle(.red)
            } else {
                Text(data.backupID.isEmpty ? "No ID set" : data.backupID)
                    .foregroundStyle(.blue)
            }
            
            // Task type badge for non-standard types
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
        .opacity(data.task == SharedReference.shared.halted ? 0.4 : 1.0)
    }
    .width(min: 90, max: 200)
    
    // Remaining columns with halted dimming
    TableColumn("Source", value: \.localCatalog)
        .width(min: 80, max: 300)
    TableColumn("Destination", value: \.offsiteCatalog)
        .width(min: 80, max: 300)
    TableColumn("Server") { data in
        Text(data.offsiteServer.isEmpty ? "localhost" : data.offsiteServer)
            .opacity(data.task == SharedReference.shared.halted ? 0.4 : 1.0)
    }
    .width(min: 50, max: 90)
}
```

4. Note: The edit view table doesn't need a "Last Sync" column since this view is for editing, not monitoring.

5. Also apply the same changes to `ConfigurationsTableLoadDataView.swift` (the profile preview table) for consistency.

**Test:** The Tasks table should show a status dot, task name (with optional type badge), source, destination, and server. No "Action" text column. Halted rows should be dimmed. Selecting a task should load it in the inspector.

---

## Step 7: Task List Table — Column Header Rename

**Goal:** Shorten column headers for consistency with the Synchronize view.

**Files to change:**
- `Views/Configurations/ConfigurationsTableDataView.swift`
- `Views/Configurations/ConfigurationsTableDataMainView.swift`
- `Views/Configurations/ConfigurationsTableLoadDataView.swift`

**What to do:**

1. Rename columns across all three table files:
   - "Source folder" → "Source"
   - "Destination folder" → "Destination"
   - "Synchronize ID" → "Task" (shorter, clearer)

2. These are simple string changes in `TableColumn("...")` constructors.

**Test:** Column headers should be shorter and consistent across both the Synchronize and Tasks views.

---

## Step 8: Empty State — Improve "No Task Selected" View

**Goal:** Replace the plain "No task\nselected" text in the inspector with a more informative empty state.

**Files to change:**
- `Views/InspectorViews/InspectorView.swift`

**What to do:**

1. Replace the current empty state (lines 26-36):

```swift
if selecteduuids.count == 0 {
    ZStack {
        AddTaskView(...)
            .opacity(0)
            .allowsHitTesting(false)
        
        Text("No task\nselected")
            .font(.title2)
    }
}
```

With a proper `ContentUnavailableView`:

```swift
if selecteduuids.count == 0 {
    ZStack {
        AddTaskView(rsyncUIdata: rsyncUIdata,
                    selectedTab: $selectedTab,
                    selecteduuids: $selecteduuids,
                    showAddPopover: $showAddPopover)
            .opacity(0)
            .allowsHitTesting(false)
        
        ContentUnavailableView {
            Label("No Task Selected", systemImage: "square.dashed")
        } description: {
            Text("Select a task from the list to edit its configuration.")
        }
    }
}
```

2. The invisible `AddTaskView` is kept for its `onAppear`/`onChange` side effects — do not remove it.

**Test:** When no task is selected, the inspector should show a centered icon + "No Task Selected" + description text. Selecting a task should switch to the tabbed editor.

---

## Step 9: Parameters Tab — Clean Up Danger Zone

**Goal:** The Parameters tab has a "Danger Zone" section with a red bordered box for `--delete`. Tighten it up so it takes less vertical space and looks less alarming.

**Files to change:**
- `Views/InspectorViews/RsyncParameters/RsyncParametersView.swift`

**What to do:**

1. The current "Danger Zone" section (lines 55-99) uses a large red-bordered box with padding, background tint, and a "website" button. Simplify it:

```swift
// Replace the large HStack with the red border (lines 58-114) with:
VStack(alignment: .leading, spacing: 8) {
    Text("Advanced")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(0.5)
    
    HStack {
        Toggle("--delete parameter", isOn: Binding(
            get: { selectedconfig?.parameter4 == "--delete" },
            set: { _ in parameters.adddelete(!parameters.adddelete) }
        ))
        .toggleStyle(.switch)
        .disabled(selecteduuids.isEmpty)
        
        Spacer()
        
        Link("Info", destination: URL(string: "https://rsyncui.netlify.app/docs/getting-started/important/")!)
            .font(.caption)
    }
    .padding(10)
    .background(.red.opacity(0.05))
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .overlay(
        RoundedRectangle(cornerRadius: 6)
            .stroke(.red.opacity(0.3), lineWidth: 1)
    )
    
    Toggle("Backup parameter", isOn: $backup)
        .toggleStyle(.switch)
        .onChange(of: backup) {
            guard !selecteduuids.isEmpty else {
                backup = false
                return
            }
            parameters.setbackup()
        }
}
```

2. This replaces:
   - The large "Danger Zone" title + divider + red background box + full-width "Info" button
   - The separate "Append Backup parameter" section
   
   With a compact "Advanced" section containing both toggles.

3. Also update the SSH section header from `Text("Task specific SSH parameter").font(.headline)` to the same section header style used in Step 3:

```swift
Text("SSH")
    .font(.caption)
    .fontWeight(.semibold)
    .foregroundStyle(.secondary)
    .textCase(.uppercase)
    .tracking(0.5)
```

**Test:** The Parameters tab should feel less cluttered. The --delete toggle should still work. The red tint should be subtle, not alarming. The backup toggle should work. SSH fields should display correctly.

---

## Step 10: Overall — Consistent Table Selection Behavior

**Goal:** Ensure task selection behavior is consistent between the Synchronize and Tasks views. Currently they use different table instances with different selection behaviors.

**Files to change:**
- `Views/Configurations/ConfigurationsTableDataView.swift`
- `Views/Configurations/ListofTasksAddView.swift`

**What to do:**

1. In `ListofTasksAddView.swift`, add the same context menu for double-click that `ListofTasksMainView` has. Currently double-click in the Tasks view does nothing useful:

```swift
.contextMenu(forSelectionType: SynchronizeConfiguration.ID.self) { selectedIDs in
    // Empty — context menu handled by onDeleteCommand
} primaryAction: { selectedIDs in
    // Double-click: select the first item for editing
    if let first = selectedIDs.first {
        selecteduuids = [first]
    }
}
```

2. Ensure single-click selection works the same way: clicking a row selects it and loads it in the inspector. This should already work via the `selecteduuids` binding flowing to `InspectorView` → `AddTaskView`.

3. Verify that multi-select works: selecting multiple tasks should show the "No task selected" state in the inspector (since editing multiple tasks simultaneously isn't supported), or show a summary count.

**Test:** Click a task in the list — it should be selected and the inspector should show its details. Double-click — same behavior. Select multiple tasks with Cmd+click — inspector should show the empty state. Delete key should trigger the delete confirmation.

---

## Summary of All Files Changed

| Step | File | Change |
|------|------|--------|
| 1 | `EditTabView.swift` | Labeled "Add Task" toolbar button |
| 2 | `InspectorView.swift` | Segmented control replacing TabView |
| 3 | `extensionAddTaskView+FormFields.swift`, `AddTaskContentView.swift` | Consistent section headers |
| 4 | `OpencatalogView.swift` | Better folder browse button |
| 5 | `AddTaskContentView.swift`, `InspectorView.swift` | Bottom action bar for Update button |
| 6 | `ConfigurationsTableDataView.swift` | Status dot, remove Action column, type badges |
| 7 | `ConfigurationsTableDataView.swift`, `ConfigurationsTableDataMainView.swift`, `ConfigurationsTableLoadDataView.swift` | Shorter column headers |
| 8 | `InspectorView.swift` | ContentUnavailableView empty state |
| 9 | `RsyncParametersView.swift` | Cleaner danger zone + consistent headers |
| 10 | `ListofTasksAddView.swift`, `ConfigurationsTableDataView.swift` | Consistent selection behavior |

---

## Dependencies Between Steps

Most steps are independent. Here are the exceptions:

- **Step 2 before Step 5**: The segmented control layout (Step 2) changes the inspector structure that Step 5 builds on for the bottom action bar.
- **Step 3 before Step 9**: Both establish the same section header style — do Step 3 first, then reuse in Step 9. Consider extracting the header into a shared view modifier after Step 3.
- **Step 6 before Step 7**: Step 6 restructures the table columns; Step 7 is a simple rename pass.

Recommended execution order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10
