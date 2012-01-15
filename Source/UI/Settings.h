//
//  Settings.h
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Settings : NSObject {
	UIView* settingsView;
	id target;
	SEL selector;
}

- (void) show;
- (id)initWithTarget:(id)t andSelector:(SEL)sel;
-(void)showSettings;
- (void)playButtonClick;

@end
