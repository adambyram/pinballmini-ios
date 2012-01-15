//
//  MainMenu.mm
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainMenu.h"
#import "PinballMiniConstants.h"
#import "Information.h"
#import "Help.h"
#import "CocosDenshion.h"
#import "CDAudioManager.h"
#import "GameBoard.h"
#import "Storefront.h"
#import "PinballMiniAppDelegate.h"
#import <QuartzCore/QuartzCore.h>


@implementation MainMenu
UIButton* csb = nil;

@synthesize internalScene;
@synthesize localScores;

//SystemSoundID buttonClick;

+(id) scene
{
	// 'scene' is an autorelease object.
	//Scene *scene = [ShakeEnabledScene node];
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MainMenu *layer = [MainMenu node];
	layer.internalScene = scene;
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}
/*
-(void)productPurchased:(UAProduct*) product {
	//UALOG(@"[StoreFrontDelegate] Purchased: %@ -- %@", product.productIdentifier, product.title);
	NSString* baseDocumentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	NSString* downloadPath = [baseDocumentPath stringByAppendingPathComponent:product.productIdentifier];
	NSArray* directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:downloadPath];
	NSMutableArray* newBoards = [[NSMutableArray alloc] init];
	NSError* error = nil;
	for(NSString* file in directoryContents)
	{
		NSString* fullFilePath = [downloadPath stringByAppendingPathComponent:file];
		BOOL isDirectory = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:fullFilePath isDirectory:&isDirectory] && isDirectory)
		{
			
			
			if([[NSFileManager defaultManager] fileExistsAtPath:[[baseDocumentPath stringByAppendingPathComponent:@"Boards/"] stringByAppendingPathComponent:file]])
			{
				[[NSFileManager defaultManager] removeItemAtPath:[[baseDocumentPath stringByAppendingPathComponent:@"Boards/"] stringByAppendingPathComponent:file] error:&error];
				if(error != nil)
				{
					NSLog(@"%@",error);
				}
			}
			
			[[NSFileManager defaultManager] copyItemAtPath:fullFilePath toPath:[[baseDocumentPath stringByAppendingPathComponent:@"Boards/"] stringByAppendingPathComponent:file] error:&error];
			if(error != nil)
			{
				NSLog(@"%@",error);
			}
			
			[newBoards addObject:[[NSDictionary dictionaryWithContentsOfFile:[fullFilePath stringByAppendingPathComponent:@"BoardInfo.plist"]] objectForKey:@"BoardId"]];
			[[NSFileManager defaultManager] removeItemAtPath:fullFilePath error:&error];
			if(error != nil)
			{
				NSLog(@"%@",error);
			}
		}
	}
	[[NSFileManager defaultManager] removeItemAtPath:downloadPath error:&error];
	
	NSMutableArray* installedBoardArray = [NSMutableArray arrayWithContentsOfFile:[baseDocumentPath stringByAppendingPathComponent:@"Configuration/InstalledBoards.plist"]];
	for(NSString* board in newBoards)
	{
		BOOL alreadyAdded = NO;
		for(NSDictionary* dictionary in installedBoardArray)
		{
			if([(NSString*)[dictionary objectForKey:@"BoardId"] compare:board] == NSOrderedSame)
			{
				alreadyAdded = YES;
				break;
			}
		}
		if(!alreadyAdded)
		{
			[installedBoardArray addObject:[NSDictionary dictionaryWithObject:board forKey:@"BoardId"]];
		}
	}
	
	[installedBoardArray writeToFile:[baseDocumentPath stringByAppendingPathComponent:@"Configuration/InstalledBoards.plist"] atomically:YES];
	[self reloadBoardDisplay];
}


-(void)storeFrontDidHide {
	UALOG(@"[StoreFrontDelegate] StoreFront quit, do something with content");
	//[self reloadBoardDisplay];
}

-(void)storeFrontWillHide {
	UALOG(@"[StoreFrontDelegate] StoreFront will hide");
}
*/ 

-(void)applyScreenshotSprite
{
	UIView* currentView = [[CCDirector sharedDirector] openGLView];
	UIGraphicsBeginImageContext(currentView.bounds.size);
	[currentView.layer renderInContext:UIGraphicsGetCurrentContext()];
	//[screenshot release];
	//screenshot = nil;
	screenshot = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	screenshotSprite = [CCSprite spriteWithCGImage:[screenshot CGImage]];
	[screenshotSprite setPosition:CGPointMake(320.0f/2,480.0f/2)];
	[self addChild:screenshotSprite];
}

-(void)removeScreenshotSprite
{
	[self unschedule:@selector(removeScreenshotSprite)];
	[self removeChild:screenshotSprite cleanup:YES];
	
}

-(void)infoButton:(id)sender
{
	[self applyScreenshotSprite];
	[self schedule:@selector(removeBoardScrollView)];
	[[CCDirector sharedDirector] replaceScene:[CCFlipXRTransition transitionWithDuration:0.5f scene:[Information sceneFromOriginalScene:[[CCDirector sharedDirector] runningScene]]]];
}

 

-(void)showOpenFeintDashboard:(id)sender
{
	//[OpenFeint launchDashboard];
}


-(void)playButton:(id)sender
{
	[[CDAudioManager sharedManager] pauseBackgroundMusic];
	[self applyScreenshotSprite];
	[self schedule:@selector(removeBoardScrollView)];
	int gameMode = PM_SCOREMODE_TIMED2MINUTE;
	
	if([freePlayButton isSelected])
	{
		gameMode = PM_SCOREMODE_FREEPLAY;
	}
	
	NSLog(@"%@ | %i",csb, csb.tag);
	CCScene* gameBoardScene = [GameBoard sceneWithMainMenu:self andGameMode:gameMode andBoardId:csb.tag];
	[[CCDirector sharedDirector] replaceScene:[CCSlideInRTransition transitionWithDuration:0.5f scene:gameBoardScene]];
	
	/*
	int boardNumber = -1;
	//for(int board = 0; board < [boardButtons count]; board++)
	//{
	//	if([[boardButtons objectAtIndex:board] isSelected])
	//	{
	//		boardNumber = board;
	//		break;
	//	}
	//}
	boardNumber = csb.tag;
	
	if(boardNumber == 0 || boardNumber == 1 || boardNumber == 2 || boardNumber == 3 || boardNumber == 4|| boardNumber == 5)
	{
		Scene* newScene = [HelloWorld scene];
		[[[newScene children] objectAtIndex:0] setAccelerometerDisabled:gravityLockEnabled];
		[[[newScene children] objectAtIndex:0] setBoardPrefix:[NSString stringWithFormat:@"%i",boardNumber,nil]];
		[[[newScene children] objectAtIndex:0] setPlaySounds:[soundButton isSelected]];
		
		if([freePlayButton isSelected])
		{
			[[[newScene children] objectAtIndex:0] setGameMode:GAME_MODE_FREEPLAY];
		}
		else if([timed2mButton isSelected])
		{
			[[[newScene children] objectAtIndex:0] setGameMode:GAME_MODE_TIMED_2MIN];
		}
		else
		{
			[[[newScene children] objectAtIndex:0] setGameMode:GAME_MODE_TIMED_5MIN];
		}
		[self applyScreenshotSprite];
		[self schedule:@selector(removeBoardScrollView)];
		[[Director sharedDirector] replaceScene:[SlideInRTransition transitionWithDuration:0.5f scene:newScene]];
	}
	*/ 
}


-(void)showShop:(id)sender
{
	[storefront show];
	//[[Airship shared] displayStoreFront];
}


-(void)helpButton:(id)sender
{
	
	[self applyScreenshotSprite];
	[self schedule:@selector(removeBoardScrollView)];
	[[CCDirector sharedDirector] pushScene:[CCFlipXTransition transitionWithDuration:0.5f scene:[Help sceneFromOriginalScene:[[CCDirector sharedDirector] runningScene]]]];
}

-(void)scoresButton:(id)sender
{
	localScores.browsingScores = YES;
	localScores.scoreMode = PM_SCOREMODE_TIMED2MINUTE;
	localScores.highlightRow = -1;
	
	[localScores show];
}

-(void)gameModeButton:(id)sender
{
	int hint  = [sender hint];
	switch(hint)
	{
		case 0:
			[freePlayButton setSelected:YES];
			[timed2mButton setSelected:NO];
			//[timed5mButton setSelected:NO];
			break;
		case 2:
			[freePlayButton setSelected:NO];
			[timed2mButton setSelected:YES];
			break;
	}
}

-(void)gameBoardButton:(id)sender
{
	int hint  = [sender hint];
	for(int board = 0; board < [boardButtons count]; board++)
	{
		[[boardButtons objectAtIndex:board] setSelected:(board == hint)];
	}
}

-(id)init
{
	if(self == [super init])
	{
		[(PinballMiniAppDelegate*)[[UIApplication sharedApplication] delegate] setMainMenu:self];
		//[[StoreFront shared] setDelegate:self];
		self.isTouchEnabled = YES;
		
		
		cocosButtons = [[NSMutableArray alloc] init];
		boardButtons = [[NSMutableArray alloc] init];
		background = [CCSprite spriteWithFile:@"Menu-Background.png"];
		[background.texture setAliasTexParameters];
		[background setPosition:CGPointMake(320.0f/2,480.0f/2)];
		[self addChild:background z:0];
		
		infoButton = [[CocosButton alloc] initWithNormalImage:@"Button-Info.png" andTarget:self andSelector:@selector(infoButton:) andParentNode:self];
		[infoButton setPosition:CGPointMake(320.0f-20.0f,480.0f-20.0f)];
		[cocosButtons addObject:infoButton];
        
        ofButton = [[CocosButton alloc] initWithNormalImage:@"Button-OpenFeintDashboard.png" andTarget:self andSelector:@selector(showOpenFeintDashboard:) andParentNode:self];
		[ofButton setPosition:CGPointMake(320.0f/2, 123.5f)];
		[ofButton setCanShrink:NO];
		[cocosButtons addObject:ofButton];
		
		shopButton = [[CocosButton alloc] initWithNormalImage:@"Button-Shop.png" andTarget:self andSelector:@selector(showShop:) andParentNode:self];
		[shopButton setPosition:CGPointMake(252.0f/2, 88.5)];
		[shopButton setCanShrink:NO];
		[cocosButtons addObject:shopButton];
		
		settingsButton = [[CocosButton alloc] initWithNormalImage:@"Button-Settings.png" andTarget:self andSelector:@selector(showSettings:) andParentNode:self];
		[settingsButton setPosition:CGPointMake(252.0f/2, 53.0f)];
		[settingsButton setCanShrink:NO];
		[cocosButtons addObject:settingsButton];
		
		scoresButton = [[CocosButton alloc] initWithNormalImage:@"Button-Scores.png" andTarget:self andSelector:@selector(scoresButton:) andParentNode:self];
		[scoresButton setPosition:CGPointMake(252.0f/2, 17.0f)];
		[scoresButton setCanShrink:NO];
		[cocosButtons addObject:scoresButton];
		
		playButton = [[CocosButton alloc] initWithNormalImage:@"Button-Play.png" andTarget:self andSelector:@selector(playButton:) andParentNode:self useAntiAlias:NO];
		[playButton setPosition:CGPointMake(239.0f+10.0f,480.0f-414.0f)];
		[playButton setCanShrink:NO];
		[cocosButtons addObject:playButton];
				
		helpButton = [[CocosButton alloc] initWithNormalImage:@"Button-Help.png" andTarget:self andSelector:@selector(helpButton:) andParentNode:self];
		[helpButton setPosition:CGPointMake(20.0f,480.0f-20.0f)];
		[cocosButtons addObject:helpButton];
		
		freePlayButton = [[CocosButton alloc] initWithNormalImage:@"GameMode-FP.png" andSelectedImage:@"GameMode-FP-Highlighted.png" andTarget:self andSelector:@selector(gameModeButton:) andParentNode:self];
		freePlayButton.hint = 0;
		[freePlayButton setCanShrink:NO];
		[freePlayButton setPosition:CGPointMake(320.0f-(157.0f/2.0f),290.0f-29.0f)];
		[cocosButtons addObject:freePlayButton];
		
		timed2mButton = [[CocosButton alloc] initWithNormalImage:@"GameMode-2m.png" andSelectedImage:@"GameMode-2m-Highlighted.png" andTarget:self andSelector:@selector(gameModeButton:) andParentNode:self];
		timed2mButton.hint = 2;
		[timed2mButton setPosition:CGPointMake(161.0f/2.0f,290.0f-29.0f)];
		[timed2mButton setSelected:YES];
		[timed2mButton setCanShrink:NO];
		[cocosButtons addObject:timed2mButton];
		
		leftArrow = [[CocosButton alloc] initWithNormalImage:@"Board-Arrow-Left.png" andTarget:nil andSelector:nil andParentNode:self];
		leftArrow.playsClickSound = NO;
		leftArrow.canShrink = NO;
		[leftArrow setPosition:CGPointMake(11.0f,187.0f)];
		[leftArrow setSelected:NO];
		[leftArrow setVisible:NO];
		[cocosButtons addObject:leftArrow];
		
		rightArrow = [[CocosButton alloc] initWithNormalImage:@"Board-Arrow-Right.png" andTarget:nil andSelector:nil andParentNode:self];
		rightArrow.playsClickSound = NO;
		rightArrow.canShrink = NO;
		[rightArrow setPosition:CGPointMake(320.0f-11.0f,187.0f)];
		[rightArrow setSelected:NO];
		[cocosButtons addObject:rightArrow];
		
		storefront = [[Storefront alloc] init];
		
		[self buildBoardScrollView];
		[[CDAudioManager sharedManager] playBackgroundMusic:@"MenuBackgroundMusic.mp3" loop:YES];
	}
	return self;
}

-(void)dealloc
{
	[background release];
	[infoButton release];
	[shopButton release];
	[settingsButton release];
	[scoresButton release];
	[playButton release];
	[helpButton release];
	[freePlayButton release];
	[timed2mButton release];
	[leftArrow release];
	[rightArrow release];
	[cocosButtons release];
	[boardButtons release];
	[settings release];
	[localScores release];
	[storefront release];
	[super dealloc];
}

- (void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	
	// Check buttons
	for(CocosButton* button in cocosButtons)
	{
		[button checkForHit:touch depressOnly:YES];
	}
}

- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	//CGPoint touchPoint = CGPointMake([touch locationInView:[touch view]].x,  480.0f - [touch locationInView:[touch view]].y);
	
	// Check buttons
	for(CocosButton* button in cocosButtons)
	{
		[button checkForHit:touch depressOnly:YES];
	}
}

- (void) buildBoardScrollView
{
	if(boardScrollView == nil)
	{
		boardScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(21, 247.0f, 278, 91)];
		boardScrollView.backgroundColor = [UIColor clearColor];
		boardScrollView.bounces = YES;
		boardScrollView.showsHorizontalScrollIndicator = NO;
		boardScrollView.canCancelContentTouches = YES;
		boardScrollView.alwaysBounceHorizontal = YES;
		boardScrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
		
		
		NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
		NSArray* installedBoards = [NSArray arrayWithContentsOfFile:[documentsPath stringByAppendingPathComponent:@"Configuration/InstalledBoards.plist"]];
		
		
		// Create content view
		float horizontalPadding = 0.0f;
		int boardCount = [installedBoards count];
		int buttonSize = 68;
		int buttonSpacing = 2;
		UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0,0,(buttonSpacing*(boardCount-1))+(boardCount*buttonSize),91)];
		
		contentView.backgroundColor = [UIColor clearColor];
		
		selectedBoardHighlight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SelectedBoardHighlight.png"]];
		
		// Add buttons
		for(int c = 0; c < boardCount; c++)
		{
			int b = boardCount-1-c;
			UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(horizontalPadding+(b*(buttonSize+buttonSpacing)),0,buttonSize,91)];
			NSString* imageFilePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Boards/%@/Menu-Thumbnail.png", [[installedBoards objectAtIndex:c] objectForKey:@"BoardId"]]];
			UIImage* buttonImage = [[UIImage imageWithContentsOfFile:imageFilePath] retain];
			[button setImage:buttonImage forState:UIControlStateNormal];
			[button addTarget:self action:@selector(testButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
			button.tag = [(NSString*)[[installedBoards objectAtIndex:c] objectForKey:@"BoardId"] intValue];
			[contentView addSubview:button];
			if(b == 0) {
				[button setSelected:YES];
				csb = button;
				[button addSubview:selectedBoardHighlight];
			}
			[buttonImage release];
			[button release];
		}
		
		[boardScrollView addSubview:contentView];
		[boardScrollView setContentSize:contentView.frame.size];
		[contentView release];
		boardScrollView.hidden = YES;
		[[[CCDirector sharedDirector] openGLView] addSubview:boardScrollView];
	}
}

- (void) reloadBoardDisplay
{
	
	// TODO: Place something over the board area to show it is reloading
	//UIView* overlayView = [[UIView alloc] initWithFrame:CGRectMake(21, 247.0f, 278, 91)];
	//overlayView.alpha = 1.0;
	//overlayView.backgroundColor = [UIColor redColor];
	//UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(21, 247.0f, 278, 91)];
	//[[[CCDirector sharedDirector] openGLView] addSubview:overlayView];
	//[[[CCDirector sharedDirector] openGLView] bringSubviewToFront:overlayView];
	//[[[CCDirector sharedDirector] openGLView] addSubview:activityView];
	//[[[CCDirector sharedDirector] openGLView] bringSubviewToFront:activityView];
	
	//[NSThread sleepUntilDate:[[NSDate date] addTimeInterval:5.0]];
	
	NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	NSArray* installedBoards = [NSArray arrayWithContentsOfFile:[documentsPath stringByAppendingPathComponent:@"Configuration/InstalledBoards.plist"]];
	
	int tag = -1;
	if(csb != nil)
	{
		tag = [csb tag];
	}
	
	
	// Create content view
	float horizontalPadding = 0.0f;
	int boardCount = [installedBoards count];
	int buttonSize = 68;
	int buttonSpacing = 2;
	[[boardScrollView viewWithTag:1001] removeFromSuperview];
	[[boardScrollView viewWithTag:1002] removeFromSuperview];
	UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0,0,(buttonSpacing*(boardCount-1))+(boardCount*buttonSize),91)];
	
	contentView.backgroundColor = [UIColor clearColor];
	contentView.tag = 1001;
	
	selectedBoardHighlight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SelectedBoardHighlight.png"]];
	selectedBoardHighlight.tag = 1002;
	// Add buttons
	for(int c = 0; c < boardCount; c++)
	{
		int b = boardCount-1-c;
		UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(horizontalPadding+(b*(buttonSize+buttonSpacing)),0,buttonSize,91)];
		NSString* imageFilePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Boards/%@/Menu-Thumbnail.png", [[installedBoards objectAtIndex:c] objectForKey:@"BoardId"]]];
		UIImage* buttonImage = [[UIImage imageWithContentsOfFile:imageFilePath] retain];
		[button setImage:buttonImage forState:UIControlStateNormal];
		[button addTarget:self action:@selector(testButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
		button.tag = [(NSString*)[[installedBoards objectAtIndex:c] objectForKey:@"BoardId"] intValue];
		[contentView addSubview:button];
		if(button.tag == tag) {
			[button setSelected:YES];
			csb = button;
			[button addSubview:selectedBoardHighlight];
		}
		[buttonImage release];
		[button release];
	}
	
	[boardScrollView addSubview:contentView];
	[boardScrollView setContentSize:contentView.frame.size];
	[contentView release];
	//[activityView removeFromSuperview];
	//[activityView release];
	//[overlayView removeFromSuperview];
	//[overlayView release];
}

- (void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	
	// Check buttons
	// HACK: CocosButton really needs a way to say the touch area is smaller than the button image
	// we have overlapping buttons here, so I'm just giving priority to the play button...this should
	// not be this way in the final code though.
	if(![playButton checkForHit:touch])
	{
		for(CocosButton* button in cocosButtons)
		{
			if(button != playButton)
			{
				[button checkForHit:touch];
			}
		}
		
	}
}

-(void)onEnterTransitionDidFinish
{

	boardScrollView.hidden = NO;
	[self schedule:@selector(removeScreenshotSprite)];
	settings = [[Settings alloc] initWithTarget:self andSelector:@selector(settingsDidClose)];
	localScores = [[LocalScores alloc] init];
	[self schedule: @selector(step:)];
	
}

-(void) step: (ccTime) delta
{
	if(boardScrollView.contentOffset.x < 25.0f)
	{
		[leftArrow setVisible:NO];
	}
	else {
		[leftArrow setVisible:YES];
	}
	
	if(boardScrollView.contentOffset.x > boardScrollView.contentSize.width-25.0f-boardScrollView.frame.size.width)
	{
		[rightArrow setVisible:NO];
	}
	else {
		[rightArrow setVisible:YES];
	}
}



-(void)testButtonSelected:(id)selectedButton
{
	[csb setSelected:NO];
	[selectedBoardHighlight removeFromSuperview];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"PLAY_SOUNDS"]) [self playButtonClick];
	[selectedButton addSubview:selectedBoardHighlight];
	csb = selectedButton;
	
	
}

- (void) playButtonClick
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BUTTONCLICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
}

// Processed

-(void)showSettings:(id)sender
{
	[infoButton setVisible:NO];
	[helpButton setVisible:NO];
	
	[settings show];	
}

- (void) settingsDidClose
{
	[infoButton setVisible:YES];
	[helpButton setVisible:YES];
}

-(void)removeBoardScrollView
{
	[self unschedule:@selector(removeBoardScrollView)];
	boardScrollView.hidden = YES;
	//[boardScrollView removeFromSuperview];
}

@end
