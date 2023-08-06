//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct LogsbyConfigurationView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var filterstring: String

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
                    selecteduuids: $selecteduuids.onChange {
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
                    }
                )

                Table(logdetails, selection: $selectedloguuids) {
                    TableColumn("Date") { data in
                        Text(data.date.localized_string_from_date())
                    }

                    TableColumn("Result") { data in
                        if let result = data.resultExecuted {
                            Text(result)
                        }
                    }
                }
            }

            HStack {
                Text(numberoflogs)

                Spacer()

                Button("Reset") { selectedloguuids.removeAll() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Delete") { showAlertfordelete = true }
                    .buttonStyle(AbortButtonStyle())
                    .sheet(isPresented: $showAlertfordelete) {
                        DeleteLogsView(selecteduuids: $selectedloguuids,
                                       selectedprofile: rsyncUIdata.profile,
                                       logrecords: logrecords)
                    }
            }
        }
        .searchable(text: $filterstring)
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " +
            "\(logdetails.count)"
    }

    var logdetails: [Log] {
        if hiddenID == -1 {
            return logrecords.filterlogs(filterstring) ?? []
        } else {
            return logrecords.filterlogsbyhiddenID(filterstring, hiddenID) ?? []
        }
    }
}
