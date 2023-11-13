//
//  EstimateProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 20/01/2021.
//

import Foundation

final class EstimateProgressDetails: ObservableObject {
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
        uuids.removeAll()
    }

    func setmaxcount(_ num: Int) {
        max = num
        objectWillChange.send()
    }

    func updatetasksinprogresscount(_ num: Double) {
        tasksinprogresscount = num
        objectWillChange.send()
    }

    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?) {
        estimatedlist = argestimatedlist
        objectWillChange.send()
    }

    func appendrecordestimatedlist(_ record: RemoteinfonumbersOnetask) {
        if estimatedlist == nil {
            estimatedlist = [RemoteinfonumbersOnetask]()
        }
        estimatedlist?.append(record)
        objectWillChange.send()
    }

    func asyncestimationcomplete() {
        estimateasync = false
        objectWillChange.send()
    }

    func asyncexecutecomplete() {
        executeasyncnoestimationcompleted = true
        objectWillChange.send()
    }

    func startestimateasync() {
        estimateasync = true
        objectWillChange.send()
    }

    func asyncexecutealltasksnoestiamtioncomplete() {
        executeasyncnoestimationcompleted = true
        objectWillChange.send()
    }

    func startasyncexecutealltasksnoestimation() {
        executeasyncnoestimationcompleted = false
        objectWillChange.send()
    }

    func getestimatedlist() -> [RemoteinfonumbersOnetask]? {
        return estimatedlist
    }

    deinit {
        // print("deinit InprogressCountMultipleTasks")
    }
}
