//
//  MailListDownloader.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "MailDownloadManager.h"
#import "MailBoxTimestampItem.h"
#import "CoreDataManager.h"


#define kPARSING_PAGINATION_KEY @"pagination"
#define kPARSING_PER_PAGE_KEY   @"per_page"
#define kPARSING_EMAILS_KEY     @"emails"

@interface MailDownloadManager () <NSFetchedResultsControllerDelegate> {
    NSMutableDictionary         *_mailPageDownloaders;
    NSMutableDictionary         *_fetchedResultsControllerOfTimestamps;
}
-(id)keyForMailBoxItem: (MailBoxItem *)mailboxItem;
-(MailPageDownloader *)downloaderForMailBoxItem: (MailBoxItem *)mailboxItem;
-(void)setDownloader: (MailPageDownloader *)downloader forMailboxItem: (MailBoxItem *)mailboxItem;
-(NSArray *)fetchTimestampItemsForMailBoxItem: (MailBoxItem *)mailbox;
-(MailBoxTimestampItem *)newestTimestampItemForMailBoxItem: (MailBoxItem *)mailboxItem;
-(MailBoxTimestampItem *)nextTimestampItemForTimeStampItem: (MailBoxTimestampItem *)item;
-(void)pickDialogToNewMailItem: (MailItem *)mailItem inManagedObject: (NSManagedObjectContext *)context mailBoxItem: (MailBoxItem *)mailbox;
@end



@implementation MailDownloadManager

-(id)init
{
    self = [super init];
    if (self) {
        _mailPageDownloaders = [NSMutableDictionary new];
        _fetchedResultsControllerOfTimestamps = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - public methods

+(MailDownloadManager *)sharedDownloader
{
    static MailDownloadManager *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [self new];
    });
    return downloader;
}

-(void)downloadMostRecentMailsForMailBoxItem: (MailBoxItem *)mailboxItem
{
    MailPageDownloader *downloader = [self downloaderForMailBoxItem: mailboxItem];
    
    if (downloader) {
        [downloader cancelDownload];
    } else {
        //instatiate a new downloader
        downloader = [MailPageDownloader new];
        
        //record a downloader
        [self setDownloader: downloader forMailboxItem: mailboxItem];
    }
    
    //download fresh page ('0' page)
    [downloader downloadMailsForMailBoxItem: mailboxItem page: [NSNumber numberWithInteger: 0] finishBlock: ^(NSDictionary *mailsData) {
        
        //retrieve pagination data
        //NSDictionary *paginationData = [mailsData objectForKey: kPARSING_PAGINATION_KEY];
        //
        //get fetch results controller future batch size
        //NSString *itemsCount = [paginationData objectForKey: kPARSING_PER_PAGE_KEY];
        
        //create managed objects
        NSManagedObjectContext *context = [[CoreDataManager sharedManager] mainManagedObjectContext];
        
        //add items to core data
        NSArray *mailItemsData = [mailsData objectForKey: kPARSING_EMAILS_KEY];
                
        //enumerate downloaded dictionaries and parse them into mail items        
        [mailItemsData enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *mailData = (NSDictionary *)obj;

            __autoreleasing MailItem *oldMailItem = nil;
            MailItem *newMailItem = [MailItem newInManagedObjectContext: context mailBoxItem: mailboxItem basedOnData: mailData orOldMailItemFetchedInstead: &oldMailItem];
            
            if (newMailItem) {
                [self pickDialogToNewMailItem: newMailItem inManagedObject: context mailBoxItem: mailboxItem];
                
                //if top item is newly created, than we need a new timestamp)
                if (idx == 0) {
                    [MailBoxTimestampItem newInManagedObjectContext: context mailItem: newMailItem];
                }
            }
        }];
        
        //save context
        [[CoreDataManager sharedManager] saveMainManagedObjectContext];
        
    } errorBlock: ^(NSError *error) {
        [[[UIAlertView alloc] initWithTitle: error.localizedDescription message: error.localizedFailureReason delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil, nil] show];
    }];
}

-(void)downloadMoreMailsForMailBoxItem: (MailBoxItem *)mailboxItem
{
    NSAssert(mailboxItem, @"nil %@", NSStringFromClass(mailboxItem.class));
    
    //check for an already processing download
    MailPageDownloader *downloader = [self downloaderForMailBoxItem: mailboxItem];

    if (! downloader) {
        //instatiate a new downloader
        downloader = [MailPageDownloader new];
        
        //record a downloader
        [self setDownloader: downloader forMailboxItem: mailboxItem];
    } 
    
    if (NO == downloader.isBuzy) {
        //will start a download
        
        //get a timestamp item (meta data object)
        MailBoxTimestampItem *timestamp = [self newestTimestampItemForMailBoxItem: mailboxItem];
        if (timestamp) {
            //must have at least one valid timestamp for a mailboxType (it will record download history)
            
            //start a download
            [downloader downloadMailsForMailBoxItem: mailboxItem page: timestamp.pagesDownloadedSinceRelevantItem finishBlock: ^(NSDictionary *mailsData) {

                //create managed objects
                NSManagedObjectContext *context = [[CoreDataManager sharedManager] mainManagedObjectContext];
                
                NSArray *mailItemsData = [mailsData objectForKey: kPARSING_EMAILS_KEY];
                
                __block BOOL didIntersectNextTimestampItem = NO;
                
                //enumerate downloaded dictionaries and parse them into mail items
                [mailItemsData enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
                    NSDictionary *mailData = (NSDictionary *)obj;
                    
                    __autoreleasing MailItem *oldMailItem = nil;
                    
                    MailItem *newMailItem = [MailItem newInManagedObjectContext: context mailBoxItem: mailboxItem basedOnData: mailData orOldMailItemFetchedInstead: &oldMailItem];
                    
                    if (newMailItem) {
                        [self pickDialogToNewMailItem: newMailItem inManagedObject: context mailBoxItem: mailboxItem];
                    }
                    
                    if (oldMailItem) {
                        NSLog(@"didIntersectNextTimestampItem = YES");
                        //means that we did intersect a following timestamp item
                        didIntersectNextTimestampItem = YES;
                    }
                }];
                
                if (YES == didIntersectNextTimestampItem) {
                    //will merge timestamp itens into one
                    
                    //get a next timestamp item on a timeline (following an item which is recording this download session)
                    MailBoxTimestampItem *next_timestamp = [self nextTimestampItemForTimeStampItem: timestamp];
                    
                    NSAssert(next_timestamp, @"intersection did take place, but no following timestamp item found in %s", __FUNCTION__);
                    
                    //merge timestamps
                    [MailBoxTimestampItem mergeMailBoxDownlaodItem: timestamp withItem: next_timestamp inManagedObjectContext: context];
                    
                } else {
                    if (mailItemsData.count > 0) {
                        //increase page count of a timestamp item (which is recording this download session)
                        timestamp.pagesDownloadedSinceRelevantItem = [NSNumber numberWithInteger:timestamp.pagesDownloadedSinceRelevantItem.integerValue + 1];
                    }
                }
                
                //save context
                [[CoreDataManager sharedManager] saveMainManagedObjectContext];
                
            } errorBlock: ^(NSError *error) {
                [[[UIAlertView alloc] initWithTitle: error.localizedDescription message: error.localizedFailureReason delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil, nil] show]; 
            }];
        } else { //no timestamps exist
            [self downloadMostRecentMailsForMailBoxItem: mailboxItem];
        }
    }
}

-(void)cancellAllDownloads
{
    [_mailPageDownloaders enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop){
        MailPageDownloader *downloader = (MailPageDownloader *)obj;
        [downloader cancelDownload];
    }];
}

#pragma mark - private methods

-(id)keyForMailBoxItem:(MailBoxItem *)mailboxItem
{
    return mailboxItem.mailBoxTitle;
}

-(MailPageDownloader *)downloaderForMailBoxItem: (MailBoxItem *)mailboxItem;
{
    id key = [self keyForMailBoxItem: mailboxItem];
    return [_mailPageDownloaders objectForKey: key];
}

-(void)setDownloader: (MailPageDownloader *)downloader forMailboxItem: (MailBoxItem *)mailboxItem
{
    id key = [self keyForMailBoxItem: mailboxItem];
    [_mailPageDownloaders setObject: downloader forKey: key];
}

-(NSArray *)fetchTimestampItemsForMailBoxItem: (MailBoxItem *)mailbox
{
    //fetch items only once for every mailbox
    
    id key = [self keyForMailBoxItem: mailbox];
    NSFetchedResultsController *controller = [_fetchedResultsControllerOfTimestamps objectForKey: key];
    
    if (! controller) {
        //no fetch took place previously
        NSManagedObjectContext *context = [[CoreDataManager sharedManager] mainManagedObjectContext];
        
        controller = [MailBoxTimestampItem fetchedResultsControllerForMailBoxItem: mailbox inManagedObjectContext: context];
        
        controller.delegate = self;
        
        //record a controller
        [_fetchedResultsControllerOfTimestamps setObject: controller forKey: key];
        
        //perform fetch
        __autoreleasing NSError *error = nil;
        if (NO == [controller performFetch: &error]) {
            if (error) {
                #ifdef DEBUG
                NSLog(@"failed to fetch items in %s for mailbox: %@", __FUNCTION__, mailbox);
                NSLog(@"     error: %@", error);
                #endif
            }
        }
    }
    return controller.fetchedObjects;
}

-(MailBoxTimestampItem *)newestTimestampItemForMailBoxItem:(MailBoxItem *)mailboxItem
{
    NSAssert(_fetchedResultsControllerOfTimestamps, @"nil FRCs");
    NSAssert(mailboxItem, @"nil %@", NSStringFromClass(mailboxItem.class));
    
    MailBoxTimestampItem *timestampItem = nil;

    NSArray *timestampItems = [self fetchTimestampItemsForMailBoxItem: mailboxItem];
    
    if (timestampItems.count > 0) {
        timestampItem = timestampItems[0];
    }
    
    return timestampItem;
}

-(MailBoxTimestampItem *)nextTimestampItemForTimeStampItem: (MailBoxTimestampItem *)item
{
    NSAssert(_fetchedResultsControllerOfTimestamps, @"nil FRCs");
    NSAssert(item, @"nil %@", NSStringFromClass(item.class));

    MailBoxTimestampItem *timestampItem = nil;

    NSArray *timestampItems = [self fetchTimestampItemsForMailBoxItem: item.relevantMailItem.dialogItem.mailboxItem];
    
    //return a timestamp item, following a passed one in fetched objects list
    NSUInteger indexOfPassedItem = [timestampItems indexOfObject: item];
    NSAssert(indexOfPassedItem != NSNotFound, @"an FRC did not fetch an item: %@ in %s", item, __FUNCTION__);
    
    //seact for an object, located after a passed
    NSUInteger indexOfResultItem = indexOfPassedItem + 1;
    if (timestampItems.count > indexOfResultItem) {
        timestampItem = timestampItems[indexOfResultItem];
    }
    
    return timestampItem;
}

-(void)pickDialogToNewMailItem: (MailItem *)mailItem inManagedObject: (NSManagedObjectContext *)context mailBoxItem: (MailBoxItem *)mailbox
{
    NSAssert(context, @"nil MOC");
    NSAssert(mailItem, @"nil %@", NSStringFromClass(mailItem.class));
    NSAssert(mailbox, @"nil %@", NSStringFromClass(mailbox.class));
    
    //connect mail item to a dialog item (new dialog will be created on demand)
    __autoreleasing DialogItem *oldDialogItem = nil;
    
    [DialogItem newDialogInManagedObjectContext: context mailItem: mailItem mailbox: mailbox orOldDialogItemFetchedInstead: &oldDialogItem];
}


#pragma mark - NSFetchedResultsControllerDelegate


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    
    #ifdef DEBUG
    //NSLog(@"%@'s FRC willChangeContent", NSStringFromClass(self.class));
    #endif
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    #ifdef DEBUG
    //NSLog(@"%@'s FRC didChangeObject", NSStringFromClass(self.class));
    #endif
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    #ifdef DEBUG
    //NSLog(@"%@'s FRC didChangeSection", NSStringFromClass(self.class));
    #endif
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    #ifdef DEBUG
    //NSLog(@"%@'s FRC didChangeContent", NSStringFromClass(self.class));
    #endif
}


@end
