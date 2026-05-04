//
//  ActorReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadSynchronizeConfigurationJSON {
    func readjsonfilesynchronizeconfigurations(_ profile: String?,
                                               _ rsyncversion3: Bool) async -> [SynchronizeConfiguration]? {
        let path = await Homepath()
        var filename = ""

        Logger.process.debugThreadOnly("ActorReadSynchronizeConfigurationJSON: readjsonfilesynchronizeconfigurations()")

        if let profile, let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + profile.appending("/") + SharedConstants().fileconfigurationsjson
        } else if let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + SharedConstants().fileconfigurationsjson
        }

        do {
            let data = try DecodeGeneric().decodeArray(DecodeSynchronizeConfiguration.self, fromFile: filename)

            Logger.process.debugThreadOnly("ActorReadSynchronizeConfigurationJSON - \(profile ?? "default") ?? DECODE")
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
            let errorMessage = "ActorReadSynchronizeConfigurationJSON - \(profileName): " +
                "some ERROR reading synchronize configurations from permanent storage"
            Logger.process.errorMessageOnly("\(errorMessage)")
        }

        return nil
    }
}
