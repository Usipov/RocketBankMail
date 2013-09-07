//
//  MailBoxDownloadItem.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 03.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "MailBoxTimestampItem.h"
#import "MailItem.h"

NSString *const MailBoxTimestampItemClassName = @"MailBoxTimestampItem";
NSString *const MailBoxTimestampItemsCacheName = @"MailBox metadata objects to observe download history";

@interface MailBoxTimestampItem ()

@end

@implementation MailBoxTimestampItem

@dynamic pagesDownloadedSinceRelevantItem;
@dynamic relevantMailItem;

#pragma mark - public methods

+(MailBoxTimestampItem *)newInManagedObjectContext: (NSManagedObjectContext *)context mailItem: (MailItem *)item
{
    NSAssert(context, @"nil MOC");
    NSAssert(item, @"nil %@", NSStringFromClass(item.class));
    
    MailBoxTimestampItem *timestampItem = (MailBoxTimestampItem *)[NSEntityDescription insertNewObjectForEntityForName: MailBoxTimestampItemClassName inManagedObjectContext: context];
    
    if (timestampItem) {
        timestampItem.relevantMailItem  = item;
        item.timestampItem = timestampItem;
        timestampItem.pagesDownloadedSinceRelevantItem = [NSNumber numberWithInteger: 1];
    }
    return timestampItem;
}

+(NSFetchedResultsController *)fetchedResultsControllerForMailBoxItem: (MailBoxItem *)mailboxItem inManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    NSAssert(mailboxItem, @"nil %@", NSStringFromClass(mailboxItem.class));
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: MailBoxTimestampItemClassName inManagedObjectContext: context];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey: @"relevantMailItem.recievedAt" ascending: NO];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"relevantMailItem.dialogItem.mailboxItem == %@", mailboxItem];
    
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = entity;
    request.sortDescriptors = @[descriptor];
    request.predicate = predicate;
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest: request managedObjectContext: context sectionNameKeyPath: nil cacheName: nil];
    
    return controller;
}

+(void)mergeMailBoxDownlaodItem: (MailBoxTimestampItem *)item withItem: (MailBoxTimestampItem *)item2 inManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    NSAssert(item, @"nil %@", NSStringFromClass(item.class));
    NSAssert(item, @"nil %@", NSStringFromClass(item2.class));
    NSAssert(item == item2, @"tried to merge a same timestamp item with itself");
    
    MailBoxTimestampItem *mostRecentItem;
    MailBoxTimestampItem *itemToDelete;
    
    if ([item.relevantMailItem.recievedAt compare: item2.relevantMailItem.recievedAt] == NSOrderedDescending) {
        mostRecentItem = item;
        itemToDelete = item2;
    } else {
        mostRecentItem = item2;
        itemToDelete = item;
    }
    
    //compute new page count of a most relevant item
    NSUInteger summaryPagesCount = mostRecentItem.pagesDownloadedSinceRelevantItem.integerValue + itemToDelete.pagesDownloadedSinceRelevantItem.integerValue - 1;
    mostRecentItem.pagesDownloadedSinceRelevantItem = [NSNumber numberWithInteger: summaryPagesCount];
    
    //delete an older timestamp item
    [context deleteObject: itemToDelete];
}

+(void)deleteAllInManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: MailBoxTimestampItemClassName inManagedObjectContext: context];
    
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = entity;
    
    NSArray *itemsToDelete = [context executeFetchRequest: request error: nil];
    
    [itemsToDelete enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        MailBoxTimestampItem *item = (MailBoxTimestampItem *)obj;
        [context deleteObject: item];
    }];
}


@end
