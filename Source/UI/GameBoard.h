//
//  GameBoard.h
//  PinballMini
//
//  Created by Adam Byram on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CocosButton.h"
#import "MainMenu.h"
#import "chipmunk.h"

#import <AudioToolbox/AudioToolbox.h>

@interface GameBoard : CCLayer <NSXMLParserDelegate> {
	cpSpace* space;
	cpBody * body;
	cpBody *staticBody;
	cpBody* ballBody;
	
	CCSprite* pivotOverlay;
	CCSprite* lever;
	CCSprite* hammer;
	CCSprite* thumbButton;
	CCSprite* thumbButtonOverlay;
	
	cpBody* springHolder;
	cpBody* hammerHead;
	cpShape* hh1;
	cpShape* hh2;
	cpShape* hh3;
	cpShape* hh4;
	float leverAngle;
	float distance;
	float forceToApply;
	
	SystemSoundID scoreSound;
	SystemSoundID ballHit1Sound;
	SystemSoundID ballHit2Sound;
	SystemSoundID ballHit3Sound;
	SystemSoundID ballHit4Sound;
	SystemSoundID ballToBallClick;
	
	
	BOOL applyHammerHeadForce;
	BOOL applyHammerHeadCollision;
	UIAcceleration* lastAcceleration;
	BOOL buttonTouchActive;
	BOOL histeresisExcited;
	CCLabel* scoreLabel;
	BOOL loadingScoring;
	BOOL loadingBoundaries;
	BOOL loadingActiveObjects;
	BOOL loadingSliderActiveObject;
	BOOL loadingSpinnerActiveObject;
	//BOOL ballsNeedReset;
	
	CCSprite* pullAndReleaseSticker;
	CCSprite* shakeSticker;
	
	CocosButton* pauseResumeButton;
	CocosButton* mainMenuButton;
	BOOL paused;

	float timeRemaining;
	CCLabel* timerLabel;
	BOOL gameOver;
	BOOL scoreIncreaseIsActive;
	
	BOOL playSounds;
	BOOL needToShowShake;
	CCAction* shakeStickerAction;
	CCAction* hammerStickerAction;
	NSLock* ballAnimationLock;
	NSMutableArray* activeSliderObjects;
	NSMutableDictionary* lastBallHitSound;
	
	// SAFE
	MainMenu* mainMenu;
	int boardId;
	int gameMode;
}

+(id) sceneWithMainMenu:(MainMenu*)mm andGameMode:(int)gm andBoardId:(int)bid;

@property (retain, nonatomic) MainMenu* mainMenu;
@property (assign, nonatomic) int boardId;
@property (assign, nonatomic) int gameMode;

-(void)step:(ccTime)dt;

@property BOOL applyHammerHeadForce;
@property BOOL applyHammerHeadCollision;
@property float forceToApply;


@property BOOL playSounds;
@property (retain,nonatomic) UIAcceleration* lastAcceleration;
@property BOOL histeresisExcited;
-(void)moveHammerHead:(float)yOffset;
-(void)addBallAt:(CGPoint)point;
-(void)endShakeAnimation;
- (NSString*)fullPathForResource:(NSString*)relativeResourcePath;
- (void)slideMenuBack;
-(void)playBallHitSound:(float)force forBall:(CCSprite*)ballSprite;
- (void)showMenu:(id)sender;
- (void)playDing:(id)sender;

@end
