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



#import <Foundation/Foundation.h>

@class SFWPublisherProxy;
@class SFWTaskQueue;
@protocol SFWPublisher;

typedef void (^SFWPublisherBlock_t)(id publisher);

extern void SFWPublisherSubscribe(id<SFWPublisher> publisher, id subscriber);
extern void SFWPublisherUnsubscribe(id<SFWPublisher> publisher, id subscriber);
extern id SFWPublisherWithProtocol(id<SFWPublisher> publisher, Protocol* proto);
extern void SFWPublisherPublishToObserversUsingProtocol(id<SFWPublisher> publisher, Protocol* proto, SFWPublisherBlock_t block);
extern void SFWPublisherPublishToObserversUsingProtocolAndQueue(id<SFWPublisher> publisher, Protocol* proto, SFWTaskQueue * queue, SFWPublisherBlock_t block);

@protocol SFWPublisher<NSObject>

@required
- (NSArray*) subscribeKeys;

@optional
- (void) subscribeObserver: (id) observer;
- (void) unsubscribeObserver: (id) observer;

- (id) publisherForObserversUsing: (Protocol *) proto;
- (void) publishToObserversUsing: (Protocol *) proto block: (SFWPublisherBlock_t) block;
- (void) publishToObserversUsing: (Protocol *) proto queue: (SFWTaskQueue *) queue block: (SFWPublisherBlock_t) block;

- (BOOL) onSubscribe: (id) observer key: (Protocol*) proto;
- (BOOL) onUnsubscribe: (id) observer key: (Protocol*) proto;

@end

@interface SFWPublisher : NSObject<SFWPublisher>

@end

@interface SFWTypedPublisher<T> : SFWPublisher

- (T) typedPublisherForObserversUsing: (Protocol *) proto;

@end
