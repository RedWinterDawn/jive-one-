//
//  JCVoicemailViewController.h
//  JiveOne
//
//  Created by Doug Leonard on 2/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCVoicemailCell.h"

@interface JCVoicemailViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray* voicemails; //of type voicemail(entity). Exposed for testing

- (void)updateVoicemailData;
- (void)reloadcell:(JCVoicemailCell *)cell;
- (NSData*)getVoiceMailDataUsingString: (NSString*)String;
@end
