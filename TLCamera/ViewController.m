//
//  ViewController.m
//  TLCamera
//
//  Created by Will on 2021/1/6.
//

#import "ViewController.h"

#import "TLCameraController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *openButton = [UIButton buttonWithType:UIButtonTypeCustom];
    openButton.backgroundColor = UIColor.systemBlueColor;
    [openButton setTitle:@"打开相机" forState:UIControlStateNormal];
    [openButton addTarget:self action:@selector(openButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    openButton.frame = CGRectMake(0, 0, 100, 44);
    openButton.center = self.view.center;
    [self.view addSubview:openButton];
}

- (void)openButtonAction:(UIButton *)sender {
    TLCameraController *camera = [[TLCameraController alloc] init];
    camera.TLDoneBlock = ^(UIImage * _Nonnull image, NSURL * _Nonnull videoUrl) {
        NSLog(@"done image = %@,videoUrl = %@",image,videoUrl);
    };
    [self presentViewController:camera animated:YES completion:nil];
}



@end
