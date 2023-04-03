//
//  DetailsViewAlreadyEstimted.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/11/2022.
//

import Foundation
import SwiftUI

struct DetailsViewAlreadyEstimated: View {
    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var isPresented: Bool
    var estimatedlist: [RemoteinfonumbersOnetask]
    @StateObject var outputfromrsync = Outputfromrsync()

    var body: some View {
        VStack {
            VStack {
                Table(estimatedlistonetask) {
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

                Table(estimatedlistonetask) {
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
                // .frame(maxHeight: 50, maxWidth: 300)
                .foregroundColor(.blue)
                .frame(width: 450, height: 50, alignment: .center)
            }

            List(outputfromrsync.output) { output in
                Text(output.line)
                    .modifier(FixedTag(750, .leading))
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 900, minHeight: 500)
        .onAppear {
            let output: [RemoteinfonumbersOnetask] = estimatedlist.filter { $0.id == selectedconfig?.id }
            if output.count > 0 {
                outputfromrsync.generatedata(output[0].outputfromrsync)
            }
        }
    }

    var estimatedlistonetask: [RemoteinfonumbersOnetask] {
        return estimatedlist.filter { $0.id == selectedconfig?.id }
    }
}

extension DetailsViewAlreadyEstimated {
    func dismissview() {
        isPresented = false
    }
}
