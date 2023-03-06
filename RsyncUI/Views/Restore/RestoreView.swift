//
//  RestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RestoreView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations

    @Binding var filterstring: String
    @StateObject var restore = ObserveableRestore()
    @State private var presentsheetviewfiles = false
    @State private var presentsheetrsync = false

    var body: some View {
        ZStack {
            VStack {
                ListofAllTasks(selectedconfig: $restore.selectedconfig.onChange {
                    restore.filestorestore = ""
                })
            }
        }

        Spacer()

        HStack {
            Button("Files") {
                guard SharedReference.shared.process == nil else { return }
                guard restore.selectedconfig != nil else { return }
                presentsheetviewfiles = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .sheet(isPresented: $presentsheetviewfiles) { viewoutputfiles }

            Spacer()

            ZStack {
                VStack(alignment: .leading) {
                    setfilestorestore

                    setpathforrestore
                }

                if restore.restorefilesinprogress == true {
                    ProgressView()
                        .frame(width: 50.0, height: 50.0)
                }
            }

            Spacer()

            ToggleViewDefault("--dry-run", $restore.dryrun)

            Button("Restore") {
                Task {
                    if let config = restore.selectedconfig {
                        await restore.restore(config)
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Log") {
                guard SharedReference.shared.process == nil else { return }
                guard restore.selectedconfig != nil else { return }
                presentsheetrsync = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .sheet(isPresented: $presentsheetrsync) { viewoutput }

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .sheet(isPresented: $presentsheetrsync) { viewoutput }
    }

    var setpathforrestore: some View {
        EditValue(500, NSLocalizedString("Path for restore", comment: ""), $restore.pathforrestore.onChange {
            restore.inputchangedbyuser = true
        })
        .onAppear(perform: {
            if let pathforrestore = SharedReference.shared.pathforrestore {
                restore.pathforrestore = pathforrestore
            }
        })
    }

    var setfilestorestore: some View {
        EditValue(500, NSLocalizedString("Select files to restore or \"./.\" for full restore", comment: ""), $restore.filestorestore.onChange {
            restore.inputchangedbyuser = true
        })
    }

    var numberoffiles: some View {
        HStack {
            Text(NSLocalizedString("Number of files", comment: "") + ": ")
            Text(NumberFormatter.localizedString(from: NSNumber(value: restore.numberoffiles), number: NumberFormatter.Style.decimal))
                .foregroundColor(Color.blue)

            Spacer()
        }
        .frame(width: 300)
    }

    // Output select files tpo restore
    var viewoutputfiles: some View {
        RestoreFilesView(isPresented: $presentsheetviewfiles,
                         selectrowforrestore: $restore.selectedrowforrestore,
                         config: $restore.selectedconfig,
                         filterstring: $filterstring)
    }

    // Output from rsync
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetrsync,
                        output: restore.rsyncdata ?? [])
    }
}

extension RestoreView {
    func abort() {
        _ = InterruptProcess()
    }
}
