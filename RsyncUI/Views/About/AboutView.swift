//
//  AboutView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 28/01/2021.
//

import SwiftUI

struct AboutView: View {
    @StateObject private var new = NewversionJSON()

    var iconbystring: String = NSLocalizedString("Icon by: Zsolt Sándor", comment: "icon")
    var norwegianstring: String = NSLocalizedString("Norwegian translation by: Thomas Evensen", comment: "norwegian")
    var germanstring: String = NSLocalizedString("German translation by: Andre Voigtmann", comment: "german")
    var changelog: String = "https://rsyncui.netlify.app/post/changelog/"
    var documents: String = "https://rsyncui.netlify.app/"

    var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "Control Room"
    }

    var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    var appBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1.0"
    }

    var copyright: String {
        let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        return copyright ?? NSLocalizedString("Copyright ©2021 Thomas Evensen", comment: "copyright")
    }

    var configpath: String {
        return NamesandPaths(.configurations).fullpathmacserial ?? ""
    }

    var body: some View {
        VStack {
            headingtitle

            translations

            if new.notifynewversion { notifynewversion }

            rsynclongstring

            buttonsview

            Text(configpath)
                .font(.caption)

        }.padding()
    }

    var headingtitle: some View {
        VStack(spacing: 2) {
            Text("RsyncUI")
                .fontWeight(.bold)

            Text("Version \(appVersion) (\(appBuild))")
                .font(.caption)

            Text(copyright)
                .font(.caption)

            Text(iconbystring)
                .font(.caption)
        }
    }

    var buttonsview: some View {
        HStack {
            Button(NSLocalizedString("Changelog", comment: "About button")) { openchangelog() }
                .buttonStyle(PrimaryButtonStyle())
            Button(NSLocalizedString("RsyncUI", comment: "About button")) { opendocumentation() }
                .buttonStyle(PrimaryButtonStyle())
            Button(NSLocalizedString("Download", comment: "About button")) { opendownload() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    var rsynclongstring: some View {
        Text(SharedReference.shared.rsyncversionstring ?? "")
            .border(Color.gray)
            .font(.caption)
    }

    var translations: some View {
        VStack {
            Text(germanstring)
                .font(.caption)
            Text(norwegianstring)
                .font(.caption)
        }
    }

    var notifynewversion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("New version", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            // Show updated for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                new.notifynewversion = false
            }
        })
    }
}

extension AboutView {
    func openchangelog() {
        NSWorkspace.shared.open(URL(string: changelog)!)
    }

    func opendocumentation() {
        NSWorkspace.shared.open(URL(string: documents)!)
    }

    func opendownload() {
        if let url = SharedReference.shared.URLnewVersion {
            NSWorkspace.shared.open(URL(string: url)!)
        }
    }
}
