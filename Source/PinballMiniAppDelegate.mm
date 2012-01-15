//
//  PinballMiniAppDelegate.m
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "PinballMiniAppDelegate.h"
#import "PinballMiniConstants.h"
#import "cocos2d.h"
#import "CocosDenshion.h"
#import "CDAudioManager.h"
#import "ZipArchive.h"
#import <StoreKit/StoreKit.h>


#define RESOURCE_BUNDLE_VERSION @"7"

@implementation PinballMiniAppDelegate

@synthesize window;
@synthesize storeManager;
@synthesize mainMenu;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
	[self setupInitialUserDefaults];
	[self installOrUpgradeResourceBundle];
	storeManager = [[StoreManager alloc] init];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:storeManager];
	// Set any needed application options
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	//[[UIAccelerometer sharedAccelerometer] setUpdateInterval:<#(NSTimeInterval)#>

	// Prep the view
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[window setUserInteractionEnabled:YES];	
	[window setMultipleTouchEnabled:YES];
	[self setupCocos2d];
	[self setupSoundEngine];
    [window makeKeyAndVisible];
	
	// Load the initial scene and start the game
	[[CCDirector sharedDirector] runWithScene:[MainMenu scene]];
}

- (void) setupSoundEngine
{
	// Pre-initialize the sound engine
	[CDAudioManager sharedManager];
	
	if ([CDAudioManager sharedManagerState] != kAMStateInitialised) {
		//The audio manager is not initialised yet so kick off the sound loading as an NSOperation that will wait for
		//the audio manager
		NSInvocationOperation* bufferLoadOp = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadSoundBuffers:) object:nil] autorelease];
		NSOperationQueue *opQ = [[[NSOperationQueue alloc] init] autorelease]; 
		[opQ addOperation:bufferLoadOp];
		//_appState = kAppStateAudioManagerInitialising;
	} else {
		[self loadSoundBuffers:nil];
		//_appState = kAppStateSoundBuffersLoading;
	}	
	[CDAudioManager sharedManager].mute = ![[NSUserDefaults standardUserDefaults] boolForKey:PM_USERDEFAULT_PLAYSOUND];
}

- (void) installOrUpgradeResourceBundle
{
	if([[NSUserDefaults standardUserDefaults] objectForKey:PM_USERDEFAULT_RESOURCEBUNDLEVERSION] == nil || [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:PM_USERDEFAULT_RESOURCEBUNDLEVERSION] compare:RESOURCE_BUNDLE_VERSION] != NSOrderedSame)
	{
		NSString* baseDocumentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
		ZipArchive* zipArchive = [[ZipArchive alloc] init];
		if([zipArchive UnzipOpenFile:[[NSBundle mainBundle] pathForResource:@"BaseResourceBundle" ofType:@"zip"]])
		{
			if([zipArchive UnzipFileTo:baseDocumentPath overWrite:YES])
			{
				[[NSUserDefaults standardUserDefaults] setObject:RESOURCE_BUNDLE_VERSION forKey:PM_USERDEFAULT_RESOURCEBUNDLEVERSION];
			}
		}
		[zipArchive release];
	}
}

- (void) loadSoundBuffers:(NSObject*)data
{
	//Wait for the audio manager if it is not initialised yet
	while ([CDAudioManager sharedManagerState] != kAMStateInitialised) {
		[NSThread sleepForTimeInterval:0.1];
	}
	
	CDSoundEngine *soundEngine = [CDAudioManager sharedManager].soundEngine;
	
	// Sync loading
	[soundEngine loadBuffer:PM_SOUND_BUTTONCLICK filePath:@"ButtonClick.wav"];
	//[soundEngine loadBuffer:PM_SOUND_BUTTONCLICK filePath:@"SingleClockTick.wav"];
	[soundEngine loadBuffer:PM_SOUND_SCOREDING filePath:@"Ding.wav"];
	[soundEngine loadBuffer:PM_SOUND_HAMMERCLICK1 filePath:@"Hammer1.wav"];
	[soundEngine loadBuffer:PM_SOUND_HAMMERCLICK2 filePath:@"Hammer2.wav"];
	[soundEngine loadBuffer:PM_SOUND_HAMMERCLICK3 filePath:@"Hammer3.wav"];
	[soundEngine loadBuffer:PM_SOUND_BALLONPLASTIC1 filePath:@"BallOnPlastic2.wav"];
	[soundEngine loadBuffer:PM_SOUND_MULTIPLIER_X2 filePath:@"Multiplier x2.wav"];
	[soundEngine loadBuffer:PM_SOUND_MULTIPLIER_X3 filePath:@"Multiplier x2.wav"];
	[soundEngine loadBuffer:PM_SOUND_MULTIPLIER_X4 filePath:@"Multiplier x2.wav"];
	[soundEngine loadBuffer:PM_SOUND_MULTIPLIER_X5 filePath:@"Multiplier x2.wav"];
	[soundEngine loadBuffer:PM_SOUND_CLOCKTICK filePath:@"SingleClockTick.wav"];
	[soundEngine loadBuffer:PM_SOUND_VICTORY filePath:@"Victory.wav"];
	[[CDAudioManager sharedManager] preloadBackgroundMusic:@"MenuBackgroundMusic.mp3"];
	[[CDAudioManager sharedManager].backgroundMusic setVolume:0.3];
	
	
	//[[CDAudioManager sharedManager].backgroundMusic play];
	// Async loading - if needed
	//NSMutableArray *loadRequests = [[[NSMutableArray alloc] init] autorelease];
	//[loadRequests addObject:[[[CDBufferLoadRequest alloc] init:PM_SOUND_BUTTONCLICK filePath:@"ButtonClick.wav"] autorelease]];
	//[soundEngine loadBuffersAsynchronously:loadRequests];
	
}

/*
- (void) setupFlurryAnalytics
{
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	[FlurryAPI startSession:@"6TKCN2G2M48I7QN25DRI"];
}
*/

- (void) setupInitialUserDefaults
{
	if([[NSUserDefaults standardUserDefaults] objectForKey:PM_USERDEFAULT_PLAYSOUND] == nil)
	{
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:PM_USERDEFAULT_PLAYSOUND];
	}
	
	// We'll always turn off gravity lock at launch, but the user can change while running
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:PM_USERDEFAULT_GRAVITYLOCK];
	
	[[NSUserDefaults standardUserDefaults] synchronize];			
}

- (void) setupCocos2d
{
	// Try to use the display link director if possible
	if(![CCDirector setDirectorType:CCDirectorTypeDisplayLink])
	{
		// The other timers (*MainLoop) aren't an option since we need UIKit objects
		[CCDirector setDirectorType:CCDirectorTypeNSTimer];
	}
	[[CCDirector sharedDirector] setDisplayFPS:NO];
	[[CCDirector sharedDirector] setAnimationInterval:1.0f/30.0f];
	[[CCDirector sharedDirector] attachInWindow:window];
}

// Pausing the game
-(void) applicationWillResignActive:(UIApplication *)application
{
	[[CCDirector sharedDirector] pause];
}

// Returning from pause
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	[[CCDirector sharedDirector] resume];
}

// Low memory condition
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCTextureCache sharedTextureCache] removeAllTextures];
}

// Something changed the clock
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

-(void) applicationWillTerminate:(UIApplication *)application
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver: storeManager];
}

- (void)dealloc {
	[storeManager release];
    [window release];
    [super dealloc];
}



@end
