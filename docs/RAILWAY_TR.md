# Railway — düşük kullanım profili, 15 Eylül 2026

**Durum: proje açıldı, plan doğrulandı; canlı servis veya disk oluşturulmadı.**
Proje: [sahsindan](https://railway.com/project/87da6148-dba9-4e45-b6cf-f42e7819b820).
Kullanıcının önceki sıfır bütçe talebi korunuyor. Bu yapı ücretsiz çalışma veya
belirli bir aylık fatura garantisi vermez. Bütçe tanımlanmaması ücretli kaynakları
sınırsız açma izni olarak kabul edilmedi.

## Hazırlanan yapı

Web yayını Vercel'e ayrıldı. Railway planından web servisi çıkarıldı; aynı web
uygulaması için ikinci bir ücretli çalışma süreci açılmayacak.

Tek ortam ve her serviste tek replika; otomatik ölçeklendirme yok. Yeni Railway
projeleri için güncel `.railway/railway.ts` kullanılır. SDK `3.11.0` ve bağımlılık
kilidi kaydedildi. Plan mevcut başka projeleri değiştirmez.

| Servis | Bellek üst sınırı | CPU üst sınırı | Kalıcı disk |
|---|---:|---:|---:|
| API + bakım işlemi | 512 MiB | 0,5 | 1.024 MB |
| PostgreSQL 16 | 256 MiB | 0,5 | 1.024 MB |
| Redis 7.4.11 | 128 MiB | 0,25 | 512 MB |

Bu değerler tahsis edilen veya sürekli tüketilen miktarlar değil, kaynak
sınırlarıdır. Yeni imaj dağıtımının kaynak tüketimi ayrıca ölçülmelidir. Profil
küçük yatırımcı demosuna yöneliktir; yüksek erişilebilirlik veya binlerce eşzamanlı
kullanıcı kapasitesi doğrulanmış değildir. Disk kullanan tek replikanın yeniden
dağıtımında kısa kesinti olabilir.

API bir işçiyle çalışır; bakım aynı konteynerde, aynı diskte çalışır. Railway diski
root sahibiyle geldiği için başlangıçta yalnızca disk kökünün sahipliği düzeltilir,
ardından süreçler UID/GID `10001` ile çalışır. Disk yoksa veya yazılamıyorsa servis
açılmaz. Alt süreçlerden biri durursa diğeri de sonlandırılır ve konteyner hata
verir. PostgreSQL/Redis erişimi `/ready` üzerinden kontrol edilir.

PostgreSQL 30 bağlantıyla, API süreç başına 2 bağlantı + 1 ek bağlantıyla
sınırlandı. Redis 32 MB veride `noeviction` ve kalıcı AOF kullanır; dolduğunda
yetkilendirme/kota kayıtlarını sessizce silmez. API ve bakım sürekli gerektiği
için uyutulmaz. Veritabanlarına public TCP proxy açılmaz.

Uygulama profili: günlük 10.000 API isteği, ölçülen API yanıtlarında günlük
50 MiB, toplam 512 MiB yükleme alanı, günlük toplam 50 MiB / kullanıcı başına
10 MiB yükleme, kullanıcı başına 5 aktif ilan, 100 favori ve 2 WebSocket.
Bu limitler tüm sağlayıcı trafiğini, derlemeleri veya aylık faturayı sınırlamaz.
Özellikle statik dosya trafiği günlük API yanıt ölçümünün tamamına dahil değildir.
Önceki genel üretim varsayılanları değiştirilmedi; bu kotalar Railway profiline özeldir.

## Yayın için kalan adımlar

Ücretli çalıştırma izni olmadan aşağıdaki apply/deploy adımları yapılmaz.

1. Yalnızca Şahsından ortamında paylaşılan `DATABASE_PASSWORD`, `REDIS_PASSWORD`,
   farklı `JWT_SECRET`/`JWT_REFRESH_SECRET` ve geçerli Fernet `MFA_ENCRYPTION_KEY`
   oluşturulur. İlk dört sır için en az 32 karakter URL-safe rastgele değer
   kullanılır. Sırlar kaynak dosyalara, mobil `.env` dosyasına veya sohbet çıktısına konmaz.
2. Plan yeniden incelenip uygulanır. API/web için kaynak kod otomatik bağlanmaz.
   Railway HTTPS alan adları oluşturulup `PUBLIC_API_URL` ve `PUBLIC_WEB_URL`
   paylaşılan değişkenlerine origin olarak, son `/` olmadan yazılır. API adresine
   bu değişkende `/api` eklenmez. Eksik origin ile uygulama dağıtılmaz.
3. PostgreSQL ve Redis hazır olunca repo kökünden API yüklenir:
   `railway up services/api --path-as-root --service api --environment production`.
   `alembic upgrade head` pre-deploy adımında çalışır. Pre-deploy diski göremediği
   için dosya uzlaştırması bu adımda çalıştırılmaz; bakım başlangıçta yapar.
4. Web Vercel üzerinden yayımlanır. Backend bağlanırken gerçek domain üzerinde
   CORS, HttpOnly refresh çerezi ve oturum yenileme doğrulanır; yalnızca API
   adresini yazmak tam entegrasyon kanıtı değildir. API bağlantısı olmadan web
   tanıtım durumunu gösterir ve hesap işlemlerini başlatmaz.
5. Gerçek yönetici ve MFA kurulumu, kontrollü yatırımcı hesapları ve gerçek HTTPS
   üzerinde giriş/ilan/fotoğraf/mesajlaşma akışları doğrulanır. Yerel test
   kullanıcıları veya bilinen demo şifreleri internete taşınmaz.
6. Mevcut `scripts/ios_release.py` ile canlı API kontrol edilip yeni IPA üretilir.
   TestFlight yüklemesi ve Apple beta incelemesi ayrıca tamamlanır.

SMTP henüz bağlı değildir: parola sıfırlama e-postası yayına hazır sayılmaz.
Mevcut reset akışı servis yokken kontrollü hata verir. Manuel doğrulama ve
yönetici MFA zorunluluğu korunur; ücretli AI/SMS/KYC açılmaz. Railway ücretli yedek
eklentisi etkinleştirilmedi; dışarıda şifreli yedek ve geri yükleme doğrulaması
gerçek kullanıcı verisi kabul etmeden önce tamamlanmalıdır.

## Doğrulama

- Güncel Railway planı: 3 servis + 3 disk ekleme niyeti; sıfır değiştirme/silme,
  tanı hatası yok. **Apply çalıştırılmadı.**
- Gerçek geçici PostgreSQL + Redis üzerinde tüm backend süiti: **145 geçti**.
  Bunun 7 testi Railway başlangıcı, disk denetimi, yetki düşürme, süreç hatası
  ve SIGTERM kapanışı için yeni regresyonlardır.
- Web birim testleri: **5 geçti**.
- API/web Docker imajları derlendi. Web 256 MiB / 0,5 CPU sınırında HTTP 200
  verdi; ayrı API build arg değerinin tarayıcı paketine girdiği doğrulandı.
- Yeni Railway SDK bağımlılık denetimi: bilinen güvenlik açığı **0**.
- Yerel Docker üzerinde planın CPU/bellek sınırlarıyla PostgreSQL/Redis/API
  başlangıcı, yetkisiz istekte 401, root olmayan ana süreç, yeniden başlatmada
  dosya kalıcılığı ve bakım sonlanınca API'nin de kapanması doğrulandı.
- Önceki mobil/E2E sonuçları [TestFlight raporunda](TESTFLIGHT_TR.md) tarihlidir;
  bu hazırlık yeni bir canlı E2E veya kapasite testi olarak sunulmaz.

Makine okunabilir kayıt: [railway-readiness-2026-09-15.json](validation/railway-readiness-2026-09-15.json).

Kaynaklar: [Railway IaC](https://docs.railway.com/infrastructure-as-code),
[IaC alanları](https://docs.railway.com/infrastructure-as-code/reference),
[kalıcı disk](https://docs.railway.com/volumes/reference),
[pre-deploy](https://docs.railway.com/deployments/pre-deploy-command),
[maliyet kontrolleri](https://docs.railway.com/pricing/cost-control).
