//
//  DialogItem.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 04.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString *const DialogItemClassName;

@class MailBoxItem, MailItem;

@interface DialogItem : NSManagedObject

@property (nonatomic, retain, readonly) NSDate * efficientDate;

@property (nonatomic, retain) NSSet *mailItems;
@property (nonatomic, retain) MailBoxItem *mailboxItem;

+(DialogItem *)newDialogInManagedObjectContext: (NSManagedObjectContext *)context mailItem: (MailItem *)mailItem mailbox: (MailBoxItem *)mailbox orOldDialogItemFetchedInstead: (DialogItem * __autoreleasing *)oldDialog;

+(NSFetchedResultsController *)fetchedResultsControllerForMailBox: (MailBoxItem *)mailbox inManagedObjectContext: (NSManagedObjectContext *)context;

+(void)deleteAllInManagedObjectContext: (NSManagedObjectContext *)context;

@end

@interface DialogItem (CoreDataGeneratedAccessors)

- (void)addMailItemsObject:(MailItem *)value;
- (void)removeMailItemsObject:(MailItem *)value;
- (void)addMailItems:(NSSet *)values;
- (void)removeMailItems:(NSSet *)values;

@end
