//
//  AudioMixer.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/15/21.
//

#import "AudioMixer.h"
#import <Accelerate/Accelerate.h>

@implementation AudioMixer

+(void)changeVolumeForBufferList:(AudioBufferList *)bufferList volume:(CGFloat)volume {
    for (UInt32 bufferIndex=0; bufferIndex<(bufferList->mNumberBuffers); bufferIndex++) {
        AudioBuffer audioBuffer = bufferList->mBuffers[bufferIndex];
        void *rawBuffer = audioBuffer.mData;
        if (rawBuffer) {
            UInt32 frameCount = (UInt32)(audioBuffer.mDataByteSize)/(UInt32)(sizeof(float));
            const float tarVolume = volume;
            vDSP_vsmul(rawBuffer, 1, &tarVolume, rawBuffer, 1, frameCount);
        }
    }
}

@end
