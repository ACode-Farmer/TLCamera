### Version 1.0.0 (2021-03-23) ###

1、使用GPUImageVideoCamera时会报子线程操作UI
参考https://www.jianshu.com/p/15cc2cd3a862
在GPUImageView的layoutSubviews加个属性存储viewBounds = bounds，在recalculateViewGeometry中将bounds替换为viewBounds
