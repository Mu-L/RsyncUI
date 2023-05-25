//
//  DetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/10/2022.
//

import Foundation
import SwiftUI

struct DetailsView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @Binding var reload: Bool
    var selectedconfig: Configuration?

    @State private var gettingremotedata = true
    @StateObject var estimateddataonetask = Estimateddataonetask()
    @StateObject var outputfromrsync = Outputfromrsync()

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                VStack(alignment: .leading) {
                    if #available(macOS 13.0, *) {
                        Form {
                            if gettingremotedata == false {
                                HStack {
                                    VStack(alignment: .leading) {
                                        LabeledContent("Synchronize ID: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].backupID)
                                                .foregroundColor(.blue)
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
                                            Text(estimateddataonetask.estimatedlistonetask[0].offsiteServer)
                                                .foregroundColor(.blue)
                                        }
                                    }

                                    VStack(alignment: .leading) {
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
                    } else {
                        Table(estimateddataonetask.estimatedlistonetask) {
                            TableColumn("Synchronize ID", value: \.backupID)
                                .width(min: 100, max: 200)
                            TableColumn("Task", value: \.task)
                                .width(max: 80)
                            TableColumn("Local catalog", value: \.localCatalog)
                                .width(min: 80, max: 300)
                            TableColumn("Remote catalog", value: \.offsiteCatalog)
                                .width(min: 80, max: 300)
                            TableColumn("Server", value: \.offsiteServer)
                                .width(max: 70)
                            TableColumn("User", value: \.offsiteUsername)
                                .width(max: 50)
                        }
                        .frame(width: 650, height: 50, alignment: .center)
                        .foregroundColor(.blue)

                        Table(estimateddataonetask.estimatedlistonetask) {
                            TableColumn("New") { files in
                                Text(files.newfiles)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .width(max: 40)
                            TableColumn("Delete") { files in
                                Text(files.deletefiles)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .width(max: 40)
                            TableColumn("Files") { files in
                                Text(files.transferredNumber)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .width(max: 40)
                            TableColumn("Bytes") { files in
                                Text(files.transferredNumberSizebytes)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
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
                        .foregroundColor(.blue)
                        .frame(width: 450, height: 50, alignment: .center)
                    }

                    List(outputfromrsync.output) { output in
                        Text(output.line)
                            .modifier(FixedTag(750, .leading))
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()

                if gettingremotedata { ProgressView() }

                Spacer()

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
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

extension DetailsView {
    func processtermination(data: [String]?) {
        outputfromrsync.generatedata(data)
        estimateddataonetask.update(data: data, hiddenID: selectedconfig?.hiddenID, config: selectedconfig)
        gettingremotedata = false
    }
}

final class Estimateddataonetask: ObservableObject {
    @Published var estimatedlistonetask = [RemoteinfonumbersOnetask]()

    func update(data: [String]?, hiddenID: Int?, config: Configuration?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: data,
                                              config: config)
        estimatedlistonetask = [RemoteinfonumbersOnetask]()
        estimatedlistonetask.append(record)
    }
}

final class Outputfromrsync: ObservableObject {
    @Published var output = [Data]()

    struct Data: Identifiable {
        let id = UUID()
        var line: String
    }

    func generatedata(_ data: [String]?) {
        for i in 0 ..< (data?.count ?? 0) {
            if let line = data?[i] {
                output.append(Data(line: line))
            }
        }
    }
}
