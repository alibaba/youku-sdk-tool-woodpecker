//
//  YKWRulerView.m
//  YKWoodpecker
//
//  Created by Zim on 2019/3/7.
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

#import "YKWRulerView.h"
#import "YKWoodpeckerCommonHeaders.h"

@interface YKWRulerView() {
    UILabel *_widthHeightLabel;
}

@end

@implementation YKWRulerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor ykw_colorWithHexString:@"ff00e6"] colorWithAlphaComponent:0.5];
        self.followWoodpeckerIcon = NO;
        
        _widthHeightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _widthHeightLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _widthHeightLabel.font = [UIFont systemFontOfSize:12.];
        _widthHeightLabel.textColor = [UIColor whiteColor];
        _widthHeightLabel.textAlignment = NSTextAlignmentCenter;
        _widthHeightLabel.adjustsFontSizeToFitWidth = YES;
        _widthHeightLabel.minimumScaleFactor = 0.3;
        [self addSubview:_widthHeightLabel];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    NSString *width = nil;
    if ([self isRoundInteger:self.ykw_width]) {
        width = [NSString stringWithFormat:@"%.0f", self.ykw_width];
    } else {
        width = [NSString stringWithFormat:@"%.1f", self.ykw_width];
    }
    NSString *height = nil;
    if ([self isRoundInteger:self.ykw_height]) {
        height = [NSString stringWithFormat:@"%.0f", self.ykw_height];
    } else {
        height = [NSString stringWithFormat:@"%.1f", self.ykw_height];
    }

    _widthHeightLabel.text = [width stringByAppendingFormat:@"•%@", height];
}

- (BOOL)isRoundInteger:(CGFloat)num {
    return (int)num == num;
}

@end
