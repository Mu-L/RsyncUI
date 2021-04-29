//
//  SnapshotListView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotListView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @EnvironmentObject var snapshotdata: SnapshotData

    @Binding var selectedconfig: Configuration?
    @Binding var snapshotrecords: Logrecordsschedules?
    @Binding var selecteduuids: Set<UUID>

    var body: some View {
        Divider()

        List(selection: $snapshotrecords) {
            if let logs = snapshotdata.getsnapshotdata() {
                ForEach(logs) { record in
                    SnapshotRow(selecteduuids: $selecteduuids, logrecord: record)
                        .tag(record)
                }
            }
        }
    }
}
