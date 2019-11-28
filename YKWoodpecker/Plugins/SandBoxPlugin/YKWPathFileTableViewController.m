//
//  YKWPathFileTableViewController.m
//  YKWoodpecker
//
//  Created by Zim on 2019/3/19.
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

#import "YKWPathFileTableViewController.h"
#import "YKWTextViewController.h"
#import "YKWoodpeckerMessage.h"
#import "YKWImageTextPreview.h"

#define kYKWPathFileTableViewControllerTxtTypes @[@"", @"txt", @"plist", @"json", @"xml", @"strings", @"log", @"setting", @"js", @"config"]
#define kYKWPathFileTableViewControllerImageTypes @[@"png", @"PNG", @"jpg", @"JPG"]

@interface YKWPathFileTableViewController () {
    NSMutableArray *_subpathsAry;
}

@end

@implementation YKWPathFileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"╳" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    
    [self.tableView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)]];
    
    if (self.path) {
        if (!self.title) {
            self.title = self.path.lastPathComponent;
        }
        _subpathsAry = [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil] sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
            return [obj1.lowercaseString compare:obj2.lowercaseString];
        }] mutableCopy];
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"YKWPathFileTableViewControllerTip"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"YKWPathFileTableViewControllerTip"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [YKWoodpeckerMessage showMessage:YKWLocalizedString(@"Long press to share") duration:5.];
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        NSString *subpath = [_subpathsAry ykw_objectAtIndex:indexPath.row];
        BOOL isDirectory = NO;
        NSString *fullPath = [self.path stringByAppendingPathComponent:subpath];
        [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
        NSURL *url = [NSURL fileURLWithPath:fullPath isDirectory:isDirectory];
        if (url) {
            [YKWoodpeckerUtils showShareActivityWithItems:@[url]];
        }
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _subpathsAry.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.5;
    cell.textLabel.text = [_subpathsAry ykw_objectAtIndex:indexPath.row];
    
//    long size = [self getPathSize:[_subpathsAry ykw_objectAtIndex:indexPath.row]];
//    if (size > 1024 * 1024 * 1024) {
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.3fGB", size / 1024. / 1024. /1024.];
//    } else if (size > 1024 * 1024) {
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.3fMB", size / 1024. / 1024.];
//    } else if (size > 1024) {
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.3fKB", size / 1024.];
//    } else {
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ldB", size];
//    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *subpath = [_subpathsAry ykw_objectAtIndex:indexPath.row];
        NSString *fullPath = [self.path stringByAppendingPathComponent:subpath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            NSError *er = nil;
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&er];
            if (er) {
                [YKWoodpeckerMessage showMessage:er.description];
            } else {
                [_subpathsAry removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *subpath = [_subpathsAry ykw_objectAtIndex:indexPath.row];
    if (subpath) {
        BOOL isDirectory = NO;
        NSString *fullPath = [self.path stringByAppendingPathComponent:subpath];
        [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
        if (isDirectory) {
            YKWPathFileTableViewController *controller = [[YKWPathFileTableViewController alloc] init];
            controller.path = [self.path stringByAppendingPathComponent:subpath];
            [self.navigationController pushViewController:controller animated:YES];
        } else if ([kYKWPathFileTableViewControllerTxtTypes containsObject:fullPath.pathExtension]) {
            YKWTextViewController *controller = [[YKWTextViewController alloc] init];
            controller.contentPath = fullPath;
            [self.navigationController pushViewController:controller animated:YES];
        } else if ([kYKWPathFileTableViewControllerImageTypes containsObject:fullPath.pathExtension]) {
            YKWImageTextPreview *preview = [[YKWImageTextPreview alloc] init];
            preview.image = [UIImage imageWithContentsOfFile:fullPath];
            [preview show];
        } else {
            NSURL *url = [NSURL fileURLWithPath:fullPath isDirectory:NO];
            if (url) {
                [YKWoodpeckerUtils showShareActivityWithItems:@[url]];
            }
        }
    }
}

// Bad
//- (long)getPathSize:(NSString *)path {
//    long totalSize = 0;
//    BOOL isDirectory = NO;
//    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
//    if (isExist){
//        if(isDirectory) {
//            NSArray *pathsAry = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
//            for(NSString *subpath in pathsAry) {
//                totalSize += [self getPathSize:[path stringByAppendingPathComponent:subpath]];
//            }
//        } else {
//            NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
//            totalSize += [dic[@"NSFileSize"] longLongValue];
//        }
//    }
//    return totalSize;
//}

@end
