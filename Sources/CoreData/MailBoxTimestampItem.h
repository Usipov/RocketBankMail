//
//  MailBoxDownloadItem.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 03.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "CoreDataManager.h"

extern NSString *const MailBoxTimestampItemClassName;

//a timestamp item. items are used to observe separated download areas out of a full list (server list).
//new mail pages for every mailbox are donwloaded gradually one by one since a page, containing a relevantMailItem (relevant item is a MailItem object, derived from a top mail record on a downlaoded most relevant page ('0' page)

@interface MailBoxTimestampItem : NSManagedObject

@property (nonatomic, retain) NSNumber * pagesDownloadedSinceRelevantItem;
@property (nonatomic, retain) MailItem *relevantMailItem;

+(MailBoxTimestampItem *)newInManagedObjectContext: (NSManagedObjectContext *)context mailItem: (MailItem *)item;

+(NSFetchedResultsController *)fetchedResultsControllerForMailBoxItem: (MailBoxItem *)mailboxItem inManagedObjectContext: (NSManagedObjectContext *)context;

//usually item is newer than item2. item2 will be deleted. page counts will be merged
+(void)mergeMailBoxDownlaodItem: (MailBoxTimestampItem *)item withItem: (MailBoxTimestampItem *)item2 inManagedObjectContext: (NSManagedObjectContext *)context;

+(void)deleteAllInManagedObjectContext: (NSManagedObjectContext *)context;

@end
