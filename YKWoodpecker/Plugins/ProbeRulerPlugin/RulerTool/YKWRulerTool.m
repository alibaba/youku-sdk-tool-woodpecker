//
//  YKWRulerTool.m
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

#import "YKWRulerTool.h"
#import <sys/utsname.h>
#import "YKWoodpeckerMessage.h"
#import "YKWRulerView.h"

#define kYKWRulerToolIsDp @"YKWRulerToolIsDp"
#define kYKWRulerToolLastFrame @"YKWRulerToolLastFrame"

typedef NS_ENUM(NSUInteger, YKWRulerToolControlType) {
    YKWRulerToolControlTypeNone            = 0,
    YKWRulerToolControlTypeAddX            = 1,
    YKWRulerToolControlTypeAddY            = 2,
    YKWRulerToolControlTypeMinusX          = 3,
    YKWRulerToolControlTypeMinusY          = 4,
    YKWRulerToolControlTypeAddWidth        = 5,
    YKWRulerToolControlTypeAddHeight       = 6,
    YKWRulerToolControlTypeMinusWidth      = 7,
    YKWRulerToolControlTypeMinusHeight     = 8,
};

@interface YKWRulerTool()<UITextFieldDelegate> {
    NSUInteger _currentIndex;
    
    UIButton *_DpPxBtn;
    
    BOOL _isDp;
    UITextField *_sizeTxtField;
    
    NSTimer *_longPressTriggerTimer;
    YKWRulerToolControlType _controlType;
}

@property (nonatomic, strong) NSMutableArray *rulerViewAry;

@end

@implementation YKWRulerTool

- (instancetype)initWithFrame:(CGRect)frame {
    frame.size.width = 190.0;
    frame.size.height = 220.0;
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.rulerViewAry = [NSMutableArray array];
        _currentIndex = 0;
        
        _isDp = YES;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kYKWRulerToolIsDp]) {
            _isDp = [([[NSUserDefaults standardUserDefaults] objectForKey:kYKWRulerToolIsDp]) boolValue];
        }
        
        _longPressTriggerTimer = nil;
        _controlType = YKWRulerToolControlTypeNone;
        
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        
        UILabel *_infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, frame.size.width, 25)];
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.textColor = YKWForegroudColor;
        _infoLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:12];
        _infoLabel.text = [NSString stringWithFormat:@"%@   %.0f %@", platform, [UIScreen mainScreen].scale, YKWLocalizedString(@"scale")];
        [self addSubview:_infoLabel];
        
        UIButton *_addBtn = ({
            UIButton *btn = [self getABtn];
            btn.frame = CGRectMake(10, _infoLabel.ykw_bottom + 5, 80, 30);
            btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:20];
            [btn setTitle:@"＋" forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(addRulerView) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            btn;
        });
        
        _DpPxBtn = ({
            UIButton *btn = [self getABtn];
            btn.tag = 1;
            btn.frame = CGRectMake(100, _addBtn.ykw_top, 80, 30);
            btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:14];
            [btn setTitle:(_isDp ? @"Dp" : @"Px") forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(switchDpPx) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            btn;
        });
        
        _sizeTxtField = [[UITextField alloc] initWithFrame:CGRectMake(10, _addBtn.ykw_bottom + 10, frame.size.width - 20, 30)];
        _sizeTxtField.backgroundColor = YKWBackgroudColor;
        _sizeTxtField.textColor = YKWForegroudColor;
        _sizeTxtField.textAlignment = NSTextAlignmentCenter;
        _sizeTxtField.borderStyle = UITextBorderStyleNone;
        _sizeTxtField.layer.borderColor = YKWForegroudColor.CGColor;
        _sizeTxtField.layer.borderWidth = 0.5;
        _sizeTxtField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        _sizeTxtField.returnKeyType = UIReturnKeyDone;
        _sizeTxtField.autocorrectionType = UITextAutocorrectionTypeNo;
        _sizeTxtField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _sizeTxtField.delegate = self;
        [self addSubview:_sizeTxtField];
        
        {
            UILabel *label = [self getAControlLabel];
            label.tag = YKWRulerToolControlTypeAddX;
            label.center = CGPointMake(self.ykw_width / 4 + 25, _sizeTxtField.ykw_bottom + 55);
            label.text = @"▷";
        }
        
        {
            UILabel *label = [self getAControlLabel];
            label.tag = YKWRulerToolControlTypeAddY;
            label.center = CGPointMake(self.ykw_width / 4, _sizeTxtField.ykw_bottom + 80);
            label.text = @"▷";
            label.transform = CGAffineTransformMakeRotation(M_PI_2);
        }

        {
            UILabel *label = [self getAControlLabel];
            label.tag = YKWRulerToolControlTypeMinusX;
            label.center = CGPointMake(self.ykw_width / 4 - 25, _sizeTxtField.ykw_bottom + 55);
            label.text = @"▷";
            label.transform = CGAffineTransformMakeRotation(M_PI);
        }

        {
            UILabel *label = [self getAControlLabel];
            label.tag = YKWRulerToolControlTypeMinusY;
            label.center = CGPointMake(self.ykw_width / 4, _sizeTxtField.ykw_bottom + 30);
            label.text = @"▷";
            label.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }
        
        {
            UILabel *label = [self getAControlLabel];
            label.tag = YKWRulerToolControlTypeAddWidth;
            label.center = CGPointMake(self.ykw_width * 3 / 4 - 25, _sizeTxtField.ykw_bottom + 30);
            label.text = @"◁▷";
        }
        
        {
            UILabel *label = [self getAControlLabel];
            label.tag = YKWRulerToolControlTypeMinusWidth;
            label.center = CGPointMake(self.ykw_width * 3 / 4 + 25, _sizeTxtField.ykw_bottom + 30);
            label.text = @"▷◁";
        }

        {
            UILabel *label = [self getAControlLabel];
            label.tag = YKWRulerToolControlTypeAddHeight;
            label.center = CGPointMake(self.ykw_width * 3 / 4 - 25, _sizeTxtField.ykw_bottom + 80);
            label.text = @"◁▷";
            label.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        
        {
            UILabel *label = [self getAControlLabel];
            label.tag = YKWRulerToolControlTypeMinusHeight;
            label.center = CGPointMake(self.ykw_width * 3 / 4 + 25, _sizeTxtField.ykw_bottom + 80);
            label.text = @"▷◁";
            label.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
    }
    return self;
}

- (UIButton *)getABtn {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [YKWBackgroudColor colorWithAlphaComponent:0.6];
    btn.clipsToBounds = YES;
    btn.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    btn.layer.borderColor = YKWForegroudColor.CGColor;
    btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:15];
    [btn setTitleColor:YKWForegroudColor forState:UIControlStateNormal];
    [self addSubview:btn];
    return btn;
}

- (UILabel *)getAControlLabel {
    UILabel *label = [UILabel new];
    label.frame = CGRectMake(0, 0, 40, 40);
    label.backgroundColor = [UIColor clearColor];
    label.userInteractionEnabled = YES;
    label.clipsToBounds = YES;
    label.layer.cornerRadius = label.ykw_width / 2.0;
    label.layer.borderWidth = 0.5;
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.borderColor = YKWForegroudColor.CGColor;
    label.font = [UIFont boldSystemFontOfSize:15];
    label.textColor = [UIColor whiteColor];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureRecognizer:)];
    [label addGestureRecognizer:tapGes];
    UILongPressGestureRecognizer *longGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureRecognizer:)];
    longGes.minimumPressDuration = 0.2;
    [label addGestureRecognizer:longGes];
    
    [self addSubview:label];
    return label;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSMutableArray *txts = [[textField.text componentsSeparatedByString:@" "] mutableCopy];
    [txts filterUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
    if (txts.count == 2) {
        CGFloat scale = _isDp ? 1 : [UIScreen mainScreen].scale;
        CGFloat width = [txts.firstObject floatValue] / scale;
        CGFloat height = [txts.lastObject floatValue] / scale;
        if (width > 0 && width < 5000 * scale && height > 0 && height < 5000 * scale) {
            YKWRulerView *view = [self.rulerViewAry ykw_objectAtIndex:_currentIndex];
            if (!view) {
                view = self.rulerViewAry.lastObject;
            }
            view.ykw_width = width;
            view.ykw_height = height;
            [textField resignFirstResponder];
        } else {
            [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Input Error")];
        }
    }
    return YES;
}

#pragma mark - Functions
- (void)addRulerView {
    YKWRulerView *view = [[YKWRulerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    view.center = [UIApplication sharedApplication].keyWindow.center;
    if (!CGRectIsEmpty([[self.rulerViewAry ykw_objectAtIndex:_currentIndex] frame])) {
        view.frame = [[self.rulerViewAry ykw_objectAtIndex:_currentIndex] frame];
        view.ykw_centerX += 10;
        view.ykw_centerY += 10;
    } else {
        NSString *rectStr = [[NSUserDefaults standardUserDefaults] objectForKey:kYKWRulerToolLastFrame];
        CGRect lastRect = CGRectFromString(rectStr);
        CGRect intersectionRect = CGRectIntersection(lastRect, [UIApplication sharedApplication].keyWindow.bounds);
        if (intersectionRect.size.width > 1 && intersectionRect.size.height > 1) {
            view.frame = CGRectFromString(rectStr);
        }
    }
    
    CGRect intersectionRect = CGRectIntersection(view.frame, [UIApplication sharedApplication].keyWindow.bounds);
    if (CGRectIsEmpty(intersectionRect)) {
        view.frame = CGRectMake([UIApplication sharedApplication].keyWindow.ykw_centerX, [UIApplication sharedApplication].keyWindow.ykw_centerY, 100, 100);
    }
    
    [self.rulerViewAry addObject:view];
    _currentIndex = self.rulerViewAry.count - 1;
    [[UIApplication sharedApplication].keyWindow addSubview:view];
    
    UITapGestureRecognizer *singleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectRulerView:)];
    [view addGestureRecognizer:singleTapGes];
    
    UITapGestureRecognizer *doubleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeRulerView:)];
    doubleTapGes.numberOfTapsRequired = 2;
    [view addGestureRecognizer:doubleTapGes];
    [singleTapGes requireGestureRecognizerToFail:doubleTapGes];

    [self updateRulerInfoWithView:view];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kYKWRulerToolIsDp]) {
        [[NSUserDefaults standardUserDefaults] setObject:@(_isDp) forKey:kYKWRulerToolIsDp];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Remove with a double-tap") duration:5.];
    }
}

- (void)selectRulerView:(UITapGestureRecognizer *)sender {
    _currentIndex = [self.rulerViewAry indexOfObject:sender.view];
    UIView *view = [self.rulerViewAry ykw_objectAtIndex:_currentIndex];
    if (view) {
        [self updateRulerInfoWithView:view];

        [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            view.transform = CGAffineTransformMakeScale(1.1, 1.1);
        } completion:nil];
        [UIView animateWithDuration:0.15 delay:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
            view.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)removeRulerView:(UITapGestureRecognizer *)sender {
    [self.rulerViewAry removeObject:sender.view];
    [sender.view removeFromSuperview];
    
    if (self.rulerViewAry.count) {
        _currentIndex = self.rulerViewAry.count - 1;
        [self updateRulerInfoWithView:self.rulerViewAry.lastObject];
    }
}

- (void)configTriggerTimer {
    [self invalidateTimer];
    _longPressTriggerTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_longPressTriggerTimer forMode:NSRunLoopCommonModes];
}

- (void)invalidateTimer {
    if (_longPressTriggerTimer) {
        [_longPressTriggerTimer invalidate];
        _longPressTriggerTimer = nil;
    }
}

- (void)handleGestureRecognizer:(UIGestureRecognizer *)sender {
    if ([sender isKindOfClass:[UILongPressGestureRecognizer class]]) {
        UILongPressGestureRecognizer *longGes = (UILongPressGestureRecognizer *)sender;
        if (longGes.state == UIGestureRecognizerStateBegan) {
            _controlType = sender.view.tag;
            [self configTriggerTimer];
        }
        if (longGes.state == UIGestureRecognizerStateEnded) {
            _controlType = YKWRulerToolControlTypeNone;
            [self invalidateTimer];
        }
    } else {
        _controlType = sender.view.tag;
        [self step:1];
        _controlType = YKWRulerToolControlTypeNone;
    }
}

- (void)onTimer {
    [self step:5];
}

- (void)step:(CGFloat)multiple {
    CGFloat step = 1 / (_isDp ? 1 : [UIScreen mainScreen].scale) * multiple;
    YKWRulerView *view = [self.rulerViewAry ykw_objectAtIndex:_currentIndex];
    if (!view) {
        view = self.rulerViewAry.lastObject;
    }
    switch (_controlType) {
        case YKWRulerToolControlTypeAddX:
            view.ykw_left += step;
            if (!CGRectIntersectsRect(view.superview.bounds, view.frame)) {
                view.ykw_left -= step;
            }
            break;
        case YKWRulerToolControlTypeAddY:
            view.ykw_top += step;
            if (!CGRectIntersectsRect(view.superview.bounds, view.frame)) {
                view.ykw_top -= step;
            }
            break;
        case YKWRulerToolControlTypeMinusX:
            view.ykw_left -= step;
            if (!CGRectIntersectsRect(view.superview.bounds, view.frame)) {
                view.ykw_left += step;
            }
            break;
        case YKWRulerToolControlTypeMinusY:
            view.ykw_top -= step;
            if (!CGRectIntersectsRect(view.superview.bounds, view.frame)) {
                view.ykw_top += step;
            }
            break;
        case YKWRulerToolControlTypeMinusWidth:
            if (view.ykw_width - step <= 0) {
                view.ykw_width = step;
            } else {
                view.ykw_width -= step;
            }
            break;
        case YKWRulerToolControlTypeMinusHeight:
            if (view.ykw_height - step <= 0) {
                view.ykw_height = step;
            } else {
                view.ykw_height -= step;
            }
            break;
        case YKWRulerToolControlTypeAddWidth:
            view.ykw_width += step;
            break;
        case YKWRulerToolControlTypeAddHeight:
            view.ykw_height += step;
            break;
        default:
            break;
    }
    [self updateRulerInfoWithView:view];
}

- (void)switchDpPx {
    _isDp = !_isDp;
    [_DpPxBtn setTitle:(_isDp ? @"Dp" : @"Px") forState:UIControlStateNormal];
    YKWRulerView *view = [self.rulerViewAry ykw_objectAtIndex:_currentIndex];
    if (!view) {
        view = self.rulerViewAry.lastObject;
    }
    [self updateRulerInfoWithView:view];
}

- (void)updateRulerInfoWithView:(UIView *)view {
    CGFloat scale = _isDp ? 1 : [UIScreen mainScreen].scale;
    _sizeTxtField.text = [NSString stringWithFormat:@"%.1f %.1f", view.frame.size.width * scale, view.frame.size.height * scale];
}

- (void)showInView:(UIView *)view {
    self.ykw_centerX = view.ykw_width / 2;
    [view addSubview:self];
    [self addRulerView];
}

- (void)hide {
    if (!CGRectIsEmpty([self.rulerViewAry.lastObject frame])) {
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGRect([self.rulerViewAry.lastObject frame]) forKey:kYKWRulerToolLastFrame];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.rulerViewAry makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.rulerViewAry removeAllObjects];
    }];
}

@end
