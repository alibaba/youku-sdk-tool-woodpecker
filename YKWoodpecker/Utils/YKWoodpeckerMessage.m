//
//  YKWoodpeckerMessage.m
//  YKWoodpecker
//
//  Created by Zim on 2018/11/19.
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

#import "YKWoodpeckerMessage.h"

#define kYKWoodpeckerMessageTag -28588

@implementation YKWoodpeckerMessage

+ (void)showMessage:(NSString *)msg {
    YKWoodpeckerMessage *ykwmsg = [[YKWoodpeckerMessage alloc] initWithMessag:msg];
    [ykwmsg showWithDuratin:2.0 inView:nil position:CGPointZero];
}

+ (void)showMessage:(NSString *)msg duration:(NSTimeInterval)interval {
    YKWoodpeckerMessage *ykwmsg = [[YKWoodpeckerMessage alloc] initWithMessag:msg];
    [ykwmsg showWithDuratin:interval inView:nil position:CGPointZero];
}

+ (void)showMessage:(NSString *)msg duration:(NSTimeInterval)interval inView:(UIView *)view position:(CGPoint)postion {
    YKWoodpeckerMessage *ykwmsg = [[YKWoodpeckerMessage alloc] initWithMessag:msg];
    [ykwmsg showWithDuratin:interval inView:view position:postion];
}

+ (void)showActivityMessage:(NSString *)msg {
    YKWoodpeckerMessage *ykwmsg = [[YKWoodpeckerMessage alloc] initWithMessag:msg];
    [ykwmsg showWithDuratin:2.0 inView:nil position:CGPointZero];
}

+ (void)hideActivityMessage {
    UIView *msgView = [[UIApplication sharedApplication].windows.firstObject viewWithTag:kYKWoodpeckerMessageTag];
    [msgView removeFromSuperview];
}

- (instancetype)initWithMessag:(NSString *)msg {
    self = [self init];
    if (self) {
        self.tag = kYKWoodpeckerMessageTag;
        self.font = [UIFont systemFontOfSize:14];
        self.textColor = [UIColor whiteColor];
        self.numberOfLines = 0;
        self.textAlignment = NSTextAlignmentCenter;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
        self.text = msg;
        self.layer.zPosition = 1000.;
    }
    return self;
}

- (void)showWithDuratin:(NSTimeInterval)interval inView:(UIView *)view position:(CGPoint)postion  {
    if (!view) {
        view = [UIApplication sharedApplication].windows.firstObject;
        postion = CGPointMake(view.ykw_width / 2, view.ykw_height / 2);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ykw_width = view.bounds.size.width - 100.;
        [self sizeToFit];
        self.ykw_width += 40.;
        self.ykw_height += 30.;
        self.center = postion;
        self.alpha = 0.0;
        [view addSubview:self];
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 1.0;
        }];
        if (interval > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self hide];
            });
        }
    });
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
