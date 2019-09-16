//
//  YKWoodpeckerUtils.m
//  YKWoodpecker
//
//  Created by Zim on 2019/3/26.
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

#import "YKWoodpeckerUtils.h"

static NSDictionary *_cnLocalizeDic = nil;

@implementation YKWoodpeckerUtils

+ (void)showShareActivityWithItems:(NSArray *)items {
    if (!items.count) return;
    
    UIWindow *window = nil;
    if ([UIApplication sharedApplication].keyWindow.rootViewController) {
        window = [UIApplication sharedApplication].keyWindow;
    } else {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    UIViewController *presentingVC = [[UIViewController alloc] init];
    presentingVC.view.bounds = window.bounds;
    [window addSubview:presentingVC.view];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [presentingVC.view removeFromSuperview];
    };
    
    [presentingVC presentViewController:activityVC animated:YES completion:nil];
}

+ (void)presentViewControllerOnMainWindow:(UIViewController *)controller {
    UIViewController *presentVC = nil;
    if ([UIApplication sharedApplication].keyWindow.rootViewController) {
        presentVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    } else {
        presentVC = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    }
    while (presentVC.presentedViewController) presentVC = presentVC.presentedViewController;
    [presentVC presentViewController:controller animated:true completion:nil];
}

+ (BOOL)isCnLocaleLanguage {
    static BOOL isCn = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isCn = [[[NSLocale preferredLanguages] firstObject] rangeOfString:@"zh-Hans"].location != NSNotFound;
    });
    return isCn;
}

+ (NSString *)localizedStringForKey:(NSString *)key {
    if (![YKWoodpeckerUtils isCnLocaleLanguage]) {
        return key;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"ykwoodpecker_cn.json"];
        NSData *cnData = [[NSData alloc] initWithContentsOfFile:path];
        if (cnData) {
            NSDictionary *cnDic = [NSJSONSerialization JSONObjectWithData:cnData options:0 error:nil];
            if (cnDic) {
                _cnLocalizeDic = cnDic;
            }
        }
    });

    NSString *cnStr = [_cnLocalizeDic objectForKey:key];
    return (cnStr.length ? cnStr : key);
}

@end
