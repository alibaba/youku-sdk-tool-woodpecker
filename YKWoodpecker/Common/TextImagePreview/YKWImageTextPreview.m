//
//  YKWImageTextPreview.m
//  YKWoodpecker
//
//  Created by Zim on 2018/11/13.
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

#import "YKWImageTextPreview.h"
#import "YKWoodpeckerMessage.h"

@interface YKWImageTextPreview() {
    UIImageView *_imageView;
    UITextView *_txtView;
    UILabel *_infoLabel;
}

@end

@implementation YKWImageTextPreview

- (instancetype)initWithFrame:(CGRect)frame {
    frame = CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height);
    self = [super initWithFrame:frame];
    if (self) {
        float random = (arc4random() % 100)/100.;
        self.backgroundColor = [UIColor colorWithWhite:random alpha:1.0];
    
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.frame = CGRectMake(20, 70, self.width - 40, self.height - 90);
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _imageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        _imageView.userInteractionEnabled = NO;
        [self addSubview:_imageView];
        
        _txtView = [[UITextView alloc] init];
        _txtView.frame = _imageView.frame;
        _txtView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _txtView.backgroundColor = [UIColor blackColor];
        _txtView.editable = NO;
        _txtView.font = [UIFont systemFontOfSize:12.];
        _txtView.textColor = [UIColor whiteColor];
        [self addSubview:_txtView];
        
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTap:)];
        [self addGestureRecognizer:tapGes];
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.backgroundColor = [UIColor blackColor];
        closeBtn.frame = CGRectMake(20, 40, 60, 30);
        closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        [closeBtn setTitle:@"╳" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:closeBtn];
        
        UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        shareBtn.backgroundColor = [UIColor blackColor];
        shareBtn.frame = CGRectMake(self.width - 80, 40, 60, 30);
        shareBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        [shareBtn setTitle:YKWLocalizedString(@"Share") forState:UIControlStateNormal];
        [shareBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [shareBtn addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:shareBtn];
        
        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(closeBtn.right, 40, shareBtn.left - closeBtn.right, 30)];
        _infoLabel.textColor = [UIColor colorWithWhite:random > 0.5 ? 0:1 alpha:1.0];
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _infoLabel.font = [UIFont systemFontOfSize:14];
        _infoLabel.numberOfLines = 3;
        _infoLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_infoLabel];
    }
    return self;
}

- (NSString *)loadTextWithUrl:(NSString *)url {
    NSError *er = nil;
    NSString *content = [[NSString alloc] initWithContentsOfFile:url usedEncoding:nil error:&er];
    if (!er) {
        return content;
    }
    
    er = nil;
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    content = [[NSString alloc] initWithContentsOfFile:url encoding:enc error:&er];
    if (!er) {
        return content;
    }
    
    er = nil;
    for (int i = 1; i <= 30; i++) {
        content = [[NSString alloc] initWithContentsOfFile:url encoding:i error:&er];
        if (!er) {
            return content;
        }
    }
    return [@"Failed to load " stringByAppendingString:url];
}

- (void)share {
    NSArray *array = nil;
    if (self.text.length) {
        array = @[self.text];
    } else if (self.image) {
        array = @[self.image];
    } else if (self.sourceImageView.image) {
        array = @[self.sourceImageView.image];
    } else if (self.sourceImageView.animationImages.count) {
        array = self.sourceImageView.animationImages;
    }
    if (array) {
        [YKWoodpeckerUtils showShareActivityWithItems:array];
    }
}

- (void)viewTap:(id)sender {
    [self hide];
}

- (void)show {
    NSString *info = nil;
    if (self.sourceImageView) {
        _imageView.hidden = NO;
        _txtView.hidden = YES;
        
        _image = self.sourceImageView.image;
        _imageView.image = _image;
        _imageView.highlightedImage = self.sourceImageView.highlightedImage;
        _imageView.animationImages = self.sourceImageView.animationImages;
        _imageView.highlightedAnimationImages = self.sourceImageView.highlightedAnimationImages;
        _imageView.highlighted = self.sourceImageView.highlighted;
        _imageView.animationDuration = self.sourceImageView.animationDuration;
        if (_imageView.animationImages.count) {
            [_imageView startAnimating];
        }
    } else if (self.image) {
        _imageView.hidden = NO;
        _txtView.hidden = YES;
        _imageView.image = self.image;
    } else if (self.text.length) {
        _imageView.hidden = YES;
        _txtView.hidden = NO;
        _txtView.text = self.text;
    } else if (self.textUrl.length) {
        _imageView.hidden = YES;
        _txtView.hidden = NO;
        _txtView.text = [@"Loading " stringByAppendingString:self.textUrl];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.text = [self loadTextWithUrl:self.textUrl];
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_txtView.text = self.text;
            });
        });
    } else {
        [YKWoodpeckerMessage showMessage:@"No content"];
        return;
    }
    
    if (_image) {
        info = [NSString stringWithFormat:@"%@%@: w%.1f h%.1f @scale%.1f",YKWLocalizedString(@"Image"), YKWLocalizedString(@"Size"), _image.size.width, _image.size.height, _image.scale];
    } else if (self.textUrl.length) {
        info = self.textUrl;
    }
    _infoLabel.text = info;
    
    self.alpha = 0.0;
    if ([UIApplication sharedApplication].keyWindow.rootViewController) {
        [[UIApplication sharedApplication].keyWindow addSubview:self];
    } else {
        [[UIApplication sharedApplication].windows.firstObject addSubview:self];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        [[YKWoodpeckerManager sharedInstance] hide];
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [[YKWoodpeckerManager sharedInstance] show];
    }];
}

@end
