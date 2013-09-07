//
//  DialogItem.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 04.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "CoreDataManager.h"
#import "DialogItem.h"

NSString *const DialogItemClassName = @"DialogItem";

static NSMutableDictionary *st_fetchedResultsControllers;

@interface DialogItem ()

+(DialogItem *)findSuitableDialogItemForMailItem: (MailItem *)mailItem inMailbox: (MailBoxItem *)mailbox inManagedObjectContext: (NSManagedObjectContext *)context;

+(DialogItem *)dialogItemForInReplyMailItem: (MailItem *)mailItemInReply inManagedObjectContext: (NSManagedObjectContext *)context;

+(NSFetchRequest *)fetchRequestForDialogItem: (DialogItem *)dialog inManagedObjectContext: (NSManagedObjectContext *)context;

-(NSArray *)sortedMailItems;

@property (nonatomic, retain, readwrite) NSDate * efficientDate;

@end

@implementation DialogItem

@dynamic efficientDate;

@dynamic mailItems;
@dynamic mailboxItem;

+(void)initialize
{
    [super initialize];
    st_fetchedResultsControllers = [NSMutableDictionary new];
}

#pragma mark - public methods

+(DialogItem *)newDialogInManagedObjectContext: (NSManagedObjectContext *)context mailItem: (MailItem *)mailItem mailbox: (MailBoxItem *)mailbox orOldDialogItemFetchedInstead: (DialogItem * __autoreleasing *)oldDialog
{
    NSAssert(context, @"nil MOC");
    NSAssert(mailItem, @"nil %@", NSStringFromClass(mailItem.class));
    NSAssert(mailbox, @"nil %@", NSStringFromClass(mailItem.class));
    
    //fetch a suitable existing dialog 
    DialogItem *oldSuitableDialogItem = [self findSuitableDialogItemForMailItem: mailItem inMailbox: mailbox inManagedObjectContext: context];
    if (oldSuitableDialogItem) {
        oldSuitableDialogItem.efficientDate = mailItem.recievedAt;
        *oldDialog = oldSuitableDialogItem;
        return nil;
    }
    
    //instantiate a new object
    DialogItem *newDialogItem = (DialogItem *)[NSEntityDescription insertNewObjectForEntityForName: DialogItemClassName inManagedObjectContext: context];
    newDialogItem.mailboxItem = mailbox;
    newDialogItem.efficientDate = mailItem.recievedAt;
    
    mailItem.dialogItem = newDialogItem;

    return newDialogItem;
}

+(NSFetchedResultsController *)fetchedResultsControllerForMailBox:(MailBoxItem *)mailbox inManagedObjectContext:(NSManagedObjectContext *)context;
{
    NSAssert(context, @"nil MOC");
    NSAssert(mailbox, @"nil %@", NSStringFromClass(mailbox.class));
    
    NSFetchedResultsController *controller = [st_fetchedResultsControllers objectForKey: mailbox.createdAt];
    if (! controller) {
        NSFetchRequest *request = [self fetchRequestForMailBoxItem: mailbox inManagedObjectContext: context];
        
        controller = [[NSFetchedResultsController alloc] initWithFetchRequest: request managedObjectContext: context sectionNameKeyPath: nil cacheName: nil];
        
        [st_fetchedResultsControllers setObject: controller forKey: mailbox.createdAt];
    }
    return controller;
}

+(void)deleteAllInManagedObjectContext: (NSManagedObjectContext *)context
{
    NSAssert(context, @"nil MOC");
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: DialogItemClassName inManagedObjectContext: context];
    
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = entity;
    
    NSArray *itemsToDelete = [context executeFetchRequest: request error: nil];
    
    [itemsToDelete enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        DialogItem *item = (DialogItem *)obj;
        [context deleteObject: item];
    }];
}

#pragma mark - private methods

+(DialogItem *)findSuitableDialogItemForMailItem: (MailItem *)mailItem inMailbox: (MailBoxItem *)mailbox inManagedObjectContext: (NSManagedObjectContext *)context
{
    DialogItem *oldDialogItem = nil;
    
    //search for an old suitable instance
    if (mailItem.dialogItem) {
        oldDialogItem = mailItem.dialogItem;
    } else {
        //search for a recipient message item corresponding to a passed one
        if (mailItem.inReplyToIdentifier) {
            DialogItem *fetchedDialog = [self dialogItemForInReplyMailItem: mailItem inManagedObjectContext: context];
            if (fetchedDialog) {
                mailItem.dialogItem = fetchedDialog;
                oldDialogItem = fetchedDialog;
            }
        }
    }
    
    return oldDialogItem;
}

+(DialogItem *)dialogItemForInReplyMailItem: (MailItem *)mailItemInReply inManagedObjectContext:(NSManagedObjectContext *)context
{
    DialogItem *dialogItem = nil;
    
    NSFetchRequest *request = [MailItem requestForMailItemBeingTargetOfInReplyMailItem: mailItemInReply inManagedObjectContext: context];
    
    __autoreleasing NSError *error = nil;
    NSArray *objects = [context executeFetchRequest: request error: &error];
    if (! objects) {
        if (error) {
            NSLog(@"failed to fetch objects in %s", __FUNCTION__);
            NSLog(@"    error: %@", error);
        }
    } else {
        NSAssert(objects.count < 2, @"to many %@ objects fetched", MailItemClassName);
        if (objects.count > 0) {
            MailItem *mailItem = objects[0];
            mailItemInReply.replyTargetItem = mailItem;
            dialogItem = mailItem.dialogItem;
        }
    }
    
    return dialogItem;
}


+(NSFetchRequest *)fetchRequestForMailBoxItem: (MailBoxItem *)mailbox inManagedObjectContext: (NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest new];
    
    //entity
    NSEntityDescription *entity = [NSEntityDescription entityForName: DialogItemClassName inManagedObjectContext: context];
    [request setEntity: entity];
    
    //predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"mailboxItem == %@", mailbox];
    request.predicate = predicate;
    
    //sort descriptors
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey: @"efficientDate" ascending: NO];
    request.sortDescriptors = @[descriptor];
    
    return request;
}

-(NSArray *)sortedMailItems
{
    NSMutableArray *allMailItems = [self.mailItems.allObjects mutableCopy];
    [allMailItems sortUsingComparator: ^NSComparisonResult(id obj1, id obj2) {
        MailItem *mail1 = (MailItem *)obj1;
        MailItem *mail2 = (MailItem *)obj1;
        
        //sort in descending order
        return [mail2.recievedAt compare: mail1.recievedAt];
    }];
    return allMailItems;
}


@end

