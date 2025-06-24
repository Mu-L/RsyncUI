//
//  CheckfornewversionofRsyncUI.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2022.
//

import DecodeEncodeGeneric
import Foundation
import Observation
import OSLog

struct VersionsofRsyncUI: Codable {
    let url: String?
    let version: String?

    enum CodingKeys: String, CodingKey {
        case url
        case version
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        version = try values.decodeIfPresent(String.self, forKey: .version)
    }
}

@Observable @MainActor
final class CheckfornewversionofRsyncUI {
    var notifynewversion: Bool = false
    var downloadavaliable: Bool = false
}

actor GetversionofRsyncUI {
    
    nonisolated func getversionsofrsyncui() async -> Bool {
        do {
            Logger.process.info("GetversionofRsyncUI: getversionsofrsyncui() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
            let versions = await DecodeGeneric()
            if let versionsofrsyncui =
                try await versions.decodearraydata(VersionsofRsyncUI.self,
                                                   fromwhere: Resources().getResource(resource: .urlJSON))
            {
                Logger.process.info("CheckfornewversionofRsyncUI: \(versionsofrsyncui, privacy: .public)")
                let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
                if check.count > 0 {
                    Logger.process.info("CheckfornewversionofRsyncUI: COMPLETED NEW VERSION FOUND")
                    return true
                } else {
                    Logger.process.info("CheckfornewversionofRsyncUI: COMPLETED NO NEW VERSION")
                    return false
                }
            }
        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return false
        }
        return false
    }

    
    nonisolated func downloadlinkofrsyncui() async -> String? {
        do {
            Logger.process.info("GetversionofRsyncUI: downloadlinkofrsyncui() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
            let versions = await DecodeGeneric()
            if let versionsofrsyncui =
                try await versions.decodearraydata(VersionsofRsyncUI.self,
                                                   fromwhere: Resources().getResource(resource: .urlJSON))
            {
                Logger.process.info("CheckfornewversionofRsyncUI: \(versionsofrsyncui, privacy: .public)")
                let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
                if check.count > 0 {
                    return check[0].url
                } else {
                    return nil
                }
            }
        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return nil
        }
        return nil
    }
}

