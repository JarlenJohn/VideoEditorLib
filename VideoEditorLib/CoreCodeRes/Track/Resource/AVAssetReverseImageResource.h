//
//  AVAssetReverseImageResource.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/19/21.
//  Load image from AVAssetReader as video frame, but order reversed

#import "ImageResource.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVAssetReverseImageResource : ImageResource

@property (nonatomic, strong) AVURLAsset *asset;

- (instancetype)initWithAsset:(AVURLAsset *)asset;

@end

NS_ASSUME_NONNULL_END
