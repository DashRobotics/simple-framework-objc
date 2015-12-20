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

#import "SFWRealTimeThread.h"
#import <pthread.h>
#include <mach/mach.h>
#include <mach/mach_time.h>

static const uint64_t NANOS_PER_USEC = 1000ULL;
static const uint64_t NANOS_PER_MILLISEC = 1000ULL * NANOS_PER_USEC;
static const uint64_t NANOS_PER_SEC = 1000ULL * NANOS_PER_MILLISEC;

static const NSTimeInterval kMinSleepInterval = 0.00001;

@implementation SFWRealTimeThread {
    BOOL _isExecuting;
    BOOL _isFinished;
    NSRunLoop * _runLoop;
}

void move_pthread_to_realtime_scheduling_class(pthread_t pthread)
{
    mach_timebase_info_data_t timebase_info;
    mach_timebase_info(&timebase_info);

    const uint64_t NANOS_PER_MSEC = 1000000ULL;
    double clock2abs = ((double)timebase_info.denom / (double)timebase_info.numer) * NANOS_PER_MSEC;

    thread_time_constraint_policy_data_t policy;
    policy.period      = 0;
    policy.computation = (uint32_t)(5 * clock2abs); // 5 ms of work
    policy.constraint  = (uint32_t)(10 * clock2abs);
    policy.preemptible = FALSE;

    int kr = thread_policy_set(pthread_mach_thread_np(pthread_self()),
            THREAD_TIME_CONSTRAINT_POLICY,
            (thread_policy_t)&policy,
            THREAD_TIME_CONSTRAINT_POLICY_COUNT);
    if (kr != KERN_SUCCESS) {
        [NSException raise:@"SFWThreadException" format:@"could not configure real-time thread."];
    }
}

- (instancetype) init {
    self = [super init];

    _sleepInterval = kMinSleepInterval;

    return self;
}

- (void) main {

    move_pthread_to_realtime_scheduling_class(pthread_self());

    [super main];

    _isExecuting = YES;
    _runLoop = [NSRunLoop currentRunLoop];
    [_runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];

    mach_timebase_info_data_t timebase_info;
    mach_timebase_info(&timebase_info);

    while (_isExecuting) {

        [_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];

        uint64_t time_to_wait = (uint64_t) (self.sleepInterval * NANOS_PER_SEC) * timebase_info.denom / timebase_info.numer;
        uint64_t nowMach = mach_absolute_time();
        mach_wait_until(nowMach + time_to_wait);
    }

    _isFinished = YES;
}

- (void) cancel {
    [super cancel];

    if (self.isExecuting)
        _isExecuting = NO;
    else
        _isFinished = YES;
}

- (void)setSleepInterval:(NSTimeInterval)sleepInterval {
    _sleepInterval = fmax(sleepInterval, kMinSleepInterval);
}


- (BOOL) isExecuting {
    return _isExecuting;
}

- (BOOL)isCancelled {
    return !_isExecuting;
}

- (BOOL)isFinished {
    return _isFinished;
}

@end