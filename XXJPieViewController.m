#import "XXJPieViewController.h"
#import "XXJPieView.h"
#import "AppDelegate.h"
#import "Account.h"
#import "XXJPieTableViewCell.h"
#import "XXJTypeDetailViewController.h"
#import <CoreData/CoreData.h>
@interface XXJPieViewController () <UITableViewDataSource, XXJPieViewDataSource>
@property (weak, nonatomic) IBOutlet XXJPieView *pieView;
@property (weak, nonatomic) IBOutlet UITableView *typeTableView;
@property (weak, nonatomic) IBOutlet UILabel *moneyLabel;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *rightSwipe; 
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *leftSwipe; 
@property (strong, nonatomic) UILabel *nullLabel; 
@property (strong, nonatomic) NSString *incomeType;
@property (assign, nonatomic) double totalMoney; 
@property (strong, nonatomic) NSArray *dataArray; 
@property (strong, nonatomic) NSArray *uniqueDateArray;
@property (strong, nonatomic) NSArray *uniqueTypeArray;
@property (strong, nonatomic) NSArray *sortedMoneyArray;
@property (strong, nonatomic) NSArray *sortedPercentArray; 
@property (strong, nonatomic) NSDictionary *dict; 
@property (assign, nonatomic) NSInteger currentIndex; 
@property (strong, nonatomic) NSString *currentDateString; 
@property (strong, nonatomic) NSDate *currentDate; 
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSArray *colors; 
@property (strong, nonatomic) NSArray *colorArray; 
@end
@implementation XXJPieViewController
- (NSInteger)currentIndex {
    if (!_currentIndex) {
        _currentIndex = 0; 
    }
    return _currentIndex;
}
- (NSString *)incomeType {
    if (!_incomeType) {
        _incomeType = @"expense"; 
    }
    return _incomeType;
}
- (NSArray *)colors {
    if (!_colors) {
        _colors = @[[UIColor colorWithRed:252/255.0 green:25/255.0 blue:28/255.0 alpha:1],
                    [UIColor colorWithRed:254/255.0 green:200/255.0 blue:46/255.0 alpha:1],
                    [UIColor colorWithRed:217/255.0 green:253/255.0 blue:53/255.0 alpha:1],
                    [UIColor colorWithRed:42/255.0 green:253/255.0 blue:130/255.0 alpha:1],
                    [UIColor colorWithRed:43/255.0 green:244/255.0 blue:253/255.0 alpha:1],
                    [UIColor colorWithRed:18/255.0 green:92/255.0 blue:249/255.0 alpha:1],
                    [UIColor colorWithRed:219/255.0 green:39/255.0 blue:249/255.0 alpha:1],
                    [UIColor colorWithRed:253/255.0 green:105/255.0 blue:33/255.0 alpha:1],
                    [UIColor colorWithRed:255/255.0 green:245/255.0 blue:54/255.0 alpha:1],
                    [UIColor colorWithRed:140/255.0 green:253/255.0 blue:49/255.0 alpha:1],
                    [UIColor colorWithRed:44/255.0 green:253/255.0 blue:218/255.0 alpha:1],
                    [UIColor colorWithRed:29/255.0 green:166/255.0 blue:250/255.0 alpha:1],
                    [UIColor colorWithRed:142/255.0 green:37/255.0 blue:248/255.0 alpha:1],
                    [UIColor colorWithRed:249/255.0 green:31/255.0 blue:181/255.0 alpha:1]];
    }  
    return _colors;
}
- (IBAction)segValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.incomeType = @"expense";
        [self refreshAll];
    } else {
        self.incomeType = @"income";
        [self refreshAll];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.typeTableView.dataSource = self;
    self.pieView.dataSource = self;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    [self setSwipeGesture];
    [self judgeFirstLoadThisView];
}
- (void)judgeFirstLoadThisView {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"haveLoadedAZXPieViewController"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"教學" message:@"首頁顯示本月的收支統計圖，手指左右划動屏幕可改變當前顯示月份，要查看某一類別的詳細情況，點擊該行" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"知道了，不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [defaults setBool:YES forKey:@"haveLoadedAZXPieViewController"];
        }];
        [alert addAction:actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshAll];
}
- (void)viewWillDisappear:(BOOL)animated {
    [self.pieView removeAllLabel];
}
- (void)refreshAll {
    [self.pieView removeAllLabel];
    [self.nullLabel removeFromSuperview];
    [self fetchData];
    [self filterData];
    [self setMoneyLabel];
    [self.typeTableView reloadData];
    [self.pieView reloadData];
}
- (void)setSwipeGesture {
    self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [self.view addGestureRecognizer:self.leftSwipe];
    [self.view addGestureRecognizer:self.rightSwipe];
    self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
}
- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
        [comps setMonth:1];
        self.currentDate = [calendar dateByAddingComponents:comps toDate:self.currentDate options:0];
    } else if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
        [comps setMonth:-1];
        self.currentDate = [calendar dateByAddingComponents:comps toDate:self.currentDate options:0];
    }
    [self refreshAll];
}
- (void)fetchData {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    if (self.currentDateString == nil) {
        self.currentDate = [NSDate date];
        self.currentDateString = [[dateFormatter stringFromDate:self.currentDate] substringToIndex:7];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@ and incomeType == %@", self.currentDateString, self.incomeType]];
    } else {
        self.currentDateString = [[dateFormatter stringFromDate:self.currentDate] substringToIndex:7];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@ and incomeType == %@", self.currentDateString, self.incomeType]];
    }
    NSError *error = nil;
    self.dataArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (self.dataArray.count == 0) {
        self.nullLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        self.nullLabel.text = @"暫無資料";
        self.nullLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        self.nullLabel.textColor = [UIColor lightGrayColor];
        [self.nullLabel sizeToFit];
        self.nullLabel.center = self.view.center;
        [self.view addSubview:self.nullLabel];
    }
}
- (void)filterData {
    NSMutableArray *tmpTypeArray = [NSMutableArray array];
    NSMutableArray *tmpAccountArray = [NSMutableArray array];
    NSDictionary *tmpDict = [NSMutableDictionary dictionary];
    NSMutableArray *tmpMoneyArray = [NSMutableArray array];
    NSMutableArray *tmpDateArray = [NSMutableArray array];
    NSMutableArray *tmpSortedPercentArray = [NSMutableArray array];
    NSMutableArray *tmpColorArray = [NSMutableArray array];
    double tmpMoney = 0;
    for (Account *account in self.dataArray) {
        [tmpTypeArray addObject:account.type];
        [tmpAccountArray addObject:account];
        tmpMoney += [account.money doubleValue];
        [tmpDateArray addObject:[account.date substringToIndex:7]];
    }
    self.totalMoney = tmpMoney;
    NSSet *typeSet = [NSSet setWithArray:[tmpTypeArray copy]];
    tmpTypeArray = [NSMutableArray array];
    NSSet *dateSet = [NSSet setWithArray:[tmpDateArray copy]];
    self.uniqueDateArray = [dateSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO]]];
    for (NSString *type in typeSet) {
        NSArray *array = [tmpAccountArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", type]];
        double totalMoneyInOneType = 0;
        for (Account *account in array) {
            totalMoneyInOneType += [account.money doubleValue];
        }
        [tmpMoneyArray addObject:[NSNumber numberWithDouble:totalMoneyInOneType]];
        [tmpTypeArray addObject:type];
    }
    tmpDict = [NSDictionary dictionaryWithObjects:[tmpMoneyArray copy] forKeys:[tmpTypeArray copy]];
    self.sortedMoneyArray = [tmpMoneyArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO]]];
    NSMutableArray *tmpTypes = [NSMutableArray array];
    NSInteger x = 0;
    double tmpTotalPercent = 0;
    for (NSInteger i = 0; i < self.sortedMoneyArray.count; i++) {
        double money = [self.sortedMoneyArray[i] doubleValue];
        double percent = [[NSString stringWithFormat:@"%.2f",money/self.totalMoney*100] doubleValue];
        if (i != self.sortedMoneyArray.count - 1) {
            [tmpSortedPercentArray addObject:[NSNumber numberWithDouble:percent]];
            tmpTotalPercent += percent;
        } else {
            [tmpSortedPercentArray addObject:[NSNumber numberWithDouble:[[NSString stringWithFormat:@"%.2f", 100-tmpTotalPercent] doubleValue]]];
        }
        [tmpColorArray addObject:self.colors[i%14]];
        if (i > 0 && (self.sortedMoneyArray[i-1] == self.sortedMoneyArray[i])) {
            x++;
        } else {
            x = 0;
        }
        NSString *type = [tmpDict allKeysForObject:self.sortedMoneyArray[i]][x];
        [tmpTypes addObject:type];
    }
    self.sortedPercentArray = [tmpSortedPercentArray copy];
    self.colorArray = [tmpColorArray copy];
    self.uniqueTypeArray = [tmpTypes copy];
}
- (void)setMoneyLabel {
    NSMutableAttributedString *mutString;
    if ([self.incomeType isEqualToString:@"income"]) {
        mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ 總收入: %@", self.currentDateString, [NSNumber numberWithDouble:self.totalMoney]]];
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(13, [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalMoney]].length)];
    } else {
        mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ 總支出: %@", self.currentDateString, [NSNumber numberWithDouble:self.totalMoney]]];
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(13, [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalMoney]].length)];
    }
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 12)];
    [self.moneyLabel setAttributedText:mutString];
}
#pragma mark - UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uniqueTypeArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXJPieTableViewCell *cell = [self.typeTableView dequeueReusableCellWithIdentifier:@"pieTypeCell" forIndexPath:indexPath];
    cell.colorView.backgroundColor = self.colorArray[indexPath.row];
    NSString *type = self.uniqueTypeArray[indexPath.row];
    NSNumber *money = self.sortedMoneyArray[indexPath.row];
    NSNumber *percent = self.sortedPercentArray[indexPath.row];
    NSString *percentString = [NSString stringWithFormat:@"%@", percent];
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@     %@     %@%%", type, money, [self filterLastZeros:percentString]]];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, type.length)];
    NSInteger moneyLength = [NSString stringWithFormat:@"%@", money].length;
    if ([self.incomeType isEqualToString:@"income"]) {
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(type.length + 5, moneyLength)];
    } else {
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(type.length + 5, moneyLength)];
    }
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(type.length + 5 + moneyLength + 5, percentString.length + 1)];
    [cell.moneyLabel setAttributedText:mutString];
    return cell;
}
- (NSString *)filterLastZeros:(NSString *)string {
    NSString *str = string;
    if ([str containsString:@"."] && [string substringFromIndex:[string rangeOfString:@"."].location].length > 3) {
        str = [string substringToIndex:[string rangeOfString:@"."].location+3];
    }
    if ([str containsString:@"."]) {
        if ([[str substringFromIndex:str.length-1] isEqualToString: @"0"]) {
            return [str substringToIndex:str.length-1];
        } else if ([[str substringFromIndex:str.length-2] isEqualToString:@"00"]) {
            return [str substringToIndex:str.length-2];
        } else {
            return str;
        }
    }
    return str;
}
#pragma mark - AZXPieView DataSource
- (NSArray *)percentsForPieView:(XXJPieView *)pieView {
    return self.sortedPercentArray;
}
- (NSArray *)colorsForPieView:(XXJPieView *)pieView {
    return self.colorArray;
}
- (NSArray *)typesForPieView:(XXJPieView *)pieView {
    return self.uniqueTypeArray;
}
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTypeDetail"]) {
        if ([[segue destinationViewController] isKindOfClass:[XXJTypeDetailViewController class]]) {
            XXJTypeDetailViewController *viewController = [segue destinationViewController];
            viewController.date = self.currentDateString;
            viewController.incomeType = self.incomeType;
            NSIndexPath *indexPath = [self.typeTableView indexPathForSelectedRow];
            viewController.type = self.uniqueTypeArray[indexPath.row];
        }
    }
}
@end
