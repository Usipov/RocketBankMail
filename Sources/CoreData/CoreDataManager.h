//
//  CoreDataManager.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "DialogItem.h"
#import "MailBoxItem.h"
#import "MailItem.h"
#import "MailBoxTimestampItem.h"


@interface CoreDataManager : NSObject

+(CoreDataManager *)sharedManager;

@property (nonatomic, retain, readonly) NSManagedObjectModel *mainManagedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *mainPersistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *mainManagedObjectContext;

-(NSManagedObjectContext *)newManagedObjectContext;
-(void)saveMainManagedObjectContext;
-(void)clearCoreData;

-(void)createDefaultMailBoxItems;

@property (nonatomic, retain, readonly) NSArray *immutableMailboxes;

@end
