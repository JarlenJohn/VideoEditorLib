//
//  VideoCompositionInstruction.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/10/21.
//

#import <Foundation/Foundation.h>
#import "CompositionProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class VideoCompositionLayerInstruction;


@interface VideoCompositionInstruction : NSObject <AVVideoCompositionInstruction>

@property (nonatomic, strong) CIColor *backgroundColor;
@property (nonatomic, strong) NSMutableArray <VideoCompositionLayerInstruction *>*layerInstructions;
@property (nonatomic, strong) id<VideoCompositionProvider> passingThroughVideoCompositionProvider;
@property (nonatomic, strong) NSArray <NSNumber *>*mainTrackIDs;

- (instancetype)initWithPassthroughTrackID:(CMPersistentTrackID)thePassthroughTrackID forTimeRange:(CMTimeRange)theTimeRange;
- (instancetype)initWithSourceTrackIDs:(NSArray <NSValue *>*)trackIDs forTimeRange:(CMTimeRange)timeRange;

- (CIImage *)applyRequest:(AVAsynchronousVideoCompositionRequest *)request;
@end



NS_ASSUME_NONNULL_END
