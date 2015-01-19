//
//  JCConferenceCallCardViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 1/19/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCurrentCallCardViewCell.h"
#import "JCConferenceCallCard.h"

@interface JCConferenceCallCardViewCell : JCCurrentCallCardViewCell

@property (nonatomic, strong) JCConferenceCallCard *callCard;

@end
