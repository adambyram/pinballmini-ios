//
//  MainMenu.h
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CocosButton.h"
#import "Settings.h"
#import "LocalScores.h"
#import "Storefront.h"

@interface MainMenu : CCLayer {
	BOOL accelerometerLocked;
	CCSprite* background;
	
	CocosButton* infoButton;
	CocosButton* ofButton;
	CocosButton* shopButton;
	CocosButton* settingsButton;
	CocosButton* helpButton;
	CocosButton* scoresButton;
	CocosButton* playButton;
	
	CocosButton* leftArrow;
	CocosButton* rightArrow;
	
	CocosButton* freePlayButton;
	CocosButton* timed2mButton;
	
	NSMutableArray* cocosButtons;
	NSMutableArray* boardButtons;
	
	UIScrollView* boardScrollView;
	UIImageView* selectedBoardHighlight;
	UIImage* screenshot;
	CCSprite* screenshotSprite;
	Settings* settings;
	LocalScores* localScores;
	CCScene* internalScene;
	Storefront* storefront;
}

+(id) scene;
- (void) playButtonClick;
- (void) buildBoardScrollView;
- (void) reloadBoardDisplay;

@property (retain, nonatomic) CCScene* internalScene;
@property (retain, nonatomic) LocalScores* localScores;

@end
