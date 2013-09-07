//
//  CoreDataManager.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "CoreDataManager.h"
#import "MailItem.h"

#define kFETCH_BATCH_SIZE @"Shared Fetch Batch Size"

#define MAIL_BOX_IMMUTABLE_NAME_ARCHIVE @"Archive"
#define MAIL_BOX_IMMUTABLE_NAME_INBOX @"Inbox"
#define MAIL_BOX_IMMUTABLE_NAME_TRASH @"Trash"

static NSUInteger st_fetchBatchSize = 50;

@interface CoreDataManager () {
    NSFetchedResultsController *_allMailboxesController;
    NSFetchedResultsController *_immutableMailboxesController;
}

@property (nonatomic, retain, readwrite) NSManagedObjectModel *mainManagedObjectModel;
@property (nonatomic, retain, readwrite) NSPersistentStoreCoordinator *mainPersistentStoreCoordinator;
@property (nonatomic, retain, readwrite) NSManagedObjectContext *mainManagedObjectContext;

@property (nonatomic, retain, readwrite) NSArray *immutableMailboxes;

+(NSURL *)applicationCoreDataStoreFileURL;

@end

#pragma mark -

@implementation CoreDataManager

@synthesize mainManagedObjectContext        = _mainManagedObjectContext,
            mainManagedObjectModel          = _mainManagedObjectModel,
            mainPersistentStoreCoordinator  = _mainPersistentStoreCoordinator;

@synthesize immutableMailboxes;

-(id)init
{
    self = [super init];
    if (self) {
        //will instantiate fetched results controllers observing mailbox items
    }
    return self;
}

#pragma mark - public methods

+(CoreDataManager *)sharedManager
{
	static dispatch_once_t predicate = 0;
	static CoreDataManager *object = nil;
	dispatch_once(&predicate, ^{
        object = [self new];
    });
	return object; // CoreDataManager singleton
}



#pragma mark - properties

-(NSManagedObjectModel *)mainManagedObjectModel
{
	if (! _mainManagedObjectModel) {
        NSAssert(YES == [NSThread isMainThread], @"Create mainManagedObjectModel only on the main thread");
        
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource: @"RocketBankMail" withExtension: @"momd"];
        
		_mainManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelURL];
	}
    
	return _mainManagedObjectModel;
}

-(NSPersistentStoreCoordinator *)mainPersistentStoreCoordinator
{
	if (! _mainPersistentStoreCoordinator) {
		NSAssert(YES == [NSThread isMainThread], @"Create mainPersistentStoreCoordinator only on the main thread");
        
		NSURL *storeURL = [CoreDataManager applicationCoreDataStoreFileURL];
        
		__autoreleasing NSError *error = nil;
		NSDictionary *migratingOptions = @ {
            NSMigratePersistentStoresAutomaticallyOption : [NSNumber numberWithBool: YES],
            NSInferMappingModelAutomaticallyOption : [NSNumber numberWithBool: YES] };

		_mainPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self mainManagedObjectModel]];
        
        NSPersistentStore *store = [_mainPersistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: storeURL options: migratingOptions error: &error];
        if (! store) {
            #ifdef DEBUG
            NSLog(@"Failed to create an SQLite store");
            NSLog(@"error: %@", error);
            #endif
        }
	}
    
	return _mainPersistentStoreCoordinator;
}

-(NSManagedObjectContext *)mainManagedObjectContext
{
	if (! _mainManagedObjectContext) {
		NSAssert(YES == [NSThread isMainThread], @"Create mainManagedObjectContext only on the main thread");
        
		NSPersistentStoreCoordinator *coordinator = [self mainPersistentStoreCoordinator];
		if (coordinator) {
			_mainManagedObjectContext = [NSManagedObjectContext new];
			[_mainManagedObjectContext setPersistentStoreCoordinator: coordinator];
		}
	}
	return _mainManagedObjectContext;
}

-(NSArray *)immutableMailboxes
{
    if (! _immutableMailboxesController) {
        
        //instantiate a controller
        _immutableMailboxesController = [MailBoxItem fetchedResultsControllerForImmitableMailBoxesInManagedObjectContext: _mainManagedObjectContext];
        
        //fetch data
        __autoreleasing NSError *error = nil;
        BOOL fetchIsOK = [_immutableMailboxesController performFetch: &error];
        if (NO == fetchIsOK) {
            if (error) {
                NSLog(@"Failed to fetch in %s", __FUNCTION__);
                NSLog(@"     error: %@", error);
            }
        } else {
            immutableMailboxes = _immutableMailboxesController.fetchedObjects;
        }
    }

    return immutableMailboxes;
}

#pragma mark - public methods

-(NSManagedObjectContext *)newManagedObjectContext
{
	NSManagedObjectContext *someManagedObjectContext = nil;
    
	NSPersistentStoreCoordinator *coordinator = [self mainPersistentStoreCoordinator];
    
	if (coordinator) {
		someManagedObjectContext = [NSManagedObjectContext new];
		[someManagedObjectContext setPersistentStoreCoordinator: coordinator];
	}
    
	return someManagedObjectContext;
}

-(void)saveMainManagedObjectContext
{
    NSAssert(YES == [NSThread isMainThread], @"Save moc only on a main thread");
    
	if (_mainManagedObjectContext) {
		__autoreleasing NSError *error = nil; 
        
		if (YES == [_mainManagedObjectContext hasChanges]) {
			if (NO == [_mainManagedObjectContext save: &error]) {
                #ifdef DEBUG
				NSLog(@"%s %@", __FUNCTION__, error); 
                #endif
			}
		}
	}
}

-(void)clearCoreData
{
    //delete all managed objects, except mailboxes
    [DialogItem deleteAllInManagedObjectContext: _mainManagedObjectContext];
    [MailItem deleteAllInManagedObjectContext: _mainManagedObjectContext];
    [MailBoxTimestampItem deleteAllInManagedObjectContext: _mainManagedObjectContext];
    
    [self saveMainManagedObjectContext];
}

-(void)createDefaultMailBoxItems
{
    //will create mailboxes
    
    NSString *archivedTitle = NSLocalizedString(@"mailbox archived title", nil);
    NSString *inboxedTitle = NSLocalizedString(@"mailbox inboxed title", nil);
    NSString *trashedTitle = NSLocalizedString(@"mailbox trashed title", nil);
    NSArray *titles = @[archivedTitle, inboxedTitle, trashedTitle];
    
    NSArray *urls = @[[NSNull null], @"http://rocket-ios.herokuapp.com/emails.json?page=", [NSNull null]];
    
    //create mailboxes
    [titles enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *title = (NSString *)obj;
        NSString *url = nil;
        
        //get a url
        id urlOrNull = [urls objectAtIndex: idx];
        if (urlOrNull != [NSNull null]) {
            url = urlOrNull;
        }
        
        [MailBoxItem newMailBoxItemInManagedObjectContext: _mainManagedObjectContext title: title url: url immutable: YES orOldMailBoxItemFetchedInstead: nil];
    }];
    
    //save context
    [self saveMainManagedObjectContext];
}


#pragma mark - private methods

+(NSURL *)applicationCoreDataStoreFileURL
{
    NSFileManager *fileManager = [NSFileManager new];
    NSURL *url = [fileManager URLForDirectory: NSApplicationSupportDirectory inDomain: NSUserDomainMask appropriateForURL: nil create: YES error: NULL];
    return [url URLByAppendingPathComponent: @"RocketBankMail.sqlite"];
}


@end
