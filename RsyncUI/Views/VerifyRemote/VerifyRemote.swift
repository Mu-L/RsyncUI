//
//  VerifyRemote.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

struct VerifyRemote: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var snapshotdata = SnapshotData()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selectedconfiguuid = Set<SynchronizeConfiguration.ID>()
    @State private var showdetails: Bool = false

    var body: some View {
        NavigationStack  {
            ListofTasksLightView(selecteduuids: $selectedconfiguuid,
                                 profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata.configurations ?? [])
                .onChange(of: selectedconfiguuid) {
                    if let configurations = rsyncUIdata.configurations {
                        if let index = configurations.firstIndex(where: { $0.id == selectedconfiguuid.first }) {
                            selectedconfig = configurations[index]
                        } else {
                            selectedconfig = nil
                        }
                    }
                }
        }
        .navigationTitle("Verify remote")
        .navigationDestination(isPresented: $showdetails) {
            if let selectedconfig {
                OutputRsyncVerifyView(config: selectedconfig, checkremote: true)
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
        }
        .toolbar(content: {
            
            ToolbarItem {
                Button {
                    showdetails = true
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(.blue)
                }
                .help("Check remote")
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

    func abort() {
        _ = InterruptProcess()
    }
}
