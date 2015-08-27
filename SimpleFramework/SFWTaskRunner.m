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

#import "SFWTask.h"
#import "SFWTaskRunner+Private.h"

static char* const CURRENT_RUNNER_KEY = "SFWTaskRunner.current";

@implementation SFWTaskRunner {

}

+ (instancetype)mainRunner {
    static SFWTaskRunner* mainQueue = nil;

    if (mainQueue == nil) {
        mainQueue = [[self alloc] initWithQueue:dispatch_get_main_queue()];
    }

    return mainQueue;
}

+ (instancetype)backgroundRunner {
    static SFWTaskRunner* backgroundQueue = nil;

    if (backgroundQueue == nil) {
        backgroundQueue = [[self alloc] initWithQueue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)];
    }

    return backgroundQueue;
}

+ (instancetype)currentRunner {
    return (__bridge id) dispatch_get_specific(CURRENT_RUNNER_KEY);
}

- (instancetype) initWithQueue: (dispatch_queue_t) queue {
    self = [self init];

    _queue = queue;

    return self;
}

- (SFWTask_t)scheduleAsync:(SFWRunBlock_t)block after:(NSTimeInterval)timeDelay {
    return [self scheduleAsyncTask:[[SFWTask alloc] initWithBlock:block] after: timeDelay];
}

- (SFWTask_t)scheduleAsync:(SFWRunBlock_t)block at:(NSTimeInterval)timeDelay {
    return [self scheduleAsyncTask:[[SFWTask alloc] initWithBlock:block] at: timeDelay];
}

- (SFWTask_t)scheduleAsyncTask:(SFWTask_t)task after: (NSTimeInterval) delay {

    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (dispatch_time_t) (NSEC_PER_SEC * delay));
    dispatch_after(when, _queue, ^{
        dispatch_queue_set_specific(_queue, CURRENT_RUNNER_KEY, (__bridge void*) self, NULL);
        [task run];
        dispatch_queue_set_specific(_queue, CURRENT_RUNNER_KEY, NULL, NULL);
    });

    return task;
}

- (SFWTask_t)scheduleAsyncTask:(SFWTask_t)task at: (NSTimeInterval) when {

    dispatch_after((dispatch_time_t) when, _queue, ^{
        [task run];
    });

    return task;
}

@end
