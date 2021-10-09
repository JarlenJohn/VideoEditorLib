//
//  CompositionGenerator.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import <UIKit/UIKit.h>
#import "CompositionGenerator.h"
#import "VideoCompositionInstruction.h"
#import "AVCompositionTrack+Helper.h"
#import "TimeRangeHelper.h"
#import "VideoCompositor.h"
#import "VideoCompositionLayerInstruction.h"

@interface CompositionGenerator()

@property (nonatomic, strong) AVComposition *composition;
@property (nonatomic, strong) AVVideoComposition *videoComposition;
@property (nonatomic, strong) AVAudioMix *audioMix;

@property (nonatomic, assign) BOOL needRebuildComposition;
@property (nonatomic, assign) BOOL needRebuildVideoComposition;
@property (nonatomic, assign) BOOL needRebuildAudioMix;

@property (nonatomic, assign) int increasementTrackID;

@property (nonatomic, strong) NSMutableArray <TrackInfo *> *mainVideoTrackInfo;
@property (nonatomic, strong) NSMutableArray <TrackInfo *> *mainAudioTrackInfo;
@property (nonatomic, strong) NSMutableArray <TrackInfo<VideoProvider> *> *overlayTrackInfo;
@property (nonatomic, strong) NSMutableArray <TrackInfo<AudioProvider> *> *audioTrackInfo;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSArray *>*audioTransitionInfo;
@property (nonatomic, strong) id<AudioTransition> previousAudioTransition;

@end

@implementation CompositionGenerator

- (instancetype)initWithTimeline:(Timeline *)timeline {
    if (self = [super init]) {
        _needRebuildComposition = YES;
        _needRebuildVideoComposition = YES;
        _needRebuildAudioMix = YES;
        _increasementTrackID = 0;
        
        _timeline = timeline;
    }
    return self;
}

#pragma mark - Lazy

- (NSMutableArray<TrackInfo *> *)mainVideoTrackInfo {
    if (!_mainVideoTrackInfo) {
        _mainVideoTrackInfo = [NSMutableArray array];
    }
    return _mainVideoTrackInfo;
}

- (NSMutableArray<TrackInfo *> *)mainAudioTrackInfo {
    if (!_mainAudioTrackInfo) {
        _mainAudioTrackInfo = [NSMutableArray array];
    }
    return _mainAudioTrackInfo;
}

- (NSMutableArray<TrackInfo<VideoProvider> *> *)overlayTrackInfo {
    if (!_overlayTrackInfo) {
        _overlayTrackInfo = [NSMutableArray array];
    }
    return _overlayTrackInfo;
}

- (NSMutableArray<TrackInfo<AudioProvider> *> *)audioTrackInfo {
    if (!_audioTrackInfo) {
        _audioTrackInfo = [NSMutableArray array];
    }
    return _audioTrackInfo;
}

- (NSMutableDictionary<NSNumber *,NSArray *> *)audioTransitionInfo {
    if (!_audioTransitionInfo) {
        _audioTransitionInfo = [NSMutableDictionary dictionary];
    }
    return _audioTransitionInfo;
}

#pragma mark - Setter & Getter
- (void)setTimeline:(Timeline *)timeline {
    if (_timeline != timeline) {
        self.needRebuildComposition = YES;
        self.needRebuildVideoComposition = YES;
        self.needRebuildAudioMix = YES;
    }
}

#pragma mark - Custom method
- (AVPlayerItem *)buildPlayerItem {
    AVComposition *composition = [self buildComposition];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
    playerItem.videoComposition = [self buildVideoComposition];
    playerItem.audioMix = [self buildAudioMix];
    return playerItem;
}

#pragma mark - Build Composition
- (AVComposition *)buildComposition {
    if (self.composition && !self.needRebuildComposition) {
        return self.composition;
    }
    
    [self resetSetupInfo];
    
    AVMutableComposition *composition = [AVMutableComposition compositionWithURLAssetInitializationOptions:@{AVURLAssetPreferPreciseDurationAndTimingKey : @(YES)}];
    
    NSMutableDictionary <NSNumber *, NSNumber *>*videoChannelTrackIDs = [[NSMutableDictionary alloc] init];
    [self.timeline.videoChannel enumerateObjectsUsingBlock:^(id<TransitionableVideoProvider>  _Nonnull provider, NSUInteger idx, BOOL * _Nonnull stop) {
        for (int index = 0; index < provider.numberOfVideoTracks; index++) {
            CMPersistentTrackID trackID = [self getVideoTrackIDForIndex:index fromVideoChannelTrackIDs:videoChannelTrackIDs] + ((idx % 2) + 1)*1000;
            AVCompositionTrack *compositionTrack = [provider videoCompositionTrackFor:composition atIndex:index preferredTrackID:trackID];
            
            TrackInfo *info = nil;
            for (TrackInfo *trackInfo in self.mainVideoTrackInfo) {
                if (trackInfo.track == compositionTrack) {
                    info = trackInfo;
                    break;
                }
            }
            if (info) {
                [info.info addObject:provider];
            }else {
                info = [[TrackInfo alloc] initWithTrack:compositionTrack info:[NSMutableArray arrayWithObject:provider]];
                [self.mainVideoTrackInfo addObject:info];
            }
        }
    }];
    
    NSMutableDictionary <NSNumber *, NSNumber *>*audioChannelTrackIDs = [[NSMutableDictionary alloc] init];
    [self.timeline.audioChannel enumerateObjectsUsingBlock:^(id<TransitionableAudioProvider>  _Nonnull provider, NSUInteger idx, BOOL * _Nonnull stop) {
        for (int index = 0; index < provider.numberOfAudioTracks; index++) {
            CMPersistentTrackID trackID = [self getAudioTrackIDForIndex:index fromAudioChannelTrackIDs:audioChannelTrackIDs] + ((idx % 2) + 1)*1000;
            AVCompositionTrack *compositionTrack = [provider audioCompositionTrack:composition atIndex:index preferredTrackID:trackID];
            TrackInfo *info = nil;
            for (TrackInfo *trackInfo in self.mainAudioTrackInfo) {
                if (trackInfo.track == compositionTrack) {
                    info = trackInfo;
                    break;
                }
            }
            if (info) {
                [info.info addObject:provider];
            }else {
                info = [[TrackInfo alloc] initWithTrack:compositionTrack info:[NSMutableArray arrayWithObject:provider]];
                [self.mainAudioTrackInfo addObject:info];
            }
        }
        
        if (idx == 0) {
            if (self.timeline.audioChannel.count > 1) {
                [self.audioTransitionInfo setObject:@[[NSNull null], provider.audioTransition?:(id<AudioTransition>)[NSNull null]] forKey:[NSNumber numberWithInteger:idx]];
            }
        }else if (idx == self.timeline.audioChannel.count - 1) {
            [self.audioTransitionInfo setObject:@[self.previousAudioTransition?:(id<AudioTransition>)[NSNull null], [NSNull null]] forKey:[NSNumber numberWithInteger:idx]];
        }else {
            [self.audioTransitionInfo setObject:@[self.previousAudioTransition?:(id<AudioTransition>)[NSNull null], provider.audioTransition?:(id<AudioTransition>)[NSNull null]] forKey:[NSNumber numberWithInteger:idx]];
        }
        self.previousAudioTransition = provider.audioTransition;
    }];
    
    
    //复用trackID，因为AVFoundation只能同时使用16个轨道
    NSMutableArray <NSNumber *>*overlaysTrackIDs = [[NSMutableArray alloc] init];
    for (id<VideoProvider>  _Nonnull provider in self.timeline.overlays) {
        for (int index = 0; index < provider.numberOfVideoTracks; index++) {
            
            int(^getTrackID)(void) = ^{
                for (NSNumber *number in overlaysTrackIDs) {
                    int trackID = [number intValue];
                    
                    BOOL(^hasTrackID)(int) = ^(int trackID) {
                        AVCompositionTrack *track = [composition trackWithTrackID:trackID];
                        if (track) {
                            for (AVAssetTrackSegment *segment in track.segments) {
                                if (CMTIME_COMPARE_INLINE(segment.timeMapping.target.start, >, CMTimeRangeGetEnd(provider.timeRange))) {
                                    break;
                                }
                                if (CMTIME_COMPARE_INLINE(CMTimeAdd(segment.timeMapping.target.start, segment.timeMapping.target.duration), <, provider.timeRange.start)) {
                                    continue;
                                }
                                if (!segment.isEmpty) {
                                    CMTimeRange timerange = CMTimeRangeGetIntersection(provider.timeRange, segment.timeMapping.target);
                                    if (CMTimeGetSeconds(timerange.duration) > 0) {
                                        return NO;
                                    }
                                }
                            }
                            return YES;
                        }
                        return NO;
                    };
                    
                    if (hasTrackID(trackID)) {
                        return trackID;
                    }
                }
                return [self generateNextTrackID];
            };
            
            int trackID = getTrackID();
            AVCompositionTrack *compositionTrack = [provider videoCompositionTrackFor:composition atIndex:index preferredTrackID:trackID];
            if (compositionTrack) {
                TrackInfo *info = [[TrackInfo alloc] initWithTrack:compositionTrack info:provider];
                [self.overlayTrackInfo addObject:info];
            }
            
            BOOL trackIDExist = NO;
            for (NSNumber *number in overlaysTrackIDs) {
                if ([number intValue] == trackID) {
                    trackIDExist = YES;
                    break;
                }
            }
            if (!trackIDExist) {
                [overlaysTrackIDs addObject:[NSNumber numberWithInt:trackID]];
            }
        }
    }
    
    
    for (id<AudioProvider>  _Nonnull provider in self.timeline.audios) {
        for (int index = 0; index < provider.numberOfAudioTracks; index++) {
            int trackID = [self generateNextTrackID];
            AVCompositionTrack *track = [provider audioCompositionTrack:composition atIndex:index preferredTrackID:trackID];
            if (track) {
                TrackInfo *info = [[TrackInfo alloc] initWithTrack:track info:provider];
                [self.audioTrackInfo addObject:info];
            }
        }
    }
    
    self.composition = composition;
    self.needRebuildComposition = NO;
    return composition;
}

- (AVVideoComposition *)buildVideoComposition {
    if (self.videoComposition && !_needRebuildVideoComposition) {
        return self.videoComposition;
    }
    
    [self buildComposition];
    
    NSMutableArray <VideoCompositionLayerInstruction *>*layerInstructions = [[NSMutableArray alloc] init];
    
    [self.mainVideoTrackInfo enumerateObjectsUsingBlock:^(TrackInfo * _Nonnull info, NSUInteger idx, BOOL * _Nonnull stop) {
        [info.info enumerateObjectsUsingBlock:^(id  <TransitionableVideoProvider>_Nonnull provider, NSUInteger idx, BOOL * _Nonnull stop) {
            VideoCompositionLayerInstruction *layerInstruction = [[VideoCompositionLayerInstruction alloc] initWithTrackID:info.track.trackID videoCompositionProvider:provider];
            NSString *timeRangeIdentifier = [TimeRangeHelper vf_identifierFromTimeRange:provider.timeRange];
            layerInstruction.prefferdTransform = [[info.track.preferredTransforms objectForKey:timeRangeIdentifier] CGAffineTransformValue];
            layerInstruction.timeRange = provider.timeRange;
            layerInstruction.transition = provider.videoTransition;
            [layerInstructions addObject:layerInstruction];
        }];
    }];
    
    [self.overlayTrackInfo enumerateObjectsUsingBlock:^(TrackInfo<VideoProvider> * _Nonnull info, NSUInteger idx, BOOL * _Nonnull stop) {
        AVCompositionTrack *track = info.track;
        id<VideoProvider> provider = info.info;
        VideoCompositionLayerInstruction *layerInstruction = [[VideoCompositionLayerInstruction alloc] initWithTrackID:track.trackID videoCompositionProvider:provider];
        NSString *timeRangeIdentifier = [TimeRangeHelper vf_identifierFromTimeRange:provider.timeRange];
        layerInstruction.prefferdTransform = [[info.track.preferredTransforms objectForKey:timeRangeIdentifier] CGAffineTransformValue];
        layerInstruction.timeRange = provider.timeRange;
        [layerInstructions addObject:layerInstruction];
    }];
    
    [layerInstructions sortUsingComparator:^NSComparisonResult(VideoCompositionLayerInstruction *left, VideoCompositionLayerInstruction *right) {
        if (CMTIME_COMPARE_INLINE(left.timeRange.start, ==, right.timeRange.start)) {
            return NSOrderedSame;
        }else if(CMTIME_COMPARE_INLINE(left.timeRange.start, <, right.timeRange.start)) {
            return NSOrderedAscending;
        }else {
            return NSOrderedDescending;
        }
    }];
    
    //将layerInstructions有重合部分切片，并根据时间放入数组instructions
    //each instructions contains layerInstructions whose time range have insection with instruction，
    //当需要渲染每一帧时，instruction可以快速找到对应的layerInstructions
    NSArray *layerInstructionsSlices = [self calculateSlicesForLayerInstructions:layerInstructions];
    
    NSMutableArray *mainTrackIDs = [[NSMutableArray alloc] init];
    for (TrackInfo *info in self.mainVideoTrackInfo) {
        [mainTrackIDs addObject:@(info.track.trackID)];
    }
    NSMutableArray <VideoCompositionInstruction *>*instructions = [[NSMutableArray alloc] init];
    for (NSArray *slice in layerInstructionsSlices) {
        NSMutableArray *trackIDs = [[NSMutableArray alloc] init];
        for (VideoCompositionLayerInstruction *layerInstruction in slice[1]) {
            [trackIDs addObject:@(layerInstruction.trackID)];
        }

        CMTimeRange sliceTimeRange = [slice[0] CMTimeRangeValue];
        VideoCompositionInstruction *instruction = [[VideoCompositionInstruction alloc] initWithSourceTrackIDs:trackIDs forTimeRange:sliceTimeRange];
        instruction.backgroundColor = self.timeline.backgroundColor;
        instruction.layerInstructions = slice[1];
        instruction.passingThroughVideoCompositionProvider = self.timeline.passingThroughVideoCompositionProvider;
        
        NSMutableArray *mainTracks = [[NSMutableArray alloc] init];
        for (NSNumber *mainTrackID in mainTrackIDs) {
            BOOL existInTrackIDS = NO;
            for (NSNumber *trackID in trackIDs) {
                if ([trackID intValue] == [mainTrackID intValue]) {
                    existInTrackIDS = YES;
                    break;
                }
            }
            if (existInTrackIDS) {
                [mainTracks addObject:mainTrackID];
            }
        }
        instruction.mainTrackIDs = mainTracks;
        
        [instructions addObject:instruction];
    }
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    videoComposition.renderSize = self.timeline.renderSize;
    videoComposition.instructions = (NSArray *)instructions;
    videoComposition.customVideoCompositorClass = [VideoCompositor class];
    self.videoComposition = videoComposition;
    self.needRebuildVideoComposition = NO;
    return videoComposition;
}

- (AVAudioMix *)buildAudioMix {
    if (self.audioMix && !self.needRebuildAudioMix) {
        return self.audioMix;
    }
    
    [self buildComposition];
    
    NSMutableArray <AVMutableAudioMixInputParameters *>*audioParameters = [[NSMutableArray alloc] init];
    
    for (TrackInfo *info in self.mainAudioTrackInfo) {
        AVCompositionTrack *track = info.track;
        AVMutableAudioMixInputParameters *inputParameter = [self createInputParameterWithTrack:track InAudioParameters:audioParameters];
        
        for (id<AudioProvider> provider in info.info) {
            [provider configureAudioMixParameters:inputParameter];
            
            NSInteger index = -1;
            for (id<TransitionableAudioProvider>audioProvider in self.timeline.audioChannel) {
                if (audioProvider == provider) {
                    index = [self.timeline.audioChannel indexOfObject:audioProvider];
                    break;
                }
            }
            
            if (index != -1) {
                NSArray *transitions = [self.audioTransitionInfo objectForKey:[NSNumber numberWithInteger:index]];
                if (![transitions isKindOfClass:[NSNull class]]) {
                    AVCompositionTrackSegment *segment = nil;
                    for (AVCompositionTrackSegment *temSegment in track.segments) {
                        if (CMTimeRangeEqual(temSegment.timeMapping.target, provider.timeRange)) {
                            segment = temSegment;
                            break;
                        }
                    }
                    
                    if (segment) {
                        CMTimeRange targetTimeRange = segment.timeMapping.target;
                        id <AudioTransition> transitionNext = transitions[0];
                        if (![transitionNext isKindOfClass:[NSNull class]]) {
                            [transitionNext applyNextAudioMixInputParameters:inputParameter timeRange:targetTimeRange];
                        }
                        
                        id <AudioTransition> transitionPre = transitions[0];
                        if (![transitionPre isKindOfClass:[NSNull class]]) {
                            [transitionPre applyPreviousAudioMixInputParameters:inputParameter timeRange:targetTimeRange];
                        }
                    }
                }
            }
        }
    }
    
    for (TrackInfo<AudioProvider> *info in self.audioTrackInfo) {
        AVCompositionTrack *track = info.track;
        id provider = info.info;
        
        AVMutableAudioMixInputParameters *inputParameter = [self createInputParameterWithTrack:track InAudioParameters:audioParameters];
        [provider configureAudioMixParameters:inputParameter];
    }
    
    if (audioParameters.count == 0) {
        return nil;
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = audioParameters;
    self.audioMix = audioMix;
    self.needRebuildAudioMix = NO;
    return audioMix;
}

- (AVMutableAudioMixInputParameters *)createInputParameterWithTrack:(AVCompositionTrack *)track InAudioParameters:(NSMutableArray *)audioParameters {
    AVMutableAudioMixInputParameters *inputParameters = nil;
    for (AVMutableAudioMixInputParameters *parameters in audioParameters) {
        if (parameters.trackID == track.trackID) {
            inputParameters = parameters;
            break;
        }
    }
    
    if (!inputParameters) {
        inputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
        [audioParameters addObject:inputParameters];
    }
    return inputParameters;
}


#pragma mark - Helper
- (CMPersistentTrackID)getVideoTrackIDForIndex:(NSInteger)index fromVideoChannelTrackIDs:(NSMutableDictionary *)videoChannelTrackIDs {
    NSNumber *numberKey = [NSNumber numberWithInteger:index];
    if ([videoChannelTrackIDs objectForKey:numberKey]) {
        return [[videoChannelTrackIDs objectForKey:numberKey] intValue];
    }
    
    CMPersistentTrackID trackID = [self generateNextTrackID];
    [videoChannelTrackIDs setObject:[NSNumber numberWithInteger:trackID] forKey:[NSNumber numberWithInteger:index]];
    return trackID;
}

- (CMPersistentTrackID)getAudioTrackIDForIndex:(NSInteger)index fromAudioChannelTrackIDs:(NSMutableDictionary *)trackIDsDic {
    NSNumber *numberKey = [NSNumber numberWithInteger:index];
    if ([trackIDsDic objectForKey:numberKey]) {
        return [[trackIDsDic objectForKey:numberKey] intValue];
    }
    
    CMPersistentTrackID trackID = [self generateNextTrackID];
    [trackIDsDic setObject:[NSNumber numberWithInteger:trackID] forKey:[NSNumber numberWithInteger:index]];
    return trackID;
}


/// LayerInstruction切片函数
/// @param layerInstructions VideoCompositionLayerInstruction数组
- (NSArray *)calculateSlicesForLayerInstructions:(NSArray <VideoCompositionLayerInstruction *>*)layerInstructions {
    NSMutableArray *layerInstructionsSlices = @[].mutableCopy;
    for (VideoCompositionLayerInstruction * _Nonnull layerInstruction in layerInstructions) {
        __block NSMutableArray *slices = [NSMutableArray arrayWithArray:layerInstructionsSlices];
        __block NSArray <NSValue *>*leftTimeRanges = [NSMutableArray arrayWithObject:[NSValue valueWithCMTimeRange:layerInstruction.timeRange]];
        __block int increaseNumber = 0;

        [layerInstructionsSlices enumerateObjectsUsingBlock:^(NSArray * _Nonnull slice, NSUInteger offset, BOOL * _Nonnull stop) {
            CMTimeRange intersectionTimeRange = CMTimeRangeGetIntersection([slice[0] CMTimeRangeValue], layerInstruction.timeRange);
            if (!CMTIMERANGE_IS_EMPTY(intersectionTimeRange)) {
                [slices removeObjectAtIndex:(offset + increaseNumber)];
                
                //存放元素为(CMTimeRange, [VideoCompositionLayerInstruction])
                NSMutableArray *currentSlices = [[NSMutableArray alloc] init];
                NSArray <NSValue *>*sliceTimeRanges = [TimeRangeHelper sliceTimeRangesForTimeRange:layerInstruction.timeRange timeRange2:[slice[0] CMTimeRangeValue]];
                
                for (NSValue *timeRangeValue in sliceTimeRanges) {
                    CMTimeRange timeRange = [timeRangeValue CMTimeRangeValue];
                    if (CMTimeRangeContainsTimeRange([slice[0] CMTimeRangeValue], timeRange)) {
                        if (CMTimeRangeContainsTimeRange(layerInstruction.timeRange, timeRange)) {
                            
                            NSMutableArray *layerInstrctions = [NSMutableArray arrayWithArray:[slice objectAtIndex:1]];
                            [layerInstrctions addObject:layerInstruction];
                            NSArray *newSlice = [NSArray arrayWithObjects:[NSValue valueWithCMTimeRange:timeRange], layerInstrctions, nil];
                            [currentSlices addObject:newSlice];
                            
                            NSMutableArray *tempLeftTimeRanges = [[NSMutableArray alloc] init];
                            for (NSValue *leftTimeRangeValue in leftTimeRanges) {
                                CMTimeRange leftTimeRange = [leftTimeRangeValue CMTimeRangeValue];
                                NSArray *tempTimeRanges = [TimeRangeHelper substructTimeRange:timeRange from:leftTimeRange];
                                for (NSValue *timerangeValue in tempTimeRanges) {
                                    if (!CMTIMERANGE_IS_EMPTY([timerangeValue CMTimeRangeValue])) {
                                        [tempLeftTimeRanges addObject:timerangeValue];
                                    }
                                }
                            }
                            leftTimeRanges = tempLeftTimeRanges;
                        }else {
                            NSArray *newSlice = [NSArray arrayWithObjects:[NSValue valueWithCMTimeRange:timeRange], [slice objectAtIndex:1], nil];
                            [currentSlices addObject:newSlice];
                        }
                    }
                }
        
                [currentSlices enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull slice, NSUInteger idx, BOOL * _Nonnull stop) {
                    [slices insertObject:slice atIndex:(offset + increaseNumber)];
                }];
                
                increaseNumber += currentSlices.count - 1;
            }
        }];
        
        for (NSValue *timeRangeValue in leftTimeRanges) {
            NSArray *sliceObj = [NSArray arrayWithObjects:timeRangeValue, @[layerInstruction], nil];
            [slices addObject:sliceObj];
        }
        
        layerInstructionsSlices = slices;
    }
    
    [layerInstructionsSlices sortUsingComparator:^NSComparisonResult(NSArray *slice1, NSArray *slice2) {
        CMTimeRange sliceTimeRange1 = [[slice1 objectAtIndex:0] CMTimeRangeValue];
        CMTimeRange sliceTimeRange2 = [[slice2 objectAtIndex:0] CMTimeRangeValue];
        
        if (CMTIME_COMPARE_INLINE(sliceTimeRange1.start, ==, sliceTimeRange2.start)) {
            return NSOrderedSame;
        }else if(CMTIME_COMPARE_INLINE(sliceTimeRange1.start, <, sliceTimeRange2.start)) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
    return layerInstructionsSlices;
}

- (void)resetSetupInfo {
    self.increasementTrackID = 0;
    [self.mainVideoTrackInfo removeAllObjects];
    [self.mainAudioTrackInfo removeAllObjects];
    [self.overlayTrackInfo removeAllObjects];
    [self.audioTrackInfo removeAllObjects];
    [self.audioTransitionInfo removeAllObjects];
}

#pragma mark - Helper
- (int)generateNextTrackID {
    int trackId = self.increasementTrackID + 1;
    self.increasementTrackID = trackId;
    return trackId;
}

@end


@implementation TrackInfo

- (instancetype)initWithTrack:(AVCompositionTrack *)track info:(id)info {
    if (self = [super init]) {
        self.track = track;
        self.info = info;
    }
    return self;
}

@end
