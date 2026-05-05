//
//  GetversionofRsyncUI.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import OSLog

struct GetversionofRsyncUI {
    private func fetchMatchingVersions() async throws -> [VersionsofRsyncUI] {
        guard let resourceURL = URL(string: Resources().getResource(resource: .urlJSON)) else {
            throw URLError(.badURL)
        }

        let all = try await SharedJSONStorageReader.shared.decodeArray(
            VersionsofRsyncUI.self,
            fromRemoteURL: resourceURL
        )
        Logger.process.debugThreadOnly("GetversionofRsyncUI: \(all)")
        let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return all.filter { runningversion.isEmpty ? true : $0.version == runningversion }
    }

    func getversionsofrsyncui() async -> Bool {
        do {
            return try await fetchMatchingVersions().isEmpty == false
        } catch {
            Logger.process.warning("GetversionofRsyncUI: loading data failed)")
            return false
        }
    }

    func downloadlinkofrsyncui() async -> String? {
        do {
            return try await fetchMatchingVersions().first?.url
        } catch {
            Logger.process.warning("GetversionofRsyncUI: loading data failed)")
            return nil
        }
    }
}
