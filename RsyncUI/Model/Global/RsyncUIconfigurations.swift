//
//  RsyncUIconfigurations.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Observation
import SwiftUI

struct ProfilesnamesRecord: Identifiable, Equatable, Hashable {
    var profilename: String
    let id = UUID()

    init(_ name: String) {
        profilename = name
    }
}

@Observable @MainActor
final class RsyncUIconfigurations {
    var configurations: [SynchronizeConfiguration]?
    var profile: String?
    // This is observed when URL actions are initiated.
    // Before commence the real action must be sure that selected profile data is loaded from store
    @ObservationIgnored var validprofiles: [ProfilesnamesRecord] = []
    // Toggle sidebar
    var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    // .doubleColumn or .detailOnly

    @ObservationIgnored var oneormoretasksissnapshot: Bool {
        guard SharedReference.shared.rsyncversion3 else { return false }
        return (configurations?.contains { $0.task == SharedReference.shared.snapshot } ?? false)
    }

    @ObservationIgnored var oneormoresnapshottasksisremote: Bool {
        guard SharedReference.shared.rsyncversion3 else { return false }
        return configurations?.filter { $0.task == SharedReference.shared.snapshot &&
            $0.offsiteServer.isEmpty == false
        }.count ?? 0 > 0
    }

    @ObservationIgnored var oneormoresynchronizetasksisremoteVer3x: Bool {
        guard SharedReference.shared.rsyncversion3 else { return false }
        return configurations?.filter { $0.task == SharedReference.shared.synchronize &&
            $0.offsiteServer.isEmpty == false
        }.count ?? 0 > 0
    }

    @ObservationIgnored var oneormoresynchronizetasksisremoteOpenrsync: Bool {
        configurations?.filter { $0.task == SharedReference.shared.synchronize &&
            $0.offsiteServer.isEmpty == false
        }.count ?? 0 > 0
    }

    @ObservationIgnored var externalurlrequestinprogress: Bool = false
    @ObservationIgnored var executetasksinprogress: Bool = false

    init() {}
}
