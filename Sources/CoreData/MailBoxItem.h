//
//  MailBoxItem.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 04.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreDataManager.h"

extern NSString *const MailBoxItemClassName;



@interface MailBoxItem : NSManagedObject

@property (nonatomic, retain, readonly) NSDate * createdAt;
@property (nonatomic, retain) NSString * mailBoxTitle;
@property (nonatomic, retain) NSSet *dialogItems;
@property (nonatomic, retain, readonly) NSNumber *isImmutable;
@property (nonatomic, retain, readonly) NSString *url;

+(MailBoxItem *)newMailBoxItemInManagedObjectContext: (NSManagedObjectContext *)context title: (NSString *)title url: (NSString *)url immutable: (BOOL)immutable orOldMailBoxItemFetchedInstead: (MailBoxItem * __autoreleasing *)oldMailbox;

+(NSFetchedResultsController *)fetchedResultsControllerForAllMailBoxItemsInManagedObjectContext: (NSManagedObjectContext *)context;

+(NSFetchedResultsController *)fetchedResultsControllerForImmitableMailBoxesInManagedObjectContext: (NSManagedObjectContext *)context;

+(void)deleteAllInManagedObjectContext: (NSManagedObjectContext *)context;

@end

@interface MailBoxItem (CoreDataGeneratedAccessors)

- (void)addDialogItemsObject:(DialogItem *)value;
- (void)removeDialogItemsObject:(DialogItem *)value;
- (void)addDialogItems:(NSSet *)values;
- (void)removeDialogItems:(NSSet *)values;

@end
