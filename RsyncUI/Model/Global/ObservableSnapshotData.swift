//
//  SnapshotData.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import Foundation
import Observation
import OSLog

@Observable
final class ObservableSnapshotData {
    var maxnumbertodelete: Int = 0
    var remainingsnapshotstodelete: Int = 0
    // Deleteobject
    var delete: DeleteSnapshots?
    var inprogressofdelete: Bool = false
    // Show progress view when getting data
    var snapshotlist: Bool = false
    // UUIDs for DELETE snapshots
    var snapshotuuidsfordelete = Set<LogRecordSnapshot.ID>()
    var catalogsanddates: [Catalogsanddates] = []
    var logrecordssnapshot: [LogRecordSnapshot]?
    // Originally loaded logrecords, to be used if cleaning up logrecords
    // with no snapshot catalogs
    var readlogrecordsfromfile: [LogRecords]?
    // UUIDs for logrecords with no snapshot catalogs
    var notmappedloguuids: Set<Log.ID>?

    func setsnapshotdata(_ data: [LogRecordSnapshot]?) {
        logrecordssnapshot = data
        inprogressofdelete = false
        snapshotuuidsfordelete.removeAll()
        maxnumbertodelete = 0
        remainingsnapshotstodelete = 0
        notmappedloguuids = nil
    }

    func getsnapshotdata() -> [LogRecordSnapshot]? {
        if let logrecordssnapshot {
            return logrecordssnapshot.sorted { cat1, cat2 -> Bool in
                if let cat1 = cat1.snapshotCatalog,
                   let cat2 = cat2.snapshotCatalog
                {
                    return (Int(cat1.dropFirst(2)) ?? 0) > (Int(cat2.dropFirst(2)) ?? 0)
                }
                return false
            }
        }
        return nil
    }
    
    deinit {
        Logger.process.info("ObservableSnapshotData: deinit")
    }
}

struct Catalogsanddates: Identifiable, Equatable {
    let id = UUID()
    var catalog: String
}
