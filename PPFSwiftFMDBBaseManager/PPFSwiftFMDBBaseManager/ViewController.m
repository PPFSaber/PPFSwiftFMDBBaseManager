//
//  ViewController.m
//  PPFSwiftFMDBBaseManager
//
//  Created by colinpian on 2020/8/7.
//  Copyright © 2020 com.PPFSwiftFMDBBaseManager.ppf. All rights reserved.
//

#import "ViewController.h"
#import "people.h"
#import <PPFSwiftFMDBBaseManager-Swift.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIButton *bt = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self.view addSubview:bt];
    [bt addTarget:self action:@selector(tapBT) forControlEvents:(UIControlEventTouchUpInside)];
    bt.frame = CGRectMake(0, 0, 100, 40);
    bt.center = self.view.center;
    bt.backgroundColor = UIColor.blueColor;
    PPFBaseDataBaseManager *m = [PPFBaseDataBaseManager sharedBaseDBManagerWithDbName:@"PPFDB.sqlite" dbPath:@"/Users/colinpian/Desktop"];
    BOOL success = [m ppf_creatTableWithTableName:@"user" modelClass:People.class];
    
    if (success == false) {
        NSLog(@"ppf_creatTableWithTableName false");
    }
}

- (void)tapBT
{
    PPFBaseDataBaseManager *m = [PPFBaseDataBaseManager sharedBaseDBManager];
    People *p = [self people];
    BOOL success = [m ppf_insertWithTableName:@"user" model:p];
    
    if (success == false) {
        NSLog(@"ppf_insertWithTableName false");
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSArray *ar =  [m ppf_lookupWithTableName:@"user" modelClass:People.class whereStr:@""];
        
        if ([p isEqual: ar.lastObject])
        {
            NSLog(@"%@",p);
        }
        else
        {
            NSLog(@"%@",ar);
        }
        
    });
}

-(People*)people{
    //存储对象使用示例
    People* p = [People new];
    p.name = @"斯巴达7";
    p.num = @(220.88);
    p.age = 99;
    p.sex = @"男";
    p.eye = @"末世眼皮111";
    p.Url = [NSURL URLWithString:@"http://www.baidu.com"];
    p.addBool = YES;
//    p.range = NSMakeRange(0,10);
//    p.rect = CGRectMake(0,0,10,20);
//    p.size = CGSizeMake(50,50);
//    p.point = CGPointMake(2.55,3.14);
//    p.color = [UIColor colorWithRed:245 green:245 blue:245 alpha:1.0];
//    NSMutableAttributedString* attStrM = [[NSMutableAttributedString alloc] initWithString:@"BGFMDB"];
//    [attStrM addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 2)];
//    p.attriStr = attStrM;
//    p.image = [UIImage imageNamed:@"MarkMan"];
    NSData* data = UIImageJPEGRepresentation([UIImage imageNamed:@"MarkMan"], 1);
    p.data2 = data;
    
    p.arrM = [NSMutableArray array];
    for(int i=1;i<=5;i++){
        [p.arrM addObject:UIImageJPEGRepresentation([UIImage imageNamed:[NSString stringWithFormat:@"ima%d",i]], 1)];
    }
    
    [p setValue:@(110) forKey:@"testAge"];
    p->testName = @"测试名字";
    p.sex_old = @"新名";
    User* user = [[User alloc] init];
    user.name = @"陈浩南";
    user.attri = @{@"用户名":@"黄芝标",@"密码":@(123456),@"数组":@[@"数组1",@"数组2"],@"集合":@{@"集合1":@"集合2"}};
    Student* student = [[Student alloc] init];
    student.num = @"标哥";
    student.names = @[@"小哥哥",@"小红",@(110),@[@"数组元素1",@"数组元素2"],@{@"集合key":@"集合value"}];
    student.count = 199;
    Human* human = [[Human alloc] init];
    human.sex = @"女";
    human.body = @"小芳";
    human.humanAge = 98;
    human.age = 18;
    student.human = human;
    user.student = student;
    p.students = @[@(1),@"呵呵",@[@"数组元素1",@"数组元素2"],@{@"集合key":@"集合value"},student,student];
    p.infoDic = @{@"name":@"标哥",@"年龄":@(1),@"数组":@[@"数组1",@"数组2"],@"集合":@{@"集合1":@"集合2"},@"user":user};
    
    NSHashTable* hashTable = [NSHashTable new];
    [hashTable addObject:@"h1"];
    [hashTable addObject:@"h2"];
    [hashTable addObject:student];
    NSMapTable* mapTable = [NSMapTable  new];
    [mapTable setObject:@"m_value1" forKey:@"m_key1"];
    [mapTable setObject:@"m_value2" forKey:@"m_key2"];
    [mapTable setObject:user forKey:@"m_key3"];
    NSSet* set1 = [NSSet setWithObjects:@"1",@"2",student, nil];
    NSMutableSet* set2 = [NSMutableSet set];
    [set2 addObject:@{@"key1":@"value"}];
    [set2 addObject:@{@"key2":user}];
    
    People* userP = [People new];
    userP.name = @"互为属性测试";
    user.userP = userP;
    
    p.user = user;
    p.user1 = [User new];
    p.user1.name = @"小明_fuck2222";
    p.bfloat = 8.88;
    p.bdouble = 100.567;
    p.user.userAge = 13;
    p.user.userNumer = @(3.14);
    p.user.student.human.humanAge = 9999;
    
//    p.hashTable = hashTable;
//    p.mapTable = mapTable;
    p.nsset = set1;
    p.setM = set2;
//    p.date = [NSDate date];
    return p;
}

@end
