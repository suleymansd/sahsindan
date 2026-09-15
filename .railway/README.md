# Şahsından Railway yapılandırması

Hedef proje: `87da6148-dba9-4e45-b6cf-f42e7819b820`, ortam: `production`.
Başka bir proje/ortamda plan çalıştırılması engellenir.

Bu dosyalar **canlı dağıtım yapıldığı anlamına gelmez**. Proje boş olarak açıldı;
ücret oluşturmamak için servis ve disk planı uygulanmadı.

```sh
npm ci --prefix .railway --ignore-scripts --no-audit --no-fund
railway config plan
```

`railway config apply` ücretli kaynak başlatır. Otomatik apply, GitHub otomatik
deploy ve ücretli Railway Agent iş akışı eklenmedi. Çalışma alanı harcama limiti
bu projeye özel değildir; diğer projeleri de durdurabileceğinden değiştirilmedi.

Servisler, sırların sağlanması, yayın sırası ve doğrulama:
[Railway kurulum notları](../docs/RAILWAY_TR.md).
