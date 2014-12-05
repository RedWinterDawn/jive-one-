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
#import <QuartzCore/QuartzCore.h>

@interface JCLineConfigurationViewController ()
{
    JCAuthenticationManager *_authenticationManger;
    BOOL _pickerVisible;
    NSInteger _verticalSpacing;
}

@property (strong, nonatomic) NSArray *lineConfigurations;

@end

@implementation JCLineConfigurationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    [[self.lineSelection layer] setBorderWidth:1.0f];
    [[self.lineSelection layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    [[self.lineSelection layer] setCornerRadius:2.0f];
    
    self.lineConfigurations = [LineConfiguration MR_findAllSortedBy:@"display" ascending:YES];
    
    _authenticationManger = [JCAuthenticationManager sharedInstance];
    [_authenticationManger addObserver:self forKeyPath:NSStringFromSelector(@selector(lineConfiguration)) options:0 context:NULL];
    
    LineConfiguration *currentLineConfiguration = _authenticationManger.lineConfiguration;
    
    NSString *currentLine = currentLineConfiguration.display;
    NSInteger index = [self.lineConfigurations indexOfObject:currentLineConfiguration];
    [self.lineList selectRow:index inComponent:0 animated:NO];
    
    // This is the line we have selected and we want to start the selection list on this line.
    [self.lineSelection setTitle:currentLine forState:UIControlStateNormal];
    
    _pickerVisible = TRUE;
    [self hidePicker:false];
}

-(void)awakeFromNib{
    _verticalSpacing = self.lineListBottomConstraint.constant;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(lineConfiguration))]) {
        JCAuthenticationManager *manager =  (JCAuthenticationManager *)object;
        [self.lineSelection setTitle:manager.lineConfiguration.display forState:UIControlStateNormal];
        
    }
}

-(void)dealloc{
    [_authenticationManger removeObserver:self forKeyPath:NSStringFromSelector(@selector(lineConfiguration))];
}

#pragma mark - IBActions -

-(IBAction)close:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(lineConfigurationViewControllerShouldDismiss:)]) {
        [_delegate lineConfigurationViewControllerShouldDismiss:self];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)lineSelectionAction:(id)sender {
    if(_pickerVisible) {
        [self hidePicker:true];
    } else {
        [self showPicker:true];
    }
}

- (IBAction)doneButton:(id)sender {
    [self hidePicker:TRUE];
}

#pragma mark - Private -

-(void)showPicker:(BOOL)animated{
    if (_pickerVisible) {
        return;
    }
    __unsafe_unretained JCLineConfigurationViewController *weakSelf = self;
    _lineListBottomConstraint.constant = 0;
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:(animated ? 0.6 : 0.0)
                     animations:^{
                         
                         [weakSelf.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         _pickerVisible = true;
                     }];
}

-(void)hidePicker:(BOOL)animated{
    if(!_pickerVisible) {
        return;
    }
    __unsafe_unretained JCLineConfigurationViewController *weakSelf = self;
    _lineListBottomConstraint.constant = -_lineListHeightConstraint.constant;
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:(animated ? 0.6 : 0.0)
                     animations:^{
                         [weakSelf.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         _pickerVisible = false;
                     }];
}



#pragma mark - Delegate Handlers -

#pragma mark UIPickerDataSource Methods

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_lineConfigurations count];
}

#pragma mark UIPickerDelegate Methods

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
    [self hidePicker:YES];
    
}

@end
