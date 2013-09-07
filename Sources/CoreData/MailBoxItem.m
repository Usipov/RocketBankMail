//
//  MailBoxItem.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 04.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "MailBoxItem.h"
#import "DialogItem.h"

NSString *const MailBoxItemClassName = @"MailBoxItem";
NSString *const MailBoxItemCacheName = @"All mailboxes in one cache ))";

@interface MailBoxItem ()

+(MailBoxItem *)findSuitableMailBoxItemWithTitle: (NSString *)title inManagedObjectContext: (NSManagedObjectContext *)context;

+(NSFetchRequest *)fetchRequestForMailBoxTitle: (NSString *)title immutableObjects: (NSNumber *)immutable inManagedObjectContext: (NSManagedObjectContext *)context;

+(NSPredicate *)predicateForMailBoxTitle: (NSString *)title immutableObjects: (NSNumber *)immutable;

@property (nonatomic, retain, readwrite) NSDate *createdAt;
@property (nonatomic, retain, readwrite) NSNumber *isImmutable;
@property (nonatomic, retain, readwrite) NSString *url;

@end


@implementation MailBoxItem

@dynamic createdAt;
@dynamic mailBoxTitle;
@dynamic dialogItems;
@dynamic url;

#pragma mark - public methods

+(MailBoxItem *)newMailBoxItemInManagedObjectContext:(NSManagedObjectContext *)context title:(NSString *)title url:(NSString *)url immutable:(BOOL)immutable orOldMailBoxItemFetchedInstead:(MailBoxItem *__autoreleasing *)oldMailbox
{
    NSAssert(context, @"nil MOC");
    NSAssert(title, @"nil title");
    
    //search for an existing suitable mailbox item
    MailBoxItem *oldSuitableMailBox = [self findSuitableMailBoxItemWithTitle: title inManagedObjectContext: context];
    if (oldSuitableMailBox) {
        *oldMailbox = oldSuitableMailBox;
        return nil;
    }
    
    //allocate new one
    MailBoxItem *newMailbox = (MailBoxItem *)[NSEntityDescription insertNewObjectForEntityForName: MailBoxItemClassName inManagedObjectContext: context];

    newMailbox.createdAt = [NSDate date];
    newMailbox.mailBoxTitle = title;
    newMailbox.isImmutable = [NSNumber numberWithBool: immutable];
    newMailbox.url = url;
    
    return newMailbox;
}

+(NSFetchedResultsController *)fetchedResultsControllerForAllMailBoxItemsInManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    
    NSFetchRequest *fetchRequest = [self fetchRequestForMailBoxTitle: nil immutableObjects: nil inManagedObjectContext: context];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: context sectionNameKeyPath: nil cacheName: MailBoxItemCacheName];
    
    return controller;
}

+(NSFetchedResultsController *)fetchedResultsControllerForImmitableMailBoxesInManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    
    BOOL willScanOnlyForImmutableItems = YES;
    
    NSFetchRequest *fetchRequest = [self fetchRequestForMailBoxTitle: nil immutableObjects: [NSNumber numberWithBool: willScanOnlyForImmutableItems] inManagedObjectContext: context];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: context sectionNameKeyPath: nil cacheName: nil];
    
    return controller;
}

+(void)deleteAllInManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");    
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: MailBoxItemClassName inManagedObjectContext: context];

    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = entity;
    
    NSArray *itemsToDelete = [context executeFetchRequest: request error: nil];
    
    [itemsToDelete enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        MailBoxItem *item = (MailBoxItem *)obj;
        [context deleteObject: item];
    }];
}

#pragma mark - private mathods
            
+(MailBoxItem *)findSuitableMailBoxItemWithTitle: (NSString *)title inManagedObjectContext: (NSManagedObjectContext *)context
{
    MailBoxItem *mailboxItem = nil;
    
    NSFetchRequest *request = [NSFetchRequest new];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: MailBoxItemClassName inManagedObjectContext: context];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"mailBoxTitle == %@", title];
    
    request.entity = entity;
    request.predicate = predicate;
    
    __autoreleasing NSError *error = nil;
    NSArray *objects = [context executeFetchRequest: request error: &error];
    if (! objects) {
        if (error) {
            NSLog(@"failed to fetch objects in %s", __FUNCTION__);
            NSLog(@"    error: %@", error);
        }
    } else {
        NSAssert(objects.count < 2, @"to many %@ objects with name: %@ were fetched", MailBoxItemClassName, title);
        if (objects.count > 0) {
            mailboxItem = objects[0];
        }
    }
    
    return mailboxItem;
}


+(NSFetchRequest *)fetchRequestForMailBoxTitle: (NSString *)title immutableObjects: (NSNumber *)immutable inManagedObjectContext: (NSManagedObjectContext *)context;
{
    NSFetchRequest *request = [NSFetchRequest new];

    NSEntityDescription *entity = [NSEntityDescription entityForName: MailBoxItemClassName inManagedObjectContext: context];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey: @"createdAt" ascending: YES];
    
    NSPredicate *predicate = [self predicateForMailBoxTitle: title immutableObjects: immutable];
    
    request.entity = entity;
    request.sortDescriptors = @[descriptor];
    request.predicate = predicate;
    
    return request;
}

+(NSPredicate *)predicateForMailBoxTitle: (NSString *)title immutableObjects: (NSNumber *)immutable
{
    NSPredicate *predicate = nil;
    
    NSMutableString *predicateString = [NSMutableString new];
    NSString *titlePart, *immutablePart;
        
    if (title) {
        titlePart = [NSString stringWithFormat: @"mailBoxTitle == %@", title];
        [predicateString appendString: titlePart];
    }
    if (immutable) {
        immutablePart = [NSString stringWithFormat: @"isImmutable == %@", immutable];
        
        if (title) {
            [predicateString appendString: @" && "];
        }
        [predicateString appendString: immutablePart];
    }

    if (predicateString) {
        predicate = [NSPredicate predicateWithFormat: predicateString];
    }
    
    return predicate;
}

@end
