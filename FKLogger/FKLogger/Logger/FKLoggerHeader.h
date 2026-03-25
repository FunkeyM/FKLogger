//
//  FKLoggerHeader.h
//  FKLogger
//
//  Created by Bobby on 2026/3/24.
//

#ifndef FKLoggerHeader_h
#define FKLoggerHeader_h

#if __has_include("FKLogger-Swift.h")
#import "FKLogger-Swift.h"
#endif

#define FKLogVerbose(fmt, ...) [[FKLoggerManager shared] verbose:[NSString stringWithFormat:fmt, ##__VA_ARGS__] file:[NSString stringWithUTF8String:__FILE__] function:[NSString stringWithUTF8String:__FUNCTION__] line:__LINE__]
#define FKLogDebug(fmt, ...) [[FKLoggerManager shared] debug:[NSString stringWithFormat:fmt, ##__VA_ARGS__] file:[NSString stringWithUTF8String:__FILE__] function:[NSString stringWithUTF8String:__FUNCTION__] line:__LINE__]
#define FKLogInfo(fmt, ...) [[FKLoggerManager shared] info:[NSString stringWithFormat:fmt, ##__VA_ARGS__] file:[NSString stringWithUTF8String:__FILE__] function:[NSString stringWithUTF8String:__FUNCTION__] line:__LINE__]
#define FKLogWarn(fmt, ...) [[FKLoggerManager shared] warn:[NSString stringWithFormat:fmt, ##__VA_ARGS__] file:[NSString stringWithUTF8String:__FILE__] function:[NSString stringWithUTF8String:__FUNCTION__] line:__LINE__]
#define FKLogError(fmt, ...) [[FKLoggerManager shared] error:[NSString stringWithFormat:fmt, ##__VA_ARGS__] file:[NSString stringWithUTF8String:__FILE__] function:[NSString stringWithUTF8String:__FUNCTION__] line:__LINE__]


#endif /* FKLoggerHeader_h */
