//
//  YKWChartLineView.m
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

#import "YKWChartLineView.h"

@interface YKWChartLineView() {
    NSMutableArray *_pointsAry;
    UIBezierPath *_drawPath;
    UILabel *_dataLabel;
}

@end

@implementation YKWChartLineView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _dataLabel = [[UILabel alloc] init];
        _dataLabel.frame = CGRectMake(0, 0, 100, 12);
        _dataLabel.font = [UIFont systemFontOfSize:11];
        _dataLabel.textColor = YKWHighlightColor;
        _dataLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_dataLabel];
        
        _pointsAry = [NSMutableArray array];
        _xStep = 20;
        self.lineColor = YKWHighlightColor;
        [self setupBezierPath];
    }
    return self;
}

- (void)drawPoints:(NSArray <NSNumber *>*)pointsAry {
    if (pointsAry) {
        _pointsAry = [pointsAry mutableCopy];
    }
    [self setupBezierPath];
    
    if (_maxValue - _baseValue <= 0) {
        return;
    }
    for (int i = 0; i < _pointsAry.count; i++) {
        CGPoint point = CGPointMake(_xStep * i, (1 - ([_pointsAry[i] floatValue] - _baseValue) / (_maxValue - _baseValue)) * self.ykw_height);
        if (i != 0) {
            [_drawPath addLineToPoint:point];
        }
        [_drawPath moveToPoint:point];
        [_drawPath addArcWithCenter:point radius:2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        [_drawPath moveToPoint:point];

        _dataLabel.text = [NSString stringWithFormat:@"%.2f", [_pointsAry[i] floatValue]];
        _dataLabel.center = CGPointMake(point.x, point.y - _dataLabel.ykw_height);
    }
    
    [self setNeedsDisplay];
}

- (void)clear {
    _dataLabel.text = nil;
    [self setupBezierPath];
    [self setNeedsDisplay];
}

- (void)setupBezierPath {
    _drawPath = [UIBezierPath bezierPath];
    _drawPath.lineWidth = 2.0;
    _drawPath.lineJoinStyle = kCGLineJoinRound;
    _drawPath.lineCapStyle = kCGLineCapRound;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [_lineColor setStroke];
    [_drawPath stroke];
}

@end
