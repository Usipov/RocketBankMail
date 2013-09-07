//
//  AppDelegate.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 31.08.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "AppDelegate.h"
#import "CoreDataManager.h"
#import "MailsViewController.h"

#define kIS_FIRST_APP_LAUNCH_KEY @"App was never lanched?"

void UncoughtExceptionHandler(NSException *exception)
{
    NSLog(@"App terminated by an exception: %@", exception);
    NSLog(@"Call Stack: %@", exception.callStackSymbols);
}

@interface AppDelegate ()

@property (nonatomic, readwrite) BOOL isFirstAppLaunch;

@end

@implementation AppDelegate

@synthesize isFirstAppLaunch = _isFirstAppLaunch;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //set an uncought exception handler
    NSSetUncaughtExceptionHandler(&UncoughtExceptionHandler);

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
   [self.window makeKeyAndVisible];

    //configure Core Data
    [[CoreDataManager sharedManager] mainManagedObjectContext];
    
    //preload initiial instances on 1st app launch
    if (YES == self.isFirstAppLaunch) {
        [[CoreDataManager sharedManager] createDefaultMailBoxItems];
    }
    
    
    MailsViewController *mailsVC = [[MailsViewController alloc] initForThreeMailBoxesWithStyle: UITableViewStylePlain];
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController: mailsVC];
    
    self.window.rootViewController = nvc;
    
    return YES;
}

-(BOOL)isFirstAppLaunch
{
    if (NO == _isFirstAppLaunch) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *flag = [defaults objectForKey: kIS_FIRST_APP_LAUNCH_KEY];
        if (! flag) {
             //(first app launch case)
            flag = [NSNumber numberWithBool: YES];
            [defaults setObject: flag forKey: kIS_FIRST_APP_LAUNCH_KEY];
            [defaults synchronize];
            _isFirstAppLaunch = YES;
        }
    }
    return _isFirstAppLaunch;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end



