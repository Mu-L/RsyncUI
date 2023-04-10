//
//  Counter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2023.
//

import SwiftUI

struct Counter: View {
    @SwiftUI.Environment(\.scenePhase) var scenePhase
    // May be deleted
    @StateObject var deltatimeinseconds = Deltatimeinseconds()

    @Binding var timervalue: Double

    let timer1 = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    let timer2 = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if timervalue <= 60 {
            timerBelow60active
        } else {
            timerOver60active
        }
    }

    var timerOver60active: some View {
        Text("\(Int(timervalue / 60)) " + "minute(s)")
            .font(.largeTitle)
            .onReceive(timer1) { _ in
                timervalue -= 60
                if timervalue <= 0 {
                    timer1.upstream.connect().cancel()
                    print("Counter: CANCEL")
                }
            }
            .onDisappear {
                timer1.upstream.connect().cancel()
                print("Counter: CANCEL onDisappaer")
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .inactive {
                    deltatimeinseconds.timerminimized = Date()
                } else if newPhase == .active {
                    deltatimeinseconds.computeminimizedtime()
                } else if newPhase == .background {}
            }
    }

    var timerBelow60active: some View {
        Text("\(Int(timervalue)) " + "seconds")
            .font(.largeTitle)
            .onReceive(timer2) { _ in
                timervalue -= 1
                if timervalue <= 0 {
                    timer2.upstream.connect().cancel()
                    print("Counter: CANCEL")
                }
            }
            .onDisappear {
                timer2.upstream.connect().cancel()
                print("Counter: CANCEL onDisappaer")
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .inactive {
                    deltatimeinseconds.timerminimized = Date()
                } else if newPhase == .active {
                    deltatimeinseconds.computeminimizedtime()
                } else if newPhase == .background {}
            }
    }
}

final class Deltatimeinseconds: ObservableObject {
    var timerminimized: Date?
    var sleeptime: Double = 0

    func computeminimizedtime() {
        if let timerminimized = timerminimized {
            let now = Date()
            if sleeptime == 0 {
                sleeptime = now.timeIntervalSinceReferenceDate - timerminimized.timeIntervalSinceReferenceDate
            } else {
                sleeptime += (now.timeIntervalSinceReferenceDate - timerminimized.timeIntervalSinceReferenceDate)
            }
            print(sleeptime)
        }
    }
}
