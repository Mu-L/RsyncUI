//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import SwiftUI

struct RsyncUIView: View {
    @StateObject var rsyncversion = Rsyncversion()
    @StateObject var profilenames = Profilenames()
    @StateObject var newversion = CheckfornewversionofRsyncUI()
    @StateObject var inprogresscountexecuteonetaskdetails = InprogressCountExecuteOneTaskDetails()

    @Binding var selectedprofile: String?
    @State private var reload: Bool = false
    @State private var defaultprofile = "Default profile"
    @State private var start: Bool = true

    // Initial view in tasks for sidebar macOS 12
    @State private var selection: NavigationItem? = Optional.none

    var body: some View {
        VStack {
            if start {
                VStack {
                    Text("RsyncUI, a GUI for rsync ...")
                        .font(.largeTitle)
                    Text("https://rsyncui.netlify.app")
                        .font(.title2)
                }
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        start = false
                    }
                })

            } else {
                if profilenames.profiles?.count == 0 {
                    defaultprofilepicker
                } else {
                    profilepicker
                }

                if #available(macOS 13.0, *) {
                    SidebarVentura(reload: $reload,
                                   selectedprofile: $selectedprofile)
                        .environmentObject(rsyncUIdata)
                        .environmentObject(errorhandling)
                        .environmentObject(inprogresscountexecuteonetaskdetails)
                        .environmentObject(profilenames)
                        .onChange(of: reload, perform: { _ in
                            reload = false
                        })
                } else {
                    Sidebar(reload: $reload,
                            selectedprofile: $selectedprofile,
                            selection: $selection)
                        .environmentObject(rsyncUIdata)
                        .environmentObject(errorhandling)
                        .environmentObject(inprogresscountexecuteonetaskdetails)
                        .environmentObject(profilenames)
                        .onChange(of: reload, perform: { _ in
                            reload = false
                        })
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
    }

    var rsyncUIdata: RsyncUIconfigurations {
        return RsyncUIconfigurations(profile: selectedprofile)
    }

    var errorhandling: ErrorHandling {
        SharedReference.shared.errorobject = ErrorHandling()
        return SharedReference.shared.errorobject ?? ErrorHandling()
    }

    var profilepicker: some View {
        HStack {
            Picker("", selection: $selectedprofile) {
                if let profiles = profilenames.profiles {
                    ForEach(profiles, id: \.self) { profile in
                        Text(profile.profile ?? "")
                            .tag(profile.profile)
                    }
                }
            }
            .frame(width: 180)
            .accentColor(.blue)

            Spacer()
        }
    }

    var defaultprofilepicker: some View {
        HStack {
            Picker("", selection: $defaultprofile) {
                Text("Default profile")
                    .tag("Default profile")
            }
            .frame(width: 180)
            .accentColor(.blue)

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
    func tooltip(_ tip: String) -> some View {
        ZStack {
            background(GeometryReader { childGeometry in
                TooltipView(tip, geometry: childGeometry) {
                    self
                }
            })
            self
        }
    }
}

struct TooltipView<Content>: View where Content: View {
    let content: () -> Content
    let tip: String
    let geometry: GeometryProxy

    init(_ tip: String, geometry: GeometryProxy, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.tip = tip
        self.geometry = geometry
    }

    var body: some View {
        Tooltip(tip, content: content)
            .frame(width: geometry.size.width, height: geometry.size.height)
    }
}

struct Tooltip<Content: View>: NSViewRepresentable {
    typealias NSViewType = NSHostingView<Content>

    init(_ text: String?, @ViewBuilder content: () -> Content) {
        self.text = text
        self.content = content()
    }

    let text: String?
    let content: Content

    func makeNSView(context _: Context) -> NSHostingView<Content> {
        NSViewType(rootView: content)
    }

    func updateNSView(_ nsView: NSHostingView<Content>, context _: Context) {
        nsView.rootView = content
        nsView.toolTip = text
    }
}
