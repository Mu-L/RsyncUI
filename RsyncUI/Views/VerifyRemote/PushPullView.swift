//
//  PushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct PushPullView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var verifynavigationispresented: Bool
    // URL code
    @Binding var queryitem: URLQueryItem?

    @State private var progress = true
    // Pull data from remote
    @State private var pullremotedatanumbers: RemoteDataNumbers?
    // Push data to remote
    @State private var pushremotedatanumbers: RemoteDataNumbers?
    // Decide push or pull
    @State private var pushorpull = ObservablePushPull()
    // If aborted
    @State private var isaborted: Bool = false

    let config: SynchronizeConfiguration

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    if progress {
                        Spacer()

                        ProgressView()
                            .toolbar(content: {
                                ToolbarItem {
                                    Button {
                                        isaborted = true
                                        abort()
                                    } label: {
                                        Image(systemName: "stop.fill")
                                    }
                                    .help("Abort (⌘K)")
                                }
                            })

                        Spacer()

                    } else {
                        if let pullremotedatanumbers, let pushremotedatanumbers {
                            HStack {
                                DetailsVerifyView(remotedatanumbers: pushremotedatanumbers,
                                                  push: true)

                                DetailsVerifyView(remotedatanumbers: pullremotedatanumbers,
                                                  push: false)
                            }
                        }
                    }
                }

                if progress == false, isaborted == false {
                    switch pushorpull.decideremoteVSlocal(pullremotedatanumbers: pullremotedatanumbers,
                                                          pushremotedatanumbers: pushremotedatanumbers)
                    {
                    case .remotemoredata:
                        MessageView(mytext: NSLocalizedString("It seems that REMOTE is more updated than LOCAL. A PULL may be next.", comment: ""), size: .title3)
                    case .localmoredata:
                        MessageView(mytext: NSLocalizedString("It seems that LOCAL is more updated than REMOTE. A SYNCHRONIZE may be next.", comment: ""), size: .title3)
                    case .evenamountadata:
                        MessageView(mytext: NSLocalizedString("There is an equal amount of data. You can either perform a SYNCHRONIZE or a PULL operation.\n Alternatively, you can choose to do nothing.", comment: ""), size: .title3)
                    case .noevaluation:
                        MessageView(mytext: NSLocalizedString("I couldn’t decide between LOCAL and REMOTE.", comment: ""), size: .title3)
                    }
                }
            }
            .onAppear {
                pullremote(config: config)
            }
            .toolbar(content: {
                if progress == false {
                    ToolbarItem {
                        Button {
                            // verifynavigation.removeAll()
                            // verifynavigation.append(VerifyTasks(task: .executepushpull))
                            verifynavigationispresented = true
                        } label: {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .help("Pull or push")
                    }
                }
            })
        }
        .navigationTitle("Verify remote")
        .navigationDestination(isPresented: $verifynavigationispresented) {
            if let pushremotedatanumbers {
                ExecutePushPullView(config: config,
                                    pushorpullremotednumbers: pushremotedatanumbers)
            } else if let pullremotedatanumbers {
                ExecutePushPullView(config: config,
                                    pushorpullremotednumbers: pullremotedatanumbers)
            }
        }
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
        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                      config: config)
        } else {
            pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                      config: config)
        }
        guard isaborted == false else {
            progress = false
            return
        }
        // Rsync output pull
        pushorpull.rsyncpull = stringoutputfromrsync
        // Then do a synchronize task, adjusted for push vs pull
        pushremote(config: config)
    }

    // This is a normal synchronize task, dry-run = true
    func pushprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        guard isaborted == false else {
            progress = false
            return
        }
        progress = false
        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                      config: config)
        } else {
            pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                      config: config)
        }

        // Rsync output push
        pushorpull.rsyncpush = stringoutputfromrsync
        // Adjust both outputs
        pushorpull.adjustoutput()

        Task {
            pullremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(pushorpull.adjustedpull)
            pushremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(pushorpull.adjustedpush)
        }
    }

    func abort() {
        InterruptProcess()
    }
}
