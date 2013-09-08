//
//  MailListDownloader.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MailPageDownloader.h"

#import "CoreDataManager.h"

@interface MailDownloadManager : NSObject

+(MailDownloadManager *)sharedDownloader;

-(void)downloadMostRecentMailsForMailBoxItem: (MailBoxItem *)mailboxItem;
-(void)downloadMoreMailsForMailBoxItem: (MailBoxItem *)mailboxItem;
-(void)cancelAllDownloads;

@end
