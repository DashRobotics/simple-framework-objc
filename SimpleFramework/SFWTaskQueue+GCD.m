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

#import "SFWTaskRunner.h"
#import "SFWTaskQueue.h"
#import <objc/runtime.h>

static char* const CURRENT_RUNNER_KEY = "SFWTaskRunner.current";
static char* const CURRENT_QUEUE_KEY = "SFWTaskQueue.current";

@interface SFWTask : NSObject <SFWTask>

@property (atomic, strong) SFWRunTaskBlock_t runBlock;

@end

@implementation SFWTask

- (instancetype)initWithBlock:(SFWRunBlock_t)block {
    self.runBlock = ^(SFWTask_t task) {
        block();
    };
    return self;
}

- (void)run {
    self.runBlock(self);
}

@end

@implementation SFWTaskRunner {
    dispatch_queue_t _queue;
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

- queue {
    return _queue;
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

@implementation SFWTaskQueue {
    NSMutableArray * _tasks;
    SFWTaskRunner * _runner;
    SFWTask_t _run;
    dispatch_group_t _group;
    bool _isScheduled;
}

+ (instancetype)mainQueue {
    static SFWTaskQueue * mainQueue = nil;

    if (mainQueue == nil) {
        mainQueue = [[self alloc] initWithRunner: [SFWTaskRunner mainRunner]];
    }

    return mainQueue;
}

+ (instancetype)backgroundQueue {
    static SFWTaskQueue * backgroundQueue = nil;

    if (backgroundQueue == nil) {
        backgroundQueue = [[self alloc] initWithRunner:[SFWTaskRunner backgroundRunner]];
    }

    return backgroundQueue;
}

+ (instancetype)currentQueue {
    return (__bridge id) dispatch_get_specific(CURRENT_QUEUE_KEY);
}

- (instancetype) initWithRunner: (SFWTaskRunner *) runner {
    self = [self init];

    __weak SFWTaskQueue* weakSelf = self;

    _group = dispatch_group_create();
    _tasks = [NSMutableArray array];
    _runner = runner;
    _run = [[SFWTask alloc] initWithBlock:^{
        SFWTaskQueue * queue = weakSelf;
        [queue doNext];
    }];

    return self;
}

- (void) runTask: (SFWTask*) task {
    dispatch_queue_set_specific(_runner.queue, CURRENT_QUEUE_KEY, (__bridge void*) self, NULL);

    task.runBlock(task);
    task.runBlock = nil;

    dispatch_queue_set_specific(_runner.queue, CURRENT_QUEUE_KEY, NULL, NULL);
}

- (void) doNext {
    @synchronized (self) {

        SFWTask *task = nil;
        NSNumber *after = nil;

        if (_tasks.count > 0) {
            NSDictionary *dict = _tasks.firstObject;
            task = dict[@"task"];
            after = dict[@"after"];
            [_tasks removeObjectAtIndex:0];
        }

        [self runTask:task];
        NSLog(@"doNext: task completed");

        if (_tasks.count > 0) {
            NSDictionary *dict = _tasks.firstObject;
            after = dict[@"after"];

            int32_t afterVal = after.intValue;
            if (afterVal >= 0) {
                dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * afterVal);
                NSLog(@"doNext: after %@, when %lld", after, when);
                [_runner scheduleAsyncTask:_run at: when];
            }
        } else {
            _isScheduled = NO;
            if (after.integerValue >= 0)
                dispatch_group_leave(_group);
        }

    }
}

- (SFWTask_t) addObject: (SFWTask_t) task after: (NSTimeInterval) after {

    if (after == -1) {
        dispatch_group_wait(_group, DISPATCH_TIME_FOREVER);
        @synchronized (self) {
            [self runTask:task];
        }
    } else {
        @synchronized (self) {
            [_tasks addObject:@{
                    @"task" : task, @"after" : @(after)
            }];

            if (!_isScheduled) {
                dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (dispatch_time_t) (NSEC_PER_SEC * after));
                [_runner scheduleAsyncTask:_run at:when];
                _isScheduled = YES;
                dispatch_group_enter(_group);
            }
        }
    }

    return task;
}

- (SFWTask_t)queue:(SFWRunBlock_t)block sync:(bool)bSync {
    return [self addObject: [[SFWTask alloc] initWithBlock:block ] after:bSync ? -1 : 0];
}

- (SFWTask_t)queueSync:(SFWRunBlock_t)block {
    return [self addObject: [[SFWTask alloc] initWithBlock:block ] after:-1];
}

- (SFWTask_t)queueAsync:(SFWRunBlock_t)block {
    return [self addObject: [[SFWTask alloc] initWithBlock:block ] after:0];
}

- (SFWTask_t)queueAsync:(SFWRunBlock_t)block after:(NSTimeInterval)timeDelay {
    return [self addObject:[[SFWTask alloc] initWithBlock:block ] after:timeDelay];
}

@end