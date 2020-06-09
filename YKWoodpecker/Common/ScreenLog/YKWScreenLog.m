//
//  YKWScreenLog.m
//  YKWoodpecker
//
//  Created by Zim on 2018/11/23.
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

#import "YKWScreenLog.h"
#import "YKWoodpeckerMessage.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "YKWoodpeckerManager.h"
#import "YKWCmdView.h"
#import "YKWoodpeckerCommonHeaders.h"

#define kYKWScreenLogPreInputCache @"YKWScreenLogPreInputCache"
#define kYKWScreenLogRegExpression @"YKWScreenLogRegExpression"
#define kYKWScreenLogLastFrame @"YKWScreenLogLastFrame"
#define kYKWScreenLogPreInputCache @"YKWScreenLogPreInputCache"
#define kYKWScreenLogPreInputCacheCount 20

#define YKWScreenLogAutoPlainLength 6000
#define YKWScreenLogAutoHideLength 2000
#define YKWScreenLogAutoCleanLogLength 15000

@interface YKWScreenLog()<UITextViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, YKWCmdViewDelegate> {
    UITextView *_txtView;
    BOOL _isDeleting;
    NSMutableString *_allLogString;
    
    UIButton *_functionBtn;
    
    CGPoint _preLoc;
    UILabel *_sizeLabel;
    CGFloat _originalHeight;
    
    UILabel *_showHideLogLabel;

    UIView *_searchView;
    UITextField *_searchTxtField;
    UILabel *_searchResultNumLabel;
    UILabel *_searchNextLabel;
    NSArray *_searchResultAry;
    NSInteger _searchResultCurrentIndex;
    
    NSMutableArray *_appendedAry;
    
    NSMutableArray *_preInputAry;       // Input history
}

@end

@implementation YKWScreenLog

- (instancetype)initWithFrame:(CGRect)frame {
    if (CGRectIsEmpty(frame)) {
        NSString *rectStr = [[NSUserDefaults standardUserDefaults] objectForKey:kYKWScreenLogLastFrame];
        if (rectStr.length) {
            frame = CGRectFromString(rectStr);
        }
        CGRect intersectionRect = CGRectIntersection(frame, [UIApplication sharedApplication].keyWindow.bounds);
        if (frame.size.width < 300 || frame.size.height < 200 || intersectionRect.size.width  < 100 || intersectionRect.size.height  < 100) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                frame = CGRectMake([UIApplication sharedApplication].keyWindow.bounds.size.width / 4., 0, [UIApplication sharedApplication].keyWindow.bounds.size.width / 2., [UIApplication sharedApplication].keyWindow.bounds.size.height / 2. + 50.);
            } else {
                frame = CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height / 2. + 50.);
            }
        }
    }
    self = [super initWithFrame:frame];
    if (self) {
        _originalHeight = self.ykw_height;
        self.backgroundColor = [YKWBackgroudColor colorWithAlphaComponent:0.92];
        self.clipsToBounds = YES;
        self.followVelocity = 1.0;
        _resizeable = YES;
        _inputable = YES;
        _isDeleting = NO;
        _parseCommands = YES;
        _showLog = YES;
        
        _appendedAry = [NSMutableArray array];
        
        _regExpressionAry = [NSMutableArray array];
        _toFindStringAry = [NSMutableArray array];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kYKWScreenLogPreInputCache]) {
            _preInputAry = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kYKWScreenLogPreInputCache]];
        } else {
            _preInputAry = [NSMutableArray array];
        }
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selfTapped:)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
        
        _allLogString = [NSMutableString string];

        _txtView = [[UITextView alloc] init];
        _txtView.frame = CGRectMake(10, 20, self.ykw_width - 20, self.ykw_height - 70);
        _txtView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        _txtView.backgroundColor = [UIColor clearColor];
        _txtView.clipsToBounds = YES;
        _txtView.layer.cornerRadius = 1;
        _txtView.layer.borderColor = YKWForegroudColor.CGColor;
        _txtView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        _txtView.editable = _inputable;
        _txtView.showsVerticalScrollIndicator = YES;
        _txtView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _txtView.autocorrectionType = UITextAutocorrectionTypeNo;
        _txtView.font = [UIFont systemFontOfSize:12];
        _txtView.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5);
        _txtView.textColor = [UIColor whiteColor];
        _txtView.attributedText = [NSAttributedString new];
        _txtView.dataDetectorTypes = UIDataDetectorTypeNone;
        _txtView.delegate = self;
        [self addSubview:_txtView];

        CGFloat y = _txtView.ykw_bottom + 10;
        {
            UIButton *btn = [self getBtn];
            btn.frame = CGRectMake(10, y, 45, 30);
            [btn setTitle:YKWLocalizedString(@"Clear") forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(clearTxt) forControlEvents:UIControlEventTouchUpInside];
        }
        {
            UIButton *btn = [self getBtn];
            btn.frame = CGRectMake(65, y, 45, 30);
            [btn setTitle:YKWLocalizedString(@"Share") forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(shareTxt) forControlEvents:UIControlEventTouchUpInside];
        }
        {
            _functionBtn = [self getBtn];
            _functionBtn.frame = CGRectMake(120, y, 65, 30);
            [_functionBtn setTitle:YKWLocalizedString(@"Function") forState:UIControlStateNormal];
            [_functionBtn addTarget:self action:@selector(handleFunction) forControlEvents:UIControlEventTouchUpInside];
        }
        {
            UIButton *btn = [self getBtn];
            btn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
            btn.frame = CGRectMake(self.ykw_width - 40, y, 30, 30);
            btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:16];
            [btn setTitle:@"×" forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        }
        {
            UIButton *btn = [self getBtn];
            btn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
            btn.frame = CGRectMake(self.ykw_width - 80, y, 30, 30);
            btn.titleLabel.font = [UIFont systemFontOfSize:13.];
            [btn setTitle:@"🔍" forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(searchBtn) forControlEvents:UIControlEventTouchUpInside];
        }
        
        _sizeLabel = [[UILabel alloc] init];
        _sizeLabel.backgroundColor = YKWForegroudColor;
        _sizeLabel.frame = CGRectMake(self.ykw_width - 120, y, 30, 30);
        _sizeLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
        _sizeLabel.layer.cornerRadius = 2;
        _sizeLabel.clipsToBounds = YES;
        _sizeLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:12];
        _sizeLabel.textAlignment = NSTextAlignmentCenter;
        _sizeLabel.textColor = YKWBackgroudColor;
        _sizeLabel.text = @"◢";
        
        _sizeLabel.userInteractionEnabled = YES;
        [_sizeLabel addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSizeGesture:)]];
        self.panGestureRecognizer.delegate = self;
        [self addSubview:_sizeLabel];
        
        _showHideLogLabel = [[UILabel alloc] init];
        _showHideLogLabel.backgroundColor = YKWForegroudColor;
        _showHideLogLabel.frame = CGRectMake(self.ykw_width - 160, y, 30, 30);
        _showHideLogLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
        _showHideLogLabel.layer.cornerRadius = 2;
        _showHideLogLabel.clipsToBounds = YES;
        _showHideLogLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:18];
        _showHideLogLabel.textAlignment = NSTextAlignmentCenter;
        _showHideLogLabel.textColor = YKWBackgroudColor;
        _showHideLogLabel.text = _showLog ? @"◉" : @"○";

        _showHideLogLabel.userInteractionEnabled = YES;
        [_showHideLogLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleShowHideLogGesture:)]];
        [self addSubview:_showHideLogLabel];
    }
    return self;
}

- (UIButton *)getBtn {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = YKWForegroudColor;
    btn.layer.cornerRadius = 2;
    btn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    btn.titleLabel.font = [UIFont systemFontOfSize:12];
    [btn setTitleColor:YKWBackgroudColor forState:UIControlStateNormal];
    [self addSubview:btn];
    return btn;
}

#pragma mark - - Events
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if (gestureRecognizer.view == _sizeLabel) {
            return NO;
        }
        return YES;
    }
    
    CGPoint point = [gestureRecognizer locationInView:self];
    for (UIView *view in _appendedAry) {
        if (CGRectContainsPoint(view.frame, point)) {
            return NO;
        }
    }
    return YES;
}

- (void)selfTapped:(id)sender {
    if (_txtView.isFirstResponder) {
        [_txtView resignFirstResponder];
    }
    if (_searchTxtField.isFirstResponder) {
        [_searchTxtField resignFirstResponder];
    }
}

- (void)setInputable:(BOOL)inputable {
    _inputable = inputable;
    _txtView.editable = _inputable;
}

- (void)setResizeable:(BOOL)resizeable {
    _resizeable = resizeable;

    _sizeLabel.hidden = !_resizeable;
}

- (void)handleSizeGesture:(UIPanGestureRecognizer *)sender {
    CGPoint loc = [sender locationInView:self.superview];
    if (sender.state == UIGestureRecognizerStateBegan) {
        _preLoc = loc;
    }

    CGFloat width = self.ykw_width + (loc.x - _preLoc.x);
    if (width > 360) {
        self.ykw_width = width;
    }
    
    CGFloat height = self.ykw_height + (loc.y - _preLoc.y);
    if (height > 200) {
        self.ykw_height = height;
    }
    _preLoc = loc;
}

- (void)handleShowHideLogGesture:(UIPanGestureRecognizer *)sender {
    if (_showLog) {
        [self logInfo:YKWLocalizedString(@"<Hiding log, check log via share...>")];
        _showLog = NO;
    } else {
        _showLog = YES;
        [self logInfo:YKWLocalizedString(@"<Showing log...>")];
    }
    _showHideLogLabel.text = _showLog ? @"◉" : @"○";
}
    
- (NSString *)functionButtonTitle {
    return [_functionBtn titleForState:UIControlStateNormal];
}

- (void)setFunctionButtonTitle:(NSString *)functionButtonTitle {
    if (functionButtonTitle.length) {
        _functionBtn.hidden = NO;
        [_functionBtn setTitle:functionButtonTitle forState:UIControlStateNormal];
    } else {
        _functionBtn.hidden = YES;
    }
}

- (void)handleFunction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(screenLogDidTapFirstFunction:)]) {
        [self.delegate screenLogDidTapFirstFunction:self];
    }
}

- (void)shareTxt {
    NSString *string = _allLogString;
    if (string.length) {
        [YKWoodpeckerUtils showShareActivityWithItems:@[string]];
    } else {
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Empty")];
    }
}

- (void)clearTxt {
    _allLogString = [NSMutableString string];
    _txtView.text = @"";
    _txtView.attributedText = [NSAttributedString new];
    _searchResultAry = nil;
    [self updateSearchResultNumLabel];
}

#pragma mark - Functions
- (void)appendView:(UIView *)view {
    if (view) {
        self.autoresizesSubviews = NO;
        view.frame = CGRectMake(0, self.ykw_height, self.ykw_width, view.ykw_height);
        view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
        self.ykw_height += view.ykw_height;
        [self addSubview:view];
        [_appendedAry addObject:view];
        self.autoresizesSubviews = YES;
    }
}

- (void)show {
    self.alpha = 0.0;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self];
    }];
}

- (void)hide {
    if (_resizeable) {
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGRect(self.frame) forKey:kYKWScreenLogLastFrame];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    BOOL willClose = YES;
    if ([self.delegate respondsToSelector:@selector(screenLogWillClose:)]) {
        willClose = [self.delegate screenLogWillClose:self];
    }
    if (willClose) {
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            if (self->_searchView.superview) {
                [self->_searchView removeFromSuperview];
            }
        }];
    }
}

#pragma mark - Log
- (NSString *)logString {
    return _txtView.text;
}

- (NSString *)regFilterLog:(NSString *)logStr {
    NSMutableString *retStr = [NSMutableString string];
    for (NSString *regStr in _regExpressionAry) {
        NSError *error = nil;
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:regStr options:NSRegularExpressionCaseInsensitive error:&error];
        if (error) continue;
        NSArray *mAry = [regex matchesInString:logStr options:0 range:NSMakeRange(0, logStr.length)];
        if (mAry.count) {
            for (int i = 0; i < mAry.count; i++) {
                NSTextCheckingResult *result = mAry[i];
                [retStr appendFormat:@"\n%@", [logStr substringWithRange:result.range]];
            }
        }
    }
    if (retStr.length) {
        return [NSString stringWithFormat:@"\n%@:%@", YKWLocalizedString(@"Reg Matches"), retStr];
    }
    return YKWLocalizedString(@"<No reg matches>");
}

- (NSString *)findFilterLog:(NSString *)logStr {
    for (NSString *findStr in _toFindStringAry) {
        if ([logStr rangeOfString:findStr].location == NSNotFound) {
            return YKWLocalizedString(@"<No to-find string matches>");
        }
    }
    return logStr;
}

- (void)log:(NSString *)logStr {
    [self log:logStr color:nil keepLine:NO checkReg:NO checkFind:NO];
}

- (void)logInfo:(NSString *)logStr {
    [self log:logStr color:YKWINFOCOLOR keepLine:NO checkReg:NO checkFind:NO];
}

- (void)log:(NSString *)logStr color:(UIColor *)color keepLine:(BOOL)keepline checkReg:(BOOL)checkReg checkFind:(BOOL)checkFind {
    if (!logStr) {
        return;
    }
    
    if (checkFind && _toFindStringAry.count) {
        logStr = [self findFilterLog:logStr];
    }
    
    if (checkReg && _regExpressionAry.count) {
        logStr = [self regFilterLog:logStr];
    }
    
    [_allLogString appendString:logStr];
    
    if (logStr.length > YKWScreenLogAutoHideLength) {
        logStr = YKWLocalizedString(@"<Log is too long to show, check it via share>");
    }
    
    if (!color) {
        color = [UIColor whiteColor];
    }
    
    if (!keepline) {
        logStr = [logStr stringByAppendingString:@"\n"];
        [_allLogString appendString:@"\n"];
    }
    
    if (!_showLog) {
        return;
    }
    
    if (_txtView.text.length > YKWScreenLogAutoCleanLogLength) {
        _txtView.text = nil;
        _txtView.attributedText = nil;
    }
    
    BOOL autoScrl = NO;
    if (_txtView.contentSize.height < _txtView.ykw_height || _txtView.contentSize.height - _txtView.ykw_height - _txtView.contentOffset.y < 50) {
        autoScrl = YES;
    }
    
    if (logStr.length > YKWScreenLogAutoPlainLength || _txtView.text.length > YKWScreenLogAutoPlainLength) {
        if (_txtView.textColor != UIColor.whiteColor) {
            _txtView.textColor = UIColor.whiteColor;
        }
        _txtView.text = [_txtView.text stringByAppendingString:logStr];
    } else {
        NSAttributedString* logString = [[NSAttributedString alloc] initWithString:logStr attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12], NSForegroundColorAttributeName : color}];
        NSMutableAttributedString *mLog = [[NSMutableAttributedString alloc] initWithAttributedString:_txtView.attributedText];
        [mLog appendAttributedString:logString];
        _txtView.attributedText = mLog;
    }
    
    if (autoScrl && _txtView.contentSize.height > _txtView.ykw_height) {
        [_txtView setContentOffset:CGPointMake(0, _txtView.contentSize.height - _txtView.ykw_height) animated:YES];
    }
    
    [self searchLogWithKey:nil];
}

- (NSString *)getTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:@"MM/dd HH:mm:ss.SSS:"];
    return [formatter stringFromDate:[NSDate date]];
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    _isDeleting = range.length > 0;
    if (range.length > 0 && range.location < _txtView.text.length &&
        [textView.text rangeOfString:@"\n" options:0 range:NSMakeRange(range.location, textView.text.length - range.location)].location != NSNotFound) {
        return NO;
    }
    if ([text isEqualToString:@"\n"]) {
        [self log:@""];
        [self stripInputString];
        return NO;
    }
    return YES;
}

- (void)stripInputString {
    if ([_txtView.text hasSuffix:@"\n"] && !_isDeleting) {
        NSInteger index = _txtView.text.length - 1;
        NSString *inputStr = nil;
        while (index > 0) {
            index--;
            inputStr = [_txtView.text substringWithRange:NSMakeRange(index, _txtView.text.length - index - 1)];
            if ([inputStr hasPrefix:@"\n"]) {
                break;
            }
        }
        inputStr = [inputStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        if (inputStr.length) {
            if (self.parseCommands && [self parseCommandString:inputStr]) {
                return;
            }
            if ([self.delegate respondsToSelector:@selector(screenLog:didInput:)]) {
                [self.delegate screenLog:self didInput:inputStr];
            }
        }
    }
}

- (BOOL)parseCommandString:(NSString *)cmdStr {
    NSArray *components = [cmdStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];

    // History
    if (components.count == 1 && ([components.firstObject isEqualToString:@"h"] || [components.firstObject isEqualToString:@"H"])) {
        [self printInputHistory];
        return YES;
    } else if (components.count == 1 && [self isPureNum:components.firstObject]) {
        if (0 < [components.firstObject intValue] && [components.firstObject intValue] <= _preInputAry.count) {
            [self log:[_preInputAry ykw_objectAtIndex:cmdStr.intValue - 1] color:nil keepLine:YES checkReg:NO checkFind:NO];
        } else {
            [self logInfo:YKWLocalizedString(@"No history")];
        }
        return YES;
    } else if ([cmdStr hasPrefix:@"r"] || [cmdStr hasPrefix:@"R"]) { // r command
        if (components.count == 1 && [components.firstObject length] == 1) {
            if ([components.firstObject length] == 1) {
                [self printRegExpression];
            } else {
                [self logInfo:YKWLocalizedString(@"Unrecognized command")];
            }
            return YES;
        }
        
        cmdStr = [cmdStr substringFromIndex:2];
        while ([cmdStr hasPrefix:@" "]) {
            cmdStr = [cmdStr substringFromIndex:1];
        }
        if (cmdStr.length > 0) {
            if ([cmdStr isEqualToString:@"clr"]) {
                [self clearRegExpression];
            } else {
                [self addRegExpression:cmdStr];
            }
        } else {
            [self logInfo:YKWLocalizedString(@"Input format error")];
        }
        return YES;
    } else if ([cmdStr hasPrefix:@"f"] || [cmdStr hasPrefix:@"F"]) { // f command
        if (components.count == 1 && [components.firstObject length] == 1) {
            if ([components.firstObject length] == 1) {
                [self printToFindString];
            } else {
                [self logInfo:YKWLocalizedString(@"Unrecognized command")];
            }
            return YES;
        }
        
        cmdStr = [cmdStr substringFromIndex:2];
        while ([cmdStr hasPrefix:@" "]) {
            cmdStr = [cmdStr substringFromIndex:1];
        }
        if (cmdStr.length > 0) {
            if ([cmdStr isEqualToString:@"clr"]) {
                [self clearToFindString];
            } else {
                [self addToFindString:cmdStr];
            }
        } else {
            [self logInfo:YKWLocalizedString(@"Input format error")];
        }
        return YES;
    }
    return NO;
}

#pragma mark - Regular expression
- (void)addRegExpression:(NSString *)regStr {
    [self.regExpressionAry addObject:regStr];
    [self logInfo:YKWLocalizedString(@"Reg: Reg has been added")];
}

- (void)clearRegExpression {
    [self.regExpressionAry removeAllObjects];
    [self logInfo:YKWLocalizedString(@"Reg: All regs have been removed")];
}

- (void)printRegExpression {
    if (_regExpressionAry.count > 0) {
        for (int i = 1; i <= _regExpressionAry.count; i++) {
            [self logInfo:[_regExpressionAry ykw_objectAtIndex:i - 1]];
        }
    } else {
        [self logInfo:YKWLocalizedString(@"<No regs>")];
    }
    [self logInfo:@""];
}

#pragma mark - To-find string
- (void)addToFindString:(NSString *)findStr {
    [self.toFindStringAry addObject:findStr];
    [self logInfo:YKWLocalizedString(@"To-find: To-find string has been added")];
}

- (void)clearToFindString {
    [self.toFindStringAry removeAllObjects];
    [self logInfo:YKWLocalizedString(@"To-find: All to-find string have been removed")];
}

- (void)printToFindString {
    if (_toFindStringAry.count > 0) {
        for (int i = 1; i <= _toFindStringAry.count; i++) {
            [self logInfo:[_toFindStringAry ykw_objectAtIndex:i - 1]];
        }
    } else {
        [self logInfo:YKWLocalizedString(@"<No to-find strings>")];
    }
    [self logInfo:@""];
}

#pragma mark - History
- (void)printInputHistory {
    if (_preInputAry.count > 0) {
        [self logInfo:YKWLocalizedString(@"<Input the number to input the corresponding command>")];
        for (int i = 1; i <= _preInputAry.count && i <= 10; i++) {
            [self logInfo:[NSString stringWithFormat:@"%d:%@", i, [_preInputAry ykw_objectAtIndex:i - 1]]];
        }
    } else {
        [self logInfo:YKWLocalizedString(@"<No input history>")];
    }
    [self logInfo:@""];
}

- (void)saveInputToHistory:(NSString *)input {
    if (input.length > 1 && ![_preInputAry.firstObject isEqualToString:input]) {
        [_preInputAry insertObject:input atIndex:0];
        while (_preInputAry.count > kYKWScreenLogPreInputCacheCount) {
            [_preInputAry removeLastObject];
        }
        [[NSUserDefaults standardUserDefaults] setObject:_preInputAry forKey:kYKWScreenLogPreInputCache];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (BOOL)isPureNum:(NSString *)str{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"([0-9]+)"];
    return [predicate evaluateWithObject:str];
}

#pragma mark - Search

- (void)searchBtn {
    if (_searchView.superview) {
        [_searchView removeFromSuperview];
        return;
    }
    if (!_searchView) {
        [self setupSearchView];
    }
    
    _searchView.frame = CGRectMake(_txtView.ykw_left, _txtView.ykw_top, _txtView.ykw_width, 26);
    _searchView.alpha = 0.0;
    [self addSubview:_searchView];
    [UIView animateWithDuration:0.2 animations:^{
        self->_searchView.alpha = 1.;
    } completion:^(BOOL finished) {
        [self->_searchTxtField becomeFirstResponder];
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *searchSeed = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self searchLogWithKey:searchSeed];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self showNextSearchResult];
    return NO;
}

- (void)searchLogWithKey:(NSString *)key {
    if (!key.length) {
        if (_searchTxtField.superview && _searchTxtField.text.length) {
            key = _searchTxtField.text;
        } else {
            return;
        }
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:key options:NSRegularExpressionCaseInsensitive error:nil];
    _searchResultAry = [regex matchesInString:self.logString options:NSMatchingReportCompletion range:NSMakeRange(0, self.logString.length)];
    
    _searchResultCurrentIndex = 0;
    NSRange visibleRange = [self visibleRangeOfTextView:_txtView];
    for (NSTextCheckingResult *result in _searchResultAry) {
        if (NSLocationInRange(result.range.location, visibleRange)) {
            break;
        }
        _searchResultCurrentIndex++;
    }
    [self showNextSearchResult];
}

- (void)searchNextTapped:(UITapGestureRecognizer *)sender {
    CGPoint p = [sender locationInView:sender.view];
    if (p.x < sender.view.ykw_width / 2) {
        [self showPreviousSearchResult];
    } else {
        [self showNextSearchResult];
    }
}

- (void)showPreviousSearchResult {
    if (!_searchResultAry.count) {
        [self updateSearchResultNumLabel];
        return;
    }
    
    _searchResultCurrentIndex--;
    if (_searchResultCurrentIndex < 1) {
        _searchResultCurrentIndex = _searchResultAry.count;
    }
    NSTextCheckingResult *result = [_searchResultAry ykw_objectAtIndex:_searchResultCurrentIndex - 1];
    [self showResult:result];
}

- (void)showNextSearchResult {
    if (!_searchResultAry.count) {
        [self updateSearchResultNumLabel];
        return;
    }
    
    _searchResultCurrentIndex++;
    if (_searchResultCurrentIndex > _searchResultAry.count) {
        _searchResultCurrentIndex = 1;
    }
    NSTextCheckingResult *result = [_searchResultAry ykw_objectAtIndex:_searchResultCurrentIndex - 1];
    [self showResult:result];
}

- (void)showResult:(NSTextCheckingResult *)result {
    NSRange visibleRange = [self visibleRangeOfTextView:_txtView];
    if (visibleRange.location > result.range.location) {
        if (result.range.location > 160) {
            [_txtView scrollRangeToVisible:NSMakeRange(result.range.location - 150, 1)];
        } else {
            [_txtView scrollRangeToVisible:result.range];
        }
    } else {
        if (result.range.location + 160 < self.logString.length) {
            [_txtView scrollRangeToVisible:NSMakeRange(result.range.location + 150, 1)];
        } else {
            [_txtView scrollRangeToVisible:result.range];
        }
    }
    [_txtView setSelectedRange:result.range];
    [self updateSearchResultNumLabel];
    
    CGRect frame = [self frameOfTextRange:result.range inTextView:_txtView];
    UIView *highlightView = [[UIView alloc] initWithFrame:frame];
    highlightView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
    [_txtView addSubview:highlightView];
    [highlightView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:2];
}

- (void)updateSearchResultNumLabel {
    if (_searchResultAry.count) {
        _searchResultNumLabel.text = [NSString stringWithFormat:@"%ld/%lu", (long)_searchResultCurrentIndex, (unsigned long)_searchResultAry.count];
    } else {
        _searchResultNumLabel.text = @"0/0";
    }
    [_searchResultNumLabel sizeToFit];
    _searchResultNumLabel.ykw_width += 5;
}

- (NSRange)visibleRangeOfTextView:(UITextView *)textView {
    CGRect bounds = textView.bounds;
    UITextPosition *start = [textView characterRangeAtPoint:bounds.origin].start;
    UITextPosition *end = [textView characterRangeAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))].end;
    return NSMakeRange([textView offsetFromPosition:textView.beginningOfDocument toPosition:start],
                       [textView offsetFromPosition:start toPosition:end]);
}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return [textView convertRect:rect fromView:textView.textInputView];
}

- (void)setupSearchView {
    if (!_searchView) {
        _searchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _txtView.ykw_width, 26)];
        _searchView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
        _searchView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        
        _searchTxtField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, _searchView.ykw_width - 60, _searchView.ykw_height)];
        _searchTxtField.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _searchTxtField.backgroundColor = [UIColor clearColor];
        _searchTxtField.textColor = [UIColor whiteColor];
        _searchTxtField.layer.borderWidth = 1. / [UIScreen mainScreen].scale;
        _searchTxtField.layer.borderColor = YKWHighlightColor.CGColor;
        _searchTxtField.clearButtonMode = UITextFieldViewModeAlways;
        _searchTxtField.font = [UIFont systemFontOfSize:14];
        _searchTxtField.delegate = self;
        [_searchView addSubview:_searchTxtField];
        
        _searchResultNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, _searchView.ykw_height)];
        _searchResultNumLabel.textColor = [UIColor whiteColor];
        _searchResultNumLabel.font = [UIFont systemFontOfSize:12];
        _searchResultNumLabel.textAlignment = NSTextAlignmentCenter;
        _searchTxtField.rightView = _searchResultNumLabel;
        _searchTxtField.rightViewMode = UITextFieldViewModeAlways;
        _searchResultNumLabel.text = @"0/0";
        
        _searchNextLabel = [[UILabel alloc] initWithFrame:CGRectMake(_searchView.ykw_width - 60, 0, 60, _searchView.ykw_height)];
        _searchNextLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight;
        _searchNextLabel.textColor = [UIColor whiteColor];
        _searchNextLabel.font = [UIFont systemFontOfSize:12];
        _searchNextLabel.textAlignment = NSTextAlignmentCenter;
        _searchNextLabel.text = @"◀  |  ▶";
        _searchNextLabel.userInteractionEnabled = YES;
        [_searchNextLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(searchNextTapped:)]];
        [_searchView addSubview:_searchNextLabel];
    }
}

@end
