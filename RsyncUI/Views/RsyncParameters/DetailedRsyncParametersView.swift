//
//  DetailedRsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct DetailedRsyncParametersView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @StateObject var parameters = ObserveableParametersRsync()

    @Binding var reload: Bool
    @Binding var showdetails: Bool
    @Binding var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var presentrsynccommandoview = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                EditRsyncParameter(550, $parameters.parameter8.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter9.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter10.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter11.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter12.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter13.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter14.onChange {
                    parameters.inputchangedbyuser = true
                })
            }

            VStack(alignment: .leading) {
                Section(header: headerremove) {
                    HStack {
                        ToggleView(NSLocalizedString("-e shh", comment: "RsyncParametersView"), $parameters.removessh.onChange {
                            parameters.inputchangedbyuser = true
                        })
                        ToggleView(NSLocalizedString("--compress", comment: "RsyncParametersView"), $parameters.removecompress.onChange {
                            parameters.inputchangedbyuser = true
                        })
                        ToggleView(NSLocalizedString("--delete", comment: "RsyncParametersView"), $parameters.removedelete.onChange {
                            parameters.inputchangedbyuser = true
                        })
                    }
                }

                VStack(alignment: .leading) {
                    Section(header: headerssh) {
                        setsshpath

                        setsshport
                    }
                }
            }
        }

        Spacer()

        HStack {
            Button(NSLocalizedString("Linux", comment: "RsyncParametersView")) {
                parameters.suffixlinux = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("FreeBSD", comment: "RsyncParametersView")) {
                parameters.suffixfreebsd = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Daemon", comment: "RsyncParametersView")) {
                parameters.daemon = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Backup", comment: "RsyncParametersView")) {
                parameters.backup = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()

            Button(NSLocalizedString("Rsync", comment: "RsyncParametersView")) { presenteview() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentrsynccommandoview) {
                    RsyncCommandView(selectedconfig: $parameters.configuration, isPresented: $presentrsynccommandoview)
                }

            saveparameters

            Button(NSLocalizedString("Return", comment: "RsyncParametersView")) {
                selectedconfig = nil
                showdetails = false
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .onAppear(perform: {
            parameters.configuration = selectedconfig
        })
    }

    // Save usersetting is changed
    var saveparameters: some View {
        HStack {
            if parameters.isDirty {
                Button(NSLocalizedString("Save", comment: "RsyncParametersView")) { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            } else {
                Button(NSLocalizedString("Save", comment: "RsyncParametersView")) {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!parameters.isDirty)
    }

    // Header remove
    var headerremove: some View {
        Text(NSLocalizedString("Remove default rsync parameters", comment: "RsyncParametersView"))
    }

    // Ssh header
    var headerssh: some View {
        Text(NSLocalizedString("Set ssh keypath and identityfile", comment: "RsyncParametersView"))
    }

    var setsshpath: some View {
        EditValue(250, NSLocalizedString("Local ssh keypath and identityfile", comment: "RsyncParametersView"),
                  $parameters.sshkeypathandidentityfile.onChange {
                      parameters.inputchangedbyuser = true
                  })
            .onAppear(perform: {
                if let sshkeypath = parameters.configuration?.sshkeypathandidentityfile {
                    parameters.sshkeypathandidentityfile = sshkeypath
                }
            })
    }

    var setsshport: some View {
        EditValue(250, NSLocalizedString("Local ssh port", comment: "RsyncParametersView"), $parameters.sshport.onChange {
            parameters.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshport = parameters.configuration?.sshport {
                    parameters.sshport = String(sshport)
                }
            })
    }
}

extension DetailedRsyncParametersView {
    func presenteview() {
        presentrsynccommandoview = true
    }

    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIData.rsyncdata?.profile,
                                     configurations: rsyncUIData.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.isDirty = false
        parameters.inputchangedbyuser = false
    }
}
