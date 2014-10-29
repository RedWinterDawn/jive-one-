//
//  JCVoicemailCell.h
//  JiveOne
//
//  Created by Robert Barclay on 10/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentEventCell.h"
#import "Voicemail.h"

@interface JCVoicemailCell : JCRecentEventCell

@property (nonatomic, strong) Voicemail *voicemail;

@property (nonatomic, weak) IBOutlet UILabel *callerIdLabel;
@property (nonatomic, weak) IBOutlet UILabel *callerNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *duration;
@property (nonatomic, weak) IBOutlet UILabel *creationTime;
@property (nonatomic, weak) IBOutlet UILabel *extensionLabel;

@end
