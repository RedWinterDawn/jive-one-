//
//  JCPresenceCell.m
//  JiveOne
//
//  Created by Robert Barclay on 11/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPresenceCell.h"
#import "JCPresenceManager.h"

#define DEFAULT_PRESENCE_LINE_WIDTH 4

@interface JCPresenceCell ()
{
    JCPresenceManager *_presenceManager;
    JCLinePresence *_linePresence;
    CALayer *_presenceLayer;
}

@property (nonatomic, readonly) CALayer *presenceLayer;
@property (nonatomic, readonly) JCLinePresenceState state;

@end

@implementation JCPresenceCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        _presenceManager = [JCPresenceManager sharedManager];
        _lineWidth = DEFAULT_PRESENCE_LINE_WIDTH;
        _baseColor = DEFAULT_PRESENCE_BASE_COLOR;
    }
    return self;
}

/**
 * Draw the initial presence layer.
 *
 * This is called when the view is first added to its super view. By placing the
 * rebuildLayers method call in here, we ensure that when the view is drawn
 * after being added to subview the subview layer will have been drawn.
 */
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if(newSuperview)
        [self rebuildLayers];
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    
    if (_linePresence) {
        [_linePresence removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];
        _linePresence = nil;
    }
    
    [self rebuildLayers];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:NSStringFromSelector(@selector(state))]){
        [self rebuildLayers];
    }
}

#pragma mark - Setters -

-(void)setIdentifier:(NSString *)identifier {
    if (_linePresence) {
        [_linePresence removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];
    }
        
    _linePresence = [_presenceManager linePresenceForIdentifier:identifier];
    if (_linePresence) {
        [_linePresence addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:NSKeyValueObservingOptionInitial context:NULL];
    }
    
    if(self.superview)
        [self rebuildLayers];
}

#pragma mark - Getters -

-(NSString *)identifier
{
    return _linePresence.identfier;
}

-(JCLinePresenceState)state
{
    if(_linePresence)
        return _linePresence.state;
    return JCLinePresenceTypeOffline;
}

- (CALayer *)presenceLayer
{
    if(!_presenceLayer) {
        _presenceLayer = [CALayer layer];
        _presenceLayer.frame = CGRectMake(0, 0, _lineWidth, self.bounds.size.height);
        _presenceLayer.contentsScale = [UIScreen mainScreen].scale;
        _presenceLayer.backgroundColor = [self colorForState:self.state].CGColor;
    }
    return _presenceLayer;
}

#pragma mark - Private -

-(void)rebuildLayers
{
    [_presenceLayer removeFromSuperlayer];
    _presenceLayer = nil;
    [self.layer addSublayer:self.presenceLayer];
}

-(UIColor *)colorForState:(JCLinePresenceState)state
{
    switch (state) {
        case JCLinePresenceTypeAvailable:
            return DEFAULT_PRESENCE_AVAILABLE_COLOR;
            
        case JCLinePresenceTypeBusy:
            return DEFAULT_PRESENCE_BUSY_COLOR;
            
        case JCLinePresenceTypeDoNotDisturb:
            return DEFAULT_PRESENCE_DO_NOT_DISTURB_COLOR;
            
        default:
            return DEFAULT_PRESENCE_OFFLINE_COLOR;
    }
}

@end
