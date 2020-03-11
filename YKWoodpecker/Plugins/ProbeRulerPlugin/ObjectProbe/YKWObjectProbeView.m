//
//  YKWObjectProbeView.m
//  YKWoodpecker
//
//  Created by Zim on 2018/11/22.
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

#import "YKWObjectProbeView.h"
#import "YKWObjectTableView.h"
#import "YKWoodpeckerMessage.h"
#import "YKWImageTextPreview.h"
#import "YKWPoCommandCore.h"
#import "YKWScreenLog.h"
#import <objc/runtime.h>

@interface YKWObjectProbeView()<YKWObjectTableViewDelegate, YKWScreenLogDelegate> {
    YKWScreenLog *_logView;
    YKWPoCommandCore *_poCmdCore;
    
    UIScrollView *_probeTableScrollView;
    NSMutableArray *_probeTableAry;
}

@end

@implementation YKWObjectProbeView

- (instancetype)initWithFrame:(CGRect)frame {
    frame = CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height);
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = YKWBackgroudColor;
        self.clipsToBounds = YES;
        self.followVelocity = 0.0;
        
        _logView = [[YKWScreenLog alloc] initWithFrame:CGRectMake(0, 0, self.ykw_width, self.ykw_height / 2 + 30)];
        _logView.followVelocity = 0;
        _logView.resizeable = NO;
        _logView.functionButtonTitle = YKWLocalizedString(@"Show View");
        _logView.delegate = self;
        [self addSubview:_logView];
        
        [_logView logInfo:YKWLocalizedString(@"<Tap an object to show its property list, double-tap to show description, or input as 'k/K Key.Path' to read KVC, input 'po [1/2.../class ...]' to run po-command, input 'h' to show input history.>")];
        
        _poCmdCore = [[YKWPoCommandCore alloc] init];

        _probeTableScrollView = [[UIScrollView alloc] init];
        _probeTableScrollView.frame = CGRectMake(10, _logView.ykw_bottom, _logView.ykw_width - 20, self.ykw_height - _logView.ykw_bottom - 10);
        _probeTableScrollView.backgroundColor = [YKWHighlightColor colorWithAlphaComponent:0.3];
        _probeTableScrollView.directionalLockEnabled = YES;
        [self addSubview:_probeTableScrollView];
        
        _probeTableAry = [NSMutableArray array];
    }
    return self;
}

- (void)show {
    self.alpha = 0.0;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    }];
    
    [[YKWoodpeckerManager sharedInstance] hide];
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
    [[YKWoodpeckerManager sharedInstance] show];
}

- (void)setEntranceObject:(NSObject *)entranceObject {
    if (_entranceObject) {
        return;
    }
    _entranceObject = entranceObject;

    [_probeTableAry makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_probeTableAry removeAllObjects];
    _probeTableScrollView.contentSize = CGSizeZero;
    _probeTableScrollView.contentOffset = CGPointZero;

    if (_entranceObject) {
        [self setupTableViewWith:_entranceObject class:nil];
    }
}

#pragma mark - YKWScreenLogDelegate
- (BOOL)screenLogWillClose:(YKWScreenLog *)log {
    [self hide];
    return NO;
}

- (void)screenLogDidTapFirstFunction:(YKWScreenLog *)log {
    YKWObjectTableView *tableView = _probeTableAry.lastObject;
    UIView *view = nil;
    if ([tableView.probedObject isKindOfClass:[UIView class]]) {
        view = (UIView *)tableView.probedObject;
    } else if ([tableView.probedObject isKindOfClass:[UIViewController class]]) {
        view = [(UIViewController *)tableView.probedObject view];
    }
    if (view) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(objectProbeView:wantsToShowView:)]) {
            [self.delegate objectProbeView:self wantsToShowView:view];
            [self hide];
        }
    } else {
        [_logView logInfo:YKWLocalizedString(@"The object is not a view.")];
    }
}

- (void)screenLog:(YKWScreenLog *)log didInput:(NSString *)inputStr {
    [log saveInputToHistory:inputStr];

    if ([inputStr hasPrefix:@"k "] || [inputStr hasPrefix:@"K "]) {
        inputStr = [inputStr substringFromIndex:1];
        inputStr = [inputStr stringByReplacingOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, inputStr.length)];
        if (inputStr.length > 0) {
            YKWObjectTableView *tableView = _probeTableAry.lastObject;
            NSObject *obj = [tableView.probedObject valueForKeyPath:inputStr];
            if (obj) {
                [self objectTableView:tableView didSelectObject:obj class:nil key:inputStr];
            } else {
                [_logView logInfo:YKWLocalizedString(@"Can't find object")];
            }
        } else {
            [_logView logInfo:YKWLocalizedString(@"Can't find key")];
        }
    } else {
        if ([_poCmdCore parseInput:inputStr]) {
            if (_poCmdCore.lastReturnedObject) {
                if (![self checkIfShowInfoObject:_poCmdCore.lastReturnedObject key:nil]) {
                    [self setupTableViewWith:_poCmdCore.lastReturnedObject class:_poCmdCore.lastReturnedObject.class];
                }
            } else {
                [_logView logInfo:@"Return void"];
            }
        } else {
            [_logView logInfo:_poCmdCore.lastErrorInfo];
        }
    }
}

#pragma mark - YKWObjectTableViewDelegate
- (void)objectTableView:(YKWObjectTableView *)objTableView didTapOnObject:(nullable NSObject *)object key:(NSString *)key {
    if (!object) {
        if ([key isEqualToString:@"brotherviews"] && [objTableView.probedObject isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)objTableView.probedObject;
            object = view.superview.subviews;
        } else {
            if ([objTableView.probedObject isKindOfClass:[NSArray class]]) {
                object = [(NSArray *)objTableView.probedObject ykw_objectAtIndex:key.integerValue];
            } else {
                object = [objTableView.probedObject valueForKey:key];
            }
        }
    }
    
    if (object) {
        [self showInfo:[self checkIfJsonStyle:object] key:key];
        
        if ([object isKindOfClass:[UIImage class]]) {
            YKWImageTextPreview *preview = [[YKWImageTextPreview alloc] init];
            preview.image = (UIImage *)object;
            [preview show];
        }
    }
}

- (void)objectTableView:(YKWObjectTableView *)objTableView didSelectNonObject:(id)sth class:(__unsafe_unretained Class)cls key:(NSString *)key {
    if (!sth) {
        [_logView logInfo:YKWLocalizedString(@"Can't find object")];
    }
}

- (void)objectTableView:(YKWObjectTableView *)objTableView didSelectObject:(NSObject *)object class:(__unsafe_unretained Class)cls key:(NSString *)key {
    if ([self checkIfShowInfoObject:object key:key]) {
        return;
    }
    
    NSInteger index = [_probeTableAry indexOfObject:objTableView] + 1;
    YKWObjectTableView *nextTable = [_probeTableAry ykw_objectAtIndex:index];
    if (nextTable) {
        nextTable.probeClass = cls;
        nextTable.probedObject = object;
        for (index++; index < _probeTableAry.count;) {
            YKWObjectTableView *aTable = [_probeTableAry ykw_objectAtIndex:index];
            [aTable removeFromSuperview];
            [_probeTableAry removeObject:aTable];
        }
        _probeTableScrollView.contentSize = CGSizeMake(_probeTableAry.count * nextTable.ykw_width, 0);
        [_probeTableScrollView setContentOffset:CGPointMake(_probeTableScrollView.contentSize.width - _probeTableScrollView.ykw_width, 0) animated:YES];
    } else {
        [self setupTableViewWith:object class:cls];
    }
}

- (void)setupTableViewWith:(NSObject *)object class:(Class)cls {
    YKWObjectTableView *tableView = [[YKWObjectTableView alloc] init];
    tableView.ykw_width = _probeTableScrollView.ykw_width / 1.3;
    tableView.ykw_left = _probeTableAry.count * tableView.ykw_width;
    tableView.ykw_height = _probeTableScrollView.ykw_height;
    tableView.probeClass = cls;
    tableView.objDelegate = self;
    tableView.probedObject = object;
    [_probeTableAry addObject:tableView];
    [_probeTableScrollView addSubview:tableView];
    [self setupObjectIndex];
    _probeTableScrollView.contentSize = CGSizeMake(_probeTableAry.count * tableView.ykw_width, 0);
    if (_probeTableAry.count == 1) {
        [_probeTableScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    } else {
        [_probeTableScrollView setContentOffset:CGPointMake(_probeTableScrollView.contentSize.width - _probeTableScrollView.ykw_width, 0) animated:YES];
    }
}

- (void)setupObjectIndex {
    NSMutableArray *objectAry = [NSMutableArray array];
    for (int i = 0; i < _probeTableAry.count; i++) {
        YKWObjectTableView *v = [_probeTableAry ykw_objectAtIndex:i];
        v.objectIndex = i + 1;
        if (v.probedObject) {
            [objectAry addObject:v.probedObject];
        }
    }
    _poCmdCore.objectsArray = objectAry;
}

- (BOOL)checkIfShowInfoObject:(NSObject *)object key:(NSString *)key {
    if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSURL class]] || [object isKindOfClass:[NSNumber class]] || [object isKindOfClass:[NSValue class]] || [object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSSet class]]) {
        [self showInfo:[self checkIfJsonStyle:object] key:key];
        return YES;
    }
    return NO;
}

- (void)showInfo:(NSString *)string key:(NSString *)key {
    if (key.length) {
        [_logView log:[key stringByAppendingString:@":"] color:YKWHighlightColor keepLine:YES checkReg:NO checkFind:NO];
    }
    if (string) {
        [_logView log:string color:nil keepLine:NO checkReg:NO checkFind:NO];
    }
}

- (NSString *)checkIfJsonStyle:(NSObject *)obj {
    if (!obj) return @"<nil>";
    
    NSError *er = nil;
    NSData *data = nil;
    if ([NSJSONSerialization isValidJSONObject:obj]) {
        data = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&er];
    } else if ([obj isKindOfClass:[NSString class]]) {
        id jsonObj = [NSJSONSerialization JSONObjectWithData:[(NSString *)obj dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&er];
        if (!er && jsonObj) {
            er = nil;
            data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:&er];
        }
    }
    if (!er && data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return obj.description;
}

@end
