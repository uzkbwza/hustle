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
