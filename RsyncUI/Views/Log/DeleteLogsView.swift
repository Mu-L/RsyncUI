//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//

import SwiftUI

struct DeleteLogsView: View {
    @EnvironmentObject var logrecords: RsyncUIlogrecords
    @Binding var selecteduuids: Set<UUID>
    @Binding var isPresented: Bool
    @Binding var selectedprofile: String?

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Delete") { delete() }
                    .buttonStyle(AbortButtonStyle())

                Button("Cancel") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = NSLocalizedString("Delete", comment: "")
                + " \(selecteduuids.count) "
                + "log(s)?"
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }

    func delete() {
        logrecords.removerecords(selecteduuids)
        let deleteschedule = UpdateLogs(profile: selectedprofile,
                                        scheduleConfigurations: logrecords.logrecordsfromstore?.scheduleData.scheduleConfigurations)
        deleteschedule.deletelogs(uuids: selecteduuids)
        selecteduuids.removeAll()
        // WriteScheduleJSON(selectedprofile, logrecords.logrecordsfromstore?.scheduleData.scheduleConfigurations)
        isPresented = false
    }
}
