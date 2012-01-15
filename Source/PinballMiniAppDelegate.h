//
//  PinballMiniAppDelegate.h
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoreManager.h"
#import "MainMenu.h"

@interface PinballMiniAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	StoreManager* storeManager;
	MainMenu* mainMenu;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) StoreManager* storeManager;
@property (nonatomic, retain) MainMenu* mainMenu;

//- (void) setupFlurryAnalytics;
- (void) setupInitialUserDefaults;
- (void) setupOpenFeint;
- (void) setupCocos2d;
- (void) installOrUpgradeResourceBundle;
- (void) setupSoundEngine;
- (void) loadSoundBuffers:(NSObject*)data;

@end

