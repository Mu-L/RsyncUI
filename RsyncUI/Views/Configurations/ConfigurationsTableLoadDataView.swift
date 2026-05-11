//
//  ConfigurationsTableLoadDataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/12/2025.
//

import SwiftUI

struct ConfigurationsTableLoadDataView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var uuidprofile: ProfilesnamesRecord.ID?

    @State private var configurations: [SynchronizeConfiguration]?

    var body: some View {
        Table(configurations ?? []) {
            TableColumn("Synchronize ID") { data in
                HStack(spacing: 4) {
                    if data.parameter4?.isEmpty == false {
                        if data.backupID.isEmpty == true {
                            Text("No ID set")
                                .foregroundStyle(.red)
                        } else {
                            Text(data.backupID)
                                .foregroundStyle(.red)
                        }
                    } else {
                        if data.backupID.isEmpty == true {
                            Text("No ID set")
                                .foregroundStyle(.blue)
                        } else {
                            Text(data.backupID)
                                .foregroundStyle(.blue)
                        }
                    }

                    ConfigurationTaskBadge(task: data.task)
                }
            }
            .width(min: 90, max: 200)

            TableColumn("Source", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Destination", value: \.offsiteCatalog)
                .width(min: 80, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 50, max: 90)
        }
        .task(id: uuidprofile) {
            configurations = []
            let record = rsyncUIdata.validprofiles.filter { $0.id == uuidprofile }
            guard record.count > 0 else { return }
            let profile = record[0].profilename
            configurations = await ReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profile,
                                                       SharedReference.shared.rsyncversion3)
        }
    }
}
