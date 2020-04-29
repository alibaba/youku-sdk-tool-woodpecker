//
//  YKWJSONGrabManager.m
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

#import "YKWJSONGrabManager.h"
#import "YKWObjcMethodHook.h"
#import "YKWScreenLog.h"
#import "YKWoodpeckerMessage.h"

@interface YKWJSONGrabManager()<YKWObjcMethodHookDelegate, UITableViewDelegate, UITableViewDataSource> {
    YKWFollowView *_contentView;
    UITableView *_tableView;
    NSMutableArray *_jsonsAry;
}

@end

@implementation YKWJSONGrabManager

+ (YKWJSONGrabManager *)sharedInstance {
    static YKWJSONGrabManager *grabManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        grabManager = [[self alloc] init];
    });
    return grabManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _jsonsAry = [NSMutableArray array];
        
        _contentView = [[YKWFollowView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
        _contentView.backgroundColor = [YKWBackgroudColor colorWithAlphaComponent:0.9];
        
        _tableView = [[UITableView alloc] initWithFrame:_contentView.bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorInset = UIEdgeInsetsZero;
        _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        [_contentView addSubview:_tableView];

        [_tableView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)]];

        UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        hideButton.backgroundColor = [UIColor clearColor];
        hideButton.frame = CGRectMake(_contentView.ykw_width - 30, -12, 40, 40);
        hideButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:25];
        [hideButton setTitle:@"×" forState:UIControlStateNormal];
        [hideButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [hideButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:hideButton];
        
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        clearButton.backgroundColor = [UIColor clearColor];
        clearButton.frame = CGRectMake(_contentView.ykw_width - 30, _contentView.ykw_height - 32, 40, 40);
        clearButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:25];
        [clearButton setTitle:@"☒" forState:UIControlStateNormal];
        [clearButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [clearButton addTarget:self action:@selector(clear) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:clearButton];
        
        _methodHook = [[YKWObjcMethodHook alloc] init];
        _methodHook.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyWindowDidChange)
                                                     name:UIWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hide)
                                                     name:YKWoodpeckerManagerPluginsDidShowNotification object:nil];
    }
    return self;
}

- (void)keyWindowDidChange {
    if (_contentView.superview && _contentView.window != [UIApplication sharedApplication].keyWindow) {
        [self show];
    }
}

- (void)show {
    [self beginJsonGrab];

    _contentView.alpha = 0.0;
    CGRect frame = _contentView.frame;
    frame.origin = [YKWoodpeckerManager sharedInstance].woodpeckerRestPoint;
    _contentView.frame = frame;
    [[UIApplication sharedApplication].keyWindow addSubview:_contentView];
    [UIView animateWithDuration:0.2 animations:^{
        self->_contentView.alpha = 1.0;
    } completion:^(BOOL finished) {

    }];
}

- (void)hide {
    [self stopJsonGrab];
    [UIView animateWithDuration:0.2 animations:^{
        self->_contentView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self->_contentView removeFromSuperview];
    }];
}

- (void)clear {
    [_jsonsAry removeAllObjects];
    [_tableView reloadData];
}

- (void)beginJsonGrab {
    if (![_methodHook isListeningClass:[NSJSONSerialization class] selector:@selector(dataWithJSONObject:options:error:)]) {
        [_methodHook parseCommand:@"l NSJSONSerialization JSONObjectWithData:options:error:"];
    }
}

- (void)stopJsonGrab {
    [_methodHook clearFunctions];
}

#pragma mark - YKWObjcMethodHookDelegate
- (void)objcMethodHook:(YKWObjcMethodHook *)core didOutput:(NSString *)output {
    if (!output.length) {
        if ([[_methodHook.hadListenedParas ykw_objectAtIndex:1] isKindOfClass:[NSData class]]) {
            NSData *jsonData = [_methodHook.hadListenedParas ykw_objectAtIndex:1];
            if (jsonData) {
                NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                
                if (jsonStr) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->_jsonsAry addObject:jsonStr];
                        [self->_tableView reloadData];
                    });
                }
            }
        }
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_jsonsAry.count) {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"YKWJSONGrabManagerTip"]) {
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"YKWJSONGrabManagerTip"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Long press to share") duration:5.];
        }
    }
    return _jsonsAry.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = YKWForegroudColor;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.numberOfLines = 3;

    NSString *json = [_jsonsAry ykw_objectAtIndex:indexPath.row];
    NSInteger length = json.length;
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"[length: %ld]", (long)length] attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12], NSForegroundColorAttributeName : [YKWHighlightColor colorWithAlphaComponent:0.6 + length / 10000.]}];
    if (length > 300) {
        json = [json substringToIndex:300];
    }
    json = [[json stringByReplacingOccurrencesOfString:@"\n" withString:@" "] stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
    NSAttributedString *str1 = [[NSAttributedString alloc] initWithString:json attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12], NSForegroundColorAttributeName : YKWForegroudColor}];
    [str appendAttributedString:str1];
    cell.textLabel.attributedText = str;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *json = [_jsonsAry ykw_objectAtIndex:indexPath.row];
    if (json.length) {
        _methodHook.disableHook = YES;
        NSError *er = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&er];
        if (!er && jsonObj) {
            er = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:&er];
            if (!er && data) {
                json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
        _methodHook.disableHook = NO;
    }
    
    YKWScreenLog *log = [[YKWScreenLog alloc] init];
    log.inputable = NO;
    [log log:json];
    [log show];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:_tableView];
        NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:point];
        NSString *json = [_jsonsAry ykw_objectAtIndex:indexPath.row];
        [YKWoodpeckerUtils showShareActivityWithItems:@[json]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
