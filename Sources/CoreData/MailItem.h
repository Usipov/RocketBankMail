//
//  MailItem.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreDataManager.h"

extern NSString *const MailItemClassName;

@class DialogItem;
@class MailBoxTimestampItem;

@interface MailItem : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * from;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * inReplyToIdentifier;
@property (nonatomic, retain) NSNumber * mailboxType;
@property (nonatomic, retain) NSNumber * messages;
@property (nonatomic, retain) NSDate * recievedAt;
@property (nonatomic, retain) NSNumber * starred;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSString * to;

@property (nonatomic, retain) DialogItem *dialogItem;
@property (nonatomic, retain) MailItem *replyTargetItem;
@property (nonatomic, retain) MailBoxTimestampItem *timestampItem;


+(MailItem *)newInManagedObjectContext: (NSManagedObjectContext *)context mailBoxItem: (MailBoxItem *)mailboxItem basedOnData: (NSDictionary *)data orOldMailItemFetchedInstead: (MailItem * __autoreleasing *)oldItem;

+(void)deleteAllMailItemsInMOC: (NSManagedObjectContext *)context;

+(NSFetchRequest *)requestForMailItemBeingTargetOfInReplyMailItem: (MailItem *)inReplyMailItem inManagedObjectContext: (NSManagedObjectContext *)context;

+(void)deleteAllInManagedObjectContext: (NSManagedObjectContext *)context;

@end
