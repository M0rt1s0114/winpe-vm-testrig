# 踩坑记录

全部是在真实 WinPE + 无头 VMware 上实测出来的。

## 1. 无头 VMware 也能"看得见"

- `vmcli.exe <vmx> MKS captureScreenshot <png>` 在 `nogui` 模式下可用
- `vmcli.exe <vmx> MKS sendKeySequence <seq>` 可注入按键(需 HID 码形式)
- `vmrun captureScreen` 会报 `Anonymous guest operations are not allowed`,
  不要用它,用 `vmcli`

## 2. 自制 PE ISO 不需要管理员权限

宿主机 `C:\Windows\Boot` 里就有全套引导素材:

| 用途 | 文件 |
|---|---|
| BIOS El Torito | `C:\Windows\Boot\DVD\PCAT\etfsboot.com` |
| BIOS 引导管理器 | `C:\Windows\Boot\PCAT\bootmgr` |
| BIOS BCD 模板 | `C:\Windows\Boot\DVD\PCAT\BCD` |
| RAM 磁盘 | `C:\Windows\Boot\DVD\PCAT\boot.sdi` |
| UEFI El Torito | `C:\Windows\Boot\DVD\EFI\en-US\efisys.bin` |
| UEFI 引导管理器 | `C:\Windows\Boot\EFI\bootmgfw.efi` |
| 启动字体 | `C:\Windows\Boot\Fonts\*.ttf` |

oscdimg 双引导命令(注意 `b"路径"` 的引号必须原样传给 oscdimg,
用 PowerShell 直接调用会被吞掉引号,建议包一层 `.cmd`):

```
oscdimg -bootdata:2#p0,e,b"<iso>\boot\etfsboot.com"#pEF,e,b"<efisys.bin>" ^
        -h -m -u2 -udfver102 -lLABEL "<iso>" "<out>.iso"
```

## 3. 键盘/时间/工具在 WinPE 里的可用性

- `timeout /t N` 在 WinPE 的 cmd 里**不生效**,不等待。用
  `ping -n N 127.0.0.1 >nul` 或调用被测程序自己的等待命令
- `certutil`、`curl`、`powershell` 常见于正常系统,但**不一定在 PE 里**
- `wmic` 可能因为 WMI 仓库未就绪而报 `Generic failure`
- `tasklist` 也可能缺失;`reg`、`dir`、`findstr`、`fc`、`diskpart`、`format`、
  `pnputil`、`more` 相对可靠

## 4. payload 脚本一律用纯 ASCII

`.cmd` 文件里的 UTF-8 中文注释会被中文 PE 的 GBK 控制台错误解释,
其中的括号/引号会破坏 cmd 的括号配对,典型症状:

```
':label' was unexpected at this time.
```

## 5. 源码编码不确定,别猜

同一个项目里可能混着不同编码:实测 PECMD2.8.8U 的 `PECMD.cpp` 是
**UTF-16LE(带 BOM)**,而同名项目的帮助文本是 GBK。
按字节做 ASCII 搜索会静默失败,先读前几个字节确认 BOM。

## 6. 串口设备存在 ≠ COM 端口存在

见 README「结果通道 / 串口」。要 `PortName` 写入 + 重启设备之后才可用。

## 7. 让 PE 主动"分屏循环"打印

PE 侧脚本按 `cls` + 打印一块 + 等待 的节奏循环,宿主机每 10~15 秒截一次屏,
这样不需要交互就能稳定收集到每一屏内容。

## 8. 把待测程序放到真实启动路径上

两种模式,信息量不同:

- **hook 模式**:保留 PE 原本的启动链,在其启动脚本末尾追加一行调用待测程序。
  PE 能正常进桌面,适合验证单个功能点
- **integration 模式**:把 PE 的入口程序整个换成待测程序。
  这能验证"能否接管启动",失败的后果是黑屏/卡在引导动画

integration 模式下若替换的是 WinPE 的外壳程序,注意 **shell 就绪信号**:
外壳不向 `winlogon` 报告就绪时,引导动画会一直转。
