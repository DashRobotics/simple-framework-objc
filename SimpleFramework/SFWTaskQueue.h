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
#import "SFWTask.h"

@class SFWTaskQueue;
@protocol SFWTask;

@interface SFWTaskQueue : NSObject

+ (instancetype) mainQueue;
+ (instancetype) backgroundQueue;
+ (instancetype) currentQueue;

- (instancetype) initWithName: (NSString*) name;

- (SFWTask_t) queue: (SFWRunBlock_t) block sync: (bool) bSync;
- (SFWTask_t) queueSync: (SFWRunBlock_t) block;
- (SFWTask_t) queueAsync: (SFWRunBlock_t) block;
/* Runs the block delayed by a timeout after the last queued block is executed. */
- (SFWTask_t) queueAsync: (SFWRunBlock_t) block after: (NSTimeInterval) timeDelay;
/* Runs the block at a certain time. */
- (SFWTask_t) queueAsync: (SFWRunBlock_t) block at: (NSTimeInterval) timeDelay;

- (void) pause;
- (void) resume;
- (void) cancelAll;
- (void) cancel: (SFWTask_t) task;

/*
- (SFWTask *) queueTask: (SFWTask *) op sync: (bool) bSync;
- (SFWTask *) queueSyncTask: (SFWTask *) op;
- (SFWTask *) queueAsyncTask: (SFWTask *) op;
*/

@end