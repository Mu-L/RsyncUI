//
//  Othersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//

import SwiftUI

struct Othersettings: View {
    @State private var backup: Bool = false
    @State private var environmentvalue: String = ""
    @State private var environment: String = ""

    var body: some View {
        Form {
            Spacer()

            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        setenvironment

                        setenvironmenvariable
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
        }
        .lineSpacing(2)
        .padding()
        .toolbar {
            ToolbarItem {
                Button {
                    saveusersettings()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(Color(.blue))
                }
                .help("Save usersettings")
            }
        }
    }

    var setenvironment: some View {
        EditValue(350, NSLocalizedString("Environment", comment: ""), $environment)
            .onAppear(perform: {
                if let environmentstring = SharedReference.shared.environment {
                    environment = environmentstring
                }
            })
            .onChange(of: environment) {
                SharedReference.shared.environment = environment
            }
    }

    var setenvironmenvariable: some View {
        EditValue(350, NSLocalizedString("Environment variable", comment: ""), $environmentvalue)
            .onAppear(perform: {
                if let environmentvaluestring = SharedReference.shared.environmentvalue {
                    environmentvalue = environmentvaluestring
                }
            })
            .onChange(of: environmentvalue) {
                SharedReference.shared.environmentvalue = environmentvalue
            }
    }
}

extension Othersettings {
    func saveusersettings() {
        _ = WriteUserConfigurationJSON(UserConfiguration())
        backup = true
    }
}
