//
//  MailPageDownloader.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 02.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataManager.h"

typedef void (^MailListDownloadFinishBlock) (NSDictionary *mailsData);
typedef void (^MailListDownloadErrorBlock) (NSError *error);

@interface MailPageDownloader : NSObject

-(void)cancelDownload;
-(void)downloadMailsForMailBoxItem: (MailBoxItem *)mailbox page: (NSNumber *)page finishBlock: (MailListDownloadFinishBlock)finishBlock errorBlock: (MailListDownloadErrorBlock)errorBlock;


@property (nonatomic, retain, readonly) MailBoxItem *mailbox;
@property (nonatomic, retain, readonly) NSNumber *page;
@property (nonatomic, readonly) BOOL isBuzy;

@end
