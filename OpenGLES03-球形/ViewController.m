//
//  ViewController.m
//  OpenGLES03-球形
//
//  Created by waqu on 2017/8/22.
//  Copyright © 2017年 com.waqu. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view = [[OpenGLView alloc] initWithFrame:self.view.bounds];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
