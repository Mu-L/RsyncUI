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

    @State private var newversion = CheckfornewversionofRsyncUI()
    @State private var rsyncversion = Rsyncversion()
    @State private var start: Bool = true
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()

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
                Sidebar(rsyncUIdata: rsyncUIdata,
                        selectedprofile: $selectedprofile,
                        selecteduuids: $selecteduuids,
                        profilenames: profilenames,
                        errorhandling: errorhandling)
            }

            HStack {
                Spacer()

                if newversion.notifynewversion { notifynewversion }

                Spacer()
            }
            .padding()
        }
        .padding()
        .task {
            rsyncversion.getrsyncversion()
            await newversion.getversionsofrsyncui()
        }
        .toolbar(content: {
            ToolbarItem {
                profilepicker
            }
        })
    }

    var rsyncUIdata: RsyncUIconfigurations {
        return RsyncUIconfigurations(selectedprofile)
    }

    var profilenames: Profilenames {
        return Profilenames()
    }

    var errorhandling: AlertError {
        SharedReference.shared.errorobject = AlertError()
        return SharedReference.shared.errorobject ?? AlertError()
    }

    var profilepicker: some View {
        HStack {
            Picker("", selection: $selectedprofile) {
                ForEach(profilenames.profiles, id: \.self) { profile in
                    Text(profile.profile ?? "")
                        .tag(profile.profile)
                }
            }
            .frame(width: 180)
            .onChange(of: selectedprofile) {
                selecteduuids.removeAll()
            }
            Spacer()
        }
    }

    var notifynewversion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("New version is available")
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            newversion.notify()
        })
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

/*
 extension EnvironmentValues {
     var ConfigurationsData: Readconfigurationsfromstore {
         get { self[ConfigurationsDataKey.self] }
         set { self[ConfigurationsDataKey.self] = newValue }
     }
 }

 private struct ConfigurationsDataKey: EnvironmentKey {
     static var defaultValue: Readconfigurationsfromstore = .init(profile: nil)
 }
 */
