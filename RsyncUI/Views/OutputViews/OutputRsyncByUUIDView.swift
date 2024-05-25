//
//  OutputRsyncByUUIDView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/05/2024.
//

import SwiftUI

struct OutputRsyncByUUIDView: View {
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var outputfromrsync = ObservableOutputfromrsync()

    var body: some View {
        VStack {
            Table(outputfromrsync.output) {
                TableColumn("Output from rsync") { data in
                    Text(data.line)
                }
            }
        }
        .padding()
        .onAppear {
            outputfromrsync.generateoutput(rsyncoutput)
        }
        .onChange(of: selecteduuids) {
            outputfromrsync.output.removeAll()
            outputfromrsync.generateoutput(rsyncoutput)
        }
    }

    var rsyncoutput: [String] {
        if let index = estimateprogressdetails.estimatedlist?.firstIndex(where: { $0.id == selecteduuids.first }) {
            return estimateprogressdetails.estimatedlist?[index].outputfromrsync ?? []
        } else {
            return ["Either select a task or the task is not estimated"]
        }
    }
}
