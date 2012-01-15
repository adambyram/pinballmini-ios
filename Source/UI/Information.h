//
//  Info.h
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CocosButton.h"
#import "cocos2d.h"

@interface Information : CCLayer {
	CocosButton* backToMenu;
	CCScene* originalScene;
}

@property (retain,nonatomic) CCScene* originalScene;

-(void)backToOriginalScene:(id)sender;
+(id)sceneFromOriginalScene:(CCScene*)original;

@end
