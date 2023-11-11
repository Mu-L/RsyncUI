//
//  NavigationTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Observation
import OSLog
import SwiftUI

struct NavigationTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var progressdetails: ExecuteProgressDetails
    // These two objects keeps track of the state and collects
    // the estimated values.
    @State private var estimatingstate = EstimatingState()
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var showview: DestinationView?
    @Bindable var estimatingprogressdetails: EstimateProgressDetails
    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var focusaborttask: Bool = false
    // Filterstring
    @State private var filterstring: String = ""
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    // Modale view
    @State private var modaleview = false
    @State var sheetchooser = NavigationSheetChooser()
    @State var selectedconfig = Selectedconfig()
    // Double click, only for macOS13 and later
    @State private var doubleclick: Bool = false

    var body: some View {
        ZStack {
            NavigationListofTasksMainView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                reload: $reload,
                doubleclick: $doubleclick
            )
            .frame(maxWidth: .infinity)
            .onChange(of: selecteduuids) {
                let selected = rsyncUIdata.configurations?.filter { config in
                    selecteduuids.contains(config.id)
                }
                if (selected?.count ?? 0) == 1 {
                    if let config = selected {
                        selectedconfig.config = config[0]
                    }
                } else {
                    selectedconfig.config = nil
                }
            }

            // Remember max 10 in one Group
            Group {
                if focusstartestimation { labelstartestimation }
                if focusstartexecution { labelstartexecution }
                if focusaborttask { labelaborttask }
                if estimatingprogressdetails.estimateasync { progressviewestimateasync }
                if doubleclick { doubleclickaction }
            }
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .sheet(isPresented: $modaleview) { makeSheet() }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    estimate()
                } label: {
                    Image(systemName: "wand.and.stars")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.blue, .blue)
                }
                .help("Estimate (⌘E)")
            }

            ToolbarItem {
                Button {
                    execute()
                } label: {
                    Image(systemName: "arrowshape.turn.up.backward")
                }
                .help("Execute (⌘R)")
            }

            ToolbarItem {
                Button {
                    selecteduuids.removeAll()
                    reset()
                } label: {
                    Image(systemName: "eraser")
                }
                .help("Reset estimates")
            }

            ToolbarItem {
                Button {
                    sheetchooser.sheet = .alltasksview
                    modaleview = true
                } label: {
                    Image(systemName: "list.bullet")
                }
                .help("List tasks all profiles")
            }

            ToolbarItem {
                Button {
                    detailsestimatedtask()
                } label: {
                    Image(systemName: "info")
                }
                .help("Rsync output estimated task")
            }

            ToolbarItem {
                Spacer()
            }

            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
    }

    @ViewBuilder
    func makeSheet() -> some View {
        switch sheetchooser.sheet {
        case .dryrunalreadyestimated:
            DetailsOneTaskAlreadyEstimatedView(estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [],
                                               selectedconfig: selectedconfig.config)
        case .alltasksview:
            AlltasksView()
        }
    }

    var progressviewestimateasync: some View {
        AlertToast(displayMode: .alert, type: .loading)
            .onAppear {
                Task {
                    let estimate = EstimateTasksAsync(profile: rsyncUIdata.profile,
                                                      configurations: rsyncUIdata,
                                                      updateinprogresscount: estimatingprogressdetails,
                                                      uuids: selecteduuids,
                                                      filter: filterstring)
                    await estimate.startexecution()
                }
            }
            .onDisappear {
                focusstartestimation = false
                progressdetails.resetcounter()
                progressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
                showview = .estimatedview
            }
    }

    var doubleclickaction: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                doubleclickactionfunction()
                doubleclick = false
            })
    }

    var labelstartestimation: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                estimate()
            })
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                execute()
            })
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }
}

extension NavigationTasksView {
    func doubleclickactionfunction() {
        if estimatingprogressdetails.getestimatedlist() == nil {
            dryrun()
        } else if estimatingprogressdetails.tasksareestimated(selecteduuids) {
            execute()
        } else {
            dryrun()
        }
    }

    func dryrun() {
        if selectedconfig.config != nil,
           estimatingprogressdetails.getestimatedlist()?.count ?? 0 == 0
        {
            Logger.process.info("DryRun: execute a dryrun for one task only")
            doubleclick = false
            showview = .dryrunonetask
        } else if selectedconfig.config != nil,
                  estimatingprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false
        {
            Logger.process.info("DryRun: profile is changed, new task selected, execute a dryrun")
            doubleclick = false
            showview = .dryrunonetask
        } else {
            // New profile is selected, just return no action
            return
        }
    }

    func detailsestimatedtask() {
        // DryRun: all tasks already estimated, show details on task
        guard progressdetails.taskisestimatedbyUUID(selectedconfig.config?.id ?? UUID()) == true else { return }
        Logger.process.info("DryRun: task is already estimated, show details on task")
        sheetchooser.sheet = .dryrunalreadyestimated
        modaleview = true
    }

    func estimate() {
        guard estimatingprogressdetails.estimateasync == false else {
            Logger.process.info("TasksView: estimate already in progress")
            return
        }
        if selectedconfig.config != nil {
            let profile = selectedconfig.config?.profile ?? "Default profile"
            if profile != rsyncUIdata.profile {
                selecteduuids.removeAll()
                selectedconfig.config = nil
            }
        }
        estimatingprogressdetails.resetcounts()
        progressdetails.resetcounter()
        estimatingprogressdetails.startestimateasync()
    }

    func execute() {
        // All tasks are estimated and ready for execution.
        if selecteduuids.count == 0,
           estimatingprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == true

        {
            Logger.process.info("Execute() all estimated tasks")
            // Execute all estimated tasks
            selecteduuids = estimatingprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            showview = .executestimatedview

        } else if selecteduuids.count >= 1,
                  estimatingprogressdetails.tasksareestimated(selecteduuids) == true

        {
            // One or some tasks are selected and estimated
            Logger.process.info("Execute() estimated tasks only")
            // Execute estimated tasks only
            // Execute all estimated tasks
            selecteduuids = estimatingprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            showview = .executestimatedview
        } else {
            // Execute all tasks, no estimate
            Logger.process.info("Execute() selected or all tasks NO estimate")
            // Execute tasks, no estimate
            showview = .executenoestimatetasksview
        }
    }

    func reset() {
        progressdetails.resetcounter()
        estimatingprogressdetails.resetcounts()
        estimatingstate.updatestate(state: .start)
        selectedconfig.config = nil
        estimatingprogressdetails.estimateasync = false
        estimatingprogressdetails.estimatedlist = nil
        showview = .taskview
    }

    func abort() {
        progressdetails.resetcounter()
        selecteduuids.removeAll()
        estimatingstate.updatestate(state: .start)
        estimatingprogressdetails.resetcounts()
        _ = InterruptProcess()
        reload = true
        focusstartestimation = false
        focusstartexecution = false
    }
}

enum NavigationSheet: String, Identifiable {
    case dryrunalreadyestimated, alltasksview
    var id: String { rawValue }
}

@Observable
final class NavigationSheetChooser {
    // Which sheet to present
    // Do not redraw view when changing
    // no @Publised
    @ObservationIgnored
    var sheet: NavigationSheet = .alltasksview
}

@Observable
final class NavigationSelectedconfig {
    var config: Configuration?
}

// swiftlint:enable line_length file_length
