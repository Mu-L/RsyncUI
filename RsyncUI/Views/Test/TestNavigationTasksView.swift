//
//  TestNavigationTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/11/2023.
//

import Observation
import OSLog
import SwiftUI

struct TestNavigationTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var progressdetails: ExecuteProgressDetails
    @Bindable var estimatingprogressdetails: EstimateProgressDetails
    @State private var estimatingstate = EstimatingState()
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var showview: TestDestinationView?
    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusaborttask: Bool = false
    // Filterstring
    @State private var filterstring: String = ""
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
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
                if estimatingprogressdetails.estimatealltasksasync { progressviewestimateasync }
                if doubleclick { doubleclickaction }
            }
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.aborttask, $focusaborttask)
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
                    selecteduuids.removeAll()
                    reset()
                } label: {
                    Image(systemName: "eraser")
                }
                .help("Reset estimates")
            }

            ToolbarItem {
                Button {
                    showview = .alltasksview
                } label: {
                    Image(systemName: "list.bullet")
                }
                .help("List tasks all profiles")
            }

            ToolbarItem {
                Button {
                    if estimatingprogressdetails.tasksareestimated(selecteduuids) {
                        Logger.process.info("Info: view details for already estimated and selected task")
                        showview = .dryrunonetaskalreadyestimated
                    } else {
                        Logger.process.info("Info: iniate an execute for dryrun to view details for selected task")
                        showview = .dryrunonetask
                    }
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
}

extension TestNavigationTasksView {
    func doubleclickactionfunction() {
        if estimatingprogressdetails.getestimatedlist() == nil {
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
                  estimatingprogressdetails.executeanotherdryrun(rsyncUIdata.profile ?? "Default profile") == true
        {
            Logger.process.info("DryRun: new task same profile selected, execute a dryrun")
            doubleclick = false
            showview = .dryrunonetask

        } else if selectedconfig.config != nil,
                  estimatingprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false
        {
            Logger.process.info("DryRun: profile is changed, new task selected, execute a dryrun")
            doubleclick = false
            showview = .dryrunonetask
        }
    }

    func estimate() {
        guard estimatingprogressdetails.estimatealltasksasync == false else {
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

    func reset() {
        progressdetails.resetcounter()
        estimatingprogressdetails.resetcounts()
        estimatingstate.updatestate(state: .start)
        selectedconfig.config = nil
    }

    func abort() {
        progressdetails.resetcounter()
        estimatingprogressdetails.resetcounts()
        selecteduuids.removeAll()
        estimatingstate.updatestate(state: .start)
        _ = InterruptProcess()
        reload = true
        focusstartestimation = false
    }
}
