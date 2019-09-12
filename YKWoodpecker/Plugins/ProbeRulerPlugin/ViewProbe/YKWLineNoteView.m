//
//  YKWLineNoteView.m
//  YKWoodpecker
//
//  Created by Zim on 2018/11/14.
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

#import "YKWLineNoteView.h"
#import "YKWFollowView.h"

@interface YKWLineNoteView()

@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIView *lineView;

@end

@implementation YKWLineNoteView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.lineView];
        [self addSubview:self.infoLabel];
    }
    return self;
}

- (void)setNote:(NSString *)note {
    _note = note;
    self.infoLabel.text = _note;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.width > self.height) {
        self.lineView.width = self.width;
        self.lineView.height = 1;
    } else {
        self.lineView.width = 1;
        self.lineView.height = self.height;
    }
    self.lineView.center = CGPointMake(self.width / 2, self.height / 2);
    [self.infoLabel sizeToFit];
    self.infoLabel.width += 2;
    self.infoLabel.height -= 2;
    self.infoLabel.center = self.lineView.center;
    if (self.infoLabel.left < 0) {
        self.infoLabel.left = 0;
    }
    if (self.infoLabel.top < 0) {
        self.infoLabel.top = 0;
    }
    if (self.infoLabel.right > self.width) {
        self.infoLabel.right = self.width;
    }
    if (self.infoLabel.bottom > self.height) {
        self.infoLabel.bottom = self.height;
    }
    if (self.left == 0) {
        if (self.infoLabel.left < 0) {
            self.infoLabel.left = 0;
        }
    }
    if (self.top == 0) {
        if (self.infoLabel.top < 0) {
            self.infoLabel.top = 0;
        }
    }
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = YKWHighlightColor;
    }
    return _lineView;
}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.layer.cornerRadius = 2;
        _infoLabel.clipsToBounds = YES;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.backgroundColor = YKWHighlightColor;
        _infoLabel.font = [UIFont systemFontOfSize:8];
        _infoLabel.textColor = YKWForegroudColor;
        _infoLabel.numberOfLines = 1;
    }
    return _infoLabel;
}

@end
