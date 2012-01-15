//
//  CocosButton.h
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CocosButton : NSObject {

	// Old
	CCSprite* normalStateSprite;
	CCSprite* selectedStateSprite;
	id targetObject;
	SEL targetSelector;
	int hint;
	BOOL selectedState;
	//SystemSoundID buttonClick;
	BOOL playsClickSound;
	BOOL canShrink;
}

- (void) playButtonClick;

// Old
-(id)initWithNormalImage:(NSString*)normalImage andTarget:(id)target andSelector:(SEL)selector andParentNode:(CCNode*)node;
-(id)initWithNormalImage:(NSString*)normalImage andTarget:(id)target andSelector:(SEL)selector andParentNode:(CCNode*)node useAntiAlias:(BOOL)antiAlias;
-(id)initWithNormalImage:(NSString*)normalImage andSelectedImage:(NSString*)selectedImage andTarget:(id)target andSelector:(SEL)selector andParentNode:(CCNode*)node;
-(id)initWithNormalImage:(NSString*)normalImage andSelectedImage:(NSString*)selectedImage andTarget:(id)target andSelector:(SEL)selector andParentNode:(CCNode*)node useAntiAlias:(BOOL)antiAlias;
-(BOOL)checkForHit:(UITouch*)touch;
-(BOOL)checkForHit:(UITouch*)touch depressOnly:(BOOL)depress;
-(void)setPosition:(CGPoint)pos;
-(void)setSelected:(BOOL)selected;
-(BOOL)isSelected;
-(void)releaseIfDepressed;
-(void)setVisible:(BOOL)visible;
-(BOOL)isVisible;


// Old
@property BOOL playsClickSound;
@property int hint;
@property BOOL canShrink;

@end
