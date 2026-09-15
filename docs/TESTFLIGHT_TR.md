# Yatırımcı demosu ve TestFlight — 15 Eylül 2026

**Yerel demo çalışıyor; internete backend yayını ve TestFlight yüklemesi yapılmadı. Dağıtılabilir IPA henüz yok.** Bu belge önceki [hazırlık raporuna](FINAL_READINESS_TR.md) ektir.

Son durum: [Railway düşük kullanım profili](RAILWAY_TR.md) hazır, proje boş olarak
açıldı ve 145 backend testi geçti; ücretli servisler başlatılmadı. Xcode arşiv ve
App Store Connect IPA export denemesi başarılı oldu. Bu imzalama denemesi canlı
API'ye bağlı olmadığı için yatırımcıya verilecek IPA değildir; TestFlight'a yüklenmedi.

## Yapılanlar

- Bu Mac'te `com.sahsindan.app` / `475GX393HD` ekibine ait, 18 Aralık 2026'ya kadar geçerli App Store provisioning profili bulundu. Projedeki örnek bundle ID düzeltildi. Profil, aktif üyeliğin veya App Store Connect yetkisinin doğrulandığı anlamına gelmez.
- Xcode 26.6 ve Flutter 3.47.1 ile simülatör derlemesi ve uygulama açılışı doğrulandı. iPhone release hedefi **imzasız** derlendi (22,3 MB `.app`). Bu çıktı yalnızca derleme doğrulamasıdır: canlı API tanımlı olmadığı için dağıtıma uygun değildir.
- Şahsından uygulama adı, mağaza ikonları ve açılış işareti eklendi. İkonlar `scripts/ios_brand.swift` vektör yollarından yerel üretilir; ücretli servis kullanılmaz.
- Fotoğraf seçicinin eksik `NSPhotoLibraryUsageDescription` açıklaması eklendi. Release/Profile ATS istisnası kaldırıldı; yerel HTTP yalnızca `Info-Debug.plist` içinde açık. Derlenmiş release plist'i doğrulandı.
- Release API adresinin geliştirme `.env` dosyasından alınması engellendi: açık `--dart-define`, HTTPS ve `/api` zorunlu; kullanıcı bilgisi/query/fragment kabul edilmez.
- `scripts/ios_release.py`: gerçek HTTPS/DNS, readiness, kapalı pazarın ilan/hesap endpoint'lerine yetkisiz erişimde 401 ve hata sözleşmesi kontrolü; istemci asset'ine sunucu sırlarının yanlışlıkla eklenmesine karşı anahtar kontrolü; arşiv kimliği/build/ATS/izin/kod imzası denetimi. Eski IPA dosyası başarılı yeni çıktı sayılmaz. Bu ön kontrol, gerçek hesapla tam kullanıcı akışı testinin yerine geçmez.
- `/ready` artık PostgreSQL ve Redis'i kontrol eder. Bağımlılık arızasında hassas bağlantı bilgisini sızdırmadan 503 döner; `/health` canlılığı ayrı bildirir.
- Native E2E ilk çalışmada **yanlış şifrede giriş formunun kaybolduğunu** yakaladı. `routerProvider` her auth değişiminde yeni GoRouter oluşturuyordu. Router artık sabit kalır, redirect güncel auth durumunu okur; router ve stream kapanırken temizlenir. Aynı testle yeniden doğrulanır.

## Testler

| Kontrol | Sonuç |
|---|---|
| Tüm gerçek PostgreSQL + Redis API testleri | 138 geçti (dört yeni readiness regresyonu) |
| Web unit / Chromium E2E | 5 / 12 geçti; Next üretim derlemesi başarılı |
| Flutter unit/widget | 18 geçti; release URL ve auth/route regresyonları dahil |
| IPA hazırlık regresyonları | 8 geçti |
| iOS simülatör ve imzasız cihaz release derlemesi | Başarılı; imzalama/yayın anlamına gelmez |
| Native E2E: boş form, yanlış parola, giriş, ilan detayı | iPhone 17 Pro / iOS 26.5 üzerinde gerçek yerel API ile geçti |

Native testte klavye kapatıldıktan sonra `WidgetTester` eski odak bağlantısını tutuyordu; yeniden şifre yazmadan önce alana gerçek dokunma eklenerek metnin değiştirilmesi doğrulandı. Bu test etkileşimi düzeltmesidir; uygulamadaki router hatası ayrı olarak giderildi. Mobil kaynaklar, unit ve integration testleri için statik analiz temizdir.

Makine okunabilir sonuç: [investor-readiness-2026-09-15.json](validation/investor-readiness-2026-09-15.json).

Önceki coverage/yük/backup ölçümleri [genel raporda](FINAL_READINESS_TR.md) tarihlidir; bu oturumda yeni kapasite veya coverage iddiası yoktur. Python deprecation ve secure-storage'ın gelecekteki Swift Package Manager desteği uyarıları devam eder.

## Canlı backend

Alan adı/DNS, sunucu/hosting erişimi, aylık bütçe, SMTP ve gerçek yönetici bilgileri bekleniyor. Şu an API `http://127.0.0.1:8080`, web `http://127.0.0.1:3000`; SQLite/demo verisi kullanılır. TestFlight uygulaması başka bir telefondan bu yerel adreslere erişemez.

Gerçek sunucu için [kurulum kılavuzu](YAYIN_KILAVUZU_TR.md) hazır: özel env → PostgreSQL/Redis/migration/API/maintenance/web/Caddy → DNS/TLS → yönetici/MFA → SMTP → uzak şifreli yedek/restore ve monitör. Gerçek sunucuda dış erişim, reset e-postası ve kullanıcı akışı doğrulanmalıdır. Ücretli AI/altyapı açılmadı; hosting ve Apple üyeliği dahil mutlak sıfır maliyet vaat edilmez.

## IPA ve TestFlight adımları

Canlı backend hazır olduğunda repo kökünde gerçek değerlerle:

```sh
python3 scripts/ios_release.py check --api-url https://GERCEK_ALAN_ADI/api
python3 scripts/ios_release.py build --api-url https://GERCEK_ALAN_ADI/api \
  --build-number YENI_POZITIF_BUILD_NUMARASI --flutter /path/to/flutter
```

Başarılı export `apps/mobile/build/ios/ipa/*.ipa` ve `release.json` üretir; otomatik yükleme yapmaz. Build numarası App Store Connect'te daha önce kullanılmamış olmalıdır; script uzak geçmişi sorgulamaz.

İlk keychain taramasında yalnızca **Apple Development** kimlikleri görünüyordu;
sonraki gerçek `xcodebuild archive` ve `xcodebuild -exportArchive` denemeleri
`475GX393HD` ekibiyle başarıyla tamamlandı. Yalnızca sertifika listesinden IPA
export yapılamayacağı sonucu çıkarılmamalıdır. Canlı backend adresiyle yeni build
ve App Store Connect uygulama kaydı/yükleme rolü kontrolü hâlâ gereklidir. Başka
ekiplerin sertifikaları/profilleri değiştirilmedi; özel anahtarlar repo'ya konmadı.

App Store Connect'teki `com.sahsindan.app` kaydı ve rol doğrulandıktan sonra IPA, Transporter veya Xcode Organizer ile yüklenir. İşleme sonrasında beta açıklaması, iletişim, gerekiyorsa inceleme hesabı ve şifreleme soruları tamamlanır. Yatırımcı ekip üyesi değilse dış test grubu ve ilk build için TestFlight App Review gerekir. Apple onayı ve dağıtım tamamlanmadan TestFlight bağlantısı hazır denemez.

Genel mağaza yayını için ayrıca gizlilik/hesap silme akışı, fiziksel cihazda fotoğraf izni/zayıf ağ testi, gerçek operasyonel yedek ve alarmlar tamamlanmalı. Bu oturum Apple incelemesi veya bağımsız penetrasyon testi yerine geçmez.

Kaynaklar: [Flutter iOS dağıtımı](https://docs.flutter.dev/deployment/ios), [Apple build yükleme](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds), [dış testçiler](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers), [şifreleme bilgileri](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation).
