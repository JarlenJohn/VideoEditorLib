//
//  AudioProcessingTapHolder.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/15/21.
//

#import "AudioProcessingTapHolder.h"

@implementation AudioProcessingTapHolder

- (instancetype)init {
    if (self = [super init]) {
        _audioProcessingChain = [[AudioProcessingChain alloc] init];
        
        
        MTAudioProcessingTapCallbacks *callbacks = (MTAudioProcessingTapCallbacks *)malloc(sizeof(MTAudioProcessingTapCallbacks));
        callbacks->version = kMTAudioProcessingTapCallbacksVersion_0;
        callbacks->clientInfo = (__bridge void * _Nullable)(self.audioProcessingChain);
        callbacks->init = tapInit;
        callbacks->finalize = tapFinalize;
        callbacks->prepare = tapPrepare;
        callbacks->unprepare = tapUnprepare;
        callbacks->process = tapProcess;
        
        MTAudioProcessingTapRef tap = NULL;
        OSStatus status = MTAudioProcessingTapCreate(kCFAllocatorDefault, callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap);
        if (status != noErr) {
            NSLog(@"error: failed to create audioProcessingTap.");
        }
        self.tap = tap;
    }
    return self;
}

void tapInit(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
    NSLog(@"tapInit the Audio Tap Processor");
    *tapStorageOut = clientInfo;
}

void tapFinalize(MTAudioProcessingTapRef CM_NONNULL tap) {
    NSLog(@"finalize %@.", tap);
    void* storage = MTAudioProcessingTapGetStorage(tap);
    CFRelease(storage);
}

void tapPrepare(
                MTAudioProcessingTapRef CM_NONNULL tap,
                CMItemCount maxFrames,
                const AudioStreamBasicDescription * CM_NONNULL processingFormat) {
    NSLog(@"prepare: %@, %ld, %@", tap, (long)maxFrames, processingFormat);
}

void tapUnprepare(MTAudioProcessingTapRef CM_NONNULL tap) {
    NSLog(@"%@", tap);
}

void tapProcess(
                MTAudioProcessingTapRef CM_NONNULL tap,
                CMItemCount numberFrames,
                MTAudioProcessingTapFlags flags,
                AudioBufferList * CM_NONNULL bufferListInOut,
                CMItemCount * CM_NONNULL numberFramesOut,
                MTAudioProcessingTapFlags * CM_NONNULL flagsOut) {
    NSLog(@"tapProcess: %@, %ld, %u, %@, %p, %p", tap, (long)numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut);
    CMTimeRange timeRange = kCMTimeRangeZero;
    OSStatus status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, &timeRange, numberFramesOut);
    if (status != noErr) {
        NSLog(@"error: failed to get source audio");
        return;
    }
    
    void*storage = MTAudioProcessingTapGetStorage(tap);
    AudioProcessingChain *audioProcessingChain = CFBridgingRelease(storage);
    [audioProcessingChain processTimeRange:timeRange bufferListInOut:bufferListInOut];
}

- (id)copyWithZone:(NSZone *)zone {
    AudioProcessingTapHolder *holder = [[self class] allocWithZone:zone];
    holder.audioProcessingChain = [self.audioProcessingChain copy];
    return holder;
}

@end

