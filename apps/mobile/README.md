# Şahsından mobil

Flutter iOS/Android istemcisi. iOS paket kimliği `com.sahsindan.app`, mevcut Apple ekibi `475GX393HD`.

Yerel geliştirme (önce backend'i başlatın):

```sh
cp -n .env.example .env
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api --dart-define=LOG_NETWORK=false
flutter test
```

Android emülatöründe `127.0.0.1` yerine `10.0.2.2` kullanın. `.env` uygulama paketine dahil olur: yalnızca herkese açık `API_BASE_URL` ve `LOG_NETWORK` ayarlarını içermelidir. Sunucu anahtarı/parola koymayın. Release sürümü API adresini yalnızca `--dart-define` ile alır ve HTTPS zorunludur.

```sh
flutter test integration_test/investor_demo_test.dart -d IOS_SIMULATOR_ID \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080/api --dart-define=LOG_NETWORK=false
```

Native E2E yalnızca yerel backend'deki mevcut `verified@test.com` demo hesabını kullanır. Boş form, yanlış parola, başarılı giriş ve gerçek ilan detayını kapsar; prod sunucusunda çalıştırılmaz. Simülatördeki uygulamanın oturum anahtarlarını test öncesi/sonrası temizler.

Unicode klasör yolunda analyzer JSON hatası için repo kökünde `python3 scripts/analyze_mobile.py --flutter /path/to/flutter` kullanın.

IPA hazırlığı ve mevcut yayın engelleri: [TestFlight kılavuzu](../../docs/TESTFLIGHT_TR.md).
