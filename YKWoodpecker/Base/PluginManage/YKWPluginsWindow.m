//
//  YKWPluginsWindow.m
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

#import "YKWPluginsWindow.h"
#import "YKWPluginModelCell.h"
#import "YKWPluginSectionHeader.h"

#define kYKWPluginsWindowLastCenter @"YKWPluginsWindowLastCenter"

@interface YKWPluginsWindow()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    BOOL _firstLoad;
    
    UIView *_contentView;
    
    UIImageView *_woodpeckerIcon;
}

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation YKWPluginsWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _firstLoad = YES;
        
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = MAXFLOAT;
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        panGestureRecognizer.minimumNumberOfTouches = 1;
        [panGestureRecognizer addTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:panGestureRecognizer];

        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        _contentView.backgroundColor = [YKWBackgroudColor colorWithAlphaComponent:0.9];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _contentView.clipsToBounds = YES;
        _contentView.layer.borderColor = [YKWForegroudColor colorWithAlphaComponent:0.3].CGColor;
        _contentView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        _contentView.layer.cornerRadius = 2;
        [self addSubview:_contentView];
        
        _woodpeckerIcon = nil;

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        self.collectionView.backgroundColor = [UIColor clearColor];
        if (@available(iOS 11.0, *)) {
            self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        self.collectionView.alwaysBounceHorizontal = NO;
        self.collectionView.alwaysBounceVertical = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.directionalLockEnabled = YES;
        [self.collectionView registerClass:[YKWPluginModelCell class] forCellWithReuseIdentifier:@"YKWPluginModelCell"];
        [self.collectionView registerClass:[YKWPluginSectionHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"YKWPluginSectionHeader"];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        [_contentView addSubview:self.collectionView];
        
        UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        hideButton.backgroundColor = [UIColor clearColor];
        hideButton.frame = CGRectMake(_contentView.width - 30, -12, 40, 40);
        hideButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        hideButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:15];
        [hideButton setTitle:@"×" forState:UIControlStateNormal];
        [hideButton setTitleColor:[YKWForegroudColor colorWithAlphaComponent:0.8] forState:UIControlStateNormal];
        [hideButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:hideButton];
    }
    return self;
}

- (void)becomeKeyWindow {
    [[UIApplication sharedApplication].windows.firstObject makeKeyAndVisible];
}

- (void)showWoodpecker {
    UIImage *icon = [UIImage imageNamed:@"icon_woodpecker" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    if (icon) {
        _woodpeckerIcon = [[UIImageView alloc] initWithImage:icon];
        _woodpeckerIcon.layer.anchorPoint = CGPointMake(0.5, 0.9);
    } else {
        _woodpeckerIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 38., 38.)];
        _woodpeckerIcon.backgroundColor = [YKWHighlightColor colorWithAlphaComponent:0.8];
        _woodpeckerIcon.clipsToBounds = YES;
        _woodpeckerIcon.layer.anchorPoint = CGPointMake(0.7, 0.7);
        _woodpeckerIcon.layer.cornerRadius = _woodpeckerIcon.width / 2.0;
    }
    _woodpeckerIcon.center = CGPointMake(2, 2);
    _woodpeckerIcon.userInteractionEnabled = YES;
    [_woodpeckerIcon addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIconTap:)]];
    [self addSubview:_woodpeckerIcon];
}

#pragma mark - Icon
// To receive touch events on the woodpecker icon.
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    if (_woodpeckerIcon) {
        CGPoint p = [_woodpeckerIcon convertPoint:point fromView:self];
        if (CGRectContainsPoint(_woodpeckerIcon.bounds, p)) {
            return YES;
        }
    }
    return [super pointInside:point withEvent:event];
}

// Woodpecker pecking animation.
- (void)handleIconTap:(id)sender {
    if (_woodpeckerIcon.image) {
        [UIView animateWithDuration:0.06 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self->_woodpeckerIcon.transform = CGAffineTransformMakeRotation(M_PI_4 - 0.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.05 delay:0.05 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self->_woodpeckerIcon.transform = CGAffineTransformIdentity;
            } completion:nil];
        }];
    }
    
    if (_contentView.width > 10) {
        [self fold:YES];
    } else {
        [self unfold:YES];
    }
}

- (void)pan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:sender.view];
    [sender setTranslation:CGPointZero inView:sender.view];
    self.center = CGPointMake(self.centerX + translation.x, self.centerY + translation.y);
}

- (void)fold:(BOOL)animated {
    if (_contentView.width > 0) {
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                self->_contentView.width = 0;
                self->_contentView.height = 0;
            } completion:^(BOOL finished) {
                self.width = 1.;
                self.height = 1.;
            }];
        } else {
            _contentView.width = 0;
            _contentView.height = 0;
            self.width = 1.;
            self.height = 1.;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YKWoodpeckerManagerPluginsDidHideNotification object:nil];
}

- (void)unfold:(BOOL)animated {
    if (_contentView.width <= 0) {
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                [self setupSize];
            }];
        } else {
            [self setupSize];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:YKWoodpeckerManagerPluginsDidShowNotification object:nil];
    }
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible];
}

- (void)hide {
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(self.center) forKey:kYKWPluginsWindowLastCenter];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.hidden = YES;
}

- (void)setPluginModelArray:(NSArray<NSArray<YKWPluginModel *> *> *)pluginModelArray {
    _pluginModelArray = pluginModelArray;
    
    if (_contentView.width > 10) {
        [self setupSize];
    }
    [self.collectionView reloadData];
}

// Determine the size of the plugin collection view.
- (void)setupSize {
    NSInteger widthCount = 4;
    NSInteger heightCount = 0;
    for (NSArray *pluginAry in _pluginModelArray) {
        heightCount += (pluginAry.count + 3) / 4;
    }
    self.width = widthCount * ([YKWPluginModelCell cellSizeForModel:nil].width + 10) + 10;
    self.height = heightCount * ([YKWPluginModelCell cellSizeForModel:nil].height + 10)  + _pluginModelArray.count * 20;
    if (self.height > [UIScreen mainScreen].bounds.size.height * 3. / 4.) {
        self.height = [UIScreen mainScreen].bounds.size.height * 3. / 4.;
    }
    self.collectionView.frame = CGRectMake(0, 0, self.width, self.height);

    // Restore to previous postion on first show.
    if (_firstLoad) {
        _firstLoad = NO;
        NSString *centerStr = [[NSUserDefaults standardUserDefaults] objectForKey:kYKWPluginsWindowLastCenter];
        if (centerStr.length) {
            CGPoint center = CGPointFromString(centerStr);
            // Position protection.
            if (CGRectContainsPoint(UIEdgeInsetsInsetRect([UIApplication sharedApplication].keyWindow.bounds, UIEdgeInsetsMake(50, 50, 50, 50)), CGPointMake(center.x - self.width / 2., center.y - self.height / 2.))) {
                self.center = center;
            }
        }
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.pluginModelArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.pluginModelArray ykw_objectAtIndex:section] count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        YKWPluginSectionHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"YKWPluginSectionHeader" forIndexPath:indexPath];
        YKWPluginModel *model = [[self.pluginModelArray ykw_objectAtIndex:indexPath.section] ykw_objectAtIndex:0];
        headerView.titleLabel.text = model.pluginCategoryName;
        return headerView;
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YKWPluginModelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKWPluginModelCell" forIndexPath:indexPath];
    YKWPluginModel *model = [[self.pluginModelArray ykw_objectAtIndex:indexPath.section] ykw_objectAtIndex:indexPath.row];
    cell.pluginModel = model;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [YKWPluginModelCell cellSizeForModel:nil];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(collectionView.width, 20);
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(pluginsWindow:didSelectPlugin:)]) {
        [self fold:YES];
        YKWPluginModel *model = [[self.pluginModelArray ykw_objectAtIndex:indexPath.section] ykw_objectAtIndex:indexPath.row];
        [self.delegate pluginsWindow:self didSelectPlugin:model];
    }
}

@end
