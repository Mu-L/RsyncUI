//
//  SnapshotsView.swift
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
    
    var body: some View {
        
        HStack {
            
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
            
            if let selectedconfig {
                OutputRsyncVerifyView(config: selectedconfig, checkremote: true)
            }
        }
    
        .toolbar(content: {
            ToolbarItem {
                Button {
                    guard selectedconfiguuid.isEmpty == false else { return }
                } label: {
                    Image(systemName: "flag.checkered")
                }
                .help("Verify task")
            }
        })
                 
                 }
}

