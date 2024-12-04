//
//  WriteSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

final class WriteSynchronizeConfigurationJSON: PropogateError {

    private func writeJSONToPersistentStore(jsonData: Data?, _ profile: String?) {
        let path = Homepath()
        var profile: String?
        if profile == SharedReference.shared.defaultprofile {
           profile = nil
        }
        if let fullpathmacserial = path.fullpathmacserial {
            var configurationfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            if let profile {
                let tempURL = fullpathmacserialURL.appendingPathComponent(profile)
                configurationfileURL = tempURL.appendingPathComponent(SharedReference.shared.fileconfigurationsjson)

            } else {
                configurationfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.fileconfigurationsjson)
            }
            if let jsonData, let configurationfileURL {
                do {
                    try jsonData.write(to: configurationfileURL)
                    let myprofile = profile
                    Logger.process.info("WriteSynchronizeConfigurationJSON - \(myprofile ?? "default profile", privacy: .public): write configurations to permanent storage")
                } catch let e {
                    let error = e
                    path.propogateerror(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ configurations: [SynchronizeConfiguration], _ profile: String?) {
        let encodejsondata = EncodeGeneric()
        do {
            if let encodeddata = try encodejsondata.encodedata(data: configurations) {
                writeJSONToPersistentStore(jsonData: encodeddata, profile)
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    @discardableResult
    init(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) {
        if let configurations {
            encodeJSONData(configurations, profile)
        }
    }

    deinit {
        Logger.process.info("WriteSynchronizeConfigurationJSON deinit")
    }
}

// swiftlint:enable line_length
