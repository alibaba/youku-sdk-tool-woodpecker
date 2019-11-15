//
//  YKWObjcMethodHook.m
//  YKWoodpecker
//
//  Created by Zim on 2019/11/15.
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

#import "YKWObjcMethodHook.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "YKWJSONGrabManager.h"

@interface YKWObjcMethodHook() {
    NSMutableArray *_listeningAry;      // @"Class -/+ method:para:"
    NSMutableArray *_postListenCmdAry;  // Commands that run after a listen-in
}

@end

@implementation YKWObjcMethodHook

- (instancetype)init {
    self = [super init];
    if (self) {
        _listeningAry = [NSMutableArray array];
        _postListenCmdAry = [NSMutableArray array];
    }
    return self;
}

- (void)output:(NSString *)str {
    if (self.delegate && [self.delegate respondsToSelector:@selector(objcMethodHook:didOutput:)]) {
        [self.delegate objcMethodHook:self didOutput:str];
    }
}

- (void)clearFunctions {
    [self clearListen];
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
    [self output:@""];
}

- (BOOL)checkIfAddToPostListenCmd:(NSString *)cmdStr {
    // Post commands, such as k command.
    if ([cmdStr hasPrefix:@"k"] || [cmdStr hasPrefix:@"K"]) {
        [_postListenCmdAry addObject:cmdStr];
        return YES;
    }
    return NO;
}

- (void)parseCommand:(NSString *)cmdStr {
    NSArray *components = [self parseComponents:cmdStr usingSeparator:@";"];
    for (NSString *inputLine in components) {
        [self parseCmd:inputLine];
    }
}

- (void)parseCmd:(NSString *)cmdStr {
    NSArray *components = [self parseComponents:cmdStr usingSeparator:@" "];

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
            } else {
                [self output:YKWLocalizedString(@"Input format error")];
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
                [self.hadListenedParas addObject:keyObj];
            } else {
                [self output:YKWLocalizedString(@"Can't find object")];
            }
        } else {
            [self output:YKWLocalizedString(@"Can't find object")];
        }
    } else if ([cmdStr hasPrefix:@"p"] || [cmdStr hasPrefix:@"P"]) { // p command
        if ([components.firstObject length] == 1) {
            if (components.count == 2 && [components.lastObject isEqualToString:@"clr"]) {
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

- (void)ykwoodpecker_forwardInvocation:(NSInvocation *)anInvocation {
    if ([[YKWJSONGrabManager sharedInstance].methodHook isListeningClass:[self class] selector:anInvocation.selector]) {
        // Invoke original method
        SEL originSel = NSSelectorFromString([@"ykwoodpecker_" stringByAppendingString:NSStringFromSelector(anInvocation.selector)]);
        anInvocation.selector = originSel;
        [anInvocation invokeWithTarget:self];
        
        if ([YKWJSONGrabManager sharedInstance].methodHook.disableHook) {
            return;
        }
        
        NSMutableArray *parasAry = [NSMutableArray array];
        [parasAry addObject:self];
        
        NSInteger paraCount = anInvocation.methodSignature.numberOfArguments;
        
        for (int i = 2; i < paraCount; i++) {
            [YKWObjcMethodHook parseArgumentType:anInvocation index:i parasAry:parasAry];
        }
        
        // Return value
        NSString *returnLog = nil;
        if (anInvocation.methodSignature.methodReturnLength) {
            returnLog = [YKWObjcMethodHook parseArgumentType:anInvocation index:-1 parasAry:parasAry];
        }
        
        [YKWJSONGrabManager sharedInstance].methodHook.hadListenedParas = parasAry;
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
        paraStr = [NSString stringWithFormat:@"%@", para];
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
    if ([[YKWJSONGrabManager sharedInstance].methodHook isListeningClass:[self class] selector:aSelector]) {
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

@end
