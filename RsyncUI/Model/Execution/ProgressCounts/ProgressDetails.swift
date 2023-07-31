//
//  ProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//

import Foundation

final class ProgressDetails: ObservableObject {
    // Value for storing progress for current task in work
    var currenttaskprogress: Double = 0
    var hiddenIDatwork: Int = -1
    var estimatedlist: [RemoteinfonumbersOnetask]?

    func taskisestimated(_ hiddenID: Int) -> Bool {
        let answer = estimatedlist?.contains(where: { task in
            task.hiddenID == hiddenID
        }) ?? false ? true : false
        return answer
    }

    func isestimating() -> Bool {
        return (estimatedlist?.count ?? 0) == 0
    }

    func setcurrentprogress(_ num: Double) {
        currenttaskprogress = num
        objectWillChange.send()
    }

    func getmaxcountbytask() -> Double {
        let max = estimatedlist?.filter { $0.hiddenID == hiddenIDatwork }
        if (max?.count ?? 0) == 1 {
            return Double(max?[0].outputfromrsync?.count ?? 0)
        } else {
            return 0
        }
    }

    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?) {
        estimatedlist = argestimatedlist
    }

    func resetcounter() {
        currenttaskprogress = 0
        estimatedlist = nil
    }

    deinit {
        // print("deinit ProgressDetails")
    }
}
