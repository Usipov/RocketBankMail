//
//  CustomSegmentedControl.h
//  RocketBankMail
//
//  Created by Тимур Юсипов on 06.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#define kSegmTitles @"titles"
#define kSegmSize @"size" 
#define kSegmButtonImage @"button-image" 
#define kSegmButtonImageH @"button-highlight-image" 
#define kSegmDividerImage @"divider-image" 
#define kSegmCapWidth @"cap-width" 

#define kSegmButtonImageL @"button-image-left"
#define kSegmButtonImageLH @"button-image-left-highlighted"
#define kSegmButtonImageC @"button-image-center"
#define kSegmButtonImageCH @"button-image-center-highlighted"
#define kSegmButtonImageR @"button-image-right"
#define kSegmButtonImageRH @"button-image-right-highlighted"

typedef enum {
    CapLeft          = 0,
    CapMiddle        = 1,
    CapRight         = 2,
    CapLeftAndRight  = 3
} CapLocation;


@class SegmentedControl;
@protocol SegmentedControlDelegate <NSObject>

-(UIButton *)segmentedControl: (SegmentedControl*)segmentedControl buttonAtIndex: (NSUInteger)segmentIndex;

@optional
- (void)segmentedControl: (SegmentedControl*)segmentedControl touchUpInsideSegmentIndex:(NSUInteger)segmentIndex;
- (void)segmentedControl: (SegmentedControl*)segmentedControl touchDownAtSegmentIndex:(NSUInteger)segmentIndex;
@end

@interface SegmentedControl : UIView 

@property (nonatomic, retain) NSMutableArray* buttons;

-(id)initWithSegmentCount:(NSUInteger)segmentCount segmentsize:(CGSize)segmentsize dividerImage:(UIImage*)dividerImage tag:(NSInteger)objectTag delegate:(NSObject <SegmentedControlDelegate>*)segmentedControlDelegate;
-(void)setSelectedButtonAtIndex: (NSUInteger)index;

@end
