//
//  Sshsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import Combine
import OSLog
import SwiftUI

struct Sshsettings: View {
    @State private var usersettings = ObservableSSH()
    @State private var localsshkeys: Bool = false
    @State private var showcopykeys: Bool = false
    // Combine for debounce of sshport and keypath
    @State var publisherport = PassthroughSubject<String, Never>()
    @State var publisherkeypath = PassthroughSubject<String, Never>()
    // Show keys are created
    @State private var showsshkeyiscreated: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        ToggleViewDefault(NSLocalizedString("Local ssh keys are present", comment: ""), $localsshkeys)
                            .disabled(true)
                    }
                } header: {
                    Text("SSH keys")
                }

                Section {
                    setsshpath

                    setsshport

                } header: {
                    Text("SSH-keypath and SSH-port")
                }

                Section {
                    HStack {
                        Button {
                            showcopykeys = true
                        } label: {
                            Image(systemName: "arrow.forward.circle")
                        }
                        .help("Show copy keys")
                        .buttonStyle(ColorfulButtonStyle())

                        if localsshkeys == false {
                            Button {
                                createkeys()
                            } label: {
                                Image(systemName: "key")
                            }
                            .help("Create keys")
                            .buttonStyle(ColorfulButtonStyle())
                        }

                        if SharedReference.shared.settingsischanged, usersettings.ready { thumbsupgreen }
                    }

                } header: {
                    Text("SSH keys")
                }

                if showsshkeyiscreated { sshkeyiscreated }
            }
            .formStyle(.grouped)
            .onAppear(perform: {
                localsshkeys = SshKeys().validatepublickeypresent()
                Task {
                    try await Task.sleep(seconds: 3)
                    Logger.process.info("SSH settings is DEFAULT")
                    SharedReference.shared.settingsischanged = false
                    usersettings.ready = true
                }
            })
            .onChange(of: SharedReference.shared.settingsischanged) {
                guard SharedReference.shared.settingsischanged == true,
                      usersettings.ready == true else { return }
                Task {
                    try await Task.sleep(seconds: 3)
                    _ = WriteUserConfigurationJSON(UserConfiguration())
                    SharedReference.shared.settingsischanged = false
                    Logger.process.info("Usersettings is SAVED")
                }
            }
            .alert(isPresented: $usersettings.alerterror,
                   content: { Alert(localizedError: usersettings.error)
                   })
        }
        .navigationDestination(isPresented: $showcopykeys) {
            ShowSSHCopyKeysView()
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup")
            .foregroundColor(Color(.green))
            .padding()
    }

    var sshkeyiscreated: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("SSH key is created, see logfile")
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 300, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            Task {
                try await Task.sleep(seconds: 3)
                showsshkeyiscreated = false
            }
        })
    }

    var setsshpath: some View {
        EditValue(400, NSLocalizedString("Global ssh keypath and identityfile", comment: ""), $usersettings.sshkeypathandidentityfile)
            .onAppear(perform: {
                if let sshkeypath = SharedReference.shared.sshkeypathandidentityfile {
                    usersettings.sshkeypathandidentityfile = sshkeypath
                }
            })
            .onChange(of: usersettings.sshkeypathandidentityfile) {
                publisherkeypath.send(usersettings.sshkeypathandidentityfile)
            }
            .onReceive(
                publisherkeypath.debounce(
                    for: .seconds(2),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                usersettings.sshkeypath(usersettings.sshkeypathandidentityfile)
            }
    }

    var setsshport: some View {
        EditValue(400, NSLocalizedString("Global ssh port", comment: ""),
                  $usersettings.sshportnumber)
            .onAppear(perform: {
                if let sshport = SharedReference.shared.sshport {
                    usersettings.sshportnumber = String(sshport)
                }
            })
            .onChange(of: usersettings.sshportnumber) {
                publisherport.send(usersettings.sshportnumber)
            }
            .onReceive(
                publisherport.debounce(
                    for: .seconds(1),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                usersettings.sshport(usersettings.sshportnumber)
            }
    }
}

extension Sshsettings {
    func createkeys() {
        if SshKeys().createPublicPrivateRSAKeyPair() {
            Task {
                try await Task.sleep(seconds: 1)
                localsshkeys = SshKeys().validatepublickeypresent()
                showsshkeyiscreated = true
            }
        }
    }
}

// swiftlint:enable line_length
