//
//  YKWMemoryPlugin.m
//  YKWoodpecker
//
//  Created by Zim on 2019/3/15.
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

#import "YKWMemoryPlugin.h"
#import "YKWChartWindow.h"
#import "YKWMemoryUtils.h"

static YKWChartWindow *_chartWindow;

@implementation YKWMemoryPlugin

- (void)runWithParameters:(NSDictionary *)paraDic {
    if (!_chartWindow) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height;
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            width /= 2.;
        }
        _chartWindow = [[YKWChartWindow alloc] initWithFrame:CGRectMake(1, 20, width - 2, 180.)];
        _chartWindow.yTitle = @"MB";
        [_chartWindow makeKeyAndVisible];
    }
    
    _chartWindow.hidden = NO;
    [_chartWindow clearData];
    [_chartWindow startQueryDataWithInterval:1.0 block:^(NSMutableArray *dataAry) {
        [dataAry addObject:[NSString stringWithFormat:@"%.2f", [YKWMemoryUtils memoryUsage] / 1024. / 1024.]];
        while (dataAry.count > 50) {
            [dataAry removeObjectAtIndex:0];
        }
    }];
}

@end
