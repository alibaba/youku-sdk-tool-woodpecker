//
//  ViewController.m
//  YKWoodpeckerDemo
//
//  Created by Zim on 2018/12/28.
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

#import "ViewController.h"
#import "YKWoodpecker.h"
#import "AFNetworking.h"
#import "UIImageView+WebCache.h"
#import "TableViewController.h"

@interface ViewController ()<YKWCmdCoreCmdParseDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"Demo";
    self.view.backgroundColor = [UIColor whiteColor];
 
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"tableView" style:UIBarButtonItemStylePlain target:self action:@selector(pushTableView)];
    
    NSString *iconUrl = @"https://raw.githubusercontent.com/alibaba/youku-sdk-tool-woodpecker/master/woodpecker_logo_icon.png";
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    imageView.center = CGPointMake(self.view.frame.size.width / 2, 100);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView sd_setImageWithURL:[NSURL URLWithString:iconUrl]];
    [self.view addSubview:imageView];
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    btn1.frame = CGRectMake(0, 0, 180, 50);
    btn1.center = CGPointMake(self.view.frame.size.width / 2, 140);
    [btn1 setTitleColor:[UIColor colorWithRed:0.1 green:0.2 blue:0.3 alpha:1.0] forState:UIControlStateNormal];
    [btn1 setTitle:@"啄幕鸟" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(handleBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    btn2.frame = CGRectMake(0, 0, 180, 50);
    btn2.center = CGPointMake(self.view.frame.size.width / 2, 190);
    [btn2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn2 setTitle:@"AF请求配置JSON" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(request) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
    // Receive plugin communication notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessageNotification:)
                                                 name:@"YKWPluginSendMessageNotification" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pushTableView {
    [self.navigationController pushViewController:[TableViewController new] animated:YES];
}

#pragma mark - Actions
/// Open woodpecker
- (void)handleBtn:(id)sender {
    // Specify the command source URL for method-listening-in commands, the commands will loaded automatically after set * Optional, if you don't have your specifications, you can use command sources in https://github.com/ZimWoodpecker/WoodpeckerCmdSource
    [YKWoodpeckerManager sharedInstance].cmdSourceUrl = @"https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerCmdSource/master/cmdSource/default/demo.json";
    
    // It's suggested to open 'safePluginMode' in release mode, so that only safe plugins can be open * Optional
#ifndef DEBUG
    [YKWoodpeckerManager sharedInstance].safePluginMode = YES;
#endif
    
    // Specify a 'parseDelegate' and you can realize custom commands via 'YKWCmdCoreCmdParseDelegate' * Optional
    [YKWoodpeckerManager sharedInstance].cmdCore.parseDelegate = self;
    
    // Show the woodpecker, the 'ViewPicker' plugin will be open on launch.
    [[YKWoodpeckerManager sharedInstance] show];
    
    // Register the crash Handler to log crashed * Optional
    [[YKWoodpeckerManager sharedInstance] registerCrashHandler];

    // Demo for registering a plugin * Optional
    [[YKWoodpeckerManager sharedInstance] registerPluginWithParameters:@{@"pluginName" : @"XXX",
                                                                         @"isSafePlugin" : @(NO),
                                                                         @"pluginInfo" : @"by user_XX",
                                                                         @"pluginCharIconText" : @"x",
                                                                         @"pluginCategoryName" : @"自定义",
                                                                         @"pluginClassName" : @"ClassName"}];
    // You can open a plugin directly for convenience * Optional
//    [[YKWoodpeckerManager sharedInstance] openPluginNamed:@"方法监听"];
}

/// Send an AF request, only for demo method-listening-in.
- (void)request {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 60.0f;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain",@"text/html",nil];
    
    [manager GET:@"https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerCmdSource/master/cmdSource/default/demo.json" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"%@", downloadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}

// Demo for custom commands.
#pragma mark - YKWCmdCoreCmdParseDelegate
- (BOOL)cmdCore:(YKWCmdCore *)core shouldParseCmd:(NSString *)cmdStr {
    if ([cmdStr hasPrefix:@"MyCmd"]) {
        // Custom commands
        // -----------
        // Show log
        [[YKWoodpeckerManager sharedInstance].screenLog log:@"Calling my cmd"];
        return NO;
    }
    return YES;
}

// Demo for plugin communication, see more in YKWPluginProtocol.h
- (void)didReceiveMessageNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSString class]]) {
        if ([notification.object isEqualToString:@"ProbePluginNotification"]) {
            UIView *view = notification.userInfo[@"view"];
            NSString *msg = [NSString stringWithFormat:@"alpha: %f", view.alpha];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"YKWPluginReceiveMessageNotification" object:notification.object userInfo:@{@"msg" : msg}];
        } else if ([notification.object isEqualToString:@"SysInfoPluginNotification"]) {
            NSString *msg = @"我是从业务方发来的信息：\nApp名称: 我是Demo\n用户ID: x_x\n";
            [[NSNotificationCenter defaultCenter] postNotificationName:YKWPluginReceiveMessageNotification object:notification.object userInfo:@{@"msg" : msg}];
        }
    }
}

@end
