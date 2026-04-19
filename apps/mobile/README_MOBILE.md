# TrustMarket Mobile (şahsından.com)

Flutter + Riverpod + go_router + Dio istemcisi.

Bu repo iki sekilde calisir:

1) Docker + Nginx (recommended): API proxy `http://localhost:8080/api`
2) Docker'siz (SQLite + Uvicorn): API dogrudan `http://localhost:8080` (prefix yok)

## Gereksinimler

- Flutter (son stable)
- Android Studio / Xcode
- Docker + Docker Compose (backend icin)

## Backend'i calistir

Repo root (Docker + Nginx):

```bash
make dev
# veya
./infra/dev.sh
```

- API: `http://localhost:8080/api`
- Storage proxy: `http://localhost:8080/storage/...`

## Docker'siz (SQLite) + Flutter Web (Tek Komut)

Docker calismiyorsa veya hizli test istiyorsan:

```bash
./scripts/dev_mobile_web.sh
```

- API: `http://127.0.0.1:8080`
- Mobile web: `http://127.0.0.1:3005/`

## Mobile'i calistir

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Base URL (Env)

`apps/mobile/.env` icinden okunur. Default `.env` docker-free (prefix yok) olacak sekilde ayarli.

Docker-free (services/api/scripts/dev_local.sh):

- iOS Simulator / Web: `http://localhost:8080`
- Android Emulator: `http://10.0.2.2:8080`

Nginx proxy ile (make dev / infra):

- iOS Simulator / Web: `http://localhost:8080/api`
- Android Emulator: `http://10.0.2.2:8080/api`

Ornek:

```env
API_BASE_URL=http://10.0.2.2:8080
LOG_NETWORK=true
```

Alternatif olarak build-time:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Demo Hesaplar (seed)

Backend seed ile:

- Admin: `admin@trustmarket.local` / `Admin123!`
- Moderator: `mod@trustmarket.local` / `Mod123!`
- Verified User: `user1@trustmarket.local` / `User123!`
- Verified Seller: `seller1@trustmarket.local` / `User123!`
- Verified Demo: `verified@test.com` / `Test1234!`
- Pending: `pending@trustmarket.local` / `User123!`

## Notlar

- Auth: Access + refresh token `flutter_secure_storage` ile yonetilir (cookie jar yok). `X-Client: mobile` header'i ile backend refresh token'i response body'de doner.
- 401 -> refresh -> retry akisi Dio interceptor ile otomatik; refresh basarisizsa otomatik logout.
- Upload: verification ve listing photo upload multipart.
- Browse (ilan liste/detay) serbest; sadece islemler (ilan verme, mesaj, randevu, rapor, favori) dogrulama ister.

## HTTP (Dev)

Dev ortaminda `http://localhost` kullandigimiz icin:

- Android: `android:usesCleartextTraffic="true"` acik.
- iOS: `NSAllowsArbitraryLoads=true` acik (ATS).

Prod icin HTTPS kullanip bu ayarlari daraltmanizi oneririm.
