//
//  YKWCmdCore.m
//  YKWoodpecker
//
//  Created by Zim on 2018/12/24.
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

#import "YKWCmdCore.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "YKWoodpeckerManager.h"
#import "YKWScreenLog.h"
#import "YKWCmdModel.h"
#import "YKWPoCommandCore.h"

@interface YKWCmdCore() {
    NSMutableArray *_listeningAry;      // @"Class -/+ method:para:"
    NSMutableArray *_postListenCmdAry;  // Commands that run after a listen-in
    YKWPoCommandCore *_poCmdCore;
}

@end

@implementation YKWCmdCore

- (instancetype)init {
    self = [super init];
    if (self) {
        _listeningAry = [NSMutableArray array];
        _postListenCmdAry = [NSMutableArray array];
        _poCmdCore = [[YKWPoCommandCore alloc] init];
    }
    return self;
}

- (void)clearFunctions {
    [self clearListen];
    [[YKWoodpeckerManager sharedInstance].screenLog clearRegExpression];
    [[YKWoodpeckerManager sharedInstance].screenLog clearToFindString];
    [_postListenCmdAry removeAllObjects];
}

- (void)setHadListenedParas:(NSMutableArray *)hadListenedParas {
    _hadListenedParas = hadListenedParas;
    
    // Post commands, such as k command.
    if (_postListenCmdAry.count) {
        for (NSString *cmdLine in _postListenCmdAry) {
            [self output:cmdLine];
            [self parseCmd:cmdLine];
        }
    }
}

#pragma mark - Output
- (void)output:(NSString *)str {
    if (str && self.outputDelegate && [self.outputDelegate respondsToSelector:@selector(cmdCore:didOutput:)]) {
        [self.outputDelegate cmdCore:self didOutput:str];
    }
}

- (void)output:(NSString *)output color:(UIColor *)color keepLine:(BOOL)keepline checkReg:(BOOL)checkReg checkFind:(BOOL)checkFind {
    if (output && self.outputDelegate && [self.outputDelegate respondsToSelector:@selector(cmdCore:didOutput:color:keepLine:checkReg:checkFind:)]) {
        [self.outputDelegate cmdCore:self didOutput:output color:color keepLine:keepline checkReg:checkReg checkFind:checkFind];
    }
}

#pragma mark - Input
- (void)parseCmdModel:(YKWCmdModel *)cmdModel {
    NSArray *components = [self parseComponents:cmdModel.cmdLines usingSeparator:@";"];
    if (components.count) {
        [self output:@""];
        for (NSString *inputLine in components) {
            if (inputLine.length && ![self checkIfAddToPostListenCmd:inputLine]) {
                [self output:inputLine];
                if (![[YKWoodpeckerManager sharedInstance].screenLog parseCommandString:inputLine]) {
                    [self parseCmd:inputLine];
                }
            }
        }
        [self output:@""];
    }
}

- (BOOL)checkIfAddToPostListenCmd:(NSString *)cmdStr {
    // Post commands, such as k command.
    if ([cmdStr hasPrefix:@"k"] || [cmdStr hasPrefix:@"K"]) {
        [_postListenCmdAry addObject:cmdStr];
        return YES;
    }
    return NO;
}

- (void)parseInput:(NSString *)input {
    NSArray *components = [self parseComponents:input usingSeparator:@";"];
    for (NSString *inputLine in components) {
        [self parseCmd:inputLine];
    }
}

- (void)parseCmd:(NSString *)cmdStr {
    if (self.parseDelegate && [self.parseDelegate respondsToSelector:@selector(cmdCore:shouldParseCmd:)]) {
        if (![self.parseDelegate cmdCore:self shouldParseCmd:cmdStr]) return;
    }
    [_poCmdCore parseInput:cmdStr];
    if (_poCmdCore.isLastPoCmd) {
        if (_poCmdCore.lastErrorInfo.length) {
            [self output:_poCmdCore.lastErrorInfo color:YKWINFOCOLOR keepLine:NO checkReg:NO checkFind:NO];
        } else {
            if (_poCmdCore.lastReturnedObject) {
                [self output:@"Return:" color:YKWHighlightColor keepLine:NO checkReg:NO checkFind:NO];
                [self output:_poCmdCore.lastReturnedObject.debugDescription];
            } else {
                [self output:@"Return void"];
            }
        }
        return;
    }

    NSArray *components = [self parseComponents:cmdStr usingSeparator:@" "];
    
    // Save input history
    if (components.count > 1) {
        [[YKWoodpeckerManager sharedInstance].screenLog saveInputToHistory:cmdStr];
    }
    
    // Commands
    if ([cmdStr hasPrefix:@"l"] || [cmdStr hasPrefix:@"L"]) { // l command
        if (components.count == 3) {
            [self listenIntoClass:components[1] method:components[2]];
        } else if (components.count == 2 && [components.lastObject isEqualToString:@"clr"]) {
            [self clearListen];
        } else if (components.count == 1 && [components.firstObject length] == 1) {
            [self printListenAry];
        } else {
            [self output:YKWLocalizedString(@"Input format error")];
        }
    } else if ([cmdStr hasPrefix:@"k"] || [cmdStr hasPrefix:@"K"]) { // k command
        if (self.hadListenedParas.count) {
            NSInteger index = 0;
            NSObject *object = nil;
            NSString *key = nil;
            if (components.count == 3) {
                index = [components[1] integerValue];
                key = components[2];
            } else if (components.count == 2) {
                index = 1;
                key = components[1];
                if (key.integerValue > 0) {
                    index = key.integerValue;
                    key = @"debugDescription";
                }
            } else if (components.count == 1 && [components.firstObject length] == 1) {
                [self output:YKWLocalizedString(@"Listened parameters:") color:YKWHighlightColor keepLine:YES checkReg:NO checkFind:NO];
                [self output:[NSString stringWithFormat:@"%@", self.hadListenedParas] color:nil keepLine:NO checkReg:YES checkFind:YES];
                return;
            } else {
                [self output:YKWLocalizedString(@"Input format error")];
                return;
            }
            
            // Output last listened call stack
            if ([key caseInsensitiveCompare:@"callStack"] == NSOrderedSame) {
                if (self.lastCallStackArray.count) {
                    for (NSString *stackStr in self.lastCallStackArray) {
                        NSArray *parts = [self parseComponents:stackStr usingSeparator:@" "];
                        [self output:[parts componentsJoinedByString:@" "]];
                    }
                } else {
                    [self output:YKWLocalizedString(@"<No call stack>")];
                }
                return;
            }
            
            if (index > 0 && index <= self.hadListenedParas.count) {
                object = self.hadListenedParas[index - 1];
            } else {
                [self output:YKWLocalizedString(@"Can't find object")];
                return;
            }
            id keyObj = [object valueForKeyPath:key];
            if (keyObj) {
                [self output:[NSString stringWithFormat:@"%@.%@:", object.class, key] color:YKWHighlightColor keepLine:YES checkReg:NO checkFind:NO];
                [self output:[NSString stringWithFormat:@"%@", [YKWCmdCore checkIfJsonString:[keyObj description]]] color:nil keepLine:NO checkReg:YES checkFind:YES];
            } else {
                [self output:YKWLocalizedString(@"Can't find object")];
            }
        } else {
            [self output:YKWLocalizedString(@"Can't find object")];
        }
    } else if ([cmdStr hasPrefix:@"p"] || [cmdStr hasPrefix:@"P"]) { // p command
        if ([components.firstObject length] == 1) {
            if (components.count == 1) {
                [self output:YKWLocalizedString(@"Post Commands:") color:YKWHighlightColor keepLine:YES checkReg:NO checkFind:NO];
                [self output:[NSString stringWithFormat:@"%@", _postListenCmdAry] color:nil keepLine:NO checkReg:NO checkFind:NO];
            } else if (components.count == 2 && [components.lastObject isEqualToString:@"clr"]) {
                [_postListenCmdAry removeAllObjects];
                [self output:YKWLocalizedString(@"All post commands removed")];
            } else {
                NSMutableArray *mComponents = [NSMutableArray arrayWithArray:components];
                [mComponents removeObjectAtIndex:0];
                if ([self checkIfAddToPostListenCmd:[mComponents componentsJoinedByString:@" "]]) {
                    [self output:YKWLocalizedString(@"Post command added")];
                } else {
                    [self output:YKWLocalizedString(@"Invalid post command")];
                }
            }
        } else {
            [self output:YKWLocalizedString(@"Input format error")];
        }
    } else {
        [self output:YKWLocalizedString(@"Unrecognized command")];
        [[YKWoodpeckerManager sharedInstance].screenLog printInputHistory];
    }
}

- (NSArray *)parseComponents:(NSString *)inputStr usingSeparator:(NSString *)separator {
    NSArray *components = [inputStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:separator]];
    return [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
}

- (void)printListenAry {
    if (_listeningAry.count > 0) {
        for (int i = 1; i <= _listeningAry.count; i++) {
            [self output:[_listeningAry ykw_objectAtIndex:i - 1]];
        }
    } else {
        [self output:YKWLocalizedString(@"<No method listening-in>")];
    }
    [self output:@""];
}

- (void)outputCmdIntroduce {
    [self output:YKWLocalizedString(@"<Introduce>")];
    [self output:YKWLocalizedString(@"<Input history:h/H>")];
    [self output:YKWLocalizedString(@"<Add a method listen-in:l/L ClassName Method:Name:>")];
    [self output:YKWLocalizedString(@"<Listening-in method list:l/L>")];
    [self output:YKWLocalizedString(@"<Clear all listen-in:l/L clr>")];
    [self output:YKWLocalizedString(@"<Check last listened objects:k/K")];
    [self output:YKWLocalizedString(@"<KVC read from the N-th last listened object:k/K N Key.Path>")];
    [self output:YKWLocalizedString(@"<Add a to-find string:f/F ToFindString>")];
    [self output:YKWLocalizedString(@"<To-find string list:f/F>")];
    [self output:YKWLocalizedString(@"<Clear all to-find string:f/F clr>")];
    [self output:YKWLocalizedString(@"<Add a regular expression:r/R RegExpression>")];
    [self output:YKWLocalizedString(@"<Reg list:r/R>")];
    [self output:YKWLocalizedString(@"<Clear all regs:r/R clr>")];
    [self output:@""];
}

#pragma mark - Hook
- (void)listenIntoClass:(NSString *)clsStr method:(NSString *)methodStr {
    Class cls = NSClassFromString(clsStr);
    if (!cls) {
        [self output:YKWLocalizedString(@"Listen: Class name error")];
        return;
    }
    SEL selector = NSSelectorFromString(methodStr);
    if (!selector) {
        [self output:YKWLocalizedString(@"Listen: Method name error")];
        return;
    }
    
    NSString *cmdStr = [clsStr stringByAppendingFormat:@" - %@", methodStr];
    
    if ([self isListeningClass:cls selector:selector]) {
        [self output:YKWLocalizedString(@"Listen: The method has been added")];
        return;
    }
    
    if (![cls instancesRespondToSelector:selector]) {
        // if class method, then hook meta-class
        Class mcls = objc_getMetaClass(class_getName(cls));
        if ([mcls instancesRespondToSelector:selector]) {
            cls = mcls;
            cmdStr = [clsStr stringByAppendingFormat:@" + %@", methodStr];
        } else {
            [self output:YKWLocalizedString(@"Listen: The class doesn't response to the method")];
            return;
        }
    }
    
    if (![cls instancesRespondToSelector:@selector(ykwoodpecker_methodSignatureForSelector:)]) {
        if (![self swizzleMethodMethodSignature:cls]) {
            [self output:YKWLocalizedString(@"Listen: Hook methodSignatureForSelector error, failed.")];
            return;
        }
    }
    if (![cls instancesRespondToSelector:@selector(ykwoodpecker_forwardInvocation:)]) {
        if (![self swizzleMethodForwardInvocation:cls]) {
            [self output:YKWLocalizedString(@"Listen: Hook forwardInvocation error, failed")];
            return;
        }
    }
    
    Method method = class_getInstanceMethod(cls, selector);
    IMP imp = method_getImplementation(method);
    char *typeDescription = (char *)method_getTypeEncoding(method);
    
    SEL ykwSelector = NSSelectorFromString([@"ykwoodpecker_" stringByAppendingString:methodStr]);
    class_replaceMethod(cls, ykwSelector, imp, typeDescription);
    class_replaceMethod(cls, selector, _objc_msgForward, typeDescription);
    
    [_listeningAry addObject:cmdStr];
    [self output:YKWLocalizedString(@"Listen: Succeeded")];
}

- (void)clearListen {
    for (NSString *cmdStr in _listeningAry) {
        NSArray *components = [cmdStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        if (components.count == 3) {
            Class cls = NSClassFromString(components.firstObject);
            // if class method
            if ([[components ykw_objectAtIndex:1] isEqualToString:@"+"]) {
                cls = objc_getMetaClass(class_getName(cls));
            }
            // Restore IMP
            SEL selector = NSSelectorFromString(components.lastObject);
            SEL ykwSelector = NSSelectorFromString([@"ykwoodpecker_" stringByAppendingString:components.lastObject]);
            [cls ykwoodpeckerRuntimeSwizzleSelector:selector withSelector:ykwSelector];
        }
    }
    [_listeningAry removeAllObjects];
    [self output:YKWLocalizedString(@"Listen: All listening-in cleared")];
}

- (BOOL)isListeningClass:(Class)cls selector:(SEL)sel {
    NSString *clsStr = NSStringFromClass(cls);
    NSString *selStr = NSStringFromSelector(sel);
    if (!clsStr || !selStr) return NO;
    
    for (NSString *listenStr in _listeningAry) {
        NSArray *components = [listenStr componentsSeparatedByString:@" "];
        if (components.count == 3) {
            if ([selStr isEqualToString:components.lastObject] && ([clsStr isEqualToString:components.firstObject] || [cls isSubclassOfClass:NSClassFromString(components.firstObject)])) {
                return YES;
            }
        }
    }
    return NO;
}

// See more: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
- (void)ykwoodpecker_forwardInvocation:(NSInvocation *)anInvocation {
    if ([[YKWoodpeckerManager sharedInstance].cmdCore isListeningClass:[self class] selector:anInvocation.selector]) {
        [YKWoodpeckerManager sharedInstance].cmdCore.lastCallStackArray = [NSThread callStackSymbols];
        
        NSMutableArray *parasAry = [NSMutableArray array];
        [parasAry addObject:self];
        
        NSInteger paraCount = anInvocation.methodSignature.numberOfArguments;
        NSArray *selParsesAry = [NSStringFromSelector(anInvocation.selector) componentsSeparatedByString:@":"];
        NSMutableArray *logsAry = [NSMutableArray arrayWithCapacity:paraCount];
        [logsAry addObject:[NSString stringWithFormat:@"[%@", NSStringFromClass(self.class)]];
        if (paraCount == 2) {
            NSString *selParse = selParsesAry.lastObject;
            [logsAry addObject:[NSString stringWithFormat:@" %@", selParse]];
        } else {
            for (int i = 2; i < paraCount; i++) {
                NSString *selParse = [selParsesAry ykw_objectAtIndex:i - 2];
                [logsAry addObject:[NSString stringWithFormat:@" %@:", selParse]];
                NSString *paraStr = [YKWCmdCore parseArgumentType:anInvocation index:i parasAry:parasAry];
                if (paraStr) {
                    [logsAry addObject:paraStr];
                }
            }
        }
        [logsAry addObject:@"]"];

        // Invoke original method
        SEL originSel = NSSelectorFromString([@"ykwoodpecker_" stringByAppendingString:NSStringFromSelector(anInvocation.selector)]);
        anInvocation.selector = originSel;
        [anInvocation invokeWithTarget:self];
        
        // Return value
        NSString *returnLog = nil;
        if (anInvocation.methodSignature.methodReturnLength) {
            returnLog = [YKWCmdCore parseArgumentType:anInvocation index:-1 parasAry:parasAry];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Output parameters
            for (int i = 0; i < logsAry.count; i++) {
                if (i == 0 || i == 1 || i%2 == 1) {
                    [[YKWoodpeckerManager sharedInstance].screenLog log:[logsAry ykw_objectAtIndex:i] color:YKWHighlightColor keepLine:YES checkReg:NO checkFind:NO];
                } else {
                    [[YKWoodpeckerManager sharedInstance].screenLog log:[logsAry ykw_objectAtIndex:i] color:nil keepLine:(i<logsAry.count-1) checkReg:YES checkFind:YES];
                }
            }
            [[YKWoodpeckerManager sharedInstance].screenLog log:@"" color:nil keepLine:NO checkReg:NO checkFind:NO];
            // Output return value
            if (returnLog) {
                [[YKWoodpeckerManager sharedInstance].screenLog log:@"Return:" color:YKWHighlightColor keepLine:YES checkReg:NO checkFind:NO];
                [[YKWoodpeckerManager sharedInstance].screenLog log:returnLog color:nil keepLine:NO checkReg:YES checkFind:YES];
            } else {
                [[YKWoodpeckerManager sharedInstance].screenLog log:@"Return Void" color:YKWHighlightColor keepLine:NO checkReg:NO checkFind:NO];
            }
            [[YKWoodpeckerManager sharedInstance].screenLog log:@"" color:nil keepLine:NO checkReg:NO checkFind:NO];
            
            // Trigger post-listening commands
            [YKWoodpeckerManager sharedInstance].cmdCore.hadListenedParas = parasAry;
        });
    } else {
        [self ykwoodpecker_forwardInvocation:anInvocation];
    }
}

+ (NSString *)parseArgumentType:(NSInvocation *)anInvocation index:(NSInteger)i parasAry:(NSMutableArray *)parasAry {
    NSString *paraStr = nil;
    const char *type = NULL;
    if (i < 0) {
        type = anInvocation.methodSignature.methodReturnType;
    } else if (i < anInvocation.methodSignature.numberOfArguments) {
        type = [anInvocation.methodSignature getArgumentTypeAtIndex:i];
    } else {
        return nil;
    }
    if (type == NULL) return nil;
    
    if (strcmp(type, "@") == 0) {
        __unsafe_unretained id para = nil;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%@", [YKWCmdCore checkIfJsonObject:para]];
        if (para) {
            [parasAry addObject:para];
        }
    } else if (strcmp(type, "i") == 0) {
        int para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%d", para];
    } else if (strcmp(type, "l") == 0) {
        long para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%ld", para];
    } else if (strcmp(type, "q") == 0) {
        long long para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%lld", para];
    } else if (strcmp(type, "I") == 0) {
        unsigned int para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%u", para];
    } else if (strcmp(type, "L") == 0) {
        unsigned long para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%lu", para];
    } else if (strcmp(type, "Q") == 0) {
        unsigned long long para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%llu", para];
    } else if (strcmp(type, "f") == 0) {
        float para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%.5f", para];
    } else if (strcmp(type, "d") == 0) {
        double para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%.5f", para];
    } else if (strcmp(type, "B") == 0) {
        bool para = 0;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%d", para];
    } else if (strcmp(type, "#") == 0) {
        Class para = nil;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%@", NSStringFromClass(para)];
    } else if (strcmp(type, ":") == 0) {
        SEL para = nil;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%@", NSStringFromSelector(para)];
    } else if ([[NSString stringWithUTF8String:type] hasPrefix:@"{UIEdgeInsets"]) {
        UIEdgeInsets para;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%@", [NSValue valueWithUIEdgeInsets:para]];
    } else if ([[NSString stringWithUTF8String:type] hasPrefix:@"{CGRect"]) {
        CGRect para;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%@", @(para)];
    } else if ([[NSString stringWithUTF8String:type] hasPrefix:@"{CGSize"]) {
        CGSize para;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%@", @(para)];
    } else if ([[NSString stringWithUTF8String:type] hasPrefix:@"{CGPoint"]) {
        CGPoint para;
        if (i < 0) {
            [anInvocation getReturnValue:&para];
        } else {
            [anInvocation getArgument:&para atIndex:i];
        }
        paraStr = [NSString stringWithFormat:@"%@", @(para)];
    } else {
        paraStr = @"<UnknownType>";
    }
    return paraStr;
}

- (BOOL)swizzleMethodForwardInvocation:(Class)cls  {
    NSString *selectorStr = @"forwardInvocation:";
    SEL selector = NSSelectorFromString(selectorStr);
    
    SEL forwardInvocationSelector = NSSelectorFromString(@"ykwoodpecker_forwardInvocation:");
    BOOL ret1 = ykwoodpeckerRuntimeAddMethod(cls, forwardInvocationSelector, [self class], forwardInvocationSelector);
    BOOL ret2 = ykwoodpeckerRuntimeSwizzleMethod(cls, selector, cls, forwardInvocationSelector);
    return ret1 && ret2;
}

- (NSMethodSignature *)ykwoodpecker_methodSignatureForSelector:(SEL)aSelector {
    if ([[YKWoodpeckerManager sharedInstance].cmdCore isListeningClass:[self class] selector:aSelector]) {
        SEL originSel = NSSelectorFromString([@"ykwoodpecker_" stringByAppendingString:NSStringFromSelector(aSelector)]);
        NSMethodSignature *sig = [self ykwoodpecker_methodSignatureForSelector:originSel];
        if (sig) {
            return sig;
        }
    }
    return [self ykwoodpecker_methodSignatureForSelector:aSelector];
}

- (BOOL)swizzleMethodMethodSignature:(Class)cls  {
    NSString *selectorStr = @"methodSignatureForSelector:";
    SEL selector = NSSelectorFromString(selectorStr);
    
    SEL methodSignatureSelector = NSSelectorFromString(@"ykwoodpecker_methodSignatureForSelector:");
    BOOL ret1 = ykwoodpeckerRuntimeAddMethod(cls, methodSignatureSelector, [self class], methodSignatureSelector);
    BOOL ret2 = ykwoodpeckerRuntimeSwizzleMethod(cls, selector, cls, methodSignatureSelector);
    return ret1 && ret2;
}

#pragma mark - Class method
+ (NSString *)checkIfJsonString:(NSString *)str {
    if ([[YKWoodpeckerManager sharedInstance].cmdCore isListeningClass:[NSJSONSerialization class] selector:@selector(JSONObjectWithData:options:error:)] || [[YKWoodpeckerManager sharedInstance].cmdCore isListeningClass:[NSJSONSerialization class] selector:@selector(dataWithJSONObject:options:error:)]) {
        return str;
    }
    if (str.length) {
        NSError *er = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&er];
        if (!er && jsonObj) {
            er = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:&er];
            if (!er && data) {
                return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
    }
    return str;
}

+ (id)checkIfJsonObject:(id)obj {
    if ([[YKWoodpeckerManager sharedInstance].cmdCore isListeningClass:[NSJSONSerialization class] selector:@selector(dataWithJSONObject:options:error:)]) {
        return obj;
    }
    if (obj && [NSJSONSerialization isValidJSONObject:obj]) {
        NSError *er = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&er];
        if (!er && data) {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return obj;
}

@end
