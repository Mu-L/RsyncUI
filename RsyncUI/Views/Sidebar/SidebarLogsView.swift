//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    var body: some View {
        TabView {
            LogListAlllogsView(reload: $reload, selectedprofile: $selectedprofile)
                .tabItem {
                    Text(NSLocalizedString("All logs", comment: "logsview"))
                }
            LogsbyConfigurationView()
                .tabItem {
                    Text(NSLocalizedString("By config", comment: "logsview"))
                }
        }
        .padding()
    }
}
