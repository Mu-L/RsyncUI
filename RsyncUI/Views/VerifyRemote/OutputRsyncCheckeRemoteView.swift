//
//  OutputRsyncCheckeRemoteView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct OutputRsyncCheckeRemoteView: View {
    @State private var progress = true
    // Pull data fraom remote
    @State private var pullremotedatanumbers: RemoteDataNumbers?
    // Push data from local to remote
    @State private var pushremotedatanumbers: RemoteDataNumbers?
    //
    @State private var pushVSremote = ObservableRemoteVSlocal()

    let config: SynchronizeConfiguration

    var body: some View {
        VStack {
            HStack {
                if progress {
                    Spacer()

                    ProgressView()

                    Spacer()

                } else {
                    if let pullremotedatanumbers, let pushremotedatanumbers {
                        HStack {
                            DetailsPullPushView(remotedatanumbers: pullremotedatanumbers,
                                                text: "PULL remote")
                            DetailsPullPushView(remotedatanumbers: pushremotedatanumbers,
                                                text: "PUSH local")
                        }
                    }
                }
            }
            if progress == false {
                switch pushVSremote.decideremoteVSlocal(pullremotedatanumbers: pullremotedatanumbers,
                                                        pushremotedatanumbers: pushremotedatanumbers)
                {
                case .remotemoredata:
                    MessageView(mytext: "Seems to be more data in remote VS local, a PULL from remote MAY be next action.", size: .title3)
                case .localmoredata:
                    MessageView(mytext: "Seems to be more data in local VS remote, a normal SYNCHRONIZE MAY be next action.", size: .title3)
                case .evenamountadata:
                    MessageView(mytext: "Seems to even amount of data in local VS remote, a normal SYNCHRONIZE MAY be next action.", size: .title3)
                case .noevaluation:
                    MessageView(mytext: "Could not decide local VS remote.", size: .title3)
                }
            }
        }
        .onAppear {
            pullremote(config: config)
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
    }

    // For check remote, pull remote data
    func pullremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true,
                                                                                              forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: pullprocesstermination)
        process.executeProcess()
    }

    // For check remote, pull remote data
    func pushremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: true,
                                                                                           forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: pushprocesstermination)
        process.executeProcess()
    }

    func pullprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
        // Then do a normal synchronize task
        pushremote(config: config)
    }

    // This is a normal synchronize task, dry-run = true
    func pushprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false
        pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
    }

    func abort() {
        _ = InterruptProcess()
    }
}
