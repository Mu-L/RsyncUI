//
//  Logsettings.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/06/2024.
//

import OSLog
import SwiftUI

struct Logsettings: View {
    @Environment(AlertError.self) private var alerterror
    @State private var usersettings = ObservableUsersetting()

    var body: some View {
        Form {
            Section {
                ToggleViewDefault(NSLocalizedString("Monitor network", comment: ""), $usersettings.monitornetworkconnection)
                    .onChange(of: usersettings.monitornetworkconnection) {
                        SharedReference.shared.monitornetworkconnection = usersettings.monitornetworkconnection
                    }
                ToggleViewDefault(NSLocalizedString("Check for error in output", comment: ""), $usersettings.checkforerrorinrsyncoutput)
                    .onChange(of: usersettings.checkforerrorinrsyncoutput) {
                        SharedReference.shared.checkforerrorinrsyncoutput = usersettings.checkforerrorinrsyncoutput
                    }
                ToggleViewDefault(NSLocalizedString("Add summary to logfile", comment: ""), $usersettings.detailedlogging)
                    .onChange(of: usersettings.detailedlogging) {
                        SharedReference.shared.detailedlogging = usersettings.detailedlogging
                    }
                ToggleViewDefault(NSLocalizedString("Log summary to file", comment: ""),
                                  $usersettings.logtofile)
                    .onChange(of: usersettings.logtofile) {
                        SharedReference.shared.logtofile = usersettings.logtofile
                    }

                if SharedReference.shared.rsyncversion3 {
                    ToggleViewDefault(NSLocalizedString("Confirm execute", comment: ""), $usersettings.confirmexecute)
                        .onChange(of: usersettings.confirmexecute) {
                            SharedReference.shared.confirmexecute = usersettings.confirmexecute
                        }
                }
            } header: {
                Text("Monitor network, error and log settings")
            }
        }
        .formStyle(.grouped)
        .alert(isPresented: $usersettings.alerterror,
               content: { Alert(localizedError: usersettings.error)
               })
        .toolbar {
            ToolbarItem {
                if SharedReference.shared.settingsischanged && usersettings.ready { thumbsupgreen }
            }
        }
        .onAppear(perform: {
            Task {
                try await Task.sleep(seconds: 1)
                Logger.process.info("Monitor network, error and log settings is DEFAULT")
                SharedReference.shared.settingsischanged = false
                usersettings.ready = true
            }
        })
        .onChange(of: SharedReference.shared.settingsischanged) {
            guard SharedReference.shared.settingsischanged == true,
                  usersettings.ready == true else { return }
            Task {
                try await Task.sleep(seconds: 1)
                _ = WriteUserConfigurationJSON(UserConfiguration())
                SharedReference.shared.settingsischanged = false
                Logger.process.info("Monitor network, error and log settings is SAVED")
            }
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup")
            .foregroundColor(Color(.green))
            .padding()
    }
}

// swiftlint:enable line_length
