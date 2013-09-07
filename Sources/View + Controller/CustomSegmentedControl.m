//
//  CustomSegmentedControl.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 06.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "CustomSegmentedControl.h"

@interface CustomSegmentedControl () {
    id<CustomSegmentedControlDelegate> _segmentedControlDelegate;
}

@end

@implementation CustomSegmentedControl
@synthesize buttons = _buttons;

- (id) initWithSegmentCount:(NSUInteger)segmentCount segmentsize:(CGSize)segmentsize dividerImage:(UIImage*)dividerImage tag:(NSInteger)objectTag delegate:(NSObject <CustomSegmentedControlDelegate>*)customSegmentedControlDelegate
{
    self = [super init];
    if (self) {
        // The tag allows callers withe multiple controls to distinguish between them
        self.tag = objectTag;
        
        // Set the delegate
        _segmentedControlDelegate = customSegmentedControlDelegate;
        
        // Adjust our width based on the number of segments & the width of each segment and the sepearator
        self.frame = CGRectMake(0, 0, (segmentsize.width * segmentCount) + (dividerImage.size.width * (segmentCount - 1)), segmentsize.height);
        
        // Initalize the array we use to store our buttons
        self.buttons = [[NSMutableArray alloc] initWithCapacity:segmentCount];
        
        // horizontalOffset tracks the proper x value as we add buttons as subviews
        CGFloat horizontalOffset = 0;
        
        // Iterate through each segment
        for (NSUInteger i = 0 ; i < segmentCount ; i++) {
            // Ask the delegate to create a button
            UIButton* button = [_segmentedControlDelegate buttonFor: self atIndex: i];
            
            // Register for touch events
            [button addTarget: self action: @selector(touchDownAction:) forControlEvents: UIControlEventTouchDown];
            [button addTarget: self action: @selector(touchUpInsideAction:) forControlEvents: UIControlEventTouchUpInside];
            [button addTarget: self action: @selector(otherTouchesAction:) forControlEvents: UIControlEventTouchUpOutside];
            [button addTarget: self action: @selector(otherTouchesAction:) forControlEvents: UIControlEventTouchDragOutside];
            [button addTarget: self action: @selector(otherTouchesAction:) forControlEvents: UIControlEventTouchDragInside];
            
            // Add the button to our buttons array
            [_buttons addObject:button];
            
            // Set the button's x offset
            button.frame = CGRectMake(horizontalOffset, 0.0, button.frame.size.width, button.frame.size.height);
            
            // Add the button as our subview
            [self addSubview: button];
            
            // Add the divider unless we are at the last segment
            if (i != segmentCount - 1) {
                UIImageView* divider = [[UIImageView alloc] initWithImage: dividerImage];
                divider.frame = CGRectMake(horizontalOffset + segmentsize.width, 0.0, dividerImage.size.width, dividerImage.size.height);
                [self addSubview: divider];
            }
            
            // Advance the horizontal offset
            horizontalOffset = horizontalOffset + segmentsize.width + dividerImage.size.width;
        }
    }
    return self;
}

-(void)dimAllButtonsExcept:(UIButton*)selectedButton
{
    for (UIButton* button in _buttons) {
        if (button == selectedButton) {
            button.selected = YES;
            button.highlighted = button.selected ? NO : YES;
        } else {
            button.selected = NO;
            button.highlighted = NO;
        }
    }
}

- (void)touchDownAction:(UIButton*)button
{
    [self dimAllButtonsExcept:button];
    
    if ([_segmentedControlDelegate respondsToSelector: @selector(touchDownAtSegmentIndex:)])
        [_segmentedControlDelegate touchDownAtSegmentIndex: [_buttons indexOfObject: button]];
}

- (void)touchUpInsideAction:(UIButton*)button
{
    [self dimAllButtonsExcept:button];
    
    if ([_segmentedControlDelegate respondsToSelector:@selector(touchUpInsideSegmentIndex:)])
        [_segmentedControlDelegate touchUpInsideSegmentIndex: [_buttons indexOfObject: button]];
}

- (void)otherTouchesAction:(UIButton*)button
{
    [self dimAllButtonsExcept:button];
}



@end
