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
    switch (paraAry.count) {
        case 0:{
            objc_msgSend(target, selector);
        }break;
        case 1:{
            switch (paraTypeStr.integerValue) {
                case 1:
                    ((void (*)(id, SEL, id))objc_msgSend)
                    (target, selector, objc_msgSend(paraAry[0], paraAry[0].getParaSelector));
                    break;
                case 2:
                    ((void (*)(id, SEL, long long))objc_msgSend)
                    (target, selector, paraAry[0].longlongPara);
                    break;
                case 3:
                    ((void (*)(id, SEL, double))objc_msgSend)
                    (target, selector, paraAry[0].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        case 2:{
            switch (paraTypeStr.integerValue) {
                case 11:
                    ((void (*)(id, SEL, id, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 12:
                    ((void (*)(id, SEL, id, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara);
                    break;
                case 13:{
                    ((void (*)(id, SEL, id, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara);
                }break;
                case 21:
                    ((void (*)(id, SEL, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 22:
                    ((void (*)(id, SEL, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     paraAry[1].longlongPara);
                    break;
                case 23:
                    ((void (*)(id, SEL, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     paraAry[1].doublePara);
                    break;
                case 31:
                    ((void (*)(id, SEL, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 32:
                    ((void (*)(id, SEL, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     paraAry[1].longlongPara);
                    break;
                case 33:
                    ((void (*)(id, SEL, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     paraAry[1].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        case 3:{
            switch (paraTypeStr.integerValue) {
                case 111:
                    ((void (*)(id, SEL, id, id, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 112:
                    ((void (*)(id, SEL, id, id, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 113:
                    ((void (*)(id, SEL, id, id, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 121:
                    ((void (*)(id, SEL, id, long long, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 122:
                    ((void (*)(id, SEL, id, long long, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 123:
                    ((void (*)(id, SEL, id, long long, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 131:
                    ((void (*)(id, SEL, id, long long, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 132:
                    ((void (*)(id, SEL, id, long long, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 133:
                    ((void (*)(id, SEL, id, long long, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                    
                case 211:
                    ((void (*)(id, SEL, long long, id, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 212:
                    ((void (*)(id, SEL, long long, id, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 213:
                    ((void (*)(id, SEL, long long, id, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 221:
                    ((void (*)(id, SEL, long long, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 222:
                    ((void (*)(id, SEL, long long, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 223:
                    ((void (*)(id, SEL, long long, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 231:
                    ((void (*)(id, SEL, long long, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 232:
                    ((void (*)(id, SEL, long long, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 233:
                    ((void (*)(id, SEL, long long, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                    
                case 311:
                    ((void (*)(id, SEL, double, id, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 312:
                    ((void (*)(id, SEL, double, id, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 313:
                    ((void (*)(id, SEL, double, id, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 321:
                    ((void (*)(id, SEL, double, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 322:
                    ((void (*)(id, SEL, double, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 323:
                    ((void (*)(id, SEL, double, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 331:
                    ((void (*)(id, SEL, double, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 332:
                    ((void (*)(id, SEL, double, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 333:
                    ((void (*)(id, SEL, double, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        default:
            break;
    }
}

- (id)runIdReturnWithTarget:(id)target selector:(SEL)selector paraType:(NSString *)paraTypeStr paraAry:(NSArray<YKWPoCommandPara *> *)paraAry {
    id ret = nil;
    switch (paraAry.count) {
        case 0:{
            ret = objc_msgSend(target, selector);
        }break;
        case 1:{
            switch (paraTypeStr.integerValue) {
                case 1:
                    ret = ((id (*)(id, SEL, id))objc_msgSend)
                    (target, selector, objc_msgSend(paraAry[0], paraAry[0].getParaSelector));
                    break;
                case 2:
                    ret = ((id (*)(id, SEL, long long))objc_msgSend)
                    (target, selector, paraAry[0].longlongPara);
                    break;
                case 3:
                    ret = ((id (*)(id, SEL, double))objc_msgSend)
                    (target, selector, paraAry[0].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        case 2:{
            switch (paraTypeStr.integerValue) {
                case 11:
                    ret = ((id (*)(id, SEL, id, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 12:
                    ret = ((id (*)(id, SEL, id, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara);
                    break;
                case 13:{
                    ret = ((id (*)(id, SEL, id, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara);
                }break;
                case 21:
                    ret = ((id (*)(id, SEL, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 22:
                    ret = ((id (*)(id, SEL, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     paraAry[1].longlongPara);
                    break;
                case 23:
                    ret = ((id (*)(id, SEL, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     paraAry[1].doublePara);
                    break;
                case 31:
                    ret = ((id (*)(id, SEL, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 32:
                    ret = ((id (*)(id, SEL, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     paraAry[1].longlongPara);
                    break;
                case 33:
                    ret = ((id (*)(id, SEL, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     paraAry[1].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        case 3:{
            switch (paraTypeStr.integerValue) {
                case 111:
                    ret = ((id (*)(id, SEL, id, id, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 112:
                    ret = ((id (*)(id, SEL, id, id, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 113:
                    ret = ((id (*)(id, SEL, id, id, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 121:
                    ret = ((id (*)(id, SEL, id, long long, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 122:
                    ret = ((id (*)(id, SEL, id, long long, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 123:
                    ret = ((id (*)(id, SEL, id, long long, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 131:
                    ret = ((id (*)(id, SEL, id, long long, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 132:
                    ret = ((id (*)(id, SEL, id, long long, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 133:
                    ret = ((id (*)(id, SEL, id, long long, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                    
                case 211:
                    ret = ((id (*)(id, SEL, long long, id, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 212:
                    ret = ((id (*)(id, SEL, long long, id, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 213:
                    ret = ((id (*)(id, SEL, long long, id, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 221:
                    ret = ((id (*)(id, SEL, long long, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 222:
                    ret = ((id (*)(id, SEL, long long, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 223:
                    ret = ((id (*)(id, SEL, long long, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 231:
                    ret = ((id (*)(id, SEL, long long, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 232:
                    ret = ((id (*)(id, SEL, long long, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 233:
                    ret = ((id (*)(id, SEL, long long, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                    
                case 311:
                    ret = ((id (*)(id, SEL, double, id, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 312:
                    ret = ((id (*)(id, SEL, double, id, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 313:
                    ret = ((id (*)(id, SEL, double, id, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 321:
                    ret = ((id (*)(id, SEL, double, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 322:
                    ret = ((id (*)(id, SEL, double, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 323:
                    ret = ((id (*)(id, SEL, double, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 331:
                    ret = ((id (*)(id, SEL, double, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 332:
                    ret = ((id (*)(id, SEL, double, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 333:
                    ret = ((id (*)(id, SEL, double, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        default:
            return nil;
            break;
    }
    return  ret;
}

- (double)runDoubleReturnWithTarget:(id)target selector:(SEL)selector paraType:(NSString *)paraTypeStr paraAry:(NSArray<YKWPoCommandPara *> *)paraAry {
    double ret = 0;
    switch (paraAry.count) {
        case 0:{
            ret = ((double (*)(id, SEL))objc_msgSend)(target, selector);
        }break;
        case 1:{
            switch (paraTypeStr.integerValue) {
                case 1:
                    ret = ((double (*)(id, SEL, id))objc_msgSend)
                    (target, selector, objc_msgSend(paraAry[0], paraAry[0].getParaSelector));
                    break;
                case 2:
                    ret = ((double (*)(id, SEL, long long))objc_msgSend)
                    (target, selector, paraAry[0].longlongPara);
                    break;
                case 3:
                    ret = ((double (*)(id, SEL, double))objc_msgSend)
                    (target, selector, paraAry[0].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        case 2:{
            switch (paraTypeStr.integerValue) {
                case 11:
                    ret = ((double (*)(id, SEL, id, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 12:
                    ret = ((double (*)(id, SEL, id, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara);
                    break;
                case 13:
                    ret = ((double (*)(id, SEL, id, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara);
                    break;
                case 21:
                    ret = ((double (*)(id, SEL, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 22:
                    ret = ((double (*)(id, SEL, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     paraAry[1].longlongPara);
                    break;
                case 23:
                    ret = ((double (*)(id, SEL, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     paraAry[1].doublePara);
                    break;
                case 31:
                    ret = ((double (*)(id, SEL, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 32:
                    ret = ((double (*)(id, SEL, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     paraAry[1].longlongPara);
                    break;
                case 33:
                    ret = ((double (*)(id, SEL, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     paraAry[1].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        case 3:{
            switch (paraTypeStr.integerValue) {
                case 111:
                    ret = ((double (*)(id, SEL, id, id, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 112:
                    ret = ((double (*)(id, SEL, id, id, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 113:
                    ret = ((double (*)(id, SEL, id, id, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 121:
                    ret = ((double (*)(id, SEL, id, long long, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 122:
                    ret = ((double (*)(id, SEL, id, long long, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 123:
                    ret = ((double (*)(id, SEL, id, long long, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 131:
                    ret = ((double (*)(id, SEL, id, long long, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 132:
                    ret = ((double (*)(id, SEL, id, long long, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 133:
                    ret = ((double (*)(id, SEL, id, long long, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                    
                case 211:
                    ret = ((double (*)(id, SEL, long long, id, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 212:
                    ret = ((double (*)(id, SEL, long long, id, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 213:
                    ret = ((double (*)(id, SEL, long long, id, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 221:
                    ret = ((double (*)(id, SEL, long long, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 222:
                    ret = ((double (*)(id, SEL, long long, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 223:
                    ret = ((double (*)(id, SEL, long long, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 231:
                    ret = ((double (*)(id, SEL, long long, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 232:
                    ret = ((double (*)(id, SEL, long long, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 233:
                    ret = ((double (*)(id, SEL, long long, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                    
                case 311:
                    ret = ((double (*)(id, SEL, double, id, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 312:
                    ret = ((double (*)(id, SEL, double, id, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 313:
                    ret = ((double (*)(id, SEL, double, id, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 321:
                    ret = ((double (*)(id, SEL, double, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 322:
                    ret = ((double (*)(id, SEL, double, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 323:
                    ret = ((double (*)(id, SEL, double, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 331:
                    ret = ((double (*)(id, SEL, double, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 332:
                    ret = ((double (*)(id, SEL, double, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 333:
                    ret = ((double (*)(id, SEL, double, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        default:
            return 0;
            break;
    }
    return ret;
}

- (double)runLonglongReturnWithTarget:(id)target selector:(SEL)selector paraType:(NSString *)paraTypeStr paraAry:(NSArray<YKWPoCommandPara *> *)paraAry {
    long long ret = 0;
    switch (paraAry.count) {
        case 0:{
            ret = ((long long (*)(id, SEL))objc_msgSend)(target, selector);
        }break;
        case 1:{
            switch (paraTypeStr.integerValue) {
                case 1:
                    ret = ((long long (*)(id, SEL, id))objc_msgSend)
                    (target, selector, objc_msgSend(paraAry[0], paraAry[0].getParaSelector));
                    break;
                case 2:
                    ret = ((long long (*)(id, SEL, long long))objc_msgSend)
                    (target, selector, paraAry[0].longlongPara);
                    break;
                case 3:
                    ret = ((long long (*)(id, SEL, double))objc_msgSend)
                    (target, selector, paraAry[0].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        case 2:{
            switch (paraTypeStr.integerValue) {
                case 11:
                    ret = ((long long (*)(id, SEL, id, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 12:
                    ret = ((long long (*)(id, SEL, id, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara);
                    break;
                case 13:
                    ret = ((long long (*)(id, SEL, id, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara);
                    break;
                case 21:
                    ret = ((long long (*)(id, SEL, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 22:
                    ret = ((long long (*)(id, SEL, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     paraAry[1].longlongPara);
                    break;
                case 23:
                    ret = ((long long (*)(id, SEL, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[0].longlongPara,
                     paraAry[1].doublePara);
                    break;
                case 31:
                    ret = ((long long (*)(id, SEL, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector));
                    break;
                case 32:
                    ret = ((long long (*)(id, SEL, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     paraAry[1].longlongPara);
                    break;
                case 33:
                    ret = ((long long (*)(id, SEL, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[0].doublePara,
                     paraAry[1].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        case 3:{
            switch (paraTypeStr.integerValue) {
                case 111:
                    ret = ((long long (*)(id, SEL, id, id, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 112:
                    ret = ((long long (*)(id, SEL, id, id, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 113:
                    ret = ((long long (*)(id, SEL, id, id, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 121:
                    ret = ((long long (*)(id, SEL, id, long long, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 122:
                    ret = ((long long (*)(id, SEL, id, long long, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 123:
                    ret = ((long long (*)(id, SEL, id, long long, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 131:
                    ret = ((long long (*)(id, SEL, id, long long, id))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 132:
                    ret = ((long long (*)(id, SEL, id, long long, long long))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 133:
                    ret = ((long long (*)(id, SEL, id, long long, double))objc_msgSend)
                    (target, selector,
                     objc_msgSend(paraAry[0], paraAry[0].getParaSelector),
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                    
                case 211:
                    ret = ((long long (*)(id, SEL, long long, id, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 212:
                    ret = ((long long (*)(id, SEL, long long, id, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 213:
                    ret = ((long long (*)(id, SEL, long long, id, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 221:
                    ret = ((long long (*)(id, SEL, long long, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 222:
                    ret = ((long long (*)(id, SEL, long long, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 223:
                    ret = ((long long (*)(id, SEL, long long, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 231:
                    ret = ((long long (*)(id, SEL, long long, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 232:
                    ret = ((long long (*)(id, SEL, long long, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 233:
                    ret = ((long long (*)(id, SEL, long long, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[2].longlongPara,
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                    
                case 311:
                    ret = ((long long (*)(id, SEL, double, id, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 312:
                    ret = ((long long (*)(id, SEL, double, id, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].longlongPara);
                    break;
                case 313:
                    ret = ((long long (*)(id, SEL, double, id, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[1], paraAry[1].getParaSelector),
                     paraAry[2].doublePara);
                    break;
                case 321:
                    ret = ((long long (*)(id, SEL, double, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 322:
                    ret = ((long long (*)(id, SEL, double, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     paraAry[2].longlongPara);
                    break;
                case 323:
                    ret = ((long long (*)(id, SEL, double, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].longlongPara,
                     paraAry[2].doublePara);
                    break;
                case 331:
                    ret = ((long long (*)(id, SEL, double, long long, id))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     objc_msgSend(paraAry[2], paraAry[2].getParaSelector));
                    break;
                case 332:
                    ret = ((long long (*)(id, SEL, double, long long, long long))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     paraAry[2].longlongPara);
                    break;
                case 333:
                    ret = ((long long (*)(id, SEL, double, long long, double))objc_msgSend)
                    (target, selector,
                     paraAry[1].doublePara,
                     paraAry[1].doublePara,
                     paraAry[2].doublePara);
                    break;
                default:
                    break;
            }
        }break;
        default:
            return 0;
            break;
    }
    return ret;
}

@end
