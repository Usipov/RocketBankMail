//
//  MailsViewController.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "MailsViewController.h"
#import "CoreDataManager.h"
#import "MailItem.h"
#import "MailDownloadManager.h"
#import "PlaceHolderCell.h"
#import "DialogItemCell.h"
#import "MailsView.h"
#import "AppDelegate.h"
#import "CustomSegmentedControl.h"

NSString *const BatchSizeKey = @"UserDefaultsBatchSizeKey";

@interface MailsViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, DialogItemCellDelegate, CustomSegmentedControlDelegate> {
    BOOL                         _isHandlingSingleMailboxType;
    NSArray                     *_mailboxes;
    NSArray                     *_fetchedResultsControllers; //fetch dialog items
    MailsView                   *_mailsView;
    UITableViewStyle             _tableViewStyle;
    CustomSegmentedControl      *_control;
    NSDictionary                *_controlData;
    BOOL                         _willHandlePlaceHolderCell;
}

-(void)reloadData; //fetch all data, reload all tables
-(void)prepareFetchedResultsControllersForMailBoxItems: (NSArray *)mailboxes;
-(void)refetchDataForMailBoxItem: (MailBoxItem *)mailboxItem;
-(void)configureMailItemCell: (DialogItemCell *)cell withFetchedResultsController: (NSFetchedResultsController *)controller atIndexPath: (NSIndexPath *)indexPath;
-(void)setSwipeActionsForCell:(DialogItemCell *)cell tableIndex: (NSUInteger)index;
@end

@interface MailsViewController (ButtonsHandler)
-(void)refreshTapped: (UIButton *)sender;
@end

@interface MailsViewController (SegmentedControl)
-(void)createSegmentedControl;
@end

@implementation MailsViewController

-(id)initForThreeMailBoxesWithStyle:(UITableViewStyle)style
{
    self = [super initWithNibName: nil bundle: nil];
    if (self) {
        _tableViewStyle = style;
        _isHandlingSingleMailboxType = NO;
        _mailboxes = [[CoreDataManager sharedManager] immutableMailboxes];
    }
    return self;
}

-(id)initWithStyle:(UITableViewStyle)style singleMailBoxItem:(MailBoxItem *)mailbox
{
    self = [super initWithNibName: nil bundle: nil];
    if (self) {
        #warning code missing
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //navigation bar background
    [self.navigationController.navigationBar setBackgroundImage: [UIImage imageNamed: @"navBar-Portrait"] forBarMetrics: UIBarMetricsDefault];
    
    //right bar button item
    UIButton *button = [UIButton buttonWithType: UIButtonTypeCustom];
    button.frame = CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
    [button addTarget: self action: @selector(refreshTapped:) forControlEvents: UIControlEventTouchUpInside];
    [button setImage: [UIImage imageNamed: @"refresh-button-item"] forState: UIControlStateNormal];
    UIBarButtonItem *refreshControl = [[UIBarButtonItem alloc] initWithCustomView: button];
    self.navigationItem.rightBarButtonItem = refreshControl;
    
    
    //create Main View
    if (YES == _isHandlingSingleMailboxType) {
        #warning code missing
        
    } else { //NO == _isHandlingSingleMailboxType

        //title view
        [self createSegmentedControl];
        
        //create tableViews
        CGRect frame = self.view.frame; frame.origin = CGPointZero;
        _mailsView = [[MailsView alloc] initWithFrame: frame mailboxItems: _mailboxes tableStyle: _tableViewStyle tableDelegate: self tableDataSource: self];
        _mailsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.view.autoresizesSubviews = YES;
        [self.view addSubview: _mailsView];
        
        //set a proper tableView
        [_mailsView setSelectedTableAtIndex: TableIndexMid animated: NO];
    }
    
    //fetch all data, reload all tables
    [self reloadData];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [self willRotateToInterfaceOrientation: kAPP_ORIENTATION() duration: 0.0];
}

#pragma mark - rotations

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    if (YES == IS_PAD()) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (YES == IS_PAD()) {
        return YES;
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

#pragma mark - private methods

-(void)reloadData
{
    //will allocate controllers, fetch all data, reload all tables
 
    _willHandlePlaceHolderCell = YES;//start requesting more data when scrolled to bottom
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    BOOL isFirstAppLaunch = delegate.isFirstAppLaunch;
    
    //allocate controllers
    [self prepareFetchedResultsControllersForMailBoxItems: _mailboxes];
    
    [_mailboxes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        MailBoxItem *mailbox = (MailBoxItem *)obj;

        //refetch data
        [self refetchDataForMailBoxItem: mailbox];
        
        //check first app launch
        if (YES == isFirstAppLaunch) {
            //start downloading fresh data
            [[MailDownloadManager sharedDownloader] downloadMostRecentMailsForMailBoxItem: mailbox];
        }
        
        //reload a corresponding table
        UITableView *table = [_mailsView tableViewAtIndex: idx];
        NSAssert(table, @"nil table");
        [table reloadData];
    }];
}

-(void)prepareFetchedResultsControllersForMailBoxItems: (NSArray *)mailboxes
{
    if (! _fetchedResultsControllers) {

        NSMutableArray *controllers = [NSMutableArray arrayWithCapacity: mailboxes.count];
        
        NSManagedObjectContext *context = [[CoreDataManager sharedManager] mainManagedObjectContext];
        
        [mailboxes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            MailBoxItem *mailboxItem = (MailBoxItem *)obj;
            
            //get a fetch results controller
            NSFetchedResultsController *mailboxController = [DialogItem fetchedResultsControllerForMailBox: mailboxItem inManagedObjectContext: context];
            mailboxController.delegate = self;
            
            [controllers addObject: mailboxController];
        }];
        
        _fetchedResultsControllers = controllers;
    }
}

-(void)refetchDataForMailBoxItem: (MailBoxItem *)mailboxItem
{    
    //get a comtroller first
    NSUInteger mailboxIndex = [_mailboxes indexOfObject: mailboxItem];
    NSAssert(mailboxIndex != NSNotFound, @"bad mailbox in %s", __FUNCTION__);
    
    NSFetchedResultsController *mailboxController = _fetchedResultsControllers[mailboxIndex];
    
    //perform fetch now
    __autoreleasing NSError *error = nil;
    BOOL fetchIsOK = [mailboxController performFetch: &error];
    
    if (NO == fetchIsOK) {
        if (error) {
            #ifdef DEBUG
            NSLog(@"Failed to perfrom fetch in %s mailbox: %@", __FUNCTION__, mailboxItem);
            NSLog(@"     error: %@", error);
            #endif
        }
    } else {
//        return;
//
//        __block NSMutableDictionary *allPairs = [NSMutableDictionary new];
//        
//        [mailboxController.fetchedObjects enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
//
//            DialogItem *item = (DialogItem *)obj;
//
//            NSString *sender = item.from;
//            NSString *recipient = item.to;
//
//            NSLog(@"____________________________________________________________");
//            NSLog(@"from : %@", sender);
//            NSLog(@"  to : %@", recipient);
//            
//            NSMutableArray *toFromArray = [NSMutableArray new];
//            [toFromArray addObject: sender];
//            [toFromArray addObject: recipient];
//
//            //sort
//            [toFromArray sortUsingComparator: ^NSComparisonResult(id obj1, id obj2) {
//                return [(NSString *)obj1 compare: (NSString *)obj2];
//            }];
//            
//            NSString *key = [NSString stringWithFormat: @"%@__%@", toFromArray[0], toFromArray[1]];
//        
//            NSMutableArray *mails = [allPairs objectForKey: key];
//            if (! mails) {
//                mails = [NSMutableArray new];
//                NSLog(@"added new key : %@", key);
//            } else {
//                NSLog(@"duplicate key: %@", key);
//            }
//            [mails addObject: item];
//            [allPairs setObject: mails forKey: key];
//        }];
//        
//        NSLog(@"________________________");
//        NSLog(@"__________All Pairs__________");
//        NSLog(@"%@", allPairs);
//        NSLog(@"________________________");
//
//        }];
    }
}

-(void)configureMailItemCell: (DialogItemCell *)cell withFetchedResultsController: (NSFetchedResultsController *)controller atIndexPath:(NSIndexPath *)indexPath
{
    //get a source item
    DialogItem *item = [controller objectAtIndexPath: indexPath];
    
    //refresh a cell
    [cell updateOnDialogItem: item];
}

-(void)setSwipeActionsForCell:(DialogItemCell *)cell tableIndex: (NSUInteger)index
{
    switch (index) {
        case TableIndexLeft:
            cell.leftLongSwipeAction = cell.leftSwipeAction = DialogItemCellActionNone;
            cell.rightLongSwipeAction = DialogItemCellActionMoveToArchive;
            cell.rightSwipeAction = DialogItemCellActionMoveToInbox;
            break;
        case TableIndexMid:
            cell.rightLongSwipeAction = cell.rightSwipeAction = DialogItemCellActionMoveToArchive;
            cell.leftLongSwipeAction = cell.leftSwipeAction = DialogItemCellActionMoveToTrash;
            break;
        case TableIndexRight:
            cell.rightLongSwipeAction = cell.rightSwipeAction = DialogItemCellActionNone;
            cell.leftLongSwipeAction = DialogItemCellActionMoveToTrash;
            cell.leftSwipeAction = DialogItemCellActionMoveToInbox;
            break;
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    NSUInteger tableIndex = [_mailsView indexOfTableView: tableView];
    NSFetchedResultsController *controller = _fetchedResultsControllers[tableIndex];
    NSAssert(controller, @"nil frc");
    NSUInteger sections = controller.sections.count;
    
    if (sections == 0) { sections ++; }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger tableIndex = [_mailsView indexOfTableView: tableView];
    NSFetchedResultsController *controller = _fetchedResultsControllers[tableIndex];
    NSAssert(controller, @"nil FRC");
    id<NSFetchedResultsSectionInfo> sectionInfo = controller.sections[section];
    
    NSUInteger rows = sectionInfo.numberOfObjects;
    
    //add a placeholder cell on a middle table (inbox table)
    if (tableIndex == TableIndexMid) { rows ++; }
    
    return rows;
 }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellPlaceholderIdentifier = @"Cell2";
    
    NSUInteger tableIndex = [_mailsView indexOfTableView: tableView];
    MailBoxItem *mailbox = _mailboxes[tableIndex];
    
    if (tableIndex == TableIndexMid) {
        //middle table may have a placeholder cell
        
        //check if requested cell is at very bottom (placeholder cell)
        BOOL sectionIsLast = indexPath.section == [self numberOfSectionsInTableView: tableView] - 1;
        BOOL rowIsLast = indexPath.row == [self tableView: tableView numberOfRowsInSection: indexPath.section] - 1;
        BOOL placeHolderCellRequested = sectionIsLast && rowIsLast;
        
        if (YES == placeHolderCellRequested) {
            //scrolled to a bottom cell (need more data)
            
            PlaceHolderCell *cell = [tableView dequeueReusableCellWithIdentifier: CellPlaceholderIdentifier];
            if (! cell) {
                cell = [[PlaceHolderCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellPlaceholderIdentifier];
                
                cell.textLabel.text = NSLocalizedString(@"downloading", nil);
            } 

            //request more data
            if (mailbox) {
                if (YES == _willHandlePlaceHolderCell) {
                    [[MailDownloadManager sharedDownloader] downloadMoreMailsForMailBoxItem: mailbox];
                }
            }
            
            return cell;
        }
    }
    
    
    
    //regular case. return dialog item cells
    DialogItemCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (! cell) {
        cell = [[DialogItemCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: CellIdentifier];
        cell.actionsDelegate = self; //handle pan gestures
    }
    [self setSwipeActionsForCell: cell tableIndex: tableIndex];
    
    NSFetchedResultsController *controller = _fetchedResultsControllers[tableIndex];
    [self configureMailItemCell: cell withFetchedResultsController: controller atIndexPath: indexPath];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 86.0f;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    NSUInteger controllerIndex = [_fetchedResultsControllers indexOfObject: controller];
    UITableView *tableView = [_mailsView tableViewAtIndex: controllerIndex];
    NSAssert(tableView, @"nil table in %s", __FUNCTION__);
    [tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{    
    NSUInteger controllerIndex = [_fetchedResultsControllers indexOfObject: controller];
    UITableView *tableView = [_mailsView tableViewAtIndex: controllerIndex];
    NSAssert(tableView, @"nil table in %s", __FUNCTION__);
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths: @[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths: @[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            DialogItemCell *cell = (DialogItemCell *)[tableView cellForRowAtIndexPath: indexPath];
            [self configureMailItemCell: cell withFetchedResultsController: controller atIndexPath: indexPath];
            break;            
        }
        
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths: @[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSUInteger controllerIndex = [_fetchedResultsControllers indexOfObject: controller];
    UITableView *tableView = [_mailsView tableViewAtIndex: controllerIndex];
    NSAssert(tableView, @"nil table in %s", __FUNCTION__);
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertSections: [NSIndexSet indexSetWithIndex: sectionIndex] withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections: [NSIndexSet indexSetWithIndex: sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSUInteger controllerIndex = [_fetchedResultsControllers indexOfObject: controller];
    UITableView *tableView = [_mailsView tableViewAtIndex: controllerIndex];
    NSAssert(tableView, @"nil table in %s", __FUNCTION__);
    [tableView endUpdates];
}

#pragma mark - DialogItemCellDelegate

-(void)dialogItemCell:(DialogItemCell *)cell didRegisterAction:(DialogItemCellActionType)action
{    
    //compute an index path of a cell
    UITableView *table = (UITableView *)cell.superview;
    NSIndexPath *indexPathOfCell = [table indexPathForCell: cell];
    
    //get a fetched results contoller
    NSUInteger tableIndex = [_mailsView indexOfTableView: table];
    NSAssert(tableIndex != NSNotFound, @"bad table index in %s", __FUNCTION__);
    NSFetchedResultsController *controller = _fetchedResultsControllers[tableIndex];
    
    //get a managed item
    DialogItem *dialogItem = [controller objectAtIndexPath: indexPathOfCell];
    MailBoxItem *mailboxToBeAssigned = nil; //future item's mailbox
    
    switch (action) {
        case DialogItemCellActionMoveToArchive:
            mailboxToBeAssigned = _mailboxes[TableIndexRight];
            break;
        case DialogItemCellActionMoveToInbox:
            mailboxToBeAssigned = _mailboxes[TableIndexMid];
            break;
        case DialogItemCellActionMoveToTrash:
            mailboxToBeAssigned = _mailboxes[TableIndexLeft];
            break;
        default:
            break;
    }
    
    //assign dialog item to a new mailbox
    dialogItem.mailboxItem = mailboxToBeAssigned;
    
    [[CoreDataManager sharedManager] saveMainManagedObjectContext];
}

@end

#pragma mark


@implementation MailsViewController (ButtonsHandler)

-(void)refreshTapped:(UIButton *)sender
{
    [[MailDownloadManager sharedDownloader] cancellAllDownloads];
    _willHandlePlaceHolderCell = NO; //stop requesting more data when scrolled to bottom
    [[CoreDataManager sharedManager] clearCoreData];
    [self reloadData];
}

@end

#pragma mark

@implementation MailsViewController (SegmentedControl)

-(void)createSegmentedControl
{
    NSArray *titles = @[@"", @"", @""];
    CGSize segmentSize = CGSizeMake(52.0f, 31.0f);
    
    _controlData = [NSDictionary dictionaryWithObjectsAndKeys:
         titles,                                                 kSegmTitles,
         [NSValue valueWithCGSize: segmentSize],                 kSegmSize,
         @"segm_left",                                           kSegmButtonImageL,
         @"segm_left_hl",                                        kSegmButtonImageLH,
         @"segm_mid",                                            kSegmButtonImageC,
         @"segm_mid_hl",                                         kSegmButtonImageCH,
         @"segm_right",                                          kSegmButtonImageR,
         @"segm_right_hl",                                       kSegmButtonImageRH,
         [NSNumber numberWithFloat: 0.0],                        kSegmCapWidth, nil];
    
    _control = [[CustomSegmentedControl alloc] initWithSegmentCount: titles.count segmentsize: segmentSize dividerImage: nil tag: 0 delegate: self];
    
    self.navigationItem.titleView = _control;
}


#pragma mark CustomSegmentedControlDelegate

-(UIButton *)buttonFor: (CustomSegmentedControl*)segmentedControl atIndex: (NSUInteger)segmentIndex;
{
    NSArray* titles = [_controlData objectForKey: kSegmTitles];
    
    CapLocation location;
    if (segmentIndex == 0) {
        location = CapLeft;
    } else if (segmentIndex == titles.count - 1) {
        location = CapRight;
    } else {
        location = CapMiddle;
    }
    UIImage* buttonImage = nil;
    UIImage* buttonPressedImage = nil;
    
    CGSize buttonSize = [[_controlData objectForKey: kSegmSize] CGSizeValue];
    
    if (location == CapLeft) {
        buttonImage         = [UIImage imageNamed: [_controlData objectForKey: kSegmButtonImageL]];
        buttonPressedImage  = [UIImage imageNamed: [_controlData objectForKey: kSegmButtonImageLH]];
    } else if (location == CapMiddle) {
        buttonImage         = [UIImage imageNamed: [_controlData objectForKey: kSegmButtonImageC]];
        buttonPressedImage  = [UIImage imageNamed: [_controlData objectForKey: kSegmButtonImageCH]];
    } else if (location == CapRight) {
        buttonImage         = [UIImage imageNamed: [_controlData objectForKey: kSegmButtonImageR]];
        buttonPressedImage  = [UIImage imageNamed: [_controlData objectForKey: kSegmButtonImageRH]];
    }
    
    UIButton* button = [UIButton buttonWithType: UIButtonTypeCustom];
    button.frame = CGRectMake(0.0, 0.0, buttonSize.width, buttonSize.height);
    [button setImage: buttonImage forState: UIControlStateNormal];
    [button setImage: buttonPressedImage forState: UIControlStateHighlighted];
    [button setImage: buttonPressedImage forState: UIControlStateSelected];
    button.adjustsImageWhenHighlighted = NO;
    
    if (segmentIndex == TableIndexMid)
        button.selected = YES;
    return button;
}

- (void) touchUpInsideSegmentIndex:(NSUInteger)segmentIndex
{
    [_mailsView setSelectedTableAtIndex: segmentIndex animated: YES];
}

- (void) touchDownAtSegmentIndex:(NSUInteger)segmentIndex
{
    //
}



@end
