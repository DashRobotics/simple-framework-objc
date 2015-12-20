//
//  SFWRealTimeThreadSpec.m
//  simple-framework-obj
//
//  Created by Jose Rojas on 12/19/15.
//  Copyright 2015 Jose Rojas, Redline Solutions, LLC. All rights reserved.
//

#import "Specta.h"
#import "SFWRealTimeThread.h"
#import "NSObject+TaskQueue.h"
#import <Expecta/Expecta.h>
#import <pthread.h>
#import <mach/mach_time.h>

typedef void (^SFWRealTimeThreadRunBlock)();

@interface SFWRealTimeThreadTest : NSObject

@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL performed;
@property (nonatomic, assign) uint64_t runTime1;
@property (nonatomic, assign) uint64_t runTime2;

@end

@implementation SFWRealTimeThreadTest

- (void) testRun {
    self.running = YES;
}

- (void) performOnThread: (NSThread*) thread {

    expect([NSThread currentThread]).to.equal(thread);

    self.performed = YES;
}

- (void) performOnMain: (SFWRealTimeThreadRunBlock) block {

    [self performSelector:@selector(performBlock:) withObject:block afterDelay:1.0];

}

- (void) performBlock: (SFWRealTimeThreadRunBlock) block {
    block();
}

- (void) performRunTime1: (SFWRealTimeThread *) thread {
    self.runTime1 = mach_absolute_time();

    [self performSelector:@selector(performRunTime2) withObject:nil afterDelay:thread.sleepInterval / 2];
}

- (void) performRunTime2 {
    self.runTime2 = mach_absolute_time();
}


@end


SpecBegin(SFWRealTimeThread)

describe(@"SFWRealTimeThread", ^{

    __block SFWRealTimeThread * thread;
    SFWRealTimeThreadTest* testobj = [SFWRealTimeThreadTest new];

    beforeAll(^{

    });
    
    beforeEach(^{

    });
    
    it(@"should create a new unstarted thread.", ^{

        thread = [[SFWRealTimeThread alloc] initWithTarget:testobj selector:@selector(testRun) object:nil];
        expect(thread).to.beTruthy();
        expect(thread.executing).to.beFalsy();
        expect(testobj.running).to.beFalsy();

        expect(pthread_self()).to.beTruthy();

    });

    it(@"should start the thread and call the target.", ^{

        waitUntil(^(DoneCallback done){

           [thread start];

           [testobj performSelectorOnMainThread:@selector(performOnMain:) withObject:^{
               expect(thread.executing).to.beTruthy();
               expect(testobj.running).to.beTruthy();

               done();
           } waitUntilDone:NO];

        });

    });

    it(@"should perform selector asynchronously on the thread.", ^{

        waitUntil(^(DoneCallback done){

            expect(testobj.performed).to.beFalsy();

            [testobj performSelector:@selector(performOnThread:) onThread:thread withObject:thread waitUntilDone:NO];

            [testobj performSelectorOnMainThread:@selector(performOnMain:) withObject:^{
                expect(thread.executing).to.beTruthy();
                expect(testobj.performed).to.beTruthy();

                done();
            } waitUntilDone:NO];
        });

    });

    it(@"should perform executions within 500 micro seconds tolerance.", ^{

        waitUntil(^(DoneCallback done){

            [testobj performSelector:@selector(performRunTime1:) onThread:thread withObject:thread waitUntilDone:NO];

            [testobj performSelectorOnMainThread:@selector(performOnMain:) withObject:^{

                mach_timebase_info_data_t timebase_info;
                mach_timebase_info(&timebase_info);

                uint64_t value = (uint64_t) (thread.sleepInterval * NSEC_PER_SEC) * timebase_info.denom / timebase_info.numer;
                //tolerance is defined by Apple's recommendation
                //https://developer.apple.com/library/ios/technotes/tn2169/_index.html
                uint64_t tolerance = (uint64_t) (0.0005 * NSEC_PER_SEC) * timebase_info.denom / timebase_info.numer;

                expect(thread.executing).to.beTruthy();
                expect(testobj.runTime2 - testobj.runTime1).to.beGreaterThanOrEqualTo(value);
                expect(testobj.runTime2 - testobj.runTime1).to.beLessThanOrEqualTo(value + tolerance);

                done();
            } waitUntilDone:NO];
        });

    });


    afterEach(^{

    });
    
    afterAll(^{

    });
});

SpecEnd
