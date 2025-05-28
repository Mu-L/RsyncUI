//
//  LogToFile.swift
//  rcloneosx
//
//  Created by Thomas Evensen on 20.11.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable non_optional_string_data_conversion

import Foundation
import OSLog

enum FilesizeError: LocalizedError {
    case toobig

    var errorDescription: String? {
        switch self {
        case .toobig:
            "Big logfile\n Please reset file"
        }
    }
}

@MainActor
final class LogToFile {
    private var logfile: String?
    let path = Homepath()

    func getlogfile() -> [String] {
        logfile.map { _ in
            logfile?.components(separatedBy: .newlines) ?? [""]
        } ?? [""]
    }

    func writeloggfile() {
        if let fullpathmacserial = path.fullpathmacserial {
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.logname)
            
            Logger.process.info("Write logfile to \(logfileURL.path, privacy: .public)")
            
            if let logfiledata = logfile {
                if let data = logfiledata.data(using: .utf8) {
                    do {
                        try data.write(to: logfileURL)
                        filesize { [weak self] result in
                            switch result {
                            case let .success(size):
                                if Int(truncating: size) > SharedReference.shared.logfilesize {
                                    let size = Int(truncating: size)
                                    if size > SharedReference.shared.logfilesize {
                                        throw FilesizeError.toobig
                                    }
                                }
                                return
                            case let .failure(error):
                                self?.path.propogateerror(error: error)
                            }
                        }
                    } catch let e {
                        let error = e
                        path.propogateerror(error: error)
                    }
                }
            }
        }
    }

    func filesize(then handler: @escaping (Result<NSNumber, Error>) throws -> Void) {
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedReference.shared.logname
            guard fm.locationExists(at: logfileString, kind: .file) == true else { return }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.logname)

            do {
                // Return filesize
                if let filesize = try fm.attributesOfItem(atPath: logfileURL.path)[FileAttributeKey.size] as? NSNumber {
                    Logger.process.info("Filesize of logfile \(filesize, privacy: .public)")
                    try handler(.success(filesize))
                }
            } catch let e {
                let error = e
                path.propogateerror(error: error)
            }
        }
    }

    func readloggfile() {
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedReference.shared.logname
            guard fm.locationExists(at: logfileString, kind: .file) == true else { return }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.logname)
            
            Logger.process.info("Read logfile \(logfileURL.path, privacy: .public)")

            do {
                let data = try Data(contentsOf: logfileURL)
                logfile = String(data: data, encoding: .utf8)
            } catch let e {
                let error = e
                path.propogateerror(error: error)
            }
        }
    }

    private func minimumloggingwithcommand(command: String, stringoutputfromrsync: [String]) {
        let date = Date().localized_string_from_date()
        readloggfile()
        var tmplogg = [String]()

        var startindex = stringoutputfromrsync.count - 20
        if startindex < 0 { startindex = 0 }

        tmplogg.append("\n" + date)
        tmplogg.append(command)
        tmplogg.append("Last twenty records from rsync output\n")

        var count = 0
        let tmploggrsync = stringoutputfromrsync.compactMap { line in
            count += 1
            return startindex >= count ? nil : line
        }

        if logfile == nil {
            logfile = tmplogg.joined(separator: "\n") + tmploggrsync.joined(separator: "\n")
        } else {
            logfile! += tmplogg.joined(separator: "\n") + tmploggrsync.joined(separator: "\n")
        }
        writeloggfile()
    }

    private func fulllogging(_ stringoutputfromrsync: [String]) {
        let date = Date().localized_string_from_date()
        readloggfile()
        let tmplogg = "\n" + date + ": "
        if logfile == nil {
            logfile = tmplogg + stringoutputfromrsync.joined(separator: "\n")
        } else {
            logfile! += tmplogg + stringoutputfromrsync.joined(separator: "\n")
        }
        writeloggfile()
    }

    init(_ reset: Bool) {
        if reset {
            // Reset loggfile
            let date = Date().localized_string_from_date()
            logfile = date + ": " + "logfile is reset..." + "\n"
            writeloggfile()
        } else {
            // Read the logfile
            readloggfile()
        }
    }

    @discardableResult
    init(_ stringoutputfromrsync: [String]?, error: Bool) {
        if error {
            if let stringoutputfromrsync {
                fulllogging(stringoutputfromrsync)
            }
        }
    }

    @discardableResult
    init(command: String, stringoutputfromrsync: [String]?) {
        if let stringoutputfromrsync {
            minimumloggingwithcommand(command: command, stringoutputfromrsync: stringoutputfromrsync)
        }
    }
}

// swiftlint:enable non_optional_string_data_conversion
