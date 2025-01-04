//
//  TimerView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/12/2024.
//

import SwiftUI

struct TimerView: View {
    @Environment(\.dismiss) var dismiss

    @Bindable var executeprogressdetails: ExecuteProgressDetails
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var path: [Tasks]

    @State var startDate = Date.now
    @State var timetosynchronize: Int = 5
    @State var timeosynchronizestring: String = "5"

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(timeosynchronizestring) {
            dismiss()
        }
        .buttonStyle(ColorfulButtonStyle())
        .onReceive(timer) { firedDate in
            timetosynchronize -= Int(firedDate.timeIntervalSince(startDate))
            timeosynchronizestring = String(timetosynchronize)

            if timetosynchronize < 0 {
                executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                path.removeAll()
                path.append(Tasks(task: .executestimatedview))
            }
        }
    }
}
