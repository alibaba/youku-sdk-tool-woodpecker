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

@interface YKWChartWindow() {
    YKWChartView *_chartView;
    
    UIButton *_pauseBtn;
    
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
        self.backgroundColor = [UIColor whiteColor];
        self.windowLevel = UIWindowLevelStatusBar - 1.0;

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
        _chartView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _chartView.layer.borderWidth = 0.5;
        [self addSubview:_chartView];
        
        _pauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _pauseBtn.frame = CGRectMake(frame.size.width - 75., -3, 50., 50.);
        _pauseBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        _pauseBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:15.];
        [_pauseBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_pauseBtn setTitle:@"‖" forState:UIControlStateNormal];
        [_pauseBtn setTitle:@"▷" forState:UIControlStateSelected];
        [_pauseBtn addTarget:self action:@selector(handlePause:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pauseBtn];
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.frame = CGRectMake(self.width - 45., -5, 50., 50.);
        closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        closeBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:20.];
        [closeBtn setTitle:@"×" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:closeBtn];

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
    self.center = CGPointMake(self.centerX + translation.x, self.centerY + translation.y);
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
    _chartView.dataArray = _dataAry;
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

- (void)setYTitle:(NSString *)yTitle {
    _yTitle = yTitle;
    _chartView.yTitle = _yTitle;
}

@end
