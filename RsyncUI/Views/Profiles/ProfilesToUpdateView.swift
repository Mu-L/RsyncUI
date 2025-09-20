//
//  ProfilesToUpdateView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/10/2024.
//

import OSLog
import SwiftUI

struct ProfilesToUpdateView: View {
    let allconfigurations: [SynchronizeConfiguration]

    var body: some View {
        Table(allconfigurations) {
            
            TableColumn("Synchronize ID : profilename") { data in
                let split = data.backupID.split(separator: " : ")
                if split.count > 1 {
                    Text(split[0]) + Text(" : ") + Text(split[1]).foregroundColor(.blue)
                } else {
                    Text(data.backupID)
                }
            }
            .width(min: 150, max: 300)
            
            TableColumn("Task", value: \.task)
                .width(max: 80)

            TableColumn("Min/hour/day") { data in
                var seconds: Double {
                    if let date = data.dateRun {
                        let lastbackup = date.en_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                let color: Color = markconfig(seconds) == true ? .red : .white

                Text(latest(seconds))
                    .foregroundColor(color)
            }
            .width(max: 90)
            TableColumn("Date last") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)
        }

        .overlay {
            if allconfigurations.count == 0 {
                ContentUnavailableView {
                    Label("All tasks has been synchronized in the past \(SharedReference.shared.marknumberofdayssince) days",
                          systemImage: "play.fill")
                } description: {
                    Text("This is only due to Marknumberofdayssince set in the settings")
                }
            }
        }
    }

    private func markconfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }

    private func latest(_ seconds: Double) -> String {
        if seconds <= 3600 * 24 {
            if seconds <= 60 * 60 {
                String(format: "%.0f", seconds / 60) + " min"
            } else {
                String(format: "%.0f", seconds / (60 * 60)) + " hour(s)"
            }
        } else {
            String(format: "%.0f", seconds / (60 * 60 * 24)) + " day(s)"
        }
    }
}
