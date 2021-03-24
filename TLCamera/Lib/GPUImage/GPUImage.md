### Version 1.0.0 (2021-03-23) ###

1、使用GPUImageVideoCamera时会报子线程操作UI
在GPUImageView的layoutSubviews加个属性存储viewBounds = bounds，在recalculateViewGeometry中将bounds替换为viewBounds

2、内存释放
参考https://www.jianshu.com/p/b16d4f0786f8
GPUImageMovieWriter.m
    inputRotation = kGPUImageNoRotation;
    _movieWriterContext = [GPUImageContext sharedImageProcessingContext];
//    _movieWriterContext = [[GPUImageContext alloc] init];
//    [_movieWriterContext useSharegroup:[[[GPUImageContext sharedImageProcessingContext] context] sharegroup]];

GPUImageContext.m  ##很重要,会一直增加内存，导致app被kill
- (void)dealloc {
    if (_coreVideoTextureCache != NULL) {
        CFRelease(_coreVideoTextureCache);
    }
}

3、GPUImagemovie 预览、合成视频导致原视频曝光问题
GPUImageFilter.h中修改kColorConversion601Default和kColorConversion709Default
GLfloat kColorConversion601Default[] = {
    1,       1,       1,
    0, -.39465, 2.03211,
    1.13983, -.58060,       0,
};
// BT.709, which is the standard for HDTV.
GLfloat kColorConversion709Default[] = {x
    1,       1,       1,
    0, -.21482, 2.12798,
    1.28033, -.38059,       0,
};
