//
//  TableViewController.m
//  YKWoodpeckerDemo
//
//  Created by Zim on 2019/9/16.
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

#import "TableViewController.h"
#import "UIImageView+WebCache.h"

static NSString *_readme = nil;

@interface TableViewCell : UITableViewCell {
    UILabel *_label;
    UIImageView *_imageView1;
    UIImageView *_imageView2;
    UIImageView *_imageView3;
}

@property (nonatomic) NSInteger type;

@end

@implementation TableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:15];
        _label.textColor = [UIColor colorWithRed:(arc4random() % 100 / 200.) green:(arc4random() % 100 / 200.) blue:(arc4random() % 100 / 200.) alpha:1];
        _label.numberOfLines = 0;
        [self addSubview:_label];
        
        _imageView1 = [[UIImageView alloc] init];
        _imageView1.clipsToBounds = YES;
        _imageView1.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView1];
        
        _imageView2 = [[UIImageView alloc] init];
        _imageView2.clipsToBounds = YES;
        _imageView2.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView2];

        _imageView3 = [[UIImageView alloc] init];
        _imageView3.clipsToBounds = YES;
        _imageView3.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView3];
    }
    return self;
}

- (void)setType:(NSInteger)type {
    _type = type;
    switch (_type) {
        case 0:{
            [self setupLabel:_label];
            _label.frame = CGRectMake(15, 15, self.frame.size.width - 190, 150);

            [self setupImageView:_imageView1];
            _imageView1.frame = CGRectMake(self.frame.size.width - 165, 15, 150, self.frame.size.height - 30);
            _imageView1.hidden = NO;
            _imageView2.hidden = YES;
            _imageView3.hidden = YES;
        }break;
        case 1:{
            [self setupLabel:_label];
            _label.frame = CGRectMake(180, 15, self.frame.size.width - 190, 150);

            [self setupImageView:_imageView1];
            _imageView1.frame = CGRectMake(15, 15, 150, self.frame.size.height - 30);
            _imageView1.hidden = NO;
            _imageView2.hidden = YES;
            _imageView3.hidden = YES;
        }break;
        case 2:{
            [self setupLabel:_label];
            _label.frame = CGRectMake(15, 15, self.frame.size.width - 30, 20);
            
            [self setupImageView:_imageView1];
            [self setupImageView:_imageView2];
            [self setupImageView:_imageView3];
            CGFloat width = (self.frame.size.width - 60) / 3.;
            _imageView1.hidden = NO;
            _imageView1.frame = CGRectMake(15, 50, width, width);
            _imageView2.hidden = NO;
            _imageView2.frame = CGRectMake(30 + width, 50, width, width);
            _imageView3.hidden = NO;
            _imageView3.frame = CGRectMake(45 + width * 2, 50, width, width);
        }break;
        default:
            break;
    }
}

- (void)setupLabel:(UILabel *)label {
    if (_readme.length) {
        NSInteger length = 50 + arc4random() % 100;
        _label.text = [_readme substringWithRange:NSMakeRange(arc4random() % (_readme.length - length * 2), length)];
    } else {
        NSMutableString *text = [NSMutableString string];
        NSInteger length = 10 + arc4random() % 50;
        for (int i = 0; i < length; i++) {
            [text appendString:[self getRandomEnglishWord]];
        }
        _label.text = text;
    }
}

- (void)setupImageView:(UIImageView *)imageView {
    if (arc4random() % 2) {
        float r = 0, g = 0, b = 0;
        HSLtoRGB((arc4random() % 360), 1.0, 0.75, &r, &g, &b);
        imageView.backgroundColor = [UIColor colorWithRed:r/255. green:g/255. blue:b/255. alpha:1];
        imageView.image = nil;
    } else {
        NSArray *images = @[@"woodpecker_all_plugins.PNG",
                            @"woodpecker_arch.png",
                            @"woodpecker_demo_cmds.png",
                            @"woodpecker_demo_filter.png",
                            @"woodpecker_demo_history.png",
                            @"woodpecker_demo_k_cmd.png",
                            @"woodpecker_demo_listen_in.png",
                            @"woodpecker_demo_object_check.png",
                            @"woodpecker_demo_ruler.png",
                            @"woodpecker_demo_sysinfo.png",
                            @"woodpecker_demo_ui_check.png",
                            @"woodpecker_demo_ui_check_ruler.png",
                            @"woodpecker_demo_ui_compare.png",
                            @"woodpecker_po_cmd.png"];
        [imageView sd_setImageWithURL:[NSURL URLWithString:[@"https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/" stringByAppendingString:[images objectAtIndex:(arc4random() % images.count)]]]];
    }
}

- (NSString*)getRandomEnglishWord {
    NSString *base = @"abcdefghijklmnopqrstuvwxyz";
    NSInteger count = 1 + arc4random() % 7;
    NSMutableString *text = [NSMutableString string];
    for (int i = 0; i < count; i++) {
        [text appendFormat:@"%c", [base characterAtIndex:(arc4random() % 26)]];
    }
    return [text stringByAppendingString:@" "];
}

void HSLtoRGB (float h, float s, float l, float* R, float* G, float* B) {
    float v1, v2;
    float H = h/360.0;
    float S = s;
    float L = l;
    if (0 == S) {
        *R = L * 255;
        *G = L * 255;
        *B = L * 255;
    } else {
        if (L < 0.5)
            v2 = L * (1+S);
        else
            v2 = (L+S) - (L*S);
        
        v1 = 2 * L - v2;
        *R = 255 * HuetoRGB(v1, v2, H+(1.0/3.0));
        *G = 255 * HuetoRGB(v1, v2, H);
        *B = 255 * HuetoRGB(v1, v2, H-(1.0/3.0));
    }
}

float HuetoRGB (float v1, float v2, float vH) {
    if (vH < 0)
        vH += 1;
    if (vH > 1)
        vH -= 1;
    if ((6*vH) < 1)
        return (v1 + (v2-v1)*6*vH);
    if ((2*vH) < 1)
        return v2;
    if ((3*vH) < 2)
        return (v1 + (v2-v1)*((2.0/3.0)-vH)*6);
    return v1;
}

@end

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!_readme.length) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *er = nil;
            _readme = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/alibaba/youku-sdk-tool-woodpecker/master/README.md"] encoding:NSUTF8StringEncoding error:&er];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        });
    }
    
    self.title = @"Table View";
    [self.tableView registerClass:[TableViewCell class] forCellReuseIdentifier:@"TableViewCell"];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (tableView.frame.size.width - 60.) / 3. + 65;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell" forIndexPath:indexPath];
    cell.type = arc4random() % 3;
    return cell;
}

@end
