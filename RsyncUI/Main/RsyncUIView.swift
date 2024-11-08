//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import OSLog
import SwiftUI

struct RsyncUIView: View {
    @Binding var selectedprofile: String?
    @State private var rsyncversion = Rsyncversion()
    @State private var start: Bool = true

    var body: some View {
        VStack {
            if start {
                VStack {
                    Text("RsyncUI a GUI for rsync")
                        .font(.largeTitle)
                    Text("https://rsyncui.netlify.app")
                        .font(.title2)
                }
                .onAppear(perform: {
                    Task {
                        try await Task.sleep(seconds: 1)
                        start = false
                    }

                })
            } else {
                SidebarMainView(rsyncUIdata: rsyncUIdata,
                                selectedprofile: $selectedprofile,
                                errorhandling: errorhandling)
            }
        }
        .padding()
        .task {
            ReadUserConfigurationJSON().readuserconfiguration()
            // Get version of rsync
            rsyncversion.getrsyncversion()
        }
    }

    var rsyncUIdata: RsyncUIconfigurations {
        RsyncUIconfigurations(selectedprofile)
    }

    var errorhandling: AlertError {
        SharedReference.shared.errorobject = AlertError()
        return SharedReference.shared.errorobject ?? AlertError()
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
