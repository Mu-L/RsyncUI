//
//  Snapshotlogsandcatalogs.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation
import OSLog

@MainActor
final class Snapshotlogsandcatalogs {
    var catalogsanddates: [SnapshotFolder]?
    var mysnapshotdata: ObservableSnapshotData?
    var config: SynchronizeConfiguration
    var logrecords: [LogRecords]

    func getremotecataloginfo() {
        let arguments = ArgumentsSnapshotRemoteCatalogs(config: config).remotefilelistarguments()
        let command = ProcessRsyncVer3x(arguments: arguments,
                                        processtermination: processtermination)
        command.executeProcess()
    }

    // Merging remote snaphotcatalogs and existing logs
    private func mergeremotecatalogsandlogs() {
        var adjustedlogrecords: [LogRecordSnapshot]?
        let mycatalogs = catalogsanddates
        let mylogrecords = RecordsSnapshot(config: config, logrecords: logrecords).loggrecordssnapshots?.map { record in
            var item = record
            if let secondssince = calculatedays(datestringlocalized: item.dateExecuted) {
                item.latest = latest(secondssince)
            }
            return item
        }
        adjustedlogrecords = mycatalogs?.map { record in
            let realsnapshotcatalog = "(" + record.folder.dropFirst(2) + ")"
            if let record = mylogrecords?.filter({ $0.resultExecuted.contains(realsnapshotcatalog) }), record.count == 1 {
                let catalogelementlog = record[0].resultExecuted.split(separator: " ")[0]
                let snapshotcatalogfromschedulelog = "./" + catalogelementlog.dropFirst().dropLast()
                var item = record[0]
                item.period = "... no tag ..."
                item.snapshotCatalog = snapshotcatalogfromschedulelog
                return item
            } else {
                var item = LogRecordSnapshot(idlogrecord: UUID(), date: Date(), dateExecuted: "no record", resultExecuted: "no record")
                let snapshotcatalogfromschedulelog = "./" + realsnapshotcatalog.dropFirst().dropLast()
                item.period = "... no tag ..."
                item.snapshotCatalog = snapshotcatalogfromschedulelog
                return item
            }
        }
        mysnapshotdata?.setsnapshotdata(adjustedlogrecords)
        mysnapshotdata?.notmappedloguuids = mapnotuselogrecords()
        // Save all log records before if cleaning up, if loaded
        // from store id is recomputed
        mysnapshotdata?.readlogrecordsfromfile = logrecords
    }

    // Mapping all UUIDS not used logrecords. Those logrecords may be deleted.
    // For snapshots, only log records with matched snap catalogs should be used
    private func mapnotuselogrecords() -> Set<UUID> {
        var mergedalluuids = Set<UUID>()
        var mergeuseduuids = Set<UUID>()
        var merged = [Log]()

        _ = logrecords.map { logrecord in
            if let logrecords = logrecord.logrecords {
                merged += [logrecords].flatMap(\.self)
            }
        }
        mergedalluuids = Set(merged.map(\.id))
        if let logrecordssnapshot = mysnapshotdata?.logrecordssnapshot {
            mergeuseduuids = Set(logrecordssnapshot.map(\.idlogrecord))
        }
        return mergedalluuids.subtracting(mergeuseduuids)
    }

    private func calculatedays(datestringlocalized: String) -> Double? {
        guard datestringlocalized != "" else { return nil }
        let lastbackup = datestringlocalized.localized_date_from_string()
        let seconds: TimeInterval = lastbackup.timeIntervalSinceNow
        return seconds * -1
    }

    init(config: SynchronizeConfiguration,
         logrecords: [LogRecords],
         snapshotdata: ObservableSnapshotData)
    {
        self.config = config
        self.logrecords = logrecords
        guard config.task == SharedReference.shared.snapshot else { return }

        mysnapshotdata = snapshotdata
        getremotecataloginfo()
    }

    deinit {
        Logger.process.info("Snapshotlogsandcatalogs: DEINIT")
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        if let stringoutputfromrsync {
            let catalogs = TrimOutputForRestore(stringoutputfromrsync).trimmeddata
            catalogsanddates = catalogs?.compactMap { line in
                let item = SnapshotFolder(folder: line)
                return (line.contains("done") == false && line.contains("receiving") == false &&
                    line.contains("sent") == false && line.contains("total") == false &&
                    line.contains("./.") == false && line.isEmpty == false &&
                    line.contains("speedup") == false && line.contains("bytes") == false) ? item : nil
            }.sorted { cat1, cat2 in
                (Int(cat1.folder.dropFirst(2)) ?? 0) > (Int(cat2.folder.dropFirst(2)) ?? 0)
            }
        }
        mysnapshotdata?.snapshotfolders = catalogsanddates ?? []
        mergeremotecatalogsandlogs()
        // Getting data is completed
        mysnapshotdata?.snapshotlist = false
    }
    
    private func latest(_ seconds: Double) -> String {
        if seconds <= 3600 * 24 {
            if seconds <= 60 * 60 {
                return seconds <= 60 ? String(format: "%.0f", seconds / 60) + " min" : String(format: "%.0f", seconds / 60) + " mins"
            } else {
                return seconds <= 60 * 60 ? String(format: "%.0f", seconds / (60 * 60)) + " hour" : String(format: "%.0f", seconds / (60 * 60)) + " hours"
            }
        } else {
            return seconds <= 60 * 60 * 24 ? String(format: "%.0f", seconds / (60 * 60 * 24)) + " day" : String(format: "%.0f", seconds / (60 * 60 * 24)) + " days"
        }
    }
}
