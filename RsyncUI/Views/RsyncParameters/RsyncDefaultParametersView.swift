//
//  RsyncDefaultParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RsyncDefaultParametersView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @StateObject var parameters = ObserveableParametersDefault()
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var rsyncoutput: InprogressCountRsyncOutput?

    @State private var showprogressview = false
    @State private var presentsheetview = false
    @State private var valueselectedrow: String = ""
    @State private var selecteduuids = Set<UUID>()

    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Section(header: headerssh) {
                            setsshpath

                            setsshport
                        }

                        Section(header: headerremove) {
                            VStack(alignment: .leading) {
                                ToggleViewDefault("-e ssh", $parameters.removessh)
                                ToggleViewDefault("--compress", $parameters.removecompress)
                                ToggleViewDefault("--delete", $parameters.removedelete)
                            }
                        }

                        Section(header: headerdaemon) {
                            ToggleViewDefault("daemon", $parameters.daemon)
                        }

                        Spacer()
                    }

                    VStack(alignment: .leading) {
                        ListofTasksLightView(
                            selecteduuids: $selecteduuids.onChange {
                                let selected = rsyncUIdata.configurations?.filter { config in
                                    selecteduuids.contains(config.id)
                                }
                                if (selected?.count ?? 0) == 1 {
                                    if let config = selected {
                                        selectedconfig = config[0]
                                        parameters.setvalues(selectedconfig)
                                    }
                                } else {
                                    selectedconfig = nil
                                    parameters.setvalues(selectedconfig)
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)

                        HStack(alignment: .center) {
                            RsyncCommandView(config: $parameters.configuration, selectedrsynccommand: $selectedrsynccommand)
                        }
                    }

                    if focusaborttask { labelaborttask }
                }

                Spacer()

                HStack {
                    Spacer()

                    if showprogressview { ProgressView() }

                    Spacer()

                    Button("Verify") {
                        if let configuration = parameters.updatersyncparameters() {
                            Task {
                                await verify(config: configuration)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Save") { saversyncparameters() }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
            .focusedSceneValue(\.aborttask, $focusaborttask)
            .padding()
            .onAppear(perform: {
                if selectedprofile == nil {
                    selectedprofile = SharedReference.shared.defaultprofile
                }
            })
            .sheet(isPresented: $presentsheetview) { viewoutput }
        }
    }

    // Header remove
    var headerremove: some View {
        Text("Remove default rsync parameters")
    }

    // Ssh header
    var headerssh: some View {
        Text("Set ssh keypath and identityfile")
    }

    // Daemon header
    var headerdaemon: some View {
        Text("Enable rsync daemon")
    }

    var setsshpath: some View {
        EditValue(250, "Local ssh keypath and identityfile",
                  $parameters.sshkeypathandidentityfile.onChange {
                      parameters.setvalues(selectedconfig)
                  })
                  .onAppear(perform: {
                      if let sshkeypath = parameters.configuration?.sshkeypathandidentityfile {
                          parameters.sshkeypathandidentityfile = sshkeypath
                      }
                  })
    }

    var setsshport: some View {
        EditValue(250, "Local ssh port", $parameters.sshport.onChange {
            parameters.setvalues(selectedconfig)
        })
        .onAppear(perform: {
            if let sshport = parameters.configuration?.sshport {
                parameters.sshport = String(sshport)
            }
        })
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(output: rsyncoutput?.getoutput() ?? [])
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }
}

extension RsyncDefaultParametersView {
    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.configurationsfromstore?.profile,
                                     configurations: rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.reset()
        selectedconfig = nil
        reload = true
    }

    func verify(config: Configuration) async {
        var arguments: [String]?
        switch selectedrsynccommand {
        case .synchronize:
            arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: false)
        case .restore:
            arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: false, tmprestore: true)
        case .verify:
            arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: false)
        }
        rsyncoutput = InprogressCountRsyncOutput(outputprocess: OutputfromProcess())
        showprogressview = true
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processtermination)
        await process.executeProcess()
    }

    func processtermination(outputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        rsyncoutput?.setoutput(data: outputfromrsync)
        presentsheetview = true
    }

    func abort() {
        showprogressview = false
        _ = InterruptProcess()
    }
}
