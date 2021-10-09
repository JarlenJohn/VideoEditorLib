//
//  AVAssetTrackResource.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.

#import "Resource.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVAssetTrackResource : Resource

@property (nonatomic, strong) AVAsset *asset;

- (instancetype)initWithAsset:(AVAsset *)asset;

@end

NS_ASSUME_NONNULL_END
