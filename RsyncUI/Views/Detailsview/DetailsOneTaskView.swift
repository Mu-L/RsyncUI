//
//  DetailsOneTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/10/2022.
//
// swiftlint: disable line_length

import Foundation
import Observation
import SwiftUI

struct DetailsOneTaskView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(EstimateProgressDetails.self) var inprogresscountmultipletask

    var selectedconfig: Configuration?

    @State private var gettingremotedata = true
    @State private var estimateddataonetask = Estimateddataonetask()
    @State private var outputfromrsync = Outputfromrsync()

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                VStack(alignment: .leading) {
                    Form {
                        if gettingremotedata == false {
                            HStack {
                                VStack(alignment: .leading) {
                                    LabeledContent("Synchronize ID: ") {
                                        if estimateddataonetask.estimatedlistonetask[0].backupID.count == 0 {
                                            Text("Synchronize ID")
                                                .foregroundColor(.blue)
                                        } else {
                                            Text(estimateddataonetask.estimatedlistonetask[0].backupID)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    LabeledContent("Task: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].task)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Local catalog: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].localCatalog)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Remote catalog: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].offsiteCatalog)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Server: ") {
                                        if estimateddataonetask.estimatedlistonetask[0].offsiteServer.count == 0 {
                                            Text("localhost")
                                                .foregroundColor(.blue)
                                        } else {
                                            Text(estimateddataonetask.estimatedlistonetask[0].offsiteServer)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    LabeledContent("New: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].newfiles)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Delete: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].deletefiles)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Files: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].transferredNumber)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Bytes: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].transferredNumberSizebytes)
                                            .foregroundColor(.blue)
                                    }
                                }

                                VStack(alignment: .trailing) {
                                    LabeledContent("Tot num: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].totalNumber)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Tot bytes: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].totalNumberSizebytes)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Tot dir: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].totalDirs)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }

                    Table(outputfromrsync.output) {
                        TableColumn("Output") { data in
                            Text(data.line)
                        }
                        .width(min: 800)
                    }
                }

                if gettingremotedata { AlertToast(displayMode: .alert, type: .loading) }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismiss() }
                    .buttonStyle(ColorfulButtonStyle())
            }
        }
        .onAppear(perform: {
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentssynchronize(dryRun: true, forDisplay: false)
            guard arguments != nil else { return }
            let task = RsyncAsync(arguments: arguments,
                                  processtermination: processtermination)
            Task {
                await task.executeProcess()
            }
        })
        .padding()
        .frame(minWidth: 900, minHeight: 500)
    }
}

extension DetailsOneTaskView {
    func processtermination(data: [String]?) {
        outputfromrsync.generatedata(data)
        estimateddataonetask.update(data: data, hiddenID: selectedconfig?.hiddenID, config: selectedconfig)
        gettingremotedata = false
        // Adding computed estimate if later execute and view of progress
        if estimateddataonetask.estimatedlistonetask.count == 1 {
            inprogresscountmultipletask.resetcounts()
            inprogresscountmultipletask.appenduuid(selectedconfig?.id ?? UUID())
            inprogresscountmultipletask.appendrecordestimatedlist(estimateddataonetask.estimatedlistonetask[0])
        }
    }
}

@Observable
final class Estimateddataonetask {
    var estimatedlistonetask = [RemoteinfonumbersOnetask]()

    func update(data: [String]?, hiddenID: Int?, config: Configuration?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: data,
                                              config: config)
        estimatedlistonetask = [RemoteinfonumbersOnetask]()
        estimatedlistonetask.append(record)
    }
}

@Observable
final class Outputfromrsync {
    var output = [Data]()

    struct Data: Identifiable {
        let id = UUID()
        var line: String
    }

    func outputistruncated(_ number: Int) -> Bool {
        do {
            if number > 20000 { throw OutputIsTruncated.istruncated }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return true
        }
        return false
    }

    func generatedata(_ data: [String]?) {
        var count = data?.count
        let summarycount = data?.count
        if count ?? 0 > 20000 { count = 20000 }
        // Show the 10,000 first lines
        for i in 0 ..< (count ?? 0) {
            if let line = data?[i] {
                output.append(Data(line: line))
            }
        }
        if outputistruncated(summarycount ?? 0) {
            output.append(Data(line: ""))
            output.append(Data(line: "**** Summary *****"))
            for i in ((summarycount ?? 0) - 20) ..< (summarycount ?? 0) - 1 {
                if let line = data?[i] {
                    output.append(Data(line: line))
                }
            }
        }
    }
}

extension Outputfromrsync {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

enum OutputIsTruncated: LocalizedError {
    case istruncated

    var errorDescription: String? {
        switch self {
        case .istruncated:
            return "Output from rsync was truncated"
        }
    }
}

// swiftlint: enable line_length
