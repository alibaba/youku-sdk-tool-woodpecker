//
//  YKWAllImagesViewController.m
//  YoukuResource
//
//  Created by better on 2018/12/15.
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

#import "YKWAllImagesViewController.h"
#import "YKWImageTextPreview.h"

#define COVER_WIDTH (([UIScreen mainScreen].bounds.size.width)/5)
#define COVER_HEIGHT (COVER_WIDTH)

@interface YKWImgInfoView : UIView

@property (nonatomic, strong) UIImageView * cover;
@property (nonatomic, strong) UILabel * sizeLabel;
@property (nonatomic, strong) UILabel * nameLabel;

- (void) setImage:(NSString*)image;
- (void) setImage:(NSString*)image fit:(BOOL) fit;

@end

@interface YKWAllImagesViewController ()<UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>{
    UICollectionView *_mainCollectionView;
}

@property (nonatomic, strong) NSMutableSet<NSString*> * allIcons;
@property (nonatomic, strong) NSMutableArray<NSString*> * allIconsArr;

@end

@implementation YKWAllImagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"All Images";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"╳" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];

    [self readAllImages];
    
    [self createCollectionView];
}

- (void)createCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    _mainCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.ykw_width, self.view.ykw_height) collectionViewLayout:layout];
    _mainCollectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_mainCollectionView];
    [_mainCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellId"];
    [_mainCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellId2"];
    
    [_mainCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"reusableView"];
    
    _mainCollectionView.delegate = self;
    _mainCollectionView.dataSource = self;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - collectionView
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.allIcons.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = (UICollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:indexPath.section == 0? @"cellId" : @"cellId2" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    YKWImgInfoView * view = [cell viewWithTag:99999];
    if (!view) {
        view = [[YKWImgInfoView alloc] initWithFrame:CGRectMake(0, 0, COVER_WIDTH, COVER_HEIGHT)];
        view.tag = 99999;
        [cell addSubview:view];
    }
    [view setImage:self.allIconsArr[indexPath.row]];
    cell.layer.borderWidth = 1.0/[UIScreen mainScreen].scale;
    cell.layer.borderColor = [UIColor blackColor].CGColor;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return CGSizeMake(COVER_WIDTH, COVER_HEIGHT);
    } else {
        return [UIScreen mainScreen].bounds.size;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0; //COVER_WIDTH/6 - 1;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0; //COVER_WIDTH/6;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    YKWImageTextPreview *preview = [[YKWImageTextPreview alloc] init];
    preview.image = [UIImage imageNamed:[self.allIconsArr ykw_objectAtIndex:indexPath.row]];
    [preview show];
}

- (void) readAllImages {
    self.allIcons = [[NSMutableSet alloc] init];
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    [self parseIconsRecursive:resourcePath];
    self.allIconsArr = [NSMutableArray new];
    for (NSString * icon in self.allIcons) {
        [self.allIconsArr addObject:icon];
    }
    [self.allIconsArr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [(NSString*)obj1 compare:(NSString*)obj2];
    }];
}

- (void) parseIconsRecursive:(NSString*)path {
    NSFileManager * fileManger = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManger fileExistsAtPath:path isDirectory:&isDir];
    if (isExist) {
        if (isDir) {
            NSArray * dirArray = [fileManger contentsOfDirectoryAtPath:path error:nil];
            NSString * subPath = nil;
            for (NSString * str in dirArray) {
                subPath  = [path stringByAppendingPathComponent:str];
                BOOL issubDir = NO;
                [fileManger fileExistsAtPath:subPath isDirectory:&issubDir];
                if (!issubDir) {
                    NSString *tmpstr = [self processName:str];
                    if (tmpstr) {
                        UIImage * image = [UIImage imageNamed:tmpstr];
                        if (image) {
                            [self.allIcons addObject:tmpstr];
                        }
                    }
                } else {
                    [self parseIconsRecursive:subPath];
                }
            }
        }
    }
}

- (NSString*) processName:(NSString*)str {
    if ([str containsString:@"@2x.png"] || [str containsString:@"@3x.png"] ) {
        str = [str substringToIndex:str.length - @"@2x.png".length];
        return str;
    } if (![str containsString:@".png"]) {
        return nil;
    }
    return [str substringToIndex:str.length - @".png".length];;
}

@end

@implementation YKWImgInfoView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.cover = [[UIImageView alloc] initWithFrame:CGRectMake(0, 5, self.ykw_width/2, self.ykw_height/2)];
        self.cover.layer.borderWidth = 1.0/[UIScreen mainScreen].scale;
        self.cover.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.cover.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.cover];
        self.sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        self.sizeLabel.tag = 99998;
        self.sizeLabel.textAlignment = NSTextAlignmentCenter;
        self.sizeLabel.font = [UIFont systemFontOfSize:7];
        self.sizeLabel.textColor = [UIColor blackColor];
        [self addSubview:self.sizeLabel];
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.nameLabel.tag = 99997;
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.font = [UIFont systemFontOfSize:7];
        self.nameLabel.textColor = [UIColor blackColor];
        [self addSubview:self.nameLabel];
    }
    return self;
}
- (void) setImage:(NSString*)image fit:(BOOL) fit {
    //    self.cover.image = [UIImage imageNamed:];
    self.cover.image = [UIImage imageNamed:image];
    self.cover.ykw_width =  self.ykw_width/2;
    self.cover.ykw_height = self.ykw_width/2;
    if (fit) {
        [self.cover sizeToFit];
        if (self.cover.ykw_width > self.ykw_width/2) {
            self.cover.ykw_width = self.ykw_width/2;
        }
        if (self.cover.ykw_height > self.ykw_width/2) {
            self.cover.ykw_height = self.ykw_width/2;
        }
    }

    if (self.cover.image.size.width > self.cover.image.size.height) {
        self.cover.ykw_height = self.cover.ykw_width * self.cover.image.size.height/self.cover.image.size.width;
    } else {
        self.cover.ykw_width = self.cover.ykw_height * self.cover.image.size.width/self.cover.image.size.height;
    }
    self.cover.center = CGPointMake(self.ykw_width/2.0f, self.ykw_height/2.0f);
    
    self.sizeLabel.text = [NSString stringWithFormat:@"%.0fx%.0f", self.cover.image.size.width, self.cover.image.size.height];
    [self.sizeLabel sizeToFit];
    self.sizeLabel.ykw_height += 5;
    self.sizeLabel.ykw_width += 10;
    self.nameLabel.text = image;
    [self.nameLabel sizeToFit];
    self.nameLabel.ykw_width = self.ykw_width;
    self.nameLabel.ykw_bottom = self.ykw_height - 3;
}
- (void) setImage:(NSString*)image {
    [self setImage:image fit:NO];
}

@end
