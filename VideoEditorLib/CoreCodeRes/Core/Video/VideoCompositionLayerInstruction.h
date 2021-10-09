//
//  VideoCompositionLayerInstruction.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/13/21.
//

#import <Foundation/Foundation.h>
#import "CompositionProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoCompositionLayerInstruction: NSObject

@property(nonatomic, readonly, assign) CMPersistentTrackID trackID;
@property (nonatomic, strong) id <VideoCompositionProvider>videoCompositionProvider;
@property (nonatomic, assign) CMTimeRange timeRange;
@property (nonatomic, strong) id<VideoTransition> transition;
@property (nonatomic, assign) CGAffineTransform prefferdTransform;

- (instancetype)initWithTrackID:(CMPersistentTrackID)trackID videoCompositionProvider:(id)videoCompositionProvider;
- (CIImage *)applySourceImage:(CIImage *)sourceImage atTime:(CMTime)time renderSize:(CGSize)renderSize;

@end

NS_ASSUME_NONNULL_END
