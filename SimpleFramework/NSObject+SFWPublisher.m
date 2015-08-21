/*
The MIT License

Copyright (c) 2015 Jose Rojas, Redline Solutions, LLC.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#import <objc/runtime.h>
#import "SFWWeakRef.h"
#import "NSObject+SFWPublisher.h"
#import "SFWTaskQueue.h"

@interface SFWPublisherProxy : NSObject

@property NSMutableArray * observers;
@property NSMutableDictionary * selectorToSignature;

@end

@implementation SFWPublisherProxy

- (instancetype)initWithProtocol: (Protocol*) proto {
    self.observers = [NSMutableArray new];
    self.selectorToSignature = [NSMutableDictionary new];

    [self addProtocol:proto methods:YES];
    [self addProtocol:proto methods:NO];

    return self;
}

- (void) addProtocol: (Protocol *) proto methods: (BOOL) req {
    unsigned int count = 0;
    struct objc_method_description* list = protocol_copyMethodDescriptionList(proto, req, YES, &count);

    int i = 0;
    while (i < count)  {
        struct objc_method_description method = list[i];
        NSMethodSignature * theMethodSignature = [NSMethodSignature signatureWithObjCTypes:method.types];

        SEL sel = method.name;
        self.selectorToSignature[NSStringFromSelector(sel)] = theMethodSignature;

        i++;
    }

    free(list);
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {

    @synchronized (self) {
        for (SFWWeakRef *observer in self.observers) {
            [anInvocation invokeWithTarget:observer.value];
        }
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return self.selectorToSignature[NSStringFromSelector(aSelector)];
}

- (void) addObserver: (id)observer {
    @synchronized (self) {
        id objectToAdd = [SFWWeakRef weakRef:observer];
        if (![self.observers containsObject:objectToAdd])
            [self.observers addObject:objectToAdd];
    }
}

- (void) removeObserver: (id)observer {
    @synchronized (self) {
        [self.observers removeObject:[SFWWeakRef weakRef:observer]];
    }
}

@end


@implementation NSObject (SFWPublisher)

static const char* NSOBJECT_SFWPUBLISHER_DICT_KEY = "SFWPublisher_dict_key";

- (SFWPublisherProxy *)findPublisher: (Protocol *) proto {
    NSMutableDictionary * dict = objc_getAssociatedObject(self, NSOBJECT_SFWPUBLISHER_DICT_KEY);

    if (dict == nil) {
        dict = [NSMutableDictionary new];
        objc_setAssociatedObject(self, NSOBJECT_SFWPUBLISHER_DICT_KEY, dict, OBJC_ASSOCIATION_RETAIN);
    }

    NSString* key = NSStringFromProtocol(proto);
    SFWPublisherProxy * surrogate = dict[key];
    if (surrogate == nil) {
        dict[key] = surrogate = [[SFWPublisherProxy alloc] initWithProtocol:proto];
    }

    return surrogate;
}

- (void) subscribeObserver: (id) observer {

    if ([self respondsToSelector:@selector(subscribeKeys)]) {
        NSArray * protocols = [(id<SFWPublisher>) self subscribeKeys];

        for (Protocol* proto in protocols) {
            if ([observer conformsToProtocol:proto] &&
                [self onSubscribe:observer key:proto]) {
                SFWPublisherProxy * surrogate = [self findPublisher:proto];

                [surrogate addObserver:observer];
            }
        }
    }

}

- (void) unsubscribeObserver: (id) observer {

    if ([self respondsToSelector:@selector(subscribeKeys)]) {
        NSArray * protocols = [(id<SFWPublisher>) self subscribeKeys];

        for (Protocol* proto in protocols) {
            if ([observer conformsToProtocol:proto] &&
                [self onUnsubscribe:observer key:proto]) {
                SFWPublisherProxy * surrogate = [self findPublisher:proto];

                [surrogate removeObserver:observer];
            }
        }
    }

}

- (NSArray *)subscribeKeys {
    return nil;
}

- (id)publisherForObserversUsing:(Protocol *)proto {
    return [self findPublisher:proto];
}

- (void)publishToObserversUsing:(Protocol *)proto block:(SFWPublisherBlock_t)block {
    [self publishToObserversUsing:proto queue:nil block:block];
}

- (void)publishToObserversUsing:(Protocol *)proto queue:(SFWTaskQueue *)queue block:(SFWPublisherBlock_t)block {
    SFWPublisherProxy * publisher = [self findPublisher:proto];

    if (queue == nil)
        block(publisher);
    else
        [queue queueAsync:^{
            block(publisher);
        }];
}

- (BOOL)onSubscribe:(id)observer key:(Protocol *)proto {
    return YES;
}

- (BOOL)onUnsubscribe:(id)observer key:(Protocol *)proto {
    return YES;
}

@end