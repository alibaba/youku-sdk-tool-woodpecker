//
//  YKWDataFlowPlugin.m
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

#import "YKWDataFlowPlugin.h"
#import "YKWChartWindow.h"
#import "YKWDataFlowUtils.h"

static YKWChartWindow *_chartWindow;
static unsigned int _lastDataFlow = 0;

@implementation YKWDataFlowPlugin

- (void)runWithParameters:(NSDictionary *)paraDic {
    if (!_chartWindow) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height;
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            width /= 2.;
        }
        _chartWindow = [[YKWChartWindow alloc] initWithFrame:CGRectMake(1, 20, width - 2, 180.)];
        [_chartWindow makeKeyAndVisible];
    }
    
    _chartWindow.hidden = NO;
    [_chartWindow clearData];
    _lastDataFlow = [YKWDataFlowUtils netDataFlow];
    [_chartWindow startQueryDataWithInterval:1.0 block:^(NSMutableArray *dataAry) {
        unsigned int dataFlow = [YKWDataFlowUtils netDataFlow] - _lastDataFlow;
        if (dataFlow > 1024 * 1024 * 1024) {
            if (![_chartWindow.yTitle isEqualToString:@"GB"]) {
                NSArray *ary = [dataAry copy];
                [dataAry removeAllObjects];
                for (NSString *s in ary) {
                    [dataAry addObject:[NSString stringWithFormat:@"%.2f", s.doubleValue / 1024.]];
                }
            }
            _chartWindow.yTitle = @"GB";
            [dataAry addObject:[NSString stringWithFormat:@"%.2f", dataFlow / (1024 * 1024 * 1024.)]];
        } else if (dataFlow > 1024 * 1024) {
            if (![_chartWindow.yTitle isEqualToString:@"MB"]) {
                NSArray *ary = [dataAry copy];
                [dataAry removeAllObjects];
                for (NSString *s in ary) {
                    [dataAry addObject:[NSString stringWithFormat:@"%.2f", s.doubleValue / 1024.]];
                }
            }
            _chartWindow.yTitle = @"MB";
            [dataAry addObject:[NSString stringWithFormat:@"%.2f", dataFlow / (1024 * 1024.)]];
        } else if (dataFlow > 1024)  {
            if (![_chartWindow.yTitle isEqualToString:@"KB"]) {
                NSArray *ary = [dataAry copy];
                [dataAry removeAllObjects];
                for (NSString *s in ary) {
                    [dataAry addObject:[NSString stringWithFormat:@"%.2f", s.doubleValue / 1024.]];
                }
            }
            _chartWindow.yTitle = @"KB";
            [dataAry addObject:[NSString stringWithFormat:@"%.2f", dataFlow / 1024.]];
        } else {
            _chartWindow.yTitle = @"B";
            [dataAry addObject:[NSString stringWithFormat:@"%u", dataFlow]];
        }
        while (dataAry.count > 50) {
            [dataAry removeObjectAtIndex:0];
        }
    }];
}

@end
