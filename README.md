# 🧭 南方见 (NanFangJian)

> **“风过千山，我们在南方见。”**  
> 一款融合俄罗斯先锋派构成主义（Constructivism）美学、奶龙元气守护与专属人物指针的艺术级指南针 App。

---

## 📲 直接下载安装 (Android & iOS)

无需配置复杂的开发环境，直接前往 Releases 页面下载安装包：

👉 **[点击前往 Releases 下载双端最新安装包](https://github.com/yolo12z/nanfangjian/releases)**

### 📱 各平台安装指引：
* **Android (安卓手机)**：
  - 下载页面中的 `app-release.apk`，在手机上直接点击安装即可。
* **iOS (苹果 iPhone / iPad)**：
  - 下载页面中的 `NanFangJian-iOS.ipa` 文件；
  - 苹果设备使用电脑端工具（**爱思助手** / **AltStore** / **TrollStore 巨魔**）签名后导入 iPhone 即可使用；
  - 也可通过同一局域网用 iPhone Safari 浏览器打开 H5 页面后点击 **“分享 -> 添加到主屏幕”** 获得原汁原味的轻 App 体验！

---

## ✨ 软件特色与设计语言

1. **头顶指正南（独特指针算法）**：
   - 传统指南针以红针指北，而在「南方见」中，人物形象正上方（头顶/举手方向）在现实三维空间中**恒定死死咬住地理正南方（South）**；
   - 算法通过 `(180° - heading)` 进行实时地理逆向补偿，旋转平稳丝滑。

2. **至上主义与构成主义美学**：
   - 采用红、黑、羊皮纸黄先锋几何海报作为全屏视觉基调；
   - 工业风粗黑体方位代号（`SOUTH // 南方见 · 锁定`、`NORTH // 极北`）与大字号角度仪表；
   - 对准正南方时，触发专属的红色与金色高能双环呼吸脉冲动效。

3. **奶龙实体伴游**：
   - 经典的双手抱胸奶龙浮空立像环绕在罗盘外轨道，与人物指针同步漫游，目光穿透屏幕；
   - 正南方锁定状态触发“✦ 坐标对齐 · 南方已至 ✦”金色共鸣。

4. **全天候桌面悬浮指针（浮窗）**：
   - 支持开启微型（约 68dp）透明悬浮窗；
   - 在手机桌面、微信、抖音等任意 App 界面上方自由拖拽，即便切到后台也能全天候实时指向南方。

---

## 🛠️ 本地开发与编译

本项目基于 **Flutter** 跨平台引擎开发：

```bash
# 1. 克隆本项目
git clone https://github.com/yolo12z/nanfangjian.git

# 2. 进入项目目录
cd nanfangjian

# 3. 安装依赖
flutter pub get

# 4. 连接安卓/苹果真机调试
flutter run

# 5. 打包 Android Release APK
flutter build apk --release

# 6. 打包 iOS 应用
flutter build ios --release --no-codesign
```

---

## 📄 开源许可

本项目遵循 [MIT License](LICENSE) 开源协议。
