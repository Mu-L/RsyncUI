//
//  Othersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//

import SwiftUI

struct Othersettings: View {
    @StateObject var usersettings = ObserveablePath()
    @State private var backup: Bool = false

    var body: some View {
        Form {
            Spacer()

            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    /*
                     **Schedules**
                     VStack(alignment: .leading) {
                         Section(header: headerpaths) {
                             setpathtorsyncui

                             setpathtorsyncschedule
                         }
                     }.padding()
                     */
                    // Column 1
                    VStack(alignment: .leading) {
                        // Section(header: headerenvironment) {
                        setenvironment

                        setenvironmenvariable
                        // }
                    }.padding()

                    Spacer()
                }

                if backup == true {
                    AlertToast(type: .complete(Color.green),
                               title: Optional(NSLocalizedString("Saved", comment: "")), subTitle: Optional(""))
                        .onAppear(perform: {
                            // Show updated for 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                backup = false
                            }
                        })
                }
            }
            // Save button right down corner
            Spacer()

            HStack {
                Spacer()

                Button("Save") { saveusersettings() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .lineSpacing(2)
        .padding()
    }

    // Environment
    var headerenvironment: some View {
        Text("Environment")
    }

    // Paths
    var headerpaths: some View {
        Text("Paths for apps")
    }

    var setenvironment: some View {
        EditValue(350, NSLocalizedString("Environment", comment: ""),
                  $usersettings.environment)
            .onAppear(perform: {
                if let environment = SharedReference.shared.environment {
                    usersettings.environment = environment
                }
            })
    }

    var setenvironmenvariable: some View {
        EditValue(350, NSLocalizedString("Environment variable", comment: ""),
                  $usersettings.environmentvalue)
            .onAppear(perform: {
                if let environmentvalue = SharedReference.shared.environmentvalue {
                    usersettings.environmentvalue = environmentvalue
                }
            })
    }

    /*
     var setpathtorsyncui: some View {
         EditValue(250, NSLocalizedString("Path to RsyncUI", comment: ""),
                   $usersettings.pathrsyncui)
             .onAppear(perform: {
                 if let pathrsyncui = SharedReference.shared.pathrsyncui {
                     usersettings.pathrsyncui = pathrsyncui
                 }
             })
     }

     var setpathtorsyncschedule: some View {
         EditValue(250, NSLocalizedString("Path to RsyncSchedule", comment: ""),
                   $usersettings.pathrsyncschedule)
             .onAppear(perform: {
                 if let pathrsyncschedule = SharedReference.shared.pathrsyncschedule {
                     usersettings.pathrsyncschedule = pathrsyncschedule
                 }
             })
     }
      */
}

extension Othersettings {
    func saveusersettings() {
        _ = WriteUserConfigurationJSON(UserConfiguration(true))
        backup = true
    }
}
