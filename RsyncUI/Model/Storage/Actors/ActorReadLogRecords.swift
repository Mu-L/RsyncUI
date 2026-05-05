//
//  ActorReadLogRecords.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/12/2024.
//

import Foundation
import OSLog

actor ActorReadLogRecords {
    func readjsonfilelogrecords(_ profile: String?,
                                _ validhiddenIDs: Set<Int>) async -> [LogRecords]? {
        let path = await Homepath()
        Logger.process.debugThreadOnly("ActorReadLogRecordsJSON: readjsonfilelogrecords()")

        guard let fullpathmacserial = path.fullpathmacserial else { return nil }

        let baseURL = URL(fileURLWithPath: fullpathmacserial)
        let fileURL: URL = if let profile {
            baseURL.appendingPathComponent(profile)
                .appendingPathComponent(SharedConstants().filenamelogrecordsjson)
        } else {
            baseURL.appendingPathComponent(SharedConstants().filenamelogrecordsjson)
        }

        Logger.process.debugMessageOnly("ActorReadLogRecordsJSON: readjsonfilelogrecords() from \(fileURL.path)")

        do {
            let data = try await SharedJSONStorageReader.shared.decodeArray(
                DecodeLogRecords.self,
                from: fileURL
            )
            Logger.process.debugThreadOnly("ActorReadLogRecordsJSON - \(profile ?? "default")")
            return data.compactMap { element in
                let item = LogRecords(element)
                return validhiddenIDs.contains(item.hiddenID) ? item : nil
            }
        } catch {
            let profileName = profile ?? "default profile"
            Logger.process.errorMessageOnly(
                "ActorReadLogRecordsJSON - \(profileName): some ERROR reading logrecords from permanent storage"
            )
        }
        return nil
    }

    deinit {
        Logger.process.debugMessageOnly("ActorReadLogRecords: DEINIT")
    }
}
