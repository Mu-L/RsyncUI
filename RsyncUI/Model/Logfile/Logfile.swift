//
//  Logging.swift
//  rcloneosx
//
//  Created by Thomas Evensen on 20.11.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Files
import Foundation

enum FilesizeError: LocalizedError {
    case toobig

    var errorDescription: String? {
        switch self {
        case .toobig:
            return NSLocalizedString("Too big logfile", comment: "filesize error") + "..."
        }
    }
}

final class Logfile: NamesandPaths {
    private var outputprocess: OutputProcess?
    private var logfile: String?
    private var preparedlogview = [String]()

    func getlogfile() -> [String] {
        return preparedlogview
    }

    func writeloggfile() {
        if let atpath = fullroot {
            do {
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: SharedReference.shared.logname)
                if let data = logfile {
                    try file.write(data)
                    do {
                        let filesize = try self.filesize()
                        do {
                            try reportfilesize(filesize)
                        } catch let e {
                            let error = e
                            self.propogateerror(error: error)
                        }
                    } catch let e {
                        let error = e
                        self.propogateerror(error: error)
                    }
                }
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    func reportfilesize(_ filesize: NSNumber?) throws {
        let size = Int(truncating: filesize ?? 0)
        if size > SharedReference.shared.logfilesize {
            print("throwing filesize")
            throw FilesizeError.toobig
        }
    }

    func filesize() throws -> NSNumber {
        if var atpath = fullroot {
            do {
                do {
                    if try Folder(path: atpath).containsFile(named: SharedReference.shared.logname) == false { return 0
                    }
                } catch let e {
                    let error = e
                    self.propogateerror(error: error)
                }
                atpath += "/" + SharedReference.shared.logname
                let file = try File(path: atpath).url
                return try FileManager.default.attributesOfItem(atPath: file.path)[FileAttributeKey.size] as? NSNumber ?? 0
            } catch {
                return 0
            }
        }
        return 0
    }

    func readloggfile() {
        if var atpath = fullroot {
            do {
                // check if file exists ahead of reading, if not bail out
                guard try Folder(path: atpath).containsFile(named: SharedReference.shared.logname) else { return }
                atpath += "/" + SharedReference.shared.logname
                let file = try File(path: atpath)
                logfile = try file.readAsString()
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    private func minimumlogging() {
        let date = Date().localized_string_from_date()
        readloggfile()
        var tmplogg = [String]()
        var startindex = (outputprocess?.getOutput()?.count ?? 0) - 8
        if startindex < 0 { startindex = 0 }
        tmplogg.append("\n" + date + "\n")
        for i in startindex ..< (outputprocess?.getOutput()?.count ?? 0) {
            tmplogg.append(outputprocess?.getOutput()?[i] ?? "")
        }
        if logfile == nil {
            logfile = tmplogg.joined(separator: "\n")
        } else {
            logfile! += tmplogg.joined(separator: "\n")
        }
        writeloggfile()
    }

    private func fulllogging() {
        let date = Date().localized_string_from_date()
        readloggfile()
        let tmplogg: String = "\n" + date + "\n"
        if logfile == nil {
            logfile = tmplogg + (outputprocess?.getOutput() ?? [""]).joined(separator: "\n")
        } else {
            logfile! += tmplogg + (outputprocess?.getOutput() ?? [""]).joined(separator: "\n")
        }
        writeloggfile()
    }

    private func preparelogfile() {
        if let data = logfile?.components(separatedBy: .newlines) {
            for i in 0 ..< data.count {
                preparedlogview.append(data[i])
            }
        }
    }

    init(_ outputprocess: OutputProcess?) {
        super.init(profileorsshrootpath: .profileroot)
        guard SharedReference.shared.fulllogging == true ||
            SharedReference.shared.minimumlogging == true
        else {
            return
        }
        self.outputprocess = outputprocess
        if SharedReference.shared.fulllogging {
            fulllogging()
        } else {
            minimumlogging()
        }
    }

    init(_ outputprocess: OutputProcess?, _ logging: Bool) {
        super.init(profileorsshrootpath: .profileroot)
        if logging == false, outputprocess == nil {
            let date = Date().localized_string_from_date()
            logfile = date + ": " + "new logfile is created...\n"
            writeloggfile()
        } else {
            self.outputprocess = outputprocess
            fulllogging()
        }
    }

    init(_ data: [String], _: Bool) {
        super.init(profileorsshrootpath: .profileroot)
        let date = Date().localized_string_from_date()
        readloggfile()
        let tmplogg: String = "\n" + date + "\n"
        if logfile == nil {
            logfile = tmplogg + data.joined(separator: "\n")
        } else {
            logfile! += tmplogg + data.joined(separator: "\n")
        }
        writeloggfile()
    }

    init() {
        super.init(profileorsshrootpath: .profileroot)
        readloggfile()
        preparelogfile()
    }
}
