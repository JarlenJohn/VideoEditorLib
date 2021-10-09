//
//  Resource.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ResourceTask;

typedef struct {
    AVAssetTrack *track;
    CMTimeRange selectedTimeRange;
    CMTime scaleToDuration;
}ResourceTrackInfo;

typedef NS_ENUM(NSUInteger, ResourceStatus) {
    ResourceStatusUnavaliable,
    ResourceStatusAvaliable,
};

typedef void (^CancelHandler)(void);


@protocol ResourceTrackInfoProvider <NSObject>

- (ResourceTrackInfo *)trackInfoForType:(AVMediaType)type atIndex:(NSUInteger)index;
- (CIImage *)imageAtTime:(CMTime)time renderSize:(CGSize)renderSize;

@end


@interface Resource : NSObject <NSCopying, ResourceTrackInfoProvider>

@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) CMTimeRange selectedTimeRange;
@property (nonatomic, assign) CMTime scaledDuration;
/// Natural frame size of this resource
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) ResourceStatus status;
@property (nonatomic, strong) NSError *statusError;

- (CMTime)sourceTimeForTimelineTime:(CMTime)timelineTime;

/// Provide tracks for specific media type
///
/// - Parameter type: specific media type, currently only support AVMediaTypeVideo and AVMediaTypeAudio
/// - Returns: tracks
- (NSArray <AVAssetTrack *>*)tracksForType:(AVMediaType)type;

- (ResourceTask *)prepareWithProgressHandler:(void (^)(double progress))progressHandler
                                  completion:(void (^)(ResourceStatus resourceStatus, NSError *statusError))completionHandler;

@end


@interface Resource (Speed)

- (void)setSpeed:(float)speed;
@end


@interface ResourceTask : NSObject

@property (nonatomic, copy) CancelHandler cancelHandler;

- (instancetype)initWithCancelHandler:(CancelHandler)handler;

@end

NS_ASSUME_NONNULL_END
