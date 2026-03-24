//
//  FKLoggerManager.swift
//  Stream_iOS
//
//  Created by Bobby on 2026/3/18.
//

import Foundation
import CocoaLumberjack
import SSZipArchive

/// 日志级别
@objc public enum FKLogLevel: Int {
    case verbose = 0
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4

    var ddLogLevel: DDLogLevel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warn: return .warning
        case .error: return .error
        }
    }
}


// 使用内联函数让 #file #function #line 获取调用者位置
@inline(__always)
private func logMessage(_ message: String, file: String, function: String, line: Int) -> String {
    let fileName = (file as NSString).lastPathComponent
    return "[\(fileName):\(line)] \(function) -> \(message)"
}

public func LogVerbose(message: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogVerbose("\(logMessage(message, file: "\(file)", function: "\(function)", line: Int(line)))", level: .verbose, file: file, function: function, line: line)
}
public func LogDebug(message: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogDebug("\(logMessage(message, file: "\(file)", function: "\(function)", line: Int(line)))", level: .debug, file: file, function: function, line: line)
}
public func LogInfo(message: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogInfo("\(logMessage(message, file: "\(file)", function: "\(function)", line: Int(line)))", level: .info, file: file, function: function, line: line)
}
public func LogWarn(message: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogWarn("\(logMessage(message, file: "\(file)", function: "\(function)", line: Int(line)))", level: .warning, file: file, function: function, line: line)
}
public func LogError(message: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogError("\(logMessage(message, file: "\(file)", function: "\(function)", line: Int(line)))", level: .error, file: file, function: function, line: line)
}



/// 日志管理器 - OC和Swift通用
@objc public class FKLoggerManager: NSObject {

    /// 单例
    @objc public static let shared = FKLoggerManager()

    /// 日志目录路径
    @objc public var logDirectory: String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return (documentsPath as NSString).appendingPathComponent("FKLogger")
    }

    /// 当前日志文件名
    @objc public var currentLogFileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "log_\(dateFormatter.string(from: Date())).log"
    }

    /// 完整的当前日志文件路径
    @objc public var currentLogFilePath: String {
        return (logDirectory as NSString).appendingPathComponent(currentLogFileName)
    }

    /// 初始化日志系统
    /// - Parameter logLevel: 日志级别，默认debug
    @objc public func setupLogger(logLevel: FKLogLevel = .debug) {
        // 创建日志目录
        createLogDirectoryIfNeeded()

        // 创建格式化器
        let formatter = FKLoggerFormat()

        // 配置DDOSLogger (控制台输出)
        DDOSLogger.sharedInstance.logFormatter = formatter
        DDLog.add(DDOSLogger.sharedInstance)

        // 配置文件日志 - 使用自定义日志文件管理器指定目录
        let fileManager = DDLogFileManagerDefault(logsDirectory: logDirectory)
        let fileLogger = DDFileLogger(logFileManager: fileManager)
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24小时滚动一次
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7 // 最多7个文件
        fileLogger.logFormatter = formatter
        DDLog.add(fileLogger)

        // 设置日志级别
        dynamicLogLevel = logLevel.ddLogLevel

        // 删除过期日志
        cleanExpiredLogs()

        DDLogInfo("FKLogger initialized, log directory: \(logDirectory)")
    }

    /// 切换日志级别
    /// - Parameter level: 日志级别
    @objc public func setLogLevel(_ level: FKLogLevel) {
        dynamicLogLevel = level.ddLogLevel
    }

    // MARK: - OC 日志方法

    /// verbose 日志
    @objc public func verbose(_ message: String) {
        DDLogVerbose("\(message)")
    }

    /// debug 日志
    @objc public func debug(_ message: String) {
        DDLogDebug("\(message)")
    }

    /// info 日志
    @objc public func info(_ message: String) {
        DDLogInfo("\(message)")
    }

    /// warn 日志
    @objc public func warn(_ message: String) {
        DDLogWarn("\(message)")
    }

    /// error 日志
    @objc public func error(_ message: String) {
        DDLogError("\(message)")
    }

    // MARK: - OC 日志方法 (带位置信息)

    /// verbose 日志 - 带位置信息
    @objc public func verbose(_ message: String, file: String, function: String, line: Int32) {
        log(message, level: .verbose, file: file, function: function, line: Int(line))
    }

    /// debug 日志 - 带位置信息
    @objc public func debug(_ message: String, file: String, function: String, line: Int32) {
        log(message, level: .debug, file: file, function: function, line: Int(line))
    }

    /// info 日志 - 带位置信息
    @objc public func info(_ message: String, file: String, function: String, line: Int32) {
        log(message, level: .info, file: file, function: function, line: Int(line))
    }

    /// warn 日志 - 带位置信息
    @objc public func warn(_ message: String, file: String, function: String, line: Int32) {
        log(message, level: .warn, file: file, function: function, line: Int(line))
    }

    /// error 日志 - 带位置信息
    @objc public func error(_ message: String, file: String, function: String, line: Int32) {
        log(message, level: .error, file: file, function: function, line: Int(line))
    }

    /// 通用日志方法 - 带位置信息
    private func log(_ message: String, level: FKLogLevel, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "[\(fileName):\(line)] \(function) -> \(message)"

        switch level {
        case .verbose:
            DDLogVerbose("\(formattedMessage)")
        case .debug:
            DDLogDebug("\(formattedMessage)")
        case .info:
            DDLogInfo("\(formattedMessage)")
        case .warn:
            DDLogWarn("\(formattedMessage)")
        case .error:
            DDLogError("\(formattedMessage)")
        }
    }

    // MARK: - 日志文件管理

    /// 获取所有日志文件
    @objc public func getAllLogFiles() -> [String] {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: logDirectory) else {
            return []
        }

        return files
            .filter { $0.hasSuffix(".log") }
            .sorted()
    }

    /// 获取日志文件的完整路径
    @objc public func getLogFilePaths() -> [String] {
        return getAllLogFiles().map { (logDirectory as NSString).appendingPathComponent($0) }
    }

    /// 删除过期日志（超过7天的）
    @objc public func cleanExpiredLogs() {
        let fileManager = FileManager.default
        let calendar = Calendar.current
        let expirationDate = calendar.date(byAdding: .day, value: -7, to: Date())!

        guard let files = try? fileManager.contentsOfDirectory(atPath: logDirectory) else {
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for file in files {
            guard file.hasSuffix(".log") else { continue }

            let filePath = (logDirectory as NSString).appendingPathComponent(file)
            // 从文件名提取日期
            let dateString = file.replacingOccurrences(of: "log_", with: "").replacingOccurrences(of: ".log", with: "")

            if let fileDate = dateFormatter.date(from: dateString), fileDate < expirationDate {
                try? fileManager.removeItem(atPath: filePath)
                DDLogInfo("Deleted expired log file: \(file)")
            }
        }
    }

    // MARK: - 压缩功能

    /// 压缩所有日志文件到zip
    /// - Parameter completion: 压缩完成回调，返回zip文件路径
    @objc public func compressAllLogsToZip(completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }

            let logFiles = self.getLogFilePaths()
            guard !logFiles.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // 创建临时zip文件路径
            let zipFileName = "logs_\(self.getCurrentDateString()).zip"
            let tempPath = NSTemporaryDirectory()
            let zipPath = (tempPath as NSString).appendingPathComponent(zipFileName)

            // 删除已存在的zip文件
            try? FileManager.default.removeItem(atPath: zipPath)

            // 压缩日志文件
            let success = SSZipArchive.createZipFile(atPath: zipPath, withFilesAtPaths: logFiles)

            DispatchQueue.main.async {
                if success {
                    completion(zipPath)
                } else {
                    completion(nil)
                }
            }
        }
    }

    /// 压缩指定日期范围的日志
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    ///   - completion: 完成回调
    @objc public func compressLogs(from startDate: Date, to endDate: Date, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }

            let fileManager = FileManager.default
            guard let files = try? fileManager.contentsOfDirectory(atPath: self.logDirectory) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            var filesToCompress: [String] = []

            for file in files {
                guard file.hasSuffix(".log") else { continue }

                let filePath = (self.logDirectory as NSString).appendingPathComponent(file)
                let dateString = file.replacingOccurrences(of: "log_", with: "").replacingOccurrences(of: ".log", with: "")

                if let fileDate = dateFormatter.date(from: dateString),
                   fileDate >= startDate && fileDate <= endDate {
                    filesToCompress.append(filePath)
                }
            }

            guard !filesToCompress.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let zipFileName = "logs_\(dateFormatter.string(from: startDate))_\(dateFormatter.string(from: endDate)).zip"
            let tempPath = NSTemporaryDirectory()
            let zipPath = (tempPath as NSString).appendingPathComponent(zipFileName)

            try? FileManager.default.removeItem(atPath: zipPath)

            let success = SSZipArchive.createZipFile(atPath: zipPath, withFilesAtPaths: filesToCompress)

            DispatchQueue.main.async {
                if success {
                    completion(zipPath)
                } else {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - 工具方法

    /// 获取日志文件大小（字节）
    @objc public func getLogFilesTotalSize() -> UInt64 {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: logDirectory) else {
            return 0
        }

        var totalSize: UInt64 = 0
        for file in files {
            let filePath = (logDirectory as NSString).appendingPathComponent(file)
            if let attrs = try? fileManager.attributesOfItem(atPath: filePath),
               let size = attrs[.size] as? UInt64 {
                totalSize += size
            }
        }
        return totalSize
    }

    /// 格式化文件大小
    @objc public func getFormattedLogSize() -> String {
        let size = getLogFilesTotalSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    /// 获取分享URL
    @objc public func getShareURL(for zipPath: String) -> URL? {
        return URL(fileURLWithPath: zipPath)
    }

    // MARK: - Private Methods

    private func createLogDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: logDirectory) {
            try? fileManager.createDirectory(atPath: logDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return dateFormatter.string(from: Date())
    }
}

// MARK: - Swift 专用扩展 (带位置信息)

public extension FKLoggerManager {

    /// Swift 专用 verbose 日志 (自动记录位置)
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        DDLogVerbose("[\((file as NSString).lastPathComponent):\(line)] \(function) -> \(message)")
    }

    /// Swift 专用 debug 日志 (自动记录位置)
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        DDLogDebug("[\((file as NSString).lastPathComponent):\(line)] \(function) -> \(message)")
    }

    /// Swift 专用 info 日志 (自动记录位置)
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        DDLogInfo("[\((file as NSString).lastPathComponent):\(line)] \(function) -> \(message)")
    }

    /// Swift 专用 warn 日志 (自动记录位置)
    func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        DDLogWarn("[\((file as NSString).lastPathComponent):\(line)] \(function) -> \(message)")
    }

    /// Swift 专用 error 日志 (自动记录位置)
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        DDLogError("[\((file as NSString).lastPathComponent):\(line)] \(function) -> \(message)")
    }

    /// 格式化日志输出
    static func format(_ message: String, file: String = #file, function: String = #function, line: Int = #line) -> String {
        let fileName = (file as NSString).lastPathComponent
        return "[\(fileName):\(line)] \(function) -> \(message)"
    }

    /// 记录字典
    func logDict(_ dict: [String: Any], level: FKLogLevel = .debug) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let string = String(data: data, encoding: .utf8) else { return }

        switch level {
        case .verbose: verbose(string)
        case .debug: debug(string)
        case .info: info(string)
        case .warn: warn(string)
        case .error: error(string)
        }
    }

    /// 记录对象
    func logObject(_ object: Any, level: FKLogLevel = .debug) {
        let mirror = Mirror(reflecting: object)
        var dict: [String: Any] = [:]

        for child in mirror.children {
            if let key = child.label {
                dict[key] = child.value
            }
        }

        logDict(dict, level: level)
    }
}
