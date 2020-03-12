//
//  YKWScreenLog.h
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

#import "YKWFollowView.h"

@class YKWScreenLog;
@protocol YKWScreenLogDelegate <NSObject>

@optional
- (void)screenLog:(YKWScreenLog *)log didInput:(NSString *)inputStr;
- (void)screenLogDidTapFirstFunction:(YKWScreenLog *)log;
- (BOOL)screenLogWillClose:(YKWScreenLog *)log;

@end

@interface YKWScreenLog : YKWFollowView

@property (nonatomic, weak) id<YKWScreenLogDelegate> delegate;

@property (nonatomic, readonly) NSString *logString;

/**
 Whether the view is resizeable, default is YES.
 */
@property (nonatomic, assign) BOOL resizeable;

/**
 Show log or hide log, default is YES.
 */
@property (nonatomic, assign) BOOL showLog;

/**
 Whether inputable, default is YES.
 */
@property (nonatomic, assign) BOOL inputable;

/**
 Whether parse commands, default is YES.
 */
@property (nonatomic, assign) BOOL parseCommands;

/**
 The filtering regular expressions array.
 */
@property (nonatomic, strong) NSMutableArray *regExpressionAry;

/**
 The filtering to-find strings array.
 */
@property (nonatomic, strong) NSMutableArray *toFindStringAry;

/**
 The title for the function button.
 */
@property (nonatomic, copy) NSString *functionButtonTitle;

/**
 Equal to [self log:logStr color:[UIColor WhiteColor] keepLine:NO checkReg:NO checkFind:NO].
 */
- (void)log:(NSString *)logStr;

/**
 Equal to [self log:logStr color:COLOR(0x999999) keepLine:NO checkReg:NO checkFind:NO].
 */
- (void)logInfo:(NSString *)logStr;

/**
 Show log.

 @param logStr The log string.
 @param color The log's color.
 @param keepline If keep the line at the end.
 @param checkReg If filter the log with the regular expressions in 'regExpressionAry'.
 @param checkFind If filter the log with the to-find strings in 'toFindStringAry'.
 */
- (void)log:(NSString *)logStr color:(UIColor *)color keepLine:(BOOL)keepline checkReg:(BOOL)checkReg checkFind:(BOOL)checkFind;

/**
 Append a view at the bottom.

 @param view The view to add, whose width will be set to the screen log's width.
 */
- (void)appendView:(UIView *)view;

/**
 Try to parse a screen log command.

 @param cmdStr the command string.
 @return success or not.
 */
- (BOOL)parseCommandString:(NSString *)cmdStr;

/**
 Add a regular expression as filter.

 @param regStr a regular expression.
 */
- (void)addRegExpression:(NSString *)regStr;

/**
 Clear all filtering regular expression.
 */
- (void)clearRegExpression;

/**
 Print all filtering regular expression.
 */
- (void)printRegExpression;

/**
 Add a to-find string as filter.

 @param findStr a to-find string.
 */
- (void)addToFindString:(NSString *)findStr;

/**
 Clear all filtering to-find string.
 */
- (void)clearToFindString;

/**
 Print all filtering to-find string.
 */
- (void)printToFindString;

/**
 Print the input history.
 */
- (void)printInputHistory;

/**
 Save input history.

 @param input input
 */
- (void)saveInputToHistory:(NSString *)input;

- (void)show;
- (void)hide;

@end
