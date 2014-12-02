//
//  JCLineConfigurationViewController.m
//  JiveOne
//
//  Created by P Leonard on 12/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLineConfigurationViewController.h"

#import "LineConfiguration.h"
#import "JCAuthenticationManager.h"

@interface JCLineConfigurationViewController ()
{
    JCAuthenticationManager *_authenticationManger;
}



@property (strong, nonatomic) NSArray *lineConfigurations;

@end

@implementation JCLineConfigurationViewController





- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lineConfigurations = [LineConfiguration MR_findAllSortedBy:@"display" ascending:YES];
    
    _authenticationManger = [JCAuthenticationManager sharedInstance];
//    KVO subscription
    [_authenticationManger addObserver:self forKeyPath:NSStringFromSelector(@selector(lineConfiguration)) options:0 context:NULL];
    
    LineConfiguration *currentLineConfiguration = _authenticationManger.lineConfiguration;
    
    NSString *currentLine = currentLineConfiguration.display;
    NSInteger index = [self.lineConfigurations indexOfObject:currentLineConfiguration];
    [self.lineList selectRow:index inComponent:0 animated:NO];
    
//    This is the line we have selected and we want to start the selection list on this line.
    [self.lineSelection setTitle:currentLine forState:UIControlStateNormal];
    
   
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(lineConfiguration))]) {
        JCAuthenticationManager *manager =  (JCAuthenticationManager *)object;
        [self.lineSelection setTitle:manager.lineConfiguration.display forState:UIControlStateNormal];
        
    }
}
//  KVO Unsubscribe
-(void)dealloc{
    [_authenticationManger removeObserver:self forKeyPath:NSStringFromSelector(@selector(lineConfiguration))];
}


#pragma mark Picker data source Methods
//  Only One collum
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_lineConfigurations count];
}

#pragma mark Picker Delegate Methods
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    LineConfiguration *lineConfiguration = [_lineConfigurations objectAtIndex:row];
    return lineConfiguration.display;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    LineConfiguration *lineConfiguration  = [_lineConfigurations objectAtIndex:row];
    if (self.makeDefaultLineSwitch.on) {
        
        NSArray *lineConfigurations = _lineConfigurations;
        for (LineConfiguration *lineConfig in lineConfigurations) {
            if (lineConfiguration == lineConfig){
                lineConfig.active = TRUE;
            }
            else{
                lineConfig.active = FALSE;
            }
        }
        
        // If we have changes, save them.
        if (lineConfiguration.managedObjectContext.hasChanges) {
            __autoreleasing NSError *error;
            if(![lineConfiguration.managedObjectContext save:&error])
                NSLog(@"%@", [error description]);
        }
    }
    
    _authenticationManger.lineConfiguration = lineConfiguration;
    
}

- (IBAction)lineSelectionAction:(id)sender {
    //add animating in and out upon selection
    
   }
@end
