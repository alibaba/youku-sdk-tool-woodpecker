//
//  YKWoodpeckerMessage.h
//  YKWoodpecker
//
//  Created by Zim on 2018/11/19.
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

#import <UIKit/UIKit.h>

/**
 Show messages.
 */
@interface YKWoodpeckerMessage : UILabel

/**
 Show a message for 2 seconds.

 @param msg The message to show.
 */
+ (void)showMessage:(NSString *)msg;

/**
 Show a message.

 @param msg The message to show.
 @param interval Time interval.
 */
+ (void)showMessage:(NSString *)msg duration:(NSTimeInterval)interval;

/**
 Show a message.

 @param msg The message to show.
 @param interval Time interval.
 @param view The view on which to show the message, which will be 'appWindow' if nil.
 @param postion The position to show the message, which will be center if 'view' is nil.
 */
+ (void)showMessage:(NSString *)msg duration:(NSTimeInterval)interval inView:(UIView *)view position:(CGPoint)postion;

/**
 Show an activity message.
 
 @param msg The activity message.
 */
+ (void)showActivityMessage:(NSString *)msg;

/**
 Hide activity messages.
 */
+ (void)hideActivityMessage;

@end
