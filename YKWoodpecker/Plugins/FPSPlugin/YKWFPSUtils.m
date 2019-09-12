//
//  YKWFPSUtils.m
//  YKWoodpecker
//
//  Created by Zim on 2019/3/18.
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

#import "YKWFPSUtils.h"
#import "YKWChartWindow.h"

@interface YKWFPSUtils()<YKWChartWindowDelegate> {
    CADisplayLink *_displayLink;
    
    CFTimeInterval _preTimeStamp;
    CFTimeInterval _currentTimeStamp;
    NSInteger _displayCount;
}

@end

@implementation YKWFPSUtils

+ (YKWFPSUtils *)sharedInstance {
    static YKWFPSUtils *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)startFps {
    [self stopFps];
    
    _preTimeStamp = 0;
    _displayCount = 0;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopFps {
    if (_displayLink) {
        _displayLink.paused = YES;
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void)handleDisplayLink:(CADisplayLink *)link {
    if (_preTimeStamp == 0) {
        _preTimeStamp = link.timestamp;
        _displayCount = 0;
    } else {
        _displayCount++;
        _currentTimeStamp = link.timestamp;
    }
}

- (float)fps {
    CFTimeInterval span = _currentTimeStamp - _preTimeStamp;
    if (span > 0) {
        float fps = _displayCount / span;
        _preTimeStamp = 0;
        _displayCount = 0;
        return fps;
    }
    return 0.0;
}

- (void)chartWindowDidHide:(YKWChartWindow *)chartWindow {
    [self stopFps];
}

@end
