//
//  YKWObjcMethodHook.h
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

#import <Foundation/Foundation.h>

/**
 For output.
 */
@class YKWObjcMethodHook;
@protocol YKWObjcMethodHookDelegate <NSObject>

@optional
- (void)objcMethodHook:(YKWObjcMethodHook *)core didOutput:(NSString *)output;

@end

@interface YKWObjcMethodHook : NSObject

@property (nonatomic, weak) id<YKWObjcMethodHookDelegate> delegate;

@property (nonatomic) BOOL disableHook;

@property (nonatomic) NSMutableArray *hadListenedParas;

- (void)parseCommand:(NSString *)cmdStr;

- (BOOL)isListeningClass:(Class)cls selector:(SEL)sel;

- (void)clearFunctions;

@end
