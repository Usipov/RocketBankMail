//
//  MailItemCell.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataManager.h"

typedef enum {
    DialogItemCellMoveDirectionLeft = 200,
    DialogItemCellMoveDirectionCenter,
    DialogItemCellMoveDirectionRight,
} DialogItemCellMoveDirectionType;

typedef enum {
    DialogItemCellActionMoveToInbox = 100,
    DialogItemCellActionMoveToTrash,
    DialogItemCellActionMoveToArchive,
    DialogItemCellActionNone
} DialogItemCellActionType;

@class DialogItemCell;

@protocol DialogItemCellDelegate <NSObject>

-(void)dialogItemCell: (DialogItemCell *)cell didRegisterAction: (DialogItemCellActionType)action;

@end

@interface DialogItemCell : UITableViewCell

-(void)updateOnDialogItem: (DialogItem *)dialog;
-(void)cancelGestureRecognizer;

@property (nonatomic) DialogItemCellActionType leftSwipeAction;
@property (nonatomic) DialogItemCellActionType leftLongSwipeAction;
@property (nonatomic) DialogItemCellActionType rightSwipeAction;
@property (nonatomic) DialogItemCellActionType rightLongSwipeAction;

@property (nonatomic, retain) id<DialogItemCellDelegate> actionsDelegate;

@end
