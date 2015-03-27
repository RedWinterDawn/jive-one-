//
//  JCMessagesMenuCell.h
//  JiveOne
//
//  Created by P Leonard on 2/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"
#import "JCBadgeView.h"

@interface JCMessagesMenuCell : JCCustomCell
@property (nonatomic, weak) IBOutlet JCBadgeView *unreadSMSMessagesView;
@property (nonatomic, weak) IBOutlet JCBadgeView *unreadChatMessagesView;

@end
