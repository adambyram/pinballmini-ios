//
//  CocosButton.mm
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CocosButton.h"
#import "CocosDenshion.h"
#import "CDAudioManager.h"
#import "PinballMiniConstants.h"

@implementation CocosButton

@synthesize hint;
@synthesize playsClickSound;
@synthesize canShrink;

-(id)initWithNormalImage:(NSString*)normalImage andTarget:(id)target andSelector:(SEL)selector andParentNode:(CCNode*)node
{
	return [self initWithNormalImage:normalImage andSelectedImage:nil andTarget:target andSelector:selector andParentNode:node useAntiAlias:NO];
}

-(id)initWithNormalImage:(NSString*)normalImage andTarget:(id)target andSelector:(SEL)selector andParentNode:(CCNode*)node useAntiAlias:(BOOL)antiAlias
{
	return [self initWithNormalImage:normalImage andSelectedImage:nil andTarget:target andSelector:selector andParentNode:node useAntiAlias:antiAlias];
}

-(id)initWithNormalImage:(NSString*)normalImage andSelectedImage:(NSString*)selectedImage andTarget:(id)target andSelector:(SEL)selector andParentNode:(CCNode*)node
{
	return [self initWithNormalImage:normalImage andSelectedImage:selectedImage andTarget:target andSelector:selector andParentNode:node useAntiAlias:NO];
}

-(id)initWithNormalImage:(NSString*)normalImage andSelectedImage:(NSString*)selectedImage andTarget:(id)target andSelector:(SEL)selector andParentNode:(CCNode*)node useAntiAlias:(BOOL)antiAlias
{
	if(self == [super init])
	{
		normalStateSprite = [CCSprite spriteWithFile:normalImage];
		if(!antiAlias)[normalStateSprite.texture setAliasTexParameters];
		targetObject = target;
		targetSelector = selector;
		canShrink = YES;
		[normalStateSprite setVisible:NO];
		[node addChild:normalStateSprite z:10];
		
		playsClickSound = YES;
		
		//NSURL *filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"button_click" ofType:@"wav"] isDirectory:NO];
		//NSURL *filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ClickSound5" ofType:@"wav"] isDirectory:NO];
		
		//AudioServicesCreateSystemSoundID((CFURLRef)filePath, &buttonClick);
		
		if(selectedImage != nil)
		{
			selectedStateSprite = [CCSprite spriteWithFile:selectedImage];
			if(!antiAlias)[selectedStateSprite.texture setAliasTexParameters];
			[selectedStateSprite setVisible:NO];
			[node addChild:selectedStateSprite z:10];
		}
		else
		{
			selectedStateSprite = nil;
		}
		selectedState = NO;
	}
	return self;
}

-(void)dealloc
{
	//[normalStateSprite release];
	//[selectedStateSprite release];
	[super dealloc];
}

-(BOOL)checkForHit:(UITouch*)touch depressOnly:(BOOL)depress
{
	// If you can't see the button, then you can't click it. Period.
	if(![self isVisible]) return NO;
	
	// Since we're in OpenGL we have to modify the Y here
	CGPoint touchPoint = CGPointMake([touch locationInView:[touch view]].x,  480.0f - [touch locationInView:[touch view]].y);
	float x = [normalStateSprite position].x;
	float y = [normalStateSprite position].y;
	float h = [normalStateSprite contentSize].height;
	float w = [normalStateSprite contentSize].width;
	CGRect buttonRect = CGRectMake(x-w/2,y-h/2,w,h);
	
	if(CGRectContainsPoint(buttonRect, touchPoint))
	{
		if(depress && canShrink)
		{
			if(normalStateSprite.visible)
			{
				if(normalStateSprite.scale > 0.90f) [normalStateSprite setScale:0.90f];
			}
			else
			{
				if(selectedStateSprite.scale > 0.90f) [selectedStateSprite setScale:0.90f];
			}
			return YES;
			
		}
		else if(!depress)
		{
			[self setSelected:!selectedState];
			if(playsClickSound && [[NSUserDefaults standardUserDefaults] boolForKey:@"PLAY_SOUNDS"]) [self playButtonClick];
			[targetObject performSelector:targetSelector withObject:self];
			return YES;
		}
	}
	else if(depress && canShrink)
	{
		if(normalStateSprite.visible)
		{
			if(normalStateSprite.scale < 1.0f) [normalStateSprite setScale:1.0f];
		}
		else
		{
			if(selectedStateSprite.scale < 1.0f) [selectedStateSprite setScale:1.0f];
		}
	}
	return NO;
}

-(void)releaseIfDepressed
{
	if(normalStateSprite.visible)
	{
		if(normalStateSprite.scale < 1.0f) [normalStateSprite setScale:1.0f];
	}
	else
	{
		if(selectedStateSprite.scale < 1.0f) [selectedStateSprite setScale:1.0f];
	}
}

-(BOOL)checkForHit:(UITouch*)touch
{
	return [self checkForHit:touch depressOnly:NO];
}

-(void)setPosition:(CGPoint)pos
{
	[normalStateSprite setPosition:pos];
	[selectedStateSprite setPosition:pos];
	if(!normalStateSprite.visible && (selectedStateSprite == nil || !selectedStateSprite.visible))
		[self setSelected:selectedState];
}

-(void)setSelected:(BOOL)selected
{
	if(selectedStateSprite != nil)
	{
		if(selected)
		{
			
			[normalStateSprite setVisible:NO];
			[selectedStateSprite setVisible:YES];
			[normalStateSprite setScale:1.0f];
			[selectedStateSprite setScale:1.0f];
		}
		else
		{
			[normalStateSprite setVisible:YES];
			[selectedStateSprite setVisible:NO];
			[normalStateSprite setScale:1.0f];
			[selectedStateSprite setScale:1.0f];
		}
		selectedState = selected;
	}
	else
	{
		if(!normalStateSprite.visible)
			[normalStateSprite setVisible:YES];
		[normalStateSprite setScale:1.0f];
	}
}

-(BOOL)isSelected
{
	return selectedState;
}

-(BOOL)isVisible
{
	return [normalStateSprite visible] || [selectedStateSprite visible];
}

-(void)setVisible:(BOOL)visible
{
	[normalStateSprite setVisible:visible];
	[selectedStateSprite setVisible:visible];
}

- (void) playButtonClick
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BUTTONCLICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
}

@end