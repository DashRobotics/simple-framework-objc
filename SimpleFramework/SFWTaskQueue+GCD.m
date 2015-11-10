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

#import "SFWTaskRunner+Private.h"
#import "SFWTaskQueue.h"
#import <objc/runtime.h>

static char* const CURRENT_QUEUE_KEY = "SFWTaskQueue.current";


@implementation SFWTaskQueue {
    NSMutableArray * _tasks;
    SFWTaskRunner * _runner;
    SFWTask_t _run;
    dispatch_group_t _group;
    bool _isScheduled;
    bool _isPaused;
    SFWTask_t _needsRescheduledAfterPause;
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

- (instancetype) initWithName: (NSString*) name {

    dispatch_queue_t queue = dispatch_queue_create([name cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_CONCURRENT);
    SFWTaskRunner* runner = [[SFWTaskRunner alloc] initWithQueue: queue];

    return [self initWithRunner:runner];
}

- (instancetype) initWithRunner: (SFWTaskRunner *) runner {
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

- (void) runTask: (SFWTask_t) task {
    dispatch_queue_set_specific(_runner.queue, CURRENT_QUEUE_KEY, (__bridge void*) self, NULL);

    [task run];

    dispatch_queue_set_specific(_runner.queue, CURRENT_QUEUE_KEY, NULL, NULL);
}

- (void) doNext {

    BOOL bRunTask = NO;
    SFWTask *task = nil;
    NSNumber *at = nil;

    @synchronized (self) {

        if (!_isPaused) {


            if (_tasks.count > 0) {
                NSDictionary *dict = _tasks.firstObject;
                task = dict[@"task"];
                at = dict[@"at"];
                [_tasks removeObjectAtIndex:0];
            }

            bRunTask = YES;

        } else {
            _needsRescheduledAfterPause = _run;
        }

    }

    if (bRunTask) {
        [self runTask:task];
        //NSLog(@"doNext: task completed");

        @synchronized (self) {
            if (_tasks.count > 0) {
                NSDictionary *dict = _tasks.firstObject;
                at = dict[@"at"];

                float atVal = at.floatValue;
                if (atVal >= 0) {
                    dispatch_time_t when = dispatch_time((dispatch_time_t) (NSEC_PER_SEC * atVal), 0);
                    //NSLog(@"doNext: after %@, when %lld", after, when);
                    [_runner scheduleAsyncTask:_run at:when];
                }
            } else {
                _isScheduled = NO;
                if (at.integerValue >= 0)
                    dispatch_group_leave(_group);
            }
        }
    }
}

- (SFWTask_t) addObject: (SFWTask_t) task after: (NSTimeInterval) after {

    NSTimeInterval at = 0;
    if (after == -1) {
        [self addObject:task at:after];
    } else {
        @synchronized (self) {
            //get last value
            NSDictionary* dict = [_tasks lastObject];
            if (dict) {
                NSNumber* nextAt = dict[@"at"];
                at = nextAt.floatValue + after;
            } else {
                at = (NSTimeInterval) dispatch_time(DISPATCH_TIME_NOW, 0) / NSEC_PER_SEC;
                at += after;
            }
        }
        [self addObject:task at:at];
    }

    return task;
}

- (SFWTask_t) addObject: (SFWTask_t) task at: (NSTimeInterval) at {

    if (at == -1) {
        dispatch_group_wait(_group, DISPATCH_TIME_FOREVER);
        bool bRunTask = NO;
        @synchronized (self) {
            if (!_isPaused) {
                bRunTask = YES;
            } else {
                _needsRescheduledAfterPause = task;
            }
        }
        if (bRunTask)
            [self runTask:task];
    } else {
        @synchronized (self) {
            //insertion sort
            NSUInteger index = 0;
            for (NSDictionary * dict in _tasks) {
                NSNumber* nextAt = dict[@"at"];
                if (nextAt.floatValue > at) {
                    break;
                }
                index++;
            }
            if (index >= _tasks.count) {
                [_tasks addObject:@{
                        @"task" : task, @"at" : @(at)
                }];
            } else {
                [_tasks insertObject:@{
                        @"task" : task, @"at" : @(at)
                } atIndex:index];
            }

            if (!_isScheduled) {
                dispatch_time_t when = dispatch_time((dispatch_time_t) (at * NSEC_PER_SEC), 0);
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

- (SFWTask_t)queueAsync:(SFWRunBlock_t)block at:(NSTimeInterval)timeDelay {
    return [self addObject:[[SFWTask alloc] initWithBlock:block ] at:timeDelay];
}


- (void)pause {
    @synchronized (self) {
        _isPaused = YES;
    }
}

- (void)resume {
    @synchronized (self) {
        _isPaused = NO;
        if (_isScheduled && _needsRescheduledAfterPause) {
            SFWTask_t task = _needsRescheduledAfterPause;
            _needsRescheduledAfterPause = nil;
            dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 0);
            [_runner scheduleAsyncTask:task at:when];
        }
    }
}

@end