#import "XXJNewAccountTableViewController.h"
#import "AppDelegate.h"
#import "XXJAccountViewController.h"
#import "UIViewController+BackButtonHandler.h"
#import "VENCalculatorInputTextField.h"
@interface XXJNewAccountTableViewController () <UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *moneyTextField; 
@property (strong, nonatomic) VENCalculatorInputTextField *customTextField; 
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITextView *detailTextView; 
@property (strong, nonatomic) UIDatePicker *datePicker; 
@property (strong, nonatomic) UIPickerView *pickerView; 
@property (strong, nonatomic) NSString *incomeType; 
@property (strong, nonatomic) UIView *shadowView; 
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) NSMutableArray *incomeArray; 
@property (strong, nonatomic) NSMutableArray *expenseArray;
@property (weak, nonatomic) NSIndexPath *index;
@end
@implementation XXJNewAccountTableViewController
#pragma mark - view did load
- (BOOL)isSegueFromTableView {
    if (!_isSegueFromTableView) {
        _isSegueFromTableView = NO; 
    }
    return _isSegueFromTableView;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.customTextField.frame.size.width == 0) {
        self.customTextField.frame = self.moneyTextField.frame;
        [[self.moneyTextField superview] bringSubviewToFront:self.customTextField];
        self.customTextField.textAlignment = NSTextAlignmentRight;
        self.customTextField.placeholder = @"輸入金額";
        self.customTextField.textColor = [UIColor redColor];
    }
    if (self.isSegueFromTableView) {
        self.customTextField.text = self.accountInSelectedRow.money;
        if ([self.incomeType isEqualToString:@"income"]) {
            self.customTextField.textColor = [UIColor blueColor];
        } else {
            self.customTextField.textColor = [UIColor redColor];
        }
    }
    [self.customTextField becomeFirstResponder];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
    tap.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tap];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self customizeRightButton];
    if (self.isSegueFromTableView) {
        self.dateLabel.text = self.accountInSelectedRow.date;
        self.detailTextView.text = self.accountInSelectedRow.detail;
        self.incomeType = self.accountInSelectedRow.incomeType;
        self.typeLabel.text = self.accountInSelectedRow.type;
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        self.dateLabel.text = [dateFormatter stringFromDate:[NSDate date]];
        self.detailTextView.delegate = self;
        self.detailTextView.text = @"詳細描述(選填)";
        self.detailTextView.textColor = [UIColor lightGrayColor];
        self.incomeType = @"expense";
    }
    [self judgeFirstLoadThisView];
    self.customTextField = [[VENCalculatorInputTextField alloc] initWithFrame:CGRectZero];
    [[self.moneyTextField superview] addSubview:self.customTextField];
    [self.customTextField becomeFirstResponder];
}
- (void)judgeFirstLoadThisView {
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    if (![self.userDefaults boolForKey:@"haveLoadedAZXNewAccountTableViewController"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"教學" message:@"輸入金額、類別、日期以及詳細(選填)，點右上角按鈕保存" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"知道了，不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.userDefaults setBool:YES forKey:@"haveLoadedAZXNewAccountTableViewController"];
        }];
        [alert addAction:actionOK];
        [self.customTextField resignFirstResponder];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewController:didPassDate:)]) {
    }
}
#pragma mark - tap screen methods
- (void)tapScreen:(UITapGestureRecognizer *)gesture {
    CGFloat touchY = [gesture locationInView:[self.tableView superview]].y;
    if (touchY < 99 || touchY > 149) {
        [self.customTextField resignFirstResponder];
        self.customTextField.text = [self deleteDotsInString:self.customTextField.text];
    }
    if (touchY < 285 || touchY > 369) {
        [self.detailTextView resignFirstResponder];
    }
}
- (void)setUpDatePicker {
    [self insertShadowView];
    if (self.datePicker == nil) {
        self.datePicker = [[UIDatePicker alloc] init];
        self.datePicker.datePickerMode = UIDatePickerModeDate;
        self.datePicker.center = self.view.center;
        self.datePicker.backgroundColor = [UIColor whiteColor];
        self.datePicker.layer.cornerRadius = 10;
        self.datePicker.layer.masksToBounds = YES;
        [self.view addSubview:self.datePicker];
    } else {
        [self.view addSubview:self.datePicker];
    }
    [self.datePicker addTarget:self action:@selector(datePickerValueDidChanged:) forControlEvents:UIControlEventValueChanged];
}
- (void)setUpPickerView {
    [self setDefaultDataForPickerView];
    [self insertShadowView];
    if (self.pickerView == nil) {
        self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 300, 180)];
        self.pickerView.center = self.view.center;
        self.pickerView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.pickerView];
    } else {
        [self.view addSubview:self.pickerView];
    }
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    if ([self.incomeType isEqualToString:@"expense"]) {
        self.typeLabel.text = self.expenseArray[0];
    } else {
        self.typeLabel.text = self.incomeArray[0];
    }
}
#pragma mark - customize right button
- (void)customizeRightButton {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(preserveButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightItem;
}
- (void)preserveButtonPressed:(UIButton *)sender {
    if ([self.typeLabel.text isEqualToString:@"點擊輸入"] || [self.customTextField.text isEqualToString:@""]) {
        [self presentAlertControllerWithMessage:@"金錢數額和類型都是必填的"];
    } else if ([self.customTextField.text componentsSeparatedByString:@"."].count > 2) {
        [self presentAlertControllerWithMessage:@"輸入金額不格式不符"];
    } else if ([self moneyTextContainsCharacterOtherThanNumber]) {
        [self presentAlertControllerWithMessage:@"輸入金額只能是數字"];
    } else {
        if (self.isSegueFromTableView) {
            self.accountInSelectedRow.type = self.typeLabel.text;
            self.accountInSelectedRow.detail = self.detailTextView.text;
            [self setMoneyToAccount:self.accountInSelectedRow];
            self.accountInSelectedRow.incomeType = self.incomeType;
            self.accountInSelectedRow.date = self.dateLabel.text;
        } else {
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            Account *account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:appDelegate.managedObjectContext];
            account.type = self.typeLabel.text;
            [self setMoneyToAccount:account];
            account.incomeType = self.incomeType;
            account.date = self.dateLabel.text;
            if (![self.detailTextView.text isEqualToString:@"詳細描述(選填)"]) {
                account.detail = self.detailTextView.text;
            } else {
                account.detail = @"";
            }
        }
        [(AppDelegate *)[[UIApplication sharedApplication]delegate] saveContext];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (void)setMoneyToAccount:(Account *)account {
    NSString *moneyInput = self.customTextField.text;
    if ([moneyInput containsString:@"."]) {
        NSString *dotString = [moneyInput substringFromIndex:[moneyInput rangeOfString:@"."].location]; 
        if (dotString.length == 1) {
            account.money = [moneyInput substringToIndex:moneyInput.length - 1];
        } else if (dotString.length == moneyInput.length) {
            account.money = [@"0" stringByAppendingString:dotString];
        } else {
            account.money = [moneyInput substringToIndex:[moneyInput rangeOfString:@"."].location + 2];
        }
    } else {
        account.money = self.customTextField.text;
    }
}
- (void)presentAlertControllerWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    [alertController addAction:action];
    [self.customTextField resignFirstResponder];
    [self.detailTextView resignFirstResponder];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (BOOL)moneyTextContainsCharacterOtherThanNumber {
    if (!([self isPureInt:self.customTextField.text] || [self isPureFloat:self.customTextField.text])) {
        return YES;
    } else {
        return NO;
    }
}
- (NSString *)deleteDotsInString:(NSString *)string {
    NSArray *subStrings = [string componentsSeparatedByString:@","];
    NSString *newString = [NSString string];
    for (NSInteger i = 0; i < subStrings.count; i++) {
        newString = [newString stringByAppendingString:subStrings[i]];
    }
    return newString;
}
- (BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}
- (BOOL)isPureFloat:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    float val;
    return[scan scanFloat:&val] && [scan isAtEnd];
}
- (BOOL)navigationShouldPopOnBackButton {
    if (self.isSegueFromTableView) {
        if (![self.customTextField.text isEqualToString:self.accountInSelectedRow.money] || ![self.typeLabel.text isEqualToString:self.accountInSelectedRow.type] || ![self.dateLabel.text isEqualToString:self.accountInSelectedRow.date] || ![self.detailTextView.text isEqualToString:self.accountInSelectedRow.detail]) {
            [self alertControllerAskWhetherStoreWithMessage:@"確定返回？修改將不會被保存"];
            return NO;
        }
    } else if (![self.customTextField.text isEqualToString:@""] && ![self.typeLabel.text isEqualToString:@"點擊輸入"]) {
        [self alertControllerAskWhetherStoreWithMessage:@"確定返回？這筆帳單將不會被保存"];
        return NO;
    }
    return YES;
}
- (void)alertControllerAskWhetherStoreWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提醒" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"不，留在頁面" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else {
        return 1;
    }
}
#pragma mark - insert shadow view and add button
- (void)insertShadowView {
    [self insertGrayView];
    [self.shadowView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerSelected)]];
    self.navigationItem.rightBarButtonItem = nil;
}
#pragma mark - set data for pickerView
- (void)setDefaultDataForPickerView {
    self.incomeArray = [self.userDefaults objectForKey:@"incomeAZX"];
    self.expenseArray = [self.userDefaults objectForKey:@"expenseAZX"];
    if (self.incomeArray.count == 0 || self.expenseArray.count == 0) {
        self.incomeArray = [NSMutableArray arrayWithArray:@[@"工資薪酬", @"獎金福利", @"生意經營", @"投資理財", @"彩票中獎", @"銀行利息", @"其他收入"]];
        self.expenseArray = [NSMutableArray arrayWithArray:@[@"餐飲食品", @"交通路費", @"日常用品", @"服裝首飾", @"學習教育", @"煙酒消費", @"房租水電", @"網上購物", @"運動健身", @"電子產品", @"化妝護理", @"醫療體檢", @"遊戲娛樂", @"外出旅遊", @"油費維護", @"慈善捐贈", @"其他支出"]];
        [self.userDefaults setObject:self.incomeArray forKey:@"incomeAZX"];
        [self.userDefaults setObject:self.expenseArray forKey:@"expenseAZX"];
        for (NSString *string in self.incomeArray) {
            [self.userDefaults setObject:string forKey:string];
        }
        for (NSString *string in self.expenseArray) {
            [self.userDefaults setObject:string forKey:string];
        }
    }
}
#pragma mark - date value changed
- (void)datePickerValueDidChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    self.dateLabel.text = [dateFormatter stringFromDate:sender.date];
}
#pragma mark - picker selected
- (void)pickerSelected {
    self.navigationItem.rightBarButtonItem = nil;
    [self.pickerView removeFromSuperview];
    [self.datePicker removeFromSuperview];
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;
    [self customizeRightButton];
}
#pragma mark - detail text View delegate methods
- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString: @"詳細描述(選填)"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
}
- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"詳細描述(選填)";
        textView.textColor = [UIColor lightGrayColor];
    }
}
#pragma mark - insert a shadow view
- (void)insertGrayView {
    self.shadowView = [[UIView alloc] initWithFrame:self.view.frame];
    self.shadowView.backgroundColor = [UIColor grayColor];
    self.shadowView.alpha = 0.5;
    [self.view addSubview:self.shadowView];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath.row == 1) {
        [self.view bringSubviewToFront:self.pickerView];
    } else if (indexPath.row == 2) {
        [self.view bringSubviewToFront:self.datePicker];
    }
}
#pragma mark - UIPickerView dataSource
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        return 2; 
    } else {
        if ([self.incomeType isEqualToString:@"income"]) {
            return self.incomeArray.count;
        } else if ([self.incomeType isEqualToString:@"expense"]) {
            return self.expenseArray.count;
        } else {
            return 0;
        }
    }
}
#pragma mark - UIPickerView delegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) { 
        if (row == 0) {
            return @"支出";
        } else {
            return @"收入";
        }
    } else {
        if ([self.incomeType isEqualToString:@"income"]) {
            return self.incomeArray[row];
        } else {
            return self.expenseArray[row];
        }
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if ([indexPath section] == 0) {
        switch ([indexPath row]) {
            case 0:
                [self.customTextField becomeFirstResponder];
                break;
            case 1:
                [self setUpPickerView];
                break;
            case 2:
                [self setUpDatePicker];
                break;
            default:
                break;
        }
    }
    else {
        [self.detailTextView becomeFirstResponder];
    }
}
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        if (row == 0) {
            self.incomeType = @"expense";
            self.customTextField.textColor = [UIColor redColor];
            self.typeLabel.text = self.expenseArray[0];
        } else {
            self.incomeType = @"income";
            self.customTextField.textColor = [UIColor blueColor];
            self.typeLabel.text = self.incomeArray[0];
        }
        [self.pickerView reloadComponent:1];
    } else {
        if ([self.incomeType isEqualToString:@"income"]) {
            self.typeLabel.text = self.incomeArray[row];
        } else {
            self.typeLabel.text = self.expenseArray[row];
        }
    }
}
@end
