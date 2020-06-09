//
//  YKWCmdView.m
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

#import "YKWCmdView.h"
#import "YKWCmdCollectionViewCell.h"
#import "YKWoodpeckerMessage.h"
#import "YKWoodpeckerCommonHeaders.h"

#define kYKWCmdViewCmdData @"YKWCmdViewCmdData"

@interface YKWCmdView()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSMutableArray *cmdsAry;

@end

@implementation YKWCmdView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.alwaysBounceHorizontal = YES;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self.collectionView registerClass:[YKWCmdCollectionViewCell class] forCellWithReuseIdentifier:@"YKWCmdCollectionViewCell"];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        [self addSubview:self.collectionView];
    }
    return self;
}

- (void)loadCmd {
    id cmdsDic = [[NSUserDefaults standardUserDefaults] objectForKey:kYKWCmdViewCmdData];
    if (cmdsDic) {
        [self parseCmdModels:cmdsDic];
    }

    if (!_cmdSourceUrl.length) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *er = nil;
        NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:self->_cmdSourceUrl] options:0 error:&er];
        id json = nil;
        if (data.length) {
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        }
        
        if ([json isKindOfClass:[NSDictionary class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:json forKey:kYKWCmdViewCmdData];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self parseCmdModels:json];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(cmdsViewDidFinishLoadCmd:error:)]) {
                    [self.delegate cmdsViewDidFinishLoadCmd:self error:er];
                }
            });
        }
    });
}

- (void)parseCmdModels:(NSDictionary *)cmdsDic {
    NSArray *cmdAry = nil;
    if ([cmdsDic isKindOfClass:[NSDictionary class]]) {
        cmdAry = [cmdsDic objectForKey:@"cmds"];
    }
    if ([cmdAry isKindOfClass:[NSArray class]]) {
        NSMutableArray *modelAry = [NSMutableArray arrayWithCapacity:cmdAry.count];
        for (NSDictionary *dic in cmdAry) {
            YKWCmdModel *model = [[YKWCmdModel alloc] initWithDictionary:dic];
            [modelAry addObject:model];
        }
        if (modelAry.count) {
            self.cmdsAry = modelAry;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                if ([self.delegate respondsToSelector:@selector(cmdsViewDidFinishLoadCmd:error:)]) {
                    [self.delegate cmdsViewDidFinishLoadCmd:self error:nil];
                }
            });
        }
    }
}

- (void)setCmdOff {
    for (YKWCmdModel *m in self.cmdsAry) {
        m.isOn = NO;
    }
    [self.collectionView reloadData];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.collectionView.frame = CGRectMake(0, 0, self.ykw_width, self.ykw_height);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cmdsAry.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YKWCmdCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([YKWCmdCollectionViewCell class]) forIndexPath:indexPath];
    if (indexPath.row < self.cmdsAry.count) {
        cell.cmdModel = self.cmdsAry[indexPath.row];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = 0.0;
    if (indexPath.row < self.cmdsAry.count) {
        width = [YKWCmdCollectionViewCell sizeForCmdModel:self.cmdsAry[indexPath.row]].width;
    }
    return CGSizeMake(width, collectionView.ykw_height - 10);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(-10, 10, 0, 10);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 10;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.cmdsAry.count) {
        YKWCmdModel *cmdModel = self.cmdsAry[indexPath.row];
        if (cmdModel.isOn) {
            if ([self.delegate respondsToSelector:@selector(cmdsView:didUnSelectCmd:)]) {
                [self.delegate cmdsView:self didUnSelectCmd:cmdModel];
            }
            cmdModel.isOn = NO;
        } else {
            if ([self.delegate respondsToSelector:@selector(cmdsView:didSelectCmd:)]) {
                [self.delegate cmdsView:self didSelectCmd:cmdModel];
            }
            for (YKWCmdModel *m in self.cmdsAry) {
                m.isOn = NO;
            }
            cmdModel.isOn = YES;
        }
        [self.collectionView reloadData];
    }
}

@end
