//
//  AudioProcessingChain.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import "AudioProcessingChain.h"

@implementation AudioProcessingChain

- (instancetype)init {
    if (self = [super init]) {
        _nodes = @[].mutableCopy;
    }
    return self;
}

- (void)processTimeRange:(CMTimeRange)timerange bufferListInOut:(AudioBufferList *)bufferListInOut {
    for (id<AudioProcessingNode>  _Nonnull obj in self.nodes) {
        [obj processTimeRange:timerange bufferListInOut:bufferListInOut];
    }
}

- (id)copyWithZone:(NSZone *)zone {
    AudioProcessingChain *chain = [[self class] allocWithZone:zone];
    chain.nodes = self.nodes;
    return chain;
}

@end
