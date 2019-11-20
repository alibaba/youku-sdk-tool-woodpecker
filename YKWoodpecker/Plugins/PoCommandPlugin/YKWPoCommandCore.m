//
//  YKWPoCommandCore.m
//  YKWoodpecker
//
//  Created by Zim on 2019/8/6.
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

#import "YKWPoCommandCore.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface YKWPoCommandPara : NSObject {
    NSString *_parsedParaStr;
}

@property (nonatomic) NSString *parsedParaStr;
@property (nonatomic) NSString *parsedParaType;
@property (nonatomic) SEL getParaSelector;

- (BOOL)parsePara:(NSString *)paraStr;

- (NSString *)stringPara;
- (NSNumber *)numberPara;
- (long long)longlongPara;
- (double)doublePara;

@end

@implementation YKWPoCommandPara

- (BOOL)parsePara:(NSString *)paraStr {
    if ([paraStr hasPrefix:@"@\""] && [paraStr hasSuffix:@"\""]) {
        self.parsedParaStr = [paraStr substringWithRange:NSMakeRange(2, paraStr.length - 3)];
        self.getParaSelector = @selector(stringPara);
        self.parsedParaType = @"1";
    } else if ([paraStr hasPrefix:@"@("] && [paraStr hasSuffix:@")"]) {
        self.parsedParaStr = [paraStr substringWithRange:NSMakeRange(2, paraStr.length - 3)];
        self.getParaSelector = @selector(numberPara);
        self.parsedParaType = @"1";
    } else if ([paraStr isEqualToString:@"nil"]) {
        self.parsedParaStr = nil;
        self.getParaSelector = @selector(stringPara);
        self.parsedParaType = @"";
    } else if ([paraStr rangeOfString:@"[-0-9]*" options:NSRegularExpressionSearch].length == paraStr.length) {
        self.parsedParaStr = paraStr;
        self.getParaSelector = @selector(longlongPara);
        self.parsedParaType = @"2";
    } else if ([paraStr rangeOfString:@"[-0-9.]*" options:NSRegularExpressionSearch].length == paraStr.length) {
        self.parsedParaStr = paraStr;
        self.getParaSelector = @selector(doublePara);
        self.parsedParaType = @"3";
    } else if ([paraStr isEqualToString:@"YES"] || [paraStr isEqualToString:@"NO"]) {
        self.parsedParaStr = [paraStr isEqualToString:@"YES"] ? @"1" : @"0";
        self.getParaSelector = @selector(longlongPara);
        self.parsedParaType = @"2";
    } else {
        return NO;
    }
    
    return YES;
}

- (NSString *)stringPara {
    return _parsedParaStr;
}

- (NSNumber *)numberPara {
    if ([_parsedParaStr rangeOfString:@"."].location != NSNotFound) {
        return [NSNumber numberWithDouble:_parsedParaStr.doubleValue];
    } else {
        return [NSNumber numberWithLongLong:_parsedParaStr.longLongValue];
    }
}

- (long long)longlongPara {
    return _parsedParaStr.longLongValue;
}

- (double)doublePara {
    return _parsedParaStr.doubleValue;
}

@end

@implementation YKWPoCommandCore

- (BOOL)parseInput:(NSString *)input {
    if (![input hasPrefix:@"po "] && ![input hasPrefix:@"Po "]) {
        self.isLastPoCmd = NO;
        self.lastErrorInfo = @"Not po command.";
        return NO;
    }
    self.isLastPoCmd = YES;
    
    input = [input substringFromIndex:[input rangeOfString:@"["].location];
    input = [input stringByReplacingOccurrencesOfString:@"[ [" withString:@"[["];
    
    if ([input hasPrefix:@"[[[["]) {
        self.lastErrorInfo = @"Too many [] blocks.";
        return NO;
    } else if ([input hasPrefix:@"[[["]) {
        
    } else if ([input hasPrefix:@"[["]) {
        NSRange startRange = [input rangeOfString:@"[["];
        NSRange endRange = [input rangeOfString:@"]"];
        NSRange subRange = NSMakeRange(startRange.location + 1, endRange.location - startRange.location);
        NSString *subCmd = [input substringWithRange:subRange];
        if ([self runPoCommand:subCmd]) {
            input = [input stringByReplacingOccurrencesOfString:subCmd withString:@"lastReturn "];
            return [self runPoCommand:input];
        }
    } else if ([input hasPrefix:@"["]) {
        return [self runPoCommand:input];
    }
    return NO;
}

- (BOOL)runPoCommand:(NSString *)poCmd {
    NSArray *components = [poCmd componentsSeparatedByString:@" "];
    components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
    if ([components.firstObject hasPrefix:@"["]) {
        NSMutableString *selectorStr = [NSMutableString string];
        NSMutableString *paraTypeStr = [NSMutableString string];
        NSMutableArray <YKWPoCommandPara *>*paraAry = [NSMutableArray array];
        for (int i = 1; i < components.count; i++) {
            NSString *component = components[i];
            if (i == components.count - 1) {
                if ([component hasSuffix:@";"]) {
                    component = [component substringToIndex:component.length - 1];
                }
                if ([component hasSuffix:@"]"]) {
                    component = [component substringToIndex:component.length - 1];
                }
            }
            NSArray *methodComponents = [component componentsSeparatedByString:@":"];
            if (i != components.count - 1 && methodComponents.count < 2) {
                self.lastErrorInfo = @"Syntax error.";
                return NO;
            }
            [selectorStr appendFormat:@"%@%@", methodComponents.firstObject, methodComponents.count == 2 ? @":" : @""];
            if (methodComponents.count == 2) {
                YKWPoCommandPara *para = [[YKWPoCommandPara alloc] init];
                if ([para parsePara:methodComponents.lastObject]) {
                    if (para.parsedParaType.length) {
                        [paraTypeStr appendString:para.parsedParaType];
                        [paraAry addObject:para];
                    }
                } else {
                    self.lastErrorInfo = [NSString stringWithFormat:@"Unrecognized parameter %@.", methodComponents.lastObject];
                    return NO;
                }
            }
        }
        
        if (paraAry.count > 3) {
            self.lastErrorInfo = @"Too many parameters";
            return NO;
        }
        
        id target = nil;
        SEL selector = NSSelectorFromString(selectorStr);
        NSMethodSignature *methodSignature = nil;
        
        NSString *first = [components.firstObject stringByReplacingOccurrencesOfString:@"[" withString:@""];
        if ([first isEqualToString:@"lastReturn"]) {
            target = self.lastReturnedObject;
            if (!target) {
                self.lastErrorInfo = @"Target object error.";
                return NO;
            }
            if (![target respondsToSelector:selector]) {
                self.lastErrorInfo = @"Target object does not respond to selector.";
                return NO;
            }
            methodSignature = [target methodSignatureForSelector:selector];
        } else {
            Class cls = NSClassFromString(first);
            if (!cls) {
                self.lastErrorInfo = @"Class name error.";
                return NO;
            }
            target = cls;
            if (![target respondsToSelector:selector]) {
                self.lastErrorInfo = @"Class does not respond to selector.";
                return NO;
            }
            methodSignature = [target methodSignatureForSelector:selector];
        }
        if (!methodSignature) {
            self.lastErrorInfo = @"Get method signature error.";
            return NO;
        }
        
        const char *type = methodSignature.methodReturnType;
        if (strcmp(type, "v") == 0) {
            [self runVoidReturnWithTarget:target selector:selector paraType:paraTypeStr paraAry:paraAry];
            self.lastReturnedObject = @"Run success, return void.";
        } else if (strcmp(type, "@") == 0) {
            id ret = [self runIdReturnWithTarget:target selector:selector paraType:paraTypeStr paraAry:paraAry];
            if (ret) {
                self.lastReturnedObject = ret;
            } else {
                self.lastReturnedObject = @"Run success, return void.";
            }
        } else if (strcmp(type, "f") == 0 || strcmp(type, "d") == 0) {
            double ret = [self runDoubleReturnWithTarget:target selector:selector paraType:paraTypeStr paraAry:paraAry];
            self.lastReturnedObject = @(ret).stringValue;
        } else if (strcmp(type, "i") == 0 || strcmp(type, "l") == 0 || strcmp(type, "q") == 0 || strcmp(type, "I") == 0 || strcmp(type, "L") == 0 || strcmp(type, "Q") == 0 || strcmp(type, "B") == 0) {
            long long ret = [self runLonglongReturnWithTarget:target selector:selector paraType:paraTypeStr paraAry:paraAry];
            self.lastReturnedObject = @(ret).stringValue;
        } else {
            self.lastErrorInfo = @"Unsupported return type.";
            return NO;
        }
        return YES;
    } else {
        self.lastErrorInfo = @"Syntax error.";
        return NO;
    }
}

- (BOOL)inputIsPureNumber:(NSString *)input {
    NSString *regex =@"[0-9.]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [pred evaluateWithObject:input];
}

- (void)runVoidReturnWithTarget:(id)target selector:(SEL)selector paraType:(NSString *)paraTypeStr paraAry:(NSArray<YKWPoCommandPara *> *)paraAry {
    typedef id (*msgTypeOne)(id, SEL);
    msgTypeOne msgSendOne = (msgTypeOne)objc_msgSend;
    switch (paraAry.count) {
        case 0:{
            typedef void (*msgType)(id, SEL);
            msgType msgSend = (msgType)objc_msgSend;
            msgSend(target, selector);
        }break;
        case 1:{
            switch (paraTypeStr.integerValue) {
                case 1:{
                    typedef void (*msgType)(id, SEL, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector, msgSendOne(paraAry[0], paraAry[0].getParaSelector));
                }break;
                case 2:{
                    typedef void (*msgType)(id, SEL, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector, paraAry[0].longlongPara);
                }break;
                case 3:{
                    typedef void (*msgType)(id, SEL, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector, paraAry[0].doublePara);
                }break;
                default:break;
            }
        }break;
        case 2:{
            switch (paraTypeStr.integerValue) {
                case 11:{
                    typedef void (*msgType)(id, SEL, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 12:{
                    typedef void (*msgType)(id, SEL, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            paraAry[1].longlongPara);
                }break;
                case 13:{
                    typedef void (*msgType)(id, SEL, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            paraAry[1].doublePara);
                }break;
                case 21:{
                    typedef void (*msgType)(id, SEL, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[0].longlongPara,
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 22:{
                    typedef void (*msgType)(id, SEL, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[0].longlongPara,
                            paraAry[1].longlongPara);
                }break;
                case 23:{
                    typedef void (*msgType)(id, SEL, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[0].longlongPara,
                            paraAry[1].doublePara);
                }break;
                case 31:{
                    typedef void (*msgType)(id, SEL, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[0].doublePara,
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 32:{
                    typedef void (*msgType)(id, SEL, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[0].doublePara,
                            paraAry[1].longlongPara);
                }break;
                case 33:{
                    typedef void (*msgType)(id, SEL, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[0].doublePara,
                            paraAry[1].doublePara);
                }break;
                default:break;
            }
        }break;
        case 3:{
            switch (paraTypeStr.integerValue) {
                case 111:{
                    typedef void (*msgType)(id, SEL, id, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 112:{
                    typedef void (*msgType)(id, SEL, id, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            paraAry[2].longlongPara);
                }break;
                case 113:{
                    typedef void (*msgType)(id, SEL, id, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            paraAry[2].doublePara);
                }break;
                case 121:{
                    typedef void (*msgType)(id, SEL, id, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            paraAry[1].longlongPara,
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 122:{
                    typedef void (*msgType)(id, SEL, id, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            paraAry[1].longlongPara,
                            paraAry[2].longlongPara);
                }break;
                case 123:{
                    typedef void (*msgType)(id, SEL, id, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            paraAry[1].longlongPara,
                            paraAry[2].doublePara);
                }break;
                case 131:{
                    typedef void (*msgType)(id, SEL, id, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            paraAry[1].doublePara,
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 132:{
                    typedef void (*msgType)(id, SEL, id, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            paraAry[1].doublePara,
                            paraAry[2].longlongPara);
                }break;
                case 133:{
                    typedef void (*msgType)(id, SEL, id, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                            paraAry[1].doublePara,
                            paraAry[2].doublePara);
                }break;
                    
                case 211:{
                    typedef void (*msgType)(id, SEL, long long, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 212:{
                    typedef void (*msgType)(id, SEL, long long, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            paraAry[2].longlongPara);
                }break;
                case 213:{
                    typedef void (*msgType)(id, SEL, long long, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            paraAry[2].doublePara);
                }break;
                case 221:{
                    typedef void (*msgType)(id, SEL, long long, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            paraAry[1].longlongPara,
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 222:{
                    typedef void (*msgType)(id, SEL, long long, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            paraAry[1].longlongPara,
                            paraAry[2].longlongPara);
                }break;
                case 223:{
                    typedef void (*msgType)(id, SEL, long long, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            paraAry[1].longlongPara,
                            paraAry[2].doublePara);
                }break;
                case 231:{
                    typedef void (*msgType)(id, SEL, long long, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            paraAry[1].doublePara,
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 232:{
                    typedef void (*msgType)(id, SEL, long long, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            paraAry[1].doublePara,
                            paraAry[2].longlongPara);
                }break;
                case 233:{
                    typedef void (*msgType)(id, SEL, long long, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[2].longlongPara,
                            paraAry[1].doublePara,
                            paraAry[2].doublePara);
                }break;
                    
                case 311:{
                    typedef void (*msgType)(id, SEL, double, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 312:{
                    typedef void (*msgType)(id, SEL, double, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            paraAry[2].longlongPara);
                }break;
                case 313:{
                    typedef void (*msgType)(id, SEL, double, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                            paraAry[2].doublePara);
                }break;
                case 321:{
                    typedef void (*msgType)(id, SEL, double, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            paraAry[1].longlongPara,
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 322:{
                    typedef void (*msgType)(id, SEL, double, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            paraAry[1].longlongPara,
                            paraAry[2].longlongPara);
                }break;
                case 323:{
                    typedef void (*msgType)(id, SEL, double, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            paraAry[1].longlongPara,
                            paraAry[2].doublePara);
                }break;
                case 331:{
                    typedef void (*msgType)(id, SEL, double, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            paraAry[1].doublePara,
                            msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 332:{
                    typedef void (*msgType)(id, SEL, double, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            paraAry[1].doublePara,
                            paraAry[2].longlongPara);
                }break;
                case 333:{
                    typedef void (*msgType)(id, SEL, double, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    msgSend(target, selector,
                            paraAry[1].doublePara,
                            paraAry[1].doublePara,
                            paraAry[2].doublePara);
                }break;
                default:break;
            }
        }break;
        default:break;
    }
}

- (id)runIdReturnWithTarget:(id)target selector:(SEL)selector paraType:(NSString *)paraTypeStr paraAry:(NSArray<YKWPoCommandPara *> *)paraAry {
    id ret = nil;
    typedef id (*msgTypeOne)(id, SEL);
    msgTypeOne msgSendOne = (msgTypeOne)objc_msgSend;
    switch (paraAry.count) {
        case 0:{
            typedef id (*msgType)(id, SEL);
            msgType msgSend = (msgType)objc_msgSend;
            ret = msgSend(target, selector);
        }break;
        case 1:{
            switch (paraTypeStr.integerValue) {
                case 1:{
                    typedef id (*msgType)(id, SEL, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, msgSendOne(paraAry[0], paraAry[0].getParaSelector));
                }break;
                case 2:{
                    typedef id (*msgType)(id, SEL, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, paraAry[0].longlongPara);
                }break;
                case 3:{
                    typedef id (*msgType)(id, SEL, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, paraAry[0].doublePara);
                }break;
                default:break;
            }
        }break;
        case 2:{
            switch (paraTypeStr.integerValue) {
                case 11:{
                    typedef id (*msgType)(id, SEL, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 12:{
                    typedef id (*msgType)(id, SEL, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara);
                }break;
                case 13:{
                    typedef id (*msgType)(id, SEL, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara);
                }break;
                case 21:{
                    typedef id (*msgType)(id, SEL, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 22:{
                    typedef id (*msgType)(id, SEL, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  paraAry[1].longlongPara);
                }break;
                case 23:{
                    typedef id (*msgType)(id, SEL, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  paraAry[1].doublePara);
                }break;
                case 31:{
                    typedef id (*msgType)(id, SEL, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 32:{
                    typedef id (*msgType)(id, SEL, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  paraAry[1].longlongPara);
                }break;
                case 33:{
                    typedef id (*msgType)(id, SEL, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  paraAry[1].doublePara);
                }break;
                default:break;
            }
        }break;
        case 3:{
            switch (paraTypeStr.integerValue) {
                case 111:{
                    typedef id (*msgType)(id, SEL, id, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 112:{
                    typedef id (*msgType)(id, SEL, id, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 113:{
                    typedef id (*msgType)(id, SEL, id, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 121:{
                    typedef id (*msgType)(id, SEL, id, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 122:{
                    typedef id (*msgType)(id, SEL, id, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 123:{
                    typedef id (*msgType)(id, SEL, id, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 131:{
                    typedef id (*msgType)(id, SEL, id, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 132:{
                    typedef id (*msgType)(id, SEL, id, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 133:{
                    typedef id (*msgType)(id, SEL, id, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                    
                case 211:{
                    typedef id (*msgType)(id, SEL, long long, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 212:{
                    typedef id (*msgType)(id, SEL, long long, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 213:{
                    typedef id (*msgType)(id, SEL, long long, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 221:{
                    typedef id (*msgType)(id, SEL, long long, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 222:{
                    typedef id (*msgType)(id, SEL, long long, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 223:{
                    typedef id (*msgType)(id, SEL, long long, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 231:{
                    typedef id (*msgType)(id, SEL, long long, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 232:{
                    typedef id (*msgType)(id, SEL, long long, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 233:{
                    typedef id (*msgType)(id, SEL, long long, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                    
                case 311:{
                    typedef id (*msgType)(id, SEL, double, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 312:{
                    typedef id (*msgType)(id, SEL, double, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 313:{
                    typedef id (*msgType)(id, SEL, double, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 321:{
                    typedef id (*msgType)(id, SEL, double, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 322:{
                    typedef id (*msgType)(id, SEL, double, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 323:{
                    typedef id (*msgType)(id, SEL, double, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 331:{
                    typedef id (*msgType)(id, SEL, double, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 332:{
                    typedef id (*msgType)(id, SEL, double, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 333:{
                    typedef id (*msgType)(id, SEL, double, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                default:break;
            }
        }break;
        default:break;
    }
    return ret;
}

- (double)runDoubleReturnWithTarget:(id)target selector:(SEL)selector paraType:(NSString *)paraTypeStr paraAry:(NSArray<YKWPoCommandPara *> *)paraAry {
    double ret = 0;
    typedef id (*msgTypeOne)(id, SEL);
    msgTypeOne msgSendOne = (msgTypeOne)objc_msgSend;
    switch (paraAry.count) {
        case 0:{
            typedef double (*msgType)(id, SEL);
            msgType msgSend = (msgType)objc_msgSend;
            ret = msgSend(target, selector);
        }break;
        case 1:{
            switch (paraTypeStr.integerValue) {
                case 1:{
                    typedef double (*msgType)(id, SEL, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, msgSendOne(paraAry[0], paraAry[0].getParaSelector));
                }break;
                case 2:{
                    typedef double (*msgType)(id, SEL, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, paraAry[0].longlongPara);
                }break;
                case 3:{
                    typedef double (*msgType)(id, SEL, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, paraAry[0].doublePara);
                }break;
                default:break;
            }
        }break;
        case 2:{
            switch (paraTypeStr.integerValue) {
                case 11:{
                    typedef double (*msgType)(id, SEL, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 12:{
                    typedef double (*msgType)(id, SEL, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara);
                }break;
                case 13:{
                    typedef double (*msgType)(id, SEL, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara);
                }break;
                case 21:{
                    typedef double (*msgType)(id, SEL, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 22:{
                    typedef double (*msgType)(id, SEL, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  paraAry[1].longlongPara);
                }break;
                case 23:{
                    typedef double (*msgType)(id, SEL, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  paraAry[1].doublePara);
                }break;
                case 31:{
                    typedef double (*msgType)(id, SEL, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 32:{
                    typedef double (*msgType)(id, SEL, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  paraAry[1].longlongPara);
                }break;
                case 33:{
                    typedef double (*msgType)(id, SEL, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  paraAry[1].doublePara);
                }break;
                default:break;
            }
        }break;
        case 3:{
            switch (paraTypeStr.integerValue) {
                case 111:{
                    typedef double (*msgType)(id, SEL, id, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 112:{
                    typedef double (*msgType)(id, SEL, id, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 113:{
                    typedef double (*msgType)(id, SEL, id, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 121:{
                    typedef double (*msgType)(id, SEL, id, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 122:{
                    typedef double (*msgType)(id, SEL, id, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 123:{
                    typedef double (*msgType)(id, SEL, id, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 131:{
                    typedef double (*msgType)(id, SEL, id, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 132:{
                    typedef double (*msgType)(id, SEL, id, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 133:{
                    typedef double (*msgType)(id, SEL, id, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                    
                case 211:{
                    typedef double (*msgType)(id, SEL, long long, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 212:{
                    typedef double (*msgType)(id, SEL, long long, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 213:{
                    typedef double (*msgType)(id, SEL, long long, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 221:{
                    typedef double (*msgType)(id, SEL, long long, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 222:{
                    typedef double (*msgType)(id, SEL, long long, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 223:{
                    typedef double (*msgType)(id, SEL, long long, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 231:{
                    typedef double (*msgType)(id, SEL, long long, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 232:{
                    typedef double (*msgType)(id, SEL, long long, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 233:{
                    typedef double (*msgType)(id, SEL, long long, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                    
                case 311:{
                    typedef double (*msgType)(id, SEL, double, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 312:{
                    typedef double (*msgType)(id, SEL, double, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 313:{
                    typedef double (*msgType)(id, SEL, double, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 321:{
                    typedef double (*msgType)(id, SEL, double, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 322:{
                    typedef double (*msgType)(id, SEL, double, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 323:{
                    typedef double (*msgType)(id, SEL, double, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 331:{
                    typedef double (*msgType)(id, SEL, double, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 332:{
                    typedef double (*msgType)(id, SEL, double, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 333:{
                    typedef double (*msgType)(id, SEL, double, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                default:break;
            }
        }break;
        default:break;
    }
    return ret;
}

- (double)runLonglongReturnWithTarget:(id)target selector:(SEL)selector paraType:(NSString *)paraTypeStr paraAry:(NSArray<YKWPoCommandPara *> *)paraAry {
    long long ret = 0;
    typedef id (*msgTypeOne)(id, SEL);
    msgTypeOne msgSendOne = (msgTypeOne)objc_msgSend;
    switch (paraAry.count) {
        case 0:{
            typedef long long (*msgType)(id, SEL);
            msgType msgSend = (msgType)objc_msgSend;
            ret = msgSend(target, selector);
        }break;
        case 1:{
            switch (paraTypeStr.integerValue) {
                case 1:{
                    typedef long long (*msgType)(id, SEL, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, msgSendOne(paraAry[0], paraAry[0].getParaSelector));
                }break;
                case 2:{
                    typedef long long (*msgType)(id, SEL, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, paraAry[0].longlongPara);
                }break;
                case 3:{
                    typedef long long (*msgType)(id, SEL, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector, paraAry[0].doublePara);
                }break;
                default:break;
            }
        }break;
        case 2:{
            switch (paraTypeStr.integerValue) {
                case 11:{
                    typedef long long (*msgType)(id, SEL, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 12:{
                    typedef long long (*msgType)(id, SEL, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara);
                }break;
                case 13:{
                    typedef long long (*msgType)(id, SEL, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara);
                }break;
                case 21:{
                    typedef long long (*msgType)(id, SEL, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 22:{
                    typedef long long (*msgType)(id, SEL, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  paraAry[1].longlongPara);
                }break;
                case 23:{
                    typedef long long (*msgType)(id, SEL, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].longlongPara,
                                  paraAry[1].doublePara);
                }break;
                case 31:{
                    typedef long long (*msgType)(id, SEL, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector));
                }break;
                case 32:{
                    typedef long long (*msgType)(id, SEL, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  paraAry[1].longlongPara);
                }break;
                case 33:{
                    typedef long long (*msgType)(id, SEL, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[0].doublePara,
                                  paraAry[1].doublePara);
                }break;
                default:break;
            }
        }break;
        case 3:{
            switch (paraTypeStr.integerValue) {
                case 111:{
                    typedef long long (*msgType)(id, SEL, id, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 112:{
                    typedef long long (*msgType)(id, SEL, id, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 113:{
                    typedef long long (*msgType)(id, SEL, id, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 121:{
                    typedef long long (*msgType)(id, SEL, id, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 122:{
                    typedef long long (*msgType)(id, SEL, id, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 123:{
                    typedef long long (*msgType)(id, SEL, id, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 131:{
                    typedef long long (*msgType)(id, SEL, id, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 132:{
                    typedef long long (*msgType)(id, SEL, id, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 133:{
                    typedef long long (*msgType)(id, SEL, id, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  msgSendOne(paraAry[0], paraAry[0].getParaSelector),
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                    
                case 211:{
                    typedef long long (*msgType)(id, SEL, long long, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 212:{
                    typedef long long (*msgType)(id, SEL, long long, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 213:{
                    typedef long long (*msgType)(id, SEL, long long, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 221:{
                    typedef long long (*msgType)(id, SEL, long long, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 222:{
                    typedef long long (*msgType)(id, SEL, long long, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 223:{
                    typedef long long (*msgType)(id, SEL, long long, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 231:{
                    typedef long long (*msgType)(id, SEL, long long, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 232:{
                    typedef long long (*msgType)(id, SEL, long long, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 233:{
                    typedef long long (*msgType)(id, SEL, long long, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[2].longlongPara,
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                    
                case 311:{
                    typedef long long (*msgType)(id, SEL, double, id, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 312:{
                    typedef long long (*msgType)(id, SEL, double, id, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].longlongPara);
                }break;
                case 313:{
                    typedef long long (*msgType)(id, SEL, double, id, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[1], paraAry[1].getParaSelector),
                                  paraAry[2].doublePara);
                }break;
                case 321:{
                    typedef long long (*msgType)(id, SEL, double, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 322:{
                    typedef long long (*msgType)(id, SEL, double, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].longlongPara);
                }break;
                case 323:{
                    typedef long long (*msgType)(id, SEL, double, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].longlongPara,
                                  paraAry[2].doublePara);
                }break;
                case 331:{
                    typedef long long (*msgType)(id, SEL, double, long long, id);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  msgSendOne(paraAry[2], paraAry[2].getParaSelector));
                }break;
                case 332:{
                    typedef long long (*msgType)(id, SEL, double, long long, long long);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  paraAry[2].longlongPara);
                }break;
                case 333:{
                    typedef long long (*msgType)(id, SEL, double, long long, double);
                    msgType msgSend = (msgType)objc_msgSend;
                    ret = msgSend(target, selector,
                                  paraAry[1].doublePara,
                                  paraAry[1].doublePara,
                                  paraAry[2].doublePara);
                }break;
                default:break;
            }
        }break;
        default:break;
    }
    return ret;
}

@end
