//
//  ActorsLogsbyConfigurationView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//
// swiftlint: disable line_length

import SwiftUI

@MainActor
struct ActorsLogsbyConfigurationView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var hiddenID = -1
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedloguuids = Set<Log.ID>()
    // Alert for delete
    @State private var showAlertfordelete = false
    // Filterstring
    @State private var filterstring: String = ""
    @State private var showindebounce: Bool = false

    @State private var logrecords: [LogRecords]?
    @State private var logs: [Log] = []

    var body: some View {
        VStack {
            HStack {
                ZStack {
                    ListofTasksLightView(selecteduuids: $selecteduuids,
                                         profile: rsyncUIdata.profile,
                                         configurations: configurations)
                        .onChange(of: selecteduuids) {
                            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                hiddenID = configurations[index].hiddenID
                            } else {
                                hiddenID = -1
                            }
                            Task {
                                if filterstring != "" {
                                    await updatelogsbyfilter()
                                } else {
                                    await updatelogsbyhiddenID()
                                }
                            }
                        }
                }

                Table(logs, selection: $selectedloguuids) {
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
                .overlay { if logs.count == 0 {
                    ContentUnavailableView {
                        Label("There are no logs by this filter", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for other filter in Date or Result")
                    }
                }
                }
            }

            HStack {
                if showindebounce {
                    indebounce
                } else {
                    Text("Counting ^[\(logs.count) log](inflect: true)")
                }
                Spacer()
            }
        }
        .navigationTitle("Log listing")
        .searchable(text: $filterstring)
        .onAppear {
            Task {
                await logrecords =
                    ActorReadLogRecordsJSON().readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs, SharedReference.shared.filenamelogrecordsjson)
                await updatelogsbyhiddenID()
            }
        }
        .onChange(of: filterstring) {
            showindebounce = true
            Task {
                try await Task.sleep(seconds: 1)
                showindebounce = false
                if filterstring.isEmpty == false {
                    Task {
                        await updatelogsbyfilter()
                    }
                } else {
                    Task {
                        await updatelogsbyhiddenID()
                    }
                }
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            Task {
                await logrecords =
                    ActorReadLogRecordsJSON().readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs, SharedReference.shared.filenamelogrecordsjson)
                await updatelogsbyhiddenID()
            }
        }
        .onChange(of: logrecords) {
            Task {
                await logrecords =
                    ActorReadLogRecordsJSON().readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs, SharedReference.shared.filenamelogrecordsjson)
                await updatelogsbyhiddenID()
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    selectedloguuids.removeAll()
                    selecteduuids.removeAll()

                } label: {
                    if selectedloguuids.count == 0 {
                        Image(systemName: "clear")
                    } else {
                        Image(systemName: "clear")
                            .foregroundColor(Color(.red))
                    }
                }
                .help("Reset selections")
            }
        })
        .sheet(isPresented: $showAlertfordelete) {
            DeleteLogsView(
                selectedloguuids: $selectedloguuids,
                logrecords: $logrecords,
                selectedprofile: rsyncUIdata.profile
            )
        }
    }

    var indebounce: some View {
        ProgressView()
            .controlSize(.small)
    }

    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        _ = configurations.map { record in
            temp.insert(record.hiddenID)
        }
        return temp
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = rsyncUIdata.configurations {
            configurations
        } else {
            []
        }
    }

    func updatelogsbyfilter() async {
        guard filterstring != "" else { return }
        if let logrecords {
            if hiddenID == -1 {
                var merged = [Log]()
                _ = logrecords.map { logrecord in
                    if let logrecords = logrecord.logrecords {
                        merged += [logrecords].flatMap(\.self)
                    }
                }
                let records = merged.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                logs = records.filter { ($0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filterstring)) ?? false || ($0.resultExecuted?.contains(filterstring) ?? false)
                }
            } else {
                if let index = logrecords.firstIndex(where: { $0.hiddenID == hiddenID }),
                   let logrecords = logrecords[index].logrecords
                {
                    let records = logrecords.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                    logs = records.filter { ($0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filterstring)) ?? false || ($0.resultExecuted?.contains(filterstring) ?? false)
                    }
                }
            }
        }
    }

    func updatelogsbyhiddenID() async {
        if let logrecords {
            if hiddenID == -1 {
                var merged = [Log]()
                _ = logrecords.map { logrecord in
                    if let logrecords = logrecord.logrecords {
                        merged += [logrecords].flatMap(\.self)
                    }
                }
                // return merged.sorted(by: \.date, using: >)
                logs = merged.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
            } else {
                if let index = logrecords.firstIndex(where: { $0.hiddenID == hiddenID }),
                   let logrecords = logrecords[index].logrecords
                {
                    logs = logrecords.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                }
            }
        }
    }
}

// swiftlint: enable line_length
