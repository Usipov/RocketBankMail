//
//  MailsViewController.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataManager.h"

NSString *const BatchSizeKey;

@interface MailsViewController : UIViewController

-(id)initForThreeMailBoxesWithStyle: (UITableViewStyle)style;
-(id)initWithStyle: (UITableViewStyle)style singleMailBoxItem: (MailBoxItem *)mailbox;


@end
