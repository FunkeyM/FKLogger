//
//  YXLoggerFormat.swift
//  Stream_iOS
//
//  Created by Bobby on 2026/3/18.
//

import Foundation
import CocoaLumberjack


@objc class FKLoggerFormat: NSObject, DDLogFormatter {

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    func format(message logMessage: DDLogMessage) -> String? {
        var logLevel: String = ""
        switch logMessage.flag {
        case .error:
            logLevel = "E"
        case .debug:
            logLevel = "D"
        case .info:
            logLevel = "I"
        case .verbose:
            logLevel = "V"
        case .warning:
            logLevel = "W"
        default:
            logLevel = "D"
        }

        // 提取文件名
       // let fileName = (logMessage.fileName as NSString).lastPathComponent

        // 时间戳
        let timestamp = dateFormatter.string(from: logMessage.timestamp)

        // 线程ID (简短格式)
        let threadID = logMessage.threadID

        // 完整格式: [时间戳][级别][线程ID] 内容
        return String(format: "[%@][%@][%@] %@",
                      timestamp,
                      logLevel,
                      threadID,
                      logMessage.message)
    }
}

