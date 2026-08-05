# 拍拍枕远程控制

配置完成日期: 2026-08-05

## 概述
涂鸦WiFi红外遥控器连接牛油果拍拍哄睡枕，通过VPS远程控制。

## 技术信息
- 数据中心: 美国 (openapi.tuyaus.com)
- 认证: HMAC-SHA256，凭证存在VPS的 tuya-config.json 中

## VPS端点
- POST /api/pillow/pat-start — 开机 + 拍打
- POST /api/pillow/pat-stop — 停拍 + 关机
- POST /api/pillow/cmd — 单独按键 (body: {"key": "power/pat/fast/slow/timer"})

## IR按键ID
- power: 1785939919
- pat: 1785939927
- fast: 1785939936
- slow: 1785939943
- timer: 1785939949

## 操作顺序
- 启动拍打: 先发 power，等1.5秒，再发 pat
- 停止拍打: 先发 pat，等1.5秒，再发 power

## 注意事项
- 红外遥控器偶尔会离线，可能需要在涂鸦App中检查或重启遥控器
- 凭证不存入代码/记忆库/对话，只在VPS本地配置文件中
