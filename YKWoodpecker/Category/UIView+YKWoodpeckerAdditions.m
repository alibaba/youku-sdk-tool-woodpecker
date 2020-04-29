//
//  UIView+ITTAdditions.m
//  iTotemFrame
//
//  Created by jack on 3/15/12.
//  Copyright (c) 2012 iTotemStudio. All rights reserved.
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

#import "UIView+YKWoodpeckerAdditions.h"

@implementation UIView (YKWoodpeckerAdditions)

- (CGFloat)ykw_left {
    return self.frame.origin.x;
}

- (void)setYkw_left:(CGFloat)ykw_left {
    CGRect frame = self.frame;
    frame.origin.x = ykw_left;
    self.frame = frame;
}

- (CGFloat)ykw_top {
    return self.frame.origin.y;
}

- (void)setYkw_top:(CGFloat)ykw_top {
    CGRect frame = self.frame;
    frame.origin.y = ykw_top;
    self.frame = frame;
}

- (CGFloat)ykw_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setYkw_right:(CGFloat)ykw_right {
    CGRect frame = self.frame;
    frame.origin.x = ykw_right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)ykw_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setYkw_bottom:(CGFloat)ykw_bottom {
    CGRect frame = self.frame;
    frame.origin.y = ykw_bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)ykw_centerX {
    return self.center.x;
}

- (void)setYkw_centerX:(CGFloat)ykw_centerX {
    self.center = CGPointMake(ykw_centerX, self.center.y);
}

- (CGFloat)ykw_centerY {
    return self.center.y;
}

- (void)setYkw_centerY:(CGFloat)ykw_centerY {
    self.center = CGPointMake(self.center.x, ykw_centerY);
}

- (CGFloat)ykw_width {
    return self.frame.size.width;
}

- (void)setYkw_width:(CGFloat)ykw_width {
    CGRect frame = self.frame;
    frame.size.width = ykw_width;
    self.frame = frame;
}

- (CGFloat)ykw_height {
    return self.frame.size.height;
}

- (void)setYkw_height:(CGFloat)ykw_height {
    CGRect frame = self.frame;
    frame.size.height = ykw_height;
    self.frame = frame;
}

@end
