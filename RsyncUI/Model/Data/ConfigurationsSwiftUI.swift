//
//  ConfigurationsSwiftUI.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

struct UniqueserversandLogins: Hashable, Identifiable {
    var id = UUID()
    var offsiteUsername: String?
    var offsiteServer: String?

    init(_ username: String,
         _ servername: String)
    {
        offsiteServer = servername
        offsiteUsername = username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
    }
}

struct ConfigurationsSwiftUI {
    private var configurations: [Configuration]?
    // Initialized during startup
    // private var argumentAllConfigurations: [ArgumentsOneConfiguration]?
    // valid hiddenIDs
    var validhiddenIDs: Set<Int>?

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

    // Function for getting Configurations read into memory
    func getconfiguration(hiddenID: Int) -> Configuration? {
        let configuration = configurations?.filter { $0.hiddenID == hiddenID }
        guard configuration?.count == 1 else { return nil }
        return configuration?[0]
    }

    func getvalidhiddenIDs() -> Set<Int>? {
        return validhiddenIDs
    }

    // Function return arguments for rsync, either arguments for
    // real runn or arguments for --dry-run for Configuration at selected index
    func arguments4rsync(hiddenID: Int, argtype: ArgumentsRsync) -> [String] {
        if let config = configurations?.filter({ $0.hiddenID == hiddenID }) {
            guard config.count == 1 else { return [] }
            switch argtype {
            case .arg:
                return ArgumentsSynchronize(config: config[0]).argumentssynchronize(dryRun: false, forDisplay: false) ?? []
            case .argdryRun:
                return ArgumentsSynchronize(config: config[0]).argumentssynchronize(dryRun: true, forDisplay: false) ?? []
            case .argdryRunlocalcataloginfo:
                guard config[0].task != SharedReference.shared.syncremote else { return [] }
                return ArgumentsLocalcatalogInfo(config: config[0]).argumentslocalcataloginfo(dryRun: true, forDisplay: false) ?? []
            }
        }
        return []
    }

    init(profile: String?) {
        configurations = nil
        let configurationsdata = ReadConfigurationJSON(profile)
        configurations = configurationsdata.configurations
        validhiddenIDs = configurationsdata.validhiddenIDs
        SharedReference.shared.process = nil
    }
}

extension ConfigurationsSwiftUI: Hashable {
    static func == (lhs: ConfigurationsSwiftUI, rhs: ConfigurationsSwiftUI) -> Bool {
        return lhs.configurations == rhs.configurations
    }
}
