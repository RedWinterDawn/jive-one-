//
//  JCConversationTableViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 2/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCTableViewCell.h"

@interface JCConversationTableViewCell : JCTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UILabel *date;

@property (nonatomic, getter=isRead) BOOL read;

@end
