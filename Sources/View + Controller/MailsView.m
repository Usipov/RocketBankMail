//
//  MailsView.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 02.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MailsView.h"

@interface MailsView () {
    NSMutableArray      *_tableViews;
    NSUInteger           _selectedIndex;
}

@end


@implementation MailsView

@synthesize selectedTableIndex = _selectedIndex;

-(id)initWithFrame:(CGRect)frame mailboxItems:(NSArray *)mailboxItems tableStyle:(UITableViewStyle)style tableDelegate:(id<UITableViewDelegate>)delegate tableDataSource:(id<UITableViewDataSource>)dataSource
{
    self = [super initWithFrame:frame];
    if (self) {self.backgroundColor = [UIColor whiteColor];
        _selectedIndex = NSNotFound;
        
        if (mailboxItems) {
            _tableViews = [NSMutableArray arrayWithCapacity: mailboxItems.count];
            
            for (int i = 0; i < mailboxItems.count; i++) {
                UITableView *tableView = [[UITableView alloc] initWithFrame: CGRectZero style: style];
                tableView.delegate = delegate;
                tableView.dataSource = dataSource;
                tableView.hidden = YES;
                tableView.backgroundView = nil;
                tableView.backgroundColor = [UIColor clearColor];
                
                [self addSubview: tableView];
                _tableViews[i] = tableView;
            }
        }
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame: frame mailboxItems: nil tableStyle: 0 tableDelegate: nil tableDataSource: nil];
    return self;
}

-(void)layoutSubviews
{
    CGRect frame = self.frame;
    frame.origin = CGPointZero;

    //layuot a selected table
    if (_selectedIndex != NSNotFound) {
        UITableView *selectedTable = _tableViews[_selectedIndex];
        selectedTable.frame = frame;
    }
}

#pragma mark - public methods

-(void)setSelectedTableAtIndex: (NSUInteger)index animated:(BOOL)animated
{
    if (index == _selectedIndex) { return; }
    
    NSUInteger oldSelectedIndex = _selectedIndex;
    _selectedIndex = index;
    
    if (oldSelectedIndex == NSNotFound) {
        //initial case
        
        UITableView *newTable = _tableViews[index];
        newTable.hidden = NO;
        
        CGRect frame = self.frame; frame.origin = CGPointZero;
        newTable.frame = frame;
    } else {
        //regular case
        
        UITableView *currentTable = _tableViews[oldSelectedIndex];
        UITableView *newTable = _tableViews[index];

        int offsetDirection = (index > oldSelectedIndex) ? 1 : -1;
        
        //place new table before amimations
        newTable.hidden = YES;
        newTable.frame = CGRectOffset(currentTable.frame, offsetDirection * currentTable.frame.size.width, 0.0);
        newTable.hidden = NO;
        
        //move tables
        NSTimeInterval animationDuration = (animated) ? kANIMATION_DURATION : 0.0;
        
        [UIView animateWithDuration: animationDuration delay: 0.0 options: UIViewAnimationCurveEaseInOut animations: ^{
            currentTable.frame = CGRectOffset(currentTable.frame, - offsetDirection * currentTable.frame.size.width, 0.0);
            newTable.frame = CGRectOffset(newTable.frame, - offsetDirection * newTable.frame.size.width, 0.0);
            
        } completion: ^(BOOL finished) {
            //set offscreen tables hidden
            currentTable.hidden = YES;
        }];
    }
}

-(UITableView *)tableViewAtIndex:(NSUInteger)index
{
    UITableView *tableView = nil;
    @try {
        tableView = _tableViews[index];
    } @catch (NSException *exception) {
        NSLog(@"exception: %@", exception);
    }
    return tableView;
}

-(NSUInteger)indexOfTableView: (UITableView *)tableView
{
    return [_tableViews indexOfObject: tableView];
}



@end
