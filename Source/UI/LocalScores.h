//
//  LocalScores.h
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScoreView.h"
#import "NewLocalScore.h"


@interface LocalScores : NSObject {
	ScoreView* freePlayScoreView;
	ScoreView* timed2MinuteScoreView;
	ScoreView* scoreView;
	UIButton* showFreePlayScoresButton;
	UIButton* showTimed2MinuteScoresButton;
	UIButton* doneButtonFreePlay;
	UIButton* doneButtonTimed2Minute;
	BOOL browsingScores;
	int scoreMode;
	int highlightRow;
	UIView* entryScreen;
	NewLocalScore* newLocalScoreScreen;
	UIView* blackBackground;
}

@property (assign, nonatomic) int scoreMode;
@property (assign, nonatomic) BOOL browsingScores;
@property (assign, nonatomic) int highlightRow;

- (void) show;
- (void) submitScore:(int)score forBoard:(NSString*)boardId andGameMode:(int)gameMode;
- (void) fadeInFromNewLocalScoreScreen;
- (BOOL) scoreIsHighScore:(int)score forBoard:(NSString*)boardId andGameMode:(int)gameMode;

@end
