//
//  SFWRunQueueSpec+CGD.m
//  simple-framework-obj
//
//  Created by Jose Rojas on 8/11/15.
//  Copyright 2015 Jose Rojas, Redline Solutions, LLC. All rights reserved.
//

#import "Specta.h"
#import "SFWTaskQueue.h"
#import "Expecta.h"


SpecBegin(SFWRunQueue)

describe(@"SFWTaskQueue", ^{

    it(@"should have .mainQueue tasks running on the main queue.", ^{

        waitUntil(^(DoneCallback done) {

            __block int runOrder = 0;

            dispatch_async(dispatch_get_main_queue(), ^{

                dispatch_queue_set_specific(dispatch_get_main_queue(), "TEST", "TEST", NULL);

                expect(runOrder).to.equal(0);
                runOrder++;

            });

            expect(runOrder).to.equal(0);

            [[SFWTaskQueue mainQueue] queueAsync:^{

                expect(strcmp(dispatch_get_specific("TEST"), "TEST")).to.equal(0);

                expect(runOrder).to.equal(1);
                runOrder++;

                done();
            }];

            expect(runOrder).to.equal(0);


        });

    });

    it(@"should have .backgroundQueue tasks running not on the main queue.", ^{

        waitUntil(^(DoneCallback done) {

            __block int runOrder = 0;

            expect([SFWTaskQueue mainQueue]).notTo.equal([SFWTaskQueue backgroundQueue]);

            dispatch_queue_set_specific(dispatch_get_main_queue(), "TEST", "TEST", NULL);

            [[SFWTaskQueue backgroundQueue] queueAsync:^{

                expect(dispatch_get_specific("TEST")).to.beFalsy();

                expect(runOrder).to.equal(1);
                runOrder++;

                done();
            }];

            expect(runOrder).to.equal(0);
            runOrder++;


        });

    });

    it(@"should have .currentQueue match the queue that is currently running.", ^{

        [[SFWTaskQueue backgroundQueue] queueAsync:^{

            expect([SFWTaskQueue currentQueue]).to.equal([SFWTaskQueue backgroundQueue]);

        }];

        [[SFWTaskQueue mainQueue] queueAsync:^{

            expect([SFWTaskQueue currentQueue]).to.equal([SFWTaskQueue mainQueue]);

        }];

    });

    it(@"should run synchronously on the backgroundQueue, waiting for asynchonous blocks to complete.", ^{

        __block int runOrder = 0;

        waitUntilTimeout(5.1, ^(DoneCallback done){

            dispatch_time_t then = dispatch_time(DISPATCH_TIME_NOW, 0);

            [[SFWTaskQueue backgroundQueue] queueAsync:^{

                dispatch_time_t now = dispatch_time(DISPATCH_TIME_NOW, 0);
                expect(now - then).to.beGreaterThan(5 * NSEC_PER_SEC);
                expect(runOrder).to.equal(0);
                runOrder++;

            } after: 5];

            expect(runOrder).to.equal(0);

            [[SFWTaskQueue backgroundQueue] queueSync:^{

                expect(runOrder).to.equal(1);
                runOrder++;

            }];

            expect(runOrder).to.equal(2);
            runOrder++;

            done();
        });

    });

    it(@"should run blocks asynchronously in the future using 'queueAsync:after:'.", ^{

        __block int runOrder = 0;

        waitUntilTimeout(5.1, ^(DoneCallback done) {

            dispatch_time_t then = dispatch_time(DISPATCH_TIME_NOW, 0);

            [[SFWTaskQueue backgroundQueue] queueAsync:^{

                dispatch_time_t now = dispatch_time(DISPATCH_TIME_NOW, 0);

                expect(now - then).to.beGreaterThan(4 * NSEC_PER_SEC);
                expect(runOrder).to.equal(1);
                runOrder++;

                done();

            }                                   after:4];

            [[SFWTaskQueue backgroundQueue] queueAsync:^{

                dispatch_time_t now = dispatch_time(DISPATCH_TIME_NOW, 0);

                expect(now - then).to.beGreaterThan(5 * NSEC_PER_SEC);
                expect(runOrder).to.equal(2);
                runOrder++;

            }                                   after:1];

            runOrder++;
        });

    });

    it(@"should run blocks asynchronously in the future relative to the last queued block with 'after:'.", ^{

        __block int runOrder = 0;

        waitUntilTimeout(4.1, ^(DoneCallback done) {

            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0);

            [[SFWTaskQueue backgroundQueue] queueAsync:^{

                expect(runOrder).to.equal(1);
                runOrder++;

                done();

            }                                   after:2];

            [[SFWTaskQueue backgroundQueue] queueAsync:^{

                expect(runOrder).to.equal(2);
                runOrder++;

            }                                   after:1];

            [[SFWTaskQueue backgroundQueue] queueAsync:^{

                expect(runOrder).to.equal(3);
                runOrder++;

                dispatch_time_t timeNow = dispatch_time(DISPATCH_TIME_NOW, 0);

                expect(timeNow - time).to.beGreaterThanOrEqualTo(NSEC_PER_SEC * 4);

                done();

            } after: 1];

            runOrder++;
        });

    });

    it(@"should create a new queue.", ^{

        SFWTaskQueue* queue = [[SFWTaskQueue alloc] initWithName:@"myqueue"];

        expect(queue).toNot.equal([SFWTaskQueue backgroundQueue]);
        expect(queue).toNot.equal([SFWTaskQueue mainQueue]);
        expect(queue).toNot.equal([SFWTaskQueue currentQueue]);

        waitUntilTimeout(3, ^(DoneCallback done) {

            __block int num = 0;

            [[SFWTaskQueue backgroundQueue] queueAsync:^{
                num++;
            } after:1];

            [[SFWTaskQueue mainQueue] queueAsync:^{
                num++;
                done();
            } after:2];

            //this one should execute before the other two because it is not on the same queue
            [queue queueAsync:^{
                num++;
                expect(num).to.equal(1);
            } after:0];

        });

    });

    it(@"should block a queue using 'pause' and unblock a queue using 'resume'.", ^{

        SFWTaskQueue* queue = [[SFWTaskQueue alloc] initWithName:@"myqueue"];

        waitUntilTimeout(4, ^(DoneCallback done) {

            __block int num = 0;

            //this one should execute before the other queue even though it is scheduled later because
            //the queue is paused until this block resumes it.
            [[SFWTaskQueue backgroundQueue] queueAsync:^{
                num++;
                expect(num).to.equal(1);
                [queue resume];
            } after:2];

            [queue pause];

            [queue queueAsync:^{
                num++;
                expect(num).to.equal(2);
                done();
            } after:0];

        });

    });

});

SpecEnd
