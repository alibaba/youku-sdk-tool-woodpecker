//
//  YKWUIComparePanel.m
//  YKWoodpecker
//
//  Created by Zim on 2019/5/20.
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

#import "YKWUIComparePanel.h"
#import "YKWDrawView.h"
#import "YKWoodpeckerCommonHeaders.h"

@interface YKWUIComparePanel()<UINavigationControllerDelegate,UIImagePickerControllerDelegate> {
    NSMutableArray *_imagesAry;
    
    UIButton *_drawButton;
    YKWDrawView *_drawView;
}

@end

@implementation YKWUIComparePanel

- (instancetype)initWithFrame:(CGRect)frame {
    frame.size.width = [UIApplication sharedApplication].keyWindow.ykw_width - 40.;
    frame.size.height = 45;
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [YKWBackgroudColor colorWithAlphaComponent:0.8];
        _imagesAry = [NSMutableArray array];
        
        UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
        addButton.frame = CGRectMake(0, 0, 40, self.ykw_height);
        addButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:25];
        [addButton setTitle:@"＋" forState:UIControlStateNormal];
        [addButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(add) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:addButton];

        UIButton *delButton = [UIButton buttonWithType:UIButtonTypeCustom];
        delButton.frame = CGRectMake(40, 0, 40, self.ykw_height);
        delButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:25];
        [delButton setTitle:@"﹣" forState:UIControlStateNormal];
        [delButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [delButton addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:delButton];
        
        _drawButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _drawButton.frame = CGRectMake(self.ykw_width - 80, 0, 40, self.ykw_height);
        _drawButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:25];
        [_drawButton setTitle:@"✎" forState:UIControlStateNormal];
        [_drawButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [_drawButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [_drawButton addTarget:self action:@selector(showDraw:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_drawButton];
        
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        clearButton.frame = CGRectMake(self.ykw_width - 45, 0, 40, self.ykw_height);
        clearButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:25];
        [clearButton setTitle:@"↺" forState:UIControlStateNormal];
        [clearButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [clearButton addTarget:self action:@selector(clearDraw) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:clearButton];
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(delButton.ykw_right + 10, 0, _drawButton.ykw_left - delButton.ykw_right - 20, self.ykw_height)];
        slider.minimumValue = 0.1;
        slider.maximumValue = 1.0;
        slider.value = 0.5;
        [slider addTarget:self action:@selector(changeAlpha:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:slider];

        UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        hideButton.frame = CGRectMake(self.ykw_width - 18, -3, 20, 20);
        hideButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:20];
        [hideButton setTitle:@"×" forState:UIControlStateNormal];
        [hideButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [hideButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:hideButton];
    }
    return self;
}

- (void)show {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    self.center = CGPointMake(keyWindow.ykw_width / 2., keyWindow.ykw_height - 50);
    [keyWindow addSubview:self];
}

- (void)hide {
    [_imagesAry makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_imagesAry removeAllObjects];
    [_drawView removeFromSuperview];
    _drawView = nil;
    _drawButton.selected = NO;
    [self removeFromSuperview];
}

- (void)add {
    for (UIView *view in _imagesAry) view.hidden = YES;
    UIImagePickerController *_imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [YKWoodpeckerUtils presentViewControllerOnMainWindow:_imagePickerController];
}

- (void)delete {
    if (_imagesAry.count) {
        UIView *lastView = _imagesAry.lastObject;
        [lastView removeFromSuperview];
        [_imagesAry removeLastObject];
    } else {
        [self hide];
    }
}

- (void)showDraw:(UIButton *)sender {
    if (sender.selected) {
        if (_drawView) {
            _drawView.userInteractionEnabled = NO;
        }
    } else {
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!_drawView) {
            _drawView = [[YKWDrawView alloc] initWithFrame:keyWindow.bounds];
        }
        [keyWindow insertSubview:_drawView belowSubview:self];
        _drawView.userInteractionEnabled = YES;
    }
    sender.selected = !sender.selected;
}

- (void)clearDraw {
    if (_drawView) {
        [_drawView clear];
    }
}

- (void)changeAlpha:(UISlider *)sender {
    UIView *lastView = _imagesAry.lastObject;
    lastView.alpha = sender.value;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    for (UIView *view in _imagesAry) view.hidden = NO;
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if (image) {
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.userInteractionEnabled = NO;
        imageView.ykw_width = image.size.width / [UIScreen mainScreen].scale;
        imageView.ykw_height = image.size.height / [UIScreen mainScreen].scale;
        imageView.center = CGPointMake(keyWindow.ykw_width / 2., keyWindow.ykw_height / 2.);
        imageView.userInteractionEnabled = NO;
        YKWFollowView *followView = [[YKWFollowView alloc] initWithFrame:imageView.frame];
        followView.followWoodpeckerIcon = NO;
        followView.backgroundColor = [UIColor clearColor];
        followView.alpha = 0.5;
        imageView.ykw_left = 0;
        imageView.ykw_top = 0;
        [followView addSubview:imageView];
        if (followView.ykw_width == keyWindow.ykw_width && followView.ykw_height == keyWindow.ykw_height) {
            followView.userInteractionEnabled = NO;
        }
        if (_drawView.window) {
            [keyWindow insertSubview:followView belowSubview:_drawView];
        } else {
            [keyWindow insertSubview:followView belowSubview:self];
        }
        [_imagesAry addObject:followView];
    }
}

@end
