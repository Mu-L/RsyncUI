//
//  NavigationSummarizedAllDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import SwiftUI

struct NavigationSummarizedAllDetailsView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    var estimatedlist: [RemoteinfonumbersOnetask]

    @State private var selecteduuid = Set<Configuration.ID>()
    @State private var uuid = SelectedUUID()
    @State private var showDetails = false

    var body: some View {
        NavigationStack {
            HStack {
                Table(estimatedlist, selection: $selecteduuid) {
                    TableColumn("Synchronize ID") { data in
                        if data.datatosynchronize {
                            Text(data.backupID)
                                .foregroundColor(.blue)
                        } else {
                            Text(data.backupID)
                        }
                    }
                    .width(min: 80, max: 200)
                    TableColumn("Task", value: \.task)
                        .width(max: 80)
                    TableColumn("Local catalog", value: \.localCatalog)
                        .width(min: 100, max: 300)
                    TableColumn("Remote catalog", value: \.offsiteCatalog)
                        .width(min: 100, max: 300)
                    TableColumn("Server") { data in
                        if data.offsiteServer.count > 0 {
                            Text(data.offsiteServer)
                        } else {
                            Text("localhost")
                        }
                    }
                    .width(max: 80)
                }
                .onChange(of: selecteduuid) {
                    let selected = estimatedlist.filter { estimate in
                        selecteduuid.contains(estimate.id)
                    }
                    if (selected.count) == 1 {
                        uuid.uuid = selected[0].id
                        showDetails = true
                    } else {
                        showDetails = false
                        uuid.uuid = nil
                    }
                }

                Table(estimatedlist) {
                    TableColumn("New") { files in
                        if files.datatosynchronize {
                            Text(files.newfiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.blue)
                        } else {
                            Text(files.newfiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .width(max: 40)
                    TableColumn("Delete") { files in
                        if files.datatosynchronize {
                            Text(files.deletefiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.blue)
                        } else {
                            Text(files.deletefiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .width(max: 40)
                    TableColumn("Files") { files in
                        if files.datatosynchronize {
                            Text(files.transferredNumber)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.blue)
                        } else {
                            Text(files.transferredNumber)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .width(max: 40)
                    TableColumn("Bytes") { files in
                        if files.datatosynchronize {
                            Text(files.transferredNumberSizebytes)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.blue)
                        } else {
                            Text(files.transferredNumberSizebytes)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .width(max: 60)
                    TableColumn("Tot num") { files in
                        Text(files.totalNumber)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 80)
                    TableColumn("Tot bytes") { files in
                        Text(files.totalNumberSizebytes)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 80)
                    TableColumn("Tot dir") { files in
                        Text(files.totalDirs)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 70)
                }
            }
        }
        .navigationDestination(isPresented: $showDetails) {
            NavigationOnetaskDetails(estimatedlist: estimatedlist, selecteduuid: uuid.uuid ?? UUID())
        }
    }
}

@Observable
final class SelectedUUID {
    var uuid: Configuration.ID?
}
