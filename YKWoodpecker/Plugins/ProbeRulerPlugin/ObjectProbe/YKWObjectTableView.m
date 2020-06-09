//
//  YKWObjectTableView.m
//  YKWoodpecker
//
//  Created by Zim on 2018/11/22.
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

#import "YKWObjectTableView.h"
#import <objc/runtime.h>
#import "YKWoodpeckerCommonHeaders.h"

#define YKWObjectTableViewMargin 10
#define YKWObjectTableBortherViewsKey @"ykw_brotherViews"
#define YKWObjectTableViewControllerKey @"ykw_viewController"

@interface YKWObjectTableView()<UITableViewDelegate,UITableViewDataSource> {
    NSMutableArray *_propertyListAry; // name<class>@p/i
    UILabel *_objectIndexLabel;
}

@end

@implementation YKWObjectTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) {
        self.tableFooterView = [UIView new];
        self.layer.borderColor = YKWHighlightColor.CGColor;
        self.layer.borderWidth = 1;
        self.tag = -100;

        [self registerClass:[YKWObjectTableViewCell class] forCellReuseIdentifier:@"YKWObjectTableViewCell"];
        
        _propertyListAry = nil;
        self.dataSource = self;
        self.delegate = self;
    }
    return self;
}

- (void)setProbedObject:(NSObject *)probedObject {
    _probedObject = probedObject;
    Class objClass = self.probeClass;
    if (!objClass) {
        objClass = self.probedObject.class;
        self.probeClass = objClass;
    }
    if (![self.probedObject isKindOfClass:self.probeClass]) {
        return;
    }
    
    if (objClass) {
        NSMutableArray *temp = [[NSMutableArray alloc] init];
        if ([self.probedObject isKindOfClass:[NSArray class]]) {
            NSArray *ary = (NSArray *)self.probedObject;
            for (NSObject * obj in ary) {
                [temp addObject:[NSString stringWithFormat:@"%@", obj.description]];
            }
        } else {
            [temp addObjectsFromArray:[YKWObjectTableView getIvarList:objClass]];
            [temp addObjectsFromArray:[YKWObjectTableView getProperties:objClass]];
            [temp sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [[obj1 lowercaseString] compare:[obj2 lowercaseString]];
            }];
            
            if ([self.probedObject isKindOfClass:[UIView class]]) {
                [temp insertObject:YKWObjectTableViewControllerKey atIndex:0];
                [temp insertObject:YKWObjectTableBortherViewsKey atIndex:0];
                [temp removeObject:@"subviews"];
                [temp insertObject:@"subviews" atIndex:0];
                [temp removeObject:@"superview"];
                [temp insertObject:@"superview" atIndex:0];
            }
            [temp removeObject:@"debugDescription"];
            [temp insertObject:@"debugDescription" atIndex:0];
            if (self.probeClass == [NSObject class]) {
                [temp removeObject:@"superclass"];
                [temp removeObject:@"superclass@p"];
            } else {
                [temp insertObject:@"superclass" atIndex:0];
            }
        }

        _propertyListAry = temp;
        [self reloadData];
        self.contentOffset = CGPointZero;
    }
}

- (void)setObjectIndex:(NSInteger)objectIndex {
    _objectIndex = objectIndex;
    if (!_objectIndexLabel) {
        _objectIndexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.ykw_width, self.ykw_height)];
        _objectIndexLabel.font = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:100];
        _objectIndexLabel.textAlignment = NSTextAlignmentCenter;
        _objectIndexLabel.textColor = [YKWHighlightColor colorWithAlphaComponent:0.3];
        [self insertSubview:_objectIndexLabel atIndex:0];
    }
    _objectIndexLabel.text = [NSString stringWithFormat:@"%ld", (long)_objectIndex];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_objectIndexLabel) {
        _objectIndexLabel.ykw_top = scrollView.contentOffset.y;
    }
}

#pragma mark - UITableView Protocols
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _propertyListAry.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.ykw_width, 30)];
    header.backgroundColor = [UIColor colorWithWhite:0. alpha:0.75];
    
    UILabel *infoLabel = [UILabel new];
    infoLabel.frame = CGRectMake(YKWObjectTableViewMargin, 0, tableView.ykw_width - YKWObjectTableViewMargin, 30);
    infoLabel.font = [UIFont systemFontOfSize:12.];
    infoLabel.minimumScaleFactor = 0.2;
    infoLabel.adjustsFontSizeToFitWidth = YES;
    infoLabel.numberOfLines = 0;
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.text = [NSString stringWithFormat:@"%@<%@>(%p)", self.probedObject.class, self.probeClass, self.probedObject];
    [header addSubview:infoLabel];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKWObjectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKWObjectTableViewCell" forIndexPath:indexPath];
    cell.txtLabel.text = [_propertyListAry ykw_objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tag / 10 == indexPath.row) { // 
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.tag = -100;
        [self handleDoubleTap:indexPath];
    } else {
        self.tag = indexPath.row * 10;
        [self performSelector:@selector(handleSingleTap:) withObject:indexPath afterDelay:0.3];
    }
}

- (void)handleSingleTap:(NSIndexPath *)indexPath {
    self.tag = -100;
    NSString *pptString = [_propertyListAry ykw_objectAtIndex:indexPath.row];
    NSArray *subStrs = [pptString componentsSeparatedByString:@"<"];
    NSString *pptName = [[subStrs.firstObject stringByReplacingOccurrencesOfString:@"@p" withString:@""] stringByReplacingOccurrencesOfString:@"@i" withString:@""];
    id object = nil;
    Class objClass = nil;
    if ([self.probedObject isKindOfClass:[NSArray class]]) {
        NSArray *ary = (NSArray *)self.probedObject;
        object = [ary ykw_objectAtIndex:indexPath.row];
    } else if ([pptName isEqualToString:YKWObjectTableBortherViewsKey]) {
        UIView *view = (UIView *)self.probedObject;
        object = view.superview.subviews;
    } else if ([pptName isEqualToString:YKWObjectTableViewControllerKey]) {
        UIView *view = (UIView *)self.probedObject;
        object = [self getViewController:view];
    } else if ([pptName isEqualToString:@"superclass"]) {
        object = self.probedObject;
        objClass = class_getSuperclass(self.probeClass);
    } else {
        object = [self.probedObject valueForKey:pptName];
        objClass = [object class];
    }
    
    if (object && [self.objDelegate respondsToSelector:@selector(objectTableView:didSelectObject:class:key:)]) {
        [self.objDelegate objectTableView:self didSelectObject:object class:objClass key:pptName];
    } else if ([self.objDelegate respondsToSelector:@selector(objectTableView:didSelectNonObject:class:key:)]) {
        [self.objDelegate objectTableView:self didSelectNonObject:object class:objClass key:pptName];
    }
}

- (void)handleDoubleTap:(NSIndexPath *)indexPath {
    if ([self.objDelegate respondsToSelector:@selector(objectTableView:didTapOnObject:key:)]) {
        NSString *pptString = [_propertyListAry ykw_objectAtIndex:indexPath.row];
        NSArray *subStrs = [pptString componentsSeparatedByString:@"<"];
        NSString *pptName = [[subStrs.firstObject stringByReplacingOccurrencesOfString:@"@p" withString:@""] stringByReplacingOccurrencesOfString:@"@i" withString:@""];
        if ([self.probedObject isKindOfClass:[NSArray class]]) {
            pptName = @(indexPath.row).stringValue;
        }
        id object = nil;
        if ([pptName isEqualToString:YKWObjectTableBortherViewsKey]) {
            UIView *view = (UIView *)self.probedObject;
            object = view.superview.subviews;
        } else if ([pptName isEqualToString:YKWObjectTableViewControllerKey]) {
            UIView *view = (UIView *)self.probedObject;
            object = [self getViewController:view];
        }
        
        [self.objDelegate objectTableView:self didTapOnObject:object key:pptName];
    }
}

- (UIViewController *)getViewController:(UIView *)view {
    UIResponder *responder = view;
    while ((responder = responder.nextResponder)) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

#pragma mark - Probe
// name<pptClass>@i
+ (NSArray *)getIvarList:(Class)cls {
    unsigned int count = 0;
    Ivar *ivars = nil;
    ivars = class_copyIvarList(cls, &count);
    NSMutableArray *varsAry = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i ++) {
        Ivar ivar = nil;
        ivar = ivars[i];
        const char *cName = ivar_getName(ivar);
        const char *cType = ivar_getTypeEncoding(ivar);
        NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        NSString *type = [[[NSString stringWithCString:cType encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"" withString:@"@"] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        [varsAry addObject:[NSString stringWithFormat:@"%@<%@>@i", name, type]];
    }
    free(ivars);
    return varsAry;
}

// name<pptClass>@p
+ (NSArray *)getProperties:(Class)cls {
    unsigned int count = 0;
    objc_property_t *properties = nil;
    properties = class_copyPropertyList(cls, &count);
    NSMutableArray *pptArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        objc_property_t property = nil;
        property = properties[i];
        const char *cName = property_getName(property);
        NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        [pptArray addObject:name];
    }
    NSMutableArray *retAry = [NSMutableArray array];
    for (NSString *pptName in pptArray) {
        NSString *className = [YKWObjectTableView getPropertyClass:pptName inClass:cls];
        if (className.length) {
            [retAry addObject:[NSString stringWithFormat:@"%@<%@>@p", pptName, className]];
        } else {
//            [retAry addObject:[NSString stringWithFormat:@"%@@p", pptName]];
        }
    }
    free(properties);
    return retAry;
}

+ (NSString *)getPropertyClass:(NSString *)property inClass:(Class)class {
    objc_property_t p = class_getProperty(class, property.UTF8String);
    const char *cName = property_getAttributes(p);
    NSString *attrs = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
    NSInteger dotLoc = [attrs rangeOfString:@","].location;
    NSString *code = nil;
    NSInteger loc = 3;
    if (dotLoc == NSNotFound && attrs.length > 3) {
        code = [attrs substringFromIndex:loc];
    } else if (dotLoc != NSNotFound && dotLoc - loc - 1 > 0) {
        code = [attrs substringWithRange:NSMakeRange(loc, dotLoc - loc - 1)];
    }
    return code;
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [super isKindOfClass:aClass];
}

@end

@implementation YKWObjectTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.separatorInset = UIEdgeInsetsZero;
        self.selectionStyle = UITableViewCellSeparatorStyleSingleLine;
        [self.contentView addSubview:self.txtLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        self.contentView.backgroundColor = YKWHighlightColor;
        _txtLabel.textColor = YKWForegroudColor;
    } else {
        self.contentView.backgroundColor = YKWForegroudColor;
        _txtLabel.textColor = YKWBackgroudColor;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _txtLabel.ykw_left = YKWObjectTableViewMargin;
    _txtLabel.ykw_width = self.ykw_width - YKWObjectTableViewMargin * 2;
    _txtLabel.ykw_height = self.ykw_height - 4;
    _txtLabel.ykw_centerY = self.ykw_height / 2;
}

- (UILabel *)txtLabel {
    if (!_txtLabel) {
        _txtLabel = [UILabel new];
        _txtLabel.font = [UIFont systemFontOfSize:12.];
        _txtLabel.backgroundColor = [UIColor clearColor];
        _txtLabel.textColor = [UIColor blackColor];
        _txtLabel.minimumScaleFactor = 0.3;
        _txtLabel.adjustsFontSizeToFitWidth = YES;
        _txtLabel.numberOfLines = 0;
    }
    return _txtLabel;
}

@end
