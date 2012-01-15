//
//  Settings.mm
//  PinballMini
//
//  Created by Adam Byram on 2/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Settings.h"
#import "PinballMiniConstants.h"
#import "cocos2d.h"
#import "CocosDenshion.h"
#import "CDAudioManager.h"

#define OFFSCREEN_POSITION CGRectMake(0, 481, 320, 299)
#define ONSCREEN_POSITION CGRectMake(0,181,320,299)


@implementation Settings

- (id)initWithTarget:(id)t andSelector:(SEL)sel
{
	if(self = [super init])
	{
		target = [t retain];
		selector = sel;
		settingsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Settings-Background.png"]];
		settingsView.userInteractionEnabled = YES;
		
		// Offscreen
		settingsView.frame = OFFSCREEN_POSITION;
		
		UIButton* settingsSoundButton = [[UIButton alloc] initWithFrame:CGRectMake(82,122,82,23)];
		[settingsSoundButton setImage:[UIImage imageNamed:@"Settings-SoundButton.png"] forState:UIControlStateNormal];
		[settingsSoundButton setImage:[UIImage imageNamed:@"Settings-SoundButton-Checked.png"] forState:UIControlStateSelected];
		[settingsSoundButton addTarget:self action:@selector(toggleSound:) forControlEvents:UIControlEventTouchUpInside];
		[settingsSoundButton setSelected:[[NSUserDefaults standardUserDefaults] boolForKey:PM_USERDEFAULT_PLAYSOUND]];
		[settingsView addSubview:settingsSoundButton];
		[settingsSoundButton release];
		
		UIButton* settingsGravityLockButton = [[UIButton alloc] initWithFrame:CGRectMake(82,158,152,23)];
		[settingsGravityLockButton setImage:[UIImage imageNamed:@"Settings-GravityLockButton.png"] forState:UIControlStateNormal];
		[settingsGravityLockButton setImage:[UIImage imageNamed:@"Settings-GravityLockButton-Checked.png"] forState:UIControlStateSelected];
		[settingsGravityLockButton addTarget:self action:@selector(toggleGravityLock:) forControlEvents:UIControlEventTouchUpInside];
		[settingsGravityLockButton setSelected:[[NSUserDefaults standardUserDefaults] boolForKey:PM_USERDEFAULT_GRAVITYLOCK]];
		[settingsView addSubview:settingsGravityLockButton];
		[settingsGravityLockButton release];
		
		UIButton* settingsSaveButton = [[UIButton alloc] initWithFrame:CGRectMake(82,248,157,33)];
		[settingsSaveButton setImage:[UIImage imageNamed:@"Settings-Save.png"] forState:UIControlStateNormal];
		[settingsSaveButton addTarget:self action:@selector(saveSettings:) forControlEvents:UIControlEventTouchUpInside];
		[settingsView addSubview:settingsSaveButton];
		[settingsSaveButton release];
		
	}
	return self;
}

- (void) show
{
	[self showSettings];
}

-(void)showSettings
{
	settingsView.frame = OFFSCREEN_POSITION;
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:settingsView];
	[UIView beginAnimations:@"settingsPanelSlideIn" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:SLIDE_SPEED];
	settingsView.frame = ONSCREEN_POSITION; // On screen
	[UIView commitAnimations];
	
}

-(void)saveSettings:(id)sender
{
	[self playButtonClick];
	
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:settingsView];
	
	[UIView beginAnimations:@"settingsPanelSlideOut" context:nil];
	[UIView setAnimationDuration:SLIDE_SPEED];
	settingsView.frame = OFFSCREEN_POSITION;
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removeSettingsFromView)];
	[UIView commitAnimations];
	
	
	// TODO: Play button sound
	//if([[NSUserDefaults standardUserDefaults] boolForKey:@"PLAY_SOUNDS"]) [self playButtonClick];
}

-(void)toggleSound:(id)sender
{
	UIButton* button = (UIButton*)sender;
	button.selected = !button.selected;
	
	[[NSUserDefaults standardUserDefaults] setBool:button.selected forKey:PM_USERDEFAULT_PLAYSOUND];
	[CDAudioManager sharedManager].mute = ![[NSUserDefaults standardUserDefaults] boolForKey:PM_USERDEFAULT_PLAYSOUND];
	
	[self playButtonClick];
}

-(void)toggleGravityLock:(id)sender
{
	UIButton* button = (UIButton*)sender;
	button.selected = !button.selected;

	[[NSUserDefaults standardUserDefaults] setBool:button.selected forKey:PM_USERDEFAULT_GRAVITYLOCK];
	
	[self playButtonClick];
}

-(void)removeSettingsFromView
{
	[target performSelector:selector];
	[settingsView removeFromSuperview];
}

- (void)playButtonClick
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BUTTONCLICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
}

- (void) dealloc
{
	[target release];
	[settingsView release];
	[super dealloc];
}

@end
