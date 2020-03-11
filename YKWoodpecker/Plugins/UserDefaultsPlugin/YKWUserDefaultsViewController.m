//
//  YKWUserDefaultsViewController.m
//  YKWoodpecker
//
//  Created by Zim on 2019/6/14.
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

#import "YKWUserDefaultsViewController.h"
#import "YKWTextViewController.h"
#import "YKWoodpeckerMessage.h"

@interface YKWUserDefaultsCell : UITableViewCell
@end

@implementation YKWUserDefaultsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

@end

@interface YKWUserDefaultsViewController ()<UITextFieldDelegate> {
    NSDictionary *_userDefaultsDictionary;
    NSMutableArray *_allKeysArray;
    NSString *_filterKey;
}

@end

@implementation YKWUserDefaultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"User Defaults";

    [self loadUserDefaults];
    
    [self.tableView registerClass:[YKWUserDefaultsCell class] forCellReuseIdentifier:@"YKWUserDefaultsCell"];
    self.navigationItem.rightBarButtonItems = @[self.editButtonItem, [[UIBarButtonItem alloc] initWithTitle:@"╋" style:UIBarButtonItemStyleDone target:self action:@selector(addUserDefaults)]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"╳" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.ykw_width, 60)];
    headerView.backgroundColor = [UIColor whiteColor];
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 15, headerView.ykw_width - 40, 30)];
    textField.borderStyle = UITextBorderStyleNone;
    textField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    textField.layer.cornerRadius = 2;
    textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.placeholder = @"Search";
    textField.clearButtonMode = UITextFieldViewModeAlways;
    textField.delegate = self;
    [headerView addSubview:textField];
    self.tableView.tableHeaderView = headerView;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)loadUserDefaults {
    _userDefaultsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    _allKeysArray = [_userDefaultsDictionary.allKeys mutableCopy];
    [_allKeysArray sortUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
        return [[obj1 lowercaseString] compare:[obj2 lowercaseString]];
    }];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addUserDefaults {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Add a user default" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Key";
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Value";
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSString *key = [alertController.textFields firstObject].text;
        NSString *value = [alertController.textFields lastObject].text;
        if (key.length && value.length) {
            NSString *regex = @"[0-9]*";
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
            if ([pred evaluateWithObject:value]) {
                [[NSUserDefaults standardUserDefaults] setObject:@(value.longLongValue) forKey:key];
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            [YKWoodpeckerMessage showMessage:@"Done"];
            
            [self loadUserDefaults];
            [self.tableView reloadData];
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    _filterKey = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.tableView selector:@selector(reloadData) object:nil];
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    _filterKey = nil;
    [self.tableView reloadData];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    _filterKey = textField.text;
    [self.tableView reloadData];
    return YES;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _allKeysArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [_allKeysArray ykw_objectAtIndex:indexPath.row];
    if (_filterKey.length && [key.lowercaseString rangeOfString:_filterKey.lowercaseString].location == NSNotFound) {
        return 0.;
    }
    return 60.;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKWUserDefaultsCell" forIndexPath:indexPath];
    cell.clipsToBounds = YES;
    NSString *key = [_allKeysArray ykw_objectAtIndex:indexPath.row];
    cell.textLabel.text = key;
    cell.detailTextLabel.text = [[[_userDefaultsDictionary objectForKey:key] description] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *key = [_allKeysArray ykw_objectAtIndex:indexPath.row];
        [_allKeysArray removeObject:key];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [_allKeysArray ykw_objectAtIndex:indexPath.row];
    NSObject *value = [_userDefaultsDictionary objectForKey:key];
    YKWTextViewController *txtViewController = [[YKWTextViewController alloc] init];
    txtViewController.content = value.description;
    [self.navigationController pushViewController:txtViewController animated:YES];
}

@end
