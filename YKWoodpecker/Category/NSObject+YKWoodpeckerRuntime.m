//
//  NSObject+YKWoodpeckerRuntime.m
//  YKWoodpecker
//
//  Created by Zim on 2018/12/18.
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

#import "NSObject+YKWoodpeckerRuntime.h"
#import <objc/runtime.h>

@implementation NSObject(YKWoodpeckerRuntime)

bool ykwoodpeckerRuntimeAddMethod(Class toClass, SEL selector, Class impClass, SEL impSelector) {
    Method impMethod = class_getInstanceMethod(impClass, impSelector);
    if (!impMethod) return false;
    return class_addMethod(toClass, selector, method_getImplementation(impMethod), method_getTypeEncoding(impMethod));
}

bool ykwoodpeckerRuntimeSwizzleMethod(Class class1, SEL selector1, Class class2, SEL selector2) {
    Method method1 = class_getInstanceMethod(class1, selector1);
    Method method2 = class_getInstanceMethod(class2, selector2);
    
    class_replaceMethod(class1, selector1, method_getImplementation(method2), method_getTypeEncoding(method2));
    class_replaceMethod(class2, selector2, method_getImplementation(method1), method_getTypeEncoding(method1));
     return true;
}

+ (BOOL)ykwoodpeckerRuntimeSwizzleSelector:(SEL)selector1 withSelector:(SEL)selector2 {
    Method method1 = class_getInstanceMethod([self class], selector1);
    Method method2 = class_getInstanceMethod([self class], selector2);
    if (method1 && method2) {
        method_exchangeImplementations(method1, method2);
        return YES;
    }
    return NO;
}

@end
