// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String get password => 'Mật khẩu';

  @override
  String get btnLogin => 'ĐĂNG NHẬP';

  @override
  String welcome(String name) {
    return 'Xin chào $name';
  }

  @override
  String get companyName => 'CÔNG TY TNHH OPPERMANN VIỆT NAM';

  @override
  String get erpSystemName => 'Hệ thống Quản trị Nguồn lực Doanh nghiệp';

  @override
  String get loginSystemHeader => 'Đăng nhập Hệ thống';

  @override
  String get loginSubtitle => 'Vui lòng đăng nhập để truy cập ERP';

  @override
  String get copyright => '© 2026 Oppermann Vietnam';

  @override
  String get errorRequired => 'Vui lòng không để trống';

  @override
  String get errorLoginFailed =>
      'Đăng nhập thất bại. Vui lòng kiểm tra lại tài khoản.';

  @override
  String get errorNetwork => 'Lỗi kết nối. Vui lòng kiểm tra mạng hoặc Server.';

  @override
  String get errorGeneric => 'Đã xảy ra lỗi hệ thống';

  @override
  String get dashboard => 'Tổng quan';

  @override
  String get production => 'Sản xuất';

  @override
  String get inventory => 'Kho vận';

  @override
  String get sales => 'Bán hàng';

  @override
  String get hr => 'Nhân sự';

  @override
  String get reports => 'Báo cáo';

  @override
  String get settings => 'Cài đặt';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get totalOrders => 'Tổng đơn hàng';

  @override
  String get activePlans => 'Kế hoạch đang chạy';

  @override
  String get lowStock => 'Sắp hết hàng';

  @override
  String get revenue => 'Doanh thu';

  @override
  String get recentActivities => 'Hoạt động gần đây';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get close => 'Đóng';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get remove => 'Xóa';

  @override
  String get actions => 'Hành động';

  @override
  String get required => 'Bắt buộc';

  @override
  String get successAdded => 'Thêm thành công';

  @override
  String get successUpdated => 'Cập nhật thành công';

  @override
  String get successDeleted => 'Xóa thành công';

  @override
  String get contact => 'Liên hệ';

  @override
  String get processing => 'Đang xử lý...';

  @override
  String get note => 'Ghi chú';

  @override
  String get notice => 'Thông báo';

  @override
  String get featureUnderDevelopment =>
      'Tính năng này đang được phát triển.\nVui lòng quay lại sau.';

  @override
  String pageContent(String path) {
    return 'Nội dung trang: $path';
  }

  @override
  String get erpSystemShort => 'Data System';

  @override
  String get oppermannHeader => 'OPPERMANN';

  @override
  String get searchPlaceholder => 'Tìm kiếm...';

  @override
  String get productionOutput => 'Sản lượng sản xuất';

  @override
  String get justNow => 'Vừa xong';

  @override
  String get statusDone => 'Hoàn thành';

  @override
  String get departmentTitle => 'Quản lý Bộ phận';

  @override
  String get deptName => 'Tên bộ phận';

  @override
  String get deptDesc => 'Mô tả';

  @override
  String get searchDept => 'Tìm kiếm bộ phận...';

  @override
  String get addDept => 'Thêm bộ phận';

  @override
  String get editDept => 'Sửa bộ phận';

  @override
  String get deleteDept => 'Xóa bộ phận';

  @override
  String confirmDelete(String name) {
    return 'Bạn có chắc muốn xóa bộ phận $name không?';
  }

  @override
  String get warehouseTitle => 'Quản lý Kho hàng';

  @override
  String get warehouseSubtitle => 'Quản lý vị trí lưu trữ & tồn kho';

  @override
  String get searchWarehouseHint => 'Tìm theo tên hoặc vị trí...';

  @override
  String get addWarehouse => 'Thêm Kho';

  @override
  String get editWarehouse => 'Sửa Kho';

  @override
  String get deleteWarehouse => 'Xóa Kho';

  @override
  String confirmDeleteWarehouse(String name) {
    return 'Bạn có chắc muốn xóa kho \'$name\'? Hành động này không thể hoàn tác.';
  }

  @override
  String get warehouseName => 'Tên Kho';

  @override
  String get location => 'Vị trí';

  @override
  String get description => 'Mô tả';

  @override
  String get noWarehouseFound => 'Không tìm thấy kho nào';

  @override
  String get noDescription => 'Không có mô tả';

  @override
  String get cannotOpenMap => 'Không thể mở bản đồ';

  @override
  String get employeeTitle => 'Nhân viên';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Số điện thoại';

  @override
  String get address => 'Địa chỉ';

  @override
  String get position => 'Chức vụ';

  @override
  String get department => 'Phòng ban';

  @override
  String get searchEmployee => 'Tìm nhân viên...';

  @override
  String get addEmployee => 'Thêm nhân viên';

  @override
  String get editEmployee => 'Sửa nhân viên';

  @override
  String get deleteEmployee => 'Xóa nhân viên';

  @override
  String confirmDeleteEmployee(String name) {
    return 'Xóa nhân viên $name?';
  }

  @override
  String get selectDept => 'Chọn phòng ban';

  @override
  String get totalDepartments => 'Tổng số bộ phận';

  @override
  String get status => 'Trạng thái';

  @override
  String get active => 'Hoạt động';

  @override
  String get inactive => 'Ngưng hoạt động';

  @override
  String get members => 'Thành viên';

  @override
  String get supplierTitle => 'Nhà cung cấp';

  @override
  String get supplierName => 'Tên nhà cung cấp';

  @override
  String get searchSupplier => 'Tìm nhà cung cấp...';

  @override
  String get addSupplier => 'Thêm nhà cung cấp';

  @override
  String get editSupplier => 'Sửa nhà cung cấp';

  @override
  String get deleteSupplier => 'Xóa nhà cung cấp';

  @override
  String confirmDeleteSupplier(String name) {
    return 'Bạn có chắc muốn xóa $name không?';
  }

  @override
  String get paymentTerm => 'Điều khoản thanh toán';

  @override
  String get taxCode => 'Mã số thuế';

  @override
  String get leadTime => 'Thời gian giao hàng';

  @override
  String get days => 'Ngày';

  @override
  String get contactPerson => 'Người liên hệ';

  @override
  String get shortName => 'Tên viết tắt';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get originType => 'Nguồn gốc';

  @override
  String get isActiveProvider => 'Nhà cung cấp hoạt động?';

  @override
  String get yarnTitle => 'Kho Sợi';

  @override
  String get yarnName => 'Tên sợi';

  @override
  String get itemCode => 'Mã sản phẩm';

  @override
  String get yarnType => 'Loại sợi';

  @override
  String get color => 'Màu sắc';

  @override
  String get origin => 'Xuất xứ';

  @override
  String get supplier => 'Nhà cung cấp';

  @override
  String get searchYarn => 'Tìm sợi (tên, mã)...';

  @override
  String get addYarn => 'Thêm sợi';

  @override
  String get editYarn => 'Sửa sợi';

  @override
  String get deleteYarn => 'Xóa sợi';

  @override
  String confirmDeleteYarn(String name) {
    return 'Xóa sợi $name?';
  }

  @override
  String get selectSupplier => 'Chọn nhà cung cấp';

  @override
  String get noYarnFound => 'Không tìm thấy dữ liệu sợi';

  @override
  String get yarnLotTitle => 'Lô Sợi';

  @override
  String get lotCode => 'Mã lô';

  @override
  String get importDate => 'Ngày nhập';

  @override
  String get totalKg => 'Tổng kg';

  @override
  String get rollCount => 'Số cuộn';

  @override
  String get warehouseLoc => 'Vị trí kho';

  @override
  String get containerCode => 'Số container';

  @override
  String get driver => 'Tài xế';

  @override
  String get receiver => 'Người nhận';

  @override
  String get searchYarnLot => 'Tìm mã lô...';

  @override
  String get addYarnLot => 'Nhập lô sợi';

  @override
  String get editYarnLot => 'Sửa lô sợi';

  @override
  String get deleteYarnLot => 'Xóa lô sợi';

  @override
  String confirmDeleteYarnLot(String code) {
    return 'Xóa lô $code?';
  }

  @override
  String get selectYarn => 'Chọn loại sợi';

  @override
  String get selectEmployee => 'Chọn nhân viên';

  @override
  String get materialTitle => 'Nguyên vật liệu';

  @override
  String get materialMaster => 'Danh mục Vật tư';

  @override
  String get materialBreadcrumb => 'Kho vận > Vật tư';

  @override
  String get materialName => 'Tên Vật Tư';

  @override
  String get materialCode => 'Mã VT';

  @override
  String get materialType => 'Loại';

  @override
  String get quantity => 'Số lượng';

  @override
  String get unit => 'Đơn vị';

  @override
  String get importedBy => 'Người nhập';

  @override
  String get searchMaterial => 'Tìm vật liệu...';

  @override
  String get searchMaterialHint => 'Tìm Mã, Tên...';

  @override
  String get totalMaterials => 'Tổng vật tư';

  @override
  String get addMaterial => 'Thêm Vật tư';

  @override
  String get editMaterial => 'Sửa vật liệu';

  @override
  String get deleteMaterial => 'Xóa vật liệu';

  @override
  String confirmDeleteMaterial(String name) {
    return 'Xóa vật liệu $name?';
  }

  @override
  String get noMaterialFound => 'Không tìm thấy vật liệu';

  @override
  String get selectImporter => 'Chọn nguyên vật liệu';

  @override
  String get selectUnit => 'Chọn đơn vị';

  @override
  String get hsCode => 'Mã HS';

  @override
  String get denier => 'Denier';

  @override
  String get denierHint => 'Denier (VD: 1000D)';

  @override
  String get filament => 'Số sợi (Filament)';

  @override
  String get minStock => 'Tồn tối thiểu';

  @override
  String get uomBasePurchase => 'ĐVT Mua (Gốc)';

  @override
  String get uomProduction => 'ĐVT Sản xuất';

  @override
  String get uomBP => 'Đơn vị tính (Mua/SX)';

  @override
  String get specs => 'Thông số kỹ thuật';

  @override
  String get unitTitle => 'Đơn vị tính';

  @override
  String get unitName => 'Tên đơn vị';

  @override
  String get searchUnit => 'Tìm đơn vị...';

  @override
  String get addUnit => 'Thêm đơn vị';

  @override
  String get editUnit => 'Sửa đơn vị';

  @override
  String get deleteUnit => 'Xóa đơn vị';

  @override
  String confirmDeleteUnit(String name) {
    return 'Xóa đơn vị $name?';
  }

  @override
  String get noUnitFound => 'Không tìm thấy đơn vị nào';

  @override
  String get machineTitle => 'Máy móc thiết bị';

  @override
  String get machineName => 'Tên máy';

  @override
  String get totalLines => 'Số dây/line';

  @override
  String get purpose => 'Mục đích sử dụng';

  @override
  String get area => 'Khu vực';

  @override
  String get searchMachine => 'Tìm máy...';

  @override
  String get addMachine => 'Thêm máy';

  @override
  String get editMachine => 'Sửa thông tin máy';

  @override
  String get deleteMachine => 'Xóa máy';

  @override
  String confirmDeleteMachine(String name) {
    return 'Xóa máy $name?';
  }

  @override
  String get noMachineFound => 'Không tìm thấy máy nào';

  @override
  String get running => 'Đang chạy';

  @override
  String get stopped => 'Đang dừng';

  @override
  String get maintenance => 'Bảo trì';

  @override
  String get spinning => 'Lên sợi';

  @override
  String get yarnOut => 'Hết sợi';

  @override
  String get unassignedArea => 'Khu vực chung';

  @override
  String get statusRunning => 'Chạy máy';

  @override
  String get statusSpinning => 'Lên sợi';

  @override
  String get statusStopped => 'Dừng / Lỗi';

  @override
  String get statusMaintenance => 'Bảo trì';

  @override
  String get viewHistory => 'Xem lịch sử';

  @override
  String machineHistoryTitle(String name) {
    return 'Lịch sử: $name';
  }

  @override
  String get noHistoryData => 'Chưa có lịch sử hoạt động.';

  @override
  String reasonLabel(String reason) {
    return 'Lý do: $reason';
  }

  @override
  String durationFormatMin(String min) {
    return '$min phút';
  }

  @override
  String durationFormatHour(int hour, int min) {
    return '${hour}h ${min}p';
  }

  @override
  String get timeCurrent => 'Hiện tại';

  @override
  String changeStatusTitle(String status) {
    return 'Đổi trạng thái: $status';
  }

  @override
  String confirmStatusChangeMsg(String name, String status) {
    return 'Bạn muốn chuyển máy $name sang $status?';
  }

  @override
  String get reasonIssue => 'Lý do / Mô tả sự cố';

  @override
  String get enterReason =>
      'Nhập lý do dừng máy... (VD: Đứt sợi, Hỏng motor...)';

  @override
  String get reasonRequired => 'Vui lòng nhập lý do';

  @override
  String get captureEvidence => 'Chụp ảnh hiện trường';

  @override
  String get openingCamera => 'Đang mở Camera...';

  @override
  String get cameraFeatureDev => 'Tính năng chụp ảnh đang phát triển';

  @override
  String get shiftTitle => 'Ca làm việc';

  @override
  String get shiftName => 'Tên ca';

  @override
  String get searchShift => 'Tìm ca làm việc...';

  @override
  String get addShift => 'Thêm ca';

  @override
  String get editShift => 'Sửa ca';

  @override
  String get deleteShift => 'Xóa ca';

  @override
  String confirmDeleteShift(String name) {
    return 'Xóa ca $name?';
  }

  @override
  String get noShiftFound => 'Không tìm thấy ca làm việc';

  @override
  String get basketTitle => 'Rổ chứa';

  @override
  String get basketCode => 'Mã rổ';

  @override
  String get basketTitleVS2 => 'Rổ';

  @override
  String get basketBreadcrumb => 'Kho vận > Rổ chứa';

  @override
  String get totalBaskets => 'Tổng số rổ';

  @override
  String get tareWeight => 'Trọng lượng bì (kg)';

  @override
  String get searchBasket => 'Tìm mã rổ...';

  @override
  String get addBasket => 'Thêm rổ';

  @override
  String get editBasket => 'Sửa rổ';

  @override
  String get deleteBasket => 'Xóa rổ';

  @override
  String confirmDeleteBasket(String code) {
    return 'Xóa rổ $code?';
  }

  @override
  String get noBasketFound => 'Không tìm thấy rổ nào';

  @override
  String basketFound(String code) {
    return 'Đã tìm thấy rổ: $code';
  }

  @override
  String get basketNotFoundOrNotReady =>
      'Không tìm thấy rổ hoặc rổ chưa sẵn sàng';

  @override
  String get stReady => 'Sẵn sàng';

  @override
  String get stInUse => 'Đang sử dụng';

  @override
  String get stHolding => 'Đang lưu kho';

  @override
  String get stDamaged => 'Hư hỏng';

  @override
  String get errorTareWeightInvalid => 'Trọng lượng bì phải lớn hơn 0';

  @override
  String get dyeColorTitle => 'Màu nhuộm';

  @override
  String get colorName => 'Tên màu';

  @override
  String get hexCode => 'Mã màu (Hex)';

  @override
  String get searchColor => 'Tìm màu...';

  @override
  String get addColor => 'Thêm màu';

  @override
  String get editColor => 'Sửa màu';

  @override
  String get deleteColor => 'Xóa màu';

  @override
  String confirmDeleteColor(String name) {
    return 'Xóa màu $name?';
  }

  @override
  String get noColorFound => 'Không tìm thấy màu nào';

  @override
  String get invalidHex => 'Mã màu không hợp lệ (VD: #FF0000)';

  @override
  String get productTitle => 'Sản phẩm';

  @override
  String get productImage => 'Hình ảnh';

  @override
  String get searchProduct => 'Tìm sản phẩm...';

  @override
  String get addProduct => 'Thêm sản phẩm';

  @override
  String get editProduct => 'Sửa sản phẩm';

  @override
  String get deleteProduct => 'Xóa sản phẩm';

  @override
  String confirmDeleteProduct(String code) {
    return 'Xóa sản phẩm $code?';
  }

  @override
  String get noProductFound => 'Không tìm thấy sản phẩm';

  @override
  String get uploadImage => 'Tải ảnh lên';

  @override
  String get standardTitle => 'Tiêu chuẩn';

  @override
  String get standardCode => 'Mã tiêu chuẩn';

  @override
  String get product => 'Sản phẩm';

  @override
  String get dyeColor => 'Màu nhuộm';

  @override
  String get width => 'Khổ (mm)';

  @override
  String get thickness => 'Độ dày (mm)';

  @override
  String get strength => 'Lực đứt (daN)';

  @override
  String get elongation => 'Độ giãn (%)';

  @override
  String get colorFastDry => 'Bền màu (Khô)';

  @override
  String get colorFastWet => 'Bền màu (Ướt)';

  @override
  String get deltaE => 'Sai lệch màu (Delta E)';

  @override
  String get appearance => 'Ngoại quan';

  @override
  String get weftDensity => 'Mật độ ngang (pick/10cm)';

  @override
  String get weight => 'Trọng lượng (g/m)';

  @override
  String get searchStandard => 'Tìm tiêu chuẩn...';

  @override
  String get addStandard => 'Thêm tiêu chuẩn';

  @override
  String get editStandard => 'Sửa tiêu chuẩn';

  @override
  String get deleteStandard => 'Xóa tiêu chuẩn';

  @override
  String confirmDeleteStandard(String code) {
    return 'Xóa tiêu chuẩn $code?';
  }

  @override
  String get noStandardFound => 'Không tìm thấy tiêu chuẩn';

  @override
  String get scheduleTitle => 'Lịch làm việc';

  @override
  String get workDate => 'Ngày làm việc';

  @override
  String get employee => 'Nhân viên';

  @override
  String get shift => 'Ca làm việc';

  @override
  String get startTime => 'Giờ bắt đầu';

  @override
  String get endTime => 'Giờ kết thúc';

  @override
  String get searchSchedule => 'Tìm lịch...';

  @override
  String get addSchedule => 'Xếp lịch';

  @override
  String get editSchedule => 'Sửa lịch';

  @override
  String get deleteSchedule => 'Xóa lịch';

  @override
  String confirmDeleteSchedule(String name, String date) {
    return 'Xóa lịch của $name ngày $date?';
  }

  @override
  String get noScheduleFound => 'Không tìm thấy lịch làm việc';

  @override
  String get filterDate => 'Lọc theo ngày';

  @override
  String get errorDuplicateSchedule =>
      'Xung đột: Nhân viên này đã có ca làm việc trong ngày này rồi.';

  @override
  String get errorUnknown => 'Đã xảy ra lỗi không xác định';

  @override
  String get weavingTicketTitle => 'Phiếu Rổ Dệt';

  @override
  String get ticketCode => 'Mã phiếu';

  @override
  String get loadDate => 'Ngày lên sợi';

  @override
  String get date => 'Ngày';

  @override
  String get timeIn => 'Thời gian vào';

  @override
  String get empIn => 'Người vào';

  @override
  String get timeOut => 'Thời gian ra';

  @override
  String get empOut => 'Người ra';

  @override
  String get tage => 'Trọng lượng rổ';

  @override
  String get machineInfo => 'Máy / Line';

  @override
  String get yarnInfo => 'Lô sợi / Ngày nạp';

  @override
  String get standardData => 'Standard Specifications';

  @override
  String get weightInfo => 'Tổng / Tịnh / Bì (kg)';

  @override
  String get lengthKnots => 'Dài (m) / Số nối';

  @override
  String get employees => 'Nhân viên vận hành';

  @override
  String get timeInOut => 'Giờ Vào / Ra';

  @override
  String get inspections => 'Kết quả kiểm tra QC';

  @override
  String get addTicket => 'Tạo phiếu mới';

  @override
  String get stageName => 'Công đoạn';

  @override
  String get gross => 'Tổng trọng lượng';

  @override
  String get density => 'Mật độ sợi ngang';

  @override
  String get tension => 'Lực căng';

  @override
  String get bowing => 'Độ lệch (Bowing)';

  @override
  String get inspector => 'Người kiểm tra';

  @override
  String get noTicketSelected => 'Chọn một phiếu để xem chi tiết';

  @override
  String get deleteTicket => 'Xóa phiếu';

  @override
  String confirmDeleteTicket(String code) {
    return 'Xóa phiếu $code?';
  }

  @override
  String get deleteInspection => 'Xóa kiểm tra';

  @override
  String get machineAndMaterial => 'Máy & Nguyên vật liệu';

  @override
  String get generalInfo => 'Thông tin chung';

  @override
  String get personnel => 'Nhân sự';

  @override
  String get resultsUpdateOnly => 'Kết quả (chỉ cập nhật)';

  @override
  String get machineOperation => 'Vận hành Máy dệt';

  @override
  String get selectProductBefore => 'Chọn sản phẩm trước';

  @override
  String get line => 'Line';

  @override
  String get assignBasket => 'Gán rổ';

  @override
  String get selectBasket => 'Chọn rổ sẵn sàng';

  @override
  String get scanBarcode => 'Quét mã vạch / Nhập mã';

  @override
  String get scanBarcodeSubline => 'Quét mã rổ tại đây để tự chọn';

  @override
  String get addInspection => 'Thêm kiểm tra';

  @override
  String get viewTicket => 'Xem phiếu';

  @override
  String get editTicket => 'Sửa phiếu';

  @override
  String get currentBasket => 'Rổ hiện tại';

  @override
  String get noActiveBasket => 'Trống';

  @override
  String get confirmRelease => 'Kết thúc phiếu và ra rổ?';

  @override
  String get basketAssigned => 'Đã gán rổ thành công';

  @override
  String get releaseBasket => 'Ra rổ';

  @override
  String get finishTicket => 'Kết thúc phiếu';

  @override
  String get grossWeight => 'Trọng lượng cả bì (kg)';

  @override
  String get netWeight => 'Trọng lượng tịnh (kg)';

  @override
  String get length => 'Chiều dài (m)';

  @override
  String get splice => 'Số mối nối';

  @override
  String get bow => 'Cong';

  @override
  String get employeeOut => 'Người nhận / NV Tháo';

  @override
  String get ticketDetails => 'Chi tiết Phiếu';

  @override
  String get inspectionHistory => 'Lịch sử kiểm tra';

  @override
  String get newInspection => 'Kiểm tra mới';

  @override
  String get confirmReleaseTitle => 'Xác nhận kết thúc';

  @override
  String get confirmReleaseMsg =>
      'Bạn có chắc muốn kết thúc phiếu này và tháo rổ ra không?';

  @override
  String get saveSuccess => 'Lưu thành công';

  @override
  String get noTicketsFoundForThisDate =>
      'Không có phiếu sản xuất nào trong ngày này';

  @override
  String get noBasket => 'Không có rổ';

  @override
  String get productionInfo => 'Thông tin sản xuất';

  @override
  String get timeAndPersonnel => 'Thời gian & nhân sự';

  @override
  String get output => 'Sản lượng';

  @override
  String get noInspectionsRecorded => 'Chưa có dữ liệu kiểm tra';

  @override
  String get inspection => 'Kiểm tra chất lượng';

  @override
  String get measurements => 'Thông số đo đạc';

  @override
  String get userManagementTitle => 'Quản lý Tài khoản';

  @override
  String get searchUser => 'Tìm tài khoản (tên, email)...';

  @override
  String get noUserFound => 'Không tìm thấy tài khoản nào.';

  @override
  String get lastLogin => 'Đăng nhập cuối';

  @override
  String get notLinked => 'Chưa liên kết';

  @override
  String get superuser => 'SUPERUSER';

  @override
  String get never => 'Chưa từng';

  @override
  String get addUser => 'Thêm tài khoản';

  @override
  String get editUser => 'Sửa tài khoản';

  @override
  String get addNewUser => 'Thêm tài khoản mới';

  @override
  String get linkToEmployee => 'Liên kết Nhân viên';

  @override
  String get linkEmployeeHelper =>
      'Chọn nhân viên để liên kết với tài khoản này';

  @override
  String get noEmployeeLinkedOption => '--- Không liên kết ---';

  @override
  String get passwordRequiredNew => 'Bắt buộc đối với tài khoản mới';

  @override
  String get newPasswordPlaceholder => 'Mật khẩu mới (Để trống nếu giữ nguyên)';

  @override
  String get role => 'Vai trò';

  @override
  String get isActiveSwitch => 'Đang hoạt động';

  @override
  String get isSuperuserSwitch => 'Là Superuser';

  @override
  String get confirmDeleteTitle => 'Xác nhận xóa';

  @override
  String confirmDeleteUserMsg(String name) {
    return 'Bạn có chắc muốn xóa tài khoản $name?';
  }

  @override
  String get prodStatsTitle => 'Thống Kê Sản Lượng';

  @override
  String get exportExcel => 'Xuất Excel';

  @override
  String get refreshData => 'Làm mới dữ liệu';

  @override
  String get recalculateToday => 'Tính toán lại (Hôm nay)';

  @override
  String get searchProductHint => 'Tìm theo mã sản phẩm, ghi chú...';

  @override
  String get filterToday => 'Hôm nay';

  @override
  String get filterYesterday => 'Hôm qua';

  @override
  String get filter7Days => '7 ngày qua';

  @override
  String get filterThisMonth => 'Tháng này';

  @override
  String get filterLastMonth => 'Tháng trước';

  @override
  String get filterThisQuarter => 'Quý này';

  @override
  String get filterThisYear => 'Năm nay';

  @override
  String get filterCustom => 'Tùy chọn ngày';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get totalProduction => 'TỔNG SẢN LƯỢNG';

  @override
  String get totalLength => 'TỔNG CHIỀU DÀI';

  @override
  String get itemCount => 'SỐ MÃ';

  @override
  String get noStatsData => 'Không có dữ liệu cho giai đoạn này';

  @override
  String get machines => 'Máy';

  @override
  String get copySuccess => 'Đã sao chép vào bộ nhớ tạm!';

  @override
  String get exporting => 'Đang tạo file Excel...';

  @override
  String exportError(String error) {
    return 'Lỗi xuất file: $error';
  }

  @override
  String get purchaseOrderTitle => 'Đơn Mua Hàng';

  @override
  String get purchaseOrderSubtitle => 'Quản lý thu mua và nhà cung cấp';

  @override
  String get createPO => 'TẠO ĐƠN';

  @override
  String get searchPO => 'Tìm số PO...';

  @override
  String get poNumber => 'Số PO';

  @override
  String get vendor => 'Nhà cung cấp';

  @override
  String get orderDate => 'Ngày đặt hàng';

  @override
  String get eta => 'Ngày về dự kiến (ETA)';

  @override
  String get incoterm => 'Điều khoản TM (Incoterm)';

  @override
  String get exchangeRate => 'Tỷ giá';

  @override
  String get totalAmount => 'Tổng tiền';

  @override
  String get poDetailTitle => 'Chi tiết Đơn hàng';

  @override
  String get orderItems => 'Danh sách hàng';

  @override
  String get addItem => 'Thêm hàng';

  @override
  String get noItemsPO => 'Chưa có vật tư trong đơn này.';

  @override
  String get addMaterialPrompt => 'Nhấn \'+ Thêm Vật tư\' để bắt đầu.';

  @override
  String get materialInfo => 'THÔNG TIN VẬT TƯ';

  @override
  String get tapToSearch => 'Chạm để tìm vật tư...';

  @override
  String get transactionDetails => 'CHI TIẾT GIAO DỊCH';

  @override
  String get unitPrice => 'Đơn giá';

  @override
  String get lineTotal => 'Thành tiền';

  @override
  String get estimatedTotal => 'Tổng tạm tính';

  @override
  String get confirmAdd => 'Xác nhận thêm';

  @override
  String get searchMaterialPlaceholder => 'Nhập tên, mã, quy cách...';

  @override
  String get deletePO => 'Xóa Đơn hàng';

  @override
  String confirmDeletePO(String number) {
    return 'Bạn có chắc muốn xóa đơn $number?';
  }

  @override
  String get bomTitle => 'Quản lý Định mức';

  @override
  String get bomSubtitle => 'Sản xuất > Định mức Nguyên liệu';

  @override
  String get addBOM => 'THÊM BOM';

  @override
  String get noBOMFound => 'Không tìm thấy định mức nào';

  @override
  String get bomCode => 'Mã BOM';

  @override
  String get bomName => 'Tên BOM';

  @override
  String get baseQty => 'Số lượng gốc';

  @override
  String get version => 'Phiên bản';

  @override
  String get viewIngredients => 'Xem thành phần';

  @override
  String get newBOM => 'Tạo BOM mới';

  @override
  String get editBOM => 'Sửa thông tin BOM';

  @override
  String get selectProduct => 'Chọn sản phẩm';

  @override
  String get chooseProduct => 'Chọn một sản phẩm';

  @override
  String get loadingProducts => 'Đang tải sản phẩm...';

  @override
  String get setActiveVersion => 'Đặt làm phiên bản chính';

  @override
  String get bomCodeRequired => 'Vui lòng nhập mã BOM';

  @override
  String get productRequired => 'Vui lòng chọn sản phẩm!';

  @override
  String get deleteBOM => 'Xóa BOM';

  @override
  String confirmDeleteBOM(String code) {
    return 'Xóa BOM $code? Hành động này sẽ xóa tất cả chi tiết vật tư.';
  }

  @override
  String get bomIngredientsConfig => 'Cấu hình thành phần BOM';

  @override
  String get matId => 'Mã VL';

  @override
  String get ends => 'Số sợi';

  @override
  String get stdQty => 'Định mức';

  @override
  String get wastage => 'Hao hụt';

  @override
  String get grossQty => 'Tổng';

  @override
  String get saveDetail => 'Lưu chi tiết';

  @override
  String get editMaterialDetail => 'Sửa chi tiết vật tư';

  @override
  String get importDeclarationTitle => 'Tờ khai Hải quan';

  @override
  String get importDeclarationSubtitle =>
      'Quản lý tờ khai hải quan (E31, A11...)';

  @override
  String get newDeclaration => 'THÊM TỜ KHAI';

  @override
  String get searchDeclarationHint => 'Tìm số tờ khai, Invoice, B/L...';

  @override
  String get noDeclarationFound => 'Không tìm thấy tờ khai nào';

  @override
  String get declarationNo => 'Số tờ khai';

  @override
  String get declarationDate => 'Ngày đăng ký';

  @override
  String get declarationType => 'Loại hình';

  @override
  String get invoiceBill => 'Invoice / Vận đơn';

  @override
  String get totalTax => 'Tổng thuế';

  @override
  String get invoiceAbbr => 'Inv';

  @override
  String get billOfLadingAbbr => 'B/L';

  @override
  String get invoiceNo => 'Số Invoice';

  @override
  String get billOfLading => 'Vận đơn (B/L)';

  @override
  String get createDeclaration => 'Tạo tờ khai';

  @override
  String get editDeclaration => 'Sửa tờ khai';

  @override
  String get totalTaxAmount => 'Tổng tiền thuế';

  @override
  String get deleteDeclaration => 'Xóa tờ khai';

  @override
  String confirmDeleteDeclaration(String number) {
    return 'Bạn có chắc muốn xóa tờ khai $number không?';
  }

  @override
  String get declarationDetailTitle => 'Chi tiết Tờ khai';

  @override
  String get declarationItemsList => 'Danh sách hàng';

  @override
  String get addDeclarationItem => 'Thêm hàng';

  @override
  String get noDeclarationItems => 'Chưa có hàng hóa trong tờ khai.';

  @override
  String get addDeclarationItemPrompt => 'Nhấn \'+ Thêm hàng\' để bắt đầu.';

  @override
  String get editDeclarationItem => 'Sửa hàng hóa';

  @override
  String get addDeclarationItemTitle => 'Thêm hàng vào Tờ khai';

  @override
  String get materialLabel => 'Vật tư';

  @override
  String get selectMaterialPlaceholder => 'Chọn vật tư...';

  @override
  String get actualHSCode => 'HS Code (Thực tế)';

  @override
  String get quantityLabel => 'Số lượng';

  @override
  String get unitPriceLabel => 'Đơn giá';

  @override
  String get errorSelectMaterial => 'Vui lòng chọn vật tư!';

  @override
  String get searchMaterialTitle => 'Tìm kiếm Vật tư';

  @override
  String get deleteItemTitle => 'Xóa dòng hàng';

  @override
  String get confirmDeleteItemMsg => 'Bạn có chắc muốn xóa dòng này không?';

  @override
  String get registrationDate => 'Ngày ĐK';

  @override
  String get updateAction => 'Cập nhật';

  @override
  String get stockInTitle => 'Nhập kho';

  @override
  String get stockInSubtitle => 'Quản lý phiếu nhập kho';

  @override
  String get tabMaterial => 'Nguyên vật liệu';

  @override
  String get tabSemiFinished => 'Bán thành phẩm';

  @override
  String get tabFinished => 'Thành phẩm';

  @override
  String get goodsList => 'Danh sách hàng hóa';

  @override
  String get addRow => 'Thêm dòng';

  @override
  String get saveReceipt => 'LƯU PHIẾU NHẬP';

  @override
  String get receiptNumber => 'Mã phiếu nhập';

  @override
  String get receivingWarehouse => 'Kho nhập';

  @override
  String get sendingDepartment => 'Bộ phận chuyển đến';

  @override
  String get semiFinishedCode => 'Mã BTP';

  @override
  String get semiFinishedName => 'Tên Bán Thành Phẩm';

  @override
  String get goodQty => 'SL Đạt';

  @override
  String get badQty => 'SL Hỏng';

  @override
  String get source => 'Nguồn nhập';

  @override
  String get carton => 'Thùng/Kiện';

  @override
  String get selectPlaceholder => 'Chọn...';

  @override
  String get cancelAction => 'Hủy bỏ';

  @override
  String generalInfoTitle(String title) {
    return 'Thông tin chung - $title';
  }

  @override
  String get createReceiptTitle => 'Tạo Phiếu Nhập Mới';

  @override
  String get editReceiptTitle => 'Chi Tiết Phiếu Nhập kho Nguyên vật liệu';

  @override
  String get logisticsInfo => 'Thông tin Logistics';

  @override
  String get byPO => 'Theo đơn mua (PO)';

  @override
  String get customsDeclarationOptional => 'Tờ khai hải quan (Tùy chọn)';

  @override
  String get noSelection => '--- Không chọn ---';

  @override
  String get loadingDeclaration => 'Đang tải tờ khai...';

  @override
  String get createdBy => 'Người tạo phiếu';

  @override
  String get containerNumber => 'Số Container';

  @override
  String get sealNumber => 'Số Seal (Chì)';

  @override
  String get poQtyKg => 'SL PO (Kg)';

  @override
  String get poQtyCones => 'SL PO (Cuộn)';

  @override
  String get actualQtyKg => 'Thực Nhập (Kg)';

  @override
  String get actualQtyCones => 'Thực Nhập (Cuộn)';

  @override
  String get pallets => 'Kiện';

  @override
  String get supplierBatch => 'LÔ NCC';

  @override
  String get selectWarehouse => 'Chọn kho';

  @override
  String get noMaterialsYet => 'Chưa có vật tư nào';

  @override
  String get confirmDeleteDetailMsg =>
      'Xóa dòng này sẽ cập nhật lại số lượng PO. Tiếp tục?';

  @override
  String get searchStockInHint => 'Tìm theo số phiếu, PO, Container...';

  @override
  String get createStockIn => 'TẠO PHIẾU';

  @override
  String get reload => 'Tải lại';

  @override
  String get noStockInFound =>
      'Không tìm thấy phiếu nhập nào trong khoảng thời gian này.';

  @override
  String get containerSeal => 'Container / Seal';

  @override
  String confirmDeleteStockIn(String number) {
    return 'Bạn có chắc muốn xóa phiếu $number?';
  }

  @override
  String errorLabel(String message) {
    return 'Lỗi: $message';
  }

  @override
  String errorLoadMaterials(String error) {
    return 'Lỗi tải vật tư: $error';
  }

  @override
  String get actualImportLabel => 'THỰC NHẬP (ACTUAL)';

  @override
  String get errorNegative => 'Không âm';

  @override
  String get batchManagement => 'Quản lý Lô (Batch)';

  @override
  String get batchSubtitle => 'Theo dõi lô vật tư & trạng thái QC';

  @override
  String get addBatch => 'THÊM LÔ';

  @override
  String get searchBatchHint => 'Tìm theo Mã Lô...';

  @override
  String get internalCode => 'MÃ NỘI BỘ';

  @override
  String get originCountry => 'XUẤT XỨ';

  @override
  String get qcStatus => 'TRẠNG THÁI QC';

  @override
  String get qcNote => 'GHI CHÚ QC';

  @override
  String get traceability => 'TRUY XUẤT';

  @override
  String get linkedReceipt => 'Phiếu Nhập';

  @override
  String get linkedReceiptId => 'ID Chi tiết Phiếu';

  @override
  String get linkedReceiptIdHelper => 'Nhập ID chi tiết phiếu nhập (Tùy chọn)';

  @override
  String get mfgDate => 'Ngày SX';

  @override
  String get expDate => 'Hạn SD';

  @override
  String get qualityControl => 'Kiểm soát Chất lượng (QC)';

  @override
  String get generalNote => 'Ghi chú chung';

  @override
  String get isActiveBatchHint => 'Tắt nếu lô hàng bị hủy hoặc không dùng nữa';

  @override
  String confirmDeleteBatchMsg(String code) {
    return 'Bạn có chắc muốn xóa lô $code?';
  }

  @override
  String get noBatchesFound => 'Không tìm thấy lô hàng nào';

  @override
  String unknownMaterial(int id) {
    return 'Vật tư không xác định #$id';
  }

  @override
  String get materialPurchaseOrders => 'Đơn mua NVL';

  @override
  String get importExport => 'Nhập Xuất kho';

  @override
  String get stockOutHeader => 'Xuất kho';

  @override
  String get materialExport => 'Xuất kho NVL';

  @override
  String get semiFinishedExport => 'Xuất bán thành phẩm';

  @override
  String get finishedProductExport => 'Xuất thành phẩm';

  @override
  String get inventoryStock => 'Tồn kho';

  @override
  String get semiFinishedProducts => 'Bán thành phẩm';

  @override
  String get finishedProducts => 'Thành phẩm';

  @override
  String get materialBatches => 'Lô nguyên vật liệu';

  @override
  String get weaving => 'Dệt';

  @override
  String get machineBasketInfo => 'Thông tin Máy & Rổ dệt';

  @override
  String get weavingManagement => 'Quản lý sản xuất dệt';

  @override
  String get dyeing => 'Nhuộm';

  @override
  String get printing => 'In';

  @override
  String get safeFinishedProducts => 'Thành phẩm an toàn';

  @override
  String get packing => 'Đóng gói';

  @override
  String get rolling => 'Cuộn';

  @override
  String get cutting => 'Cắt';

  @override
  String get adminTitle => 'Administrator';

  @override
  String get activityLog => 'Nhật ký hoạt động';

  @override
  String get quickAccess => 'Truy cập nhanh';

  @override
  String get rememberMe => 'Ghi nhớ đăng nhập';
}
