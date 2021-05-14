//
//  OneConfigSmall.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/05/2021.
//

import SwiftUI

struct OneConfigSmall: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata

    var config: Configuration

    var body: some View {
        forall
    }

    var forall: some View {
        HStack {
            Group {
                if config.backupID.isEmpty {
                    Text("Synchronize ID")
                        .modifier(FixedTag(150, .leading))
                } else {
                    Text(config.backupID)
                        .modifier(FixedTag(150, .leading))
                }
                Text(config.task)
                    .modifier(FixedTag(80, .leading))
                Text(config.localCatalog)
                    .modifier(FlexTag(180, .leading))
                Text(config.offsiteCatalog)
                    .modifier(FlexTag(180, .leading))
            }

            if config.offsiteServer.isEmpty {
                Text("localhost")
                    .modifier(FixedTag(80, .leading))
            } else {
                Text(config.offsiteServer)
                    .modifier(FixedTag(100, .leading))
            }
        }
    }
}
