//
//  LogsbyConfigurationView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct LogsbyConfigurationView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @State private var filterstring: String = ""
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var selectedloguuids = Set<Log.ID>()
    @State private var reload: Bool = false
    @State private var hiddenID = -1
    // Alert for delete
    @State private var showAlertfordelete = false

    var logrecords: RsyncUIlogrecords

    var body: some View {
        VStack {
            HStack {
                ListofTasksLightView(
                    selecteduuids: $selecteduuids
                )
                .onChange(of: selecteduuids) {
                    let selected = rsyncUIdata.configurations?.filter { config in
                        selecteduuids.contains(config.id)
                    }
                    if (selected?.count ?? 0) == 1 {
                        if let config = selected {
                            hiddenID = config[0].hiddenID
                        }
                    } else {
                        hiddenID = -1
                    }
                    Task {
                        if hiddenID == -1 {
                            await logrecordsbyfilter()
                        } else {
                            await logrecordsbyhiddenIDandfilter()
                        }
                    }
                }

                Table(logrecords.activelogrecords ?? [], selection: $selectedloguuids) {
                    TableColumn("Date") { data in
                        Text(data.date.localized_string_from_date())
                    }

                    TableColumn("Result") { data in
                        if let result = data.resultExecuted {
                            Text(result)
                        }
                    }
                }
                .onDeleteCommand {
                    showAlertfordelete = true
                }
                .onChange(of: filterstring) {
                    Task {
                        if hiddenID == -1 {
                            await logrecordsbyfilter()
                        } else {
                            await logrecordsbyhiddenIDandfilter()
                        }
                    }
                }
                .overlay {
                    if logrecords.activelogrecords?.count == 0 {
                        ContentUnavailableView.search
                    }
                }
            }

            HStack {
                Text(numberoflogs)

                Spacer()
            }
        }
        .searchable(text: $filterstring)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    selectedloguuids.removeAll()
                } label: {
                    Image(systemName: "eraser")
                }
                .tooltip("Reset selections")
            }
        })
        .sheet(isPresented: $showAlertfordelete) {
            DeleteLogsView(selecteduuids: $selectedloguuids,
                           selectedprofile: rsyncUIdata.profile,
                           logrecords: logrecords)
        }
    }

    var numberoflogs: String {
        return NSLocalizedString("Number of logs", comment: "") + ": " +
            "\((logrecords.activelogrecords ?? []).count)"
    }

    func logrecordsbyfilter() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        logrecords.filterlogs(filterstring)
    }

    func logrecordsbyhiddenIDandfilter() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        if filterstring.count == 0 {
            logrecords.filterlogsbyhiddenID(hiddenID)
        } else {
            logrecords.filterlogsbyhiddenIDandfilter(filterstring, hiddenID)
        }
    }
}
