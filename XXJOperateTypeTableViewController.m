#import "XXJOperateTypeTableViewController.h"
#import "XXJOperateTypeTableViewCell.h"
#import "AppDelegate.h"
#import "Account.h"
#import <CoreData/CoreData.h>
@interface XXJOperateTypeTableViewController ()
@property (nonatomic, strong) NSMutableArray *typeArray;
@property (nonatomic, strong) NSString *incomeType;
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
@implementation XXJOperateTypeTableViewController
- (NSString *)incomeType {
    if (!_incomeType) {
        _incomeType = @"expense"; 
    }
    return _incomeType;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.defaults = [NSUserDefaults standardUserDefaults];
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    if ([self.operationType isEqualToString:@"deleteAndMoveType"]) {
        [self judgeFirstLoadThisView];
        [self.tableView setEditing:YES animated:YES];
    }
}
- (void)judgeFirstLoadThisView {
    if (![self.defaults boolForKey:@"haveLoadedAZXOperateTypeTableViewControllerAddAndDelete"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"教學" message:@"點擊類別左邊的紅色減號刪除，按住並拖動右邊的三槓符號進行位置排序" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"知道了，不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.defaults setBool:YES forKey:@"haveLoadedAZXOperateTypeTableViewControllerAddAndDelete"];
        }];
        [alert addAction:actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
}
- (IBAction)segControlChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.incomeType = @"expense";
        [self refreshAll];
        [self.tableView reloadData];
    } else {
        self.incomeType = @"income";
        [self refreshAll];
        [self.tableView reloadData];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshAll];
}
- (void)refreshAll {
    if ([self.incomeType isEqualToString:@"income"]) {
        self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"incomeAZX"]];
    } else {
        self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"expenseAZX"]];
    }
}
#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.typeArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXJOperateTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"operateTypeCell" forIndexPath:indexPath];
    cell.type.text = self.typeArray[indexPath.row];
    cell.image.image = [UIImage imageNamed:[self.defaults objectForKey:cell.type.text]];
    if ([self.operationType isEqualToString:@"changeType"]) {
        cell.operation.text = @"重命名";
        cell.operation.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRename:)];
        [cell.operation addGestureRecognizer:tapLabel];
    } else if ([self.operationType isEqualToString:@"deleteAndMoveType"]) {
        cell.operation.text = @"";
    }
    return cell;
}
#pragma mark - Add or delete methods
- (void)addType {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加類別" message:@"輸入新類別名稱" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"點擊輸入";
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確認" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.typeArray addObject:alert.textFields[0].text];
        [self.tableView reloadData];
        [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - Rename methods
- (void)tapRename:(UITapGestureRecognizer *)gesture {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gesture locationInView:self.tableView]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改名稱" message:@"請輸入新類別名稱" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = self.typeArray[indexPath.row];
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *imageName = [self.defaults objectForKey:self.typeArray[indexPath.row]];
        [self.defaults removeObjectForKey:self.typeArray[indexPath.row]];
        [self.defaults setObject:imageName forKey:alert.textFields[0].text];
        self.typeArray[indexPath.row] = alert.textFields[0].text;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - Move tableView delegate methods
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.operationType isEqualToString:@"deleteAndMoveType"]) {
        return YES;
    } else {
        return NO;
    }
}
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSString *typeToMove = self.typeArray[fromIndexPath.row];
    [self.typeArray removeObjectAtIndex:fromIndexPath.row];
    [self.typeArray insertObject:typeToMove atIndex:toIndexPath.row];
    [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.defaults removeObjectForKey:self.typeArray[indexPath.row]];
        [self removeAllAccountOfOneType:self.typeArray[indexPath.row]];
        [self.typeArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
    }
}
- (void)removeAllAccountOfOneType:(NSString *)type {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"type == %@", type]];
    NSError *error = nil;
    NSArray *accounts = [self.managedObjectContext executeFetchRequest:request error:&error];
    for (Account *account in accounts) {
        [self.managedObjectContext deleteObject:account];
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @" 刪除 ";
}
@end
