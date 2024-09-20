//
//  OtherRsyncCommandsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/09/2024.
//

import SwiftUI

struct OtherRsyncCommandsView: View {
    @Binding var config: SynchronizeConfiguration?
    @Binding var otherselectedrsynccommand: OtherRsyncCommand

    var body: some View {
        HStack {
            pickerselectcommand

            Spacer()

            showcommand
        }
    }

    var pickerselectcommand: some View {
        Picker("", selection: $otherselectedrsynccommand) {
            ForEach(OtherRsyncCommand.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(RadioGroupPickerStyle())
    }

    var showcommand: some View {
        Text(commandstring)
            .textSelection(.enabled)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue, lineWidth: 4)
            )
    }

    var commandstring: String {
        if let config {
            return OtherRsyncCommandtoDisplay(display: otherselectedrsynccommand,
                                       config: config).command
        } else {
            return NSLocalizedString("Select a task", comment: "")
        }
    }
}
