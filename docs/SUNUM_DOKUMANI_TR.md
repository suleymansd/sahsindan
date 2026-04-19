# şahsından.com - Satış, Yatırımcı, Marketing ve Genel Sunum Dokümanı

## 1) Yönetici Özeti

şahsından.com, doğrulanmış üyeler arasında güven odaklı ikinci el araç alım-satımını kolaylaştıran kapalı pazar platformudur.  
Platformun temel amacı, geleneksel açık pazaryerlerinde yaşanan sahte profil, güncel olmayan ilan, yanıtsız iletişim ve randevu no-show problemlerini sistematik olarak azaltmaktır.

Temel yaklaşım:

- Sadece doğrulanmış üyelerle işlem akışı
- Görünür güven sinyalleri (yanıt hızı, randevu disiplini, güven puanı)
- İlan yaşam döngüsü ve stale-listing kontrolü
- Mesajlaşma, randevu ve moderasyonun tek platformda birleşmesi

---

## 2) Hangi Probleme Çözüm Oluyor?

Pazardaki ana problemler:

- Sahte veya düşük güvenilirlikte hesaplar
- Satılmış olmasına rağmen yayında kalan ilanlar
- Tarafların iletişimde geç kalması veya hiç dönmemesi
- Randevuya gelmeme (no-show) nedeniyle zaman ve maliyet kaybı
- Alıcı ve satıcı arasında asimetrik güven ve düşük şeffaflık

Bu problemin sonucu:

- Düşük dönüşüm oranı
- Yüksek kullanıcı memnuniyetsizliği
- Platform güveninin zedelenmesi
- Satın alma karar sürelerinin uzaması

---

## 3) Ürün Çözümü

şahsından.com şu mekanizmalarla problemi çözer:

- Doğrulama akışı: Kullanıcı doğrulama süreci + moderatör onayı
- Güven skoru modeli: Profil, profesyonel doğrulama, randevu davranışı ve rapor etkileri
- İlan yaşam döngüsü: DRAFT, PUBLISHED, SOLD, ARCHIVED, REJECTED durumları
- Stale ilan önleme: Belirli süre sonunda doğrulama isteme, onaylanmazsa otomatik arşivleme
- Mesajlaşma ve randevu yönetimi: Thread bazlı iletişim, okundu bilgisi, randevu event akışı
- Moderasyon ve denetim: Admin/moderatör panelleri, rapor ve takedown akışı, audit log

---

## 4) Ürün Kime Hitap Ediyor?

Birincil kullanıcı grupları:

- Araç almak isteyen doğrulanmış bireysel alıcılar
- Aracını daha güvenli ortamda satmak isteyen bireysel satıcılar
- Platform güvenliğini işleten moderasyon ekipleri
- Operasyonel kontrol isteyen platform yöneticileri

Odak pazar (MVP):

- İstanbul merkezli doğrulanmış kapalı pazar

---

## 5) Değer Önerisi

### Alıcı için

- Daha az sahte hesap riski
- Daha güncel ilan havuzu
- Satıcı davranışını gösteren güven sinyalleri
- Randevu disiplinine dayalı daha öngörülebilir süreç

### Satıcı için

- Daha ciddi alıcı havuzu
- No-show etkisinin görünür olması sayesinde filtreleme
- Tek panelden ilan + mesaj + randevu yönetimi

### Platform için

- Güven odaklı farklılaşma
- Daha kaliteli işlem hacmi
- Moderasyon kapasitesinin verimli kullanımı

---

## 6) Teknik Güç ve Güvenilirlik Çerçevesi

Mevcut teknik yapı:

- Web: Next.js 14 + React Query + Tailwind
- Mobil: Flutter + Riverpod
- API: FastAPI + SQLAlchemy + Alembic
- Altyapı: Postgres, Redis, MinIO, Nginx

Güvenlik ve operasyon:

- bcrypt ile parola hashleme
- JWT access + refresh token rotasyonu
- Rate limiting (login, mesaj, upload vb.)
- Upload güvenliği (tip/size kontrolü, virus scan hook)
- Audit log ile kritik aksiyon kayıtları

---

## 7) Neden Şimdi?

- İkinci el araç pazarında güven bariyeri karar süresini doğrudan etkiliyor
- Sadece listeleme yapan platformlardan davranış/veri odaklı güven platformlarına geçiş ihtiyacı artıyor
- Randevu ve iletişim kalitesini ölçen platformlar daha hızlı güven inşa ediyor

---

## 8) İş Modeli (Önerilen)

Gelir kalemleri:

- İlan paketleri (standart / öne çıkarma / vitrin)
- Üyelik katmanları (bireysel premium, profesyonel satıcı)
- İşlem bazlı hizmet ücretleri (opsiyonel)
- Doğrulama ve güven hizmetleri (opsiyonel ücretlendirme)
- B2B iş ortaklığı gelirleri (sigorta, ekspertiz, finansman lead)

MVP döneminde öncelik:

- Güven ve kullanım davranışı KPI’larını stabilize etmek
- Sonrasında paketleme ve monetizasyonu kademeli açmak

---

## 9) Satış Stratejisi

Satış anlatısının omurgası:

- "Daha çok ilan" yerine "daha güvenli ve sonuç odaklı işlem"
- Ciddi alıcı-satıcı eşleşmesi ve zaman tasarrufu
- No-show ve iletişim kalitesi üzerinden somut performans yönetimi

Satış kanalları:

- Doğrulanmış kullanıcı toplulukları
- Niş otomotiv toplulukları ve referans ağı
- Profesyonel satıcı onboarding programları

Satışta kullanılacak ana mesaj:

- "Platformumuzda güven bir iddia değil, ölçülen bir metrik."

---

## 10) Marketing Stratejisi

### Konumlandırma

- "Güvenilir kişi bulma" odaklı araç pazarı

### İçerik eksenleri

- Sahte profil riskini azaltan pratikler
- İlan kalitesi ve güven puanı arasındaki ilişki
- Randevu disiplininin dönüşüme etkisi

### Büyüme taktikleri

- Referans programı
- Güven skoru odaklı başarı hikayeleri
- Topluluk bazlı lansman ve pilot şehir stratejisi

---

## 11) KPI Çerçevesi (Yatırımcı ve Yönetim Takibi)

Kuzey yıldızı metrikleri:

- Doğrulanmış aktif kullanıcı oranı
- Mesajdan randevuya dönüşüm oranı
- Randevudan işleme dönüşüm oranı
- No-show oranı
- Stale ilan oranı
- Ortalama yanıt süresi

İkincil metrikler:

- Moderasyon çözüm süresi
- Rapor başına aksiyon oranı
- Kullanıcı başına güven skoru trendi

---

## 12) Rekabetten Ayrışma

şahsından.com’un farkı:

- Sadece ilan vitrini değil, güven altyapısı
- Davranış verisini görünür ve karar destekleyici hale getirme
- Randevu ve iletişim kalitesini ürünün merkezine alma
- Moderasyon ve otomasyonun birlikte çalıştığı hibrit model

---

## 13) Yatırımcı Hikayesi (Pitch Çekirdeği)

Yatırımcıya verilecek kısa tez:

- Büyük bir pazarda güven problemi halen çözülmemiş durumda
- Platform, güveni ölçen ve yöneten mekanizmaları ürünün çekirdeğine koyuyor
- Davranış verisi ile zaman içinde savunulabilir veri ağı etkisi oluşuyor
- B2C + B2B gelir modeline evrilebilen bir yapı mevcut

Yatırım kullanım alanları:

- Ürün hızlandırma (UX, performans, otomasyon)
- Doğrulama/anti-fraud altyapı güçlendirmesi
- Pilot şehirlerde kontrollü büyüme
- Satış ve marketing ekibi ölçekleme

---

## 14) Riskler ve Önleyici Aksiyonlar

Riskler:

- Doğrulama sürtünmesi nedeniyle onboarding düşüşü
- Moderasyon operasyonunun ölçeklenme maliyeti
- Likiditeyi artırırken kaliteyi koruma dengesi

Önleyici yaklaşım:

- Kademeli onboarding ve rol bazlı akışlar
- Moderasyon araçları + otomatik risk sinyalleri
- Şehir ve segment bazlı kontrollü büyüme

---

## 15) Sunumda Kullanıma Hazır 10 Slayt Akışı

1. Problem: Güven açığı ve pazar verimsizliği  
2. Çözüm: Doğrulanmış kapalı pazar modeli  
3. Ürün demo akışı: doğrulama -> ilan -> mesaj -> randevu  
4. Güven motoru: skor, stale kontrol, no-show etkisi  
5. Pazar fırsatı: hedef segment ve ölçek planı  
6. İş modeli ve gelir kalemleri  
7. Go-to-market ve satış/marketing planı  
8. KPI ve traction hedefleri  
9. Yol haritası (6-12-18 ay)  
10. Yatırım talebi ve kullanım planı  

---

## 16) Kısa Pitch Metni (30 Saniye)

şahsından.com, ikinci el araç pazarındaki en büyük problemi, yani güven eksikliğini çözen doğrulanmış kapalı pazar platformudur.  
Sahte profilleri azaltır, eski ilanları otomatik temizler, iletişim ve randevu disiplinini ölçülebilir hale getirir.  
Böylece alıcı-satıcı eşleşmesini daha hızlı, daha güvenli ve daha verimli hale getirirken; platform tarafında ölçeklenebilir bir güven altyapısı oluşturur.

