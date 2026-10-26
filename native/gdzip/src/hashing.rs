// MD5 of whole files, the same value as Godot's File.get_md5() (lowercase
// hex), which the mod loader uses as a mod's identity. Several files can be
// hashed at once; one file's MD5 can't be split up.

use md5::{Digest, Md5};
use std::io::Read;

pub fn md5_file(path: &str) -> Option<String> {
    let mut f = std::fs::File::open(path).ok()?;
    let mut hasher = Md5::new();
    let mut buf = vec![0u8; 1 << 20];
    loop {
        let n = f.read(&mut buf).ok()?;
        if n == 0 {
            break;
        }
        hasher.update(&buf[..n]);
    }
    Some(hasher.finalize().iter().map(|b| format!("{b:02x}")).collect())
}

#[cfg(test)]
mod tests {
    #[test]
    fn known_md5() {
        let dir = std::env::temp_dir().join("gdzip_md5_test");
        std::fs::write(&dir, b"The quick brown fox jumps over the lazy dog").unwrap();
        assert_eq!(super::md5_file(dir.to_str().unwrap()).unwrap(), "9e107d9d372bb6826bd81d3542a419d6");
        std::fs::remove_file(dir).ok();
        assert!(super::md5_file("/definitely/not/here").is_none());
    }
}

// ---------------------------------------------------------------------------
// File fingerprints, for remembering MD5s across sessions safely.
//
// A fingerprint covers everything that changes when a file's content can have
// changed: on Linux/Android the device, inode, size, and modification and
// change times (ctime is set by the kernel on any write, rename or metadata
// change, and normal tools can't set it back); on Windows the volume, file ID,
// size, and last-write and change times. Only filesystems known to keep those
// get one; anything else returns None, and the caller just hashes the file.
//
// `settled` follows git's "racy" rule: a file changed within the last couple of
// seconds could change again without its timestamps moving, so its hash
// shouldn't be trusted next time.

const RACY_SECONDS: i64 = 2;

pub struct Fingerprint {
    pub id: String,
    pub settled: bool,
}

#[cfg(unix)]
pub fn fingerprint(path: &str) -> Option<Fingerprint> {
    use std::os::unix::fs::MetadataExt;
    let m = std::fs::metadata(path).ok()?;
    if !m.is_file() || !trusted_filesystem(path) {
        return None;
    }
    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).ok()?.as_secs() as i64;
    let changed = m.mtime().max(m.ctime());
    Some(Fingerprint {
        id: format!(
            "u{}:{}:{}:{}.{}:{}.{}",
            m.dev(),
            m.ino(),
            m.size(),
            m.mtime(),
            m.mtime_nsec(),
            m.ctime(),
            m.ctime_nsec()
        ),
        settled: now - changed >= RACY_SECONDS,
    })
}

#[cfg(unix)]
fn trusted_filesystem(path: &str) -> bool {
    // statfs f_type magic numbers of filesystems with real inodes and ctime
    const TRUSTED: [u32; 8] = [
        0xEF53,     // ext2/3/4
        0x9123683E, // btrfs
        0x58465342, // xfs
        0xF2F52010, // f2fs
        0x01021994, // tmpfs
        0x2FC12FC1, // zfs
        0xCA451A4E, // bcachefs
        0x7366746E, // ntfs3 (kernel driver)
    ];
    let Ok(c) = std::ffi::CString::new(path) else {
        return false;
    };
    let mut st: libc::statfs = unsafe { std::mem::zeroed() };
    if unsafe { libc::statfs(c.as_ptr(), &mut st) } != 0 {
        return false;
    }
    #[allow(clippy::unnecessary_cast)]
    TRUSTED.contains(&(st.f_type as u32))
}

#[cfg(windows)]
pub fn fingerprint(path: &str) -> Option<Fingerprint> {
    use std::os::windows::io::AsRawHandle;
    use windows_sys::Win32::Foundation::{FILETIME, HANDLE};
    use windows_sys::Win32::Storage::FileSystem::{
        FileBasicInfo, GetFileInformationByHandle, GetFileInformationByHandleEx, GetVolumeInformationByHandleW,
        BY_HANDLE_FILE_INFORMATION, FILE_BASIC_INFO,
    };
    use windows_sys::Win32::System::SystemInformation::GetSystemTimeAsFileTime;

    let f = std::fs::File::open(path).ok()?;
    let h = f.as_raw_handle() as HANDLE;
    unsafe {
        let mut fs_name = [0u16; 32];
        if GetVolumeInformationByHandleW(
            h,
            std::ptr::null_mut(),
            0,
            std::ptr::null_mut(),
            std::ptr::null_mut(),
            std::ptr::null_mut(),
            fs_name.as_mut_ptr(),
            fs_name.len() as u32,
        ) == 0
        {
            return None;
        }
        let name = String::from_utf16_lossy(&fs_name[..fs_name.iter().position(|&c| c == 0).unwrap_or(0)]);
        if name != "NTFS" && name != "ReFS" {
            return None;
        }
        let mut info: BY_HANDLE_FILE_INFORMATION = std::mem::zeroed();
        if GetFileInformationByHandle(h, &mut info) == 0 {
            return None;
        }
        let mut basic: FILE_BASIC_INFO = std::mem::zeroed();
        if GetFileInformationByHandleEx(
            h,
            FileBasicInfo,
            &mut basic as *mut _ as *mut _,
            std::mem::size_of::<FILE_BASIC_INFO>() as u32,
        ) == 0
        {
            return None;
        }
        let mut now: FILETIME = std::mem::zeroed();
        GetSystemTimeAsFileTime(&mut now);
        let now = ((now.dwHighDateTime as i64) << 32) | now.dwLowDateTime as i64;
        let changed = basic.LastWriteTime.max(basic.ChangeTime);
        Some(Fingerprint {
            id: format!(
                "w{}:{}:{}:{}:{}:{}",
                info.dwVolumeSerialNumber,
                ((info.nFileIndexHigh as u64) << 32) | info.nFileIndexLow as u64,
                ((info.nFileSizeHigh as u64) << 32) | info.nFileSizeLow as u64,
                basic.LastWriteTime,
                basic.ChangeTime,
                basic.CreationTime
            ),
            settled: now - changed >= RACY_SECONDS * 10_000_000,
        })
    }
}

#[cfg(not(any(unix, windows)))]
pub fn fingerprint(_path: &str) -> Option<Fingerprint> {
    None
}

#[cfg(all(test, unix))]
mod fingerprint_tests {
    use super::fingerprint;
    use std::io::Write;

    fn set_mtime(path: &str, secs: i64, nsec: i64) {
        let c = std::ffi::CString::new(path).unwrap();
        let t = [
            libc::timespec { tv_sec: secs, tv_nsec: nsec },
            libc::timespec { tv_sec: secs, tv_nsec: nsec },
        ];
        assert_eq!(unsafe { libc::utimensat(libc::AT_FDCWD, c.as_ptr(), t.as_ptr(), 0) }, 0);
    }

    #[test]
    fn same_size_rewrite_with_restored_mtime_is_caught() {
        // the case a size+mtime check misses: different content, same size,
        // timestamp put back afterwards (like `touch -r` or a timestamp-keeping copy)
        let dir = std::env::temp_dir().join("gdzip_fp_test");
        std::fs::create_dir_all(&dir).unwrap();
        let p = dir.join("a.bin");
        let ps = p.to_str().unwrap();
        std::fs::write(&p, b"first content!").unwrap();
        set_mtime(ps, 1_600_000_000, 0);
        let before = fingerprint(ps);
        std::thread::sleep(std::time::Duration::from_millis(20));
        std::fs::OpenOptions::new().write(true).open(&p).unwrap().write_all(b"other content!").unwrap();
        set_mtime(ps, 1_600_000_000, 0);
        let after = fingerprint(ps);
        // /tmp is tmpfs (trusted) on the build machine; if the filesystem
        // isn't trusted both are None, which is also safe
        if let (Some(a), Some(b)) = (&before, &after) {
            assert_ne!(a.id, b.id);
        } else {
            assert!(before.is_none() && after.is_none());
        }
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn fresh_file_is_not_settled() {
        let p = std::env::temp_dir().join("gdzip_fp_fresh.bin");
        std::fs::write(&p, b"x").unwrap();
        if let Some(f) = fingerprint(p.to_str().unwrap()) {
            assert!(!f.settled);
        }
        std::fs::remove_file(&p).ok();
    }
}
