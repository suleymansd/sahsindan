/**
 * TrustMarket - Turkish Localization Strings
 * Tüm UI metinleri burada merkezi olarak yönetilir
 */

export const strings = {
  // ========== COMMON ==========
  common: {
    appName: 'TrustMarket',
    loading: 'Yükleniyor...',
    error: 'Bir hata oluştu',
    success: 'Başarılı',
    cancel: 'İptal',
    save: 'Kaydet',
    delete: 'Sil',
    edit: 'Düzenle',
    close: 'Kapat',
    back: 'Geri',
    next: 'İleri',
    submit: 'Gönder',
    confirm: 'Onayla',
    search: 'Ara',
    filter: 'Filtrele',
    sort: 'Sırala',
    retry: 'Tekrar Dene',
    tryAgain: 'Tekrar deneyin',
    viewAll: 'Tümünü Gör',
    seeMore: 'Daha Fazla',
    showLess: 'Daha Az',
    optional: 'İsteğe bağlı',
    required: 'Zorunlu',
    yes: 'Evet',
    no: 'Hayır',
  },

  // ========== AUTH ==========
  auth: {
    login: 'Giriş Yap',
    register: 'Üye Ol',
    logout: 'Çıkış Yap',
    email: 'E-posta',
    password: 'Şifre',
    passwordConfirm: 'Şifre Tekrar',
    forgotPassword: 'Şifremi Unuttum',
    resetPassword: 'Şifre Sıfırla',
    rememberMe: 'Beni Hatırla',

    // Placeholders
    emailPlaceholder: 'ornek@email.com',
    passwordPlaceholder: 'En az 8 karakter',

    // Messages
    loginSuccess: 'Giriş başarılı',
    loginError: 'E-posta veya şifre hatalı',
    registerSuccess: 'Kayıt başarılı',
    logoutSuccess: 'Çıkış yapıldı',
    passwordResetSent: 'Şifre sıfırlama bağlantısı e-postanıza gönderildi',

    // Validation
    emailRequired: 'E-posta adresi gerekli',
    emailInvalid: 'Geçerli bir e-posta adresi girin',
    passwordRequired: 'Şifre gerekli',
    passwordTooShort: 'Şifre en az 8 karakter olmalı',
    passwordMismatch: 'Şifreler eşleşmiyor',

    // Links
    noAccount: 'Hesabınız yok mu?',
    hasAccount: 'Zaten hesabınız var mı?',
  },

  // ========== NAVIGATION ==========
  nav: {
    home: 'Ana Sayfa',
    listings: 'İlanlar',
    myListings: 'İlanlarım',
    favorites: 'Favoriler',
    messages: 'Mesajlar',
    appointments: 'Randevular',
    profile: 'Profil',
    admin: 'Yönetim',
    createListing: 'İlan Ver',
  },

  // ========== LANDING PAGE ==========
  landing: {
    hero: {
      title: 'Güvenli Araç Alım-Satımı',
      subtitle: 'Sahte ilan yok, cevapsız satıcı yok. Sadece doğrulanmış kullanıcılar.',
      ctaPrimary: 'Üye Ol',
      ctaSecondary: 'Nasıl Çalışır?',
    },
    features: {
      title: 'Neden TrustMarket?',
      verification: {
        title: 'Doğrulanmış Kullanıcılar',
        description: 'Her kullanıcı kimlik doğrulamasından geçer',
      },
      noStale: {
        title: 'Güncel İlanlar',
        description: 'Eski ilanlar otomatik arşivlenir',
      },
      appointments: {
        title: 'Randevu Sistemi',
        description: 'Zaman kaybetmeden organize görüşmeler',
      },
      trustScore: {
        title: 'Güven Puanı',
        description: 'Kullanıcı geçmişi şeffaf ve güvenilir',
      },
    },
    faq: {
      title: 'Sıkça Sorulan Sorular',
    },
  },

  // ========== LISTINGS ==========
  listings: {
    title: 'İlanlar',
    subtitle: 'Doğrulanmış ilanları filtreleyin, güvenle karşılaştırın.',
    search: 'Arama',
    searchPlaceholder: 'Marka, model, ilan no, il/ilçe ara…',
    emptyState: 'Henüz ilan yok',
    emptyStateDesc: 'İlk ilanı siz verin!',
    applyFilters: 'Filtreleri Uygula',
    clearFilters: 'Filtreleri Temizle',

    // Filters
    filters: 'Filtreler',
    priceRange: 'Fiyat Aralığı',
    yearRange: 'Model Yılı',
    kmRange: 'Kilometre',
    transmission: 'Vites',
    fuelType: 'Yakıt Tipi',
    city: 'Şehir',
    district: 'İlçe',

    // Transmission types
    transmissionManual: 'Manuel',
    transmissionAutomatic: 'Otomatik',
    transmissionSemiAutomatic: 'Yarı Otomatik',

    // Fuel types
    fuelPetrol: 'Benzin',
    fuelDiesel: 'Dizel',
    fuelLPG: 'LPG',
    fuelElectric: 'Elektrik',
    fuelHybrid: 'Hibrit',

    // Status
    statusDraft: 'Taslak',
    statusPublished: 'Yayında',
    statusSold: 'Satıldı',
    statusArchived: 'Arşivlendi',
    statusRejected: 'Reddedildi',
    statusNeedsConfirmation: 'Onay Bekliyor',

    // Actions
    markAsSold: 'Satıldı Olarak İşaretle',
    confirmActive: 'İlan Hala Aktif',
    publish: 'Yayınla',
    unpublish: 'Yayından Kaldır',
    editListing: 'İlanı Düzenle',
    deleteListing: 'İlanı Sil',

    // Card info
    verified: 'Doğrulanmış',
    trustScore: 'Güven Puanı',
    responseTime: 'Yanıt Süresi',
    responseTimeFast: 'Hızlı',
    responseTimeAverage: 'Orta',
    responseTimeSlow: 'Yavaş',
    calculatingResponseTime: 'Yanıt süresi oluşuyor',

    // Favorites
    addToFavorites: 'Favorilere Ekle',
    removeFromFavorites: 'Favorilerden Çıkar',
    addedToFavorites: 'Favorilere eklendi',
    removedFromFavorites: 'Favorilerden çıkarıldı',
    favoriteLoginRequired: 'Favoriler için giriş yapmalısınız',

    // Access
    loginRequired: 'Giriş Gerekli',
    loginRequiredDescription: 'İlanları görüntülemek için giriş yapmalısınız.',
    verificationRequired: 'Doğrulama Gerekli',
    verificationRequiredDescription: 'İlanlara erişmek için hesabınızı doğrulayın.',
  },

  // ========== LISTING DETAIL ==========
  listingDetail: {
    details: 'İlan Detayları',
    sellerInfo: 'Satıcı Bilgileri',
    contactSeller: 'Satıcıyla İletişime Geç',
    sendMessage: 'Mesaj Gönder',
    requestAppointment: 'Randevu İste',
    addToFavorites: 'Favorilere Ekle',
    removeFromFavorites: 'Favorilerden Çıkar',
    share: 'Paylaş',
    report: 'Şikayet Et',

    // Car details
    brand: 'Marka',
    model: 'Model',
    year: 'Yıl',
    mileage: 'Kilometre',
    transmission: 'Vites',
    fuelType: 'Yakıt',
    engineSize: 'Motor Hacmi',
    enginePower: 'Motor Gücü',
    color: 'Renk',
    bodyType: 'Kasa Tipi',

    // Additional info
    description: 'Açıklama',
    features: 'Özellikler',
    location: 'Konum',
    postedAt: 'Yayın Tarihi',
    updatedAt: 'Güncellenme Tarihi',
    vehicleDetails: 'Araç Detayları',
    price: 'Fiyat',

    // States
    verifiedSeller: 'Doğrulanmış Satıcı',
    awaitingConfirmation: 'Satıcı onayı bekleniyor',
    inactiveListing: 'İlan Aktif Değil',
    inactiveListingDescription: 'Bu ilan satıldı, arşivlendi veya reddedildi. Mesaj ve randevu kapalı.',
    listingUpdated: 'İlan güncellendi',

    // Auth
    loginRequired: 'Giriş Gerekli',
    loginRequiredDescription: 'İlan detaylarını görmek için giriş yapmalısınız',
    loadingListing: 'İlan yükleniyor...',
  },

  // ========== CREATE/EDIT LISTING ==========
  createListing: {
    title: 'İlan Ver',
    editTitle: 'İlanı Düzenle',

    // Steps
    step1: 'Araç Bilgileri',
    step2: 'Fotoğraflar',
    step3: 'Açıklama',
    step4: 'Önizleme',

    // Form labels
    brand: 'Marka',
    model: 'Model',
    year: 'Model Yılı',
    mileage: 'Kilometre',
    price: 'Fiyat',
    transmission: 'Vites Tipi',
    fuelType: 'Yakıt Tipi',
    engineSize: 'Motor Hacmi (cc)',
    enginePower: 'Motor Gücü (HP)',
    color: 'Renk',
    city: 'Şehir',
    district: 'İlçe',
    description: 'Açıklama',

    // Photo upload
    uploadPhotos: 'Fotoğraf Yükle',
    minPhotos: 'En az 6 fotoğraf gerekli',
    maxPhotos: 'En fazla 20 fotoğraf yüklenebilir',
    dragAndDrop: 'Sürükle bırak veya tıklayarak seç',
    photoSizeLimit: 'Maksimum dosya boyutu: 8MB',
    photoFormats: 'Desteklenen formatlar: JPG, PNG',
    reorderPhotos: 'Fotoğrafları sıralamak için sürükleyin',
    deletePhoto: 'Fotoğrafı Sil',

    // Validation
    brandRequired: 'Marka seçin',
    modelRequired: 'Model seçin',
    yearRequired: 'Model yılı gerekli',
    priceRequired: 'Fiyat gerekli',
    minPhotosRequired: 'En az 6 fotoğraf yükleyin',

    // Actions
    saveDraft: 'Taslak Olarak Kaydet',
    publishListing: 'İlanı Yayınla',

    // Messages
    draftSaved: 'Taslak kaydedildi',
    listingPublished: 'İlan yayınlandı',
    listingUpdated: 'İlan güncellendi',
  },

  // ========== FAVORITES ==========
  favorites: {
    title: 'Favoriler',
    emptyState: 'Favori ilanınız yok',
    emptyStateDesc: 'Beğendiğiniz ilanları favorilere ekleyebilirsiniz',
    removed: 'Favorilerden çıkarıldı',
    added: 'Favorilere eklendi',
  },

  // ========== MESSAGES ==========
  messages: {
    title: 'Mesajlar',
    emptyState: 'Henüz mesajınız yok',
    emptyStateDesc: 'Satıcılarla iletişime geçtiğinizde mesajlar burada görünür',

    newMessage: 'Yeni Mesaj',
    sendMessage: 'Mesaj Gönder',
    typeMessage: 'Mesajınızı yazın...',

    messageSent: 'Mesaj gönderildi',
    markAsRead: 'Okundu Olarak İşaretle',

    // Thread info
    about: 'Hakkında',
    listing: 'İlan',
  },

  // ========== APPOINTMENTS ==========
  appointments: {
    title: 'Randevular',
    emptyState: 'Henüz randevunuz yok',
    emptyStateDesc: 'İlan sahipleriyle randevu oluşturduğunuzda burada görünür',

    // Create
    requestAppointment: 'Randevu İste',
    selectDateTime: 'Tarih ve Saat Seçin',
    selectDate: 'Tarih Seçin',
    selectTime: 'Saat Seçin',
    addNote: 'Not Ekle (İsteğe bağlı)',
    notePlaceholder: 'Randevu hakkında notunuz...',

    // Actions
    accept: 'Kabul Et',
    decline: 'Reddet',
    reschedule: 'Yeniden Planla',
    cancel: 'İptal Et',
    complete: 'Tamamla',
    markNoShow: 'Gelmedi Olarak İşaretle',
    rate: 'Değerlendir',

    // Status
    statusPending: 'Onay Bekliyor',
    statusConfirmed: 'Onaylandı',
    statusDeclined: 'Reddedildi',
    statusCancelled: 'İptal Edildi',
    statusCompleted: 'Tamamlandı',
    statusNoShow: 'Gelmedi',

    // Messages
    appointmentRequested: 'Randevu istendi',
    appointmentAccepted: 'Randevu kabul edildi',
    appointmentDeclined: 'Randevu reddedildi',
    appointmentCancelled: 'Randevu iptal edildi',
    appointmentCompleted: 'Randevu tamamlandı',

    // Rating
    rateExperience: 'Deneyiminizi Değerlendirin',
    ratingSubmitted: 'Değerlendirme gönderildi',
  },

  // ========== PROFILE ==========
  profile: {
    title: 'Profil',
    editProfile: 'Profili Düzenle',

    // Info
    name: 'Ad Soyad',
    email: 'E-posta',
    phone: 'Telefon',
    city: 'Şehir',
    district: 'İlçe',

    // Trust
    trustScore: 'Güven Puanı',
    verified: 'Doğrulanmış',
    notVerified: 'Doğrulanmamış',
    verifyNow: 'Şimdi Doğrula',

    // Stats
    totalListings: 'Toplam İlan',
    activeListings: 'Aktif İlan',
    soldListings: 'Satılan İlan',
    completedAppointments: 'Tamamlanan Randevu',

    // Settings
    settings: 'Ayarlar',
    changePassword: 'Şifre Değiştir',
    notifications: 'Bildirimler',
    privacy: 'Gizlilik',

    // Actions
    profileUpdated: 'Profil güncellendi',
    passwordChanged: 'Şifre değiştirildi',
  },

  // ========== VERIFICATION ==========
  verification: {
    title: 'Kimlik Doğrulama',
    subtitle: 'Platformu kullanmak için kimliğinizi doğrulayın',

    // Steps
    stepIdentity: 'Kimlik Bilgileri',
    stepDocuments: 'Belgeler',
    stepReview: 'İnceleme',

    // Identity
    firstName: 'Ad',
    lastName: 'Soyad',
    idNumber: 'TC Kimlik No',
    phone: 'Telefon Numarası',

    // Documents
    uploadID: 'Kimlik Belgesi Yükle',
    uploadSelfie: 'Selfie Yükle',
    uploadProof: 'Adres Belgesi Yükle (İsteğe bağlı)',

    // Status
    statusPending: 'İnceleniyor',
    statusApproved: 'Onaylandı',
    statusRejected: 'Reddedildi',

    // Messages
    submitting: 'Gönderiliyor...',
    submitted: 'Doğrulama başvurunuz alındı',
    submitError: 'Bir hata oluştu, lütfen tekrar deneyin',
    pendingReview: 'Başvurunuz inceleniyor',
    approved: 'Kimliğiniz doğrulandı!',
    rejected: 'Başvurunuz reddedildi',
    rejectionReason: 'Red Nedeni',
    resubmit: 'Tekrar Başvur',
  },

  // ========== ADMIN ==========
  admin: {
    title: 'Yönetim Paneli',
    dashboard: 'Ana Sayfa',

    // Sections
    verifications: 'Doğrulamalar',
    users: 'Kullanıcılar',
    listings: 'İlanlar',
    reports: 'Şikayetler',
    settings: 'Ayarlar',

    // Verifications
    pendingVerifications: 'Bekleyen Doğrulamalar',
    approveVerification: 'Onayla',
    rejectVerification: 'Reddet',
    verificationApproved: 'Doğrulama onaylandı',
    verificationRejected: 'Doğrulama reddedildi',

    // Users
    totalUsers: 'Toplam Kullanıcı',
    activeUsers: 'Aktif Kullanıcı',
    bannedUsers: 'Yasaklı Kullanıcı',
    banUser: 'Kullanıcıyı Yasakla',
    unbanUser: 'Yasağı Kaldır',

    // Listings moderation
    takeDown: 'İlanı Kaldır',
    listingTakenDown: 'İlan kaldırıldı',
    takeDownReason: 'Kaldırma Nedeni',

    // Reports
    pendingReports: 'Bekleyen Şikayetler',
    resolveReport: 'Çöz',
    reportResolved: 'Şikayet çözüldü',

    // Settings
    systemSettings: 'Sistem Ayarları',
    staleDays: 'İlan Geçerlilik Süresi (Gün)',
    confirmWindowDays: 'Onay Penceresi (Gün)',
    settingsUpdated: 'Ayarlar güncellendi',
  },

  // ========== ERRORS ==========
  errors: {
    generic: 'Bir hata oluştu',
    network: 'Bağlantı hatası. İnternetinizi kontrol edin.',
    unauthorized: 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.',
    forbidden: 'Bu işlem için yetkiniz yok.',
    notFound: 'Aradığınız sayfa bulunamadı.',
    serverError: 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.',
    validation: 'Lütfen tüm alanları doğru şekilde doldurun.',
    uploadFailed: 'Yükleme başarısız oldu.',
    deleteFailed: 'Silme başarısız oldu.',
  },

  // ========== EMPTY STATES ==========
  emptyStates: {
    noResults: 'Sonuç bulunamadı',
    noData: 'Henüz veri yok',
    tryAgain: 'Tekrar deneyin',
    goBack: 'Geri dön',
  },

  // ========== TIME & DATE ==========
  time: {
    now: 'Şimdi',
    justNow: 'Az önce',
    minutesAgo: (n: number) => `${n} dakika önce`,
    hoursAgo: (n: number) => `${n} saat önce`,
    daysAgo: (n: number) => `${n} gün önce`,
    weeksAgo: (n: number) => `${n} hafta önce`,
    monthsAgo: (n: number) => `${n} ay önce`,
    yearsAgo: (n: number) => `${n} yıl önce`,

    today: 'Bugün',
    yesterday: 'Dün',
    tomorrow: 'Yarın',
  },

  // ========== NUMBERS & CURRENCY ==========
  numbers: {
    currency: 'TL',
    thousand: 'Bin',
    million: 'Milyon',
    km: 'km',
  },
} as const;

export type Strings = typeof strings;
