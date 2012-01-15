//
//  NewLocalScore.mm
//  PinballMini
//
//  Created by Adam Byram on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NewLocalScore.h"
#import "PinballMiniConstants.h"
#import "LocalScores.h"
#import "cocos2d.h"

@implementation NewLocalScore

@synthesize score;
@synthesize gameMode;
@synthesize boardId;

- (id)initWithLocalScoreScreen:(LocalScores*)localScores;
{
	if(self = [super init])
	{
		localScoreScreen = localScores;
		backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HighScore-Input-Background.png"]];
		backgroundImageView.userInteractionEnabled = YES;
		
		scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(215.0f,  150.0f-7.0f, 72.0f, 20.0f)];
		scoreLabel.font = [UIFont fontWithName:@"Arial" size:15.0f];
		scoreLabel.textAlignment = UITextAlignmentRight;
		scoreLabel.textColor = [UIColor whiteColor];
		scoreLabel.backgroundColor = [UIColor clearColor];
		[backgroundImageView addSubview:scoreLabel];
		
		nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(33.0f,  150.0f-7.0f, 180.0f, 20.0f)];
		nameTextField.textAlignment = UITextAlignmentLeft;
		nameTextField.text = @"";
		nameTextField.textColor = [UIColor whiteColor];
		nameTextField.font = [UIFont fontWithName:@"Arial" size:15.0f];
		nameTextField.returnKeyType = UIReturnKeyDone;
		[nameTextField setDelegate:self];
		[backgroundImageView addSubview:nameTextField];
		
	}
	return self;
}

- (void)showKeyboard
{
	[nameTextField becomeFirstResponder];
}
- (NSString*) highScoreFilePath:(int)gm
{
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"Scores/%iHighScoreList.plist",gm,nil]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[nameTextField resignFirstResponder];
	int highScorePosition = -1;
	NSMutableArray* scoreArray = [NSMutableArray arrayWithContentsOfFile:[self highScoreFilePath:gameMode]];
	if(scoreArray == nil) scoreArray = [[[NSMutableArray alloc] init] autorelease];
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
	
	NSMutableDictionary* scoreDetail = [[NSMutableDictionary alloc] init];
	[scoreDetail setObject:nameTextField.text forKey:@"Name"];
	[scoreDetail setObject:[NSString stringWithFormat:@"%04i",boardId,nil] forKey:@"Board"];
	[scoreDetail setObject:[NSString stringWithFormat:@"%i", score,nil] forKey:@"Score"];
	[scoreDetail setObject:[NSString stringWithFormat:@"%i", gameMode,nil] forKey:@"GameMode"];
	
	if(insertAtPosition == -1)
	{
		// We never found a position - so insert at the end
		[scoreArray insertObject:scoreDetail atIndex:[scoreArray count]];
		highScorePosition = [scoreArray count];
	}
	else
	{
		[scoreArray insertObject:scoreDetail atIndex:insertAtPosition];
		if([scoreArray count] > 15)
		{
			[scoreArray removeLastObject];
		}
		highScorePosition = insertAtPosition+1;
	}
	
	[scoreDetail release];
	
	[scoreArray writeToFile:[self highScoreFilePath:gameMode] atomically:YES];
	
	localScoreScreen.highlightRow = highScorePosition;
	[self showHighScoreScreen];
	return NO;
}

- (void)show
{
	scoreLabel.text = [NSString stringWithFormat:@"%i",score,nil];
	backgroundImageView.alpha = 0.0f;
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:backgroundImageView];
	[UIView beginAnimations:@"fadeInNewLocalScore" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:FADE_SPEED];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(showKeyboard)];
	backgroundImageView.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)showHighScoreScreen
{
	[localScoreScreen fadeInFromNewLocalScoreScreen];
}

- (void)removeFromView
{
	[backgroundImageView removeFromSuperview];
}

- (UIView*) view
{
	return backgroundImageView;
}

- (void)dealloc
{
	[nameTextField release];
	[scoreLabel release];
	[backgroundImageView release];
	[super dealloc];
}

@end
