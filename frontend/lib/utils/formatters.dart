String formatPhoneNumber(String number) {
  if (number.length == 10) {
    // 固定電話: 例）0921234567 → 092-123-4567
    return '${number.substring(0, 3)}-${number.substring(3, 6)}-${number.substring(6)}';
  } else if (number.length == 11) {
    // 携帯電話: 例）09012345678 → 090-1234-5678
    return '${number.substring(0, 3)}-${number.substring(3, 7)}-${number.substring(7)}';
  } else {
    return number;
  }
}
