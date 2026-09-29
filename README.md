# Scene View Kit

Scene view kiểu Unity **chạy bên trong game Cocos Creator đang chạy**: chia đôi màn
hình, camera quan sát bay tự do, gizmo, click chọn object, và công cụ
move/rotate/scale — tất cả trong lúc game vẫn chạy.

Cocos Creator có panel Scene lúc edit, nhưng khi Play thì không có gì. Đó là khoảng
trống mà kit này lấp.

## Cài vào một project

Chép đúng **một file** `scripts/sync-scene-view.bat` vào gốc project rồi chạy.

Lần đầu nó hỏi kit ở đâu (URL git hoặc thư mục), rồi nhớ luôn vào
`%LOCALAPPDATA%\scene-view-kit-source.txt`. Từ project thứ hai trở đi, double-click
là xong, không hỏi gì nữa.

Nó sẽ:

1. Lấy kit về — `git submodule` nếu project là repo git, `git clone` nếu không
2. Chép script vào `assets\scene-view\`
3. Bật `geometry-renderer` trong `settings\v2\packages\engine.json` nếu project đã
   tắt — gizmo cần module này
4. Tự cập nhật chính nó từ kit
5. Xong. Bấm Play, `F1` bật/tắt

**Không phải tạo node hay kéo component.** `AutoBoot.ts` tự gắn vào mọi scene.

## Sau khi có remote

Điền `KIT_URL` ở đầu `sync-scene-view.bat` bằng URL git của repo này. Kể từ đó
một file bat là đủ cho mọi máy, mọi project, và tất cả cập nhật từ một chỗ — không
còn phải trả lời câu hỏi nào.

## Cấu trúc

| Đường dẫn | Vai trò |
|---|---|
| `assets/scene-view/` | Toàn bộ mã nguồn runtime. Chỉ import từ `cc` và `cc/env` |
| `scripts/sync-scene-view.bat` | File duy nhất cần chép vào project |

`.meta` **không** được commit: đây là script thuần, không tham chiếu asset nào, nên
để mỗi project tự sinh UUID an toàn hơn là mang một bộ UUID đi khắp nơi.

## Yêu cầu

Cocos Creator **3.8.x**. Các bản khác chưa thử — cầu nối sang Hierarchy của editor
dựa vào API không công khai (`Editor.Selection`), nên có thể gãy ở bản khác.

Tài liệu đầy đủ về cách dùng, phím tắt và các quyết định thiết kế nằm ở
[assets/scene-view/README.md](assets/scene-view/README.md).
