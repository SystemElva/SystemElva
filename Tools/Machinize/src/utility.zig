pub fn is_sign(character: u8) bool {
    if (character > 0x20 and character < 0x30) {
        return true;
    }
    if (character > 0x39 and character < 0x41) {
        return true;
    }
    if (character > 0x5a and character < 0x61) {
        return true;
    }
    if (character > 0x7a and character < 0x7f) {
        return true;
    }
    return false;
}
