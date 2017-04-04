//
//  CBox2D.m
//  MyGLGame
//
//  Created by Borna Noureddin on 2015-03-17.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "Arkanoid.h"
#include <OpenGLES/ES2/glext.h>
#include <stdio.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
//#define LOG_TO_CONSOLE



#pragma mark - Brick and ball physics parameters

// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define BRICK_POS_X			400
#define BRICK_POS_Y			500
#define BRICK_WIDTH			100.0f
#define BRICK_HEIGHT		10.0f
#define BRICK_WAIT			1.5f
#define BALL_POS_X			400
#define BALL_POS_Y			50
#define BALL_RADIUS			15.0f
#define BALL_VELOCITY		100000.0f
#define BALL_SPHERE_SEGS	128
#define PADDLE_POS_X        400
#define PADDLE_POS_Y        30

const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;



#pragma mark - Box2D contact listener class

class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            Arkanoid *parentObj = (__bridge Arkanoid *)(bodyA->GetUserData());
            // Call RegisterHit (assume CBox2D object is in user data)
            if (bodyA->GetPosition().x > BRICK_POS_X + 50) {
                [parentObj RegisterHit2];

            } else if (bodyA->GetPosition().x < BRICK_POS_X -50) {
                [parentObj RegisterHit3];

            } else {
                [parentObj RegisterHit];
            }
            if (bodyA->GetPosition().y < 300) {
                NSLog(@"Collision");
//                if ((bodyA->GetPosition().x < PADDLE_POS_X + 50) && (bodyA->GetPosition().x > PADDLE_POS_X - 50)) {
//                    // OK hit paddle
                    [parentObj PaddleHit];
//                }
            }
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};


#pragma mark - CBox2D

@interface Arkanoid ()
{
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
    b2Body *theBrick, *theBrick2, *theBrick3, *theBall, *thePaddle;
    CContactListener *contactListener;
    
    float paddlex;
    
    // GL-specific variables
    // You will need to set up 2 vertex arrays (for brick and ball)
    GLuint brickVertexArray, ballVertexArray, brickVertexArray2, ballVertexArray2, brickVertexArray3, ballVertexArray3, paddleVertexArray;
    int numBrickVerts, numBallVerts, numBrickVerts2, numBallVerts2, numBrickVerts3, numBallVerts3, paddleVerts;
    GLKMatrix4 modelViewProjectionMatrix;
    
    // You will also need some extra variables here
    bool ballHitBrick, ballHitBrick2, ballHitBrick3;
    bool ballHitPaddle;
    bool ballLaunched;
    float totalElapsedTime;
}
@end

@implementation Arkanoid

- (instancetype)init
{
    self = [super init];
    if (self) {
        gravity = new b2Vec2(0.0f, 0.0f); // Gravity should be -9.8
        
        world = new b2World(*gravity);
        
        // For HelloWorld
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;
        
        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the brick and ball objects for Box2D
        b2BodyDef brickBodyDef, brickBodyDef2, brickBodyDef3, paddleBodyDef;
        brickBodyDef.type = b2_dynamicBody;
        brickBodyDef.position.Set(BRICK_POS_X, BRICK_POS_Y);
        theBrick = world->CreateBody(&brickBodyDef);
        brickBodyDef2.position.Set(BRICK_POS_X + 150, BRICK_POS_Y);
        theBrick2 = world->CreateBody(&brickBodyDef2);
        brickBodyDef3.position.Set(BRICK_POS_X - 150, BRICK_POS_Y);
        theBrick3 = world->CreateBody(&brickBodyDef3);
        paddleBodyDef.position.Set(BRICK_POS_X, BALL_POS_Y - 25	);
        thePaddle = world->CreateBody(&paddleBodyDef);
        if (theBrick)
        {
            theBrick->SetUserData((__bridge void *)self);
            theBrick->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theBrick->CreateFixture(&fixtureDef);
            NSLog(@"Box 1");
        }
        if (theBrick2) {
            theBrick2->SetUserData((__bridge void *)self);
            theBrick2->SetAwake(false);
            b2PolygonShape dynamicBox2;
            dynamicBox2.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef2;
            fixtureDef2.shape = &dynamicBox2;
            fixtureDef2.density = 1.0f;
            fixtureDef2.friction = 0.3f;
            fixtureDef2.restitution = 1.0f;
            theBrick2->CreateFixture(&fixtureDef2);
            NSLog(@"Box 2");
        }
        if (theBrick3) {
            theBrick3->SetUserData((__bridge void *)self);
            theBrick3->SetAwake(false);
            b2PolygonShape dynamicBox3;
            dynamicBox3.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef3;
            fixtureDef3.shape = &dynamicBox3;
            fixtureDef3.density = 1.0f;
            fixtureDef3.friction = 0.3f;
            fixtureDef3.restitution = 1.0f;
            theBrick3->CreateFixture(&fixtureDef3);
            NSLog(@"Box 3");
        }
        if (thePaddle) {
            thePaddle->SetUserData((__bridge void *)self);
            thePaddle->SetAwake(false);
            b2PolygonShape dynamicBox4;
            dynamicBox4.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef4;
            fixtureDef4.shape = &dynamicBox4;
            fixtureDef4.density = 1.0f;
            fixtureDef4.friction = 0.3f;
            fixtureDef4.restitution = 1.0f;
            thePaddle->CreateFixture(&fixtureDef4);
            NSLog(@"BoxthePaddle");
        }
        
        b2BodyDef ballBodyDef;
        ballBodyDef.type = b2_dynamicBody;
        ballBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
        theBall = world->CreateBody(&ballBodyDef);
        if (theBall)
        {
            theBall->SetUserData((__bridge void *)self);
            theBall->SetAwake(false);
            b2CircleShape circle;
            circle.m_p.Set(0, 0);
            circle.m_radius = BALL_RADIUS;
            b2FixtureDef circleFixtureDef;
            circleFixtureDef.shape = &circle;
            circleFixtureDef.density = 1.0f;
            circleFixtureDef.friction = 0.3f;
            circleFixtureDef.restitution = 1.0f;
            theBall->CreateFixture(&circleFixtureDef);
        }
    }
        
    totalElapsedTime = 0;
    ballHitBrick = false;
    ballHitBrick2 = false;
    ballHitBrick3 = false;
    ballLaunched = false;
    return self;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (groundBodyDef) delete groundBodyDef;
    if (groundBox) delete groundBox;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        theBall->ApplyLinearImpulse(b2Vec2(0, BALL_VELOCITY), theBall->GetPosition(), true);
        theBall->SetActive(true);
#ifdef LOG_TO_CONSOLE
        NSLog(@"Applying impulse %f to ball\n", BALL_VELOCITY);
#endif
        ballLaunched = false;
    }
    
    // Check if it is time yet to drop the brick, and if so
    //  call SetAwake()
    totalElapsedTime += elapsedTime;
    if ((totalElapsedTime > BRICK_WAIT) && theBrick)
        theBrick->SetAwake(true);
    
    
    int lb = -BALL_VELOCITY*2;
    int ub = BALL_VELOCITY*2;
    int randy = lb + arc4random() % (ub - lb);
    
    if (theBall->GetPosition().x > 800) {
        theBall->SetLinearVelocity(b2Vec2(theBall->GetLinearVelocity().x * -1, theBall->GetLinearVelocity().y));
        
        NSLog(@"Applying impulse %f to ball\n", BALL_VELOCITY);

    }
    
    
    if (theBall->GetPosition().x < 0) {
        theBall->SetLinearVelocity(b2Vec2(theBall->GetLinearVelocity().x * -1, theBall->GetLinearVelocity().y));
        NSLog(@"Applying impulse %f to ball\n", BALL_VELOCITY);

    }
    
    if (theBall->GetPosition().y > 565) {
        theBall->SetLinearVelocity(b2Vec2(theBall->GetLinearVelocity().x + randy, -BALL_VELOCITY));
        NSLog(@"Applying impulse %f to ball\n", BALL_VELOCITY);
        
    }
    
    // If the last collision test was positive,
    //  stop the ball and destroy the brick
    if (ballHitBrick)
    {
        theBall->SetLinearVelocity(b2Vec2(randy, -BALL_VELOCITY));
        theBall->SetAngularVelocity(0);
        world->DestroyBody(theBrick);
        theBrick = NULL;
        ballHitBrick = false;
    }
    
    if (ballHitBrick2)
    {
        theBall->SetLinearVelocity(b2Vec2(randy, -BALL_VELOCITY));
        theBall->SetAngularVelocity(0);
        world->DestroyBody(theBrick2);
        theBrick2 = NULL;
        ballHitBrick2 = false;
    }
    
    if (ballHitBrick3)
    {
        theBall->SetLinearVelocity(b2Vec2(randy, -BALL_VELOCITY));
        theBall->SetAngularVelocity(0);
        world->DestroyBody(theBrick3);
        theBrick3 = NULL;
        ballHitBrick3 = false;
    }
    
    if (ballHitPaddle)
    {
        theBall->SetLinearVelocity(b2Vec2(randy, BALL_VELOCITY));
        theBall->SetAngularVelocity(0);
        ballHitPaddle = false;
    }
    
    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }
    
    
    // Set up vertex arrays and buffers for the brick and ball here
    
    glEnable(GL_DEPTH_TEST);
    
    if (theBrick)
    {
#pragma mark - First Block
        glGenVertexArraysOES(1, &brickVertexArray);
        glBindVertexArrayOES(brickVertexArray);
        
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];
        int k = 0;
        numBrickVerts = 0;
        vertPos[k++] = theBrick->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol[numBrickVerts*3];
        for (k=0; k<numBrickVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
//        glBindVertexArrayOES(brickVertexArray);
//        if (theBrick && numBrickVerts > 0)
//            glDrawArrays(GL_TRIANGLES, 0, numBrickVerts);
    }
#pragma mark - Second Block
    if(theBrick2)
    {
        
        glGenVertexArraysOES(1, &brickVertexArray2);
        glBindVertexArrayOES(brickVertexArray2);
        
        GLuint vertexBuffers2[2];
        glGenBuffers(2, vertexBuffers2);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers2[0]);
        GLfloat vertPos2[18];
        int k = 0;
        numBrickVerts2 = 0;
        vertPos2[k++] = theBrick2->GetPosition().x - BRICK_WIDTH/2;
        vertPos2[k++] = theBrick2->GetPosition().y + BRICK_HEIGHT/2;
        vertPos2[k++] = 10;
        numBrickVerts2++;
        vertPos2[k++] = theBrick2->GetPosition().x + BRICK_WIDTH/2;
        vertPos2[k++] = theBrick2->GetPosition().y + BRICK_HEIGHT/2;
        vertPos2[k++] = 10;
        numBrickVerts2++;
        vertPos2[k++] = theBrick2->GetPosition().x + BRICK_WIDTH/2;
        vertPos2[k++] = theBrick2->GetPosition().y - BRICK_HEIGHT/2;
        vertPos2[k++] = 10;
        numBrickVerts2++;
        vertPos2[k++] = theBrick2->GetPosition().x - BRICK_WIDTH/2;
        vertPos2[k++] = theBrick2->GetPosition().y + BRICK_HEIGHT/2;
        vertPos2[k++] = 10;
        numBrickVerts2++;
        vertPos2[k++] = theBrick2->GetPosition().x + BRICK_WIDTH/2;
        vertPos2[k++] = theBrick2->GetPosition().y - BRICK_HEIGHT/2;
        vertPos2[k++] = 10;
        numBrickVerts2++;
        vertPos2[k++] = theBrick2->GetPosition().x - BRICK_WIDTH/2;
        vertPos2[k++] = theBrick2->GetPosition().y - BRICK_HEIGHT/2;
        vertPos2[k++] = 10;
        numBrickVerts2++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos2), vertPos2, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol2[numBrickVerts2*3];
        for (k=0; k<numBrickVerts2*3; k+=3)
        {
            vertCol2[k] = 1.0f;
            vertCol2[k+1] = 0.0f;
            vertCol2[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers2[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol2), vertCol2, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
//        glBindVertexArrayOES(brickVertexArray2);
//        if (theBrick2 && numBrickVerts2 > 0)
//            glDrawArrays(GL_TRIANGLES, 0, numBrickVerts2);
    }
#pragma mark - Third Block
    if(theBrick3)
    {
        glGenVertexArraysOES(1, &brickVertexArray3);
        glBindVertexArrayOES(brickVertexArray3);
        
        GLuint vertexBuffers3[2];
        glGenBuffers(2, vertexBuffers3);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers3[0]);
        GLfloat vertPos3[18];
        int k = 0;
        numBrickVerts3 = 0;
        vertPos3[k++] = theBrick3->GetPosition().x - BRICK_WIDTH/2;
        vertPos3[k++] = theBrick3->GetPosition().y + BRICK_HEIGHT/2;
        vertPos3[k++] = 10;
        numBrickVerts3++;
        vertPos3[k++] = theBrick3->GetPosition().x + BRICK_WIDTH/2;
        vertPos3[k++] = theBrick3->GetPosition().y + BRICK_HEIGHT/2;
        vertPos3[k++] = 10;
        numBrickVerts3++;
        vertPos3[k++] = theBrick3->GetPosition().x + BRICK_WIDTH/2;
        vertPos3[k++] = theBrick3->GetPosition().y - BRICK_HEIGHT/2;
        vertPos3[k++] = 10;
        numBrickVerts3++;
        vertPos3[k++] = theBrick3->GetPosition().x - BRICK_WIDTH/2;
        vertPos3[k++] = theBrick3->GetPosition().y + BRICK_HEIGHT/2;
        vertPos3[k++] = 10;
        numBrickVerts3++;
        vertPos3[k++] = theBrick3->GetPosition().x + BRICK_WIDTH/2;
        vertPos3[k++] = theBrick3->GetPosition().y - BRICK_HEIGHT/2;
        vertPos3[k++] = 10;
        numBrickVerts3++;
        vertPos3[k++] = theBrick3->GetPosition().x - BRICK_WIDTH/2;
        vertPos3[k++] = theBrick3->GetPosition().y - BRICK_HEIGHT/2;
        vertPos3[k++] = 10;
        numBrickVerts3++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos3), vertPos3, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol3[numBrickVerts3*3];
        for (k=0; k<numBrickVerts3*3; k+=3)
        {
            vertCol3[k] = 1.0f;
            vertCol3[k+1] = 0.0f;
            vertCol3[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers3[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol3), vertCol3, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
//        glBindVertexArrayOES(brickVertexArray3);
//        if (theBrick3 && numBrickVerts3 > 0)
//            glDrawArrays(GL_TRIANGLES, 0, numBrickVerts3);
    }
#pragma mark - The Paddle
    if(thePaddle)
    {
        glGenVertexArraysOES(1, &paddleVertexArray);
        glBindVertexArrayOES(paddleVertexArray);
        
        GLuint paddleVertexBuffer[2];
        glGenBuffers(2, paddleVertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, paddleVertexBuffer[0]);
        GLfloat padVerts[18];
        int k = 0;
        paddleVerts = 0;
        padVerts[k++] = thePaddle->GetPosition().x - BRICK_WIDTH/2;
        padVerts[k++] = thePaddle->GetPosition().y + BRICK_HEIGHT/2;
        padVerts[k++] = 10;
        paddleVerts++;
        padVerts[k++] = thePaddle->GetPosition().x + BRICK_WIDTH/2;
        padVerts[k++] = thePaddle->GetPosition().y + BRICK_HEIGHT/2;
        padVerts[k++] = 10;
        paddleVerts++;
        padVerts[k++] = thePaddle->GetPosition().x + BRICK_WIDTH/2;
        padVerts[k++] = thePaddle->GetPosition().y - BRICK_HEIGHT/2;
        padVerts[k++] = 10;
        paddleVerts++;
        padVerts[k++] = thePaddle->GetPosition().x - BRICK_WIDTH/2;
        padVerts[k++] = thePaddle->GetPosition().y + BRICK_HEIGHT/2;
        padVerts[k++] = 10;
        paddleVerts++;
        padVerts[k++] = thePaddle->GetPosition().x + BRICK_WIDTH/2;
        padVerts[k++] = thePaddle->GetPosition().y - BRICK_HEIGHT/2;
        padVerts[k++] = 10;
        paddleVerts++;
        padVerts[k++] = thePaddle->GetPosition().x - BRICK_WIDTH/2;
        padVerts[k++] = thePaddle->GetPosition().y - BRICK_HEIGHT/2;
        padVerts[k++] = 10;
        paddleVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(padVerts), padVerts, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat paddleCol[paddleVerts*3];
        for (k=0; k<paddleVerts*3; k+=3)
        {
            paddleCol[k] = 1.0f;
            paddleCol[k+1] = 0.0f;
            paddleCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, paddleVertexBuffer[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(paddleCol), paddleCol, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        //        glBindVertexArrayOES(brickVertexArray3);
        //        if (theBrick3 && numBrickVerts3 > 0)
        //            glDrawArrays(GL_TRIANGLES, 0, numBrickVerts3);
    }

    
    if (theBall)
    {
        glGenVertexArraysOES(1, &ballVertexArray);
        glBindVertexArrayOES(ballVertexArray);
        
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[3*(BALL_SPHERE_SEGS+2)];
        int k = 0;
        vertPos[k++] = theBall->GetPosition().x;
        vertPos[k++] = theBall->GetPosition().y;
        vertPos[k++] = 0;
        numBallVerts = 1;
        for (int n=0; n<=BALL_SPHERE_SEGS; n++)
        {
            float const t = 2*M_PI*(float)n/(float)BALL_SPHERE_SEGS;
            vertPos[k++] = theBall->GetPosition().x + sin(t)*BALL_RADIUS;
            vertPos[k++] = theBall->GetPosition().y + cos(t)*BALL_RADIUS;
            vertPos[k++] = 0;
            numBallVerts++;
        }
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol[numBallVerts*3];
        for (k=0; k<numBallVerts*3; k+=3)
        {
            vertCol[k] = 0.0f;
            vertCol[k+1] = 1.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
       
        
        glBindVertexArrayOES(0);
    }
    
    // For now assume simple ortho projection since it's only 2D
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, 800, 0, 600, -10, 100);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

-(void)Render:(int)mvpMatPtr
{

    if (theBall)
        printf("Ball: (%5.3f,%5.3f)\t",
               theBall->GetPosition().x, theBall->GetPosition().y);
    if (theBrick)
        printf("Brick: (%5.3f,%5.3f)",
               theBrick->GetPosition().x, theBrick->GetPosition().y);
    if (theBrick2)
        printf("Brick2: (%5.3f,%5.3f)",
               theBrick2->GetPosition().x, theBrick2->GetPosition().y);
    if (theBrick3)
        printf("Brick3: (%5.3f,%5.3f)",
               theBrick3->GetPosition().x, theBrick3->GetPosition().y);
    printf("\n");
    if (thePaddle)
    printf("The Paddle: (%5.3f,%5.3f)",
           thePaddle->GetPosition().x, thePaddle->GetPosition().y);
    printf("\n");

    
    glClearColor(0, 0, 0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUniformMatrix4fv(mvpMatPtr, 1, 0, modelViewProjectionMatrix.m);
    
    // Bind each vertex array and call glDrawArrays
    //  for each of the ball and brick
    
    glBindVertexArrayOES(brickVertexArray);
    if (theBrick && numBrickVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts);
    
    glBindVertexArrayOES(brickVertexArray2);
    if (theBrick2 && numBrickVerts2 > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts2);
    
    glBindVertexArrayOES(brickVertexArray3);
    if (theBrick3 && numBrickVerts3 > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts3);
    
    glBindVertexArrayOES(paddleVertexArray);
    if (thePaddle && paddleVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, paddleVerts);
    
    glBindVertexArrayOES(ballVertexArray);
    if (theBall && numBallVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBallVerts);
    glBindVertexArrayOES(0);
}

-(void)RegisterHit
{
    // Set some flag here for processing later...
    ballHitBrick = true;
}

-(void)RegisterHit2
{
    // Set some flag here for processing later...
    ballHitBrick2 = true;
}

-(void)RegisterHit3
{
    // Set some flag here for processing later...
    ballHitBrick3 = true;
}

-(void)LaunchBall
{
    // Set some flag here for processing later...
    ballLaunched = true;
}

-(void)PaddleHit
{
    ballHitPaddle = true;
}

-(void)moveBall:(CGPoint)x
{
    paddlex += x.x/1000;
    thePaddle->SetTransform(b2Vec2(paddlex + thePaddle->GetPosition().x, thePaddle->GetPosition().y), 0);
    
    if (paddlex + thePaddle->GetPosition().x < 50) {
        thePaddle->SetTransform(b2Vec2(50, thePaddle->GetPosition().y), 0);
    }
    
    if (paddlex + thePaddle->GetPosition().x > 550) {
        thePaddle->SetTransform(b2Vec2(550, thePaddle->GetPosition().y), 0);
    }
    
    NSLog(@"MOVSDNG");
    
}

-(void)HelloWorld
{
//    groundBodyDef = new b2BodyDef;
//    groundBodyDef->position.Set(0.0f, -10.0f);
//    groundBody = world->CreateBody(groundBodyDef);
//    groundBox = new b2PolygonShape;
//    groundBox->SetAsBox(50.0f, 10.0f);
//    
//    groundBody->CreateFixture(groundBox, 0.0f);
//    
//    // Define the dynamic body. We set its position and call the body factory.
//    b2BodyDef bodyDef;
//    bodyDef.type = b2_dynamicBody;
//    bodyDef.position.Set(0.0f, 4.0f);
//    b2Body* body = world->CreateBody(&bodyDef);
//    
//    // Define another box shape for our dynamic body.
//    b2PolygonShape dynamicBox;
//    dynamicBox.SetAsBox(1.0f, 1.0f);
//    
//    // Define the dynamic body fixture.
//    b2FixtureDef fixtureDef;
//    fixtureDef.shape = &dynamicBox;
//    
//    // Set the box density to be non-zero, so it will be dynamic.
//    fixtureDef.density = 1.0f;
//    
//    // Override the default friction.
//    fixtureDef.friction = 0.3f;
//    
//    // Add the shape to the body.
//    body->CreateFixture(&fixtureDef);
//    
//    // Prepare for simulation. Typically we use a time step of 1/60 of a
//    // second (60Hz) and 10 iterations. This provides a high quality simulation
//    // in most game scenarios.
//    float32 timeStep = 1.0f / 60.0f;
//    int32 velocityIterations = 6;
//    int32 positionIterations = 2;
//    
//    // This is our little game loop.
//    for (int32 i = 0; i < 60; ++i)
//    {
//        // Instruct the world to perform a single step of simulation.
//        // It is generally best to keep the time step and iterations fixed.
//        world->Step(timeStep, velocityIterations, positionIterations);
//        
//        // Now print the position and angle of the body.
//        b2Vec2 position = body->GetPosition();
//        float32 angle = body->GetAngle();
//        
//        printf("%4.2f %4.2f %4.2f\n", position.x, position.y, angle);
//    }
}

@end
