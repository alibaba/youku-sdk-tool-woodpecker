//
//  YKWPluginModel.m
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

#import "YKWPluginModel.h"
#import "YKWoodpeckerCommonHeaders.h"

@implementation YKWPluginModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self && [dictionary isKindOfClass:[NSDictionary class]]) {
        self.pluginOff = [[dictionary objectForKey:@"pluginOff"] boolValue];
        self.isSafePlugin = [[dictionary objectForKey:@"isSafePlugin"] boolValue];
        self.pluginName = [dictionary objectForKey:@"pluginName"];
        self.pluginInfo = [dictionary objectForKey:@"pluginInfo"];
        self.pluginIconName = [dictionary objectForKey:@"pluginIconName"];
        self.pluginCharIconText = [dictionary objectForKey:@"pluginCharIconText"];
        self.pluginCharIconColorHex = [dictionary objectForKey:@"pluginCharIconColorHex"];
        if (self.pluginIconName.length) {
            self.pluginIcon = [UIImage imageNamed:self.pluginIconName];
        } else {
            self.pluginIcon = [UIImage ykw_iconImageFromString:self.pluginCharIconText textColor:self.pluginCharIconColorHex size:CGSizeMake(40., 40.)];
        }
        
        self.pluginCategoryName = [dictionary objectForKey:@"pluginCategoryName"];
        
        self.pluginClassName = [dictionary objectForKey:@"pluginClassName"];
        self.pluginParameters = [dictionary objectForKey:@"pluginParameters"];
        
        self.pluginBagdeInfo = [dictionary objectForKey:@"pluginBagdeInfo"];

        self.registerDictionary = dictionary;
    }
    return self;
}

@end
