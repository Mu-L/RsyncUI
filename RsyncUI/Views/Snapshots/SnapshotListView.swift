//
//  SnapshotListView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotListView: View {
    @Binding var snapshotdata: ObservableSnapshotData
    @Binding var filterstring: String

    @Binding var selectedconfig: SynchronizeConfiguration?
    @State private var confirmdelete: Bool = false

    var body: some View {
        Table(logrecords, selection: $snapshotdata.snapshotuuidsfordelete) {
            TableColumn("Snap") { data in
                if let snapshotCatalog = data.snapshotCatalog {
                    Text(snapshotCatalog)
                }
            }
            .width(max: 40)

            TableColumn("Date") { data in
                Text(data.dateExecuted)
            }
            .width(max: 150)
            TableColumn("Tag") { data in
                if let period = data.period {
                    if period.contains("Delete") {
                        Text(period)
                            .foregroundColor(.red)
                    } else {
                        Text(period)
                    }
                }
            }
            .width(max: 200)
            TableColumn("Last") { data in
                if let days = data.latest {
                    Text(days)
                }
            }
            .width(max: 60)
            TableColumn("Result") { data in
                Text(data.resultExecuted)
            }
            .width(max: 250)
        }
        .confirmationDialog(snapshotdata.snapshotuuidsfordelete.count == 1 ? "Delete 1 snapshot" :
                                "Delete \(snapshotdata.snapshotuuidsfordelete.count) snapshots",
            isPresented: $confirmdelete
        ) {
            Button("Delete") {
                delete()
                confirmdelete = false
            }
        }
        .onDeleteCommand {
            confirmdelete = true
        }
        .overlay {
            if logrecords.count == 0,
               selectedconfig != nil,
               selectedconfig?.task == SharedReference.shared.snapshot,
               snapshotdata.snapshotlist == false
            {
                ContentUnavailableView {
                    Label("There are no snapshot records by this search string in Date or Tag",
                          systemImage: "doc.richtext.fill")
                } description: {
                    Text("Change search string to filter records")
                }
            }
        }
    }

    var logrecords: [LogRecordSnapshot] {
        if filterstring.isEmpty {
            snapshotdata.getsnapshotdata() ?? []
        } else {
            snapshotdata.getsnapshotdata()?.filter { ($0.dateExecuted).contains(filterstring) ||
                ($0.period ?? "").contains(filterstring)
            } ?? []
        }
    }

    func delete() {
        if let config = selectedconfig {
            snapshotdata.delete = DeleteSnapshots(config: config,
                                                  snapshotdata: snapshotdata,
                                                  logrecordssnapshot: snapshotdata.getsnapshotdata())
            snapshotdata.inprogressofdelete = true
            snapshotdata.delete?.deletesnapshots()
        }
    }
}
