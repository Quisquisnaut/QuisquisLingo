QuisquisLingo - Hướng dẫn Windows
================================

QuisquisLingo là ứng dụng học ngôn ngữ dành cho người học và người tạo khóa
học. Ứng dụng kết hợp các bài học có cấu trúc, bài tập tương tác, hoạt động âm
thanh và công cụ ôn tập, đồng thời cung cấp công cụ để tạo và chỉnh sửa khóa học
ngôn ngữ.

Ứng dụng được thiết kế cho cả người muốn học một ngôn ngữ lẫn tác giả, giáo viên
hoặc người dùng khác muốn xây dựng khóa học riêng.

Để xem nhanh bằng hình ảnh cách QuisquisLingo hoạt động, hãy mở
QQL infographic.png được cung cấp trong gói ứng dụng.

Để khởi động QuisquisLingo, hãy chạy QuisquisLingo.exe.

SỬ DỤNG GÓI
-----------

Gói này chứa ứng dụng QQL. Hãy giải nén toàn bộ tệp ZIP trước khi khởi động và
giữ tất cả tệp được cung cấp cùng thư mục data ở cùng một nơi. Không phân phối,
di chuyển, xóa hoặc đổi tên riêng lẻ các tệp EXE hay DLL.

KIỂM TRA KHI KHỞI ĐỘNG
----------------------

Trước khi khởi động, QuisquisLingo kiểm tra các tệp bắt buộc trong gói, khả năng
tương thích với Windows và Media Foundation. Các bước kiểm tra này không bao giờ
tải xuống hoặc cài đặt phần mềm, yêu cầu quyền quản trị, thay đổi registry hay
sửa đổi Windows.

Với một sự cố vẫn có thể tiếp tục, một thông báo có Continue anyway và Cancel
sẽ xuất hiện. Continue anyway thử khởi động QQL; Cancel đóng chương trình. Nếu
thiếu một tệp chương trình thiết yếu, thông báo sẽ có Close vì cần tải xuống và
giải nén lại toàn bộ gói.

Hỗ trợ Wine ở trạng thái Experimental. Việc thiếu Media Foundation trong Wine
có thể khiến chương trình không khởi động hoặc các tính năng âm thanh và phương
tiện không hoạt động.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Gói đầy đủ bao gồm các tệp runtime Microsoft Visual C++ x64 sau:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Nếu thiếu bất kỳ tệp nào, hãy tải xuống lại gói Windows QuisquisLingo đầy đủ và
giải nén toàn bộ. Chỉ sử dụng nguồn chính thức của Microsoft cho runtime
installer và không bao giờ tải từng tệp DLL từ trang web của bên thứ ba.

Thông tin chính thức từ Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Các phiên bản Windows N có thể cần Microsoft Media Feature Pack để sử dụng chức
năng âm thanh và phương tiện. Media Feature Pack thường có trong Windows
Optional Features. Trên một số phiên bản Windows N, Media Feature Pack có thể
không xuất hiện trong Optional Features. Trong trường hợp đó, hãy tải Media
Feature Pack phù hợp với phiên bản Windows của bạn từ trang web Microsoft.

Khởi động lại Windows sau khi cài đặt Media Feature Pack. QuisquisLingo không tự
động tải xuống hay cài đặt gói này và không thay đổi cài đặt hệ thống.

TEXT-TO-SPEECH
--------------

QuisquisLingo sử dụng các giọng nói được cài đặt trong Windows. Ngôn ngữ và giọng
nói có sẵn phụ thuộc vào các thành phần ngôn ngữ và giọng nói Windows đã cài trên
máy tính. Nếu không có giọng nói tương thích, hãy cài thành phần phù hợp qua phần
cài đặt Windows.

Audio Settings > Test Voice chỉ đọc văn bản bạn nhập và sử dụng ngôn ngữ giọng
nói được cấu hình cho khóa học đã chọn.

NHẬT KÝ VÀ CHẨN ĐOÁN
---------------------

Crash log chính được lưu tại:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log kiểm tra khi khởi động được lưu tại:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug cung cấp các tùy chọn chẩn đoán. Log chỉ nằm trên máy tính cục
bộ và không được tự động tải lên.

KHẮC PHỤC SỰ CỐ
----------------

1. Giải nén hoàn toàn toàn bộ tệp ZIP.
2. Chạy QuisquisLingo.exe từ gói đã giải nén.
3. Nếu có thông báo thiếu runtime DLL, hãy tải xuống và giải nén lại gói đầy đủ
   trước khi cân nhắc runtime installer chính thức của Microsoft.
4. Nếu cần Media Feature Pack, hãy làm theo hướng dẫn trên và khởi động lại
   Windows sau khi cài đặt.
5. Nếu QQL vẫn không khởi động, hãy giữ lại toàn bộ thông báo lỗi và các tệp log
   hiện có để được hỗ trợ.
