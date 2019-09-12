//
//  YKWCrashLogPlugin.m
//  YKWoodpecker
//
//  Created by Zim on 2019/3/19.
//  Copyright © 2019 Youku. All rights reserved.
//
//  MIT License
//
//  Copyright (c) 2019 Alibaba
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "YKWCrashLogPlugin.h"
#import "YKWPathFileTableViewController.h"

static NSUncaughtExceptionHandler *previousExceptionHandler = NULL;

@implementation YKWCrashLogPlugin

- (void)runWithParameters:(NSDictionary *)paraDic {
    [YKWCrashLogPlugin registerHandler];
    
    YKWPathFileTableViewController *controller = [[YKWPathFileTableViewController alloc] init];
    controller.path = ykwoodpecker_crashLogPath();
    controller.title = @"Crash Log";
    controller.navigationItem.title = @"Crash Log";
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [YKWoodpeckerUtils presentViewControllerOnMainWindow:nav];
}

+ (void)registerHandler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        previousExceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&ykwoodpecker_uncaughtExceptionHandler);
    });
}

static void ykwoodpecker_uncaughtExceptionHandler(NSException * exception) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];
    NSString *timeStamp = [formatter stringFromDate:[NSDate date]];
    NSString *crashLog = [NSString stringWithFormat:@"Time:%@\nName:%@\nReason:\n%@\nCallStackSymbols:\n%@", timeStamp, exception.name, exception.reason, [exception.callStackSymbols componentsJoinedByString:@"\n"]];
    
    ykwoodpecker_saveCrashLog(crashLog, timeStamp);
    
    if (previousExceptionHandler) {
        previousExceptionHandler(exception);
    }
}

static void ykwoodpecker_saveCrashLog(NSString *crashLog, NSString *timeStamp) {
    NSString *crashLogPath = ykwoodpecker_crashLogPath();
    if (![[NSFileManager defaultManager] fileExistsAtPath:crashLogPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:crashLogPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:crashLogPath]) {
        NSString *filePath = [crashLogPath stringByAppendingPathComponent:[NSString stringWithFormat:@"crash_%@.txt", timeStamp]];
        [crashLog writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

static NSString * ykwoodpecker_crashLogPath() {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *crashLogPath = [cachePath stringByAppendingPathComponent:@"Woodpecker_Crash_Log"];
    return crashLogPath;
}

@end
