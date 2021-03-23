//
//  ViewController.m
//  TLCamera
//
//  Created by Will on 2021/1/6.
//

#import "ViewController.h"

#import "TLCameraController.h"
#import "TLGPUImageController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

///
@property (nonatomic, strong) UITableView *tableView;

///
@property (nonatomic, strong) NSArray<NSString *> *data;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.data = @[@"微信相机",@"实时滤镜"];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.tableView.frame = self.view.bounds;
}

- (void)openButtonAction:(UIButton *)sender {
    
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_id"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:@"cell_id"];
    }
    cell.textLabel.text = self.data[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        TLCameraController *camera = [[TLCameraController alloc] init];
        camera.TLDoneBlock = ^(UIImage * _Nonnull image, NSURL * _Nonnull videoUrl) {
            NSLog(@"done image = %@,videoUrl = %@",image,videoUrl);
        };
        [self presentViewController:camera animated:YES completion:nil];
    }
    else if (indexPath.row == 1) {
        TLGPUImageController *gpu_controller = [[TLGPUImageController alloc] init];
        [self presentViewController:gpu_controller animated:YES completion:nil];
    }
}

#pragma mark - Getters
- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

@end
