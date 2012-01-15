//
//  NewLocalScore.h
//  PinballMini
//
//  Created by Adam Byram on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LocalScores;

@interface NewLocalScore : NSObject <UITextFieldDelegate> {
	UIImageView* backgroundImageView;
	UITextField* nameTextField;
	UILabel* scoreLabel;
	int score;
	NSString* boardId;
	int gameMode;
	LocalScores* localScoreScreen;
}

@property (assign, nonatomic) int score;
@property (assign, nonatomic) int gameMode;
@property (copy, nonatomic) NSString* boardId;

- (id)initWithLocalScoreScreen:(LocalScores*)localScores;
- (void) show;
- (UIView*) view;
- (void)showHighScoreScreen;

@end
