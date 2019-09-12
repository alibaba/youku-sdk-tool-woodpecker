//
//  YKWPluginProtocol.h
//  YKWoodpecker
//
//  Created by Zim on 2019/3/7.
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

@protocol YKWPluginProtocol <NSObject>

/**
 Run the plugin.

 @param paraDic The plugin's pluginParameters.
 */
- (void)runWithParameters:(NSDictionary *)paraDic;

@end

// Plugin outside communication notifications.
extern NSString *const YKWPluginSendMessageNotification; /**< Plugin sending notification = @"YKWPluginSendMessageNotification" */
extern NSString *const YKWPluginReceiveMessageNotification; /**< Plugin receiving notification = @"YKWPluginReceiveMessageNotification" */
/*
 UI Check plugin - View Picker:
 Sending Format:
    notification.object = @"ProbePluginNotification";
    notification.userInfo[@"view"] = the UIView picked;
 Receiving Format:
    notification.object = @"ProbePluginNotification";
    notification.userInfo[@"msg"] = message to show;
 
 System Info plugin:
 Sending Format:
    notification.object = @"SysInfoPluginNotification";
 Receiving Format:
    notification.object = @"SysInfoPluginNotification";
    notification.userInfo[@"msg"] = message to show;
*/
