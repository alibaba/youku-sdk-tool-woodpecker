//
//  YKWChartView.m
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

#import "YKWChartView.h"
#import "YKWChartLineView.h"

#define kDataScale 1.3

@interface YKWChartView() {
    float _minData;
    float _maxData;
    
    UIScrollView *_scrollView;
    YKWChartLineView *_lineView;
    UILabel *_yTitleLabel;
    
    NSMutableArray *_yLabelsArray;
    NSMutableArray *_yLinesArray;
}

@end

@implementation YKWChartView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _dataArray = [NSMutableArray array];
        
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(45, 50, frame.size.width - 45, frame.size.height - 80)];
        _scrollView.directionalLockEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_scrollView];
        
        _lineView = [[YKWChartLineView alloc] initWithFrame:CGRectMake(0, 0, _scrollView.ykw_width, _scrollView.ykw_height)];
        [_scrollView addSubview:_lineView];
        
        _yTitleLabel = [[UILabel alloc] init];
        _yTitleLabel.frame = CGRectMake(20, 15, frame.size.width - 30, 15);
        _yTitleLabel.font = [UIFont systemFontOfSize:12];
        _yTitleLabel.textColor = [UIColor lightGrayColor];
        _yTitleLabel.adjustsFontSizeToFitWidth = YES;
        _yTitleLabel.minimumScaleFactor = 0.5;
        [self addSubview:_yTitleLabel];
        
        _yLabelsArray = [NSMutableArray array];
        _yLinesArray = [NSMutableArray array];
        [self setupYLines];
        [self setupYLabels];
    }
    return self;
}

- (void)setLineColor:(UIColor *)lineColor {
    _lineColor = lineColor;
    _lineView.lineColor = _lineColor;
}

- (void)setDataArray:(NSMutableArray *)dataArray {
    _dataArray = dataArray;
    if (!_dataArray.count) {
        [self clear];
        return;
    }
    
    NSUInteger count = _dataArray.count;
    _minData = MAXFLOAT;
    _maxData = 0;
    float total = 0;
    float totalpow2 = 0;
    for (int i = 0; i < count; i++) {
        float data = [_dataArray[i] floatValue];
        if (data > _maxData) {
            _maxData = data;
        }
        if (data < _minData) {
            _minData = data;
        }
        total += data;
        totalpow2 += data * data;
    }
    float avg = total / count;
    float variance = sqrt(totalpow2 / count - avg * avg);
    _yTitleLabel.text = [NSString stringWithFormat:@"%@/ max:%.2f min:%.2f avg:%.2f σ:%.2f", _yTitle, _maxData, _minData, avg, variance];
    [self setupYLabels];
    
    CGSize contentSize = CGSizeMake(_dataArray.count * _lineView.xStep + 10, 0);
    _scrollView.contentSize = contentSize;
    _lineView.ykw_width = contentSize.width;
    if (contentSize.width > _scrollView.ykw_width) {
        [_scrollView setContentOffset:CGPointMake(contentSize.width - _scrollView.ykw_width, 0) animated:NO];
    }
    
    _lineView.baseValue = _minData / kDataScale;
    _lineView.maxValue = _maxData * kDataScale;
    [_lineView drawPoints:_dataArray];
}

- (void)setupYLabels {
    [_yLabelsArray makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    float max = _maxData * kDataScale;
    float min = _minData / kDataScale;
    
    float step = (max - min) / 5.;
    for (int i = 0; i < 6; i++) {
        float y = min + step * i;
        UILabel *yLabel = [[UILabel alloc] init];
        yLabel.frame = CGRectMake(0, 0, 40, 15);
        yLabel.ykw_centerY = 50. + (5 - i) * (self.ykw_height - 80.) / 5.;
        yLabel.textColor = [UIColor lightGrayColor];
        yLabel.font = [UIFont systemFontOfSize:10];
        yLabel.textAlignment = NSTextAlignmentRight;
        if (min > 10) {
            yLabel.text = [NSString stringWithFormat:@"%.0f", y];
        } else {
            yLabel.text = [NSString stringWithFormat:@"%.2f", y];
        }
        [self addSubview:yLabel];
        [_yLabelsArray addObject:yLabel];
    }
}

- (void)setupYLines {
    [_yLinesArray makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (int i = 0; i < 6; i++) {
        UIView *line = [[UIView alloc] init];
        line.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.8];
        line.frame = CGRectMake(45, 0, self.ykw_width - 45, 1. / [UIScreen mainScreen].scale);
        line.ykw_centerY = 50. + i * (self.ykw_height - 80.) / 5.;
        [self insertSubview:line atIndex:0];
        [_yLinesArray addObject:line];
    }
}

- (void)clear {
    [_lineView clear];
    _yTitleLabel.text = nil;
    [self setupYLabels];
}

@end
