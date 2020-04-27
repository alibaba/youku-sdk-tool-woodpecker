//
//  YKWoodpeckerManager.m
//  YKWoodpecker
//
//  Created by Zim on 2018/10/25.
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

#import <objc/runtime.h>
#import "YKWoodpeckerManager.h"
#import "YKWScreenLog.h"
#import "YKWCmdCore.h"
#import "YKWCmdView.h"
#import "YKWoodpeckerMessage.h"
#import "YKWPluginModel.h"
#import "YKWPluginsWindow.h"
#import "YKWPluginProtocol.h"
// For registering crash handler only.
#import "YKWCrashLogPlugin.h"

NSString *const YKWoodpeckerManagerDidLaunchNotification = @"YKWoodpeckerManagerDidLaunchNotification";
NSString *const YKWoodpeckerManagerPluginsDidShowNotification = @"YKWoodpeckerManagerPluginsDidShowNotification";
NSString *const YKWoodpeckerManagerPluginsDidHideNotification = @"YKWoodpeckerManagerPluginsDidHideNotification";
NSString *const YKWPluginSendMessageNotification = @"YKWPluginSendMessageNotification";
NSString *const YKWPluginReceiveMessageNotification = @"YKWPluginReceiveMessageNotification";

@interface YKWoodpeckerManager()<YKWScreenLogDelegate, YKWCmdViewDelegate, YKWCmdCoreOutputDelegate, YKWPluginsWindowDelegate> {
    YKWScreenLog *_screenLog;
    YKWCmdCore *_cmdCore;

    NSMutableArray *_pluginsCategoryArray;
    NSMutableArray *_pluginsArray;
    YKWPluginsWindow *_pluginsEntrance;
}

@property (nonatomic, strong) YKWCmdView *cmdView;

@end

@implementation YKWoodpeckerManager

+ (YKWoodpeckerManager *)sharedInstance {
    static YKWoodpeckerManager *woodpeckerManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        woodpeckerManager = [[self alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:YKWoodpeckerManagerDidLaunchNotification object:nil];
        });
    });
    return woodpeckerManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default command source URL.
        if ([YKWoodpeckerUtils isCnLocaleLanguage]) {
            _cmdSourceUrl = @"https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerCmdSource/master/cmdSource/default/cmds_cn.json";
        } else {
            _cmdSourceUrl = @"https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerCmdSource/master/cmdSource/default/cmds_en.json";
        }
        [self loadPlugins];
    }
    return self;
}

- (void)show {
    if (_pluginsEntrance) {
        [_pluginsEntrance show];
    } else {
        _pluginsEntrance = [[YKWPluginsWindow alloc] initWithFrame:CGRectMake(22, 150, 0, 0)];
        [_pluginsEntrance showWoodpecker];
        _pluginsEntrance.delegate = self;
        _pluginsEntrance.pluginModelArray = _pluginsArray;
        
        if (self.autoOpenUICheckOnShow) {
            [self openPluginNamed:YKWLocalizedString(@"UI Check")];
        }

        [_pluginsEntrance show];
    }
}

- (void)hide {
    [_pluginsEntrance hide];
}

// ------------------- Plugin Management -------------------

- (CGPoint)woodpeckerRestPoint {
    return _pluginsEntrance.frame.origin;
}

- (void)setWoodpeckerRestPoint:(CGPoint)woodpeckerRestPoint {
    if (CGRectContainsPoint(UIEdgeInsetsInsetRect([UIScreen mainScreen].applicationFrame, UIEdgeInsetsMake(20, 20, 20, 20)), woodpeckerRestPoint)) {
        _pluginsEntrance.ykw_left = woodpeckerRestPoint.x;
        _pluginsEntrance.ykw_top = woodpeckerRestPoint.y;
    }
}

- (void)addPluginModel:(YKWPluginModel *)model atIndex:(NSInteger)index {
    if (!_pluginsCategoryArray) {
        _pluginsCategoryArray = [@[YKWLocalizedString(@"Common Tools"), YKWLocalizedString(@"Debug Tools"), YKWLocalizedString(@"UI Tools"), YKWLocalizedString(@"Performance Tools")] mutableCopy];
        _pluginsArray = [NSMutableArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil];
    }
    
    if (model.pluginName.length && !model.pluginOff) {
        if (!model.pluginCategoryName.length) {
            model.pluginCategoryName = YKWLocalizedString(@"Other Tools");
        }
        if (![_pluginsCategoryArray containsObject:model.pluginCategoryName]) {
            [_pluginsCategoryArray addObject:model.pluginCategoryName];
            [_pluginsArray addObject:[NSMutableArray array]];
        }
        NSMutableArray *array = [_pluginsArray ykw_objectAtIndex:[_pluginsCategoryArray indexOfObject:model.pluginCategoryName]];
        if (index >= 0 && index < array.count) {
            [array insertObject:model atIndex:index];
        } else {
            [array addObject:model];
        }
    }
}

- (void)checkAndRemoveEmptyPluginCategory {
    for (int i = 0; i < _pluginsArray.count; i++) {
        if ([[_pluginsArray ykw_objectAtIndex:i] count] == 0) {
            [_pluginsArray removeObjectAtIndex:i];
            if (i >= 0 && i < _pluginsCategoryArray.count) {
                [_pluginsCategoryArray removeObjectAtIndex:i];
            }
            i--;
        }
    }
}

- (void)loadPlugins {
    NSString *bundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
    NSString *path = nil;
    if ([YKWoodpeckerUtils isCnLocaleLanguage]) {
        path = [bundlePath stringByAppendingPathComponent:@"woodpecker_plugin_list_cn.plist"];
    } else {
        path = [bundlePath stringByAppendingPathComponent:@"woodpecker_plugin_list_en.plist"];
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        return;
    }
    
    id obj = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:nil];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *plistDic = [[NSDictionary alloc] initWithContentsOfFile:path];
        YKWPluginModel *model = [[YKWPluginModel alloc] initWithDictionary:plistDic];
        [self addPluginModel:model atIndex:-1];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSArray *plistAry = [[NSArray alloc] initWithContentsOfFile:path];
        for (NSDictionary *dic in plistAry) {
            YKWPluginModel *model = [[YKWPluginModel alloc] initWithDictionary:dic];
            [self addPluginModel:model atIndex:-1];
        }
    }
    [self checkAndRemoveEmptyPluginCategory];
}

- (void)registerPluginWithParameters:(NSDictionary *)parasDic {
    [self registerPluginWithParameters:parasDic atIndex:-1];
}

-(void)registerPluginWithParameters:(NSDictionary *)parasDic atIndex:(NSInteger)index {
    if (parasDic) {
        YKWPluginModel *model = [[YKWPluginModel alloc] initWithDictionary:parasDic];
        if (model.pluginName.length && !model.pluginOff) {
            // Prevent duplicate plugin
            for (NSMutableArray *array in _pluginsArray) {
                for (YKWPluginModel *m in array) {
                    if ([m.pluginName isEqualToString:model.pluginName]) {
                        NSMutableDictionary *allParasDic = [m.registerDictionary mutableCopy];
                        [allParasDic addEntriesFromDictionary:parasDic];
                        model = [[YKWPluginModel alloc] initWithDictionary:allParasDic];
                        [array removeObject:m];
                        break;
                    }
                }
            }
            
            [self addPluginModel:model atIndex:index];
           
            if (_pluginsEntrance) {
                _pluginsEntrance.pluginModelArray = _pluginsArray;
            }
        }
    }
}

- (void)registerPluginCategory:(NSString *)pluginCategoryName atIndex:(NSInteger)index {
    if (!pluginCategoryName.length) return;
    if (![_pluginsCategoryArray containsObject:pluginCategoryName]) {
        [_pluginsCategoryArray addObject:pluginCategoryName];
    }
    NSInteger preIndex = [_pluginsCategoryArray indexOfObject:pluginCategoryName];
    NSMutableArray *pluginsAry = [_pluginsArray ykw_objectAtIndex:preIndex];
    if (!pluginsAry) {
        pluginsAry = [NSMutableArray array];
    }
    
    if (preIndex >=0 && preIndex < _pluginsCategoryArray.count) {
        [_pluginsCategoryArray removeObjectAtIndex:preIndex];
    }
    if (preIndex >=0 && preIndex < _pluginsArray.count) {
        [_pluginsArray removeObjectAtIndex:preIndex];
    }

    if (index >= 0 && index < _pluginsCategoryArray.count) {
        [_pluginsCategoryArray insertObject:pluginCategoryName atIndex:index];
        [_pluginsArray insertObject:pluginsAry atIndex:index];
    } else {
        [_pluginsCategoryArray addObject:pluginCategoryName];
        [_pluginsArray addObject:pluginsAry];
    }
}

- (void)openPluginNamed:(NSString *)pluginName {
    [self openPluginNamed:pluginName withParameters:nil];
}

- (void)openPluginNamed:(NSString *)pluginName withParameters:(NSDictionary *)parasDic {
    // May close other open plugins
    [[NSNotificationCenter defaultCenter] postNotificationName:YKWoodpeckerManagerPluginsDidShowNotification object:nil];
    
    YKWPluginModel *plugin = nil;
    for (NSMutableArray *array in _pluginsArray) {
        for (YKWPluginModel *p in array) {
            if ([p.pluginName isEqualToString:pluginName]) {
                plugin = p;
                break;
            }
        }
    }

    if (plugin) {
        [_pluginsEntrance fold:NO];
        if (parasDic) {
            NSDictionary *previousParas = plugin.pluginParameters;
            NSMutableDictionary *allParas = [NSMutableDictionary dictionary];
            [allParas addEntriesFromDictionary:previousParas];
            [allParas addEntriesFromDictionary:parasDic];
            plugin.pluginParameters = allParas;
            [self pluginsWindow:_pluginsEntrance didSelectPlugin:plugin];
            plugin.pluginParameters = previousParas;
        } else {
            [self pluginsWindow:_pluginsEntrance didSelectPlugin:plugin];
        }
    } else {
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Plugin not found")];
    }
}

#pragma mark - YKWPluginsViewDelegate
- (void)pluginsWindow:(YKWPluginsWindow *)pluginsWindow didSelectPlugin:(YKWPluginModel *)pluginModel {
    if (pluginModel.pluginClassName.length) {
        if (self.safePluginMode && !pluginModel.isSafePlugin) {
            [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Only safe plugins available")];
            return;
        }
        Class pluginClass = NSClassFromString(pluginModel.pluginClassName);
        if (pluginClass) {
            id<YKWPluginProtocol> plugin = [[pluginClass alloc] init];
            if ([plugin respondsToSelector:@selector(runWithParameters:)]) {
                [plugin runWithParameters:pluginModel.pluginParameters];
            } else {
                [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Not conforms to YKWPluginProtocol")];
            }
        } else {
            [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Can't resolve class name")];
        }
    } else {
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Open failed")];
    }
}

// ----------------------------- Crash Plugin -----------------------------

- (void)registerCrashHandler {
    [YKWCrashLogPlugin registerHandler];
}

// ----------------------------- Screen Log -----------------------------

- (void)showLog:(NSString *)logStr {
    if (!self.screenLog.superview) {
        [self.screenLog show];
    }
    [self.screenLog log:logStr];
}

#pragma mark - Getters
- (YKWScreenLog *)screenLog {
    if (!_screenLog) {
        _screenLog = [[YKWScreenLog alloc] init];
    }
    return _screenLog;
}

// ------------------- Method Listening -------------------

- (void)showConsole {
    [self addUndefinedKeyProtection];
    
    self.screenLog.functionButtonTitle = YKWLocalizedString(@"Clear func");
    self.screenLog.delegate = self;
    self.cmdCore.outputDelegate = self;
    self.cmdView.delegate = self;
    
    [self.screenLog show];
    [self.cmdView loadCmd];
    
    if (!self.screenLog.logString.length) {
        // Show the command introduce.
        [self.cmdCore outputCmdIntroduce];
    }
}

#pragma mark - YKWScreenLogDelegate
- (void)screenLog:(YKWScreenLog *)log didInput:(NSString *)inputStr {
    [self.cmdCore parseInput:inputStr];
}

- (void)screenLogDidTapFirstFunction:(YKWScreenLog *)log {
    [self.cmdCore clearFunctions];
    [self.cmdView setCmdOff];
}

- (BOOL)screenLogWillClose:(YKWScreenLog *)log {
    [self.cmdCore clearFunctions];
    [self.cmdView setCmdOff];
    return YES;
}

#pragma mark - YKWCmdCoreOutputDelegate
- (void)cmdCore:(YKWCmdCore *)core didOutput:(NSString *)output {
    [self.screenLog logInfo:output];
}

- (void)cmdCore:(YKWCmdCore *)core didOutput:(NSString *)output color:(UIColor *)color keepLine:(BOOL)keepline checkReg:(BOOL)checkReg checkFind:(BOOL)checkFind {
    [self.screenLog log:output color:color keepLine:keepline checkReg:checkReg checkFind:checkFind];
}

#pragma mark - YKWCmdViewDelegate
- (void)cmdsView:(YKWCmdView *)cmdView didSelectCmd:(YKWCmdModel *)cmdModel {
    [self.cmdCore clearFunctions];
    [self.cmdCore parseCmdModel:cmdModel];
}

- (void)cmdsView:(YKWCmdView *)cmdView didUnSelectCmd:(YKWCmdModel *)cmdModel {
    [self.cmdCore clearFunctions];
}

- (void)cmdsViewDidFinishLoadCmd:(YKWCmdView *)cmdView error:(NSError *)error {
    if (!error && !self.cmdView.superview && [self.screenLog.functionButtonTitle isEqualToString:YKWLocalizedString(@"Clear func")]) {
        [self.screenLog appendView:self.cmdView];
    }
}

#pragma mark - Setters
- (void)setCmdSourceUrl:(NSString *)cmdSourceUrl {
    _cmdSourceUrl = [cmdSourceUrl copy];
    
    self.cmdView.cmdSourceUrl = _cmdSourceUrl;
    [self.cmdView loadCmd];
}

#pragma mark - Getters
- (YKWCmdCore *)cmdCore {
    if (!_cmdCore) {
        _cmdCore = [[YKWCmdCore alloc] init];
        _cmdCore.outputDelegate = self;
    }
    return _cmdCore;
}

- (YKWCmdView *)cmdView {
    if (!_cmdView) {
        _cmdView = [[YKWCmdView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
        _cmdView.cmdSourceUrl = _cmdSourceUrl;
        _cmdView.delegate = self;
    }
    return _cmdView;
}

#pragma mark - For Protection
- (void)addUndefinedKeyProtection {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method method = class_getInstanceMethod(self.class, @selector(valueForUndefinedKey:));
        IMP imp = method_getImplementation(method);
        char *typeDescription = (char *)method_getTypeEncoding(method);
        class_replaceMethod([NSObject class], @selector(valueForUndefinedKey:), imp, typeDescription);
    });
}

- (id)valueForUndefinedKey:(NSString *)key {
    return nil;
}

@end
