//
//  LocalScores.m
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LocalScores.h"
#import "PinballMiniConstants.h"
#import "cocos2d.h"
#import "NewLocalScore.h"
#import "CocosDenshion.h"
#import "CDAudioManager.h"

#define OFFSCREEN_BOTTOM_POSITION CGRectMake(0.0f, 480.0f, 320, 480.0f)
#define OFFSCREEN_LEFT_POSITION CGRectMake(-320.0f, 0.0f, 320.0f, 480.0f)
#define OFFSCREEN_RIGHT_POSITION CGRectMake(320.0f, 0.0f, 320.0f, 480.0f)

#define ONSCREEN_POSITION CGRectMake(0.0f,0.0f,320.0f,480.0f)

#define BUTTON_LEFT_POSITION CGRectMake(0.0f,430.0f,161.0f,33.0f)
#define BUTTON_RIGHT_POSITION CGRectMake(163.0f,430.0f,157.0f,33.0f)
#define BUTTON_CENTER_POSITION CGRectMake(81.0f,430.0f,157.0f,33.0f)

@implementation LocalScores

@synthesize browsingScores;
@synthesize scoreMode;
@synthesize highlightRow;

- (id) init
{
	if(self = [super init])
	{
		
		blackBackground = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,480)];
		blackBackground.backgroundColor = [UIColor blackColor];
		blackBackground.hidden = YES;
		[[[[CCDirector sharedDirector] openGLView] window] addSubview:blackBackground];
		
		freePlayScoreView = [[ScoreView alloc] init];
		freePlayScoreView.highlightRow = -1;
		freePlayScoreView.scoreViewMode = PM_SCOREMODE_FREEPLAY;
		
		timed2MinuteScoreView = [[ScoreView alloc] init];
		timed2MinuteScoreView.highlightRow = -1;
		timed2MinuteScoreView.scoreViewMode = PM_SCOREMODE_TIMED2MINUTE;
		
		showFreePlayScoresButton = [[UIButton alloc] init];
		showTimed2MinuteScoresButton = [[UIButton alloc] init];
		doneButtonFreePlay = [[UIButton	alloc] init];
		doneButtonTimed2Minute = [[UIButton alloc] init];
		
		showFreePlayScoresButton = [[UIButton alloc] initWithFrame:BUTTON_LEFT_POSITION];
		[showFreePlayScoresButton setImage:[UIImage imageNamed:@"HighScore-FreePlayScores.png"] forState:UIControlStateNormal];
		[showFreePlayScoresButton addTarget:self action:@selector(switchToFreePlay:) forControlEvents:UIControlEventTouchUpInside];
		
		showTimed2MinuteScoresButton = [[UIButton alloc] initWithFrame:BUTTON_LEFT_POSITION];
		[showTimed2MinuteScoresButton setImage:[UIImage imageNamed:@"HighScore-2MinScores.png"] forState:UIControlStateNormal];
		[showTimed2MinuteScoresButton addTarget:self action:@selector(switchToTimed2Minute:) forControlEvents:UIControlEventTouchUpInside];

		doneButtonFreePlay = [[UIButton alloc] initWithFrame:BUTTON_RIGHT_POSITION];
		[doneButtonFreePlay setImage:[UIImage imageNamed:@"HighScore-MainMenu.png"] forState:UIControlStateNormal];
		[doneButtonFreePlay addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
		
		doneButtonTimed2Minute = [[UIButton alloc] initWithFrame:BUTTON_RIGHT_POSITION];
		[doneButtonTimed2Minute setImage:[UIImage imageNamed:@"HighScore-MainMenu.png"] forState:UIControlStateNormal];
		[doneButtonTimed2Minute addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
		
		showTimed2MinuteScoresButton.frame = BUTTON_LEFT_POSITION;
		[freePlayScoreView addSubview:showTimed2MinuteScoresButton];
		
		doneButtonTimed2Minute.frame = BUTTON_RIGHT_POSITION;
		[freePlayScoreView addSubview:doneButtonTimed2Minute];
		
		showFreePlayScoresButton.frame = BUTTON_LEFT_POSITION;
		[timed2MinuteScoreView addSubview:showFreePlayScoresButton];
		
		doneButtonFreePlay.frame = BUTTON_RIGHT_POSITION;
		[timed2MinuteScoreView addSubview:doneButtonFreePlay];
		
		newLocalScoreScreen = [[NewLocalScore alloc] initWithLocalScoreScreen:self];
		

		
	} 
	return self;
}

- (void)switchToFreePlay:(id)sender
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BUTTONCLICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];

	scoreView = freePlayScoreView;
	[scoreView loadScoreArray];
	freePlayScoreView.frame = OFFSCREEN_RIGHT_POSITION;
	[UIView beginAnimations:@"slideFreePlayInFromRight" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:SLIDE_SPEED];
	freePlayScoreView.frame = ONSCREEN_POSITION;
	timed2MinuteScoreView.frame = OFFSCREEN_LEFT_POSITION;
	[UIView commitAnimations];
}

- (void)switchToTimed2Minute:(id)sender
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BUTTONCLICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];

	scoreView = timed2MinuteScoreView;
	[scoreView loadScoreArray];
	timed2MinuteScoreView.frame = OFFSCREEN_LEFT_POSITION;
	[UIView beginAnimations:@"slideFreePlayInFromLeft" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:SLIDE_SPEED];
	timed2MinuteScoreView.frame = ONSCREEN_POSITION;
	freePlayScoreView.frame = OFFSCREEN_RIGHT_POSITION;
	[UIView commitAnimations];
}

- (void) fadeInFromNewLocalScoreScreen
{
	blackBackground.hidden = NO;
	[showTimed2MinuteScoresButton setHidden:YES];
	[showFreePlayScoresButton setHidden:YES];
	doneButtonFreePlay.frame = BUTTON_CENTER_POSITION;
	doneButtonTimed2Minute.frame = BUTTON_CENTER_POSITION;
	browsingScores = NO;
	if(scoreMode == PM_SCOREMODE_FREEPLAY)
	{
		scoreView = freePlayScoreView;
	}
	else
	{
		scoreView = timed2MinuteScoreView;
	}
	entryScreen = [newLocalScoreScreen view];
	scoreView.alpha = 0.0f;
	scoreView.frame = ONSCREEN_POSITION;
	scoreView.highlightRow = self.highlightRow;
	[scoreView loadScoreArray];
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:scoreView]; 
	[UIView beginAnimations:@"fadeOutNewLocalScore" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDuration:FADE_SPEED];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(releaseEntryScreen)];
	entryScreen.alpha = 0.0f;
	scoreView.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)releaseEntryScreen
{
	blackBackground.hidden = YES;
	[entryScreen removeFromSuperview];
}

- (NSString*) highScoreFilePath:(int)gm
{
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"Scores/%iHighScoreList.plist",gm,nil]];
}

- (BOOL) scoreIsHighScore:(int)score forBoard:(NSString*)boardId andGameMode:(int)gameMode
{
	NSMutableArray* scoreArray = [NSMutableArray arrayWithContentsOfFile:[self highScoreFilePath:gameMode]];
	int insertAtPosition = -1;
	for(int index = 0; index < [scoreArray count]; index++)
	{
		int oldHighScore = [[[scoreArray objectAtIndex:index] objectForKey:@"Score"] intValue];
		if(score > oldHighScore)
		{
			insertAtPosition = index;
			break;
		}
	}
	
	if(score > 0 && ((insertAtPosition != -1 && insertAtPosition < 15) || (insertAtPosition == -1 && [scoreArray count] < 15)))
	{
		return YES;
	}
	else {
		return NO;
	}

}

- (void) submitScore:(int)score forBoard:(NSString*)boardId andGameMode:(int)gameMode
{
	// TODO - Submit score to OF
	
	// TODO - Check to see if this *is* a high score
	//if([self scoreIsHighScore:score forBoard:boardId andGameMode:gameMode])
	//{
		// We have a new high score - record it
		// TODO - Save score (if high score)
		self.scoreMode = gameMode;
		self.browsingScores = NO;
		newLocalScoreScreen.score = score;
		newLocalScoreScreen.gameMode = gameMode;
		newLocalScoreScreen.boardId = boardId;
		[newLocalScoreScreen show];
	//}
}

- (void) show
{

	[showTimed2MinuteScoresButton setHidden:NO];
	[showFreePlayScoresButton setHidden:NO];
	doneButtonFreePlay.frame = BUTTON_RIGHT_POSITION;
	doneButtonTimed2Minute.frame = BUTTON_RIGHT_POSITION;
	browsingScores = YES;
	scoreView = nil;
	highlightRow = -1;
	freePlayScoreView.highlightRow = self.highlightRow;
	timed2MinuteScoreView.highlightRow = self.highlightRow;
	[freePlayScoreView setNeedsDisplay];
	[timed2MinuteScoreView setNeedsDisplay];
			
		if(scoreMode == PM_SCOREMODE_FREEPLAY)
		{
			scoreView = freePlayScoreView;
		}
		else
		{
			scoreView = timed2MinuteScoreView;
		}
	[scoreView loadScoreArray];
				
		// We'll get here from the main menu, so slide up
		scoreView.frame = OFFSCREEN_BOTTOM_POSITION;
		[[[[CCDirector sharedDirector] openGLView] window] addSubview:scoreView];
		if(scoreView == freePlayScoreView)
		{
			timed2MinuteScoreView.frame = OFFSCREEN_LEFT_POSITION;
			[[[[CCDirector sharedDirector] openGLView] window] addSubview:timed2MinuteScoreView];
		}
		else
		{		
			freePlayScoreView.frame = OFFSCREEN_RIGHT_POSITION;
			[[[[CCDirector sharedDirector] openGLView] window] addSubview:freePlayScoreView];
		}

		[UIView beginAnimations:@"localScoresSlideUp" context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDuration:SLIDE_SPEED];
		scoreView.frame = ONSCREEN_POSITION;
		[UIView commitAnimations];
	
}

- (void) hide
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BUTTONCLICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];

	if(browsingScores)
	{
		// We got here from the main menu, so slide down
		scoreView.frame = ONSCREEN_POSITION;
		//[[[[CCDirector sharedDirector] openGLView] window] addSubview:scoreView];
		[UIView beginAnimations:@"localScoresSlideDown" context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		[UIView setAnimationDuration:SLIDE_SPEED];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(removeScoreViewFromView)];
		scoreView.frame = OFFSCREEN_BOTTOM_POSITION;
		[UIView commitAnimations];	
	}
	else
	{
		// We got here when we're showing a specific high score
		scoreView.frame = ONSCREEN_POSITION;
		[UIView beginAnimations:@"localScoresSlideDown" context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		[UIView setAnimationDuration:SLIDE_SPEED];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(removeScoreViewFromView)];
		scoreView.frame = OFFSCREEN_BOTTOM_POSITION;
		[UIView commitAnimations];	
	}
}

- (void) removeScoreViewFromView
{
	[scoreView removeFromSuperview];
}

- (void) dealloc
{
	[showFreePlayScoresButton release];
	[showTimed2MinuteScoresButton release];
	[doneButtonTimed2Minute release];
	[doneButtonFreePlay release];
	[freePlayScoreView release];
	[timed2MinuteScoreView release];
	[super dealloc];
}

@end
