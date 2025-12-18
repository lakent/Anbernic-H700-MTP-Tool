# Anbernic H700 MTP 管理工具

**Anbernic H700 系列官方系统 (Stock OS)** 使用 MTP (媒体传输协议) 脚本。可以直接使用 USB 数据线在电脑上管理掌机内的文件，无需频繁插拔 SD 卡。

目前 **仅在 Anbernic RG CubeXX 官方系统(Stock OS) 上进行测试**。

## 安装与使用 (Usage)
1. 下载本项目，提取 `MTP功能管理器.sh` 文件， `mtp` 文件夹， `res` 文件夹。
2. 复制到掌机 SD 卡的 `ROMS/APPS` 目录下。
4. 在掌机 **应用中心 -> Apps** 菜单中启动脚本。

## 操作说明 (Controls)
- **Y 键**: 开启 MTP 模式。
- **A 键**: 关闭 MTP 模式并清理后台环境。
- **B 键**: 临时开启 MTP 模式。
- **菜单键**: 退出脚本界面。

## 技术原理 (Technical Details)
- 基于 `ConfigFS` 构建 USB 函数链。
- 使用 `FunctionFS (ffs)` 处理 MTP 数据响应。
- 通过 `ln -sf` 动态链接配置文件。

## 致谢 (Credits)
- **[Anbernic](https://anbernic.com/)**: 参考 Anbernic 官方固件脚本。
- **[muOS](https://github.com/MustardOS/internal/pull/223/)**: 感谢 muOS 开发团队。
- **[uMTP-Responder](https://github.com/viveris/uMTP-Responder)**: 核心驱动基于 Viveris Technologies 的开源实现。
- **资源图片**: 脚本背景图片由 **豆包 AI** 基于 SSH 功能管理器脚本图片生成。
