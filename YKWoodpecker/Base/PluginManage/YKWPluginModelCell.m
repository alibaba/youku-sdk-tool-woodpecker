//
//  YKWPluginModelCell.m
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

#import "YKWPluginModelCell.h"
#import "YKWoodpeckerMessage.h"
#import "YKWoodpeckerCommonHeaders.h"
#import "UIView+YKWoodpeckerAdditions.h"

@interface YKWPluginModelCell()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation YKWPluginModelCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 2.;
        [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)]];
        
        self.iconImageView = [[UIImageView alloc] init];
        self.iconImageView.backgroundColor = [UIColor whiteColor];
        self.iconImageView.clipsToBounds = YES;
        self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.iconImageView.layer.borderColor = [UIColor greenColor].CGColor;
        [self.contentView addSubview:self.iconImageView];
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:[YKWoodpeckerUtils isCnLocaleLanguage] ? 12. : 11.];
        self.nameLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.nameLabel];
        
        self.badgeLabel = [[UILabel alloc] init];
        self.badgeLabel.backgroundColor = [UIColor.redColor colorWithAlphaComponent:0.9];
        self.badgeLabel.textAlignment = NSTextAlignmentCenter;
        self.badgeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.badgeLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:9.];
        self.badgeLabel.textColor = [UIColor whiteColor];
        self.badgeLabel.clipsToBounds = YES;
        self.badgeLabel.layer.cornerRadius = 2;
        [self.contentView addSubview:self.badgeLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.iconImageView.ykw_width = 40.;
    self.iconImageView.ykw_height = self.iconImageView.ykw_width;
    self.iconImageView.ykw_top = 5;
    self.iconImageView.ykw_centerX = self.ykw_width / 2.;
    self.iconImageView.layer.cornerRadius = self.iconImageView.ykw_width / 2.;

    self.nameLabel.ykw_width = self.ykw_width;
    self.nameLabel.ykw_height = 15.;
    self.nameLabel.ykw_top = self.iconImageView.ykw_bottom + 5.;
    self.nameLabel.ykw_centerX = self.ykw_width / 2.;
    
    [self.badgeLabel sizeToFit];
    self.badgeLabel.ykw_width += 3;
    self.badgeLabel.ykw_height += 2;
    if (self.badgeLabel.ykw_width > 50) {
        self.badgeLabel.ykw_width = 50;
    }
    self.badgeLabel.ykw_top = 0;
    self.badgeLabel.ykw_right = self.ykw_width;
}

- (void)setPluginModel:(YKWPluginModel *)pluginModel {
    _pluginModel = pluginModel;
    self.iconImageView.image = _pluginModel.pluginIcon;
    self.nameLabel.text = _pluginModel.pluginName;
    self.badgeLabel.text = _pluginModel.pluginBagdeInfo;
    self.badgeLabel.hidden = self.badgeLabel.text.length == 0;
    
    if ([YKWoodpeckerManager sharedInstance].safePluginMode && _pluginModel.isSafePlugin) {
        self.iconImageView.layer.borderWidth = 2. / [UIScreen mainScreen].scale;
    } else {
        self.iconImageView.layer.borderWidth = 0.;
    }
    
    [self setNeedsLayout];
}

- (void)handleLongPress:(id)sender {
    if (self.pluginModel.pluginInfo.length) {
        [YKWoodpeckerMessage showMessage:self.pluginModel.pluginInfo duration:(3.0 + self.pluginModel.pluginInfo.length / 10) inView:self.superview.superview.superview position:CGPointMake(self.superview.superview.superview.ykw_width / 2., -35. - self.pluginModel.pluginInfo.length)];
    } else {
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"No plugin info") duration:2.0 inView:self.superview.superview.superview position:CGPointMake(self.superview.superview.superview.ykw_width / 2, -35.)];
    }
}

+ (CGSize)cellSizeForModel:(YKWPluginModel *)pluginModel {
    return CGSizeMake(60., 70.);
}

@end
