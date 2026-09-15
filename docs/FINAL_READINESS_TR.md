# Son hazırlık raporu — 15 Eylül 2026

Bu rapordan sonraki iOS derlemeleri, native E2E, router/readiness düzeltmeleri ve güncel yayın engelleri: [Yatırımcı demosu ve TestFlight](TESTFLIGHT_TR.md).

Kod ve yerel üretim doğrulaması tamamlandı. **Genel internete canlı yayın yapılmadı:** hedef sunucu, DNS/alan adı ve SMTP hesabı erişimleri sağlanmadı. Ücretli AI/SMS/KYC/otomatik ölçekleme hizmeti açılmadı. Sunucu, elektrik, bağlantı, alan adı veya mevcut sağlayıcı kotaları için mutlak sıfır maliyet garantisi verilemez.

Önceki arayüz ve sistem denetiminin ayrıntıları [14 Eylül raporunda](PRODUCTION_READINESS_TR.md); bu belge o rapordaki açık maddelerin güncel durumudur. Bu rapor commit/push öncesindeki doğrulama sonuçlarını kaydeder.

## Bu oturumda giderilen sorunlar

| Dosya / işlev | Kök neden ve davranışsal değişiklik | Doğrulama |
|---|---|---|
| `services/api/app/core/deps.py::get_current_user`, HTTP route DB bağımlılıkları | Kimlik kontrolü bağlantıyı endpoint sırasını beklerken tutuyordu; yanıt sonrası kota denetimi de havuzun boşalmasını geciktiriyordu. Kimlik sorgusu sonunda bağlantı bırakılır; HTTP DB kapsamı yanıt gönderilmeden biter. Havuz büyütülmeden 503 sorunu giderildi. | Tek bağlantılı regresyon testi, tüm API/E2E ve aynı 100 oturumlu yük |
| `services/api/alembic.ini` | CLI üzerinden çalışan üretim migration'ı `app` modülünü bulamıyordu. `prepend_sys_path` eklendi. | Gerçek Linux imajında boş PostgreSQL'e 0001–0009 migration |
| `core/mfa.py`, `security.py`, `deps.py`, `routes/auth.py`, `routes/ws.py`, migration `0009` | Üretim admin/moderatör için TOTP zorunlu. Sırlar ayrı anahtarla Fernet şifreli; kod atomik olarak bir kez tüketilir. Giriş denemeleri IP ve MFA hesabı bazında sınırlıdır. Eski/yeniden kurulum öncesi access/refresh/WebSocket oturumları reddedilir; parola sıfırlama MFA'yı kaldırmaz. | RFC 6238 vektörleri, eksik/yanlış/tekrar kod, eşzamanlı tek kazanan, eski oturum, reset; web E2E ve HTTPS smoke |
| `scripts/enroll_mfa.py`, web/mobil giriş | Operatör terminalinden parola ve ilk kod doğrulamasıyla kurulum; yeniden kurulumda mevcut kod da gerekir. Web yönetici ve mobil girişte doğrulayıcı kodu alanı eklendi. SMS veya uzak QR servisi kullanılmaz. | API ve tarayıcı giriş akışı; Flutter testleri |
| `utils/file_validation.py`, `routes/verification.py`, web/mobil belge formu | Biçim kontrolü zararlı PDF riskini gidermiyordu. Yeni PDF kabulü kaldırıldı; eski PDF indirmeleri karantinaya alındı. JPEG/PNG doğrulanıp metadata ve ek yüklerden temizlenir. | Sahte dosya/PDF reddi, yeniden kodlama, özel dosya yetkisi |
| `services/retention.py`, `scripts/maintenance.py` | İncelenmiş belgeler süresiz tutuluyordu. Varsayılan 30 gün sonunda saatlik bakımda silinir; dosya silinemiyorsa kayıt ve kota korunarak yeniden denenir. Bekleyen başvurular korunur. | Bekleyen/yeni/eski belge, depolama hatası, tekrar çalıştırma, kota testleri |
| `scripts/backup.py`, `production.sh` | Açık yedek, eksik Redis kopyası ve geri dönüş provası eksikti. Age şifreleme, tutarlı DB/dosya/Redis görüntüsü, disk ön kontrolü, eşzamanlı yedek kilidi, üzerine yazmama ve ayrı konteynerlerde gerçek geri dönüş eklendi. Yeniden başlatma migration çalıştırmaz. | 10 dosya referansı, 11 arşiv dosyası, 8 Redis kaydı; bozuk şifreli yedek reddi |
| `scripts/monitor.py`, `infra/systemd/*`, Compose healthcheck | HTTPS, disk, durmuş servis ve eskimiş yedek kontrolü yoktu. Yerel monitör, günlük yedek timer'ı, bakım heartbeat'i ve web healthcheck eklendi. | Sağlıklı/hatalı durum testleri; düşük disk ve durdurulmuş servis gerçekten raporlandı |
| `core/config.py`, `infra/compose.smtp.yml` | Dış SMTP'ye iç ağdan erişilemiyordu; gönderici/TLS eksikliği sessiz teslim başarısızlığı doğurabiliyordu. Mevcut dış hesap için isteğe bağlı API çıkış ağı; üretimde STARTTLS ve gönderici doğrulaması eklendi. | Gerçek yerel SMTP yakalama testi, yapılandırma ve gönderim kotası testleri |
| `scripts/analyze_mobile.py` | Flutter aracının Unicode klasör yolunda JSON/LSP hatası vermesi analizi kesiyordu. Kaynakların geçici ASCII kopyasında, aynı bağımlılıklarla analiz çalıştırılır. SDK değişmez. | Flutter analiz komutu; kurucu API'sini korumak için altı satırda hatalı stil önerisi gerekçeli olarak işaretlendi |

## Son test sonuçları

| Kontrol | Sonuç |
|---|---|
| Gerçek PostgreSQL + Redis API unit/regresyon/entegrasyon | **134 geçti, 0 başarısız, 0 atlanan** |
| SQLite + gerçek Redis uyumluluğu | **122 geçti; 12 PostgreSQL'e özel test atlandı** |
| Web unit | **5 geçti** |
| Chromium E2E; dar ekran ve admin MFA dahil | **12 geçti** |
| Flutter testleri | **14 geçti** |
| Flutter kaynak analizi | **0 sorun**; Unicode yol hatası için ASCII kopya yöntemi |
| API satır kapsamı | Önce %78,01 → **%79,19** |
| Ruff F/E9, TypeScript, Next üretim derlemesi | Başarılı |
| Web üretim npm audit / kurulu Python ortamı pip-audit | **Bilinen açık bulunmadı** |
| API ve web Linux Docker imajları | Derlendi; üretim Compose servisleri sağlıklı başladı |
| Yerel gerçek HTTPS smoke | **16 kontrol geçti**, sertifika sistem deposunu değiştirmeden doğrulandı |
| Şifreli geri dönüş | PostgreSQL, dosyalar ve Redis doğrulandı; bozuk yedek reddedildi |

API tarafında üç bağımlılık deprecation uyarısı, web tarafında mevcut `<img>` lint önerileri vardır; bunlar sıfır hata sonucu ile karıştırılmamalıdır. Python taraması kurulu ortamı, npm taraması üretim paketlerini kapsar; konteyner işletim sistemi için bağımsız güvenlik sertifikası değildir.

Testlerin makine okunabilir sonucu: [release-results.json](validation/release-results.json). [HTTPS smoke](validation/production-smoke-september.json), [yedek/geri dönüş](validation/backup-restore-september.json), [API kapsamı](validation/api-coverage-september.json), [yük sonucu](validation/load-mixed-fixed-september.json).

## Kapasite bulgusu

100 oturum, 1.000 ilan, iki Uvicorn çalışanı ve çalışan başına 5+5 bağlantıyla 120 saniye boyunca oturum başına saniyede en çok iki istek gönderildi. İlan/hesap/favori okumaları ve favori ekleme/silme işlemleri kullanıldı; üretim kotaları kaldırılmadı.

- Düzeltme öncesi: 21.937 istekte **139 adet 503**; p99 yaklaşık **4.585 ms**.
- Düzeltme sonrası: **23.900/23.900 başarılı**, ortalama **198,49 istek/sn**, p95 **119,32 ms**, p99 **157,83 ms**.
- HTTP okuma/yazma dağılımı: 19.100 GET, 2.400 POST, 2.400 DELETE.

Bu ölçüm doğrudan yerel API'ye aittir; uzun süreli gerçek sunucu/TLS/görsel yükleme/WebSocket yük testi değildir. HTTPS ve WSS işlevleri ayrıca smoke ile sınandı. Sonuç binlerce eşzamanlı kullanıcının kanıtı veya SLA değildir. Varsayılan günlük 100.000 istek ve 1 GiB API okuma bütçesi yoğun kullanımda erişimi sınırlayabilir; maliyet sınırı ile sınırsız kullanım birlikte vaat edilmez.

## Veri ve işletim güvenliği

Mevcut yerel SQLite önce ayrı 0600 yedeğe alındı, ardından 0008 → 0009 taşındı. **6 kullanıcı, 30 ilan ve 3 mesaj korundu.** Üretim denemesi `trustmarket-audit` projesi ve sahte hesaplarla ayrı volume'larda yapıldı; gerçek SMTP alıcısına ileti gönderilmedi. Deneme konteynerleri ve sahte veri volume'ları doğrulamadan sonra kaldırıldı.

Bu bilgisayarın boş diski deneme sırasında 1 GiB altına indi. Yalnızca bu çalışmanın yeniden üretilebilir derleme çıktıları/kimliği belirlenmiş önbellekleri temizlendi. Bu makineyi doğrulanmış üretim sunucusu saymayın; 2 GiB eşikli monitör disk sorununu raporlar.

## Erişim veya işletme kararı gerektiren kalanlar

1. **Gerçek yayın:** hedef sunucu/SSH, DNS/alan adı, SMTP hesabı ve gerçek yönetici bilgileri yok. Canlı TLS, gerçek alıcıya reset e-postası, dış ağ erişimi ve gerçek sunucu yük testi bu bilgiler olmadan tamamlanamaz.
2. **Uzak yedek ve alarm:** ayrı cihaz/hedef yol ve alarm alıcısı yok. Yerel şifreli yedek/restore sınandı; Linux timer dosyaları hazır ancak gerçek sunucuya kurulmadı. Tam sunucu kaybını aynı sunucudaki monitör bildiremez.
3. **Mobil dağıtım:** fiziksel cihaz, release imzalama ve mağaza yayını bu oturumda doğrulanmadı. Webin dar ekran akışları ve Flutter testleri geçti; önceki iPhone simülatör ekranları önceki rapordadır.
4. **Politika ve bağımsız inceleme:** belge saklama süresinin işletmece onayı, bekleyen başvuruların kapanış politikası, hesap/veri silme talepleri ve MFA cihaz kaybında kimlik doğrulama prosedürü gerekir. Bu denetim bağımsız bir penetrasyon testi değildir; bütün olası açıkların yokluğunu kanıtlamaz.

Yerel geliştirme uygulaması son kontrolde `http://127.0.0.1:3000`, API `http://127.0.0.1:8080` adreslerinde çalıştırıldı. Bu adresler canlı yayın değildir.

Kurulum ve işletim komutları: [Yayın kılavuzu](YAYIN_KILAVUZU_TR.md).

## Öncelikli geliştirme listesi

| Kategori / öncelik | Öneri ve nedeni | Efor | Etki |
|---|---|---|---|
| Mimari/Performans — P0 | Hedef sunucuda uzun karışık yük testi ve disk/CPU ölçümü; gerçek kapasiteyi belirler. | Orta | Yüksek |
| Mimari/Performans — P1 | Mesaj olayları için kalıcı outbox; Redis yayını kesildiğinde bildirim tekrarını güvenilir kılar. | Orta | Yüksek |
| Güvenlik — P0 | Ayrı cihazda anahtar/şifreli yedek kopyası ve gerçek felaket provası; tek disk kaybını kapsar. | Orta | Yüksek |
| Güvenlik — P1 | Hesap silme/MFA kurtarma/retention prosedürü ve bağımsız erişim kontrolü incelemesi; işletme riskini kapatır. | Orta–yüksek | Yüksek |
| Kullanıcı Deneyimi — P1 | Fiziksel iOS/Android cihazlarda kamera, klavye, zayıf ağ ve erişilebilirlik kontrolü; simülasyonun sınırlarını tamamlar. | Orta | Yüksek |
| Test/Kalite Altyapısı — P0 | Gerçek sunucuda timerları ve mevcut ücretsiz alarm kanalını etkinleştirme; sessiz arızaları görünür kılar. | Düşük–orta | Yüksek |
| Test/Kalite Altyapısı — P1 | Admin kararları/rapor işlemleri kapsamını artırma ve bağımlılık uyarılarını kontrollü yükseltmeyle giderme. | Orta | Orta |
| Yeni Özellik Fikirleri — P2 | Harcama yaratmayan kayıtlı arama ve randevu takvim çıktısı; tekrar kullanım ve randevu takibini iyileştirir. | Orta | Orta |

Teknik dayanaklar: [RFC 6238](https://www.rfc-editor.org/rfc/rfc6238), [Fernet](https://cryptography.io/en/stable/fernet/), [Dart kurucu lint kuralı](https://dart.dev/tools/linter-rules/prefer_initializing_formals). Docker temizliği yalnızca doğrulanmış kayıt kimliklerine uygulanmıştır ([Docker filtreleri](https://docs.docker.com/reference/cli/docker/buildx/prune/)).
