//
//  JCMessagesCollectionViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessagesCollectionViewCell.h"

#import <JSQMessagesViewController/JSQMessagesCollectionViewLayoutAttributes.h>

@protocol JSQMessagesCollectionViewCellPrivate <NSObject>

@optional
@property (nonatomic) CGSize avatarViewSize;

@end

@interface JSQMessagesCollectionViewCell () <JSQMessagesCollectionViewCellPrivate>

@end

@implementation JCMessagesCollectionViewCell

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];
    
    JSQMessagesCollectionViewLayoutAttributes *customAttributes = (JSQMessagesCollectionViewLayoutAttributes *)layoutAttributes;
    if (self.isIncoming) {
        self.avatarViewSize = customAttributes.incomingAvatarViewSize;
    } else {
        self.avatarViewSize = customAttributes.outgoingAvatarViewSize;
    }
    
}

@end
