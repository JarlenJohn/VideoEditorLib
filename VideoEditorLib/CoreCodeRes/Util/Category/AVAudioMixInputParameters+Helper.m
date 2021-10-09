//
//  AVAudioMixInputParameters+Helper.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/14/21.
//


#import "AVAudioMixInputParameters+Helper.h"
#import "AudioProcessingTapHolder.h"
#import <objc/runtime.h>


@implementation AVAudioMixInputParameters (Helper)

static char audioProcessingTapHolderKey;

- (void)setAudioProcessingTapHolder:(AudioProcessingTapHolder *)audioProcessingTapHolder {
    objc_setAssociatedObject(self, &audioProcessingTapHolderKey, audioProcessingTapHolder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AudioProcessingTapHolder *)audioProcessingTapHolder {
    return objc_getAssociatedObject(self, &audioProcessingTapHolderKey);
}

- (void)appendAudioProcessNode:(id <AudioProcessingNode>)node {
    if (self.audioProcessingTapHolder == nil) {
        self.audioProcessingTapHolder =  [[AudioProcessingTapHolder alloc] init];
    }
    [self.audioProcessingTapHolder.audioProcessingChain.nodes addObject:node];
}

@end
