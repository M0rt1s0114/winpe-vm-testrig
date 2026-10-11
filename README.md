# WinPE VM Test Rig

在 **无头 VMware** 里启动一份真实的 WinPE,把待测程序以**真实启动入口**的方式跑起来,
并把结果取回宿主机。

为"只能在 PE 里验证"的程序而做:这类程序的接口面往往是 Win32 的磁盘、驱动、
显示、注册表、服务,在普通 Windows 上测不出真东西。

## 它解决什么

- **引导**:用宿主机的标准引导文件 + 你手上的 PE 的 WIM,拼出一个 BIOS/UEFI 双引导 ISO
- **注入**:用 wimlib 往 WIM 里塞文件,不改动原始镜像
- **执行**:改写 PE 启动链(`winpeshl.ini` 或宿主的 `Pecmd.ini` 之类),让待测程序
  在真实启动路径上被执行,而不是被外层程序"模拟"
- **观测**:截屏 + 串口,两条通道都不需要 VMware Tools
- **结果回传**:串口(需先修好 PE 里的串口设备,见下)

全部通过命令行完成:**不需要 GUI,不需要管理员权限**。

## 依赖

| 组件 | 用途 | 备注 |
|---|---|---|
| VMware Workstation | 跑虚拟机 | 自带 `vmrun.exe` / `vmcli.exe` |
| wimlib-imagex | 读写 WIM | [wimlib](https://wimlib.net/) |
| oscdimg.exe | 生成 ISO | Windows ADK / WimBuilder2 里都有 |
| Python 3 | ISO 结构检查等 | 只用到标准库 |
| PE 的 WIM | 测试环境 | 你自己的 PE |
| 宿主的 `C:\Windows\Boot` | 引导文件 | bootmgr / bootmgfw.efi / BCD / boot.sdi / efisys.bin |

## 快速开始

1. 复制 `config.cmd.example` 为 `config.cmd`,改成本机路径
2. `scripts\prepare-iso.cmd` —— 把 WIM 放进 `iso\sources\boot.wim`,并用宿主引导文件补齐骨架
3. `scripts\make-iso.cmd` —— 生成可引导 ISO
4. `scripts\inject-wim.cmd` —— 按 `wimupdate.txt` 往 WIM 副本里注入 payload
5. `scripts\boot-capture.cmd` —— 无头启动并按间隔截屏

## 结果通道

### 截屏

```cmd
vmcli.exe <vmx> MKS captureScreenshot shot.png
```

无头模式同样可用。配合"分屏循环打印"的 PE 侧脚本,周期性截图就能覆盖到每一屏内容。

### 串口

VMX 里配置:

```
serial0.present = "TRUE"
serial0.fileType = "file"
serial0.fileName = "D:\...\serial0.log"
```

**坑(重要):** VMware 不会因为配了串口就让 guest 里出现 `COM1`。
实测在一份 WinPE 里:

- `HKLM\SYSTEM\CurrentControlSet\Services\Serial\Enum` 里已经有 `ACPI\PNP0501\1`
- 设备键 `HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\PNP0501\1` 也存在
- 但 `HKLM\HARDWARE\DEVICEMAP\SERIALCOMM` 是空的,`echo x > COM1` 报
  "The system cannot find the file specified"

修法(在 PE 内执行,见 `payload\serial-fix.cmd`):

```cmd
reg add "HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\PNP0501\1\Device Parameters" /v PortName /t REG_SZ /d COM1 /f
pnputil /restart-device "ACPI\PNP0501\1"
```

之后 `echo hello > COM1` 就能出现在宿主机的 `serial0.log` 里。

另一个坑:`serial0.log` 若在开机前已存在,VMware 会弹"替换还是追加"的询问,
无头模式下会被自动答复,建议每次启动前删掉该文件。

## 文档

- [docs/FINDINGS.md](docs/FINDINGS.md) —— 踩过的坑与结论

## 许可

MIT
