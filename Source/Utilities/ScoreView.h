//
//  ScoreView.h
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScoreView : UIView {
	UIImage* freePlayBackground;
	UIImage* timed2MinuteBackground;
	UIImage* highlightDots;
	UIImage* normalDots;
	UILabel* textLabel;
	int scoreViewMode;
	int highlightRow;
	NSArray* scoreArray;
}


@property (assign, nonatomic) int scoreViewMode;
@property (assign, nonatomic) int highlightRow;

- (void) drawScoreLine:(int)scoreNumber WithName:(NSString*)name AndScore:(NSString*)score;
- (NSString*) highScoreFilePath:(int)gm;
- (void) loadScoreArray;

@end
