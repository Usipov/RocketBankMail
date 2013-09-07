//
//  MailItemCell.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "DialogItemCell.h"
#import "MailItem.h"

#define kTOP_LINE_HEIGHT 20.0f
#define kSUBJECT_LINE_HEIGHT 25.0f
#define kBOTTOM_LINE_HEIGHT self.frame.size.height - kTOP_LINE_HEIGHT \
- kSUBJECT_LINE_HEIGHT

#define kACCESSORY_MARGIN 10.0f
#define kACCESSORY_SIZE 22.0f
#define kDATE_WIDTH 50.0f
#define kSTAR_SIZE 30.0f
#define kACTION_INDICATOR_SIZE 30.0f

#define kFIRST_CHECKPOINT_RATIO 0.33
#define kSECOND_CHECKPOINT_RATIO 0.66

#define kARCHIVE_COLOR()    [UIColor colorWithRed: 0.9 green: 0.9 blue: 0.06 alpha: 1.0]
#define kINBOX_COLOR()      [UIColor colorWithRed: 0.1 green: 1.0 blue: 0.1 alpha: 1.0]
#define kTRASH_COLOR()      [UIColor colorWithRed: 1.0 green: 0.1 blue: 0.1 alpha: 1.0]
#define kDEFAULT_COLOR()    [UIColor whiteColor]

/* fonts
 
 //Chevin Cyrillic
 //    ChevinCyrillic-BoldItalic
 //    ChevinCyrillic-Bold
 //    ChevinCyrillic-LightItalic
 //    ChevinCyrillic-Light
 
 //Chevin Pro
 //    ChevinPro-Medium
 
 */

@interface DialogItemCell () {
    UILabel     *_fromLabel;
    UILabel     *_dateLabel;
    UIImageView *_accessoryImageView;
    
    //for pan gestures
    UIPanGestureRecognizer *_panRecognizer;
    CGPoint                 _originalContentViewCenter;
    BOOL                    _leftSwipeOccured;
    BOOL                    _leftLongSwipeOccured;
    BOOL                    _rightSwipeOccured;
    BOOL                    _rightLongSwipeOccured;
    UIView                 *_coloredView;
    UIImageView            *_leftActionIndicatorView;
    UIImageView            *_rightActionIndicatorView;
    
    UIColor                *_rightActionColor;
    UIColor                *_rightLongActionColor;
    UIColor                *_leftActionColor;
    UIColor                *_leftLongActionColor;
    
    UIImage                *_rightActionImage;
    UIImage                *_rightLongActionImage;
    UIImage                *_leftActionImage;
    UIImage                *_leftLongActionImage;
}

-(NSString *)stringFromDate: (NSDate *)date;

@end

@interface DialogItemCell (PanGestureHandling) <UIGestureRecognizerDelegate>

-(void)createPanGesture;
-(void)createSubviewsForPanGesture;
-(void)handlePanGesture: (UIPanGestureRecognizer *)gesture;
-(void)handlePanOffset: (CGFloat)offset;
-(void)handleTriggeredAction;
-(UIColor *)colorForAction: (DialogItemCellActionType)action;
-(UIImage *)imageForAction: (DialogItemCellActionType)action;
-(void)moveOnDirection: (DialogItemCellMoveDirectionType)direction completion: (void (^)(BOOL finished))completionBlock;
@end

@implementation DialogItemCell

@synthesize leftSwipeAction         = _leftSwipeAction,
            leftLongSwipeAction     = _leftLongSwipeAction,
            rightSwipeAction        = _rightSwipeAction,
            rightLongSwipeAction    = _rightLongSwipeAction;

@synthesize actionsDelegate         = _actionsDelegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [self initWithStyle: style reuseIdentifier: reuseIdentifier mailboxItem: nil];
    return self;
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier mailboxItem: (MailBoxItem *)mailbox
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        _accessoryImageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"accessory"]];
        [self.contentView addSubview: _accessoryImageView];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        
        self.textLabel.numberOfLines = 1;
        self.textLabel.font = [UIFont fontWithName: @"ChevinCyrillic-Bold" size: 20.0f];
        
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.detailTextLabel.textColor = [UIColor lightGrayColor];
        self.detailTextLabel.font = [UIFont fontWithName: @"ChevinCyrillic-Light" size: 14.0f];
        
        _fromLabel = [UILabel new];
        _fromLabel.backgroundColor = [UIColor clearColor];
        _fromLabel.numberOfLines = 1;
        _fromLabel.font = [UIFont fontWithName: @"ChevinCyrillic-Light" size: 14.0f];
        
        _dateLabel = [UILabel new];
        _dateLabel.numberOfLines = 1;
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.textAlignment = UITextAlignmentRight;
        _dateLabel.font = [UIFont fontWithName: @"ChevinPro-Medium" size: 14.0f];
        
        self.imageView.image = [UIImage imageNamed: @"star"];
        [self.contentView addSubview: _fromLabel];
        [self.contentView addSubview: _dateLabel];
        
        [self createSubviewsForPanGesture];
        [self createPanGesture];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    
    _coloredView.backgroundColor = [UIColor clearColor];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    _fromLabel.frame = CGRectMake(kSTAR_SIZE, 0.0f, self.frame.size.width - kSTAR_SIZE - kDATE_WIDTH - kACCESSORY_SIZE - kACCESSORY_MARGIN, kTOP_LINE_HEIGHT);
    _dateLabel.frame = CGRectMake(CGRectGetMaxX(_fromLabel.frame), 0.0, kDATE_WIDTH, kTOP_LINE_HEIGHT);
    
    _accessoryImageView.frame = CGRectMake(self.bounds.size.width - 1 * (kACCESSORY_SIZE + kACCESSORY_MARGIN), 0.5 * (self.bounds.size.height - kACCESSORY_SIZE), kACCESSORY_SIZE, kACCESSORY_SIZE);
    
    self.imageView.frame = CGRectMake(0.0, 0.5 * (self.frame.size.height - kSTAR_SIZE), kSTAR_SIZE, kSTAR_SIZE);
    
    self.textLabel.frame = CGRectMake(kSTAR_SIZE, kTOP_LINE_HEIGHT, self.frame.size.width - kSTAR_SIZE - kACCESSORY_SIZE - kACCESSORY_MARGIN, kSUBJECT_LINE_HEIGHT);
    
    self.detailTextLabel.frame = CGRectMake(kSTAR_SIZE, kTOP_LINE_HEIGHT + kSUBJECT_LINE_HEIGHT, self.frame.size.width - kSTAR_SIZE - kACCESSORY_SIZE - kACCESSORY_MARGIN, kBOTTOM_LINE_HEIGHT);
    
    _leftActionIndicatorView.frame = CGRectMake(0.5 * kACTION_INDICATOR_SIZE, 0.5 * (self.bounds.size.height - kACTION_INDICATOR_SIZE), kACTION_INDICATOR_SIZE, kACTION_INDICATOR_SIZE);
    
    _rightActionIndicatorView.frame = CGRectMake(self.bounds.size.width - 1.5 * kACTION_INDICATOR_SIZE, 0.5 * (self.bounds.size.height - kACTION_INDICATOR_SIZE), kACTION_INDICATOR_SIZE, kACTION_INDICATOR_SIZE);
    
    _coloredView.frame = self.bounds;
}

#pragma mark - properties

-(void)setLeftLongSwipeAction:(DialogItemCellActionType)leftLongSwipeAction
{
    _leftLongSwipeAction = leftLongSwipeAction;
    _leftLongActionColor = [self colorForAction: leftLongSwipeAction];
    _leftLongActionImage = [self imageForAction: leftLongSwipeAction];
}

-(void)setLeftSwipeAction:(DialogItemCellActionType)leftSwipeAction
{
    _leftSwipeAction = leftSwipeAction;
    _leftActionColor = [self colorForAction: leftSwipeAction];
    _leftActionImage = [self imageForAction: leftSwipeAction];
}

-(void)setRightLongSwipeAction:(DialogItemCellActionType)rightLongSwipeAction
{
    _rightLongSwipeAction = rightLongSwipeAction;
    _rightLongActionColor = [self colorForAction: rightLongSwipeAction];
    _rightLongActionImage = [self imageForAction: rightLongSwipeAction];    
}

-(void)setRightSwipeAction:(DialogItemCellActionType)rightSwipeAction
{
    _rightSwipeAction = rightSwipeAction;
    _rightActionColor = [self colorForAction: rightSwipeAction];
    _rightActionImage = [self imageForAction: rightSwipeAction];    
}

#pragma mark - public methods

-(void)updateOnDialogItem: (DialogItem *)dialog;
{
    MailItem *anyMail = [dialog.mailItems anyObject];
    self.textLabel.text = anyMail.recievedAt.description;
    
    _fromLabel.text = anyMail.from;
    _dateLabel.text = [self stringFromDate: anyMail.recievedAt];
    
    self.textLabel.text = anyMail.subject;
    self.detailTextLabel.text = anyMail.body;
    
    self.imageView.hidden = ! anyMail.starred.boolValue;
}

#pragma mark - private methods

-(NSString *)stringFromDate: (NSDate *)date
{
    NSCalendar *callendar = [NSCalendar currentCalendar];
    
    //get a today date
    NSDateComponents *components = [callendar components: (NSEraCalendarUnit|NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: [NSDate date]];
    NSDate *today = [callendar dateFromComponents: components];
    
    //cut minutes, hours and seconds from a passed date
    components = [callendar components: (NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: date];
    NSDate *passedDateCutAtEnd = [callendar dateFromComponents: components];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    
    if([today isEqualToDate: passedDateCutAtEnd]) {
        //will show hours and minutes only
        formatter.dateFormat = @"HH : mm";
    } else {
        //will show day and month only
        formatter.dateFormat = @"MMM dd";
    }
    
    return [formatter stringFromDate: date];
}

@end

#pragma mark

@implementation DialogItemCell (PanGestureHandling)

-(void)createPanGesture
{
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(handlePanGesture:)];
    _panRecognizer.delegate = self;
    _panRecognizer.maximumNumberOfTouches = 1;
    _panRecognizer.minimumNumberOfTouches = 1;
    [self addGestureRecognizer: _panRecognizer];
    
    self.leftLongSwipeAction = DialogItemCellActionNone;
    self.leftSwipeAction = DialogItemCellActionNone;
    self.rightLongSwipeAction = DialogItemCellActionNone;
    self.rightSwipeAction = DialogItemCellActionNone;
}

-(void)createSubviewsForPanGesture
{
    _leftActionIndicatorView = [UIImageView new];
    _rightActionIndicatorView = [UIImageView new];
    
    _coloredView = [UIView new];
    _coloredView.backgroundColor = [UIColor clearColor];
    [_coloredView addSubview: _leftActionIndicatorView];
    [_coloredView addSubview: _rightActionIndicatorView];
    
    [self insertSubview: _coloredView belowSubview: self.contentView];
}

-(void)handlePanGesture: (UIPanGestureRecognizer *)gesture
{
    if (gesture != _panRecognizer) return;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
		// if the gesture has just started, record the current centre location
        _originalContentViewCenter = self.contentView.center;
    }
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        // translate the center
        CGPoint translation = [gesture translationInView: self];
        self.contentView.center = CGPointMake(_originalContentViewCenter.x + translation.x, _originalContentViewCenter.y);
        
        CGFloat width = self.frame.size.width;
        
        //compute flags
        _rightSwipeOccured      = translation.x / width > kFIRST_CHECKPOINT_RATIO;
        _rightLongSwipeOccured  = translation.x / width > kSECOND_CHECKPOINT_RATIO;
        _leftSwipeOccured       = translation.x / width < - kFIRST_CHECKPOINT_RATIO;
        _leftLongSwipeOccured   = translation.x / width < - kSECOND_CHECKPOINT_RATIO;
        
        //handle other views
        [self handlePanOffset: translation.x];
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        BOOL someActionRegistered = _leftLongSwipeOccured || _leftSwipeOccured || _rightLongSwipeOccured || _rightSwipeOccured;
        
        if (NO == someActionRegistered) {
            //go to origin
            [self moveOnDirection: DialogItemCellMoveDirectionCenter completion: NULL];
        } else {
            [self handleTriggeredAction];
        }
        
    }
}

-(void)handlePanOffset: (CGFloat)offset
{
    
    
    if (YES == _leftLongSwipeOccured) {
        _coloredView.backgroundColor = _leftLongActionColor;
        _rightActionIndicatorView.image = _leftLongActionImage;
    }
    else if (YES == _rightLongSwipeOccured) {
        _coloredView.backgroundColor = _rightLongActionColor;
        _leftActionIndicatorView.image = _rightLongActionImage;
    }
    else if (offset > 0) {
        _coloredView.backgroundColor = _rightActionColor;
        _leftActionIndicatorView.image = _rightActionImage;
    }
    else if (offset < 0) {
        _coloredView.backgroundColor = _leftActionColor;
        _rightActionIndicatorView.image = _leftActionImage;
    } else {
        _coloredView.backgroundColor = kDEFAULT_COLOR();
        _leftActionIndicatorView.image = nil;
        _rightActionIndicatorView.image = nil;        
    }
}

-(void)handleTriggeredAction
{
    if (_actionsDelegate) {
        if ([_actionsDelegate respondsToSelector: @selector(dialogItemCell:didRegisterAction:)]) {
        
            DialogItemCellActionType swipeAction = DialogItemCellActionNone;
            DialogItemCellMoveDirectionType direction = DialogItemCellMoveDirectionCenter;
            
            //right long
            if (YES == _rightLongSwipeOccured) {
                swipeAction = _rightLongSwipeAction;
                direction = DialogItemCellMoveDirectionRight;
            }
            //right
            else if (YES == _rightSwipeOccured) {
                swipeAction = _rightSwipeAction;
                direction = DialogItemCellMoveDirectionRight;
            }
            //left long 
            else if (YES == _leftLongSwipeOccured) {
                swipeAction = _leftLongSwipeAction;
                direction = DialogItemCellMoveDirectionLeft;
            }
            //left
            else if (YES == _leftSwipeOccured) {
                swipeAction = _leftSwipeAction;
                direction = DialogItemCellMoveDirectionLeft;
            }
            
            if (swipeAction == DialogItemCellActionNone) {
                direction = DialogItemCellMoveDirectionCenter;
            }

            //move a cell
            [self moveOnDirection: direction completion: ^(BOOL finished) {
                if (swipeAction != DialogItemCellActionNone) {
                    //inform a delegate
                    [_actionsDelegate dialogItemCell: self didRegisterAction: swipeAction];
                }
            }];
            
        }
    }
}

-(UIColor *)colorForAction: (DialogItemCellActionType)action
{
    UIColor *color = nil;
    
    switch (action) {
        case DialogItemCellActionMoveToArchive:
            color = kARCHIVE_COLOR();
            break;
        case DialogItemCellActionMoveToInbox:
            color = kINBOX_COLOR();
            break;
        case DialogItemCellActionMoveToTrash:
            color = kTRASH_COLOR();
            break;
        case DialogItemCellActionNone:
            color = kDEFAULT_COLOR();
            break;
        default:
            break;
    }
    
    return color;
}

-(UIImage *)imageForAction: (DialogItemCellActionType)action
{
    UIImage *image = nil;
    
    switch (action) {
        case DialogItemCellActionMoveToArchive:
            image = [UIImage imageNamed: @"check"];
            break;
        case DialogItemCellActionMoveToInbox:
            image = [UIImage imageNamed: @"inbox"];
            break;
        case DialogItemCellActionMoveToTrash:
            image = [UIImage imageNamed: @"cross"];
            break;
        case DialogItemCellActionNone:
            image = nil;
            break;
        default:
            break;
    }
    
    return image;
}

-(void)moveOnDirection: (DialogItemCellMoveDirectionType)direction completion: (void (^)(BOOL finished))completionBlock
{
    CGPoint newContentViewCenter = CGPointZero;
    
    switch (direction) {
        case DialogItemCellMoveDirectionLeft:
            newContentViewCenter = CGPointMake(- 3 * _originalContentViewCenter.x, _originalContentViewCenter.y);
            break;
        case DialogItemCellMoveDirectionCenter:
            newContentViewCenter = _originalContentViewCenter;
            break;
        case DialogItemCellMoveDirectionRight:
            newContentViewCenter = CGPointMake( 3 * _originalContentViewCenter.x, _originalContentViewCenter.y);
            break;
        default:
            break;
    }
    
    [UIView animateWithDuration: kANIMATION_DURATION delay: 0.0 options:UIViewAnimationOptionCurveEaseInOut animations: ^{
        //move our content view
        self.contentView.center = newContentViewCenter;
    } completion: ^(BOOL finished) {
        
        _leftSwipeOccured = NO;
        _leftLongSwipeOccured = NO;
        _rightLongSwipeOccured = NO;
        _rightSwipeOccured = NO;
        
        _leftActionIndicatorView.image = nil;
        _rightActionIndicatorView.image = nil;
        
        if (completionBlock) {
            completionBlock(finished);
        }
    }];
}
            
#pragma mark UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin: (UIPanGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass: [UIPanGestureRecognizer class]]) {
        CGPoint translation = [gestureRecognizer translationInView: self.superview];
        
        // Handle only horizontal pans
        return fabsf(translation.x) > fabsf(translation.y);
    }
    return NO;
}



@end
