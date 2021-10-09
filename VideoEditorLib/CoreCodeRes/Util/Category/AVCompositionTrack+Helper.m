//
//  AVCompositionTrack+Helper.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/10/21.
//

#import "AVCompositionTrack+Helper.h"
#import <objc/runtime.h>

static char preferredTransformsKey;

@implementation AVCompositionTrack (Helper)

- (void)setPreferredTransforms:(NSMutableDictionary *)preferredTransforms {
    objc_setAssociatedObject(self, &preferredTransformsKey, preferredTransforms, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)preferredTransforms {
    NSMutableDictionary *transforms = objc_getAssociatedObject(self, &preferredTransformsKey);
    if (transforms) {
        return transforms;
    }
    
    transforms = [NSMutableDictionary dictionary];
    self.preferredTransforms = transforms;
    return transforms;
}

@end
