//
//  YKWFollowView.m
//  YKWoodpecker
//
//  Created by Zim on 2018/10/25.
//  Copyright © 2018 Youku. All rights reserved.
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

#import "YKWFollowView.h"
#import "YKWoodpeckerCommonHeaders.h"

@implementation YKWFollowView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _followVelocity = 1.0;
        _followWoodpeckerIcon = YES;

        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        _panGestureRecognizer.maximumNumberOfTouches = 1;
        _panGestureRecognizer.minimumNumberOfTouches = 1;
        [_panGestureRecognizer addTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:_panGestureRecognizer];
    }
    return self;
}

- (void)pan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:sender.view];
    [sender setTranslation:CGPointZero inView:sender.view];
    self.center = CGPointMake(self.ykw_centerX + translation.x * self.followVelocity, self.ykw_centerY + translation.y * self.followVelocity);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (!self.followWoodpeckerIcon) {
        return;
    }
    
    [YKWoodpeckerManager sharedInstance].woodpeckerRestPoint = self.frame.origin;
}

- (void)setCenter:(CGPoint)center {
    [super setCenter:center];
    
    if (!self.followWoodpeckerIcon) {
        return;
    }

    [YKWoodpeckerManager sharedInstance].woodpeckerRestPoint = self.frame.origin;
}

@end
