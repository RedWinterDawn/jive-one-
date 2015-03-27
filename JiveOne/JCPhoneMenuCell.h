//
//  JCPhoneMenuCell.h
//  JiveOne
//
//  Created by Robert Barclay on 11/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"
#import "JCBadgeView.h"

@interface JCPhoneMenuCell : JCCustomCell

@property (nonatomic, weak) IBOutlet JCBadgeView *missedCallsBadgeView;
@property (nonatomic, weak) IBOutlet JCBadgeView *voicemailsBadgeView;

@end
