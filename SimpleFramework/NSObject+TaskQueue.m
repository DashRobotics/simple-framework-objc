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

#import "NSObject+TaskQueue.h"
#import "SFWTaskRunner.h"
#import "SFWTaskQueue.h"

@implementation NSObject (TaskQueue)

- (void) performBlock: (SFWRunBlock_t) block {
    [[SFWTaskRunner currentRunner] scheduleAsync:block at:0];
}

- (void)performBlock:(SFWRunBlock_t)block after:(NSTimeInterval)delayTime {
    [[SFWTaskRunner currentRunner] scheduleAsync:block
                                              at:dispatch_time(DISPATCH_TIME_NOW, (dispatch_time_t) (NSEC_PER_SEC * delayTime))];
}

- (void)performBlockOnMain:(SFWRunBlock_t)block {
    [[SFWTaskRunner mainRunner] scheduleAsync:block at:0];
}

- (void)performBlockOnMain:(SFWRunBlock_t)block after: (NSTimeInterval) delayTime {
    [[SFWTaskRunner mainRunner] scheduleAsync:block
                                              at:dispatch_time(DISPATCH_TIME_NOW, (dispatch_time_t) (NSEC_PER_SEC * delayTime))];
}

- (void)performBlockOnBackground:(SFWRunBlock_t)block {
    [[SFWTaskRunner backgroundRunner] scheduleAsync:block at:0];
}


- (void)performBlockOnBackground:(SFWRunBlock_t)block after: (NSTimeInterval) delayTime {
    [[SFWTaskRunner backgroundRunner] scheduleAsync:block
                                           at:dispatch_time(DISPATCH_TIME_NOW, (dispatch_time_t) (NSEC_PER_SEC * delayTime))];
}


@end