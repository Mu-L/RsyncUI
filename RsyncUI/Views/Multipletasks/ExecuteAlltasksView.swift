//
//  ExecuteAlltasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 15/02/2021.
//

import SwiftUI

struct ExecuteAlltasksView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var selecteduuids: Set<UUID>
    @Binding var isPresented: Bool
    @Binding var presentestimatedsheetview: Bool

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button(NSLocalizedString("Execute all", comment: "Execute button")) { executeall() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Cancel", comment: "Cancel button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = NSLocalizedString("Execute all tasks", comment: "Alert delete") + "?"
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }

    func executeall() {
        selecteduuids.removeAll()
        for i in 0 ..< (rsyncUIData.rsyncdata?.configurationData.getnumberofconfigurations() ?? 0) {
            if let id = rsyncUIData.rsyncdata?.configurationData.getallconfigurations()?[i].id {
                selecteduuids.insert(id)
            }
        }
        isPresented = false
        presentestimatedsheetview = true
    }
}
