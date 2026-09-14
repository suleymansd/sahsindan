# Üretim yayını ve işletim

Bu paket kendi sunucunuzda PostgreSQL, Redis, FastAPI, Next.js ve Caddy çalıştırır. Ücretli AI, SMS, otomatik kimlik doğrulama, obje depolama veya otomatik ölçekleme servisi açmaz. Sunucu, internet trafiği, alan adı, elektrik, yedek diski ve uygulama mağazası hesapları için **sıfır maliyet garantisi vermez**. Var olan donanım ve hesapların sınırları ayrıca doğrulanmalıdır.

## Yayın için gereken bilgiler

- Kontrolünüzdeki sunucu ve DNS alan adı; A/AAAA kayıtları sunucuyu göstermeli, 80/443 TCP ve 443 UDP erişilebilir olmalı. Çalışmayan IPv6 adresi yayımlamayın.
- Docker Engine ve Compose; ilk pilot için yaklaşık 4 GB RAM, 2 vCPU ve en az 30 GB boş disk başlangıç tahminidir, kapasite garantisi değildir. İmaj derleme ve yedekler ayrıca alan kullanır.
- Mevcut bir SMTP aktarım sunucusu, gönderen adresi ve gerekiyorsa kimlik bilgileri. SMTP yoksa şifre sıfırlama 503 döner; bu akış doğrulanmadan genel kullanıma açmayın.
- İlk yönetici ve kimlik belgelerini inceleyecek yetkili ekip. SMS/liveness doğrulaması yerine manuel inceleme vardır.

Bu oturumda canlı sunucu/alan adı/SMTP bilgileri sağlanmadı. Docker daemon da çalışmıyordu. Compose yapılandırması ve Caddy 2.11.4 ile HTTPS geçidi sözdizimi doğrulandı; üretim konteynerlerinin gerçekten başlatıldığı veya internetten erişildiği iddia edilmez.

## Kurulum

Depo kökünde, kendi gerçek değerlerinizi kullanın:

```bash
python3 scripts/production_env.py --domain ilan.ornek.com --email yonetici@ornek.com
```

Komut `infra/.env.production` dosyasını 0600 izinleriyle oluşturur, üç bağımsız rastgele sır üretir; sırları terminale yazmaz ve var olan dosyayı üzerine yazmaz. Dosya Git tarafından yok sayılır. Oluşan veritabanı parolasını URL uyumlu hexadecimal biçiminde tutun.

Bu dosyada SMTP ayarlarını doldurun. API ve bakım servisi yalnızca `internal` Docker ağına bağlıdır; genel internete çıkamaz. SMTP sunucusu bu ağdan erişilebilen mevcut bir aktarım servisi olmalıdır. Harici bir SMTP adresini yalnızca yazmak erişim sağlamaz. İç ağda relay kullanın; genel çıkış erişimini açma kararı verilirse sağlayıcının ücret sınırlarını ayrıca uygulayın. SMTP STARTTLS varsayılan olarak açıktır.

```bash
scripts/production.sh check
scripts/production.sh deploy
scripts/production.sh admin
scripts/production.sh status
```

`deploy`: imajları derler, veritabanını `0008_storage_budget` sürümüne taşır, mevcut dosya kullanımını uzlaştırır, iki API çalışanı ve tek bakım servisi açar. Caddy alan adında TLS sertifikasını alır. İlk yönetici komutu parolayı gizli ister; mevcut bir hesabın rolünü sessizce yükseltmez. Yönetici girişi `/giris/admin` yolundadır. **Üretimde demo seed komutlarını çalıştırmayın.**

Yayından önce `services/api/scripts/test_postgres.py`, `tests/test_real_redis.py`, web unit/E2E ve Flutter testlerini çalıştırın. `.github/workflows/release-checks.yml` yalnızca elle başlatılır; hesap CI kotası kontrol edilmeden başlatılmamalıdır. Workflow bu oturumda uzakta çalıştırılmadı.

## Kaynak ve maliyet sınırları

| Kaynak | Varsayılan | Sınır aşımındaki davranış |
|---|---:|---|
| API + dosya HTTP istekleri | 100.000 / 24 saatlik sayaç dönemi | 429, `Retry-After` |
| API/dosya IP istekleri | 1.200 / dakika | 429 |
| Oturum açmış kullanıcı | 180 API isteği / dakika | 429 |
| GET/HEAD yanıt ve dosya aktarımı | 1 GiB / sayaç dönemi | Gövde iletilmeden 429 |
| Yükleme denemeleri | 50 MiB / kullanıcı, toplam 500 MiB / dönem | 429; başarısız denemeler de sayılır |
| Kalıcı yüklenen dosyalar | 5 GiB | Yeni dosya yazılmadan 507 |
| İstek gövdesi | 10 MiB | 413 |
| İlan fotoğrafı | Varsayılan 8 MiB, 20 fotoğraf | 400 |
| Aktif/taslak ilan | Kullanıcı başına 20 | 409 |
| Favoriler | Kullanıcı başına 500 | 409; eklenmiş favoriyi tekrar eklemek geçerli |
| Doğrulama belgeleri | Başvuru başına 6 | 409; aynı tür belge değiştirilebilir |
| WebSocket | Kullanıcı başına toplam 3 bağlantı, 60 küçük mesaj/dakika | Bağlantı kapatılır |
| Şifre sıfırlama e-postası | Toplam 100/dönem, alıcı başına 3/saat | İleti gönderilmeden 429 |

Sayaç süreleri ilk kullanımdan başlayan sabit dönemlerdir, takvim günü değildir. Redis kesilirse kota gereken işlemler 503 döner; sınırsız kullanıma geçmez. Redis AOF kalıcıdır ve `noeviction` kullanır; kota anahtarları bellek baskısında atılmaz. Redis verisini silmek veya yedeksiz kaybetmek sayaçları sıfırlar; işletim erişimi korunmalıdır.

GET/HEAD bütçesi `Content-Length` bulunan API/dosya yanıtlarını kapsar; değişiklik işlemlerinin tamamlanmış sonucunu saklamamak için POST/PUT yanıtlarını engellemez. Web statik dosyaları, TLS/HTTP başlıkları, bağlantı girişimleri, Redis/WebSocket trafiği ve sağlayıcının tüm trafik ölçümü bu sayaçla birebir aynı değildir. Bu yüzden sağlayıcıdaki harcama engeli veya sabit ücretli mevcut bağlantı da gereklidir. Kota dolduğunda erişimin kesilmesi tasarımsal bir maliyet/erişilebilirlik tercihidir.

Compose CPU, bellek, bağlantı ve günlük boyutu sınırlarını sabitler. Otomatik büyüyen servis yoktur. Varsayılan bütçeler binlerce yoğun aktif kullanıcının sınırsız erişimi anlamına gelmez. Ölçülen trafik ve mevcut bütçeye göre operatör ayarlamalıdır.

## Yönetici ikinci faktörü ve belge saklama

`production_env.py` artık ayrı `MFA_ENCRYPTION_KEY` üretir. Mevcut kurulumda bu yeni değişken olmadan production başlamaz. Anahtarı uygulama env dosyasıyla birlikte ayrı güvenli cihazda saklayın; veritabanı yedeğinin tek başına kayıp MFA anahtarını geri getirmeyeceğini unutmayın.

```bash
scripts/production.sh admin
scripts/production.sh mfa
```

İkinci komut hesap şifresini ister, yerel terminalde doğrulayıcı uygulamaya eklenecek anahtarı gösterir ve ilk kodu doğrular. Anahtarı uzak QR hizmetine göndermeyin. Yeniden kurulum mevcut kodu da ister; kayıp cihaz için sunucu operatörünün kimlik kontrolüyle yürüttüğü kurtarma prosedürü gerekir. Üretimde MFA kurulmamış admin/moderatör oturum açamaz. Kurulum/değişiklik eski oturumları geçersiz kılar. Web yönetici girişinde ve mobil girişin iki adımlı doğrulama bölümünde kod alanı vardır.

Yalnızca JPEG/PNG yüklenir; metadata temizlenerek yeniden kodlanır. Önceden yüklenen PDF'ler indirmeye kapatılır ve yeni görsel istenir. `VERIFICATION_RETENTION_DAYS=30` varsayılanıyla **incelemesi bitmiş** belgeler süre sonunda saatlik bakımda silinir; bekleyen başvurular korunur. Depolama silme hatasında kayıt/kota korunup tekrar denenir. Saklama süresi işletme tarafından onaylanmalıdır; bu ayar tek başına hukuki uygunluk beyanı değildir.

## SMTP erişimi

Varsayılan API ağı internete çıkamaz. Dahili SMTP için mevcut ağa bağlı TLS relay kullanın. Mevcut dış SMTP hesabınız varsa isteğe bağlı ağ dosyasını kullanın:

```bash
export PRODUCTION_COMPOSE_OVERRIDE="$PWD/infra/compose.smtp.yml"
scripts/production.sh deploy
```

Bu ek dosya yalnızca API için dış ağ erişimi açar. `SMTP_HOST`, `SMTP_PORT`, `SMTP_SENDER`, `SMTP_USERNAME`, `SMTP_PASSWORD` değerleri mevcut hesabınıza ait olmalıdır. Üretim STARTTLS ve gönderici ister. Hiçbir SMTP hesabı veya ücretli hizmet otomatik açılmaz; günlük/alıcı limitleri yürürlükte kalır. Boş SMTP ayarıyla şifre sıfırlama kullanılamaz.

## Şifreli yedek ve geri dönüş

Python 3.12+ ve Docker Compose kullanın. İmaj age aracını içerir; hosta ayrıca şifreleme paketi kurmak gerekmez.

```bash
scripts/production.sh backup-key --identity /guvenli/ayri-disk/market.agekey
scripts/production.sh backup --recipient 'age1...public-key...' --snapshot backups/2026-09-15.tar.age
scripts/production.sh restore-check --identity /guvenli/ayri-disk/market.agekey --snapshot backups/2026-09-15.tar.age
```

`backup-key` dosyayı değiştirmez; mevcutsa reddeder. Public alıcı `.pub` dosyasındadır; özel kimliği sunucudan ayrı mevcut cihazda tutun. `backup`, API/bakım/Redis yazıcılarını kısa süre durdurur, PostgreSQL dump + dosyalar + Redis kalıcılığını birlikte alır, yalnızca durdurduğu servisleri yeniden başlatır ve age ile şifreler. Ara açık veriler 0700 dizinde tutulup temizlenir. Disk ön kontrolü, eşzamanlı yedek kilidi ve mevcut yedeğin üzerine yazmama koruması vardır. Yedek komutu migration çalıştırmaz.

`restore-check` canlı veritabanına dokunmaz: şifre çözümünü tamamen doğrular, ayrı PostgreSQL'e dump'ı yükler, bütün dosya referanslarını/boyutlarını kontrol eder ve ayrı Redis'i kayıtlı AOF ile açar. Sonunda deneme konteynerlerini kaldırır. Bozulmuş şifreli arşiv, veritabanı kurulmadan reddedilir. **15 Eylül yerel üretim denemesinde SQL + 10 dosya referansı + 8 Redis kaydı geri yüklendi; bozuk yedek reddedildi.** Bu, uzak yedek cihazının veya gerçek sunucunun sınandığı anlamına gelmez.

Felaket kurtarmada doğrulanmış arşivi yeni/boş bir kurulumda açın; dump'ı yeni PostgreSQL'e yükleyin, uploads dosyalarını 10001 kullanıcı izinleriyle ve Redis AOF dizinini Redis volume'una taşıyın. Eşleşen uygulama sürümünü, JWT/MFA env anahtarlarını ve Caddy sertifika volume'larını ayrı güvenli kopyadan alın. Redis'i boş başlatmak kullanım sayaçlarını sıfırlar. Var olan veritabanına hazırlıksız `--clean` uygulamayın. Aynı diskte tek kopya gerçek felaket yedeği değildir.

## Ücretsiz yerel izleme ve zamanlama

`infra/systemd/` servis ve timer dosyaları Linux sunucuda `/opt/trustmarket` kurulumunu esas alır. `infra/.env.operations` dosyasına `MONITOR_URL=https://alan-adiniz/ready` ve `BACKUP_RECIPIENT=age1...` public değerini yazın; dosya izinlerini 0600 yapın. Yolu farklıysa service dosyalarını uyarlayın. Hedef sunucu erişimi olmadan timerlar yüklenmiş/etkin sayılmaz.

```bash
sudo install -m 0644 infra/systemd/trustmarket-* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now trustmarket-monitor.timer trustmarket-backup.timer
journalctl -u trustmarket-monitor.service -u trustmarket-backup.service
```

Monitör dakikada bir HTTPS hazırlığı, konteyner sağlığı, en az 2 GiB boş alan ve 36 saatten yeni yedeği kontrol eder; hata JSON'u ve sıfırdan farklı çıkış verir. Bakım heartbeat'i ve web healthcheck'i Compose'a dahildir. Günlük yedek 03:30'da alınır; eski yedekler kendiliğinden silinmez ve ayrı cihaza kopyalama kullanıcı sorumluluğundadır. Harici alarm alıcısı henüz tanımlanmadı; yalnızca yerel journal kontrolü sunucunun tamamen kapanmasını dışarıdan haber vermez.

## Yayın kabul kontrolü

1. `https://alan-adiniz/ready` yanıtı başarılı; TLS sertifikası geçerli; HTTP HTTPS'e yönleniyor.
2. Gerçek e-posta ile kayıt, şifre sıfırlama, eski parolanın/oturumun iptali ve yeni giriş çalışıyor.
3. Yeni üye belge yükler; yetkili yönetici belgeleri inceleyip onaylar; sıradan üye başka kullanıcının belgesine erişemez.
4. Altı fotoğrafla ilan yayınlama, arama, favori, mesaj, randevu ve satıldı işaretleme akışları çalışır.
5. WebSocket iki çalışan arasında teslim edilir; bağlantı yoksa mesajlar yeniden sorguyla alınır.
6. Küçük test kotasıyla 429/507 davranışını doğrulayıp normal bütçeyi geri yükleyin.
7. Gerçek sunucuda TLS, görseller, mobil ağ ve kalıcı yazma yükünü içeren uzun yük testi; CPU/RAM, disk, hata oranı ve p95/p99 ölçümü yapılır.
8. Uzak yedekten geri dönüş prova edilir; yetkili ekip ve disk doluluğu/503 alarmının sorumlusu belirlenir.

## Mobil yayın

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://ilan.ornek.com/api --dart-define=LOG_NETWORK=false
flutter build ipa --release --dart-define=API_BASE_URL=https://ilan.ornek.com/api --dart-define=LOG_NETWORK=false
```

Komutlar örnektir; Android/iOS imzalama anahtarları, bundle kimlikleri ve mağaza hesapları bu oturumda yapılandırılmadı. iOS IPA için Apple imzalama yetkisi gerekir. Release uygulama HTTPS adresi olmadan başlamayı reddeder ve ağ gövdelerini/parolaları günlüğe yazmaz. Simülatör çalışması mağaza yayını değildir.
