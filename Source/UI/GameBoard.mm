//
//  GameBoard.mm
//  PinballMini
//
//  Created by Adam Byram on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GameBoard.h"
#import "PinballMiniConstants.h"
#import	"CocosDenshion.h"
#import "CDAudioManager.h"

#define LAUNCHER_X_SHIFT 9.0f
#define HAMMER_OFFSET 2.0f
#define GAME_TICK_INTERVAL 1.0f
#define SPACE_ITERATIONS 8
#define SPACE_ELASTIC_ITERATIONS 0
#define PHYSICS_STEPS 8

static BOOL L0AccelerationIsShaking(UIAcceleration* last, UIAcceleration* current, double threshold) {
	double
	deltaX = fabs(last.x - current.x),
	deltaY = fabs(last.y - current.y),
	deltaZ = fabs(last.z - current.z);
	
	return
	(deltaX > threshold && deltaY > threshold) ||
	(deltaX > threshold && deltaZ > threshold) ||
	(deltaY > threshold && deltaZ > threshold);
}

static void
eachShape(void *ptr, void* unused)
{
	GameBoard* gameBoard = (GameBoard*)unused;
	//if([gameBoard isPaused]) return;
	cpShape *shape = (cpShape*) ptr;
	CCSprite *sprite = (CCSprite*)shape->data;
	if( sprite && shape->collision_type != 20 ) {
		cpBody *body = shape->body;
		
		// TIP: cocos2d and chipmunk uses the same struct to store it's position
		// chipmunk uses: cpVect, and cocos2d uses CGPoint but in reality the are the same
		// since v0.7.1 you can mix them if you want.
		
		// before v0.7.1
		//		[sprite setPosition: ccp( body->p.x, body->p.y)];
		
		// since v0.7.1 (eaier)
		[sprite setPosition: body->p];
		
		// Active Object Spinner
		if(shape->collision_type == 25)
		{
			[sprite setRotation: (float) CC_RADIANS_TO_DEGREES( -body->a )];
			//float factor = 0.95f;
			//cpBodyApplyImpulse(body, cpv(-body->rot.x/factor,-body->rot.y/factor), body->p);
			//cpBodySetAngVel(body,cpBodyGetAngVel(body)*.99995);
			//body->rot.x = body->rot.x*factor;
			//body->rot.y = body->rot.y*factor;
			 
			
		}
	}
}

static int ballToWallCollision(cpArbiter *arb, cpSpace *space, void *data)
{
	//NSLog(@"%f",contacts->bounce);
	// TODO This was needed to play a sound...not sure if we want to play it from here or not...
	GameBoard* obj = (GameBoard*)data;
	
	//if(contacts->bounce > 60 || contacts->bounce < -60)
	//if(arb->contacts->bounce > 0.001f && arb->contacts->bounce < 1000000.0f)
	//NSLog(@"Ball hit with force: %f",arb->contacts->bounce);
	//if(arb->contacts->bounce > 0.05f && arb->contacts->bounce < 1000000.0f)
	//NSLog(@"%f",arb->a->body->v);
	//if(arb->a->body->v
	//{
		float force = cpvlength(arb->private_a->body->v);
	//arb->state == 
		//NSLog(@"Force is %f - percent: %f",arb->contacts->bounce,force,nil);
	//NSLog(@"%f",cpvlength(arb->a->body->v));
	float requiredForce = 200.0f;
	if(force > requiredForce)
	{
		CCSprite *sprite = (CCSprite*)arb->private_a->data;
		[obj playBallHitSound:((force-requiredForce)/800.0f) forBall:sprite];
	}
	//if(fabs(arb->a->body->v.x) > 10.0f || fabs(arb->a->body->v.y) > 10.0f)
	//	[obj playBallHitSound:1.0f];
		//if(obj.playSounds)AudioServicesPlaySystemSound(ballOnPlasticSound);
		//NSLog(@"Ball hit with force: %f",arb->contacts->bounce);
		//float force = 1.0f;
		//[obj playBallHitSound:force];
	//}
	//if(a->body->v.x > 20 || a->body->v.x < -20 || a->body->v.y > 20 || a->body->v.y < -20) 
	//{
	//	AudioServicesPlaySystemSound(ballOnPlasticSound);
	//	}
	
	// Get access to your layer - so you can do what you want.
	//NSLog(@"ball to wall hit");
	//NSLog(@"cpShape A X:%f, Y:%f",a->body->p.x, a->body->p.y);
	//NSLog(@"Hit cpShape B X:%f, Y:%f",b->body->p.x, b->body->p.y);
	return 1;
}

static int ballToBallCollision(cpArbiter *arb, cpSpace *space, void *data)
{
	//NSLog(@"%f",contacts->bounce);
	//GameBoard* obj = (GameBoard*)data;
	//if(contacts->bias > 0.05)
	//{
	//if(obj.playSounds)AudioServicesPlaySystemSound(ballOnPlasticSound);
	//[obj playBallHitSound];
	//	[obj playBallClickSound];
	//}
	//if(a->body->v.x > 20 || a->body->v.x < -20 || a->body->v.y > 20 || a->body->v.y < -20) 
	//{
	//	AudioServicesPlaySystemSound(ballOnPlasticSound);
	//	}
	
	// Get access to your layer - so you can do what you want.
	//NSLog(@"ball to wall hit");
	//NSLog(@"cpShape A X:%f, Y:%f",a->body->p.x, a->body->p.y);
	//NSLog(@"Hit cpShape B X:%f, Y:%f",b->body->p.x, b->body->p.y);
	return 1;
}

static int ballToSpringHolderCollision(cpArbiter *arb, cpSpace *space, void *data)
{
	return 0;
}

static int totalScore = 0;
static int tempScore = 0;
static int ballsInScoringPosition = 0;
static cpBody* activeBalls[10];
static NSString* ballHasBeenScored[10];
static BOOL ballHasPhysicsApplied[10];
static int activeBallCount;
static BOOL ballsNeedReset;
static int ballSpriteNumber = 0;
static int boundariesAdded = 0;


static int ballToActiveObjectCollision(cpArbiter *arb, cpSpace *space, void *data)
{
	return 1;
}

static int ballToScoreCollision(cpArbiter *arb, cpSpace *space, void *data)
{
	// Make sure the ball isn't moving much
	float vthresh = 10.0f;
	cpShape *a, *b; cpArbiterGetShapes(arb, &a, &b);
	
	if(a->body->v.x < vthresh && a->body->v.x > -vthresh && a->body->v.y < vthresh && a->body->v.y > -vthresh)
	{
		
		for(int pos = 0; pos < 10; pos++)
		{
			if(activeBalls[pos] == a->body)
			{
				if(ballHasBeenScored[pos] != nil)
				{
					return 0;
				}
				ballHasBeenScored[pos] = (NSString*)b->data;
			}
			
		}
		ballsInScoringPosition++;
		//	NSLog(@"Ball scored - total balls in scoring position %i", ballsInScoringPosition);
		//NSNumber* scoreData = (NSNumber*)b->data;
		//tempScore += [scoreData intValue];
		CCSprite* ballSprite = (CCSprite*)a->data;
		//[ballSprite setColor:ccc3(193,160,4)];
		if(!ballsNeedReset) [ballSprite setColor:ccc3(0,255,0)];
	}
	return 0;
}

static int ballToHammerHeadCollision(cpArbiter *arb, cpSpace *space, void *data)
{
	cpShape *a, *b; cpArbiterGetShapes(arb, &a, &b);
	GameBoard* hw = (GameBoard*)data;
	if([hw applyHammerHeadCollision])
	{
		
		if([hw applyHammerHeadForce])
		{
			for(int pos = 0; pos < 10; pos++)
			{
				if(activeBalls[pos] == a->body)
				{
					if(ballHasPhysicsApplied[pos] == YES)
					{
						return 0;
					}
					ballHasPhysicsApplied[pos] = YES;
				}
				
			}
			if(a->body->p.y <= 480.0f-314.0f-HAMMER_OFFSET)
			{
				cpBodyResetForces(a->body);
				a->body->p = CGPointMake(a->body->p.x, 480.0f-314.0f-HAMMER_OFFSET+20);
				
				//NSLog(@"Fixed below issue");
			}
			cpBodyResetForces(a->body);
			cpBodyApplyImpulse(a->body, CGPointMake(0.0f,hw.forceToApply), CGPointMake(0.0f,0.0f));
			NSLog(@"Applied physics");
			return 0;
		}
		return 1;
		//return 0;
	}
	return 0;
}



@implementation GameBoard

@synthesize mainMenu;
@synthesize boardId;
@synthesize gameMode;

@synthesize applyHammerHeadForce;
@synthesize applyHammerHeadCollision;
@synthesize forceToApply;
@synthesize lastAcceleration;
@synthesize histeresisExcited;

@synthesize playSounds;

- (BOOL) accelerometerDisabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PM_USERDEFAULT_GRAVITYLOCK];
}

- (BOOL)isPaused
{
	return paused;
}

-(void)startShakeAnimation
{
	if(shakeSticker == nil && needToShowShake && ![[NSUserDefaults standardUserDefaults] boolForKey:@"HideShake"])
	{
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HideShake"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		shakeSticker = [CCSprite spriteWithFile:@"SHAKE.png"];
		[shakeSticker setOpacity:0];
		[shakeSticker setPosition:CGPointMake((320.0f/2.0f)-10.0f,480.0f/2.0f)];
		[self addChild:shakeSticker z:1000];
		[shakeSticker stopAllActions];
		[shakeSticker setOpacity:255];
		shakeStickerAction = [CCRepeatForever actionWithAction:[CCSequence actions:[CCMoveBy actionWithDuration:0.25f position:CGPointMake(40.0f,0.0f)],[CCMoveBy actionWithDuration:0.25f position:CGPointMake(-40.0f,0.0f)],nil]];
		[shakeSticker runAction:shakeStickerAction];
		needToShowShake = NO;
		[self performSelector:@selector(endShakeAnimation:) withObject:nil afterDelay:3.0];
	}
	else if(![[NSUserDefaults standardUserDefaults] boolForKey:@"HideShake"])
	{
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HideShake"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

-(void)endShakeAnimation:(id)sender
{
	[self endShakeAnimation];
}

-(void)endShakeAnimation
{
	
	if(shakeSticker != nil)
	{
		[shakeSticker stopAllActions];
		[shakeSticker runAction:[CCFadeOut actionWithDuration:0.2]];
		shakeSticker = nil;
		shakeStickerAction = nil;
	}
}

-(void)pauseShakeAnimation:(BOOL)pause
{
	if(shakeSticker && pause)
	{
		[shakeSticker setVisible:NO];
	}
	else if(shakeSticker && !pause)
	{
		[shakeSticker setVisible:YES];
	}
}

-(void)pauseHammerAnimation:(BOOL)pause
{
	if(pullAndReleaseSticker && pause)
	{
		[pullAndReleaseSticker setVisible:NO];
	}
	else if(pullAndReleaseSticker && !pause)
	{
		[pullAndReleaseSticker setVisible:YES];
	}
}

-(void)startHammerAnimation
{
	if(pullAndReleaseSticker == nil&& ![[NSUserDefaults standardUserDefaults] boolForKey:@"HideHammerAnimation"])
	{
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HideHammerAnimation"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		pullAndReleaseSticker = [CCSprite spriteWithFile:@"FLICK.png"];
		[pullAndReleaseSticker setPosition:CGPointMake(100.0f,480.0f-395.0f)];
		CCSprite* arrowCCSprite = [CCSprite spriteWithFile:@"FLICK_ARROW.png"];
		float arrowXPosition = 160.0f;
		[arrowCCSprite setPosition:CGPointMake(arrowXPosition,70.0f)];
		[arrowCCSprite runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.8f position:CGPointMake(arrowXPosition,0.0f)],[CCMoveTo actionWithDuration:0.4f position:CGPointMake(arrowXPosition,70.0f)],nil]]];
		[pullAndReleaseSticker addChild:arrowCCSprite];
		[self addChild:pullAndReleaseSticker z:1000];
	}
}

-(void)endHammerAnimation
{
	if(pullAndReleaseSticker != nil)
	{
		[pullAndReleaseSticker stopAllActions];
		[pullAndReleaseSticker runAction:[CCFadeOut actionWithDuration:0.2f]];
		[[[pullAndReleaseSticker children] objectAtIndex:0] runAction:[CCFadeOut actionWithDuration:0.2f]];
		[self removeChild:pullAndReleaseSticker cleanup:YES];
		pullAndReleaseSticker = nil;
	}
}

NSMutableArray* physicsLines = nil;

-(void)loadShapeXml
{
	loadingBoundaries = NO;
	loadingScoring = NO;
	loadingActiveObjects = NO;
	loadingSpinnerActiveObject = NO;
	loadingSliderActiveObject = NO;
	physicsLines = [[NSMutableArray	 alloc] init];
	NSError* error;
	NSData* fileData = [[NSData dataWithContentsOfFile:[self fullPathForResource:@"Physics.svg"] options:NSUncachedRead error:&error] retain];
	if(fileData == nil)
	{
		NSLog(@"File data was NIL.");
	}
	NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithData:fileData];
	[xmlParser setDelegate:self];
	[xmlParser parse];
	//[xmlParser performSelector:@selector(parse) withObject:nil afterDelay:1.0];
	[fileData release];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSLog(@"Parse error %@",parseError);
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	NSLog(@"Parser starting...");
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	NSLog(@"Parser finished - found %i items.",boundariesAdded);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if([elementName compare:@"g"] == NSOrderedSame && [(NSString*)[attributeDict objectForKey:@"id"] compare:@"Boundaries"] == NSOrderedSame)
	{
		loadingBoundaries = YES;
		loadingScoring = NO;
		loadingActiveObjects = NO;
	}
	else if([elementName compare:@"g"] == NSOrderedSame && [(NSString*)[attributeDict objectForKey:@"id"] compare:@"Scoring"] == NSOrderedSame)
	{
		loadingBoundaries = NO;
		loadingScoring = YES;
		loadingActiveObjects = NO;
	}
	else if([elementName compare:@"g"] == NSOrderedSame && [(NSString*)[attributeDict objectForKey:@"inkscape:label"] compare:@"ActiveObjects"] == NSOrderedSame)
	{
		loadingBoundaries = NO;
		loadingScoring = NO;
		loadingActiveObjects = YES;
		loadingSpinnerActiveObject = NO;
		loadingSliderActiveObject = NO;
	}
	else if([elementName compare:@"path"] == NSOrderedSame && (loadingBoundaries || loadingScoring || loadingActiveObjects))
	{
		if([attributeDict objectForKey:@"d"] != nil)
		{
			BOOL usingRelativeCoordinates = NO;
			BOOL isAbsoluteCoordinate = NO;
			
			float currentX = 0.0f;
			float currentY = 0.0f;
			
		
			NSString* rawPointData = [attributeDict objectForKey:@"d"];
			if([rawPointData characterAtIndex:0] == 'm')
			{
				isAbsoluteCoordinate = YES;
				usingRelativeCoordinates = YES;
			}
			NSArray* itemsToProcess = [[[[[[rawPointData stringByReplacingOccurrencesOfString:@"M" withString:@""] stringByReplacingOccurrencesOfString:@"m" withString:@""] stringByReplacingOccurrencesOfString:@"L" withString:@""] stringByReplacingOccurrencesOfString:@"z" withString:@""] stringByReplacingOccurrencesOfString:@"C" withString:@""] componentsSeparatedByString:@" "];
			NSMutableArray* xValues = [[NSMutableArray alloc] init];
			NSMutableArray* yValues = [[NSMutableArray alloc] init];
			
			float xCenter = 0.0f;
			float yCenter = 0.0f;
			int pointCount = 0;
			
			for(NSString* itemString in itemsToProcess)
			{
				// Skip empty strings
				if([itemString length] > 0)
				{
					NSArray* values = [itemString componentsSeparatedByString:@","];
					float x = [[values objectAtIndex:0] floatValue];
					float y = [[values objectAtIndex:1] floatValue];
					
					if(usingRelativeCoordinates && isAbsoluteCoordinate)
					{
						currentX = x;
						currentY = y;
						isAbsoluteCoordinate = NO;
					}else if(usingRelativeCoordinates)
					{
						// This is a relative coord...so make it absolute
						x = currentX + x;
						y = currentY + y;
						currentX = x;
						currentY = y;
					}
					
					xCenter += x;
					yCenter += y;
					pointCount++;
					[xValues addObject:[NSString stringWithFormat:@"%f",x,nil]];
					[yValues addObject:[NSString stringWithFormat:@"%f",y,nil]];
					boundariesAdded++;
				}
			}
			
			xCenter = xCenter/pointCount;
			yCenter = yCenter/pointCount;
			
			[xValues addObject:[xValues objectAtIndex:0]];
			[yValues addObject:[yValues objectAtIndex:0]];
			
			NSMutableDictionary* physicsDictionary = [[NSMutableDictionary alloc] init];
			[physicsDictionary setObject:xValues forKey:@"X"];
			[physicsDictionary setObject:yValues forKey:@"Y"];
			[physicsLines addObject:physicsDictionary];
			
			
			
			cpShape *shape;
			cpBody* activeObjectBody = NULL;
			cpVect* segments = NULL;
			CCSprite* activeObjectSprite = nil;
			float endX = 0.0f;
			float endY = 0.0f;
			float slideDuration = 0.0f;
			if(loadingActiveObjects)
			{
				activeObjectBody = cpBodyNew(0.0005f, 0.0f);
				//activeObjectBody = cpBodyNew(0.0003f, 0.0f);
				activeObjectBody->p = ccp(xCenter,480.0f-yCenter);
				

				segments = (cpVect*)malloc(sizeof(cpVect)*[xValues count]);
				
				if([(NSString*)[[[attributeDict objectForKey:@"inkscape:label"] componentsSeparatedByString:@"|"] objectAtIndex:0] compare:@"spinner"] == NSOrderedSame)
				{
					// Dealing w/ a spinner
					loadingSpinnerActiveObject = YES;
					cpSpaceAddBody(space, activeObjectBody);
				}else if ([(NSString*)[[[attributeDict objectForKey:@"inkscape:label"] componentsSeparatedByString:@"|"] objectAtIndex:0] compare:@"slider"] == NSOrderedSame) {
					loadingSliderActiveObject = YES;
					// Don't add the body to space if it's a slider - we'll move that ourself
					
					endX = [[[[[[attributeDict objectForKey:@"inkscape:label"] componentsSeparatedByString:@"|"] objectAtIndex:2] componentsSeparatedByString:@","] objectAtIndex:0] floatValue];
					endY = [[[[[[attributeDict objectForKey:@"inkscape:label"] componentsSeparatedByString:@"|"] objectAtIndex:2] componentsSeparatedByString:@","] objectAtIndex:1] floatValue];
					slideDuration = [[[[attributeDict objectForKey:@"inkscape:label"] componentsSeparatedByString:@"|"] objectAtIndex:3] floatValue];
				}
				
				
				activeObjectSprite = [[CCSprite spriteWithFile:[self fullPathForResource:[[[attributeDict objectForKey:@"inkscape:label"] componentsSeparatedByString:@"|"] objectAtIndex:1]]] retain];
			}
			int segmentCount = 0;
			for(int item = 0; item < [xValues count]-2; item++)
			{
				float x1 = [[xValues objectAtIndex:item] floatValue];
				float x2 = [[xValues objectAtIndex:item+1] floatValue];
				
				float y1 = 480.0f-[[yValues objectAtIndex:item] floatValue];
				float y2 = 480.0f-[[yValues objectAtIndex:item+1] floatValue];
				
				if(loadingActiveObjects) 
				{
					segments[item] = cpv(x1,y1);
					segmentCount++;
				}
				
				
				
				if(loadingBoundaries)
				{
					shape = cpSegmentShapeNew(staticBody, ccp(x1,y1), ccp(x2,y2), 0.0f);
					shape->e = 1.0f; shape->u = 1.0f;
					shape->collision_type = 11;
					cpSpaceAddStaticShape(space, shape);
				}else if(loadingScoring)
				{
					shape = cpSegmentShapeNew(staticBody, ccp(x1,y1), ccp(x2,y2), 0.0f);
					shape->e = 1.0f; shape->u = 1.0f;
					shape->collision_type = 20;
					NSString* scoreAmount = [attributeDict objectForKey:@"inkscape:label"];
					//NSString* idWithScore = [[attributeDict objectForKey:@"id"] stringByAppendingString:[@"|" stringByAppendingString:scoreAmount]];
					NSString* stringData = [NSString stringWithFormat:@"%@|%@|%f,%f",[attributeDict objectForKey:@"id"],scoreAmount, xCenter,yCenter,nil];
					//NSArray* scoreItems = [scoreAmount componentsSeparatedByString:@"_"];
					//int* score = (int*)malloc(sizeof(int));
					//shape->data = [[NSNumber alloc] initWithInt:[[scoreItems objectAtIndex:1] intValue]];
					shape->data = [stringData copy];
					cpSpaceAddStaticShape(space, shape);
				}
				else if(loadingActiveObjects)
				{
					
					
					cpShape* segmentShape = cpSegmentShapeNew(activeObjectBody, ccp(activeObjectBody->p.x - x1,activeObjectBody->p.y - y1), ccp(activeObjectBody->p.x - x2,activeObjectBody->p.y - y2), 0.0f);
					segmentShape->e = 1.0f; segmentShape->u = 1000000.0f;
					segmentShape->collision_type = 25;
					segmentShape->group = 3;
					segmentShape->data = activeObjectSprite;
					//segmentShape->group = 2;
					cpSpaceAddShape(space, segmentShape);
					//body2->p = ccp(point.x,point.y);
					//cpSpaceAddBody(space, body2);
					
					//cpShape* ballShape = cpCircleShapeNew(body2, 16.0f/2.0, CGPointZero);
					//ballShape->e = 0.3f; ballShape->u = 0.1f;
					//ballShape->data = ballSprite;
					//ballShape->collision_type = 10;
					//cpSpaceAddShape(space, ballShape);
					//body2->data = ballShape;
					
				}
				
				
				
			}
			
			if(loadingActiveObjects)
			{
				// All segments should be loaded - so finish building out the shape
				//activeObjectBody->p = ccp(xCenter,480.0f-yCenter);
				//cpConstraint* joint = cpPinJointNew(activeObjectBody,staticBody,cpv(0.0f,0.0f), activeObjectBody->p);
				//cpPinJointSetDist(joint, 0.0f);
				activeObjectSprite.position = CGPointMake(xCenter,480.0f-yCenter);
				[self addChild:activeObjectSprite z:100];
				
				if(loadingSpinnerActiveObject)
				{
				// Add the joint to spin around
					cpConstraint* joint = cpPivotJointNew(activeObjectBody, staticBody, activeObjectBody->p);
					//NSLog(@"Joint Pos: %f,%f",activeObjectBody->p.x, activeObjectBody->p.y);
					cpSpaceAddConstraint(space, joint);
					float moment = cpMomentForPoly(activeObjectBody->m, segmentCount, segments, cpv(0.0f,0.0f));
					if(isnan(moment))
					{
						// TODO: Log that we got a nan error here for reporting purposes
					}
					cpBodySetMoment(activeObjectBody, moment);
					//NSLog(@"Moment: %f",moment);
					//NSLog(@"M: %f",activeObjectBody->m);
					
					
					// TODO: Continue to tweak this...I'm still not happy with it
					cpConstraint* spring = cpDampedRotarySpringNew(activeObjectBody, staticBody, 0.0f, 0.1f, 0.5f);
					cpSpaceAddConstraint(space, spring);
				}
				else if(loadingSliderActiveObject)
				{
					cpBodySetMass(activeObjectBody, INFINITY);
					cpBodySetMoment(activeObjectBody, INFINITY);
					activeObjectBody->data = activeObjectSprite;
					[activeSliderObjects addObject:activeObjectSprite];
					[activeObjectSprite setUserData:activeObjectBody];
					[activeObjectSprite runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCMoveBy actionWithDuration:slideDuration position:CGPointMake(endX,endY)],[CCMoveBy actionWithDuration:slideDuration position:CGPointMake(-endX,-endY)],nil]]];
				}
				
				//cpBodySetMoment(activeObjectBody, cpMomentForPoly(0.0005f, [xValues count], segments, cpv(0.0f,0.0f)));
				
				
				
			}
			
			[xValues release];
			[yValues release];
		}
	}
	else
	{
		loadingScoring = NO;
		loadingBoundaries = NO;
		loadingActiveObjects = NO;
	}
	//LineDrawingNode* lineNode = [LineDrawingNode node];
	//lineNode.elements = physicsLines;
	//[self addChild:lineNode];
}




-(void)playBallClickSound
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"PLAY_SOUNDS"]) AudioServicesPlaySystemSound(ballToBallClick);
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		NSLog(@"Init.");
		lastBallHitSound = [[NSMutableDictionary alloc] init];
		paused = NO;
		gameOver = NO;
		totalScore = 0;
		tempScore = 0;
		ballsNeedReset = NO;
		playSounds = YES;
		ballAnimationLock = [[NSLock alloc] init];
		//[[[UIApplication sharedApplication] delegate] setGamesStarted:[[[UIApplication sharedApplication] delegate] gamesStarted]+1];
		
		needToShowShake = YES;
		/*
		 filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Ball on Plastic" ofType:@"wav"] isDirectory:NO];
		 
		 AudioServicesCreateSystemSoundID((CFURLRef)filePath, &ballOnPlasticSound);
		 
		 
		 //filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ballHit1" ofType:@"wav"] isDirectory:NO];
		 filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"BallOnPlastic2" ofType:@"wav"] isDirectory:NO];
		 AudioServicesCreateSystemSoundID((CFURLRef)filePath, &ballHit1Sound);
		 
		 filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ballHit2" ofType:@"wav"] isDirectory:NO];
		 
		 AudioServicesCreateSystemSoundID((CFURLRef)filePath, &ballHit2Sound);
		 
		 filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ballHit3" ofType:@"wav"] isDirectory:NO];
		 
		 AudioServicesCreateSystemSoundID((CFURLRef)filePath, &ballHit3Sound);
		 
		 filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ballHit4" ofType:@"wav"] isDirectory:NO];
		 
		 AudioServicesCreateSystemSoundID((CFURLRef)filePath, &ballHit4Sound);
		 
		 
		 filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"BallClick" ofType:@"wav"] isDirectory:NO];
		 
		 AudioServicesCreateSystemSoundID((CFURLRef)filePath, &ballToBallClick);		
		 */
		
		//filePath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ScoreSound" ofType:@"wav"] isDirectory:NO];

		
		//AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Ball-Tap-Sound" ofType:@"wav"]], &bell);
		activeBallCount = 0;
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
		self.applyHammerHeadForce = NO;
		self.applyHammerHeadCollision = YES;
		loadingScoring = NO;
		loadingBoundaries = NO;
		ballHasBeenScored[0] = nil;
		ballHasBeenScored[1] = nil;
		ballHasBeenScored[2] = nil;
		ballHasBeenScored[3] = nil;
		ballHasBeenScored[4] = nil;
		ballHasBeenScored[5] = nil;
		ballHasBeenScored[6] = nil;
		ballHasBeenScored[7] = nil;
		ballHasBeenScored[8] = nil;
		ballHasBeenScored[9] = nil;

		scoreLabel = [CCLabel labelWithString:@"0" dimensions:CGSizeMake(160, 20) alignment:UITextAlignmentRight fontName:@"Arial-BoldMT" fontSize:21.0f];
		[scoreLabel setColor:ccc3(0, 0, 0)];
		//[scoreLabel setColor:ccc3(7, 170, 34)];
		
		[self addChild:scoreLabel z:1];
		[scoreLabel setPosition:CGPointMake(160,480.0f-71.0f)];
		
		timerLabel = [CCLabel labelWithString:@"" dimensions:CGSizeMake(160, 20) alignment:UITextAlignmentLeft fontName:@"Arial-BoldMT" fontSize:21.0f];
		
		[timerLabel setColor:ccc3(0, 0, 0)];
		timerLabel.visible = NO;
		[self addChild:timerLabel z:1];
		[timerLabel setPosition:CGPointMake(160+1.0f,480.0f-71.0f)];
		
		CGSize wins = [[CCDirector sharedDirector] winSize];
		
		
		
		cpInitChipmunk();
		
		staticBody = cpBodyNew(INFINITY, INFINITY);
		space = cpSpaceNew();
		cpSpaceResizeStaticHash(space, 20.0f, 70);
		cpSpaceResizeActiveHash(space, 20.0f, 70);
		
		space->gravity = ccp(0, 0);
		space->iterations = SPACE_ITERATIONS;
		space->elasticIterations = SPACE_ELASTIC_ITERATIONS;
		
		cpShape *shape;
		
		// bottom
		shape = cpSegmentShapeNew(staticBody, ccp(0,0), ccp(wins.width,0), 0.0f);
		shape->e = 1.0f; shape->u = 1.0f;
		shape->collision_type = 11;
		cpSpaceAddStaticShape(space, shape);
		
		// top
		shape = cpSegmentShapeNew(staticBody, ccp(0,wins.height), ccp(wins.width,wins.height), 0.0f);
		shape->e = 1.0f; shape->u = 1.0f;
		shape->collision_type = 11;
		cpSpaceAddStaticShape(space, shape);
		
		// left
		shape = cpSegmentShapeNew(staticBody, ccp(0,0), ccp(0,wins.height), 0.0f);
		shape->e = 1.0f; shape->u = 1.0f;
		shape->collision_type = 11;
		cpSpaceAddStaticShape(space, shape);
		
		// right
		shape = cpSegmentShapeNew(staticBody, ccp(wins.width,0), ccp(wins.width,wins.height), 0.0f);
		shape->e = 1.0f; shape->u = 1.0f;
		shape->collision_type = 11;
		cpSpaceAddStaticShape(space, shape);
		
		// Setup spring holder
		/*
		 springHolder = cpBodyNew(INFINITY, INFINITY);
		 // 274,311   288,311
		 shape = cpSegmentShapeNew(springHolder, ccp(274.0f,480.0f-311.0f), ccp(288.0f,480.0f-311.0f), 0.0f);
		 shape->e = 0.0f; shape->u = 0.0f;
		 shape->collision_type = 15;
		 cpSpaceAddStaticShape(space, shape);
		 // 274,313   288,313
		 shape = cpSegmentShapeNew(springHolder, ccp(274.0f,480.0f-313.0f), ccp(288.0f,480.0f-313.0f), 0.0f);
		 shape->e = 0.0f; shape->u = 0.0f;
		 shape->collision_type = 15;
		 cpSpaceAddStaticShape(space, shape);
		 shape = cpSegmentShapeNew(springHolder, ccp(274.0f,480.0f-311.0f), ccp(274.0f,480.0f-313.0f), 0.0f);
		 shape->e = 0.0f; shape->u = 0.0f;
		 shape->collision_type = 15;
		 cpSpaceAddStaticShape(space, shape);
		 shape = cpSegmentShapeNew(springHolder, ccp(288.0f,480.0f-311.0f), ccp(288.0f,480.0f-313.0f), 0.0f);
		 shape->e = 0.0f; shape->u = 0.0f;
		 shape->collision_type = 15;
		 cpSpaceAddStaticShape(space, shape);
		 */
		// Hammer head
		// 274,314   288,314
		// 274,322   288,322
		[self moveHammerHead:0.0f];
		/*hammerHead = cpBodyNew(INFINITY, INFINITY);
		 shape = cpSegmentShapeNew(hammerHead, ccp(274.0f,480.0f-314.0f), ccp(288.0f,480.0f-314.0f), 0.0f);
		 shape->e = 0.0f; shape->u = 0.0f;
		 shape->collision_type = 16;
		 cpSpaceAddStaticShape(space, shape);
		 shape = cpSegmentShapeNew(hammerHead, ccp(274.0f,480.0f-322.0f), ccp(288.0f,480.0f-322.0f), 0.0f);
		 shape->e = 0.0f; shape->u = 0.0f;
		 shape->collision_type = 16;
		 cpSpaceAddStaticShape(space, shape);
		 shape = cpSegmentShapeNew(hammerHead, ccp(274.0f,480.0f-314.0f), ccp(274.0f,480.0f-322.0f), 0.0f);
		 shape->e = 0.0f; shape->u = 0.0f;
		 shape->collision_type = 16;
		 cpSpaceAddStaticShape(space, shape);
		 shape = cpSegmentShapeNew(hammerHead, ccp(288.0f,480.0f-314.0f), ccp(288.0f,480.0f-322.0f), 0.0f);
		 shape->e = 0.0f; shape->u = 0.0f;
		 shape->collision_type = 16;
		 cpSpaceAddStaticShape(space, shape);
		 */
		/*
		 // Try to draw the "dome" at the top
		 //L 94.364854,17.117801 L 121.94422,8.7378976 L 156,4 L 193.59637,7.3125155 L 230.97473,20.023057 L 268.66281,45.951096 L 297.36045,78.811607 L 313.0987,111.96485 L 322,148
		 shape = cpSegmentShapeNew(staticBody, ccp(0.0f,480.0f-139), ccp(10.65f,480.0f-105.60f), 0.0f);
		 shape->e = 1.0f; shape->u = 1.0f;
		 cpSpaceAddStaticShape(space, shape);
		 
		 shape = cpSegmentShapeNew(staticBody, ccp(10.65f,480.0f-105.60f), ccp(24.51f,480.0f-77.72f), 0.0f);
		 shape->e = 1.0f; shape->u = 1.0f;
		 cpSpaceAddStaticShape(space, shape);
		 
		 shape = cpSegmentShapeNew(staticBody, ccp(24.51f,480.0f-77.72f), ccp(44.62f,480.0f-52.33f), 0.0f);
		 shape->e = 1.0f; shape->u = 1.0f;
		 cpSpaceAddStaticShape(space, shape);
		 
		 shape = cpSegmentShapeNew(staticBody, ccp(44.62f,480.0f-52.33f), ccp(67.01,480.0f-33.04f), 0.0f);
		 shape->e = 1.0f; shape->u = 1.0f;
		 cpSpaceAddStaticShape(space, shape);
		 */
		
		[self schedule: @selector(step:)];
		
		
		
		// create and initialize a Label
		//Label* label = [CCLabel labelWithString:@"Hello World" fontName:@"Marker Felt" fontSize:64];
		
		// ask director the the window size
		//CGSize size = [[CCDirector sharedDirector] winSize];
		
		// position the label on the center of the screen
		//label.position =  ccp( size.width /2 , size.height/2 );
		
		// add the label as a child to this Layer
		//[self addChild: label];
		
		//cpSpaceAddCollisionPairFunc(space, 10, 11, &ballToWallCollision, self);
		//cpSpaceAddCollisionHandler(space, 10, 11, NULL, &ballToWallCollision, NULL, NULL, self);
		cpSpaceAddCollisionHandler(space, 10, 11, &ballToWallCollision, NULL, NULL, NULL, self);
		//cpSpaceAddCollisionPairFunc(space, 10, 15, &ballToSpringHolderCollision, self);
		cpSpaceAddCollisionHandler(space, 10, 15, NULL, &ballToSpringHolderCollision, NULL, NULL, self);
		//cpSpaceAddCollisionPairFunc(space, 10, 16, &ballToHammerHeadCollision, self);
		cpSpaceAddCollisionHandler(space, 10, 16, NULL, &ballToHammerHeadCollision, NULL, NULL, self);
		//cpSpaceAddCollisionPairFunc(space, 10, 20, &ballToScoreCollision, self);
		cpSpaceAddCollisionHandler(space, 10, 20, NULL, &ballToScoreCollision, NULL, NULL, self);
		//cpSpaceAddCollisionPairFunc(space, 10, 10, &ballToBallCollision, self);
		cpSpaceAddCollisionHandler(space, 10, 25, NULL, &ballToActiveObjectCollision, NULL, NULL, self);
		
		ballSpriteNumber = 0;
		
		[self addBallAt:CGPointMake(37.0f,(480.0f-291.0f))];
		
		[self addBallAt:CGPointMake(30.0f,(480.0f-280.0f))];
		[self addBallAt:CGPointMake(30.0f,(480.0f-270.0f))];
		[self addBallAt:CGPointMake(30.0f,(480.0f-260.0f))];
		[self addBallAt:CGPointMake(30.0f,(480.0f-250.0f))];
		
		/*[self addBallAt:CGPointMake(286.0f,(480.0f-270.0f))];
		 [self addBallAt:CGPointMake(286.0f,(480.0f-250.0f))];
		 [self addBallAt:CGPointMake(286.0f,(480.0f-230.0f))];
		 [self addBallAt:CGPointMake(286.0f,(480.0f-210.0f))];*/
		
	}
	return self;
}


static int targetScore = 0;
static int scoreIncrement = 0;

-(void)tempCallback
{
}

- (bool)canReceiveCallbacksNow
{
	return YES;
}

static int lastSecond = 0;
-(void)timerTick:(id)sender
{
	if(timeRemaining > 0.0f && !paused)
	{
		timeRemaining -= GAME_TICK_INTERVAL;
		int minutes = ((int)timeRemaining - ((int)timeRemaining % 60)) / 60;
		int seconds = ((int)timeRemaining)%60;
		NSString* timeString = [NSString stringWithFormat:@"%02i:%02i",minutes,seconds,nil];
		
		if(minutes == 0 && seconds == 20)
		{
			[timerLabel setColor:ccc3(255,0,0)];
		}
		
		if(minutes == 0 && seconds <= 10 && seconds != lastSecond)
		{
			lastSecond = seconds;
			[self playClockTick];
		}
		
		[timerLabel setString:timeString];
		if(timeRemaining <= 0.0f)
		{
			paused = YES;
			gameOver = YES;
			
			if(scoreIncreaseIsActive)
			{
				totalScore = targetScore;
			}
			
			NSMutableArray* scoreArray = [NSMutableArray arrayWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%iHighScoreList.plist",gameMode,nil]]];
			int insertAtPosition = -1;
			for(int index = 0; index < [scoreArray count]; index++)
			{
				int oldHighScore = [[[scoreArray objectAtIndex:index] objectForKey:@"Score"] intValue];
				if(totalScore > oldHighScore)
				{
					insertAtPosition = index;
					break;
				}
			}
			//[[[UIApplication sharedApplication] delegate] setGamesFinished:[[[UIApplication sharedApplication] delegate] gamesFinished]+1];
			
			//OFDelegate success = OFDelegate(self, @selector(tempCallback));	
			//OFDelegate failure = OFDelegate(self, @selector(tempCallback));
			
			// Submit high score to OF
			//[OFHighScoreService setHighScore:[[NSNumber numberWithInt:totalScore] longLongValue] withDisplayText:nil withCustomData:nil forLeaderboard:@"182263" silently:NO onSuccess:success onFailure:failure];
			
			
			// TODO: Handle submitting a score
			//if(totalScore > 0 && ((insertAtPosition != -1 && insertAtPosition < 15) || (insertAtPosition == -1 && [scoreArray count] < 15)))
			//{
			//	NewHighScoreScene* scene = [NewHighScoreScene scene];
			//	[[scene.children objectAtIndex:0] setHighScore:totalScore];
			//	[[scene.children objectAtIndex:0] setGameMode:gameMode];
			//	[[scene.children objectAtIndex:0] setBoardNumber:[boardPrefix intValue]];
			//	[[CCDirector sharedDirector] replaceScene:[FadeTransition transitionWithDuration:0.5f scene:(Scene*)scene]];
			//}
			//else
			//{
			//	[[CCDirector sharedDirector] replaceScene:[FadeTransition transitionWithDuration:0.5f scene:[HighScoreList scene]]];
			//}
						
			//[self showMenu:nil];
			[self playVictorySoundAndExitToMenu];
			
		}
	}
	else
	{
		
	}
}


static int ballsStillAnimating = 0;


-(void)spinScoreBy:(int)score
{
	scoreIncreaseIsActive = YES;
	targetScore = totalScore + score;
	
	//[FlurryAPI logEvent:PM_ANALYTICS_CALCULATED_SCORE withParameters:[NSDictionary dictionaryWithObjectsAndKeys:boardPrefix, @"Board",[NSNumber numberWithInt:score],@"Round Score",[NSNumber numberWithInt:targetScore],@"Total Score",nil]];
	
	//[OFAchievementService queueUnlockedAchievement:@"192083"];
	
	//if([[NSUserDefaults standardUserDefaults] boolForKey:@"PLAY_SOUNDS"]) AudioServicesPlaySystemSound(scoreSound);
	[self playDing:nil];
	
	scoreIncrement = (int)score / 30.0f;
	[self schedule:@selector(incrementScore:)];
	
	
	
	ccColor3B deactivatedBallColor = ccc3(255,255,0);
	[(CCSprite*)((cpShape*)activeBalls[0]->data)->data setColor:deactivatedBallColor];
	[(CCSprite*)((cpShape*)activeBalls[1]->data)->data setColor:deactivatedBallColor];
	[(CCSprite*)((cpShape*)activeBalls[2]->data)->data setColor:deactivatedBallColor];
	[(CCSprite*)((cpShape*)activeBalls[3]->data)->data setColor:deactivatedBallColor];
	[(CCSprite*)((cpShape*)activeBalls[4]->data)->data setColor:deactivatedBallColor];
	
	ballsStillAnimating = 5;
	
	for(int i = 0; i < 5; i++)
	{
		CCSprite* ballSprite = (CCSprite*)((cpShape*)activeBalls[i]->data)->data;
		CCAction* scoreAnimation = [CCSequence actions:[CCDelayTime actionWithDuration:0.1f*i],[CCCallFunc actionWithTarget:self selector:@selector(playDing:)], [CCScaleTo actionWithDuration:0.3f scale:.65f],[CCScaleTo actionWithDuration:0.1f scale:0.1f],[CCCallFuncND actionWithTarget:self selector:@selector(ballScoreAnimationFinished:withData:) data:ballSprite], nil];
		[[[ballSprite children] objectAtIndex:0] runAction:scoreAnimation];
	}
}

- (void)playVictorySoundAndExitToMenu
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_VICTORY channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
	[self performSelector:@selector(showMenu:) withObject:nil afterDelay:2.0f];
}


- (void)playDing:(id)sender
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_SCOREDING channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
}

- (void)playClockTick
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_CLOCKTICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
}

-(void)incrementScore:(id)sender
{
	if((totalScore + scoreIncrement) > targetScore)
	{
		totalScore = targetScore;
	}
	else
	{
		totalScore += scoreIncrement;
	}
	
	[scoreLabel setString:[NSString stringWithFormat:@"%i", totalScore]];
	
	if(totalScore == targetScore)
	{
		scoreIncreaseIsActive = NO;
		[self unschedule:@selector(incrementScore:)];
	}
}

-(void)resetBallPositions
{
	//[self addBallAt:CGPointMake(37.0f,(480.0f-291.0f))];
	//[self addBallAt:CGPointMake(30.0f,(480.0f-280.0f))];
	//[self addBallAt:CGPointMake(30.0f,(480.0f-270.0f))];
	//[self addBallAt:CGPointMake(30.0f,(480.0f-260.0f))];
	//[self addBallAt:CGPointMake(30.0f,(480.0f-250.0f))];
	if(!paused)
	{
		
		// This should help prevent the shake sticker from showing up if you 
		// shake before it starts animating.
		needToShowShake = NO;
		
		cpBody* ball;
		CCSprite* ballSprite;
		
		ball = activeBalls[0];
		ball->p = CGPointMake(37.0f,(480.0f-291.0f));
		cpBodyResetForces(ball);
		ballSprite = (CCSprite*)((cpShape*)ball->data)->data;
		[ballSprite setPosition:ball->p];
		[ballSprite setColor:ccc3(255,255,255)];
		ball = activeBalls[1];
		ball->p = CGPointMake(30.0f,(480.0f-280.0f));
		cpBodyResetForces(ball);
		ballSprite = (CCSprite*)((cpShape*)ball->data)->data;
		[ballSprite setColor:ccc3(255,255,255)];
		[ballSprite setPosition:ball->p];	
		
		ball = activeBalls[2];
		ball->p = CGPointMake(30.0f,(480.0f-270.0f));
		cpBodyResetForces(ball);
		ballSprite = (CCSprite*)((cpShape*)ball->data)->data;
		[ballSprite setColor:ccc3(255,255,255)];
		[ballSprite setPosition:ball->p];	
		
		ball = activeBalls[3];
		ball->p = CGPointMake(30.0f,(480.0f-260.0f));
		cpBodyResetForces(ball);
		ballSprite = (CCSprite*)((cpShape*)ball->data)->data;
		[ballSprite setColor:ccc3(255,255,255)];
		[ballSprite setPosition:ball->p];	
		
		ball = activeBalls[4];
		ball->p = CGPointMake(30.0f,(480.0f-250.0f));
		cpBodyResetForces(ball);
		ballSprite = (CCSprite*)((cpShape*)ball->data)->data;
		[ballSprite setColor:ccc3(255,255,255)];
		[ballSprite setPosition:ball->p];	
		
		
		ballsNeedReset = NO;
	}
}

-(void)moveHammerHead:(float)yOffset
{
	if(hammerHead != NULL) 
	{
		cpSpaceRemoveStaticShape(space, hh1);
		cpSpaceRemoveStaticShape(space, hh2);
		cpSpaceRemoveStaticShape(space, hh3);
		cpSpaceRemoveStaticShape(space, hh4);
		
		cpSpaceRemoveBody(space, hammerHead);
		cpBodyDestroy(hammerHead);
		cpBodyFree(hammerHead);
	}
	// Move down to adjust values...
	yOffset += HAMMER_OFFSET;
	float height = 50.0f;
	hammerHead = cpBodyNew(INFINITY, INFINITY);
	hh1 = cpSegmentShapeNew(hammerHead, ccp(274.0f+LAUNCHER_X_SHIFT,480.0f-314.0f-yOffset), ccp(288.0f+LAUNCHER_X_SHIFT,480.0f-314.0f-yOffset), 0.0f);
	hh1->e = 0.0f; hh1->u = 0.0f;
	hh1->collision_type = 16;
	cpSpaceAddStaticShape(space, hh1);
	hh2 = cpSegmentShapeNew(hammerHead, ccp(274.0f+LAUNCHER_X_SHIFT,480.0f-322.0f-yOffset-height), ccp(288.0f+LAUNCHER_X_SHIFT,480.0f-322.0f-yOffset-height), 0.0f);
	hh2->e = 0.0f; hh2->u = 0.0f;
	hh2->collision_type = 16;
	cpSpaceAddStaticShape(space, hh2);
	hh3 = cpSegmentShapeNew(hammerHead, ccp(274.0f+LAUNCHER_X_SHIFT,480.0f-314.0f-yOffset), ccp(274.0f+LAUNCHER_X_SHIFT,480.0f-322.0f-yOffset-height), 0.0f);
	hh3->e = 0.0f; hh3->u = 0.0f;
	hh3->collision_type = 16;
	cpSpaceAddStaticShape(space, hh3);
	hh4 = cpSegmentShapeNew(hammerHead, ccp(288.0f+LAUNCHER_X_SHIFT,480.0f-314.0f-yOffset), ccp(288.0f+LAUNCHER_X_SHIFT,480.0f-322.0f-yOffset-height), 0.0f);
	hh4->e = 0.0f; hh4->u = 0.0f;
	hh4->collision_type = 16;
	cpSpaceAddStaticShape(space, hh4);
}


-(void)addBallAt:(CGPoint)point
{
	CCSprite* ballSprite = [CCSprite spriteWithFile:@"Ball.png"];
	ballSprite.tag = ballSpriteNumber++;
	[lastBallHitSound setObject:[NSNumber numberWithBool:YES] forKey:[NSNumber numberWithInt:ballSprite.tag]];
	
	//[ball Sprite setPosition:CGPointMake(320.0f-299.0f/2,480.0f-384.0f/2)];
	[ballSprite setPosition:CGPointMake(point.x,point.y)];
	[self addChild:ballSprite z:10];
	CCSprite* tempBackground = [CCSprite spriteWithFile:@"BallScoredBackground.png"];
	//[tempBackground setScale:0.65f];
	[tempBackground setScale:0.1f];
	[tempBackground setOpacity:255*.75];
	[tempBackground setPosition:CGPointMake(8,8)];
	[ballSprite addChild:tempBackground z:-1];
	
	//float mass = 0.01f;
	float mass = 0.01f;
	cpBody* body2 = cpBodyNew(mass, cpMomentForCircle(mass, 16.0f/2.0f, 0.0f, CGPointZero));
	
	// TIP:
	// since v0.7.1 you can assign CGPoint to chipmunk instead of cpVect.
	// cpVect == CGPoint
	body2->p = ccp(point.x,point.y);
	cpSpaceAddBody(space, body2);
	
	cpShape* ballShape = cpCircleShapeNew(body2, 16.0f/2.0, CGPointZero);
	ballShape->e = 0.3f; ballShape->u = 0.1f;
	ballShape->data = ballSprite;
	ballShape->collision_type = 10;
	cpSpaceAddShape(space, ballShape);
	body2->data = ballShape;
	ballBody = body2;
	activeBalls[activeBallCount] = ballBody;
	activeBallCount++;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = CGPointMake(touchPoint.x, 480.0f-touchPoint.y);
		[pauseResumeButton checkForHit:touch depressOnly:YES];
		[mainMenuButton checkForHit:touch depressOnly:YES];
	
	if(!paused)
	{
		CGPoint buttonPosition = [thumbButton position];
		int width = 80;//[[thumbButton texture] pixelsWide];
		int height = 80;//[[thumbButton texture] pixelsHigh];
		CGRect buttonRect = CGRectMake(buttonPosition.x-(width/2.0f),buttonPosition.y-(height/2.0f),width,height);
		if(touchPoint.x >= buttonRect.origin.x && touchPoint.x <= buttonRect.origin.x + buttonRect.size.width &&
		   touchPoint.y >= buttonRect.origin.y && touchPoint.y <= buttonRect.origin.y + buttonRect.size.height)
		{
			buttonTouchActive = YES;
			distance = 0.0f;
			// Started moving the button, so clear the spring
			//cpBodyResetForces(hammerHead);
			//cpBodyResetForces(springHolder);
		}
		else
		{
			buttonTouchActive = NO;
		}
		
		/*
		 if([[touches anyObject] tapCount] == 1)
		 {
		 cpBodyApplyImpulse(ballBody, CGPointMake(0.0f,11.0f), CGPointMake(0.0f,0.0f));
		 }
		 else if([[touches anyObject] tapCount] == 3)
		 {
		 [self addBallAt:CGPointMake([[touches anyObject] locationInView:[[touches anyObject] view]].x, 480.0f-[[touches anyObject] locationInView:[[touches anyObject] view] ].y)];
		 }
		 */
	}
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = CGPointMake(touchPoint.x, 480.0f-touchPoint.y);
	
	[pauseResumeButton checkForHit:touch depressOnly:YES];
		[mainMenuButton checkForHit:touch depressOnly:YES];
	
	if(buttonTouchActive && !paused)
	{
		[self endHammerAnimation];
		float moveToY = touchPoint.y;
		if(moveToY > 480.0f-383.0f)
		{
			moveToY = 480.0f-383.0f;
		}
		if(moveToY < 480.0f-431.0f)
		{
			moveToY = 480.0f-431.0f;
		}
		distance = moveToY - (480.0f-383.0f);
		//NSLog(@"%f",moveToY);
		float originalHammerYPosition = 480.0f-382.0f;
		leverAngle = 0.0f;
		
		float dx, dy;
		CGPoint targetPosition = CGPointMake([thumbButton position].x, (480.0f-410.0f)+distance);
		CGPoint sourcePosition = CGPointMake([lever position].x,480.0f-410.0f);
		dx = targetPosition.x - sourcePosition.x;
		//dx = 0.01f;
		dy = targetPosition.y - sourcePosition.y;
		
		leverAngle = atan(dy/dx) * (180.0f/M_PI);
		
		
		[thumbButton setPosition:CGPointMake([thumbButton position].x,moveToY)];
		[hammer setPosition:CGPointMake([hammer position].x, originalHammerYPosition + distance)];
		[lever setRotation:-leverAngle];
		self.applyHammerHeadCollision = NO;
		//[self moveHammerHead:-distance];
		
	}
}


// NOTE: Force should be 0.0 (no force) to 1.0 (high force)
-(void)playBallHitSound:(float)force forBall:(CCSprite*)ballSprite
{
		if(force > 1.0f) force = 1.0f;
	if([(NSNumber*)[lastBallHitSound objectForKey:[NSNumber numberWithInt:[ballSprite tag]]] boolValue] == YES)
	{
		[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BALLONPLASTIC1 channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:force loop:NO];
		[lastBallHitSound setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithInt:[ballSprite tag]]];
		[self performSelector:@selector(allowHitSoundForBall:) withObject:[NSNumber numberWithInt:[ballSprite tag]] afterDelay:0.1];
	}

	
}

-(void)allowHitSoundForBall:(NSNumber*)ballSprite
{
	[lastBallHitSound setObject:[NSNumber numberWithBool:YES] forKey:ballSprite];
}

-(void)playHammerSound
{
	float gain = 0.5f;
	int randomSound = rand()%3;
		switch(randomSound)
		{
			case 0:
				[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_HAMMERCLICK1 channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:gain loop:NO];
				break;
			case 1:
				[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_HAMMERCLICK2 channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:gain loop:NO];
				break;
			case 2:
				[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_HAMMERCLICK3 channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:gain loop:NO];
				break;
		
	}
}

-(void)startHammerForce:(id)sender
{
	[self playHammerSound];
	self.applyHammerHeadCollision = YES;
	self.applyHammerHeadForce = YES;
	
	// Max = 49, Min = 97
	
	//self.forceToApply = 12.0f*(-distance/48.0f);
	self.forceToApply = 11.0f*(-distance/48.0f);
	//NSLog(@"Force To Apply: %f \tDistance: %f",self.forceToApply, distance);
}

- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	
		[pauseResumeButton checkForHit:touch];
		[mainMenuButton checkForHit:touch];

	
	if(buttonTouchActive && !paused)
	{
		buttonTouchActive = NO;
		
		ballHasPhysicsApplied[0] = NO;
		ballHasPhysicsApplied[1] = NO;
		ballHasPhysicsApplied[2] = NO;
		ballHasPhysicsApplied[3] = NO;
		ballHasPhysicsApplied[4] = NO;
		ballHasPhysicsApplied[5] = NO;
		ballHasPhysicsApplied[6] = NO;
		ballHasPhysicsApplied[7] = NO;
		ballHasPhysicsApplied[8] = NO;
		ballHasPhysicsApplied[9] = NO;
		
		
		[lever runAction:[CCRotateBy actionWithDuration:0.05f angle:-lever.rotation]];
		[hammer runAction:[CCMoveTo actionWithDuration:0.05f position:CGPointMake(251.0f+LAUNCHER_X_SHIFT,480.0f-382.0f)]];
		[thumbButton runAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.05f position:CGPointMake(229.0f+LAUNCHER_X_SHIFT,480.0f-383.0f)], [CCCallFunc actionWithTarget:self selector:@selector(startHammerForce:)], nil]];
		// Apply the spring so snap the thing back
		//cpDampedSpring(springHolder, hammerHead, CGPointMake(7.0f,0.0f), CGPointMake(7.0f,0.0f), 0.0f, 100.0f, 0.99f, 0.2f);
	}
	/*
	 if([[touches anyObject] tapCount] == 1)
	 {
	 cpBodyApplyImpulse(ballBody, CGPointMake(0.0f,11.0f), CGPointMake(0.0f,0.0f));
	 }
	 else if([[touches anyObject] tapCount] == 3)
	 {
	 [self addBallAt:CGPointMake([[touches anyObject] locationInView:[[touches anyObject] view]].x, 480.0f-[[touches anyObject] locationInView:[[touches anyObject] view] ].y)];
	 }
	 */ 
}

/*
-(void)showMenu:(id)sender
{
	paused = YES;
	if(gameMode != GAME_MODE_FREEPLAY) 
	{
		[FlurryAPI logEvent:ANALYTICS_EXITED_GAME_EARLY withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:gameMode],@"Game Type",nil]];
		[[CCDirector sharedDirector] replaceScene:[SlideInLTransition transitionWithDuration:0.5f scene:[[[UIApplication sharedApplication] delegate] mainMenu]]];
	}
	else
	{
		[[[UIApplication sharedApplication] delegate] setGamesFinished:[[[UIApplication sharedApplication] delegate] gamesFinished]+1];
		
		if(scoreIncreaseIsActive)
		{
			totalScore = targetScore;
		}
		
		NSMutableArray* scoreArray = [NSMutableArray arrayWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%iHighScoreList.plist",gameMode,nil]]];
		int insertAtPosition = -1;
		for(int index = 0; index < [scoreArray count]; index++)
		{
			int oldHighScore = [[[scoreArray objectAtIndex:index] objectForKey:@"Score"] intValue];
			if(totalScore > oldHighScore)
			{
				insertAtPosition = index;
				break;
			}
		}
		[[[UIApplication sharedApplication] delegate] setGamesFinished:[[[UIApplication sharedApplication] delegate] gamesFinished]+1];
		if(totalScore > 0 && ((insertAtPosition != -1 && insertAtPosition < 15) || (insertAtPosition == -1 && [scoreArray count] < 15)))
		{
			NewHighScoreScene* scene = [NewHighScoreScene scene];
			[[scene.children objectAtIndex:0] setHighScore:totalScore];
			[[scene.children objectAtIndex:0] setGameMode:gameMode];
			[[scene.children objectAtIndex:0] setBoardNumber:[boardPrefix intValue]];
			[[CCDirector sharedDirector] replaceScene:[FadeTransition transitionWithDuration:0.5f scene:(Scene*)scene]];
		}
		else
		{
			[[CCDirector sharedDirector] replaceScene:[SlideInLTransition transitionWithDuration:0.5f scene:[[[UIApplication sharedApplication] delegate] mainMenu]]];
		}
		
		
	}
	
	
	
}
*/

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{	
	static float prevX=0, prevY=0;
	
#define kFilterFactor 1.0f
	
	float accelX = (float) acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
	float accelY = (float) acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
	
	prevX = accelX;
	prevY = accelY;
	
	CGPoint v = ccp( accelX, accelY);
	
	if(![self accelerometerDisabled])
	{
		space->gravity = ccpMult(v, 1500);
	}	
	
	if (self.lastAcceleration) {
		if (!histeresisExcited && L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.9)) {
			histeresisExcited = YES;
			
			/* SHAKE DETECTED. DO HERE WHAT YOU WANT. */
			//NSLog(@"Shakin baby...");
			[self resetBallPositions];
			[self endShakeAnimation];
			
		} else if (histeresisExcited && !L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.2)) {
			histeresisExcited = NO;
		}
	}
	
	self.lastAcceleration = acceleration;
}

-(void)togglePause:(id)sender
{
	NSLog(@"Pause/Resume...");
	if(!gameOver)
	{
		paused = !paused;

		[self pauseShakeAnimation:paused];
		[self pauseHammerAnimation:paused];
	}
}

-(void) onEnter
{
	[super onEnter];
	NSLog(@"OnEnter");
	boundariesAdded = 0;
	[activeSliderObjects release];
	activeSliderObjects = [[NSMutableArray alloc] init];
	// TODO: Fix analytics
	//if(gameMode == PM_SCOREMODE_FREEPLAY) 
	//	[FlurryAPI logEvent:ANALYTICS_STARTED_FREEPLAY_GAME withParameters:[NSDictionary dictionaryWithObjectsAndKeys:boardPrefix,@"Board",nil]];
	//else
	//	[FlurryAPI logEvent:ANALYTICS_STARTED_TIMED_GAME withParameters:[NSDictionary dictionaryWithObjectsAndKeys:boardPrefix,@"Board",[NSNumber numberWithInt:gameMode],@"Game Mode",nil]];
	CCSprite* backgroundSprite = [CCSprite spriteWithFile:[self fullPathForResource:@"Background.png"]];
	[backgroundSprite.texture setAliasTexParameters];
	[backgroundSprite setPosition:CGPointMake(320.0f/2,480.0f/2)];
	[self addChild:backgroundSprite z:0];
	
	if(gameMode == PM_SCOREMODE_FREEPLAY)
	{
		CCSprite* scoreBar = [CCSprite spriteWithFile:[self fullPathForResource:@"ScoreWithoutTimer.png"]];
		[scoreBar.texture setAliasTexParameters];
		[scoreBar setPosition:CGPointMake(320.0f/2,480.0f-73.0f)];
		[backgroundSprite addChild:scoreBar z:0];
	}
	else
	{
		CCSprite* scoreBar = [CCSprite spriteWithFile:[self fullPathForResource:@"ScoreWithTimer.png"]];
		[scoreBar.texture setAliasTexParameters];
		[scoreBar setPosition:CGPointMake(320.0f/2,480.0f-73.0f)];
		[backgroundSprite addChild:scoreBar z:0];
	}

	
	pivotOverlay = [CCSprite spriteWithFile:[self fullPathForResource:@"Launcher-Pivot-Joint.png"]];
	
	[pivotOverlay setPosition:CGPointMake(60.0f+LAUNCHER_X_SHIFT,480.0f-415.0f)];
	[self addChild:pivotOverlay z:20];
	
	lever = [CCSprite spriteWithFile:[self fullPathForResource:@"Launcher-Lever.png"]];
	[lever setPosition:CGPointMake(137.0f-(225.0f/2)+35+LAUNCHER_X_SHIFT,480.0f-410.0f)];
	[lever setAnchorPoint:CGPointMake(0.15555f,0.5f)];
	[self addChild:lever z:10];
	
	hammer = [CCSprite spriteWithFile:[self fullPathForResource:@"Launcher-Hammer.png"]];
	[hammer setPosition:CGPointMake(251.0f+LAUNCHER_X_SHIFT,480.0f-382.0f)];
	[self addChild:hammer z:10];
	
	thumbButton = [CCSprite spriteWithFile:[self fullPathForResource:@"Launcher-Thumb-Button.png"]];
	[thumbButton setPosition:CGPointMake(229.0f+LAUNCHER_X_SHIFT,480.0f-383.0f)];
	[self addChild:thumbButton z:50];
	
	thumbButtonOverlay = [CCSprite spriteWithFile:[self fullPathForResource:@"Launcher-Overlay.png"]];
	[thumbButtonOverlay setPosition:CGPointMake(229.0f+LAUNCHER_X_SHIFT,480.0f-404.0f)];
	[self addChild:thumbButtonOverlay z:10];
	
	
	[self loadShapeXml];
	
	
	[self startHammerAnimation];
	
		pauseResumeButton = [[CocosButton alloc] initWithNormalImage:@"Button_Pause.png" andSelectedImage:@"Button_Resume.png" andTarget:self andSelector:@selector(togglePause:) andParentNode:self];
		[pauseResumeButton setPlaysClickSound:playSounds];
		[pauseResumeButton setPosition:CGPointMake(20.0f,480.0f-20.0f)];
		
		mainMenuButton = [[CocosButton alloc] initWithNormalImage:@"Button_Menu.png" andTarget:self andSelector:@selector(showMenu:) andParentNode:self];
		[mainMenuButton setPlaysClickSound:playSounds];
		[mainMenuButton setPosition:CGPointMake(320.0f-20.0f,480.0f-20.0f)];
	
	/*
	 pauseButton = [CCSprite spriteWithFile:@"Button_Pause.png"];
	 [pauseButton setPosition:CGPointMake(23.0f,480.0f-23.0f)];
	 [self addChild:pauseButton z:1000];
	 
	 resumeButton = [CCSprite spriteWithFile:@"Button_Resume.png"];
	 [resumeButton setPosition:CGPointMake(23.0f,480.0f-23.0f)];
	 [resumeButton setOpacity:0];
	 [self addChild:resumeButton z:1000];
	 
	 mainMenuButton = [CCSprite spriteWithFile:@"Button_Menu.png"];
	 [mainMenuButton setPosition:CGPointMake(320.0f-23.0f,480.0f-23.0f)];
	 [self addChild:mainMenuButton z:1000];
	 */ 
	
	//[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 20.0)];
	
	if([self accelerometerDisabled])
	{
		space->gravity = CGPointMake(85.0f,-1400.0f);
	}
	
	if(self.gameMode == PM_SCOREMODE_TIMED2MINUTE)
	{
		if(gameMode == PM_SCOREMODE_TIMED2MINUTE)
		{
			timeRemaining = 2.0f * 60.0f;
			//timeRemaining = 20.0f;
		}
		
		timerLabel.visible = YES;
		
		// Add the extra second so we can tick it off to start
		timeRemaining += 1.0f;
		[self timerTick:nil];
		
		[self schedule:@selector(timerTick:) interval:GAME_TICK_INTERVAL];
	}
}

-(void) step: (ccTime) delta
{
	//cpSpaceRehashStatic(space);
	if(!paused)
	{
		
		// Manually update all of our active objects if needed
		for(CCSprite* activeObject in activeSliderObjects)
		{
			cpBody* aob = (cpBody*)[activeObject userData];
			cpBodySetPos(aob, activeObject.position);
		}
		
		float fixedDelta = 0.033333f;  // 1/30 sec - so 30fps
		//int steps = 10;
		int steps = PHYSICS_STEPS;
		float dt = fixedDelta/steps;	
		
		//CGFloat dt = delta/(CGFloat)steps;
		
		
		
		for(int i=0; i<steps; i++){
			tempScore = 0;
			ballsInScoringPosition = 0;
			ballHasBeenScored[0] = nil;
			ballHasBeenScored[1] = nil;
			ballHasBeenScored[2] = nil;
			ballHasBeenScored[3] = nil;
			ballHasBeenScored[4] = nil;
			ballHasBeenScored[5] = nil;
			ballHasBeenScored[6] = nil;
			ballHasBeenScored[7] = nil;
			ballHasBeenScored[8] = nil;
			ballHasBeenScored[9] = nil;
			if(!ballsNeedReset)
			{
				[(CCSprite*)((cpShape*)activeBalls[0]->data)->data setColor:ccc3(255,255,255)];
				[(CCSprite*)((cpShape*)activeBalls[1]->data)->data setColor:ccc3(255,255,255)];
				[(CCSprite*)((cpShape*)activeBalls[2]->data)->data setColor:ccc3(255,255,255)];
				[(CCSprite*)((cpShape*)activeBalls[3]->data)->data setColor:ccc3(255,255,255)];
				[(CCSprite*)((cpShape*)activeBalls[4]->data)->data setColor:ccc3(255,255,255)];
			}
			cpSpaceStep(space, dt);
			if(ballsInScoringPosition == 5 && !ballsNeedReset)
			{
				
				// TODO: Calculate score
				tempScore = 0;
				NSMutableDictionary* scoringDictionary = [[NSMutableDictionary alloc] init];
				for(int b = 0; b < 5; b++)
				{
					if([scoringDictionary objectForKey:ballHasBeenScored[b]] == nil)
					{
						[scoringDictionary setObject:[NSNumber numberWithInt:1] forKey:ballHasBeenScored[b]];
					}
					else
					{
						NSNumber* currentCount = [scoringDictionary objectForKey:ballHasBeenScored[b]];
						[scoringDictionary setObject:[NSNumber numberWithInt:[currentCount intValue]+1] forKey:ballHasBeenScored[b]];
					}
				}
				
				// If we have each ball in a different cup, then we'll have 5 entries here
				if([scoringDictionary count] == 5)
				{
					//if([OpenFeint hasUserApprovedFeint]) [OFAchievementService unlockAchievement:PM_OPENFEINT_ACHIEVEMENT_ALLBALLSINDIFFERENTCUPS];
				}
				
				
				// Now we have the buckets and number of balls in each, so we look through them and add up the score
				NSEnumerator* keyEnumerator = [scoringDictionary keyEnumerator];
				NSString* scoreKey = nil;
				int topMultiplier = 1;
				while(scoreKey = [keyEnumerator nextObject])
				{
					NSArray* scoreComponents = [scoreKey componentsSeparatedByString:@"|"];
					int baseScore = [[[[scoreComponents objectAtIndex:1] componentsSeparatedByString:@"_"] objectAtIndex:1] intValue];
					int multiplier = [[scoringDictionary objectForKey:scoreKey] intValue];
					//NSLog(@"Scored %i with x%i multiplier.",baseScore, multiplier);
					float xCenter = [[[[scoreComponents objectAtIndex:2] componentsSeparatedByString:@","] objectAtIndex:0] floatValue];
					float yCenter = [[[[scoreComponents objectAtIndex:2] componentsSeparatedByString:@","] objectAtIndex:1] floatValue];
					//NSLog(@"Score center position is: %f,%f",xCenter, yCenter);
					if(multiplier > 1)
					{
						/*
						CCParticleFlower* particleSystem = [[CCParticleFlower alloc] initWithTotalParticles:20];
						[particleSystem setScale:0.5f];
						
						ccColor4F particleColor;
						
						particleColor.r = 255/255.0f;
						particleColor.g = 1/255.0f;
						particleColor.b = 1/255.0f;
						particleColor.a	= 1.0f;
						
						[particleSystem setStartColor:particleColor];
						[particleSystem setEndColor:particleColor];
						particleSystem.position = CGPointMake(xCenter,480.0f-yCenter);
						*/ 
						CCSprite* multiplierSprite = [[CCSprite alloc] initWithFile:[NSString stringWithFormat:@"Multiplier-x%i.png",multiplier,nil]];
						//[self addChild:particleSystem z:90 tag:1];
						//[multiplierSprite addChild:particleSystem z:0 tag:1];
						multiplierSprite.visible = YES;
						multiplierSprite.opacity = 0;
						[self addChild:multiplierSprite z:100];
						multiplierSprite.position = CGPointMake(xCenter,480.0f-yCenter);
						//multiplierSprite.scaleX = 0.5;
						//multiplierSprite.scaleY = 0.5;
						[multiplierSprite setScale:0.5];
						//float multiplierScale = (multiplier == 5)? 4.0 : (multiplier == 4)? 3.0 : (multiplier == 3)? 2.0 : 1.0;
						float multiplierScale = 2.0f;
						[multiplierSprite runAction:[CCSequence actions:[CCFadeIn actionWithDuration:0.1],[CCSpawn actions:[CCScaleBy actionWithDuration:0.6f scale:multiplierScale],[CCMoveBy actionWithDuration:0.6f position:CGPointMake(0.0f, 10.0f)],nil],[CCFadeOut actionWithDuration:0.2f],[CCCallFunc actionWithTarget:self selector:@selector(removeSprite:)],nil]];
						if(multiplier > topMultiplier) topMultiplier = multiplier;
						
                        /*
                        if([OpenFeint hasUserApprovedFeint]) 
						{
							if(multiplier == 2)
							{
								
								[OFAchievementService unlockAchievement:PM_OPENFEINT_ACHIEVEMENT_MULTIPLIER2X];
							}
							else if (multiplier == 3)
							{
							
								[OFAchievementService unlockAchievement:PM_OPENFEINT_ACHIEVEMENT_MULTIPLIER3X];
							}
							else if (multiplier == 4)
							{
								
								[OFAchievementService unlockAchievement:PM_OPENFEINT_ACHIEVEMENT_MULTIPLIER4X];
							}
							else if (multiplier == 5)
							{
								
								[OFAchievementService unlockAchievement:PM_OPENFEINT_ACHIEVEMENT_MULTIPLIER5X];
							}
						}
                        */ 
						 
					}
					
					// Multiplier is the # of balls in the cup, so base*multi * balls (which is multi) = total points
					tempScore += (baseScore*multiplier)*multiplier;
				}
				
				if(topMultiplier == 2)
				{
					[[[CDAudioManager sharedManager] soundEngine] playSound:PM_SOUND_MULTIPLIER_X2 channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
				}
				else if(topMultiplier == 3)
				{
					[[[CDAudioManager sharedManager] soundEngine] playSound:PM_SOUND_MULTIPLIER_X3 channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
				}
				else if(topMultiplier == 4)
				{
					[[[CDAudioManager sharedManager] soundEngine] playSound:PM_SOUND_MULTIPLIER_X4 channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
				}
				else if(topMultiplier == 5)
				{
					[[[CDAudioManager sharedManager] soundEngine] playSound:PM_SOUND_MULTIPLIER_X5 channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
				}
				
				if((totalScore + tempScore) >= 1000000)
				{
				//	if([OpenFeint hasUserApprovedFeint]) [OFAchievementService unlockAchievement:PM_OPENFEINT_ACHIEVEMENT_ONEMILLIONPOINTS];
				}
				
				[self spinScoreBy:tempScore];
				// TODO Analytics
				/*
				NSMutableDictionary* scoreCounts = [[NSMutableDictionary alloc] init];
				
				[scoreCounts setObject:boardPrefix forKey:@"Board"];
				
				for(int b = 0; b < 5; b++)
				{
					if([scoreCounts objectForKey:[NSNumber numberWithInt:ballHasBeenScored[b]]] != nil)
					{
						[scoreCounts setObject:[NSNumber numberWithInt:([[scoreCounts objectForKey:[NSNumber numberWithInt:ballHasBeenScored[b]]] intValue]+1)] forKey:[NSNumber numberWithInt:ballHasBeenScored[b]]];
					}
					else
					{
						[scoreCounts setObject:[NSNumber numberWithInt:1] forKey:[NSNumber numberWithInt:ballHasBeenScored[b]]];
					}
				}
				
				[FlurryAPI logEvent:ANALYTICS_DETAILED_SCORE withParameters:scoreCounts];
				
				[scoreCounts release];
				*/
				 ballsNeedReset = YES;
				
			}
			
		}
		cpSpaceHashEach(space->activeShapes, &eachShape, self);
		cpSpaceHashEach(space->staticShapes, &eachShape, self);
		
		
		
		if(self.applyHammerHeadForce == YES)
		{
			self.applyHammerHeadForce = NO;
		}
	}
	
	//NSLog(@"%f,%f",hammerHead->p.x, hammerHead->p.y);
}

- (void) removeSprite:(CCNode*) sender
{
	CCSprite* sprite = (CCSprite*)sender;
	[self removeChild:sprite cleanup:YES];
}

-(void)ballScoreAnimationFinished:(id)sender withData:(void*)data
{
	
	CCSprite* ballSprite = (CCSprite*)data;
	if(ballsNeedReset)
	{
		ccColor3B deactivatedBallColor = ccc3(100,100,100);
		[ballSprite setColor:deactivatedBallColor];
	}
	else
	{
		ccColor3B deactivatedBallColor = ccc3(255,255,255);
		[ballSprite setColor:deactivatedBallColor];
	}
	[ballAnimationLock lock];
	ballsStillAnimating--;
	[ballAnimationLock unlock];
	
	if(ballsStillAnimating == 0)	[self startShakeAnimation];
	
	//[ballSprite children]
	
	//[(CCSprite*)((cpShape*)activeBalls[0]->data)->data setColor:deactivatedBallColor];
	//[(CCSprite*)((cpShape*)activeBalls[1]->data)->data setColor:deactivatedBallColor];
	//[(CCSprite*)((cpShape*)activeBalls[2]->data)->data setColor:deactivatedBallColor];
	//[(CCSprite*)((cpShape*)activeBalls[3]->data)->data setColor:deactivatedBallColor];
	//[(CCSprite*)((cpShape*)activeBalls[4]->data)->data setColor:deactivatedBallColor];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	NSLog(@"Dealloc");
	[lastBallHitSound release];
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// Release physics memory
	cpSpaceFreeChildren(space);
	cpSpaceFree(space);
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

// SAFE

- (void) scoreSubmittedToOpenFeint
{
}

- (void) failedToSubmitScoreToOpenFeint
{
}

- (void) submitScoreToOpenFeint
{
	NSDictionary* boardInformation = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForResource:@"BoardInfo.plist"]];
	NSString* leaderboardId = nil;
	if(gameMode == PM_SCOREMODE_TIMED2MINUTE)
	{
		leaderboardId = (NSString*)[[boardInformation objectForKey:@"Leaderboards"] objectForKey:@"Timed2Minute"];
	}
	else
	{
		leaderboardId = (NSString*)[[boardInformation objectForKey:@"Leaderboards"] objectForKey:@"FreePlay"];
	}
	//OFDelegate success = OFDelegate(self, @selector(scoreSubmittedToOpenFeint));	
	//OFDelegate failure = OFDelegate(self, @selector(failedToSubmitScoreToOpenFeint));
	
	
	//if([OpenFeint hasUserApprovedFeint])
	//{
	//	[OFHighScoreService  setHighScore:[[NSNumber numberWithInt:totalScore] longLongValue] forLeaderboard:leaderboardId onSuccess:success onFailure:failure];
	//}
	 
}

- (void)showMenu:(id)sender
{
	[[CDAudioManager sharedManager] resumeBackgroundMusic];
	[self submitScoreToOpenFeint];
	if([mainMenu.localScores scoreIsHighScore:totalScore forBoard:[NSString stringWithFormat:@"%i",boardId,nil] andGameMode:gameMode])
	{
		[self performSelector:@selector(slideMenuBack) withObject:nil afterDelay:0.5];
		[mainMenu.localScores submitScore:totalScore forBoard:[NSString stringWithFormat:@"%i",boardId,nil] andGameMode:gameMode];
	}
	else {
		[self slideMenuBack];
	}

}

- (void)slideMenuBack
{
	[[CCDirector sharedDirector] replaceScene:[CCSlideInLTransition transitionWithDuration:0.5f scene:mainMenu.internalScene]];
}

+(id) sceneWithMainMenu:(MainMenu*)mm andGameMode:(int)gm andBoardId:(int)bid
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameBoard *layer = [GameBoard node];
	layer.mainMenu = mm;
	layer.gameMode = gm;
	layer.boardId = bid;
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (NSString*)fullPathForResource:(NSString*)relativeResourcePath
{
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0] stringByAppendingPathComponent:[NSString stringWithFormat:@"Boards/%04i/%@",boardId,relativeResourcePath,nil]];
}

@end
