#import "XXJAddTypeViewController.h"
#import "XXJAddTypeCollectionViewCell.h"
#import "UIViewController+BackButtonHandler.h"
@interface XXJAddTypeViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *typeCollectionView;
@property (weak, nonatomic) IBOutlet UIImageView *showImage;
@property (weak, nonatomic) IBOutlet UITextField *typeTextField;
@property (strong, nonatomic) NSMutableArray *typeArray; 
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) NSString *incomeType;
@property (strong, nonatomic) NSMutableArray *incomeArray; 
@property (strong, nonatomic) NSMutableArray *expenseArray; 
@property (strong, nonatomic) UIView *shadowView; 
@property (weak, nonatomic) IBOutlet UIButton *localPhotoButton; 
@property (strong, nonatomic) UIImage *selectedPhoto; 
@property (strong, nonatomic) NSIndexPath *selectedIndexOfImage; 
@property (assign, nonatomic) BOOL isFromAlbum; 
@end
@implementation XXJAddTypeViewController
- (NSString *)incomeType {
    if (!_incomeType) {
        _incomeType = @"expense"; 
    }
    return _incomeType;
}
- (IBAction)typeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.incomeType = @"expense";
    } else {
        self.incomeType = @"income";
    }
}
- (IBAction)localPhoto:(UIButton *)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
        photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        photoPicker.delegate = self;
        photoPicker.allowsEditing = YES;
        photoPicker.modalPresentationStyle = UIModalPresentationPopover;
        [self presentViewController:photoPicker animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [photoPicker popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentationController.sourceView = self.localPhotoButton;
        presentationController.sourceRect = self.localPhotoButton.bounds;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.typeCollectionView.delegate = self;
    self.typeCollectionView.dataSource = self;
    self.typeTextField.delegate = self;
    self.typeCollectionView.backgroundColor = [UIColor whiteColor];
    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.typeTextField becomeFirstResponder];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(rightBarItemPressed)];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.expenseArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"expenseAZX"]];
    self.incomeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"incomeAZX"]];
    if (![self.defaults objectForKey:@"imagesShowInAZXAddTypeViewController"]) {
        self.typeArray = [NSMutableArray arrayWithArray:@[@"餐飲食品", @"交通路費", @"日常用品", @"服裝首飾", @"學習教育", @"煙酒消費", @"房租水電", @"網上購物", @"運動健身", @"電子產品", @"化妝護理", @"醫療體檢", @"遊戲娛樂", @"外出旅遊", @"油費維護", @"慈善捐贈", @"其他支出", @"工資薪酬", @"獎金福利", @"生意經營", @"投資理財", @"彩票中獎", @"銀行利息", @"其他收入"]];
        [self.defaults setObject:self.typeArray forKey:@"imagesShowInAZXAddTypeViewController"];
    } else {
        self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"imagesShowInAZXAddTypeViewController"]];
    }
}
- (void)rightBarItemPressed {
    if ([self.expenseArray containsObject:self.typeTextField.text] || [self.incomeArray containsObject:self.typeTextField.text]) {
        [self popoverAlertControllerWithMessage:@"類別名已存在，請使用新的類別名"];
    } else if (self.typeTextField.text && self.showImage.image) {
        [self savePhotoWithTypeName];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self popoverAlertControllerWithMessage:@"圖片與類別名都需要輸入"];
    }
}
- (void)popoverAlertControllerWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}
- (BOOL)navigationShouldPopOnBackButton {
    if (![self.typeTextField.text isEqualToString:@""] && self.showImage.image) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"還未保存，是否返回？" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *OK = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [alert addAction:OK];
        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    }
    return YES;
}
- (void)savePhotoWithTypeName {
    if (self.isFromAlbum) {
        [self savePhotoFromAlbum];
    } else {
        NSInteger index = [self.typeCollectionView indexPathsForSelectedItems][0].row;
        NSString *imageName = self.typeArray[index];
        [self.defaults setObject:imageName forKey:self.typeTextField.text];
    }
}
- (void)savePhotoFromAlbum {
    NSData *data;
    if (UIImagePNGRepresentation(self.selectedPhoto) == nil) {
        data = UIImageJPEGRepresentation(self.selectedPhoto, 1.0);
    }
    else {
        data = UIImagePNGRepresentation(self.selectedPhoto);
    }
    NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *type = self.typeTextField.text;
    [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.png", type]] contents:data attributes:nil];
    NSString *filePath = [[NSString alloc]initWithFormat:@"%@%@",DocumentsPath, [NSString stringWithFormat:@"/%@.png", type]];
    [self.defaults setObject:filePath forKey:type];
    if ([self.incomeType isEqualToString:@"income"]) {
        [self.incomeArray addObject:type];
        [self.defaults setObject:self.incomeArray forKey:@"incomeAZX"];
    } else {
        [self.expenseArray addObject:type];
        [self.defaults setObject:self.expenseArray forKey:@"expenseAZX"];
    }
    [self.typeArray addObject:filePath];
    [self.defaults setObject:self.typeArray forKey:@"imagesShowInAZXAddTypeViewController"];
}
#pragma mark - textField delegate methods
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self insertTransparentView];
    [self.shadowView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textFieldResignKeyboard)]];
}
- (void)insertTransparentView {
    self.shadowView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.shadowView];
    [self.view bringSubviewToFront:self.shadowView];
}
- (void)textFieldResignKeyboard {
    [self.typeTextField resignFirstResponder];
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;
}
#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.typeArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XXJAddTypeCollectionViewCell *cell = [self.typeCollectionView dequeueReusableCellWithReuseIdentifier:@"typeImageCell" forIndexPath:indexPath];
    cell.image.image = [UIImage imageNamed:self.typeArray[indexPath.row]];
    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [UIColor lightGrayColor];
    cell.selectedBackgroundView = backgroundView;
    return cell;
}
#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    XXJAddTypeCollectionViewCell *cell = (XXJAddTypeCollectionViewCell *)[self.typeCollectionView cellForItemAtIndexPath:indexPath];
    self.showImage.image = cell.image.image;
    self.isFromAlbum = NO;
}
#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat totalWidth = self.typeCollectionView.frame.size.width;
    return CGSizeMake(totalWidth / 4 , totalWidth / 4);
}
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^ {
        if ([self.typeCollectionView indexPathsForSelectedItems].count != 0) {
            [self.typeCollectionView deselectItemAtIndexPath:[self.typeCollectionView indexPathsForSelectedItems][0] animated:YES];
        }
    }];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        self.selectedPhoto = [info objectForKey:@"UIImagePickerControllerEditedImage"];
        self.showImage.image = self.selectedPhoto;
    }
    self.isFromAlbum = YES;
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
