//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import SwiftUI

struct RsyncUIView: View {
    @StateObject var rsyncversion = Rsyncversion()
    @StateObject var newversion = CheckfornewversionofRsyncUI()
    @Binding var selectedprofile: String?

    @State private var reload: Bool = false
    @State private var start: Bool = true
    @State var selecteduuids = Set<Configuration.ID>()

    // Initial view in tasks for sidebar macOS 12
    @State private var selection: NavigationItem? = Optional.none
    var actions: Actions

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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        start = false
                    }
                })

            } else {
                if #available(macOS 13.0, *) {
                    SidebarVentura(reload: $reload,
                                   selectedprofile: $selectedprofile,
                                   selecteduuids: $selecteduuids,
                                   actions: actions)
                        .environmentObject(rsyncUIdata)
                        .environmentObject(errorhandling)
                        .environmentObject(profilenames)
                        .onChange(of: reload) { _ in
                            reload = false
                        }
                } else {
                    SidebarMonterey(reload: $reload,
                                    selectedprofile: $selectedprofile,
                                    selecteduuids: $selecteduuids,
                                    selection: $selection,
                                    actions: actions)
                        .environmentObject(rsyncUIdata)
                        .environmentObject(errorhandling)
                        .environmentObject(profilenames)
                        .onChange(of: reload) { _ in
                            reload = false
                        }
                }
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
            selection = .tasksview
            await rsyncversion.getrsyncversion()
            await newversion.getversionsofrsyncui()
        }
        .toolbar(content: {
            ToolbarItem {
                profilepicker
            }
        })
    }

    var profilenames: Profilenames {
        return Profilenames()
    }

    var rsyncUIdata: RsyncUIconfigurations {
        return RsyncUIconfigurations(profile: selectedprofile, reload)
    }

    var errorhandling: ErrorHandling {
        SharedReference.shared.errorobject = ErrorHandling()
        return SharedReference.shared.errorobject ?? ErrorHandling()
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
            .onChange(of: selectedprofile) { _ in
                selecteduuids.removeAll()
            }
            Spacer()
        }
    }

    var notifynewversion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("New version")
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            // Show updated for 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                newversion.notifynewversion = false
            }
        })
    }
}

extension View {
    func notifymessage(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .foregroundColor(Color.blue)
    }
}
