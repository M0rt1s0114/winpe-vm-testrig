"""Inspect an ISO9660 image for El Torito BIOS/UEFI boot entries.

Usage: python inspect-iso.py <file.iso> [--dump-efi <out.img>]

Catalog layout:
  32-byte validation entry      byte0=0x01, byte1=platform (0=x86, 0xEF=UEFI)
  32-byte section header        byte0=0x90(more) / 0x91(final), byte1=platform
  32-byte boot entry            byte0=0x88, byte1=media type,
                                bytes 6..7 = sector count, bytes 8..11 = image LBA
The first boot entry right after the validation entry is the default one and
inherits the platform from the validation entry.
"""
import struct
import sys

SECTOR = 2048
PLATFORM = {0x00: "x86 BIOS", 0x01: "PowerPC", 0x02: "Mac", 0xEF: "UEFI"}
MEDIA = {0x00: "no emulation", 0x01: "1.2MB floppy", 0x02: "1.44MB floppy",
         0x03: "2.88MB floppy", 0x04: "hard disk"}


def read_at(f, lba, sectors=1):
    f.seek(lba * SECTOR)
    return f.read(sectors * SECTOR)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    path = sys.argv[1]
    dump = None
    if "--dump-efi" in sys.argv:
        dump = sys.argv[sys.argv.index("--dump-efi") + 1]

    with open(path, "rb") as f:
        lba = 16
        catalog_lba = None
        while True:
            d = read_at(f, lba)
            dtype = d[0]
            if dtype == 255:
                break
            if dtype == 0:
                sysid = d[7:39].decode("ascii", "replace").strip("\x00 ")
                catalog_lba = struct.unpack("<I", d[0x47:0x4B])[0]
                print(f"[boot record] system-id={sysid!r} catalog_lba={catalog_lba}")
            elif dtype == 1:
                volid = d[40:72].decode("ascii", "replace").strip("\x00 ")
                print(f"[pvd] volume-id={volid!r}")
            elif dtype == 2:
                print("[svd] supplementary volume descriptor present")
            lba += 1

        if catalog_lba is None:
            print("!! no El Torito boot record: not a bootable image")
            return 1

        cat = read_at(f, catalog_lba)
        if cat[0] != 0x01:
            print(f"!! bad validation entry: byte0=0x{cat[0]:02x}")
            return 1
        print(f"    validation: platform={PLATFORM.get(cat[1], hex(cat[1]))} "
              f"key55=0x{cat[0x1E]:02x}{cat[0x1F]:02x}")

        platform = cat[1]
        for off in range(32, len(cat) - 31, 32):
            e = cat[off:off + 32]
            if e[0] in (0x90, 0x91):
                platform = e[1]
                which = "final" if e[0] == 0x91 else "more"
                print(f"    section header: platform={PLATFORM.get(platform, hex(platform))} ({which})")
            elif e[0] == 0x88:
                sectors = struct.unpack("<H", e[6:8])[0]
                lba_img = struct.unpack("<I", e[8:12])[0]
                media = MEDIA.get(e[1], hex(e[1]))
                print(f"    boot entry: platform={PLATFORM.get(platform, hex(platform))} "
                      f"media={media} lba={lba_img} sectors={sectors} bytes={sectors * 512}")
                if dump and platform == 0xEF:
                    with open(dump, "wb") as out:
                        out.write(read_at(f, lba_img, sectors))
                    print(f"    -> dumped UEFI boot image to {dump}")
            elif any(e):
                print(f"    (unknown entry byte0=0x{e[0]:02x})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
