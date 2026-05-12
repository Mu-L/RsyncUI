import SwiftUI

struct SidebarStatusMessagesView: View {
    let newVersionAvailable: Bool
    @Binding var mountingVolumeNow: Bool
    let timerIsActive: Bool
    let nextScheduleText: String
    let showNotExecutedAfterWake: Bool
    let rsyncVersionShort: String
    let clearNotExecutedAfterWake: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if newVersionAvailable {
                Label("Update available", systemImage: "arrow.down.circle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            if mountingVolumeNow {
                Label("Mounting volume...", systemImage: "externaldrive")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .onAppear {
                        Task {
                            try? await Task.sleep(seconds: 2)
                            mountingVolumeNow = false
                        }
                    }
            }

            if timerIsActive {
                Label(nextScheduleText, systemImage: "calendar.badge.clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if showNotExecutedAfterWake {
                Label("Scheduled tasks missed", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .onAppear {
                        Task {
                            try? await Task.sleep(seconds: 5)
                            clearNotExecutedAfterWake()
                        }
                    }
            }

            Text(rsyncVersionShort)
                .font(.caption2)
                .foregroundStyle(.secondary).foregroundStyle(.secondary)
            
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
