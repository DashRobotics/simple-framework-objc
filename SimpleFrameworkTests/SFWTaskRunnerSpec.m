//
//  SFWTaskRunnerSpec.m
//  simple-framework-obj
//
//  Created by Jose Rojas on 8/20/15.
//  Copyright 2015 Jose Rojas, Redline Solutions, LLC. All rights reserved.
//

#import "Specta.h"
#import "Expecta.h"
#import "SFWTaskRunner.h"


SpecBegin(SFWTaskRunner)

describe(@"SFWTaskRunner", ^{
    
    beforeAll(^{

    });
    
    beforeEach(^{

    });

    it(@"should run blocks asynchronously in the future using 'scheduleAsync:after:'.", ^{

        __block int runOrder = 0;

        waitUntilTimeout(2.5, ^(DoneCallback done) {

            dispatch_time_t then = dispatch_time(DISPATCH_TIME_NOW, 0);

            [[SFWTaskRunner backgroundRunner] scheduleAsync:^{

                dispatch_time_t now = dispatch_time(DISPATCH_TIME_NOW, 0);

                expect(now - then).to.beGreaterThan(2 * NSEC_PER_SEC);
                expect(runOrder).to.equal(2);
                runOrder++;

                done();

            }                                   after:2];

            [[SFWTaskRunner backgroundRunner] scheduleAsync:^{

                dispatch_time_t now = dispatch_time(DISPATCH_TIME_NOW, 0);

                expect(now - then).to.beGreaterThan(1 * NSEC_PER_SEC);
                expect(runOrder).to.equal(1);
                runOrder++;

            }                                   after:1];

            runOrder++;
        });

    });

    afterEach(^{

    });
    
    afterAll(^{

    });
});

SpecEnd
