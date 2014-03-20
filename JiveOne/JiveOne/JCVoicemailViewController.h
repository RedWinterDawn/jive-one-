//
//  JCVoicemailViewController.h
//  JiveOne
//
//  Created by Doug Leonard on 2/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCVoicemailViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray* newVoicemails; //of type voicemail(entity). Exposed for testing
@property (strong, nonatomic) NSMutableArray* oldVoicemails; //of type voicemail(entity). Exposed for testing
- (void)updateVoicemailData;
- (NSData*)getVoiceMailDataUsingString: (NSString*)String;
@end
