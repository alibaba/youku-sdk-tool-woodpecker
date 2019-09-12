//
//  YKWCmdCore.h
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

#import <Foundation/Foundation.h>

@class YKWCmdCore, YKWCmdModel;

/**
 For custom commands.
 */
@protocol YKWCmdCoreCmdParseDelegate <NSObject>

/**
 If the core should parse the command string.
 */
@optional
- (BOOL)cmdCore:(YKWCmdCore *)core shouldParseCmd:(NSString *)cmdStr;

@end

/**
 For output.
 */
@protocol YKWCmdCoreOutputDelegate <NSObject>

@optional
- (void)cmdCore:(YKWCmdCore *)core didOutput:(NSString *)output;
- (void)cmdCore:(YKWCmdCore *)core didOutput:(NSString *)output color:(UIColor *)color keepLine:(BOOL)keepline checkReg:(BOOL)checkReg checkFind:(BOOL)checkFind;

@end

/**
 Command process.
 */
@interface YKWCmdCore : NSObject

@property (nonatomic, weak) id<YKWCmdCoreOutputDelegate> outputDelegate;
@property (nonatomic, weak) id<YKWCmdCoreCmdParseDelegate> parseDelegate;

/**
 Recently listened objects, [self, ...].
 */
@property (nonatomic, strong) NSMutableArray *hadListenedParas;

/**
 Recently listened call stack.
 */
@property (nonatomic, strong) NSArray *lastCallStackArray;

- (void)parseCmdModel:(YKWCmdModel *)cmdModel;

/**
 Command input

 @param input The command string, different commands can be joined by semicolon.
 */
- (void)parseInput:(NSString *)input;

- (BOOL)isListeningClass:(Class)cls selector:(SEL)sel;

- (void)clearFunctions;

- (void)outputCmdIntroduce;

/**
 Check to output using NSJSONWritingPrettyPrinted
 */
+ (NSString *)checkIfJsonString:(NSString *)str;
+ (id)checkIfJsonObject:(id)obj;

@end
