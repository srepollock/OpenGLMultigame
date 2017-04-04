//
//  CBox2D.h
//  MyGLGame
//
//  Created by Borna Noureddin on 2015-03-17.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#ifndef Arkanoid_h
#define Arkanoid_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

enum
{
    VertexAttribPosition,
    VertexAttribColor,
    NumVertexAttribs
};

@interface Arkanoid : NSObject

-(void) HelloWorld;

-(void) LaunchBall;
-(void) Update:(float)elapsedTime;
-(void) Render:(int)mvpMatPtr;
-(void) RegisterHit;
-(void) RegisterHit2;
-(void) RegisterHit3;
-(void) PaddleHit;
-(void) moveBall:(CGPoint)x;

@end

#endif
