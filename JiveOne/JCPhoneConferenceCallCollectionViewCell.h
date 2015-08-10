//
//  JCConferenceCallCardViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 1/19/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneActiveCallCollectionViewCell.h"
#import "JCPhoneConferenceCall.h"

@interface JCPhoneConferenceCallCollectionViewCell : JCPhoneActiveCallCollectionViewCell

@property (nonatomic, strong) JCPhoneConferenceCall *callCard;

@end
