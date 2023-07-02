//
//  rsyncUIdata.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct Readconfigurationsfromstore: Equatable {
    var configurationData: AllConfigurations
    var validhiddenIDs: Set<Int>

    init(profile: String?) {
        configurationData = AllConfigurations(profile: profile)
        validhiddenIDs = configurationData.getvalidhiddenIDs() ?? Set()
    }
}

final class RsyncUIconfigurations: ObservableObject {
    var configurationsfromstore: Readconfigurationsfromstore?
    @Published var configurations: [Configuration]?
    @Published var profile: String?
    var validhiddenIDs: Set<Int>?

    func filterconfigurations(_ filter: String) -> [Configuration]? {
        return configurations?.filter {
            filter.isEmpty ? true : $0.backupID.contains(filter)
        }
    }

    // Function for getting Configurations read into memory
    func getconfiguration(hiddenID: Int) -> Configuration? {
        let configuration = configurations?.filter { $0.hiddenID == hiddenID }
        guard configuration?.count == 1 else { return nil }
        return configuration?[0]
    }

    // Function for getting Configurations read into memory, sorted by runddate
    func getallconfigurations() -> [Configuration]? {
        if let configurations = configurations {
            let sorted = configurations.sorted { conf1, conf2 in
                if let days1 = conf1.dateRun?.en_us_date_from_string(),
                   let days2 = conf2.dateRun?.en_us_date_from_string()
                {
                    return days1 > days2
                }
                return false
            }
            return sorted
        }
        return nil
    }

    init(profile: String?) {
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            configurationsfromstore = Readconfigurationsfromstore(profile: nil)
        } else {
            configurationsfromstore = Readconfigurationsfromstore(profile: profile)
        }
        configurations = configurationsfromstore?.configurationData.getallconfigurations()
        validhiddenIDs = configurationsfromstore?.validhiddenIDs
    }
}
