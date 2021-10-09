//
//  Resource.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import "Resource.h"

@interface Resource () {
    CMTime _scaledDuration;
}

@end

@implementation Resource
@dynamic scaledDuration;

- (instancetype)init {
    if (self = [super init]) {
        _duration = kCMTimeZero;
        _selectedTimeRange = kCMTimeRangeZero;
        _scaledDuration = kCMTimeInvalid;
        _size = CGSizeZero;
        _status = ResourceStatusUnavaliable;
    }
    return self;
}

#pragma mark - Getter & Setter
- (CMTime)scaledDuration {
    if (CMTIME_IS_INVALID(_scaledDuration)) {
        return self.selectedTimeRange.duration;
    }
    return _scaledDuration;
}

- (void)setScaledDuration:(CMTime)scaledDuration {
    _scaledDuration = scaledDuration;
}

- (CMTime)sourceTimeForTimelineTime:(CMTime)timelineTime {
    CGFloat ratio = CMTimeGetSeconds(self.selectedTimeRange.duration) / CMTimeGetSeconds(self.scaledDuration);
    return CMTimeAdd(self.selectedTimeRange.start, CMTimeMultiplyByFloat64(timelineTime, ratio));
}

/// Provide tracks for specific media type
///
/// - Parameter type: specific media type, currently only support AVMediaTypeVideo and AVMediaTypeAudio
/// - Returns: tracks
- (NSArray <AVAssetTrack *>*)tracksForType:(AVMediaType)type {
    NSArray *tracks = [[Resource emptyAsset] tracksWithMediaType:type];
    return tracks ?: @[];
}

/// Load content makes it available to get tracks. When use load resource from PHAsset or internet resource, it's your responsibility to determinate when and where to load the content.
///
/// - Parameters:
///   - progressHandler: loading progress
///   - completion: load completion
- (ResourceTask *)prepareWithProgressHandler:(void (^)(double progress))progressHandler
                                  completion:(void (^)(ResourceStatus resourceStatus, NSError *statusError))completionHandler {
    completionHandler(self.status, self.statusError);
    return nil;
}


#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    Resource *resource = [[self class] allocWithZone:zone];
    resource.size = self.size;
    resource.duration = self.duration;
    resource.selectedTimeRange = self.selectedTimeRange;
    resource.scaledDuration = self.scaledDuration;
    return resource;
}

#pragma mark - ResourceTrackInfoProvider
- (ResourceTrackInfo *)trackInfoForType:(AVMediaType)type atIndex:(NSUInteger)index {
    AVAssetTrack *track = [self tracksForType:type][index];
    CMTime emptyDuration = CMTimeMake(1, 30);
    CMTimeRange emptyTimeRange = CMTimeRangeMake(kCMTimeZero, emptyDuration);
    
    ResourceTrackInfo *info = (ResourceTrackInfo*)malloc(sizeof(ResourceTrackInfo));
    info->track = track;
    info->selectedTimeRange = emptyTimeRange;
    info->scaleToDuration = self.scaledDuration;
    return info;
}

- (CIImage *)imageAtTime:(CMTime)time renderSize:(CGSize)renderSize {
    return nil;
}


#pragma mark - Helper
+(AVAsset *)emptyAsset {
    NSURL *videoUrl = [[NSBundle mainBundle] URLForResource:@"black_empty" withExtension:@"mp4"];
    return [AVAsset assetWithURL:videoUrl];
}

@end


@implementation Resource (Speed)

- (void)setSpeed:(float)speed {
    self.scaledDuration = CMTimeMultiplyByFloat64(self.selectedTimeRange.duration, (1/speed));
}
@end


@implementation ResourceTask

- (instancetype)initWithCancelHandler:(CancelHandler)handler {
    if (self = [super init]) {
        _cancelHandler = handler;
    }
    return self;
}

- (void)cancel {
    if (_cancelHandler) {
        _cancelHandler();
    }
}



@end
