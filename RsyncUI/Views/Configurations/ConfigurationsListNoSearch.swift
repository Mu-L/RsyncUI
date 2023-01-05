//
//  ConfigurationsListNoSearch.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/07/2021.
//

import SwiftUI

struct ConfigurationsListNoSearch: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedconfig: Configuration?
    // Needed in OneConfigProgressView
    @State var selecteduuids = Set<UUID>()
    @State var inwork: Int = -1

    var body: some View {
        VStack {
            configlist
        }
    }

    // Non selectable
    var configlist: some View {
        Section(header: header) {
            List(selection: $selectedconfig) {
                ForEach(configurationssorted) { configurations in
                    OneConfigProgressView(selecteduuids: $selecteduuids, inwork: $inwork, config: configurations)
                        .tag(configurations)
                }
                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
            }
        }
    }

    var configurationssorted: [Configuration] {
        return rsyncUIdata.configurations ?? []
    }

    var header: some View {
        HStack {
            Text("Synchronize ID")
                .modifier(FixedTag(120, .center))
            Text("Task")
                .modifier(FixedTag(80, .center))
            Text("Local catalog")
                .modifier(FixedTag(180, .center))
            Text("Remote catalog")
                .modifier(FixedTag(180, .center))
            Text("Server")
                .modifier(FixedTag(80, .center))
            Text("User")
                .modifier(FixedTag(35, .center))
            Text("Days")
                .modifier(FixedTag(80, .trailing))
            Text("Last")
                .modifier(FixedTag(80, .trailing))
        }
    }
}
