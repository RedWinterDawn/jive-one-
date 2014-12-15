//
//  JCPbxConfigurationViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLinePickerViewController.h"
#import "JCAuthenticationManager.h"
#import "PBX.h"
#import "Line.h"

@interface JCLinePickerViewController ()
{
    JCAuthenticationManager *_authenticationManger;
}

@property (strong, nonatomic) NSArray *lines;

@end

@implementation JCLinePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _authenticationManger = [JCAuthenticationManager sharedInstance];
    self.lines = [Line MR_findByAttribute:@"pbx.user" withValue:_authenticationManger.user andOrderBy:@"name" ascending:YES];
    [_authenticationManger addObserver:self forKeyPath:NSStringFromSelector(@selector(line)) options:0 context:NULL];
    Line *line = _authenticationManger.line;
    
    [self.pickerView selectRow:[self.lines indexOfObject:line] inComponent:0 animated:NO];
    
    NSString *name = [self titleForLine:line];
    [self.selectBtn setTitle:name forState:UIControlStateNormal];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(pbx))]) {
        JCAuthenticationManager *manager =  (JCAuthenticationManager *)object;
        [self.selectBtn setTitle:[self titleForLine:manager.line] forState:UIControlStateNormal];
    }
}

-(void)dealloc{
    [_authenticationManger removeObserver:self forKeyPath:NSStringFromSelector(@selector(pbx))];
}

-(NSString *)titleForLine:(Line *)line
{
    return [NSString stringWithFormat:@"%@ on %@", line.extension, line.pbx.name];
}

-(NSString *)titleForRow:(NSInteger)row
{
    Line *line = [_lines objectAtIndex:row];
    return [self titleForLine:line];
}

-(NSInteger)numberOfRows
{
    return [_lines count];
}

#pragma mark - Delegate Handlers -

#pragma mark UIPickerDelegate Methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    Line *line  = [_lines objectAtIndex:row];
    
    NSArray *lines = _lines;
    for (Line *item in lines) {
        if (line == item){
            item.active = TRUE;
        }
        else{
            item.active = FALSE;
        }
    }
    
    // If we have changes, save them.
    if (line.managedObjectContext.hasChanges) {
        __autoreleasing NSError *error;
        if(![line.managedObjectContext save:&error])
            NSLog(@"%@", [error description]);
    }
    
    _authenticationManger.line = line;
    
    [super pickerView:pickerView didSelectRow:row inComponent:component];
}

@end
