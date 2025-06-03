//
//  SummarizedDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import OSLog
import SwiftUI

struct SummarizedDetailsView: View {
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var path: [Tasks]

    @State private var focusstartexecution: Bool = false
    @State private var isPresentingConfirm: Bool = false

    let configurations: [SynchronizeConfiguration]
    let profile: String?
    // URL code
    let queryitem: URLQueryItem?

    var body: some View {
        VStack {
            HStack {
                if estimateprogressdetails.estimatealltasksinprogress {
                    EstimationInProgressView(estimateprogressdetails: executeprogressdetails,
                                             estimateprogressdetails: estimateprogressdetails,
                                             selecteduuids: $selecteduuids,
                                             profile: profile,
                                             configurations: configurations)
                        .onDisappear {
                            let datatosynchronize = estimateprogressdetails.estimatedlist?.compactMap { element in
                                element.datatosynchronize ? true : nil
                            }
                            if let datatosynchronize {
                                if datatosynchronize.count == 0,
                                   SharedReference.shared.alwaysshowestimateddetailsview == false
                                {
                                    path.removeAll()
                                }
                            }
                        }
                } else {
                    leftcolumndetails

                    rightcolumndetails
                }
            }
            .toolbar(content: {
                if datatosynchronizeURL {
                    ToolbarItem {
                        TimerView(estimateprogressdetails: executeprogressdetails,
                                  estimateprogressdetails: estimateprogressdetails,
                                  path: $path)
                    }

                    ToolbarItem {
                        Spacer()
                    }
                }

                if datatosynchronize {
                    if SharedReference.shared.confirmexecute {
                        ToolbarItem {
                            Button {
                                isPresentingConfirm = estimateprogressdetails.confirmexecutetasks()
                                if isPresentingConfirm == false {
                                    executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                                    path.removeAll()
                                    path.append(Tasks(task: .executestimatedview))
                                }
                            } label: {
                                Image(systemName: "play")
                                    .foregroundColor(Color(.blue))
                            }
                            .help("Synchronize (⌘R)")
                            .confirmationDialog("Synchronize tasks?",
                                                isPresented: $isPresentingConfirm)
                            {
                                Button("Synchronize", role: .destructive) {
                                    executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                                    path.removeAll()
                                    path.append(Tasks(task: .executestimatedview))
                                }
                            }
                        }
                    } else {
                        ToolbarItem {
                            Button {
                                executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                                path.removeAll()
                                path.append(Tasks(task: .executestimatedview))
                            } label: {
                                Image(systemName: "play.fill")
                                    .foregroundColor(Color(.blue))
                            }
                            .help("Synchronize (⌘R)")
                        }
                    }

                    ToolbarItem {
                        Spacer()
                    }
                }
            })
            .frame(maxWidth: .infinity)
            .focusedSceneValue(\.startexecution, $focusstartexecution)
            .onAppear {
                guard estimateprogressdetails.estimatealltasksinprogress == false else {
                    Logger.process.warning("SummarizedDetailsView: estimate already in progress")
                    return
                }
                estimateprogressdetails.resetcounts()
                executeprogressdetails.estimatedlist = nil
                estimateprogressdetails.startestimation()
            }
        }

        Spacer()

        if focusstartexecution { labelstartexecution }
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                path.removeAll()
                path.append(Tasks(task: .executestimatedview))
                focusstartexecution = false
            })
    }

    // URL code
    var datatosynchronizeURL: Bool {
        if queryitem != nil, estimateprogressdetails.estimatealltasksinprogress == false {
            let datatosynchronize = estimateprogressdetails.estimatedlist?.filter { $0.datatosynchronize == true }
            if (datatosynchronize?.count ?? 0) > 0 {
                return true
            } else {
                return false
            }
        }
        return false
    }

    var datatosynchronize: Bool {
        if queryitem == nil, estimateprogressdetails.estimatealltasksinprogress == false {
            let datatosynchronize = estimateprogressdetails.estimatedlist?.filter { $0.datatosynchronize == true }
            if (datatosynchronize?.count ?? 0) > 0 {
                return true
            } else {
                return false
            }
        }
        return false
    }

    var leftcolumndetails: some View {
        Table(estimateprogressdetails.estimatedlist ?? [],
              selection: $selecteduuids)
        {
            TableColumn("Synchronize ID") { data in
                if data.datatosynchronize {
                    if data.backupID.isEmpty == true {
                        Text("Synchronize ID")
                            .foregroundColor(.blue)
                    } else {
                        Text(data.backupID)
                            .foregroundColor(.blue)
                    }
                } else {
                    if data.backupID.isEmpty == true {
                        Text("Synchronize ID")
                    } else {
                        Text(data.backupID)
                    }
                }
            }
            .width(min: 40, max: 80)
            TableColumn("Task", value: \.task)
                .width(max: 60)
            TableColumn("Local folder", value: \.localCatalog)
                .width(min: 100, max: 300)
            TableColumn("Remote folder", value: \.offsiteCatalog)
                .width(min: 100, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(max: 60)
        }
        .onAppear {
            if selecteduuids.count > 0 {
                // Reset preselected tasks, must do a few seconds timout
                // before clearing it out
                Task {
                    try await Task.sleep(seconds: 2)
                    selecteduuids.removeAll()
                }
            }
        }
    }

    var rightcolumndetails: some View {
        Table(estimateprogressdetails.estimatedlist ?? [],
              selection: $selecteduuids)
        {
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
            TableColumn("Updates") { files in
                if files.datatosynchronize {
                    Text(files.filestransferred)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(.blue)
                } else {
                    Text(files.filestransferred)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(max: 55)
            TableColumn("kB trans") { files in
                if files.datatosynchronize {
                    Text("\(files.totaltransferredfilessize_Int / 1000)")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(.blue)
                } else {
                    Text("\(files.totaltransferredfilessize_Int / 1000)")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(max: 60)
            TableColumn("Tot files") { files in
                Text(files.numberoffiles)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 90)
            TableColumn("Tot kB") { files in
                Text("\(files.totalfilesize_Int / 1000)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 80)
            TableColumn("Tot cat") { files in
                Text(files.totaldirectories)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 70)
        }
        .onChange(of: selecteduuids) {
            guard selecteduuids.count > 0 else { return }
            path.append(Tasks(task: .dryrunonetaskalreadyestimated))
        }
    }
}
