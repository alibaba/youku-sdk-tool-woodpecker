//
//  YKWCmdCollectionViewCell.m
//  YKWoodpecker
//
//  Created by Zim on 2018/12/16.
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

#import "YKWCmdCollectionViewCell.h"

@interface YKWCmdCollectionViewCell()

@property (nonatomic) UILabel *titleLabel;

@end

@implementation YKWCmdCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = YKWForegroudColor;
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:13];
        self.titleLabel.textColor = YKWBackgroudColor;
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.layer.cornerRadius = 2;
    self.titleLabel.frame = CGRectMake(0, 0, self.width, self.height);
}

- (void)setCmdModel:(YKWCmdModel *)cmdModel {
    _cmdModel = cmdModel;
    self.titleLabel.text = _cmdModel.cmdName;
    if (_cmdModel.isOn) {
        self.titleLabel.textColor = YKWForegroudColor;
        self.backgroundColor = YKWHighlightColor;
    } else {
        self.titleLabel.textColor = YKWBackgroudColor;
        self.backgroundColor = YKWForegroudColor;
    }
}

+ (CGSize)sizeForCmdModel:(YKWCmdModel *)cmdModel {
    if (cmdModel.cmdName.length == 0) {
        return CGSizeZero;
    }
    CGSize maxSize = CGSizeMake(MAXFLOAT, 20);
    CGSize textSize = [cmdModel.cmdName boundingRectWithSize:maxSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13.0]}
                                                     context:nil].size;
    textSize.width += 20;
    return textSize;
}

@end
