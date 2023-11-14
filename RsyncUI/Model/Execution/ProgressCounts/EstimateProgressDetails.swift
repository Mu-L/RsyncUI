//
//  EstimateProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 20/01/2021.
//

import Foundation
import Observation

@Observable
final class EstimateProgressDetails {
    var estimatedlist: [RemoteinfonumbersOnetask]?
    var tasksinprogresscount: Double = 0
    var max: Int = 0
    // set uuid if data to be transferred
    var uuids = Set<UUID>()
    // Estimate async
    var estimatealltasksasync: Bool = false
    // Estimate on task, same profile
    // If one task in profile is estimated, this is set true
    // Used to decide if new profile is selected.
    // The estiamed list is usde for progress if executing.
    var onetaskisestimated: Bool = false
    var executeasyncnoestimationcompleted: Bool = false
    // Profilename and timestamp start estimation
    var profile: String?
    var timestamp: Date?
    var numberofconfigurations: Int = -1

    func tasksareestimated(_ uuids: Set<UUID>) -> Bool {
        let answer = estimatedlist?.filter {
            uuids.contains($0.id)
        }
        return answer?.count == uuids.count
    }

    func getprofile() -> String {
        return profile ?? "Default profile"
    }

    func setprofileandnumberofconfigurations(_ profilename: String, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    func executeanotherdryrun(_ profilename: String) -> Bool {
        return estimatealltasksasync == false &&
            onetaskisestimated == true &&
            estimatedlist?.count != numberofconfigurations &&
            profile == profilename
    }

    func alltasksestimated(_ profilename: String) -> Bool {
        return estimatealltasksasync == false &&
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
        uuids.removeAll()
        onetaskisestimated = false
        estimatealltasksasync = false
    }

    func setmaxcount(_ num: Int) {
        max = num
    }

    func updatetasksinprogresscount(_ num: Double) {
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
        onetaskisestimated = true
    }

    func asyncestimationcomplete() {
        estimatealltasksasync = false
    }

    func asyncexecutecomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startestimateasync() {
        estimatealltasksasync = true
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
        // print("deinit InprogressCountMultipleTasks")
    }
}
