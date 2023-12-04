//
//  NavigationExecuteEstimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import SwiftUI

struct NavigationExecuteEstimatedTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @EnvironmentObject var executeprogressdetails: ExecuteProgressDetails

    @Binding var selecteduuids: Set<UUID>
    @Binding var reload: Bool
    @Binding var path: [Tasks]

    @State private var multipletaskstate = MultipleTaskState()
    @State private var selectedconfig: Configuration?
    @State private var filterstring: String = ""
    @State private var focusaborttask: Bool = false
    @State private var doubleclick: Bool = false

    var body: some View {
        ZStack {
            ListofTasksMainView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                reload: $reload,
                doubleclick: $doubleclick,
                showestimateicon: false
            )

            if multipletaskstate.executionstate == .completed { labelcompleted }
            if multipletaskstate.executionstate == .execute { AlertToast(displayMode: .alert, type: .loading) }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            executemultipleestimatedtasks()
        })
        .onDisappear(perform: {
            executeprogressdetails.resetcounter()
        })
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
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

    // When status execution is .completed, present label and execute completed.
    var labelcompleted: some View {
        Label(multipletaskstate.executionstate.rawValue, systemImage: "play.fill")
            .onAppear(perform: {
                completed()
                path.removeAll()
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

extension NavigationExecuteEstimatedTasksView {
    func completed() {
        executeprogressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        selecteduuids.removeAll()
        path.removeAll()
        reload = true
    }

    func abort() {
        executeprogressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        selecteduuids.removeAll()
        _ = InterruptProcess()
        path.removeAll()
        reload = true
    }

    func executemultipleestimatedtasks() {
        var uuids: Set<Configuration.ID>?
        if selecteduuids.count > 0 {
            uuids = selecteduuids
        } else if executeprogressdetails.estimatedlist?.count ?? 0 > 0 {
            let uuidcount = executeprogressdetails.estimatedlist?.compactMap { $0.id }
            uuids = Set<Configuration.ID>()
            for i in 0 ..< (uuidcount?.count ?? 0) where
                executeprogressdetails.estimatedlist?[i].datatosynchronize == true
            {
                uuids?.insert(uuidcount?[i] ?? UUID())
            }
        }
        guard (uuids?.count ?? 0) > 0 else { return }
        if let uuids = uuids {
            multipletaskstate.updatestate(state: .execute)
            ExecuteMultipleTasks(uuids: uuids,
                                 profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata,
                                 multipletaskstateDelegate: multipletaskstate,
                                 executeprogressdetailsDelegate: executeprogressdetails)
        }
    }
}
