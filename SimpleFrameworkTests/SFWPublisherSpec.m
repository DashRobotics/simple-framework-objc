//
//  SFWPublisherSpec.m
//  simple-framework-obj
//
//  Created by Jose Rojas on 8/16/15.
//  Copyright 2015 Jose Rojas, Redline Solutions, LLC. All rights reserved.
//

#import "Specta.h"
#import "SFWPublisher.h"
#import "SFWTaskQueue.h"
#import <Expecta/Expecta.h>

@protocol SFWPublisherSpecTestProto

- (void) test;

@end

@protocol SFWPublisherSpecTestProto2

- (void) test2: (NSArray *) array;
- (void) test2: (NSArray *) array withInt: (int) value;

@end

@protocol SFWPublisherSpecTestProto3

- (void) test3: (NSArray *) array;

@end

@protocol SFWPublisherSpecTestProtoOptional

@optional
- (void) testOptional: (NSArray *) array;

@end


@interface SFWPublisherSpecTestEmitter : SFWPublisher

@end

@implementation SFWPublisherSpecTestEmitter

- (NSArray *)subscribeKeys {
    return @[
        @protocol(SFWPublisherSpecTestProto),
        @protocol(SFWPublisherSpecTestProto2)
    ];
}

- (void) publish {
    id<SFWPublisherSpecTestProto> publisher = [self publisherForObserversUsing:@protocol(SFWPublisherSpecTestProto)];

    [publisher test];

    id<SFWPublisherSpecTestProto2> publisher2 = [self publisherForObserversUsing:@protocol(SFWPublisherSpecTestProto2)];

    [publisher2 test2:[NSArray new]];
    [publisher2 test2:[NSArray new] withInt:1];
}

- (void) publishToQueue: (SFWTaskQueue *) queue {
    [self publishToObserversUsing:@protocol(SFWPublisherSpecTestProto) queue: queue block:^(id<SFWPublisherSpecTestProto> publisher){
        [publisher test];
    }];

    [self publishToObserversUsing:@protocol(SFWPublisherSpecTestProto2) queue: queue block:^(id<SFWPublisherSpecTestProto2> publisher){
        [publisher test2:[NSArray new]];
        [publisher test2:[NSArray new] withInt:1];
    }];
}

@end


@interface SFWPublisherSpecTestEmitter2 : SFWPublisher

@end

@implementation SFWPublisherSpecTestEmitter2

- (NSArray *)subscribeKeys {
    return @[
        @protocol(SFWPublisherSpecTestProtoOptional)
    ];
}

- (void) publishOptional {
    [self publishToObserversUsing:@protocol(SFWPublisherSpecTestProtoOptional) block:^(id<SFWPublisherSpecTestProtoOptional> publisher){
        [publisher testOptional:[NSArray new]];
    }];
}

@end


@interface SFWPublisherSpecTestReceiver : NSObject<
        SFWPublisherSpecTestProto,
        SFWPublisherSpecTestProto2,
        SFWPublisherSpecTestProto3,
        SFWPublisherSpecTestProtoOptional
        >

@property int testCalled;
@property int test2Called;
@property int test2withIntCalled;
@property int test3Called;

@end

@implementation SFWPublisherSpecTestReceiver

- (void)test {
    self.testCalled++;
}

- (void)test2:(NSArray *)array {
    self.test2Called++;
    expect(array).to.beTruthy();
}

- (void)test2:(NSArray *)array withInt:(int)value {
    self.test2withIntCalled++;
    expect(array).to.beTruthy();
    expect(value).to.beTruthy();
}

- (void)test3:(NSArray *)array {
    self.test3Called++;
}

@end

@interface SFWPublisherSpecTestReceiverOptional : NSObject<
        SFWPublisherSpecTestProto,
        SFWPublisherSpecTestProtoOptional
        >

@property int testOptionalCalled;

@end

@implementation SFWPublisherSpecTestReceiverOptional

- (void)testOptional:(NSArray *)array {
    self.testOptionalCalled++;
    expect(array).to.beTruthy();
}

@end

SpecBegin(SFWPublisher)

describe(@"SFWPublisher", ^{

    SFWPublisherSpecTestEmitter* emitter = [SFWPublisherSpecTestEmitter new];
    SFWPublisherSpecTestEmitter2 * emitter2 = [SFWPublisherSpecTestEmitter2 new];
    SFWPublisherSpecTestReceiver * receiver = [SFWPublisherSpecTestReceiver new];
    SFWPublisherSpecTestReceiver * receiver2 = [SFWPublisherSpecTestReceiver new];
    SFWPublisherSpecTestReceiverOptional * receiverOptional = [SFWPublisherSpecTestReceiverOptional new];


    beforeAll(^{

    });
    
    beforeEach(^{

    });
    
    it(@"should subscribe receivers only to protocols defined in 'subscribeKeys' method.", ^{

        expect(receiver.testCalled).to.equal(0);
        expect(receiver.test2Called).to.equal(0);
        expect(receiver.test2withIntCalled).to.equal(0);
        expect(receiver.test3Called).to.equal(0);

        [emitter subscribeObserver:receiver];
        [emitter publish];

        expect(receiver.testCalled).to.equal(1);
        expect(receiver.test2Called).to.equal(1);
        expect(receiver.test2withIntCalled).to.equal(1);
        expect(receiver.test3Called).to.equal(0);

    });

    it(@"should subscribe multiple receivers.", ^{

        expect(receiver.testCalled).to.equal(1);
        expect(receiver.test2Called).to.equal(1);
        expect(receiver.test2withIntCalled).to.equal(1);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(0);
        expect(receiver2.test2Called).to.equal(0);
        expect(receiver2.test2withIntCalled).to.equal(0);
        expect(receiver2.test3Called).to.equal(0);

        [emitter subscribeObserver:receiver2];
        [emitter publish];

        expect(receiver.testCalled).to.equal(2);
        expect(receiver.test2Called).to.equal(2);
        expect(receiver.test2withIntCalled).to.equal(2);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(1);
        expect(receiver2.test2Called).to.equal(1);
        expect(receiver2.test2withIntCalled).to.equal(1);
        expect(receiver2.test3Called).to.equal(0);

    });

    it(@"should not call methods for unsubscribed receivers.", ^{

        expect(receiver.testCalled).to.equal(2);
        expect(receiver.test2Called).to.equal(2);
        expect(receiver.test2withIntCalled).to.equal(2);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(1);
        expect(receiver2.test2Called).to.equal(1);
        expect(receiver2.test2withIntCalled).to.equal(1);
        expect(receiver2.test3Called).to.equal(0);

        [emitter unsubscribeObserver:receiver];
        [emitter publish];

        expect(receiver.testCalled).to.equal(2);
        expect(receiver.test2Called).to.equal(2);
        expect(receiver.test2withIntCalled).to.equal(2);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(2);
        expect(receiver2.test2Called).to.equal(2);
        expect(receiver2.test2withIntCalled).to.equal(2);
        expect(receiver2.test3Called).to.equal(0);

    });

    it(@"should function when there are no subscribed receivers.", ^{

        expect(receiver.testCalled).to.equal(2);
        expect(receiver.test2Called).to.equal(2);
        expect(receiver.test2withIntCalled).to.equal(2);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(2);
        expect(receiver2.test2Called).to.equal(2);
        expect(receiver2.test2withIntCalled).to.equal(2);
        expect(receiver2.test3Called).to.equal(0);

        [emitter unsubscribeObserver:receiver2];
        [emitter publish];

        expect(receiver.testCalled).to.equal(2);
        expect(receiver.test2Called).to.equal(2);
        expect(receiver.test2withIntCalled).to.equal(2);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(2);
        expect(receiver2.test2Called).to.equal(2);
        expect(receiver2.test2withIntCalled).to.equal(2);
        expect(receiver2.test3Called).to.equal(0);

    });

    it(@"should publish delegated methods on a different queue.", ^{

        expect(receiver.testCalled).to.equal(2);
        expect(receiver.test2Called).to.equal(2);
        expect(receiver.test2withIntCalled).to.equal(2);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(2);
        expect(receiver2.test2Called).to.equal(2);
        expect(receiver2.test2withIntCalled).to.equal(2);
        expect(receiver2.test3Called).to.equal(0);

        [emitter subscribeObserver:receiver];
        [emitter subscribeObserver:receiver2];
        [[SFWTaskQueue backgroundQueue] pause];
        [emitter publishToQueue:[SFWTaskQueue backgroundQueue]];

        expect(receiver.testCalled).to.equal(2);
        expect(receiver.test2Called).to.equal(2);
        expect(receiver.test2withIntCalled).to.equal(2);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(2);
        expect(receiver2.test2Called).to.equal(2);
        expect(receiver2.test2withIntCalled).to.equal(2);
        expect(receiver2.test3Called).to.equal(0);

        [[SFWTaskQueue backgroundQueue] resume];

        waitUntil(^(DoneCallback done) {

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                expect(receiver.testCalled).to.equal(3);
                expect(receiver.test2Called).to.equal(3);
                expect(receiver.test2withIntCalled).to.equal(3);
                expect(receiver.test3Called).to.equal(0);

                expect(receiver2.testCalled).to.equal(3);
                expect(receiver2.test2Called).to.equal(3);
                expect(receiver2.test2withIntCalled).to.equal(3);
                expect(receiver2.test3Called).to.equal(0);

                done();

            });

        });

    });

    it(@"should ignore multiple subscriptions of the same subscriber.", ^{

        expect(receiver.testCalled).to.equal(3);
        expect(receiver.test2Called).to.equal(3);
        expect(receiver.test2withIntCalled).to.equal(3);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(3);
        expect(receiver2.test2Called).to.equal(3);
        expect(receiver2.test2withIntCalled).to.equal(3);
        expect(receiver2.test3Called).to.equal(0);

        [emitter subscribeObserver:receiver];
        [emitter subscribeObserver:receiver];

        [emitter subscribeObserver:receiver2];
        [emitter subscribeObserver:receiver2];
        [emitter publish];

        expect(receiver.testCalled).to.equal(4);
        expect(receiver.test2Called).to.equal(4);
        expect(receiver.test2withIntCalled).to.equal(4);
        expect(receiver.test3Called).to.equal(0);

        expect(receiver2.testCalled).to.equal(4);
        expect(receiver2.test2Called).to.equal(4);
        expect(receiver2.test2withIntCalled).to.equal(4);
        expect(receiver2.test3Called).to.equal(0);

    });

    it(@"should not send messages to an observer that does not implement an optional protocol method.", ^{

        expect(receiverOptional.testOptionalCalled).to.equal(0);

        [emitter2 subscribeObserver:receiver];
        [emitter2 subscribeObserver:receiverOptional];

        [emitter2 publishOptional];

        expect(receiverOptional.testOptionalCalled).to.equal(1);

    });

    it(@"should throw an exception during publish when an observer does not implement a required protocol method.", ^{

        SFWPublisherSpecTestReceiverOptional* localReceiver = [SFWPublisherSpecTestReceiverOptional new];

        [emitter subscribeObserver:localReceiver];

        BOOL exceptionCaught = false;

        @try {
            [emitter publish];
        } @catch (NSException * ex) {
            expect(ex.name).to.equal(NSInvalidArgumentException);
            expect(ex.reason).to.contain(@"unrecognized selector");
            exceptionCaught = YES;
        }

        expect(exceptionCaught).to.beTruthy();

    });


    afterEach(^{

    });
    
    afterAll(^{

    });
});

SpecEnd
