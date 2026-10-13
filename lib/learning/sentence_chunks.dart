import '../models/phrase.dart';

// Chunks refer only to this project's existing, unchanged phrase texts.
// They are phrase pieces, not a claim of automatic Thai word segmentation.
const _chunks = <String, List<String>>{
  'money_price': ['อันนี้', 'ราคา', 'เท่าไหร่'],
  'money_discount': ['ลด', 'ได้ไหม'],
  'money_cash': ['จ่าย', 'เงินสด'],
  'money_card': ['จ่าย', 'ด้วยบัตร', 'ได้ไหม'],
  'time_now': ['ตอนนี้', 'กี่โมง'],
  'time_open': ['เปิด', 'กี่โมง'],
  'question_understand': ['ไม่', 'เข้าใจ'],
  'question_slowly': ['พูดช้าๆ ', 'ได้ไหม'],
  'food_not_spicy': ['ขอ', 'แบบ', 'ไม่เผ็ด'],
  'food_no_pork': ['ไม่', 'ใส่', 'หมู'],
  'food_water': ['ขอ', 'น้ำเปล่า', 'หนึ่งขวด'],
  'food_takeaway': ['ใส่กล่อง', 'กลับบ้าน'],
  'food_bill': ['คิดเงิน', 'ด้วย'],
  'shopping_bag': ['ไม่', 'รับ', 'ถุง'],
  'shopping_receipt': ['ขอ', 'ใบเสร็จ', 'ด้วย'],
  'shopping_this': ['เอา', 'อันนี้'],
  'transport_stop': ['จอด', 'ตรงนี้', 'ได้ไหม'],
  'transport_fare': ['ค่าโดยสาร', 'เท่าไหร่'],
  'work_finished': ['งาน', 'เสร็จแล้ว'],
  'factory_machine': ['เครื่องจักร', 'เสีย'],
  'factory_gloves': ['ขอ', 'ถุงมือ', 'ได้ไหม'],
  'home_water': ['น้ำ', 'ไม่ไหล'],
  'health_stomach': ['ปวด', 'ท้อง'],
  'health_headache': ['ปวด', 'หัว'],
  'bank_transfer': ['ต้องการ', 'โอนเงิน'],
  'job_looking': ['กำลัง', 'หางาน'],
};

List<String>? sentenceChunks(Phrase phrase, String politeStyle) {
  final parts = _chunks[phrase.id];
  if (parts == null) return null;
  final text = phrase.thaiFor(politeStyle);
  final prefix = parts.join();
  if (!text.startsWith(prefix)) return null;
  final ending = text.substring(prefix.length);
  if (!const {'ครับ', 'ค่ะ', 'คะ'}.contains(ending)) return null;
  return [...parts, ending];
}
