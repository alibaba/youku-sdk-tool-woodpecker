//
//  YKWTextViewController.m
//  YKWoodpecker
//
//  Created by Zim on 2019/3/19.
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

#import "YKWTextViewController.h"
#import "YKWoodpeckerCommonHeaders.h"

@interface YKWTextViewController () {
    UITextView *_txtView;
}

@end

@implementation YKWTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:YKWLocalizedString(@"Share") style:UIBarButtonItemStyleDone target:self action:@selector(share)];
    if (!self.title) {
        self.title = @"Text";
    }
    
    _txtView = [[UITextView alloc] init];
    _txtView.frame = self.view.bounds;
    _txtView.backgroundColor = [UIColor whiteColor];
    _txtView.editable = NO;
    _txtView.font = [UIFont systemFontOfSize:14.];
    _txtView.textColor = [UIColor blackColor];
    [self.view addSubview:_txtView];
    
    if (self.content) {
        _txtView.text = self.content;
    } else if (self.contentPath) {
        _txtView.text = [self loadContent];
    }
    _txtView.contentOffset = CGPointZero;
}

- (NSString *)loadContent {
    NSError *er = nil;
    NSString *content = [[NSString alloc] initWithContentsOfFile:self.contentPath usedEncoding:nil error:&er];
    if (!er) {
        return content;
    }
    
    er = nil;
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    content = [[NSString alloc] initWithContentsOfFile:self.contentPath encoding:enc error:&er];
    if (!er) {
        return content;
    }
    
    er = nil;
    for (int i = 1; i <= 30; i++) {
        content = [[NSString alloc] initWithContentsOfFile:self.contentPath encoding:i error:&er];
        if (!er) {
            return content;
        }
    }
    return nil;
}

- (void)share {
    if (self.content) {
        [YKWoodpeckerUtils showShareActivityWithItems:@[self.content]];
    } else if (self.contentPath) {
        NSURL *url = [NSURL fileURLWithPath:self.contentPath isDirectory:NO];
        if (url) {
            [YKWoodpeckerUtils showShareActivityWithItems:@[url]];
        }
    }
}

@end
