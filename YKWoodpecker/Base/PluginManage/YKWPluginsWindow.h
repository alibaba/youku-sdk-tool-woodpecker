//
//  YKWPluginsWindow.h
//  YKWoodpecker
//
//  Created by Zim on 2019/3/5.
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

#import "YKWFollowView.h"
#import "YKWPluginModel.h"

@class YKWPluginsWindow;
@protocol YKWPluginsWindowDelegate <NSObject>

@optional
- (void)pluginsWindow:(YKWPluginsWindow *)pluginsWindow didSelectPlugin:(YKWPluginModel *)pluginModel;

@end

@interface YKWPluginsWindow : UIWindow

@property (nonatomic, copy) NSArray<NSArray<YKWPluginModel *> *> *pluginModelArray;

@property (nonatomic, weak) id<YKWPluginsWindowDelegate> delegate;

/**
 Show the woodpecker icon.
 */
- (void)showWoodpecker;

- (void)show;
- (void)hide;

- (void)fold:(BOOL)animated;
- (void)unfold:(BOOL)animated;

@end
