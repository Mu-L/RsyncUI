//
//  ReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Foundation
import OSLog

@MainActor
struct ReadSynchronizeConfigurationJSON {
    func readjsonfilesynchronizeconfigurations(_ profile: String?,
                                               _ rsyncversion3: Bool) async -> [SynchronizeConfiguration]? {
        let path = Homepath()

        Logger.process.debugThreadOnly("ReadSynchronizeConfigurationJSON: readjsonfilesynchronizeconfigurations()")

        guard let fullpathmacserial = path.fullpathmacserial else { return nil }

        let baseURL = URL(fileURLWithPath: fullpathmacserial)
        let fileURL: URL = if let profile {
            baseURL.appendingPathComponent(profile)
                .appendingPathComponent(SharedConstants().fileconfigurationsjson)
        } else {
            baseURL.appendingPathComponent(SharedConstants().fileconfigurationsjson)
        }

        do {
            let data = try await SharedJSONStorageReader.shared.decodeArray(
                DecodeSynchronizeConfiguration.self,
                from: fileURL
            )

            Logger.process.debugThreadOnly("ReadSynchronizeConfigurationJSON - \(profile ?? "default") ?? DECODE")
            return data.compactMap { element in
                if element.task == "snapshot" || element.task == "syncremote" {
                    if rsyncversion3 {
                        return SynchronizeConfiguration(element)
                    }
                } else {
                    return SynchronizeConfiguration(element)
                }
                return nil
            }
        } catch {
            let profileName = profile ?? "default profile"
            let errorMessage = "ReadSynchronizeConfigurationJSON - \(profileName): " +
                "some ERROR reading synchronize configurations from permanent storage"
            Logger.process.errorMessageOnly(errorMessage)
            return nil
        }
    }
}
