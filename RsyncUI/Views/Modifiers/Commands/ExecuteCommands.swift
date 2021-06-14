//
//  ExecuteCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/06/2021.
//
// swiftlint:disable multiple_closures_with_trailing_closure

import SwiftUI

struct ExecuteCommands: Commands {
    var body: some Commands {
        CommandMenu("Execute") {
            Button(action: {
                //
            }) {
                Text("Estimate")
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Divider()

            Button(action: {
                //
            }) {
                Text("Execute")
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        CommandMenu("Schedule") {
            Button(action: {
                let running = Running()
                guard running.informifisrsyncshedulerunning() == false else { return }
                NSWorkspace.shared.open(URL(fileURLWithPath: (SharedReference.shared.pathrsyncschedule ?? "/Applications/")
                        + SharedReference.shared.namersyncschedule))
                NSApp.terminate(self)
            }) {
                Text("Scheduled tasks")
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }
}
