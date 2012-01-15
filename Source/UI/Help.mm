//
//  Help.mm
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Help.h"

@implementation Help

@synthesize originalScene;

+(id)sceneFromOriginalScene:(CCScene*)original
{
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	CCLayer *layer = [Help node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	Help* help = (Help*)layer;
	help.originalScene = original;
	
	// return the scene
	return scene;
}

-(void)onEnter
{
	[super onEnter];
	self.isTouchEnabled = YES;
	
	CCSprite* background = [CCSprite spriteWithFile:@"Help-Screen-1.png"];
	[background setPosition:CGPointMake(320.0f/2,480.0f/2)];
	[self addChild:background];
	
	backToMenu = [[CocosButton alloc] initWithNormalImage:@"Help-MainMenu.png" andTarget:self andSelector:@selector(backToOriginalScene:) andParentNode:self];
	[backToMenu setPosition:CGPointMake(320.0f/2.0f,35.0f)];	
}

-(void)backToOriginalScene:(id)sender
{
	[[CCDirector sharedDirector] replaceScene:[CCFlipXRTransition transitionWithDuration:0.5f scene:self.originalScene]];
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
