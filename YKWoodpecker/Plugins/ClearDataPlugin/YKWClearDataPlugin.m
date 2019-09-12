//
//  YKWClearDataPlugin.m
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

#import "YKWClearDataPlugin.h"
#import "YKWoodpeckerMessage.h"

@implementation YKWClearDataPlugin

- (void)runWithParameters:(NSDictionary *)paraDic {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:YKWLocalizedString(@"Are you sure to clear all data?") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:YKWLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:YKWLocalizedString(@"Sure") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [YKWClearDataPlugin clearData];
    }];
    [alert addAction:action2];
    [alert addAction:action1];
    [YKWoodpeckerUtils presentViewControllerOnMainWindow:alert];
}

+ (void)clearData {
    [YKWoodpeckerMessage showActivityMessage:YKWLocalizedString(@"Clearing...")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Clear files
        NSString *homePath = NSHomeDirectory();
        [self clearPath:[homePath stringByAppendingPathComponent:@"Documents"]];
        [self clearPath:[homePath stringByAppendingPathComponent:@"Library"]];
        [self clearPath:[homePath stringByAppendingPathComponent:@"tmp"]];
        [self clearPath:[homePath stringByAppendingPathComponent:@"SystemData"]];
        // Clear NSUserDefaults
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];

        dispatch_sync(dispatch_get_main_queue(), ^{
            [YKWoodpeckerMessage hideActivityMessage];
            [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Done")];
        });
    });
}

+ (void)clearPath:(NSString *)path {
    NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:path];
    for (NSString *file in files) {
        NSString *filePath = [path stringByAppendingPathComponent:file];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

@end
