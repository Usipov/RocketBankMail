//
//  MailsView.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 02.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataManager.h"

enum TableIndexes {
    TableIndexLeft = 0,
    TableIndexMid = 1,
    TableIndexRight = 2
};
@interface MailsView : UIView

-(id)initWithFrame:(CGRect)frame mailboxItems: (NSArray *)mailboxItems tableStyle: (UITableViewStyle)style tableDelegate: (id<UITableViewDelegate>)delegate tableDataSource: (id<UITableViewDataSource>)dataSource;

-(void)setSelectedTableAtIndex: (NSUInteger)index animated: (BOOL)animated;
-(UITableView *)tableViewAtIndex: (NSUInteger)index;
-(NSUInteger)indexOfTableView: (UITableView *)tableView;


@end
