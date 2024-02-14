//
//  LogsbyConfigurationView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import Combine
import SwiftUI

struct LogsbyConfigurationView: View {
    @Bindable var rsyncUIlogrecords: RsyncUIlogrecords

    @State private var hiddenID = -1
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedloguuids = Set<Log.ID>()
    // Alert for delete
    @State private var showAlertfordelete = false
    // Filterstring
    @State private var filterstring: String = ""
    @State var publisher = PassthroughSubject<String, Never>()
    @State private var debouncefilterstring: String = ""
    @State private var showindebounce: Bool = false

    @State private var sortOrder = [KeyPathComparator(\Log.resultExecuted, order: .reverse)]
    @State private var logs: [Log] = []

    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        VStack {
            HStack {
                ListofTasksLightView(selecteduuids: $selecteduuids,
                                     profile: profile,
                                     configurations: configurations)
                    .onChange(of: selecteduuids) {
                        if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                            hiddenID = configurations[index].hiddenID
                        } else {
                            hiddenID = -1
                        }
                        Task {
                            await updatelogs()
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
                Text("Number of log records: ")

                if showindebounce {
                    indebounce
                } else {
                    Text("\(logs.count)")
                }
                Spacer()
            }
        }
        .searchable(text: $filterstring)
        .onAppear {
            Task {
                await updatelogs()
            }
        }
        .onChange(of: filterstring) {
            showindebounce = true
            publisher.send(filterstring)
        }
        .onReceive(
            publisher.debounce(
                for: .seconds(1),
                scheduler: DispatchQueue.main
            )
        ) { filter in
            showindebounce = false
            debouncefilterstring = filter
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    selectedloguuids.removeAll()
                    selecteduuids.removeAll()

                } label: {
                    Image(systemName: "clear")
                }
                .help("Reset selections")
            }
        })
        .sheet(isPresented: $showAlertfordelete) {
            DeleteLogsView(
                rsyncUIlogrecords: rsyncUIlogrecords,
                selectedloguuids: $selectedloguuids,
                selectedprofile: profile
            )
        }
    }

    var indebounce: some View {
        ProgressView()
            .controlSize(.small)
    }

    // TODO: fix filter
    func updatelogs() async {
        if let logrecords = rsyncUIlogrecords.logrecords {
            if hiddenID == -1 {
                var merged = [Log]()
                for i in 0 ..< logrecords.count {
                    merged += [logrecords[i].logrecords ?? []].flatMap { $0 }
                }
                // return merged.sorted(by: \.date, using: >)
                logs = merged.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
            } else {
                if let index = logrecords.firstIndex(where: { $0.hiddenID == hiddenID }) {
                    logs = (logrecords[index].logrecords ?? []).sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                }
            }
        }
    }
}

/*
 .filter { ($0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(debouncefilterstring) ?? false) || $0.resultExecuted?.contains(debouncefilterstring) ?? false }
 */
