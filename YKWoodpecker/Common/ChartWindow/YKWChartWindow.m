//
//  YKWChartWindow.m
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

#import "YKWChartWindow.h"
#import "YKWChartView.h"
#import "YKWRotationWindowRootViewController.h"

@interface YKWChartWindow() {
    YKWChartView *_chartView;
    UILabel *_statusBarLabel;
    CGRect _previousFrame;
    
    UIButton *_pauseBtn;
    UIButton *_closeBtn;
    
    NSTimeInterval _queryInterval;
    NSTimer *_queryTimer;
    NSMutableArray *_dataAry;
}

@property(nonatomic,strong )void (^queryBlock)(NSMutableArray *dataAry);


@end

@implementation YKWChartWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.rootViewController = [YKWRotationWindowRootViewController new];
        self.rootViewController.view.backgroundColor = [UIColor clearColor];
        self.rootViewController.view.userInteractionEnabled = NO;
        
        self.backgroundColor = [UIColor whiteColor];
        self.windowLevel = UIWindowLevelStatusBar + 1;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.borderWidth = 0.5;
        _previousFrame = frame;
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        panGestureRecognizer.minimumNumberOfTouches = 1;
        [panGestureRecognizer addTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:panGestureRecognizer];

        _queryInterval = 0.0;
        _queryTimer = nil;
        _dataAry = [NSMutableArray array];
        
        _chartView = [[YKWChartView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _chartView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:_chartView];
        
        _statusBarLabel = [[UILabel alloc] init];
        _statusBarLabel.frame = CGRectMake(20, 15, frame.size.width - 30, 15);
        _statusBarLabel.font = [UIFont systemFontOfSize:12];
        _statusBarLabel.textAlignment = NSTextAlignmentCenter;
        _statusBarLabel.textColor = YKWHighlightColor;
        _statusBarLabel.adjustsFontSizeToFitWidth = YES;
        _statusBarLabel.minimumScaleFactor = 0.5;
        _statusBarLabel.userInteractionEnabled = YES;
        [_statusBarLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(statusBarLabelTap)]];
        [self addSubview:_statusBarLabel];

        _pauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _pauseBtn.frame = CGRectMake(frame.size.width - 75., -3, 50., 50.);
        _pauseBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        _pauseBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:15.];
        [_pauseBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_pauseBtn setTitle:@"‖" forState:UIControlStateNormal];
        [_pauseBtn setTitle:@"▷" forState:UIControlStateSelected];
        [_pauseBtn addTarget:self action:@selector(handlePause:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pauseBtn];
        
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeBtn.frame = CGRectMake(self.ykw_width - 45., -5, 50., 50.);
        _closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        _closeBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:20.];
        [_closeBtn setTitle:@"×" forState:UIControlStateNormal];
        [_closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeBtn];
    }
    return self;
}

- (void)close {
    self.hidden = YES;
    
    if (self && [self.delegate respondsToSelector:@selector(chartWindowDidHide:)]) {
        [self.delegate chartWindowDidHide:self];
    }
}

- (void)handlePause:(UIButton *)sender {
    if (sender.selected) {
        sender.selected = NO;
        [self resume];
    } else {
        sender.selected = YES;
        [self pause];
    }
}

- (void)becomeKeyWindow {
    [[UIApplication sharedApplication].windows.firstObject makeKeyAndVisible];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    if (hidden) {
        [self stopQueryData];
    }
}

- (void)pan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:sender.view];
    [sender setTranslation:CGPointZero inView:sender.view];
    self.center = CGPointMake(self.ykw_centerX + translation.x, self.ykw_centerY + translation.y);
}

- (void)clearData {
    _dataAry = [NSMutableArray array];
    [_chartView clear];
    _pauseBtn.selected = NO;
}

- (void)startQueryDataWithInterval:(NSTimeInterval)interval block:(void(^)(NSMutableArray *dataAry))block {
    [self stopQueryData];
    
    if (interval > 0.01 && block) {
        _queryInterval = interval;
        self.queryBlock = block;
        _queryTimer = [NSTimer scheduledTimerWithTimeInterval:_queryInterval target:self selector:@selector(handleQueryTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_queryTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)handleQueryTimer:(NSTimer *)sender {
    self.queryBlock(_dataAry);
    [self updateData];
}

- (void)updateData {
    if (self.statusBarMode) {
        if (!_dataAry.count) {
            _statusBarLabel.text = @"No Data";
            return;
        }
        
        NSUInteger count = _dataAry.count;
        float minData = MAXFLOAT;
        float maxData = 0;
        float total = 0;
        float totalpow2 = 0;
        for (int i = 0; i < count; i++) {
            float data = [_dataAry[i] floatValue];
            if (data > maxData) {
                maxData = data;
            }
            if (data < minData) {
                minData = data;
            }
            total += data;
            totalpow2 += data * data;
        }
        float avg = total / count;
        float variance = sqrt(totalpow2 / count - avg * avg);
        _statusBarLabel.text = [NSString stringWithFormat:@"%@: %@ (max:%.2f min:%.2f avg:%.2f σ:%.2f)", _yTitle, _dataAry.lastObject, maxData, minData, avg, variance];
    } else {
        _chartView.dataArray = _dataAry;
    }
}

- (void)pause {
    if (_queryTimer) {
        [_queryTimer invalidate];
        _queryTimer = nil;
    }
}

- (void)resume {
    [self pause];
    if (self.queryBlock) {
        _queryTimer = [NSTimer scheduledTimerWithTimeInterval:_queryInterval target:self selector:@selector(handleQueryTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_queryTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)stopQueryData {
    if (_queryTimer) {
        [_queryTimer invalidate];
        _queryTimer = nil;
    }
    self.queryBlock = nil;
}

- (void)statusBarLabelTap {
    self.statusBarMode = !self.statusBarMode;
}

- (void)setStatusBarMode:(BOOL)statusBarMode {
    if (_statusBarMode == statusBarMode) {
        return;
    }
    
    _statusBarMode = statusBarMode;
    if (_statusBarMode) {
        _previousFrame = self.frame;
        self.frame = CGRectMake(self.ykw_left, self.ykw_top > 20 ? self.ykw_top : 20, self.ykw_width, 20);
        _statusBarLabel.frame = self.bounds;
        _chartView.hidden = YES;
        _pauseBtn.hidden = YES;
        _closeBtn.hidden = YES;
    } else {
        self.frame = CGRectMake(self.ykw_left, self.ykw_top, self.ykw_width, _previousFrame.size.height);
        _statusBarLabel.frame = CGRectMake(20, 15, self.ykw_width - 30, 15);
        _statusBarLabel.text = nil;
        _chartView.hidden = NO;
        _pauseBtn.hidden = NO;
        _closeBtn.hidden = NO;
    }
    [self updateData];
}


- (void)setYTitle:(NSString *)yTitle {
    _yTitle = yTitle;
    _chartView.yTitle = _yTitle;
}

@end
