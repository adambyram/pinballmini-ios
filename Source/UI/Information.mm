//
//  Info.mm
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Information.h"


@implementation Information

@synthesize originalScene;

+(id)sceneFromOriginalScene:(CCScene*)original
{
	// 'scene' is an autorelease object.
	//Scene *scene = [ShakeEnabledScene node];
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	CCLayer *layer = [Information node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	Information* info = (Information*)layer;
	info.originalScene = original;
	
	// return the scene
	return scene;
}

-(void)onEnter
{
	[super onEnter];
	self.isTouchEnabled = YES;
	
	CCSprite* background = [CCSprite spriteWithFile:@"Info-Page.png"];
	[background setPosition:CGPointMake(320.0f/2,480.0f/2)];
	[self addChild:background];
	
	backToMenu = [[CocosButton alloc] initWithNormalImage:@"Button_Menu.png" andTarget:self andSelector:@selector(backToOriginalScene:) andParentNode:self];
	[backToMenu setPosition:CGPointMake(320.0f-20.0f,480.0f-20.0f)];
	
	CCLabel* versionLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"V%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],nil] fontName:@"Arial" fontSize:10.0f];
	[versionLabel setPosition:CGPointMake(303.0f,480.0f-179.0f)];
	[self addChild:versionLabel];
}

-(void)backToOriginalScene:(id)sender
{
	[[CCDirector sharedDirector] replaceScene:[CCFlipXTransition transitionWithDuration:0.5f scene:self.originalScene]];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[backToMenu checkForHit:[touches anyObject] depressOnly:YES];
}
- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[backToMenu checkForHit:[touches anyObject] depressOnly:YES];
}
- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[backToMenu checkForHit:[touches anyObject]];
}

@end