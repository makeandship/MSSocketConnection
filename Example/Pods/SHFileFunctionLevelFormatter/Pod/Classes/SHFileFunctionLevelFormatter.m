//
//  SHFileFunctionLevelFormatter.m
//
//  Created by Simon Heys on 4/12/14.
//  Copyright (c) 2014 Simon Heys Limited. All rights reserved.
//

#import "SHFileFunctionLevelFormatter.h"

@implementation SHFileFunctionLevelFormatter

+ (NSDateFormatter *)dateFormatter
{
     static NSDateFormatter *dateFormatter;
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
     });
     return dateFormatter;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *dateAndTime = [[[self class] dateFormatter] stringFromDate:(logMessage->timestamp)];
    NSString *logLevel = nil;
    switch (logMessage->logFlag) {
        case LOG_FLAG_ERROR : logLevel = @"ERROR "; break;
        case LOG_FLAG_WARN  : logLevel = @"WARN "; break;
        case LOG_FLAG_INFO  : logLevel = @"INFO "; break;
        case LOG_FLAG_DEBUG : logLevel = @"DEBUG "; break;
        default             : logLevel = @""; break;
    }

    return [NSString stringWithFormat:@"%@ %@[%@ %@][%d] %@",
        dateAndTime,
        logLevel,
        logMessage.fileName,
        logMessage.methodName,
        logMessage->lineNumber,
        logMessage->logMsg
    ];
}
@end
