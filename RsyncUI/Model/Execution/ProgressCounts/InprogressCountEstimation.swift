//
//  EstimateProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 20/01/2021.
//

import Foundation
import Observation

@Observable
final class InprogressCountEstimation {
    var estimatedlist: [RemoteinfonumbersOnetask]?
    var tasksinprogresscount: Double = 0
    var max: Int = 0
    // set uuid if data to be transferred
    var uuids = Set<UUID>()
    // Estimate async
    var estimateasync: Bool = false
    var executeasyncnoestimationcompleted: Bool = false
    // Profilename and timestamp start estimation
    var profile: String?
    var timestamp: Date?
    var numberofconfigurations: Int = -1

    func taskisestimated(_ hiddenID: Int) -> Bool {
        let answer = estimatedlist?.contains(where: { task in
            task.hiddenID == hiddenID
        }) ?? false ? true : false
        return answer
    }

    func getprofile() -> String {
        return profile ?? "Default profile"
    }

    func setprofileandnumberofconfigurations(_ profilename: String, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    func alltasksestimated(_ profilename: String) -> Bool {
        return estimateasync == false &&
            estimatedlist?.count == numberofconfigurations &&
            profile == profilename
    }

    func getuuids() -> Set<UUID> {
        return uuids
    }

    func appenduuid(_ id: UUID) {
        uuids.insert(id)
    }

    func resetcounts() {
        numberofconfigurations = -1
        tasksinprogresscount = 0
        max = 0
        uuids.removeAll()
        estimatedlist = nil
        timestamp = Date()
        profile = nil
    }

    func setmaxcount(_ num: Int) {
        max = num
    }

    func updatetasknumbercount(_ num: Double) {
        tasksinprogresscount = num
    }

    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?) {
        estimatedlist = argestimatedlist
    }

    func appendrecordestimatedlist(_ record: RemoteinfonumbersOnetask) {
        if estimatedlist == nil {
            estimatedlist = [RemoteinfonumbersOnetask]()
        }
        estimatedlist?.append(record)
    }

    func asyncestimationcomplete() {
        estimateasync = false
    }

    func asyncexecutecomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startestimateasync() {
        estimateasync = true
    }

    func asyncexecutealltasksnoestiamtioncomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startasyncexecutealltasksnoestimation() {
        executeasyncnoestimationcompleted = false
    }

    func getestimatedlist() -> [RemoteinfonumbersOnetask]? {
        return estimatedlist
    }

    deinit {
        // print("deinit EstimatingProgressCount")
    }
}
