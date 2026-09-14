**Şahsından.com — sistem denetimi ve test onarımı, 14 Eylül 2026**

Denetim API, web, mobil, migrasyonlar ve yerel çalıştırma yapılandırmasını kapsar. Bulgular kaynak incelemesi, mevcut testler, yeni negatif senaryolar, gerçek tarayıcı istekleri ve geçici PostgreSQL üzerinde doğrulandı. Değişiklikler çalışma ağacında alan bazında tutuldu; commit veya dağıtım yapılmadı. Bu rapor bütün olası kusurların tükendiği iddiasını taşımaz.

**1. Keşif ve envanter**

| Katman | Yapı ve kritik akışlar | Başlangıç test durumu |
| --- | --- | --- |
| `services/api` | FastAPI, SQLAlchemy, Alembic; kullanıcı/rol, JWT, doğrulama, ilan, favori/takip, mesaj, randevu, rapor, yönetici işlemleri | 7 modülde 8 test; SQLite ve bellek Redis |
| `apps/web` | Next.js App Router, React Query, Tailwind; rol bazlı giriş, doğrulama, ilan ve yönetici ekranları | Test çalıştırıcısı yok; lint yapılandırması interaktif soruda kalıyordu |
| `apps/mobile` | Flutter, Riverpod, Dio, go_router, secure storage | 3 test dosyası; ilk çalıştırma eksik `.env` asset'i nedeniyle başlayamadı |
| `infra` | PostgreSQL 15, Redis 7, MinIO, Nginx, çok işçili Uvicorn | Konteyner entegrasyon testi yok |
| Migrasyonlar | `0001_initial`–`0006_follow_system` | Otomatik migrasyon testi yok |

Başlangıçta doğrudan test edilmeyen kritik alanlar: yönetici kararları, şifre sıfırlama güvenliği, özel dosyalar, WebSocket yetkilendirmesi, çok sayıda negatif ilan/randevu senaryosu ve migrasyon-model uyumu. Mevcut senaryolar daha çok başarılı akışlara odaklanıyordu.

İlan okumak kimlik doğrulaması gerektiriyor; bekleyen kullanıcılar yayımlanmış ilanları okuyabiliyor. İlan oluşturma, mesaj, randevu, favori ve takip işlemleri doğrulanmış rol gerektiriyor. Ödeme/emanet ödeme, gerçek OTP/KYC ve e-posta teslimatı çalışan entegrasyonlar değil, gelecekteki entegrasyon noktaları.

**2. Bulunan ve düzeltilen sorunlar**

| Dosya / fonksiyon | Kök neden ve düzeltme | Davranışsal etki |
| --- | --- | --- |
| `app/core/security.py` — `decode_access_token` | Erişim ve sıfırlama JWT'leri aynı anahtarla, amaç kontrolü olmadan okunuyordu. Zorunlu claim, amaç ve subject kontrolü eklendi. | Sıfırlama/download tokenıyla oturum açılamaz; bozuk claim'ler 500 yerine 401 döner. Rol ve süre içeren eski erişim tokenları uyumludur. |
| `app/api/routes/auth.py` — `refresh_token` | Okuma ve iptal ayrı olduğundan aynı refresh tokenı yarışta iki kez kullanılabiliyordu. Kullanıcı, süre ve iptal durumuyla koşullu tek UPDATE uygulanıyor. | Tek kullanım; PostgreSQL üzerinde iki eşzamanlı isteğin sonuçları 200 ve 401. |
| `auth.py`, `core/deps.py`, `routes/ws.py` | Askıya alınmış/yasaklı hesap kontrolleri giriş, refresh, HTTP ve WebSocket arasında tutarsızdı. | Devre dışı hesaplar yeni erişim elde edemez; bekleyen hesapların WebSocket bağlantısı da reddedilir. |
| `auth.py` — `forgot_password`, `reset_password` | Sıfırlama tokenı herkese yanıtta dönüyor, tekrar kullanılabiliyor ve refresh oturumları açık kalıyordu. Üretimde teslimat yapılandırılana kadar 503; geliştirmede şifre sürümüne bağlı tek kullanımlı token, koşullu şifre değişimi ve refresh iptali eklendi. | Üretimde hesap ele geçirmeye açık demo sıfırlama kapalıdır. Değişiklik öncesi sıfırlama tokenları geçersiz olur. Mevcut erişim JWT'lerinin süresi ayrı olarak devam eder. |
| `auth.py` — `logout`, cookie oluşturma | Geçersiz çerezde erken dönüş çerezi silmiyordu; üretim çerezi Secure değildi. | Her çıkış yanıtı çerezi siler; üretimde HTTPS çerezi kullanılır. |
| `auth.py` — `register`; `routes/listings.py` — `create_listing` | Kullanıcı/profil ve ilan/araç detayı ayrı commit'lerle kısmen kaydedilebiliyordu. Ara adımlar flush'a çevrildi. | İlgili kayıtlar tek transaction içinde tamamlanır. |
| `schemas/auth.py` | E-posta kırpma doğrulamadan sonra yapılıyordu; bcrypt'in 72 bayt sınırı kayıt/sıfırlamada kontrol edilmiyordu. | Boşluklu e-posta normalize edilir; uzun yeni şifreler sessiz kesilmek yerine 422 döner. |
| `core/config.py` | Üretimde kısa/aynı JWT anahtarı ve joker CORS ile açılmak mümkündü. | Üretim ayarlarında bu yapılandırmalar başlangıçta reddedilir. |
| `routes/listings.py` — `list_listings`, `favorite_listing`; `routes/favorites.py` | `include_inactive=true` başka kişilerin taslaklarını açıyordu; favori yolu da gizli ilanları okuyabiliyordu. | İnaktif listeler sahibine sınırlandı; başkasının gizli ilanı favorilenemez ve favori listesinden okunamaz. Yönetici ekranı kendi endpoint'ini kullanır. |
| `routes/listings.py` — `publish_listing`, `confirm_active` | Reddedilmiş/satılmış ilan yeniden yayımlanabiliyordu. | Terminal durumlar 409 verir; yönetici reddi sahibi tarafından geri alınamaz. |
| `schemas/listing.py`; `db/models.py` | Negatif/sonlu olmayan fiyatlar, açık null güncellemeleri ve boş başlıklar doğrulanmıyordu. Modelde CHECK constraint sınıf kurulduktan sonra atanıyordu. | Hatalı HTTP girdileri 422; modelle kurulan test DB'sinde de fiyat CHECK'i mevcut. Migrasyonda zaten bulunan constraint ile uyum sağlandı. |
| `routes/appointments.py` — `_transition`, `reschedule`, `rate` | İstekten doğrudan tamamlamaya veya terminal durumdan yeniden açmaya izin veriliyordu. | Mobildeki mevcut durum kuralları sunucuda uygulanır; geçersiz geçiş 409; bitmemiş randevu puanlanamaz. Durum yazımı koşulludur. |
| `routes/admin.py` — `set_report_status` | Güven hesabı yalnızca RESOLVED'da çalışıyordu; puan hesabı CONFIRMED kullanıyordu. | Onaylanan rapor cezayı uygular; karar tersine çevrilince puan düzelir. |
| `services/stale.py`, `main.py` — arka plan döngüsü | Autoflush kapalıyken çok eski ilan ilk turda arşivlenmiyordu; değişen ilanlar tekrar/çift sayılıyordu. Bir exception döngüyü sonlandırıyordu. | Eski ilan tek turda arşivlenir, sayı benzersizdir, geçici hatadan sonra sonraki tur çalışır. |
| `services/marketplace_settings.py`, `schemas/admin.py`, ilan/stale işlemleri | Yönetici ayarları DB'ye yazılıyor, gerçek işlemler ortam sabitlerini okuyordu. | Kaydedilmiş şehir, eskime süresi ve fotoğraf limitleri uygulanır; negatif/geçersiz limitler reddedilir. Fotoğraf boyutu üst sınırı mevcut proxy sınırına uyacak şekilde 8 MB'dır. |
| `routes/verification.py` — `submit`, `status` | Başarısız selfie kabul ediliyor; kullanıcının meslek beyanı doğrulanmış sayılıyor; reason_code yanıta taşınmıyordu. | Başarısız selfie reddedilir, beyan doğrulama sağlamaz; durum yanıtı reason_code içerir. Demo sağlayıcı üretimde 503 döner. |
| `routes/admin.py` — doğrulama kararları | Onay bir yönetici hesabını USER_VERIFIED'a düşürebiliyor; incelenmiş talep yeniden karara bağlanabiliyordu. | Yetkili rol korunur, kapalı talepte 409; meslek belgesi bulunan talebin moderatör onayı meslek doğrulamasını sağlar. |
| `utils/storage.py`, dosya yükleme endpoint'leri | Kullanıcı dosya adı doğrudan yola ekleniyordu; aynı ad dosyayı eziyordu; S3 hatası sonraki istekte sessiz yerel depolamaya geçiyordu. | UUID anahtarları, yerel kök sınırı, sınırlı okuma ve açık 503 hatası; başarısız yükleme için DB varlığı yaratılmaz. |
| `main.py` — `mount_public_storage`; özel indirme endpoint'i; Nginx | Yerel storage kökü içinde SQLite DB ve doğrulama belgeleri de statik sunuluyordu. “signed_url” gerçekten imzalı değildi. | Statik erişim yalnızca ilan fotoğraflarına açık; özel belgeler yönetici tarafından oluşturulan 5 dakikalık amaç kısıtlı bağlantı gerektirir. |
| `storage.py` — `presigned_url`; `listings.py` — `photo_content` | Özel MinIO nesnesine imzasız URL üretiliyordu. | Uzak fotoğraf API tarafından doğrulanmış 1 saatlik bağlantıyla okunur; MinIO bucket'ının herkese açılması gerekmez. |
| `infra/nginx.conf` | WebSocket Upgrade/Connection başlıkları iletilmiyordu. | Proxy yükseltme başlıkları eklendi. Docker zincirinde canlı doğrulama yapılamadı. |
| Mobil `auth_interceptor.dart` | Tüm `/auth/*` yolları atlandığından `/auth/me` token almıyor/yenilenmiyordu; geçici refresh hatası kullanıcıyı çıkarıyordu. | Sadece herkese açık auth yolları hariç tutulur; `/me` bir kez yenilenip tekrar denenir; 503 oturumu silmez. |
| Mobil `app_env.dart`, `.env.example`, kurulum belgeleri | Docker'sız API'nin `/api` kullanmadığı varsayılmıştı. | Her iki çalışma modunda da doğru `/api` adresi kullanılır. |
| Web `lib/api.ts`, `lib/auth.tsx` | Yanlış şifre 401'i yönlendirme yapıyordu; eşzamanlı bootstrap token döndürüyordu; geciken auth yanıtı yeni durumu ezebiliyordu; kullanıcı değişiminde query cache kalıyordu. | Yanlış şifre formda gösterilir; refresh paylaşılır; eski auth işlemi state'e yazamaz; cache temizlenir. Auth'lı 401 bir kez yenilenip denenir. Headers ve FormData doğru korunur. |
| Web rol giriş paneli, `lib/redirect.ts`, kayıt ekranı | Yanlış rol yalnızca yerel state'i temizliyordu; `//host` yönlendirmesi kabul ediliyordu; giriş ve RouteGuard aynı anda istemci yönlendirmesi yapabiliyordu. | Yanlış rolde sunucu çıkışı; güvenli yerel hedef kontrolü; giriş yeni çerezden tam sayfa geçişi yapar. |
| `scripts/dev_mobile_web.sh` | `exec flutter` shell'i değiştirdiği için EXIT temizliği API sürecini kapatamıyordu. | Flutter normal alt süreç olarak çalışır; çıkışta API temizlenir. Eksik ilk `.env`, örnekten hazırlanır. |

Kozmetik yeniden tasarım yapılmadı. İki JSX apostrofu lint hatasını gidermek için düzeltildi; dokunulan alanlardaki kullanılmayan importlar kaldırıldı. Mesaj serileştirmede benzer fonksiyonlar ve kullanılmayan çıktı şemaları hâlâ sadeleştirme adaylarıdır; yalnızca benzer göründükleri için silinmediler.

**3. Test onarımı ve doğrulama sonuçları**

| Kontrol | Önce | Sonra |
| --- | --- | --- |
| API tüm testler | 8 başarılı | İlk tur 54; devam turunda SQLite 80, PostgreSQL 88 başarılı (8 gerçek yarış senaryosu dahil) |
| API satır kapsamı | %60,09 — 1286/2140 satır | İlk tur %72,24; devam turu %76,95 — 1803/2343 satır (SQLite süiti) |
| Mobil | `.env` olmadan asset derleme hatası | 7 başarılı: mevcut 3 + yeni 4 |
| Web gerçek tarayıcı | Yok | Chromium'da 4 akış, üretim ve geliştirme sunucularında ayrı ayrı başarılı |
| Web derleme/tip/lint | Lint ilk yapılandırma sorusunda duruyordu | Next.js 15 üretim derlemesi ve TypeScript başarılı; lint hatası yok, 8 görüntü optimizasyonu uyarısı var |
| Python statik analiz | Kullanılmayan importlar | Ruff F/E9 kontrolleri başarılı |
| Mobil statik analiz | Unicode çalışma yolunda araç LSP JSON hatası | Aynı kaynakların geçici ASCII yolunda analiz: hata/uyarı yok, 2 info bildirimi |
| Migrasyonlar | Test yok | SQLite migrasyon-model sütun testi; geçici PostgreSQL 16 üzerinde head'e yükseltme başarılı |
| Gerçek PostgreSQL yarış testi | Yok | 8 senaryo: favori, takip, sohbet, iki randevu sonucu kombinasyonu, doğrulama kararı, rapor cezaları, refresh |
| Bağımlılık güvenliği | npm: 18 etkilenen paket; pip-audit: test ortamı dahil 7 pakette 56 bildirim | Son npm ve pip-audit taramaları: bilinen açık yok |

Başlangıçtaki sekiz API testi hatalı değildi; düzeltmelerden sonra da korundu. İlk 23 yeni senaryonun 21'i ve dört yükleme senaryosunun tamamı düzeltme öncesi başarısızdı. Mobil yenileme testindeki ilk hata test doubles'ının isteğe göre yanıt değiştirmemesinden kaynaklandı; gerçek iki yanıtlı adapter ile düzeltildi. Tarayıcı testindeki genel `alert` seçicisi Next.js duyurusu ile çakıştığı için mesaj içeriğine daraltıldı. Geliştirme sunucusunun ilk derlemesi/HMR sırasında giriş takılması ayrıca gözlendi; giriş yönlendirmesi düzenlendi ve varsayılan E2E üretim derlemesine taşındı. Düzeltmeden sonra geliştirme sunucusunda da dört testin tamamı geçti. Retry ile başarısızlık gizlenmiyor.

Yeni API modülleri: `test_security_regressions.py`, `test_lifecycle_regressions.py`, `test_storage_regressions.py`, `test_admin_regressions.py`, `test_websocket.py`, `test_migrations.py`, `test_background_job.py`. `conftest.py` dış ortam DB/Redis değerlerini zorunlu izole değerlerle değiştirir; gerçek Redis'e FLUSHALL gönderme riski kaldırıldı. Test motorları kapanışta dispose edilir.

Yeni mobil testler `auth_interceptor_test.dart` içindedir: `/me` tokenı, süresi geçmiş tokenın yenilenmesi/tekrarı, yanlış şifrede yenileme yapılmaması, geçici sunucu hatasında oturumun korunması.

`apps/web/tests/e2e/auth.spec.ts` gerçek API ve geçici SQLite verisi kullanır; backend yanıtları mock değildir. Akışlar: giriş → ilan → favori → yeniden yükleme; yanlış şifre; yanlış panel rolü ve çerez temizliği; dış adrese yönlendirmeyi reddetme. Her test ayrı browser context kullanır; sunucular mevcut bir geliştirme sunucusunu yeniden kullanmaz. E2E build `.next-e2e` dizinindedir.

Çalıştırılan ortam: Python 3.11.14, Flutter 3.47.1 / Dart 3.13.1, macOS ARM64, yerel PostgreSQL 16. Dockerfile Python 3.12 ve Compose PostgreSQL 15 üzerindeki tam zincir bu oturumda çalıştırılamadı. Flutter çalıştırması test SDK'sına bağlı dört alt paket kilidini ve analiz hariç tutmalarını güncelledi.

**3.1. Devam turu — eşzamanlılık ve işlem bütünlüğü (14 Eylül 2026)**

| Dosya / fonksiyon | Kök neden ve düzeltme | Davranışsal etki |
| --- | --- | --- |
| `services/unique_relations.py`; `follows.follow_user`, `listings.favorite_listing`, `messaging.create_thread` | Ön kontrol ile INSERT arasında başka istek aynı benzersiz kaydı ekleyebiliyordu. SQLite/PostgreSQL için yalnızca ilgili benzersiz anahtara uygulanan `ON CONFLICT DO NOTHING RETURNING` kullanılır. | Tek kayıt oluşur; tekrar isteği 200, yeni takip/sohbet 201 döner. Diğer constraint hataları gizlenmez; helper commit yapmaz. |
| `services/audit.py`; `routes/admin.py` içindeki 15 audit çağrısı | İş kaydı önce, audit sonra commit ediliyordu. Helper yalnızca flush eder; commit endpoint'in sonundadır. | Audit yazılamazsa yönetici değişikliği de geri alınır. Yalnızca not yazan endpoint'ler açıkça commit eder. |
| `services/trust.py`; `appointments._transition`, `admin.set_report_status`, rol/doğrulama işlemleri | Ayrı commit kısmi kayıt bırakıyordu; eşzamanlı hesaplar puanı ezebiliyordu. Bekleyen değişiklikler flush edilir, kullanıcı `FOR NO KEY UPDATE` ile kilitlenir ve güncel sayımla hesaplanır. | Randevu/rapor, puan ve olay/audit birlikte tamamlanır. İki tamamlanan randevu 60; tamamlanan + gelinmeyen randevu 35; iki onaylı rapor 30 puan verir. Mevcut puanlama kuralları korunur. |
| `admin.approve_verification`, `reject_verification`, `request_more_info` | Karar için okunan talep satırı kilitlenmiyordu. Talep kilidi eklendi; onayda kullanıcı da kilit altında kontrol edilir. | PostgreSQL'de eşzamanlı onay/red tek kazanan ve tek audit kaydı üretir; kaybeden 409 alır. |
| `admin.ban_user`, `unban_user` | Rol değişimine rağmen puan yenilenmiyordu; BANNED rolüyle yasak kaldırılabiliyordu. | Puan mevcut kuralla yeniden hesaplanır; çelişkili unban 400 ile reddedilir. |
| `admin.set_report_status`, `update_settings` | Yeniden açılan raporda çözüm tarihi kalıyordu; aynı JSON sözlüğünün yerinde değişimi SQLAlchemy tarafından algılanmıyordu. | Yeniden açmada çözüm alanları temizlenir; ücret JSON'u kopyalanarak sayısal sütunla birlikte güncellenir. |
| `appointments._transition`, yönetici puan/ilan işlemleri | Cache eski puanı taşıyabiliyor veya commit öncesi geçersiz kılınabiliyordu. | Cache commit sonrasında geçersiz kılınır; randevu sonrası ilan listesi yeni puanı döndürür. |
| `alembic/env.py` | URL içindeki yüzde kodları ConfigParser tarafından interpolasyon kabul ediliyordu. | `%` kaçışı ile kodlanmış soket yolları/parolalar ve yüzde içeren SQLite yolları migrasyonu durdurmaz. |

Eklenen testler: `test_transaction_regressions.py` (20 senaryo), `test_relation_regressions.py` (5), `test_concurrency.py` (8); mevcut migrasyon testine yüzde içeren yol varyantı, randevu testine cache görünürlüğü doğrulaması eklendi. Bu tur toplam 34 yeni test senaryosu getirdi.

Kanıt: İlk 13 transaction regresyonunun tamamı düzeltme öncesi başarısızdı. PostgreSQL'de üç ilişki testi UniqueViolation verdi. İlk atomik puanlama denemesinde kullanılan daha güçlü `FOR UPDATE` kilidi yabancı anahtar kontrolleriyle deadlock üretti; `FOR NO KEY UPDATE` düzeltmesiyle geçti. Ücret JSON'u ve çelişkili unban için ek iki test de düzeltmeden önce başarısızdı. Yeni refresh testindeki yanlış alan adı (`revoked` yerine `revoked_at`) ve cache testindeki eksik yetki başlığı test tarafında düzeltildi.

Son doğrulama: SQLite **80 başarılı**, PostgreSQL **88 başarılı** (atlanmış test yok), üretim web sunucusuna karşı Chromium **4 başarılı**, API/test/migrasyon ve iki test runner'ı için Ruff F/E9 başarılı, `git diff --check` temiz. PostgreSQL test cluster'ı kapanıp silindi. API kapsamı önceki turdaki **%72,24 → %76,95** oldu. Mobil kod bu turda değişmedi; önceki turdaki 7 başarılı test sonucu korunuyor, yeniden çalıştırılmadı. Tüm `scripts/` dizinine genişletilen Ruff taraması, bu tur dokunulmayan `seed_sqlite.py` içinde kullanılmayan `os` importu ve `admin` atamasını da işaretledi; bu iki temizlik adayı açık bırakıldı.

**4. Bağımlılık ve uyumluluk değişiklikleri**

Next.js 14.2.5 → 15.5.24; eski sunucu yönlendirmesi `params` değerini await edecek şekilde uyarlandı. React 18 korundu; Next.js'in bu sürümündeki peer aralığıyla uyumlu. PostCSS 8.5.23 hem npm hem pnpm override ile alt ağaca uygulandı. Platforma zorlanmış Darwin SWC bağımlılığı kaldırıldı. pnpm kilidi doğrulanmış npm kilidinden aktarıldı.

FastAPI 0.141.1, Starlette 1.6.0, Pydantic 2.13.5, PyJWT 2.14.0, python-multipart 0.0.32, python-dotenv 1.2.3, pytest 9.1.1 ile API testleri yeniden çalıştırıldı. Denetim araçları `requirements-dev.txt` içindedir. Python test ortamındaki pip/setuptools da tarama için güncellendi; Docker temel imajının kendi araçları ayrıca taranmalıdır.

Güvenlik sürümü seçimi üretici bildirimleriyle doğrulandı: [Next.js AVIF bildirimi](https://github.com/vercel/next.js/security/advisories/GHSA-2xp9-vwfh-vxw4), [Next.js 15 geçiş rehberi](https://nextjs.org/docs/app/guides/upgrading/version-15), [PostCSS kaynak haritası bildirimi](https://github.com/postcss/postcss/security/advisories/GHSA-fxqj-rqcc-2cmp). “Bilinen açık yok” yalnızca taranan paket sürümlerinin o andaki veritabanı sonucudur; tüm sistem için güvenlik garantisi değildir.

**5. Açık riskler ve doğrulama sınırları**

- **Üretim OTP/KYC ve şifre sıfırlama teslimatı:** Sağlayıcı/teslimat entegrasyonu yok. Güvensiz demo davranışı üretimde 503 ile kapatıldı. Gerçek sağlayıcı ve teslimat gereksinimi olmadan bu özellikleri tamamlanmış saymak doğru olmaz.
- **Konteyner zinciri:** Docker daemon çalışmıyordu. Compose yapılandırması sözdizimi kontrolünden geçti; Nginx → API → Redis/MinIO akışı, çok işçili Uvicorn ve canlı MinIO hataları entegrasyon ortamında doğrulanmalı. S3 erişimi bu oturumda test double ile denendi.
- **WebSocket çok işçi davranışı:** RealtimeHub bağlantıları süreç belleğinde tutuyor; dört işçi arasında Redis pub/sub dağıtımı yok. Mevcut açık bağlantının sonradan banlanması/erişim tokenının süresinin dolması da bağlantıyı kendiliğinden sonlandırmıyor. HTTP ve yeni bağlantılar güncel yetki kontrolünden geçiyor.
- **Kalan yarışlar:** Favori/takip/sohbet ekleme, randevu/rapor puan hesabı ve doğrulama kararları PostgreSQL regresyonlarıyla kapsandı. Fotoğraf sayı sınırının eşzamanlı yüklemede aşılması ve ilk sistem ayarı oluşturmanın tek kayıt garantisi ayrıca ele alınmalı. SQLite genel işlev/geri alma testlerinden geçti; gerçek çok bağlantılı SQLite kilit davranışı bu turda sınanmadı. Bu testler bir yük testi garantisi değildir.
- **DB dışı tutarlılık:** Randevu/rapor/güven puanı ve yönetici audit işlemlerinin ayrı commit sorunu giderildi. Mesaj kaydı ile yanıt süresi hesabı ve gerçek zamanlı bildirim teslimatı hâlâ ayrı adımlardır; bildirimler için outbox/yeniden deneme gerekir. Cache invalidation commit sonrasında yapılır; Redis hatası ve süreç kesintisinde anlık görünürlük garanti edilmez.
- **JWT yaşam süresi:** Şifre sıfırlama refresh tokenlarını iptal eder; daha önce verilmiş access tokenı varsayılan 30 dakikalık süresi dolana kadar yaşayabilir. Anlık iptal için session/version alanı gerekir. Mobil refresh tokenı hâlâ query parametresi ile aktarılıyor; log redaksiyonu ve body tabanlı protokol önerilir.
- **Dosya içeriği:** MIME bildirimi ve boyut sınırı kontrol ediliyor; antivirüs fonksiyonu placeholder. Gerçek dosya imzası, tarama/karantina ve belge saklama/silme süresi tamamlanmadı. Kısa süreli indirme bağlantıları süreleri dolana kadar taşıyan kişiye erişim sağlar.
- **Alan kararları:** NO_SHOW cezası mevcut modelde satıcıya yazılıyor; gelmeyen taraf ayrı saklanmıyor. Kimin bildirebileceği ve kimin cezalandırılacağı ürün kararı gerektiriyor. Meslek belgesi onayının kapsamı da gerçek doğrulama sağlayıcısı ile netleşmeli.
- **Test boşlukları:** API kapsamı %76,95; özellikle yönetici filtreleri ve bazı hata yolları eksik. Mobilde tam cihaz E2E, web'de ödeme dışındaki tüm yönetici/mobil çapraz akışlar yok. Şema testi sütun ve fiyat constraint'ini kontrol eder; her indeks/tip/default farkını karşılaştırmaz.
- **Araç bildirimleri:** API'de `httpx`/AnyIO TestClient ve passlib `crypt` deprecation bildirimleri sürüyor. Python 3.13+ geçişi ayrıca ele alınmalı. Web'deki `<img>` uyarıları tasarımı değiştirmemek için bırakıldı. Flutter analizindeki iki info bildirimi deprecated `onReorder` ve testte `const` kullanımıyla ilgili.

**6. Tekrar çalıştırma**

```bash
# API — services/api içinde, uygun Python sanal ortamı etkinleştirilmişken
python -m pip install -r requirements-dev.txt
python -m pytest -m "not postgres" --cov=app
# PostgreSQL sunucu araçları PATH üzerindeyse tüm 88 testi ve migrasyonları çalıştırır:
python scripts/test_postgres.py
# Alternatif: python scripts/test_postgres.py --pg-bin /opt/homebrew/opt/postgresql@16/bin
ruff check --isolated --select F,E9 app tests scripts/e2e_server.py scripts/test_postgres.py alembic
pip-audit

# Web — apps/web içinde
npm ci
npm run lint
npm run typecheck
npm run build
npx playwright install chromium
# API_PYTHON gerekiyorsa API sanal ortamındaki Python'un tam yoludur.
npm run test:e2e
npm audit

# Mobil — apps/mobile içinde; ilk kurulumda mevcut .env'yi ezmeden hazırlayın
test -f .env || cp .env.example .env
flutter pub get
flutter test --coverage
flutter analyze
```

Geliştirme sunucusunu hedeflemek için `E2E_DEV_SERVER=1 npm run test:e2e` kullanılabilir. Ağdan font indirilemeyen ortamlarda web build ayrıca font önbelleği/yerel font gerektirir. PostgreSQL yarış testleri artık depoda sürümlenebilir durumdadır. `scripts/test_postgres.py` geçici cluster açar, TCP dinlemez, migrasyonları çalıştırır, her test için ayrı şema kullanır ve sonunda sunucuyu kapatıp verisini siler. Mevcut DB_URL/Redis ayarları testlere taşınmaz. PostgreSQL olmadan doğrudan pytest çağrısında 8 yarış testi açık gerekçeyle atlanır; bunların doğrulaması runner ile yapılır. CI job bağlantısı henüz eklenmedi.

**7. Önceliklendirilmiş geliştirme önerileri**

Her kategori içindeki öneriler öncelik sırasındadır. P0 üretim öncesi, P1 yakın dönem, P2 sonraki dönemdir.

- **Mimari/Performans — P0:** WebSocket olaylarını Redis pub/sub ile işçiler arasında dağıtın ve ban/süre sonu bağlantı kapatmayı ekleyin. Mesajların işçi seçimine göre kaybolmasını önler. **Efor: orta; etki: yüksek.**
- **Mimari/Performans — P1:** İlan, mesaj ve yönetici listelerine sayfalama; sorgu bütçesi ve indeks planı ölçümü ekleyin. Şu an birçok liste `.all()` ile sınırsız yükleniyor. **Efor: orta; etki: yüksek.**
- **Mimari/Performans — P1:** Mesaj bildirimleri için transactional outbox ve yeniden deneme ekleyin. DB kaydından sonra süreç durduğunda bildirimin kaybolmasını önler. Güven skoru/audit için tek transaction bu turda tamamlandı. **Efor: orta; etki: yüksek.**
- **Güvenlik — P0:** Gerçek OTP, kimlik/meslek doğrulama ve e-posta sıfırlama teslimatı bağlayın. Üretimde kapalı bırakılan kritik akışları güvenli açar. **Efor: yüksek; etki: yüksek.**
- **Güvenlik — P0:** Token/session sürümü ve body tabanlı mobil refresh ekleyin; hassas logları redakte edin. Anlık iptal ve token sızıntısına karşı koruma sağlar. **Efor: orta; etki: yüksek.**
- **Güvenlik — P1:** Dosya imzası kontrolü, tarama/karantina ve özel belge saklama politikasını tamamlayın. Kullanıcı bildirimi tek başına dosyanın güvenilirliğini sağlamaz. **Efor: orta–yüksek; etki: yüksek.**
- **Kullanıcı Deneyimi — P1:** Randevuda gelmeyen taraf, itiraz ve karşılıklı onay akışını tanımlayın. Yanlış kişiye güven cezasını önler. **Efor: orta; etki: yüksek.**
- **Kullanıcı Deneyimi — P1:** İlan fotoğrafı boyutlandırma ve yükleme hatasında kaldığı yerden devam ekleyin. Mobil veri tüketimini ve tekrar yüklemeleri azaltır. **Efor: orta; etki: orta.**
- **Test/Kalite Altyapısı — P0:** CI'da Python/web/mobil testleri, üretim build, bağımlılık taraması ve başarısızlık artifact'lerini zorunlu hale getirin. Bu oturumdaki kazanımların korunmasını sağlar. **Efor: orta; etki: yüksek.**
- **Test/Kalite Altyapısı — P1:** Eklenen PostgreSQL runner'ını CI'a bağlayın; gerçek Redis/MinIO, fotoğraf kotası ve çok işçi senaryolarıyla genişletin. Bellek servislerinin gizlediği hataları yakalar. **Efor: orta; etki: yüksek.**
- **Test/Kalite Altyapısı — P1:** Yönetici ve mobil cihaz akışlarını genişletin; kapsam eşiğini mevcut ölçümden başlayarak artırın. Salt yüzdelik yerine negatif iş kurallarını korur. **Efor: yüksek; etki: yüksek.**
- **Yeni Özellik Fikirleri — P2:** Kayıtlı arama ve fiyat/ilan durumu bildirimleri. Kullanıcının aynı filtreleri tekrar uygulamasını azaltır. **Efor: orta; etki: orta.**
- **Yeni Özellik Fikirleri — P2:** Randevu hatırlatma, takvim bağlantısı ve karşılıklı tamamlandı onayı. Randevuya katılımı ve güven skorunun doğruluğunu artırır. **Efor: orta; etki: yüksek.**
- **Yeni Özellik Fikirleri — P2:** Araç geçmişi/ekspertiz entegrasyonu. İlan bilgisini bağımsız veriyle destekler; sağlayıcı ve maliyet kararı gerekir. **Efor: yüksek; etki: yüksek.**
