//
//  ScoreView.mm
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScoreView.h"
#import "PinballMiniConstants.h"

const int scoreRowOffset = 100.0f;
const int scoreRowSpacing = 21.0f;
const int startingXOffset = 32.0f;
const int elementSpacing = 2.0f;

@implementation ScoreView

- (id) init
{
	if(self = [super init])
	{
		self.frame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f);
		freePlayBackground = [[UIImage imageNamed:@"HighScore-Background-FreePlay.png"] retain];
		timed2MinuteBackground = [[UIImage imageNamed:@"HighScore-Background-2Minute.png"] retain];
		highlightDots = [[UIImage imageNamed:@"HighScore-Dashed-Yellow.png"] retain];
		normalDots = [[UIImage imageNamed:@"HighScore-Dashed-Grey.png"] retain];
		textLabel = [[UILabel alloc] init];
		//scoreArray = [[NSArray alloc] init];
	}
	return self;
}

- (void) loadScoreArray
{
	[scoreArray release];
	scoreArray = [[NSMutableArray arrayWithContentsOfFile:[self highScoreFilePath:scoreViewMode]] retain];
	[self setNeedsDisplay];
}

- (NSString*) highScoreFilePath:(int)gm
{
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"Scores/%iHighScoreList.plist",gm,nil]];
}

- (void)drawRect:(CGRect)rect
{
	if(scoreViewMode == PM_SCOREMODE_FREEPLAY)
	{
		[freePlayBackground drawInRect:rect];
	}
	else if(scoreViewMode == PM_SCOREMODE_TIMED2MINUTE)
	{
		[timed2MinuteBackground drawInRect:rect];
	}
	
	int scoreNumber = 1;
	
	for(int score = 0; score < [scoreArray count]; score++)
	{
		
		[self drawScoreLine:score+1 WithName:(NSString*)[[scoreArray objectAtIndex:score] objectForKey:@"Name"] AndScore:(NSString*)[[scoreArray objectAtIndex:score] objectForKey:@"Score"]];
		scoreNumber++;
	}
	
	for(int blankScore = scoreNumber-1; blankScore < 15; blankScore++)
	{
		[self drawScoreLine:blankScore+1 WithName:@"" AndScore:@""];
		scoreNumber++;
	}
}

- (void) drawScoreLine:(int)scoreNumber WithName:(NSString*)name AndScore:(NSString*)score
{
	int scoreIndex = scoreNumber-1;  // This isn't really needed, but saves a math op later
	textLabel.frame = CGRectMake(startingXOffset, scoreRowOffset+(scoreIndex*scoreRowSpacing), 24.0f, 20.0f);
	textLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:15.0f];
	textLabel.textAlignment = UITextAlignmentLeft;
	textLabel.text = [NSString stringWithFormat:@"%i.",scoreNumber,nil];
	textLabel.textColor = [UIColor whiteColor];
	[textLabel drawTextInRect:textLabel.frame];
	
	textLabel.frame = CGRectMake(textLabel.frame.origin.x + textLabel.frame.size.width+elementSpacing, scoreRowOffset+(scoreIndex*scoreRowSpacing), 170.0f, 20.0f);
	textLabel.font = [UIFont fontWithName:@"Arial" size:15.0f];
	textLabel.textAlignment = UITextAlignmentLeft;
	textLabel.text = name;
	textLabel.textColor = [UIColor whiteColor];
	[textLabel drawTextInRect:textLabel.frame];
	
	textLabel.frame = CGRectMake(textLabel.frame.origin.x + textLabel.frame.size.width+elementSpacing, scoreRowOffset+(scoreIndex*scoreRowSpacing), 60.0f, 20.0f);
	textLabel.font = [UIFont fontWithName:@"Arial" size:15.0f];
	textLabel.textAlignment = UITextAlignmentRight;
	textLabel.text = score;
	textLabel.textColor = [UIColor whiteColor];
	[textLabel drawTextInRect:textLabel.frame];
	
	CGRect dotFrame = CGRectMake(31.0f,scoreRowOffset+(scoreIndex*scoreRowSpacing) + 18.0f,259.0f,3.0f);
	if(highlightRow == scoreNumber)
	{
		[highlightDots drawInRect:dotFrame];
	}
	else
	{
		[normalDots drawInRect:dotFrame];
	}
}

- (void) dealloc
{
	[scoreArray release];
	[highlightDots release];
	[normalDots release];
	[textLabel release];
	[freePlayBackground release];
	[timed2MinuteBackground release];
	[super dealloc];
}

@synthesize scoreViewMode;
@synthesize highlightRow;

@end
