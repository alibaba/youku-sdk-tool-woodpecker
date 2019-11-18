//
//  YKWPanelView.m
//  YKWoodpecker
//
//  Created by Zim on 2018/12/20.
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

#import "YKWPanelView.h"
#import "YKWRulerTool.h"
#import "YKWProbeView.h"
#import "YKWoodpeckerMessage.h"
#import "YKWImageTextPreview.h"
#import "YKWObjectProbeView.h"
#import "YKWoodpeckerManager.h"

#define YKWPanelViewHeight 36
#define YKWPanelViewFont ([YKWoodpeckerUtils isCnLocaleLanguage] ? 14 : 12)

@interface YKWPanelView()<YKWProbeViewDelegate, YKWObjectProbeViewDelegate> {
    UIView *_contentView;
    
    UIButton *_rulerBtn;
    UIButton *_probeBtn;
    
    UIView *_probeFuncView;
    UIButton *_probeFuncBtn1;
    UIButton *_probeFuncBtn2;
    UIButton *_probeFuncBtn3;
    
    UILabel *_infoLabel;
    
    YKWRulerTool *_rulerTool;
    YKWProbeView *_probeView;
}

@end

@implementation YKWPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    frame = CGRectMake([YKWoodpeckerManager sharedInstance].woodpeckerRestPoint.x, [YKWoodpeckerManager sharedInstance].woodpeckerRestPoint.y, 200, YKWPanelViewHeight);
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        _contentView.backgroundColor = [YKWBackgroudColor colorWithAlphaComponent:0.9];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _contentView.clipsToBounds = YES;
        _contentView.layer.borderColor = [YKWForegroudColor colorWithAlphaComponent:0.3].CGColor;
        _contentView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        _contentView.layer.cornerRadius = 2;
        [self addSubview:_contentView];
        
        UIView *line = [[UIView alloc] init];
        line.frame = CGRectMake(0, self.height, self.width, 0.5);
        line.backgroundColor = [UIColor colorWithHexString:@"3F3F3F"];
        [_contentView addSubview:line];
        
        _probeBtn = ({
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(25, 3, 80, 30);
            btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:YKWPanelViewFont];
            [btn setTitle:YKWLocalizedString(@"View Picker") forState:UIControlStateNormal];
            [btn setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.7] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(probeBtn:) forControlEvents:UIControlEventTouchUpInside];
            [_contentView addSubview:btn];
            btn;
        });
        
        _rulerBtn = ({
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(105, 3, 80, 30);
            btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:YKWPanelViewFont];
            [btn setTitle:YKWLocalizedString(@"View Ruler") forState:UIControlStateNormal];
            [btn setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.7] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(rulerBtn:) forControlEvents:UIControlEventTouchUpInside];
            [_contentView addSubview:btn];
            btn;
        });
        
        UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        hideButton.backgroundColor = [UIColor clearColor];
        hideButton.frame = CGRectMake(_contentView.width - 30, -12, 40, 40);
        hideButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:15];
        [hideButton setTitle:@"×" forState:UIControlStateNormal];
        [hideButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [hideButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:hideButton];
        
        _probeFuncView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, 35)];
        _probeFuncView.clipsToBounds = YES;
        
        _probeFuncBtn1 = ({
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.tag = 1;
            btn.frame = CGRectMake(0, 5, self.width / 3., 26);
            btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:YKWPanelViewFont];
            [btn setTitleColor:YKWForegroudColor forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(handleProbeBtn:) forControlEvents:UIControlEventTouchUpInside];
            [_probeFuncView addSubview:btn];
            btn;
        });
        
        _probeFuncBtn2 = ({
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.tag = 2;
            btn.frame = CGRectMake(_probeFuncBtn1.right, 5,  self.width / 3., 26);
            btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:YKWPanelViewFont];
            [btn setTitleColor:YKWForegroudColor forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(handleProbeBtn:) forControlEvents:UIControlEventTouchUpInside];
            [_probeFuncView addSubview:btn];
            btn;
        });
        
        _probeFuncBtn3 = ({
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.tag = 3;
            btn.frame = CGRectMake(_probeFuncBtn2.right, 5,  self.width / 3., 26);
            btn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:YKWPanelViewFont];
            [btn setTitleColor:YKWForegroudColor forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(handleProbeBtn:) forControlEvents:UIControlEventTouchUpInside];
            [_probeFuncView addSubview:btn];
            btn;
        });
        
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.font = [UIFont systemFontOfSize:12];
        _infoLabel.textColor = [YKWForegroudColor colorWithAlphaComponent:0.8];
        _infoLabel.numberOfLines = 0;
        _infoLabel.userInteractionEnabled = YES;
        _infoLabel.lineBreakMode = NSLineBreakByCharWrapping;
        UITapGestureRecognizer *singleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoSingleTap:)];
        [_infoLabel addGestureRecognizer:singleTapGes];
        UITapGestureRecognizer *doubleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoDoubleTap:)];
        doubleTapGes.numberOfTapsRequired = 2;
        [singleTapGes requireGestureRecognizerToFail:doubleTapGes];
        [_infoLabel addGestureRecognizer:doubleTapGes];
        
        _probeView = [[YKWProbeView alloc] init];
        _probeView.delegate = self;
        
        _rulerTool = [[YKWRulerTool alloc] initWithFrame:CGRectMake(0 , YKWPanelViewHeight, 0, 0)];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyWindowDidChange)
                                                     name:UIWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hide)
                                                     name:YKWoodpeckerManagerPluginsDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessageNotification:)
                                                     name:YKWPluginReceiveMessageNotification object:nil];

    }
    return self;
}

#pragma mark - Show & Hide
- (void)show {
    self.alpha = 0.0;
    CGRect frame = self.frame;
    frame.origin = [YKWoodpeckerManager sharedInstance].woodpeckerRestPoint;
    self.frame = frame;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self];
    }];
}

- (void)hide {
    [self hideProbe];
    [self hideRuler];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)keyWindowDidChange {
    if (self.superview && self.window != [UIApplication sharedApplication].keyWindow) {
        [self show];
    }
}

#pragma mark - Button Events
- (void)rulerBtn:(UIButton *)sender {
    [self hideProbe];
    
    if (_rulerTool.superview) {
        [self hideRuler];
        [self setButton:_rulerBtn selected:NO];
    } else {
        [self showRuler];
        [self setButton:_rulerBtn selected:YES];
    }
}

- (void)probeBtn:(UIButton *)sender {
    [self hideRuler];
    
    if (_infoLabel.superview) {
        [self hideProbe];
        [self setButton:_probeBtn selected:NO];
    } else {
        [self showProbe];
        [self setButton:_probeBtn selected:YES];
    }
}

- (void)logBtn:(UIButton *)sender {
    [[YKWoodpeckerManager sharedInstance] showConsole];
}

- (void)setButton:(UIButton *)btn selected:(BOOL)selected {
    if (selected) {
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:YKWPanelViewFont];
        [btn setTitleColor:YKWForegroudColor forState:UIControlStateNormal];
    } else {
        btn.titleLabel.font = [UIFont systemFontOfSize:YKWPanelViewFont];
        [btn setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.7] forState:UIControlStateNormal];
    }
}

#pragma mark - Ruler Tool
- (void)showRuler {
    if (!_rulerTool.superview) {
        _rulerTool.alpha = 0;
        [_rulerTool showInView:self];
        [UIView animateWithDuration:0.2 animations:^{
            self->_rulerTool.alpha = 1;
            self.height = YKWPanelViewHeight + self->_rulerTool.height;
        }];
    }
}

- (void)hideRuler {
    [self setButton:_rulerBtn selected:NO];
    if (_rulerTool.superview) {
        [UIView animateWithDuration:0.2 animations:^{
            self->_rulerTool.alpha = 0.0;
            self.height = YKWPanelViewHeight;
        }completion:^(BOOL finished) {
            [self->_rulerTool hide];
        }];
    }
}

#pragma mark - Probe Tool
- (void)showProbe {
    if (!_infoLabel.superview) {
        [_probeView showWithView:self];
        
        _probeFuncView.alpha = 0.0;
        _probeFuncView.top = YKWPanelViewHeight;
        _probeFuncView.width = self.width;
        [_contentView addSubview:_probeFuncView];
        
        _infoLabel.left = 10;
        _infoLabel.top = YKWPanelViewHeight + _probeFuncView.height;
        _infoLabel.width = self.width;
        _infoLabel.height = 0;
        _infoLabel.alpha = 0.0;
        _infoLabel.text = nil;
        [_contentView addSubview:_infoLabel];
    }
}

- (void)hideProbe {
    [self setButton:_probeBtn selected:NO];
    if (_infoLabel.superview) {
        [UIView animateWithDuration:0.2 animations:^{
            self->_probeView.alpha = 0.0;
            self->_infoLabel.alpha = 0.0;
            self->_probeFuncView.alpha = 0.0;
            self.height = YKWPanelViewHeight;
        }completion:^(BOOL finished) {
            [self->_probeView hide];
            [self->_infoLabel removeFromSuperview];
            [self->_probeFuncView removeFromSuperview];
            [self->_probeFuncBtn1 setTitle:@"" forState:UIControlStateNormal];
            self->_infoLabel.text = nil;
            self->_probeFuncBtn2.hidden = YES;
            self->_probeFuncBtn3.hidden = YES;
        }];
    }
}

#pragma mark - YKWProbeViewDelegate
- (void)probeView:(YKWProbeView *)probeView didProbeView:(UIView *)view {
    if (!view) return;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"YKWPanelViewPickModeTipShown"] && view.width == view.window.width) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"YKWPanelViewPickModeTipShown"];
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"A 3-finger-tap can change the pick mode") duration:5];
    }

    _probeFuncBtn2.hidden = NO;
    _probeFuncBtn3.hidden = NO;
    [_probeFuncBtn1 setTitle:YKWLocalizedString(@"Superview") forState:UIControlStateNormal];
    
    NSMutableString *info = [NSMutableString string];
    [info appendFormat:@"%@:\n", [view class]];
    UIView *frame1 = probeView.frameViewAry.lastObject;
    if (frame1) {
        [info appendFormat:@"X:%.2f Y:%.2f \n%@:%.2f %@:%.2f\n", _probeView.probedView.left, _probeView.probedView.top, YKWLocalizedString(@"Width"), _probeView.probedView.width, YKWLocalizedString(@"Height"), _probeView.probedView.height];
    }
    [info appendFormat:@"%@: %.2f\n", YKWLocalizedString(@"Opacity"), view.alpha];
    [info appendFormat:@"Hidden: %@\n", view.hidden ? @"YES" : @"NO"];
    [info appendFormat:@"ClipsToBounds: %@\n", view.clipsToBounds ? @"YES" : @"NO"];
    [info appendFormat:@"%@: %.2f\n", YKWLocalizedString(@"Corner Radius"), view.layer.cornerRadius];
    [info appendFormat:@"%@: ", YKWLocalizedString(@"Background Color")];
    if (_probeView.probedView.backgroundColor) {
        const CGFloat *components = CGColorGetComponents(_probeView.probedView.backgroundColor.CGColor);
        NSUInteger componentsCount = CGColorGetNumberOfComponents(_probeView.probedView.backgroundColor.CGColor);
        NSMutableString *hexColor = [NSMutableString stringWithString:@"0x"];
        for (int i = 0; i < componentsCount; i++) {
            [info appendFormat:@"%.2f ", components[i]];
            [hexColor appendString:[YKWPanelView getHexByDecimal:components[i] * 255]];
        }
        if (componentsCount == 4) {
            [info appendString:@" "];
            [info appendString:hexColor];
        }
    } else {
        [info appendString:YKWLocalizedString(@"<Empty>")];
    }
    [info appendString:@"\n"];

    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        [info appendFormat:@"%@:%@\n", YKWLocalizedString(@"Text"), label.text];
        [info appendFormat:@"%@:%@ %.1f\n", YKWLocalizedString(@"Font"), label.font.fontName , label.font.pointSize];
        [info appendFormat:@"%@:", YKWLocalizedString(@"Color")];
        const CGFloat *components = CGColorGetComponents(label.textColor.CGColor);
        NSUInteger componentsCount = CGColorGetNumberOfComponents(label.textColor.CGColor);
        NSMutableString *hexColor = [NSMutableString stringWithString:@"0x"];
        for (int i = 0; i < componentsCount; i++) {
            [info appendFormat:@"%.2f ", components[i]];
            [hexColor appendString:[YKWPanelView getHexByDecimal:components[i] * 255]];
        }
        if (componentsCount == 4) {
            [info appendString:@" "];
            [info appendString:hexColor];
        }
        [info appendString:@"\n"];
        [_probeFuncBtn2 setTitle:YKWLocalizedString(@"CopyText") forState:UIControlStateNormal];
        _probeFuncBtn3.hidden = YES;
    } else if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        NSURL *url = [imageView valueForKey:@"sd_imageURL"];
        if (url.absoluteString) {
            [info appendFormat:@"%@Url:%@\n", YKWLocalizedString(@"Image"), url.absoluteString];
        } else {
            [info appendFormat:@"%@Url:%@\n", YKWLocalizedString(@"Image"), YKWLocalizedString(@"<Empty>")];
        }
        url = [imageView valueForKey:@"sd_originalImageURL"];
        if (url.absoluteString) {
            [info appendFormat:@"%@Url:%@\n", YKWLocalizedString(@"ImageOriginal"), url.absoluteString];
        }
        if (imageView.image) {
            [info appendFormat:@"%@%@: w%.1f h%.1f\n",YKWLocalizedString(@"Image"), YKWLocalizedString(@"Size"), imageView.image.size.width * imageView.image.scale, imageView.image.size.height * imageView.image.scale];
        }

        [_probeFuncBtn2 setTitle:YKWLocalizedString(@"ShareUrl") forState:UIControlStateNormal];
        [_probeFuncBtn3 setTitle:YKWLocalizedString(@"Image") forState:UIControlStateNormal];
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)view;
        if (!UIEdgeInsetsEqualToEdgeInsets(btn.titleEdgeInsets, UIEdgeInsetsZero)) {
            [info appendFormat:@"TitleEdge: %.1f %.1f %.1f %.1f\n", btn.titleEdgeInsets.left, btn.titleEdgeInsets.top, btn.titleEdgeInsets.right, btn.titleEdgeInsets.bottom];
        }
        if (!UIEdgeInsetsEqualToEdgeInsets(btn.imageEdgeInsets, UIEdgeInsetsZero)) {
            [info appendFormat:@"ImageEdge: %.1f %.1f %.1f %.1f\n", btn.imageEdgeInsets.left, btn.imageEdgeInsets.top, btn.imageEdgeInsets.right, btn.imageEdgeInsets.bottom];
        }
        _probeFuncBtn2.hidden = YES;
        _probeFuncBtn3.hidden = YES;
    } else if ([view isKindOfClass:[UITextView class]]) {
        UITextView *label = (UITextView *)view;
        [info appendFormat:@"%@:%@\n", YKWLocalizedString(@"Text"), label.text];
        [info appendFormat:@"%@:%@ %.1f\n", YKWLocalizedString(@"Font"), label.font.fontName , label.font.pointSize];
        [info appendFormat:@"%@:", YKWLocalizedString(@"Color")];
        const CGFloat *components = CGColorGetComponents(label.textColor.CGColor);
        NSUInteger componentsCount = CGColorGetNumberOfComponents(label.textColor.CGColor);
        NSMutableString *hexColor = [NSMutableString stringWithString:@"0x"];
        for (int i = 0; i < componentsCount; i++) {
            [info appendFormat:@"%.2f ", components[i]];
            [hexColor appendString:[YKWPanelView getHexByDecimal:components[i] * 255]];
        }
        if (componentsCount == 4) {
            [info appendString:@" "];
            [info appendString:hexColor];
        }
        [info appendString:@"\n"];
        _probeFuncBtn2.hidden = YES;
        _probeFuncBtn3.hidden = YES;
    } else if ([view isKindOfClass:[UITextField class]]) {
        UITextField *label = (UITextField *)view;
        [info appendFormat:@"%@:%@\n", YKWLocalizedString(@"Text"), label.text];
        [info appendFormat:@"%@:%@ %.1f\n", YKWLocalizedString(@"Font"), label.font.fontName , label.font.pointSize];
        [info appendFormat:@"%@:", YKWLocalizedString(@"Color")];
        const CGFloat *components = CGColorGetComponents(label.textColor.CGColor);
        NSUInteger componentsCount = CGColorGetNumberOfComponents(label.textColor.CGColor);
        NSMutableString *hexColor = [NSMutableString stringWithString:@"0x"];
        for (int i = 0; i < componentsCount; i++) {
            [info appendFormat:@"%.2f ", components[i]];
            [hexColor appendString:[YKWPanelView getHexByDecimal:components[i] * 255]];
        }
        if (componentsCount == 4) {
            [info appendString:@" "];
            [info appendString:hexColor];
        }
        _probeFuncBtn2.hidden = YES;
        _probeFuncBtn3.hidden = YES;
        [info appendString:@"\n"];
    } else {
        [_probeFuncBtn2 setTitle:YKWLocalizedString(@"Image") forState:UIControlStateNormal];
        _probeFuncBtn3.hidden = YES;
    }
    [info appendFormat:@"%@", YKWLocalizedString(@"\n<Tap to share, double tap to see all>")];
    
    [self showInfo:info];
    
    if (view) {
        [[NSNotificationCenter defaultCenter] postNotificationName:YKWPluginSendMessageNotification object:@"ProbePluginNotification" userInfo:@{@"view":view}];
    }
}

- (void)didReceiveMessageNotification:(NSNotification *)notification {
    if (self.superview && [notification.object isKindOfClass:[NSString class]] && [notification.object isEqualToString:@"ProbePluginNotification"]) {
        NSString *msg = notification.userInfo[@"msg"];
        if ([msg isKindOfClass:[NSString class]] && msg.length) {
            NSString *info = [_infoLabel.text stringByReplacingOccurrencesOfString:YKWLocalizedString(@"\n<Tap to share, double tap to see all>") withString:[NSString stringWithFormat:@"\n%@\n%@", msg, YKWLocalizedString(@"\n<Tap to share, double tap to see all>")]];
            [self showInfo:info];
        }
    }
}

- (void)showInfo:(NSString *)info {
    _infoLabel.text = info;
    [UIView animateWithDuration:0.2 animations:^{
        self->_infoLabel.alpha = 1.0;
        self->_probeFuncView.alpha = 1.0;
        self->_infoLabel.top = YKWPanelViewHeight + self->_probeFuncView.height;
        self->_infoLabel.width = self.width - 20;
        [self->_infoLabel sizeToFit];
        self->_infoLabel.width = self.width - 20;
        self.height = YKWPanelViewHeight + self->_probeFuncView.height + self->_infoLabel.height + 10;
    }];
}

- (void)handleProbeBtn:(UIButton *)sender {
    switch (sender.tag) {
        case 1:{
            if (_probeView.probedView.superview) {
                [_probeView probeSuperView];
            } else {
                [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"No Superview")];
            }
        }break;
        case 2:{
            if ([_probeView.probedView isKindOfClass:[UILabel class]]) {
                NSString *txt = [(UILabel *)_probeView.probedView text];
                if (txt.length) {
                    [UIPasteboard generalPasteboard].string = txt;
                    [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Text Copied")];
                } else {
                    [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"No Text")];
                }
            } else if ([_probeView.probedView isKindOfClass:[UIImageView class]]) {
                UIImageView *imageView = (UIImageView *)_probeView.probedView;
                NSURL *url = [imageView valueForKey:@"sd_imageURL"];
                if (url.absoluteString) {
                    [YKWoodpeckerUtils showShareActivityWithItems:@[url.absoluteString]];
                } else {
                    [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Can't find image url")];
                }
            } else if ([_probeView.probedView isKindOfClass:[UIView class]]) {
                UIView *view = _probeView.probedView;
                if (view.layer.contents) {
                    UIImage *image = [UIImage imageWithCGImage:(__bridge CGImageRef _Nonnull)(view.layer.contents)];
                    if (image) {
                        YKWImageTextPreview *preview = [[YKWImageTextPreview alloc] init];
                        preview.image = image;
                        [preview show];
                    }
                } else {
                    [YKWoodpeckerMessage showMessage:@"layer.contents is nil"];
                }
            }
        }break;
        case 3:{
            if ([_probeView.probedView isKindOfClass:[UILabel class]]) {
                
            } else if ([_probeView.probedView isKindOfClass:[UIImageView class]]) {
                YKWImageTextPreview *preview = [[YKWImageTextPreview alloc] init];
                preview.sourceImageView = (UIImageView *)_probeView.probedView;
                [preview show];
            }
        }break;
        default:
            break;
    }
}

- (void)infoSingleTap:(id)sender {
    if (_infoLabel.text.length) {
        [YKWoodpeckerUtils showShareActivityWithItems:@[_infoLabel.text]];
    } else {
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"<Empty>")];
    }
}

- (void)infoDoubleTap:(id)sender {
    if (_probeView.probedView) {
        UIView *currentView = _probeView.probedView;
        YKWObjectProbeView *objProbeView = [[YKWObjectProbeView alloc] init];
        objProbeView.delegate = self;
        objProbeView.entranceObject = currentView;
        [objProbeView show];
    }
}

#pragma mark - YKWObjectProbeViewDelegate
- (void)objectProbeView:(YKWObjectProbeView *)probeView wantsToShowView:(UIView *)view {
    [_probeView didProbeView:view];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Class Method
+ (NSString *)getHexByDecimal:(NSInteger)decimal {
    if (decimal == 0) {
        return @"00";
    }
    NSString *hex = @"";
    NSString *letter;
    NSInteger number;
    for (int i = 0; i < 32; i++) {
        number = decimal % 16;
        decimal = decimal / 16;
        switch (number) {
            case 10:
                letter = @"A"; break;
            case 11:
                letter = @"B"; break;
            case 12:
                letter = @"C"; break;
            case 13:
                letter = @"D"; break;
            case 14:
                letter = @"E"; break;
            case 15:
                letter = @"F"; break;
            default:
                letter = [NSString stringWithFormat:@"%ld", (long)number];
        }
        hex = [letter stringByAppendingString:hex];
        if (decimal == 0) break;
    }
    return hex.length > 1 ? hex : [@"0" stringByAppendingString:hex];
}

@end
