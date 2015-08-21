//
//  SFWWeakRefSpec.m
//  simple-framework-obj
//
//  Created by Jose Rojas on 8/11/15.
//  Copyright 2015 Jose Rojas, Redline Solutions, LLC. All rights reserved.
//

#import "Specta.h"
#import "Expecta.h"
#import "SFWWeakRef.h"

SpecBegin(SFWWeakRef)

describe(@"SFWWeakRef", ^{

    it(@"should not have a nil value while reference is strongly held.", ^{

        SFWWeakRef* weakRef = nil;

        NSString* value = [NSString stringWithFormat:@"MyValue"];
        weakRef = [SFWWeakRef weakRef: value];

        expect(weakRef.value).to.beTruthy();

    });

    it(@"should have a nil value if reference is released.", ^{

        SFWWeakRef* weakRef = nil;

        @autoreleasepool {
            NSString* value = [NSString stringWithFormat:@"MyValue"];
            weakRef = [SFWWeakRef weakRef: value];
        }

        expect(weakRef.value).to.beFalsy();

    });

    it(@"should return true when comparing values with isEqual: ", ^{

        SFWWeakRef* weakRef = nil;

        NSString* value = [NSString stringWithFormat:@"MyValue"];
        weakRef = [SFWWeakRef weakRef: value];

        expect([weakRef isEqual:value]).to.beTruthy();

    });

    it(@"should return false when comparing incorrect values with isEqual: ", ^{

        SFWWeakRef* weakRef = nil;

        NSString* value = [NSString stringWithFormat:@"MyValue"];
        weakRef = [SFWWeakRef weakRef: value];

        expect([weakRef isEqual:@"MyValue2"]).to.beFalsy();

    });

    it(@"should return correct values when comparing two weak refs with isEqual: ", ^{

        SFWWeakRef* weakRef = nil;

        NSString* value = [NSString stringWithFormat:@"MyValue"];
        weakRef = [SFWWeakRef weakRef: value];
        SFWWeakRef * weakRef2 = [SFWWeakRef weakRef: value];
        SFWWeakRef * weakRef3 = [SFWWeakRef weakRef: @"MyValue2"];

        expect([weakRef isEqual:weakRef2]).to.beTruthy();
        expect([weakRef isEqual:weakRef3]).to.beFalsy();

    });


});

SpecEnd
