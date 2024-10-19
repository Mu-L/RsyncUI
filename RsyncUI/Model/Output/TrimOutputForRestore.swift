//
//  TrimOutputForRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/05/2021.
//

import Foundation

@MainActor
final class TrimOutputForRestore: PropogateError {
    var trimmeddata = [String]()

    init(_ stringoutputfromrsync: [String]) {
        trimmeddata = stringoutputfromrsync.map({ line in
            let substr = line.dropFirst(10).trimmingCharacters(in: .whitespacesAndNewlines)
            let str = substr.components(separatedBy: " ").dropFirst(3).joined(separator: " ")
            if str.isEmpty == false,
               str.contains(".DS_Store") == false,
               str.contains("bytes") == false,
               str.contains("speedup") == false
            {
                var augmentetline = ""
                augmentetline.append("./" + str)
                return augmentetline
            }
            return str
        })
    }
}
