//
//  MailItem.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "MailItem.h"
#import "DialogItem.h"
#import "MailBoxTimestampItem.h"

#define kDATA_BODY_KEY              @"body"
#define kDATA_FROM_KEY              @"from"
#define kDATA_ID_KEY                @"id"
#define kDATA_IN_REPLY_TO_ID_KEY    @"in_reply_to_id"
#define kDATA_MESSAGES_KEY          @"messages"
#define kDATA_RECIEVED_AT_KEY       @"received_at"
#define kDATA_STARRED_KEY           @"starred"
#define kDATA_SUBJECT_KEY           @"subject"
#define kDATA_TO_KEY                @"to"

#define kDATE_FORMAT_STRING     @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"

NSString *const MailItemClassName = @"MailItem";

@interface MailItem ()
+(MailItem *)mailItemInManagedObjectContext: (NSManagedObjectContext *)context basedOnData: (NSDictionary *)data;
+(NSPredicate *)predicateForSearchBasedOnData: (NSDictionary *)data;
@end

@implementation MailItem

@dynamic body;
@dynamic from;
@dynamic identifier;
@dynamic mailboxType;
@dynamic messages;
@dynamic recievedAt;
@dynamic starred;
@dynamic subject;
@dynamic to;

@dynamic timestampItem;
@dynamic replyTargetItem;
@dynamic dialogItem;


#pragma mark - public methods
#pragma mark class methods


+(MailItem *)newInManagedObjectContext:(NSManagedObjectContext *)context mailBoxItem:(MailBoxItem *)mailBoxItem basedOnData:(NSDictionary *)data orOldMailItemFetchedInstead:(MailItem *__autoreleasing *)oldItem
{
    NSAssert(context, @"nil MOC");
    NSAssert(data, @"nil data");
    
    //search for an item
    MailItem *fetchedItem = [self mailItemInManagedObjectContext: context basedOnData: data];
    
    if (fetchedItem) {
        //return a fetched object 
        *oldItem = fetchedItem;
        return nil;
    }

    //create an object
    MailItem *item = (MailItem *)[NSEntityDescription insertNewObjectForEntityForName: MailItemClassName inManagedObjectContext: context];
    
    if (item) {
        item.body = [data objectForKey: kDATA_BODY_KEY];
        item.from = [data objectForKey: kDATA_FROM_KEY];
        item.identifier = [data objectForKey: kDATA_ID_KEY];
        item.messages = [NSNumber numberWithInt: [[data objectForKey: kDATA_MESSAGES_KEY] intValue]];
        
        NSString *dateRepresentation = [data objectForKey: kDATA_RECIEVED_AT_KEY];
        NSDateFormatter *formatter = [NSDateFormatter new];
        [formatter setLocale: [NSLocale systemLocale]];
        [formatter setDateFormat: kDATE_FORMAT_STRING];
        item.recievedAt = [formatter dateFromString: dateRepresentation];

        item.starred = [NSNumber numberWithBool: [[data objectForKey: kDATA_STARRED_KEY] boolValue]];
        item.subject = [data objectForKey: kDATA_SUBJECT_KEY];
        item.to = [data objectForKey: kDATA_TO_KEY];
    }
    return item;
}



+(void)deleteAllMailItemsInMOC: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    
    
}


+(NSFetchRequest *)requestForMailItemBeingTargetOfInReplyMailItem: (MailItem *)inReplyMailItem inManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    NSAssert(inReplyMailItem, @"nil %@", NSStringFromClass(inReplyMailItem.class));
    
    NSFetchRequest *request = [NSFetchRequest new];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: MailItemClassName inManagedObjectContext: context];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"identifier == %@", inReplyMailItem.inReplyToIdentifier];
    
    request.entity = entity;
    request.predicate = predicate;
    
    return request;
}

+(void)deleteAllInManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: MailItemClassName inManagedObjectContext: context];
    
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = entity;
    
    NSArray *itemsToDelete = [context executeFetchRequest: request error: nil];
    
    [itemsToDelete enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        MailItem *item = (MailItem *)obj;
        [context deleteObject: item];
    }];
}

#pragma mark - private methods

+(MailItem *)mailItemInManagedObjectContext: (NSManagedObjectContext *)context basedOnData: (NSDictionary *)data
{
    NSAssert(context, @"nil MOC");
    
    MailItem *mailItem = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: MailItemClassName inManagedObjectContext: context];
    fetchRequest.entity = entity;

    NSPredicate *predicate = [self predicateForSearchBasedOnData: data];
    fetchRequest.predicate = predicate;
    
    __autoreleasing NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest: fetchRequest error: &error];
    
    if (fetchedObjects == nil) {
        if (error) {
            #ifdef DEBUG
            NSLog(@"failed to fectch: %s", __FUNCTION__);
            NSLog(@"error: %@", error);
            #endif
        }
    } else {
        NSAssert(fetchedObjects.count < 2, @"duplicate %@ object found", NSStringFromClass(mailItem.class));
        
        if (fetchedObjects.count > 0) {
            mailItem = fetchedObjects[0];
        }
    }

    return mailItem;
}

+(NSPredicate *)predicateForSearchBasedOnData: (NSDictionary *)data
{
    NSMutableString *formatString = [NSMutableString new];
    [formatString appendFormat: @"identifier == %@", [data objectForKey: kDATA_ID_KEY]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: formatString];
    return predicate;
}

@end
