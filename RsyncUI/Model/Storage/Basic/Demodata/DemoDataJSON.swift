//
//  DemoDataJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/01/2024.
//

import Foundation

class DemoDataJSON: @unchecked Sendable {
    let urlSession = URLSession.shared
    let jsonDecoder = JSONDecoder()

    var configurationsJSON: String =
        "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/configurationsV2.json"
    var logrecordsJSON: String =
        "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/logrecordsV2.json"

    private func getconfigurationsJSON() async throws -> [DecodeConfiguration]? {
        if let url = URL(string: configurationsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([DecodeConfiguration].self, from: data)
        } else {
            return nil
        }
    }

    private func getlogrecordsJSON() async throws -> [DecodeLogRecords]? {
        if let url = URL(string: logrecordsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([DecodeLogRecords].self, from: data)
        } else {
            return nil
        }
    }

    func getconfigurations() async -> [SynchronizeConfiguration]? {
        do {
            if let data = try await getconfigurationsJSON() {
                var myconfigurations = [SynchronizeConfiguration]()
                for i in 0 ..< data.count {
                    let oneconfiguration = SynchronizeConfiguration(data[i])
                    myconfigurations.append(oneconfiguration)
                }
                return myconfigurations
            }
        } catch {
            return nil
        }
        return nil
    }

    func getlogrecords() async -> [LogRecords]? {
        do {
            if let data = try await getlogrecordsJSON() {
                var mylogrecords = [LogRecords]()
                for i in 0 ..< data.count {
                    let onerecord = LogRecords(data[i])
                    mylogrecords.append(onerecord)
                }
                return mylogrecords
            }
        } catch {
            return nil
        }
        return nil
    }
}
