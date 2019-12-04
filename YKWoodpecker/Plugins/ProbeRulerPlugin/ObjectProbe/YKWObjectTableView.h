//
//  YKWObjectTableView.h
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

#import <UIKit/UIKit.h>

@class YKWObjectTableView;
@protocol YKWObjectTableViewDelegate <NSObject>

@optional
- (void)objectTableView:(YKWObjectTableView *)objTableView didSelectNonObject:(id)sth class:(Class)cls key:(NSString *)key;

- (void)objectTableView:(YKWObjectTableView *)objTableView didSelectObject:(NSObject *)object class:(Class)cls key:(NSString *)key;

- (void)objectTableView:(YKWObjectTableView *)objTableView didTapOnObject:(NSObject *)object key:(NSString *)key;

@end

/**
 An object's property and member var list.
 */
@interface YKWObjectTableView : UITableView

@property (nonatomic, weak) id<YKWObjectTableViewDelegate> objDelegate;

/**
 The object to probe.
 */
@property (nonatomic, strong) NSObject *probedObject;

/**
The object index to show.
*/
@property (nonatomic, assign) NSInteger objectIndex;

/**
 The class level to probe.
 */
@property (nonatomic, strong) Class probeClass;

@end

@interface YKWObjectTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *txtLabel;

@end
