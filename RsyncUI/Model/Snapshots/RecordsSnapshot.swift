//
//  RecordsSnapshot.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/08/2024.
//

import Foundation

final class RecordsSnapshot {
    var loggrecordssnapshots: [LogRecordSnapshot]?

    private func readandsortallloggdata(_ config: SynchronizeConfiguration,
                                        _ logrecords: [LogRecords])
    {
        var data = [LogRecordSnapshot]()
        let localrecords = logrecords.filter { $0.hiddenID == config.hiddenID }
        guard localrecords.count == 1 else { return }
        for i in 0 ..< (localrecords[0].logrecords?.count ?? 0) {
            var datestring: String?
            var date: Date?
            if let stringdate = localrecords[0].logrecords?[i].dateExecuted {
                if stringdate.isEmpty == false {
                    datestring = stringdate.en_us_date_from_string().localized_string_from_date()
                    date = stringdate.en_us_date_from_string()
                }
            }
            let record =
                LogRecordSnapshot(
                    date: date ?? Date(),
                    dateExecuted: datestring ?? "",
                    resultExecuted: localrecords[0].logrecords?[i].resultExecuted ?? ""
                )
            data.append(record)
        }
        loggrecordssnapshots = data.sorted(by: \.date, using: >)
    }

    init(config: SynchronizeConfiguration,
         logrecords: [LogRecords])
    {
        if loggrecordssnapshots == nil {
            readandsortallloggdata(config, logrecords)
        }
    }
}
