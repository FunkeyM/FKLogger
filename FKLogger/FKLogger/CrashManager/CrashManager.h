//
//  CrashManager.h
//  FKLogger
//
//  Created by Bobby on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 崩溃管理器 - 捕获未处理的异常和信号
@interface CrashManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 上一次崩溃的信息
@property (nonatomic, strong, readonly, nullable) NSString *lastCrashInfo;

/// 崩溃日志文件路径
@property (nonatomic, strong, readonly, nullable) NSString *crashLogFilePath;

/// 崩溃回调
@property (nonatomic, copy, nullable) void (^onCrash)(NSString *crashInfo);

/// 启动崩溃捕获
- (void)start;

/// 停止崩溃捕获
- (void)stop;

/// 读取上次崩溃日志文件内容
+ (nullable NSString *)readLastCrashLog;

@end

NS_ASSUME_NONNULL_END
