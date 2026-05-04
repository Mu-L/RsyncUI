//
//  ReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

@MainActor
struct ReadSynchronizeConfigurationJSON {
    private static let reader = ActorReadSynchronizeConfigurationJSON()

    func readjsonfilesynchronizeconfigurations(_ profile: String?,
                                               _ rsyncversion3: Bool) async -> [SynchronizeConfiguration]? {
        await Self.reader.readjsonfilesynchronizeconfigurations(profile, rsyncversion3)
    }
}
