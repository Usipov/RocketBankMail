//
//  PlaceHolderCell.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "PlaceHolderCell.h"

@implementation PlaceHolderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textAlignment = UITextAlignmentCenter;
        self.textLabel.textColor = [UIColor lightGrayColor];
        self.textLabel.font = [UIFont fontWithName: @"ChevinCyrillic-Bold" size: 22.0f];
        self.textLabel.shadowColor = [UIColor colorWithWhite: 0.3 alpha: 0.9];
        self.textLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}


@end
