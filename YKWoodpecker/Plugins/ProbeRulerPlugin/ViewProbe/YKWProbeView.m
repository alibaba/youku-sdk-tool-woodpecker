//
//  YKWProbeView.m
//  YKWoodpecker
//
//  Created by Zim on 2018/11/9.
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

#import "YKWProbeView.h"
#import "YKWLineNoteView.h"
#import "YKWFollowView.h"
#import "YKWoodpeckerMessage.h"

#define kYKWProbeViewResolveAllView @"YKWProbeViewResolveAllView"

@interface YKWProbeView() {
    BOOL _resolveAllView;

    BOOL _isDoubleTap;
    UIView *_toSkipView;
}

@property (nonatomic, strong) YKWLineNoteView *leftNoteView;
@property (nonatomic, strong) YKWLineNoteView *topNoteView;
@property (nonatomic, strong) YKWLineNoteView *rightNoteView;
@property (nonatomic, strong) YKWLineNoteView *bottomNoteView;

@end

@implementation YKWProbeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _resolveAllView = [[NSUserDefaults standardUserDefaults] boolForKey:kYKWProbeViewResolveAllView];
        _showFrames = YES;
        _isDoubleTap = NO;
        _toSkipView = nil;
        
        self.frameViewAry = [NSMutableArray array];
        self.leftNoteView = [[YKWLineNoteView alloc] init];
        self.topNoteView = [[YKWLineNoteView alloc] init];
        self.rightNoteView = [[YKWLineNoteView alloc] init];
        self.bottomNoteView = [[YKWLineNoteView alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRotation:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleRotation:(NSNotification *)notification {
    if (self.leftNoteView.superview) {
        self.width = self.superview.width;
        self.height = self.superview.height;
        
        [self didProbeView:self.probedView];
    }
}

- (void)showWithView:(UIView *)view {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.frame = CGRectMake(0, 0, window.bounds.size.width, window.bounds.size.height);
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [window addSubview:self];
    [window bringSubviewToFront:self];
    [window bringSubviewToFront:view];
    self.alpha = 0.0;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)probeSuperView {
    if (self.probedView.superview) {
        [self didProbeView:self.probedView.superview];
    }
}

- (void)updateNoteView {
    if (!_showFrames) {
        [self.leftNoteView removeFromSuperview];
        [self.topNoteView removeFromSuperview];
        [self.rightNoteView removeFromSuperview];
        [self.bottomNoteView removeFromSuperview];
        [self.frameViewAry makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.frameViewAry removeAllObjects];
        return;
    }
    UIView *frame1 = self.frameViewAry.lastObject;
    UIView *frame2 = [self.frameViewAry ykw_objectAtIndex:self.frameViewAry.count - 2];
    if (frame1) {
        [self addSubview:self.leftNoteView];
        [self addSubview:self.topNoteView];
        [self addSubview:self.rightNoteView];
        [self addSubview:self.bottomNoteView];
    } else {
        [self.leftNoteView removeFromSuperview];
        [self.topNoteView removeFromSuperview];
        [self.rightNoteView removeFromSuperview];
        [self.bottomNoteView removeFromSuperview];
    }
    
    CGFloat left = frame1.left;
    CGFloat top = frame1.top;
    CGFloat right = self.width - frame1.right;
    CGFloat bottom = self.height - frame1.bottom;

    if (frame2) {
        CGFloat delta1 = frame1.left;
        CGFloat delta2 = frame1.left - frame2.left;
        CGFloat delta3 = frame1.left - frame2.right;
        left = [self getMinimumPositive:delta1 and:delta2 and:delta3];
        
        delta1 = frame1.top;
        delta2 = frame1.top - frame2.bottom;
        delta3 = frame1.top - frame2.top;
        top = [self getMinimumPositive:delta1 and:delta2 and:delta3];
        
        delta1 = self.width - frame1.right;
        delta2 = frame2.right - frame1.right;
        delta3 = frame2.left - frame1.right;
        right = [self getMinimumPositive:delta1 and:delta2 and:delta3];

        delta1 = self.height - frame1.bottom;
        delta2 = frame2.bottom - frame1.bottom;
        delta3 = frame2.top - frame1.bottom;
        bottom = [self getMinimumPositive:delta1 and:delta2 and:delta3];
    }

    self.leftNoteView.width = left;
    self.leftNoteView.height = left - 1;
    self.leftNoteView.centerY = frame1.centerY;
    self.leftNoteView.right = frame1.left;
    self.leftNoteView.note = [NSString stringWithFormat:@"%.1f", left];
    
    self.topNoteView.height = top;
    self.topNoteView.width = top - 1;
    self.topNoteView.centerX = frame1.centerX;
    self.topNoteView.bottom = frame1.top;
    self.topNoteView.note = [NSString stringWithFormat:@"%.1f", top];

    self.rightNoteView.width = right;
    self.rightNoteView.height = right - 1;
    self.rightNoteView.centerY = frame1.centerY;
    self.rightNoteView.left = frame1.right;
    self.rightNoteView.note = [NSString stringWithFormat:@"%.1f", right];

    self.bottomNoteView.height = bottom;
    self.bottomNoteView.width = bottom - 1;
    self.bottomNoteView.centerX = frame1.centerX;
    self.bottomNoteView.top = frame1.bottom;
    self.bottomNoteView.note = [NSString stringWithFormat:@"%.1f", bottom];
}

- (CGFloat)getMinimumPositive:(CGFloat)num1 and:(CGFloat)num2 and:(CGFloat)num3 {
    CGFloat ret = MAX(num1, MAX(num2, num3));
    if (ret < 0) return 0;
    
    if (num2 > 0) {
        ret = MIN(ret, num2);
    }
    if (num3 > 0) {
        ret = MIN(ret, num3);
    }
    return ret;
}

- (void)hide {
    [self removeFromSuperview];
    [self.frameViewAry makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.frameViewAry removeAllObjects];
    [self.leftNoteView removeFromSuperview];
    [self.topNoteView removeFromSuperview];
    [self.rightNoteView removeFromSuperview];
    [self.bottomNoteView removeFromSuperview];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (event.allTouches.count > 2) {
        _resolveAllView = !_resolveAllView;
        [[NSUserDefaults standardUserDefaults] setBool:_resolveAllView forKey:kYKWProbeViewResolveAllView];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Picker mode changed")];
    }
    
    _toSkipView = nil;
    CGPoint point = [[touches anyObject] locationInView:self];
    if (_isDoubleTap) {
        [self handleDoubleTap:point];
    } else {
        UIView *view = [self resolveTopViewWithPoint:point];
        [self didProbeView:view];
    }
    
    _isDoubleTap = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->_isDoubleTap = NO;
    });
}

- (void)handleDoubleTap:(CGPoint)point {
    UIView *view = [self resolveTopViewWithPoint:point];
    if (view) {
        BOOL hidden = view.hidden;
        view.hidden = YES;
        _toSkipView = view;
        UIView *nextView = [self resolveTopViewWithPoint:point];
        view.hidden = hidden;
        _toSkipView = nil;
        if (nextView) {
            view = nextView;
        }
    }
    [self didProbeView:view];
}

- (void)didProbeView:(UIView *)view {
    if (!view) return;
    
    self.probedView = view;
    while (self.frameViewAry.count > 1) {
        [self.frameViewAry.firstObject removeFromSuperview];
        [self.frameViewAry removeObjectAtIndex:0];
    }
    UIView *first = self.frameViewAry.firstObject;
    if (first) {
        first.layer.borderColor = [UIColor colorWithHexString:@"fff400"].CGColor;
    }
    UIView *frameView = [[UIView alloc] init];
    frameView.frame = [view.superview convertRect:view.frame toView:nil];
    frameView.layer.borderColor = YKWHighlightColor.CGColor;
    frameView.layer.borderWidth = 2 / [UIScreen mainScreen].scale;
    [self.frameViewAry addObject:frameView];
    [self addSubview:frameView];
    
    [self updateNoteView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(probeView:didProbeView:)]) {
        [self.delegate probeView:self didProbeView:view];
    }
}

- (UIView *)resolveTopViewWithPoint:(CGPoint)point {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *view = nil;
    if (_resolveAllView) {
        view = [self getSubViewContainsPoint:point InView:window];
    } else {
        self.hidden = YES;
        UIView *hitView = [window hitTest:point withEvent:nil].superview;
        self.hidden = NO;
        CGPoint newP = [hitView convertPoint:point fromView:window];
        UIView *sub = [self getSubViewContainsPoint:newP InView:hitView];
        view = sub ?: hitView;
    }
    return view;
}

- (UIView *)getSubViewContainsPoint:(CGPoint)point InView:(UIView *)view {
    NSArray *subAry = view.subviews;
    for (NSInteger i = subAry.count - 1; i >= 0; i--) {
        UIView *sub = [subAry ykw_objectAtIndex:i];
        if (sub == _toSkipView || sub == self) continue;
        if (CGRectContainsPoint(sub.frame, point)) {
            CGPoint newP = [sub convertPoint:point fromView:view];
            UIView *subsub = [self getSubViewContainsPoint:newP InView:sub];
            if (subsub) {
                return subsub;
            } else {
                return sub;
            }
        }
    }
    return nil;
}

@end
