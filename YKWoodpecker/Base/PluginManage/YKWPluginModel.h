//
//  YKWPluginModel.h
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

#import <Foundation/Foundation.h>

@interface YKWPluginModel : NSObject

// The property name is the key in the dictionary, except 'pluginIcon' will be automatically read using 'pluginIconName'.
@property (nonatomic, assign) BOOL pluginOff;                   // If the plugin is off，default is NO.
@property (nonatomic, assign) BOOL isSafePlugin;                // If it's a safe plugin which can be open in safe mode, default is NO.

@property (nonatomic, copy) NSString *pluginName;               // The plugin's name, required.
@property (nonatomic, copy) NSString *pluginCategoryName;       // The plugin's category name.
@property (nonatomic, copy) NSString *pluginInfo;               // The plugin's information, such as author etc. The information will show by a long-press on the plugin's icon.

@property (nonatomic, copy) NSString *pluginIconName;           // The plugin's icon image name.
@property (nonatomic, strong) UIImage *pluginIcon;              // The plugin's icon, you don't need to specify this property.
@property (nonatomic, copy) NSString *pluginCharIconText;       // Specify a char as the plugin's icon. Suggested.
@property (nonatomic, copy) NSString *pluginCharIconColorHex;   // Specify the char's color, for example @"0xFFFFFF".

@property (nonatomic, copy) NSString *pluginClassName;          // The plugin's class name, it must conform to YKWPluginProtocol.
@property (nonatomic, copy) NSDictionary *pluginParameters;     // The plugin's parameters to run with.

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
