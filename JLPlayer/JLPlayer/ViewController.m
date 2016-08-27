//
//  ViewController.m
//  JLPlayer
//
//  Created by DEMO on 16/8/27.
//  Copyright © 2016年 DEMO. All rights reserved.
//



#import "ViewController.h"

#import "JLPlayerView.h"

@interface ViewController ()
@property (nonatomic, strong) JLPlayerView * playerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.playerView = ({
//       
        JLPlayerView * playerView = [[JLPlayerView alloc] initWithResourceUrlStr:@"http://go2study8.pinnc.com/videos/cat.mp4"
                                                                           Frame:CGRectMake(0, 0,
                                                                                            self.view.frame.size.width,
                                                                                   300)];
        
//        JLPlayerView * playerView = [[JLPlayerView alloc] initWithFrame:CGRectMake(0, 0,
//                                                                                            self.view.frame.size.width,
//                                                                                            300)];
        
        [self.view addSubview:playerView];
        
        playerView;
        
        
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation
- (void)viewWillTransitionToSize:(CGSize)mySize withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         if (mySize.width > mySize.height) {
             
             
             _playerView.frame = CGRectMake(0, 0, mySize.width, mySize.height);
             
             _playerView.deviceOrientation = JLPlayerOrientationLandscape;
             
         } else {
            
             _playerView.frame = CGRectMake(0, 0,
                                            self.view.frame.size.width,
                                            300);
             
             _playerView.deviceOrientation = JLPlayerOrientationPortrait;

         }
         
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
         
     }];
    
    [super viewWillTransitionToSize:mySize withTransitionCoordinator:coordinator];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}
@end
