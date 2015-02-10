//
//  JCMessagesInputToolbar.h
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesInputToolbar.h>
#import "JCMessagesToolbarContentView.h"

@interface JCMessagesInputToolbar : JSQMessagesInputToolbar

@property (nonatomic, weak) IBOutlet JCMessagesToolbarContentView *contentView;

@property (nonatomic) BOOL sendAsSMS;

@end
