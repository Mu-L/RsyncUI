//
//  ReadUserConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation
import OSLog

@MainActor
struct ReadUserConfigurationJSON {
    let path = Homepath()

    func readuserconfiguration() async {
        guard let fullpathmacserial = path.fullpathmacserial else { return }

        let userconfigurationfileURL = URL(fileURLWithPath: fullpathmacserial)
            .appendingPathComponent(SharedReference.shared.userconfigjson)

        do {
            let importeddata = try await SharedJSONStorageReader.shared.decode(
                DecodeUserConfiguration.self,
                from: userconfigurationfileURL
            )

            UserConfiguration(importeddata)
            Logger.process.debugThreadOnly("ReadUserConfigurationJSON: Reading user configurations")
        } catch let err {
            Logger.process.errorMessageOnly("ReadUserConfigurationJSON: some ERROR reading user configurations from permanent storage")
            let error = err
            path.propagateError(error: error)
        }
    }
}
