//
//  CrashManager.m
//  FKLogger
//
//  Created by Bobby on 2026/3/24.
//

#import "CrashManager.h"
#import <signal.h>
#import <unistd.h>

#pragma mark - 信号处理

static int gSignals[] = {SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGSEGV, SIGTRAP};
static NSString *gSignalNames[] = {@"SIGABRT", @"SIGBUS", @"SIGFPE", @"SIGILL", @"SIGSEGV", @"SIGTRAP"};
static struct sigaction gPreviousActions[6];
static CrashManager *gCrashManager = nil;
static NSString *gLogFilePath = nil;

// 异步安全写入文件
static void WriteToFile(const char *content) {
    if (!gLogFilePath) {
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        gLogFilePath = [docPath stringByAppendingPathComponent:@"crash.log"];
    }

    int fd = open([gLogFilePath UTF8String], O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd >= 0) {
        write(fd, content, strlen(content));
        write(fd, "\n", 1);
        fsync(fd);
        close(fd);
    }
}

static void SignalHandler(int sig) {
    // 获取调用栈
    NSMutableString *stackInfo = [NSMutableString string];
    NSArray *stack = [NSThread callStackSymbols];
    [stackInfo appendString:@"Call Stack:\n"];
    for (NSUInteger i = 0; i < stack.count; i++) {
        [stackInfo appendFormat:@"  %lu: %@\n", (unsigned long)i, stack[i]];
    }

    // 查找信号名称
    NSString *signalName = @"UNKNOWN";
    for (int i = 0; i < 6; i++) {
        if (gSignals[i] == sig) {
            signalName = gSignalNames[i];
            break;
        }
    }

    // 时间戳
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];

    NSString *crashInfo = [NSString stringWithFormat:@"[%@] Signal: %@ (%d)\n%@", timestamp, signalName, sig, stackInfo];

    // 保存到 CrashManager
    if (gCrashManager) {
        [gCrashManager setValue:crashInfo forKey:@"lastCrashInfo"];
        if (gCrashManager.onCrash) {
            gCrashManager.onCrash(crashInfo);
        }
    }

    // 写入文件（异步安全）
    WriteToFile([crashInfo UTF8String]);

    // 同时输出到控制台
    NSLog(@"\n========== CRASH DETECTED ==========\n%@\n====================================", crashInfo);

    // 恢复之前的信号处理器并重新抛出信号
    int index = -1;
    for (int i = 0; i < 6; i++) {
        if (gSignals[i] == sig) {
            index = i;
            break;
        }
    }
    if (index >= 0) {
        sigaction(sig, &gPreviousActions[index], NULL);
    }
    raise(sig);
}

static void RegisterSignalHandlers(void) {
    for (int i = 0; i < 6; i++) {
        struct sigaction action;
        memset(&action, 0, sizeof(action));
        action.sa_handler = SignalHandler;
        sigemptyset(&action.sa_mask);
        action.sa_flags = 0;
        sigaction(gSignals[i], &action, &gPreviousActions[i]);
    }
}

static void UnregisterSignalHandlers(void) {
    for (int i = 0; i < 6; i++) {
        sigaction(gSignals[i], &gPreviousActions[i], NULL);
    }
}

#pragma mark - 异常处理

static NSUncaughtExceptionHandler *gPreviousExceptionHandler = NULL;

static void ExceptionHandler(NSException *exception) {
    // 构建异常信息
    NSString *name = exception.name;
    NSString *reason = exception.reason ?: @"Unknown";
    NSMutableString *info = [NSMutableString stringWithFormat:@"NSException: %@\nReason: %@", name, reason];

    NSArray *callStack = exception.callStackSymbols;
    if (callStack.count > 0) {
        [info appendString:@"\nCall Stack:\n"];
        for (NSUInteger i = 0; i < callStack.count; i++) {
            [info appendFormat:@"  %lu: %@\n", (unsigned long)i, callStack[i]];
        }
    }

    // 时间戳
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    NSString *crashInfo = [NSString stringWithFormat:@"[%@] %@", timestamp, info];

    // 保存到 CrashManager
    if (gCrashManager) {
        [gCrashManager setValue:crashInfo forKey:@"lastCrashInfo"];
        if (gCrashManager.onCrash) {
            gCrashManager.onCrash(crashInfo);
        }
    }

    // 写入文件
    WriteToFile([crashInfo UTF8String]);

    // 输出到控制台
    NSLog(@"\n========== CRASH DETECTED ==========\n%@\n====================================", crashInfo);

    // 调用之前的异常处理器
    if (gPreviousExceptionHandler) {
        gPreviousExceptionHandler(exception);
    }
}

static void RegisterExceptionHandler(void) {
    gPreviousExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(ExceptionHandler);
}

static void UnregisterExceptionHandler(void) {
    NSSetUncaughtExceptionHandler(gPreviousExceptionHandler);
    gPreviousExceptionHandler = NULL;
}

#pragma mark - CrashManager

@interface CrashManager ()

@property (nonatomic, strong, readwrite, nullable) NSString *lastCrashInfo;

@end

@implementation CrashManager

+ (instancetype)sharedManager {
    static CrashManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CrashManager alloc] init];
        gCrashManager = instance;
    });
    return instance;
}

- (void)start {
    // 初始化日志文件路径
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    gLogFilePath = [docPath stringByAppendingPathComponent:@"crash.log"];

    RegisterExceptionHandler();
    RegisterSignalHandlers();

    NSLog(@"[CrashManager] Started - Crash log will be saved to: %@", gLogFilePath);
}

- (void)stop {
    UnregisterExceptionHandler();
    UnregisterSignalHandlers();
    NSLog(@"[CrashManager] Stopped");
}

- (NSString *)crashLogFilePath {
    return gLogFilePath;
}

+ (NSString *)readLastCrashLog {
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [docPath stringByAppendingPathComponent:@"crash.log"];
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

@end
