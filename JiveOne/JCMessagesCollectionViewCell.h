//
//  JCMessagesCollectionViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JSQMessagesCollectionViewCell.h"

@interface JCMessagesCollectionViewCell : JSQMessagesCollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *avatarLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@property (nonatomic, getter=isIncoming) BOOL incoming;

@end
