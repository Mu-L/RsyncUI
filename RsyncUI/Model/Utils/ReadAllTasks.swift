//
//  ReadAllTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/02/2025.
//

import Foundation
import OSLog

@MainActor
struct ReadAllTasks {
    func readAllMarkedTasks(_ validprofiles: [ProfilesnamesRecord]) async -> [SynchronizeConfiguration] {
        let allprofiles = validprofiles.map(\.profilename)
        let rsyncversion3 = SharedReference.shared.rsyncversion3
        let markdays = SharedReference.shared.marknumberofdayssince

        let perProfile: [(Int, [SynchronizeConfiguration])] =
            await withTaskGroup(of: (Int, [SynchronizeConfiguration]).self) { group in
                for (index, profilename) in allprofiles.enumerated() {
                    group.addTask {
                        let configurations = await ReadSynchronizeConfigurationJSON()
                            .readjsonfilesynchronizeconfigurations(profilename, rsyncversion3)
                        let marked = (configurations ?? []).filter { element in
                            guard let date = element.dateRun else { return false }
                            let seconds = date.en_date_from_string().timeIntervalSinceNow * -1
                            return seconds / (60 * 60 * 24) > Double(markdays)
                        }
                        let tagged = marked.map { element -> SynchronizeConfiguration in
                            var newelement = element
                            if newelement.backupID.isEmpty {
                                newelement.backupID = "No ID set"
                            }
                            newelement.backupID += " : " + profilename
                            return newelement
                        }
                        return (index, tagged)
                    }
                }
                var collected: [(Int, [SynchronizeConfiguration])] = []
                for await result in group {
                    collected.append(result)
                }
                return collected
            }

        return perProfile
            .sorted { $0.0 < $1.0 }
            .flatMap { $0.1 }
    }

    /// Put profilename in Backup ID
    func readalltasks(_ validprofiles: [ProfilesnamesRecord]) async -> [SynchronizeConfiguration] {
        let allprofiles = validprofiles.map(\.profilename)
        let rsyncversion3 = SharedReference.shared.rsyncversion3

        let perProfile: [(Int, [SynchronizeConfiguration])] =
            await withTaskGroup(of: (Int, [SynchronizeConfiguration]).self) { group in
                for (index, profilename) in allprofiles.enumerated() {
                    group.addTask {
                        let configurations = await ReadSynchronizeConfigurationJSON()
                            .readjsonfilesynchronizeconfigurations(profilename, rsyncversion3)
                        let adjusted = (configurations ?? []).map { element -> SynchronizeConfiguration in
                            var newelement = element
                            newelement.backupID = profilename
                            return newelement
                        }
                        return (index, adjusted)
                    }
                }
                var collected: [(Int, [SynchronizeConfiguration])] = []
                for await result in group {
                    collected.append(result)
                }
                return collected
            }

        return perProfile
            .sorted { $0.0 < $1.0 }
            .flatMap { $0.1 }
    }
}
