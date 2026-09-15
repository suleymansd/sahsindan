# Vercel web yayını — 15 Eylül 2026

**Web adresi: https://sahsindan.vercel.app**

Vercel `sahsindan` projesi, mevcut `süleyman's projects` hesabında yayımlandı.
Dağıtım `dpl_CbqQrvmwrMB4mg7CNp8MeLYW6bFj`, durumu `READY`, hedefi `production`.
Yayımlanan uygulama commit'i `2301475`.

## Kullanılabilirlik

Ana sayfa, yardım, giriş ve üyelik ekranları HTTPS üzerinden erişilebilir.
Backend henüz canlı olmadığı için tanıtım bildirimi görünür; giriş, üyelik ve
parola sıfırlama gönderim düğmeleri devre dışıdır. API adresi olmayan üretim
derlemesi `localhost` adresine veya aynı origin'de var olmayan `/api` yoluna
istek göndermez. Giriş/ilan işlemleri çalışıyormuş gibi sunulmaz.

Yerel geliştirme için API fallback'i korunur. `NEXT_PUBLIC_API_URL` açıkça
tanımlanan mevcut backend'li ortamların davranışı korunur. Yayına yalnızca
`apps/web` gönderildi; `.env.local`, OIDC oturum bilgisi, testler, API kaynakları
ve yerel veritabanları gönderilmedi. npm kilidi kullanılır. GitHub otomatik
dağıtımı, ücretli eklenti veya plan yükseltmesi yapılmadı.

Hesap Hobby plandadır. Vercel'in Hobby planı kişisel ve ticari olmayan kullanımla
sınırlıdır; bu tanıtım yayını, ticari kullanım için plan uygunluğunun çözüldüğü
anlamına gelmez. Ticari açılış öncesi bu koşul ele alınmalıdır.
[Vercel Hobby koşulları](https://vercel.com/docs/plans/hobby).

## Doğrulama

- 8 web birim testi geçti; 3 yeni test API'siz üretimde veri gönderilmemesi,
  açık API adresi ve geliştirme fallback'i için eklendi.
- Gerçek yerel backend ile 12 mevcut Chromium E2E testi geçti.
- Backend'siz yerel üretim derlemesinde 2 tanıtım/mobil testi geçti.
- Aynı 2 test **canlı Vercel adresinde** geçti: tanıtım bildirimi, kapalı hesap
  işlemleri, sıfır API isteği ve 390 px ekranda yatay taşma olmaması.
- `/`, `/giris/kullanici`, `/uye-ol`, `/yardim` dışarıdan HTTPS 200 verdi.
- Vercel üretim derlemesi ve tip kontrolü geçti. Mevcut `<img>` performans
  önerileri ve bağımlılık deprecation uyarıları engelleyici hata değildir.

Canlı yayın kontrollerini tekrar çalıştırmak için `apps/web` içinde:

```sh
PUBLICATION_BASE_URL=https://sahsindan.vercel.app \
  npx --no-install playwright test --config playwright.preview.config.ts
```

## Backend bağlantısı için kalanlar

[Railway planında](RAILWAY_TR.md) artık yalnızca API/PostgreSQL/Redis vardır;
ikinci bir web servisi oluşturulmaz. Railway servisleri hâlâ başlatılmadı.
Backend yayını, API adresi, domainler arası HttpOnly oturum çerezi/CORS ve
WebSocket bağlantısı gerçek tarayıcıda doğrulanmalıdır. Mevcut backend refresh
çerezi `SameSite=Lax` kullanır; farklı Vercel/Railway domainlerine yalnızca URL
yazarak kalıcı oturumun çalışacağı varsayılmamalıdır.

Bu kontrollerden sonra hesap işlemleri etkinleştirilip web yeniden derlenir.
Ardından canlı backend'e bağlı yeni IPA ve TestFlight yüklemesi tamamlanabilir.
SMTP, yönetici MFA ve yedekleme eksikleri önceki raporlarda geçerliliğini korur.

Makine okunabilir kayıt: [vercel-publication-2026-09-15.json](validation/vercel-publication-2026-09-15.json).
