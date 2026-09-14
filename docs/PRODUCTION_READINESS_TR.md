> Bu belge 14 Eylül denetiminin kaydıdır. **15 Eylül güncel sonuçları ve kapatılan eksikler: [Son hazırlık raporu](FINAL_READINESS_TR.md).** Aşağıdaki eski Docker/MFA/PDF/yedek durumları güncel değildir.

# Şahsından.com — arayüz, güvenlik ve yayına hazırlık

14 Eylül 2026. Kaynak kod, bağımlılıklar, gerçek PostgreSQL/Redis, Chromium ve iPhone simülatörü üzerinde çalışıldı. Önceki ayrıntılı bulgular [AUDIT_REPORT_TR.md](AUDIT_REPORT_TR.md) içindedir. Bu rapor sonraki arayüz/mobil çalışmaları ve maliyet kontrollü yayın paketini tamamlar.

**Durum:** Yerel web ve mobil uygulama çalışıyor. Yayın paketi hazırlandı; canlı yayın gerçekleşmedi. Alan adı, hedef sunucu ve SMTP erişimi sağlanmadı; Docker daemon çalışmadığı için üretim konteynerleri bu makinede başlatılamadı. İncelenen/test edilen davranışlar aşağıdadır; tüm olası güvenlik açıklarının bittiği veya binlerce eşzamanlı kullanıcı kapasitesinin kanıtlandığı iddia edilmez.

## 1. Envanter ve kapsam

| Katman | Yapı ve kritik akışlar | Doğrulama |
|---|---|---|
| API | FastAPI, SQLAlchemy, Alembic; rol/oturum, doğrulama, ilan/fotoğraf, favori/takip, mesaj, randevu, rapor, yönetici | SQLite regresyon + gerçek PostgreSQL yarış/işlem testleri |
| Web | Next.js 15.5.24, React, React Query, Tailwind; kullanıcı/yönetici ekranları | Unit, TypeScript, lint, üretim derlemesi, Chromium E2E |
| Mobil | Flutter 3.47.1 / Dart 3.13.1, Riverpod, Dio; ZIP referanslı mobil tasarım | Widget/oturum testleri, statik analiz, iPhone 17 Pro simülatörü |
| Üretim | PostgreSQL 16, Redis 7.4.11, iki Uvicorn çalışanı, Next standalone, Caddy | Compose config ve Caddy 2.11.4 config validate; native servis yük ölçümü |
| İşletim | Tek bakım servisi, kalıcı dosya sayacı, gizli env oluşturma, yönetici kurma ve yedek komutları | Kod/statik inceleme, migration testleri; gerçek üretim backup/restore provası yapılmadı |

Tam cihaz E2E, Safari/Firefox, gerçek SMTP teslimi, imzalı Android/iOS dağıtımı, uzun süreli üretim yükü ve bağımsız penetrasyon testi henüz kapsanmıyor. Ödeme/escrow ve ücretli AI iş akışı mevcut uygulamada yoktur; varmış gibi test sonucu sunulmadı.

## 2. Arayüz ve kullanıcı akışları

- Web ortak renkleri, tipografi, kartlar, butonlar, menü, liste/ilan detayları, giriş ve kayıt ekranları düzenlendi. Ağır cam/blur yüzeyleri sadeleştirildi; hata/boş/yükleniyor durumları görünür hale getirildi.
- Mobil ana sayfa, beş sekmeli gezinme, ilan kartı, detay, karşılaştırma, ilan editörü ve mesaj ekranı verilen ZIP tasarımına göre uyarlandı. Veri bulunmayan fotoğraf alanları açık bir yer tutucu gösterir; gerçek olmayan ilan görseli veya AI sonucu üretilmez.
- Küçük ekranda arama/filtre, klavye, menü kapatma ve taşma senaryoları test edildi. Webin 390 px ve masaüstü görünümleri ekran görüntülerinde kontrol edildi.
- Favoriler, randevular ve ilan listelerinde sayfalama; konuşmalarda önceki/son mesajlara erişim eklendi. Gönderme başarısız olduğunda mesaj taslağı korunur.
- Doğrulama ekranları manuel incelemeyi açıklar. Kullanıcının doldurduğu OTP/selfie alanı kimlik kanıtı sayılmaz; belge olmadan otomatik onay verilmez.

Ekran kanıtları: [web mobil](validation/web-mobile.png), [web masaüstü](validation/web-desktop.png), [mobil belge başvurusu](validation/web-verification.png), [iPhone ana sayfa](validation/iphone-home.png), [iPhone ilan listesi](validation/iphone-listings.png). Ölçüm özeti: [release-results.json](validation/release-results.json). Web ekran görüntülerindeki düz renk fotoğraf ve ilanlar test verisidir.

## 3. Bulunan ve düzeltilen sorunlar

API yolları `services/api/app/`, web yolları `apps/web/`, mobil yolları `apps/mobile/lib/` altındadır.

| Dosya / fonksiyon | Sorun, düzeltme ve davranış etkisi |
|---|---|
| `core/rate_limit.py::consume_limit`, `core/redis.py` | Ayrı INCR/EXPIRE ve hata halinde devam etme sınırsız kullanıma yol açabiliyordu. Redis Lua ve bellek sürümünde kilitli sayaçlar kullanılır. Kota 429; sayaç erişilemezse 503 ve Retry-After döner. |
| `core/resource_limits.py`, `core/config.py` | Ortak istek, kullanıcı, yükleme ve indirme bütçeleri yoktu. Gövde, günlük tüketim ve kaynak sınırları getirildi; endpoint değiştirerek genel kotadan kaçılmaz. Kesin kapsam/istisnalar yayın kılavuzunda belirtilir. |
| `services/storage_budget.py`, migration `0008` | Dosya büyümesi kalıcı bütçeye bağlı değildi. Veritabanı işlemi içinde atomik rezervasyon ve 507 ret uygulanır; başarısız işlem kotayı geri alır. |
| `utils/storage.py::upload_bytes` | Yerel disk dolması yarım dosya ve kontrolsüz hata bırakabilirdi. Geçici dosyaya yazma, fsync ve atomik rename kullanılır; başarısızlıkta dosya temizlenir ve API 503 döner. |
| `utils/file_validation.py::validate_upload` | MIME bildirimi tek başına kabul ediliyordu. JPEG/PNG gerçekten açılır, boyut/piksel sınırı doğrulanır, metadata atılır ve tekrar kodlanır. Bozuk PNG checksum hatası dahil geçersiz içerik 400 döner. PDF yalnızca özel indirme olarak sınırlı biçim kontrolünden geçer; antivirüs taraması değildir. |
| `routes/listings.py::upload_photo/favorite_listing/create_listing` | Aynı son kontenjana birden fazla istek girebiliyordu. İlan/kullanıcı satırı kilitleri, fotoğraf/aktif ilan/favori kotaları eklendi. Var olan favoriyi tekrar eklemek kota doluyken de idempotenttir. |
| `services/listing_cache.py` ve `list_listings` | Güncelleme ile eşzamanlı eski sorgu sonucunun yeni cache sürümüne yazılması mümkündü. Sorgu başlamadan alınan sürümle kayıt yapılır; geçersiz kılınmış sonuç yeni sürümde görünmez. |
| `routes/listings.py`, `favorites.py`, `appointments.py`, `follows.py`, `messaging.py` | Sınırsız listeler ve bütün konuşmayı topluca yükleme bellek/DB maliyetini büyütüyordu. Sınırlı sayfalar, sabit sıralama, mesaj cursor'ı ve konuşma başına son mesajları seçen SQL window sorgusu eklendi. Mobil favori durumları ayrı küçük ID yanıtından alınır. |
| Migration `0007_capacity_indexes` | Liste/mesaj/son kullanım sorguları için eksik bileşik indeksler eklendi. Önceki migrasyonlardaki indeksler tekrar oluşturulmaz. İki yeni migration mevcut veriyi silmez. |
| `services/realtime.py`, `routes/ws.py` | Bellek içi hub farklı worker'lara mesaj ulaştıramıyordu; bağlantı limiti worker başına aşılabiliyordu. Redis pub/sub, ortak süreli bağlantı kayıtları, boyut/zaman/istek sınırı, Origin ve periyodik hesap/token kontrolü eklendi. Çöken worker'ın bağlantı kotası süresi dolunca kurtarılır. |
| `routes/messaging.py::send_message/mark_read` | Senkron DB işlemleri async endpoint içinde event loop'u bloke ediyordu. DB işlemleri threadpool'da, bildirim teslimi işlem sonrası async görevde yürür. Mesaj kalıcıdır; bildirim kesintisi yeniden sorguyla telafi edilir. |
| `routes/auth.py`, `core/security.py`, `core/deps.py` | Şifre sıfırlanınca mevcut access token geçerli kalabiliyordu. Token parola sürümüne bağlanır ve her istekte kontrol edilir. Üretim refresh/logout tokenları query yerine JSON veya HttpOnly çerezle alınır. |
| `services/mail.py`, `forgot_password` | Gerçek parola kurtarma teslimi ve e-posta bütçesi yoktu. Mevcut SMTP ile teslim, alıcı/genel kota, sınırlı timeout ve genel yanıt eklendi; otomatik ücretli servis açılmaz. SMTP yokken üretim akışı açıkça 503 verir. |
| `routes/verification.py`, `routes/admin.py` | Demo OTP/selfie işaretinin güvenilmesi ve belgesiz onay riski giderildi. Başvuru manuel PENDING kalır; üretim onayı kimlik+selfie gerektirir. Eşzamanlı başvuru/karar ve belge sayısı denetlenir. |
| `schemas/auth.py`, `listing.py`, `appointments.py`, `routes/reports.py` | DB kolonlarını aşan veya sınırsız alanlar kontrol altına alındı; uzunluklar, negatif/sonlu fiyat, araç verisi, rapor sayısı ve belge türü denetlenir. İlan düzenleme artık `car_details` değişikliğini de saklar. |
| Web `app/(app)/ilan-ver/page.tsx` | Async işlem sonunda React `event.currentTarget` kaybolduğu için başarılı işlem hata veriyordu. Form referansı önceden alınır. Kısmi yüklemeden sonra aynı taslak güncellenir, yüklenen fotoğraflar tekrar yüklenmez; yayın bir kez yapılır. |
| Web `mesajlar`, `randevular`, `sifre-unuttum`, `sifre-sifirla` | Yakalanmayan ağ hataları, silinen mesaj taslağı ve takılı gönderim durumu düzeltildi. Hata görünür; kullanıcı kontrollü tekrar deneyebilir. Yeniden planlanan randevu için geçerli işlemler de gösterilir. |
| Web `lib/api.ts`, `components/providers.tsx`; mobil auth repository/interceptor | Tek uçuşlu oturum yenileme, 401 sonrası yalnızca bir tekrar ve 429/geçici arızada kontrolsüz yeniden deneme olmaması doğrulandı. Geçici refresh arızası oturumu gereksiz yere silmez. |
| Mobil `core/network/interceptors/logging_interceptor.dart`, `core/config/app_env.dart` | İstek gövdesinde parola/token ve URL parametresi günlüklenebiliyordu. Gövde/parametreler kaldırıldı; release logu kapalı, release API adresi HTTPS zorunlu. Demo giriş düğmesi yalnızca debug modundadır. |
| `scripts/create_admin.py`, `scripts/seed*.py`, Docker ignore | Sabit parolalı yönetici oluşturma kaldırıldı. Operatörden gizli parola alınır; mevcut hesap yükseltilmez. Demo seed üretimde engellenir ve test/seed araçları üretim imajına alınmaz. Test paketleri üretim requirements listesinden ayrıldı. |
| `scripts/maintenance.py`, `infra/compose.production.yml` | Her API worker'ında yinelenen bakım yerine tek süreç vardır. Süresi dolan tokenlar temizlenir, dosya sayacı uzlaştırılır, en az 24 saatlik sahipsiz dosyalar temizlenir; log, CPU, bellek ve DB bağlantı sınırları sabittir. |

Önceki audit'teki rol/IDOR kontrolleri, refresh yarışı, audit+iş verisi transaction bütünlüğü, trust score ve randevu durum geçişi onarımları korunur; ilgili regresyon dosyaları son süitte yeniden çalıştırılmıştır.

## 4. Test sonuçları ve onarımlar

| Kontrol | Sonuç |
|---|---|
| Gerçek PostgreSQL + Redis, unit/regresyon/yarışlar | **115 geçti** |
| SQLite + Redis | **105 geçti**, yalnızca gerçek PostgreSQL gerektiren **10 test atlandı**; bunlar PostgreSQL hattında geçti |
| Web unit | **5 geçti** |
| Chromium E2E + üretim derlemesi | **11 geçti** |
| Flutter test | **14 geçti** |
| Mobil lib + test statik analizi | **0 hata, 0 uyarı, 0 bilgi**; Dart analyzer protokolü |
| API Ruff, web TypeScript | Başarılı |
| Web lint | Hata yok; 6 mevcut `<img>` optimizasyon uyarısı |
| Üretim bağımlılık güvenlik taraması | npm audit ve pip-audit: **bilinen açık bulunmadı**; tarama kapsamı uygulama bağımlılıkları, konteyner OS paketleri değil |
| Üretim konfigürasyonu | Compose config ve Caddy validate başarılı; gerçek konteyner çalıştırma yapılmadı |

Bu turun başlangıcında API SQLite satır kapsamı **%76,95** (1.803/2.343) idi. Son SQLite kapsamı **%77,79** (2.133/2.742), PostgreSQL hattında **%78,01** (2.139/2.742). Yeni koruma kodu eklenmesine rağmen test edilen satır sayısı arttı. Önceki genel audit'in 8 testlik ilk durumuyla bu turun 80 testlik başlangıcı farklı aşamalardır. Kapsam ölçümü satır bazındadır; davranışların %78'inin doğru olduğuna ilişkin bir garanti değildir.

API çalıştırmaları FastAPI/TestClient uyumluluk ve passlib `crypt` kullanımı nedeniyle üç deprecation uyarısı üretir; hata/başarısız test değildir. Flutter/Chromium kontrolleri bağımsızdır; Flutter için native cihaz E2E yapıldığı iddia edilmez.

- `test_release_guardrails.py`: genel/kullanıcı/SMTP/depolama kotaları, kesintide ret, gövde sınırı, oturum iptali, üretim token sözleşmesi, bozuk görseller, cache yarışı, sayfalama, belge zorunluluğu ve güvenli yönetici kurulumunu kapsar.
- `test_real_redis.py`: gerçek Redis'te 150 eşzamanlı kota denemesinde tam 17 kabul, süresi dolan kota, iki hub arasında teslim ve ortak bağlantı sınırı. Yalnızca geçici Redis soketi kullanılır.
- `test_concurrency.py`: gerçek PostgreSQL'de aynı favori/takip/sohbet, token rotasyonu, doğrulama kararı, puan, fotoğraf ve son favori kontenjanı yarışlarını kapsar.
- `test_storage_regressions.py`: sahte içerik, özel belge/yol kaçışı, uzak depolama arızası ve disk dolunca yarım dosya/kota bırakmama.
- Web `tests/unit/api.test.cjs`: aynı origin HTTPS, eşzamanlı refresh, geçici arıza ve gereksiz retry. `tests/e2e/auth.spec.ts`: giriş/favori/yeniden açma, yanlış parola/rol/yönlendirme, arama, mobil filtre, mesaj hatası, yarım yüklemeden yayın, reset ağ hatası, yeni üye belge başvurusu ve eski mesajlara erişim.
- Mobil `auth_interceptor_test.dart`, `marketplace_test.dart` ve mevcut login/widget testleri: oturum, arama/filtre/sayfa, karşılaştırma ve dar ekranda gezinme.

E2E mutlu yolları gerçek API/DB/dosya sistemi kullanır. Negatif ağ senaryolarında ilgili isteğe kontrollü 503 veya ağ kesintisi enjekte edilir; bu ayrım test dosyasında açıktır. Başarısızlıkları gizleyen otomatik retry yoktur.

Testlerin onarım gerekçeleri: fake `b"image"` artık geçerli görsel olmadığı için gerçek PNG fixture'ı kullanıldı; hatalı checksum ayrıca negatif test olarak korundu. Demo doğrulama testi yeni manuel PENDING davranışına uyarlandı. Favori yarışındaki INSERT bariyeri yeni kullanıcı kilidinin arkasında iki isteği sonsuza kadar bekletiyordu; bariyer kilit öncesine taşındı, son kontenjanın yalnızca bir kazananı olduğu ayrıca test edildi. Playwright seçicileri Next.js route announcer ve meta description ile çakışmayacak biçimde görünür hata/form alanlarına daraltıldı.

Makinede disk alanı tükendiği turlar başarılı sayılmadı; sadece üretilen cache'ler temizlenip API hatları ayrı coverage dosyalarıyla sırayla tekrar çalıştırıldı. Flutter SDK'nın Unicode proje yolundaki LSP framing hatası için aynı Dart analiz motorunun `analyzer` protokolü kullanıldı; analiz devre dışı bırakılmadı.

## 5. Ölçülen kapasite

`services/api/scripts/load_test.py` mevcut veriye dokunmadan geçici PostgreSQL, gerçek Redis ve iki API worker'ı kurar. 1.000 ilanla, kullanıcıların liste okuması ve `/auth/me` istekleri ölçüldü.

| Oturum | İstek | Başarı | p50 | p95 | p99 | Kısa ölçümde istek/sn |
|---:|---:|---:|---:|---:|---:|---:|
| 50 | 1.000 | 1.000 / 1.000 | 31,61 ms | 49,90 ms | 66,47 ms | 1410,91 |
| 100 | 2.000 | 2.000 / 2.000 | 63,07 ms | 107,20 ms | 142,12 ms | 1.484,46 |

Bunlar macOS M4 üzerinde yaklaşık 0,7–1,35 saniyelik **kısa API okuma denemeleridir**; önbelleği kullanır, TLS/Caddy, gerçek mobil internet, fotoğraf yükü, uzun süreli yazma, WebSocket yükü, web render yükü veya üretim konteyner bellek/CPU sınırlarını temsil etmez. Sonraki dosya yazımı ve ekran değişiklikleri bu ölçümün kapsamı dışındadır. Rakamlar binlerce eşzamanlı kullanıcı için SLA/kabul sonucu değildir. Üretim kabul ölçümü hedef donanımda yapılmalıdır.

Yerel veritabanı yedeklenerek `0006` → `0008` taşındı; 6 kullanıcı, 30 ilan ve 3 mesaj korundu. Güncel API `/ready` yanıtı başarılı, web 3000 portunda ve iPhone simülatöründe ilan listesi API verisiyle açıldı. Çalışma ağacındaki değişiklikler henüz commit edilmedi.

## 6. Yayın ve sıfır maliyet sınırı

[Yayın kılavuzu](YAYIN_KILAVUZU_TR.md) komutları, güvenli env oluşturmayı, ilk yönetici hesabını, kaynak kotalarını ve yedek prosedürünü içerir. Ücretli AI/SMS/KYC/obje depolama veya autoscale etkin değildir; manuel doğrulama ve yerel dosya saklama seçilmiştir. API iç ağdan genel internete çıkamaz.

Bütçe dolunca istek reddedilir; kullanıcılara kesintisiz/sınırsız erişim vaat edilmez. Uygulama sayacı bütün sağlayıcı faturalandırmasını kapsamaz. Mevcut sunucu/alan adı, internet ve SMTP hizmeti sağlanmadan tüm sistem için **0 TL** veya canlı kullanım garantisi verilemez.

## 7. Açık kalan konular ve öncelikli öneriler

| Kategori / öncelik | İş ve gerekçe | Efor | Etki |
|---|---|---|---|
| Güvenlik — P0 | Hedef sunucu, DNS, SMTP, ilk yönetici ve belge inceleme sorumlularını belirleyip HTTPS kabul testini tamamlamak. Canlı yayının mevcut engelidir. | Orta | Yüksek |
| Test/Kalite Altyapısı — P0 | Üretim konteynerlerini başlatma ve ayrı yedekten tam geri dönüş provası. Compose/Caddy sözdizimi kontrolü bunların yerine geçmez. | Orta | Yüksek |
| Mimari/Performans — P1 | Gerçek hedefte uzun süreli karma okuma/yazma/yükleme ve web render testi; p95/p99, CPU/RAM/disk ve 429/503 oranına göre sabit bütçeyi ayarlamak. Binlerce kişi kapasitesini ancak bu ölçüm belirler. | Orta | Yüksek |
| Güvenlik — P1 | Özel PDF'ler için kendi sunucusunda antivirüs/içerik taraması veya PDF kabulünü kaldırma kararı. Mevcut kontrol dosya biçimidir; zararsız belge garantisi değildir. | Orta | Yüksek |
| Güvenlik — P1 | Belge saklama/silme politikası, şifreli ayrı yedek ve yönetici MFA. Manuel inceleme kimlik/liveness sağlayıcısının güvence düzeyini vermez; belgeler şu an başvuru referansı sürdükçe tutulur. | Orta–yüksek | Yüksek |
| Mimari/Performans — P1 | Sunucu dışından erişilebilirlik/disk alarmı ve bakım sorumlusu. Mevcut paket tek sunucudur; donanım arızası sırasında yüksek erişilebilirlik sağlamaz. | Orta | Yüksek |
| Test/Kalite Altyapısı — P1 | Gerçek Android/iPhone, Safari/Firefox ve imzalı release smoke testleri; SMTP teslim testi. Simülatör/widget testleri cihaz/mağaza yayını değildir. | Orta | Yüksek |
| Güvenlik — P1 | Bağımsız erişim kontrolü/iş mantığı penetrasyon testi ve CSP'nin nonce ile sıkılaştırılması. Otomatik bağımlılık taraması özel iş mantığı açıklarının tamamını bulmaz. | Orta–yüksek | Yüksek |
| Kullanıcı Deneyimi — P2 | Büyük veriyle profil/yönetici ekranı kabul incelemesi, klavye ve ekran okuyucu testi, profesyonel gerçek ilan fotoğrafları. Mevcut E2E bütün ekran kombinasyonlarını kapsamıyor. | Orta | Orta–yüksek |
| Mimari/Performans — P2 | Gerçek arama büyüdüğünde ölçüme göre trigram/tam metin indeksleri; durable bildirim gereksiniminde transaction outbox. Şimdiki pub/sub kesintisi kalıcı mesaj + sorguyla telafi edilir. | Orta | Orta–yüksek |
| Yeni Özellik Fikirleri — P2 | Kayıtlı arama ve uygulama içi fiyat bildirimleri; mevcut filtrelerin tekrar kullanımını kolaylaştırır. Dış ücretli gönderim servisi gerektirmeyen biçimde tasarlanabilir. | Orta | Orta |
| Yeni Özellik Fikirleri — P2 | Randevu takvim dosyası ve karşılıklı tamamlandı onayı; iletişimi ve puanın dayanağını iyileştirir. | Orta | Orta–yüksek |

Teknik dayanaklar: Redis sayaç işlemlerini tek Lua çağrısında yapmak INCR/EXPIRE arasındaki yarış penceresini kapatır ([Redis INCR belgesi](https://redis.io/docs/latest/commands/incr/)). Proxy başlıklarına güvenmek yalnızca güvenilir proxy ağıyla sınırlandırılmalıdır ([FastAPI HTTPS/proxy açıklaması](https://fastapi.tiangolo.com/deployment/https/)); üretim Compose API portunu internete açmaz.
