//
//  JCBadgeManager.m
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCBadgeManager.h"
#import "LoggerClient.h"

#import "RecentEvent.h"

#import "MissedCall.h"
#import "Voicemail.h"
#import "Conversation.h"

#import "OutgoingCall.h"

static const UIUserNotificationType USER_NOTIFICATION_TYPES_REQUIRED = UIRemoteNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
static const UIRemoteNotificationType REMOTE_NOTIFICATION_TYPES_REQUIRED = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;

NSString *const kJCBadgeManagerBadgesKey        = @"badges";
NSString *const kJCBadgeManagerRecentEventsKey  = @"recentEvents";
NSString *const kJCBadgeManagerVoicemailsKey    = @"voicemails";
NSString *const kJCBadgeManagerMissedCallsKey   = @"missedCalls";
NSString *const kJCBadgeManagerConversationsKey = @"conversations";

NSString *const kJCBadgeManagerInsertedIdentifierNotification = @"insertedIdentifier";
NSString *const kJCBadgeManagerDeletedIdentifierNotification = @"deletedIdentifier";
NSString *const kJCBadgeManagerIdentifierKey = @"identifierKey";
NSString *const kJCBadgeManagerBadgeKey = @"badgeKey";

@interface JCBadgeManager ()
{
    NSMutableDictionary *_badges;
}

@property (nonatomic, strong) NSMutableDictionary *badges;

@end

@implementation JCBadgeManager

-(instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (self) {
        _managedObjectContext = managedObjectContext;
        _saveToPersistantStore = true;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextUpdated:) name:NSManagedObjectContextDidSaveNotification object:_managedObjectContext];
        [self addObserver:self forKeyPath:kJCBadgeManagerBadgesKey options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

-(void)initialize
{
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        if (![self canSendNotifications])
        {
            UIUserNotificationSettings* requestedSettings = [UIUserNotificationSettings settingsForTypes:USER_NOTIFICATION_TYPES_REQUIRED categories:nil];
            [application registerUserNotificationSettings:requestedSettings];
        }
    }
    else
    {
        [application registerForRemoteNotificationTypes:REMOTE_NOTIFICATION_TYPES_REQUIRED];
    }
    [self update];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kJCBadgeManagerBadgesKey]) {
        [self update];
    }
}

-(void)update
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSUInteger recentEvents = self.recentEvents;
        NSLog(@"recentEvents: %lu", (unsigned long)recentEvents);
        if (self.canSendNotifications && recentEvents > 0)
        {
            [UIApplication sharedApplication].applicationIconBadgeNumber = recentEvents;
        }
    });
}

-(void)startBackgroundUpdates
{
    NSArray *keys = [self.badges allKeys];
    for (NSString *key in keys)
    {
        NSMutableDictionary *identifiers = [self identifiersForKey:key];
        NSArray *identifierKeys = [identifiers allKeys];
        for (NSString *identifier in identifierKeys)
        {
            [self setIdentifier:identifier forKey:key displayed:YES];
        }
    }
}

-(NSUInteger)endBackgroundUpdates
{
    // TODO: enumberate through all the badges, identifieying badges that have not been flagged as displayed, get
    // managed objects for the badge, and generate a local notification for it, flagging it as displayed.
    return 0;
}

// Clears out the badges in the badges array.

-(void)reset
{
    self.badges = nil;
}

#pragma mark - Setters -

-(void)setBadges:(NSMutableDictionary *)badges
{
    [self willChangeValueForKey:kJCBadgeManagerBadgesKey];
    
    _badges = badges;
    if (_saveToPersistantStore)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:badges forKey:kJCBadgeManagerBadgesKey];
        [userDefaults synchronize];
    }
    
    [self didChangeValueForKey:kJCBadgeManagerBadgesKey];
}

#pragma mark - Getters -

-(NSMutableDictionary *)badges
{
    if (!_badges)
    {
        if (_saveToPersistantStore) {
            _badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kJCBadgeManagerBadgesKey]];
        }
        else
        {
            _badges = [NSMutableDictionary dictionary];
        }
    }
    return _badges;
}

// Checks the permissions to see if we can sent notifications, including badging.
- (BOOL)canSendNotifications;
{
    UIApplication *application = [UIApplication sharedApplication];
    if (![application respondsToSelector:@selector(currentUserNotificationSettings)])
        return true; // We actually just don't know if we can, no way to tell programmatically before iOS8
    
    UIUserNotificationSettings *notificationSettings = [application currentUserNotificationSettings];
    return (notificationSettings.types == USER_NOTIFICATION_TYPES_REQUIRED);
}

- (NSUInteger)recentEvents
{
    NSDictionary *badges = self.badges;
    NSArray *keys = badges.allKeys;
    int total = 0;
    for (NSString *key in keys)
    {
        total += [self badgeCountForKey:key];
    }
    return total;
}

- (NSUInteger)voicemails
{
    return [self badgeCountForKey:kJCBadgeManagerVoicemailsKey];
}

- (NSUInteger)missedCalls
{
    return [self badgeCountForKey:kJCBadgeManagerMissedCallsKey];
}

- (NSUInteger)conversations
{
    return [self badgeCountForKey:kJCBadgeManagerConversationsKey];
}

#pragma mark - Notification Handlers -

-(void)managedObjectContextUpdated:(NSNotification *)notification
{
    NSDictionary *dictionary = notification.userInfo;
    id inserted = [dictionary objectForKey:NSInsertedObjectsKey];
    id updated = [dictionary objectForKey:NSUpdatedObjectsKey];
    id deleted = [dictionary objectForKey:NSDeletedObjectsKey];
    id object = inserted ? inserted : (updated ? updated : (deleted ? deleted : nil));
    NSSet *objects = (NSSet *)object;
    id managedObject = [objects anyObject];
    if (![managedObject isKindOfClass:[RecentEvent class]])
        return;
    
    RecentEvent *recentEvent = (RecentEvent *)managedObject;
    NSString *key = [self badgeKeyFromRecentEvent:recentEvent];
    NSString *identifier = recentEvent.objectID.URIRepresentation.absoluteString;
    BOOL read = recentEvent.read;
    BOOL insert = inserted != nil;
    BOOL update = updated != nil;
    BOOL delete = deleted != nil;
    
    // Do this stuff off of main thread, since we need to check if it contains, and then add it in a multidimensional
    // array for performance.
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        if (insert && !read) {
            [self setIdentifier:identifier forKey:key displayed:NO];
        }
        else if (update) {
            if (read) {
                [self setIdentifier:identifier forKey:key displayed:NO];
            }
            else {
                [self deleteIdentifier:identifier forKey:key];
            }
        }
        else if (delete) {
            [self deleteIdentifier:identifier forKey:key];
        }
    });
}

#pragma mark - Private -

/**
 * Returns a identifier key for a given recent event.
 *
 * The Identifier key returned is used thoughout the badge system to categorize a recent event into a bucket. The bucket
 * count provides us the badge numbers for a given key.
 */
-(NSString *)badgeKeyFromRecentEvent:(RecentEvent *)recentEvent
{
    if ([recentEvent isKindOfClass:[MissedCall class]] || [recentEvent isKindOfClass:[OutgoingCall class]]) {
        return kJCBadgeManagerMissedCallsKey;
    }
    else if ([recentEvent isKindOfClass:[Voicemail class]])
    {
        return kJCBadgeManagerVoicemailsKey;
    }
    else if ([recentEvent isKindOfClass:[Conversation class]])
    {
        return kJCBadgeManagerConversationsKey;
    }
    return nil;
}

/**
 * Gets the badge count of a badge category key.
 */
-(NSUInteger)badgeCountForKey:(NSString *)key
{
    NSDictionary *identifiers = [self identifiersForKey:key];
    return [identifiers allKeys].count;
}

/**
 * Inserts a badge event identifier into the badge system for the badge category bucket by its key.
 *
 * Only inserts on if it does not contain one. The identifier is stored as the key in a dictionary with a boolean value
 * representing if it has been "read". The read state is used during a background refresh to identifiy which ones have
 * generated a local notification for.
 */
-(void)setIdentifier:(NSString *)identifier forKey:(NSString *)key displayed:(BOOL)displayed
{
    NSMutableDictionary *identifiers = [self identifiersForKey:key];
    [identifiers setObject:[NSNumber numberWithBool:displayed] forKey:identifier];
    [self setIdentifiers:identifiers forKey:key];
}

/**
 * Removes an badge event identifier from the given badge bucket by its key.
 */
-(void)deleteIdentifier:(NSString *)identifier forKey:(NSString *)key
{
    NSMutableDictionary *identifiers = [NSMutableDictionary dictionaryWithDictionary:[self identifiersForKey:key]];
    [identifiers removeObjectForKey:identifier];
    [self setIdentifiers:identifiers forKey:key];
}

/**
 *  Returns if we have an identifier stored for the given key in badges.
 */
-(BOOL)containsIdentifier:(NSString *)identifier forKey:(NSString *)key
{
    NSDictionary *identifiers = [self.badges objectForKey:key];
    id object = [identifiers objectForKey:identifiers];
    if (object) {
        return true;
    }
    return false;
}

/**
 * Returns a dictionary of badge identifiers for a given key from the badges dictionary in the user default. If non have
 * been set, it should return nil, otherwise, it should return a dictionary of identifiers, where the identifier is the 
 * key, and a bool is the value.
 */
-(NSMutableDictionary *)identifiersForKey:(NSString *)key
{
    return [NSMutableDictionary dictionaryWithDictionary:[self.badges objectForKey:key]];
}

/**
 * Sets the the badge identifiers for a given key.
 *
 * This method does not merge current identifers, but rather replaces them. If you are updating, You should get the 
 * identifiers, add them, the set them.
 */
-(void)setIdentifiers:(NSDictionary *)identifiers forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    
    NSMutableDictionary *badges = self.badges;
    [badges setObject:identifiers forKey:key];
    self.badges = badges;
    
    [self didChangeValueForKey:key];
}


/*
- (void)setNotification:(NSInteger)voicemailCount conversation:(NSInteger)conversationCount {
    LOG_Info();
    
    //if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)  {
    
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    
    
    [_badges enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSRange rangeConversation = [key rangeOfString:@"conversations"];
        NSRange rangeRooms = [key rangeOfString:@"permanentrooms"];
        if (rangeConversation.location != NSNotFound || rangeRooms.location != NSNotFound) {
            NSMutableDictionary *convCopy = nil;
            if ([_badges[key] isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *conversations = [_badges[key] mutableCopy];
                if (conversations) {
                    convCopy = [[conversations copy] mutableCopy];
                    for (NSString *entry in conversations) {
                        NSNumber *shown = conversations[entry];
                        if (![shown boolValue]) {
                            
                            ConversationEntry *lastEntry = [ConversationEntry MR_findFirstByAttribute:@"entryId" withValue:entry];
                            PersonEntities *person = [PersonEntities MR_findFirstByAttribute:@"entityId" withValue:lastEntry.entityId];
                            NSString *alertMessage = [NSString stringWithFormat:@"%@: \"%@\"", person.firstName, lastEntry.message[@"raw"]];
                            
                            [self showLocalNotificationWithType:@"conversation" alertMessage:alertMessage];
                            [convCopy setObject:[NSNumber numberWithBool:YES] forKey:entry];
                            
                            
                        }
                    }
                    [_badges setObject:convCopy forKey:key];
                }
            }
            
        }
        
        NSRange rangeVoicemail = [key rangeOfString:@"jrn"];
        if (rangeVoicemail.location != NSNotFound ) {
            NSNumber *notified = _badges[key];
            if (![notified boolValue]) {
                notified = [NSNumber numberWithBool:YES];
                Voicemail *lastEntry = [Voicemail MR_findFirstByAttribute:@"jrn" withValue:key];
                if (lastEntry) {
                    NSString *alertMessage = lastEntry.name ? [NSString stringWithFormat:@"New voicemail from %@", lastEntry.number]  : @"Unknown";
                    [self showLocalNotificationWithType:@"voicemail" alertMessage:alertMessage];
                }
            }
            _badges[key] = notified;
            //[[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
            //[[NSUserDefaults standardUserDefaults] synchronize];
        }
        
    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}*/

/*- (void)showLocalNotificationWithType:(NSString *)alertType alertMessage:(NSString *)alertMessage
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = alertMessage;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}*/

@end

static JCBadgeManager *badgeManager = nil;

@implementation JCBadgeManager (Singleton)

+(JCBadgeManager *)sharedManager
{
    if (badgeManager != nil)
        return badgeManager;
    
    // Makes the startup of this singleton thread safe.
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        badgeManager = [[JCBadgeManager alloc] initWithManagedObjectContext:[NSManagedObjectContext MR_rootSavingContext]];
    });
    
    return badgeManager;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
