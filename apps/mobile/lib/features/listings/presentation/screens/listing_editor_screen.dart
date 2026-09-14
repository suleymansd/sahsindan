import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/widgets/listing_photo.dart';
import '../../../../core/errors/error_text.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/listings_providers.dart';

class ListingEditorScreen extends ConsumerStatefulWidget {
  const ListingEditorScreen({super.key, this.editListingId});

  final int? editListingId;

  @override
  ConsumerState<ListingEditorScreen> createState() =>
      _ListingEditorScreenState();
}

class _ListingEditorScreenState extends ConsumerState<ListingEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _district = TextEditingController();

  // Car detail only required for create.
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _mileage = TextEditingController();
  final _transmission = TextEditingController(text: 'Automatic');
  final _fuel = TextEditingController(text: 'Gasoline');
  final _color = TextEditingController(text: 'Black');

  PlatformFile? _pendingPhoto;
  int? _listingId;
  bool _saving = false;
  bool _uploading = false;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _listingId = widget.editListingId;
    if (_listingId != null) {
      Future.microtask(() async {
        final listing =
            await ref.read(listingsRepositoryProvider).get(_listingId!);
        if (!mounted) return;
        _title.text = listing.title;
        _description.text = listing.description;
        _price.text = listing.price.toStringAsFixed(0);
        _district.text = listing.district;
        _brand.text = listing.carDetails.brand;
        _model.text = listing.carDetails.model;
        _year.text = listing.carDetails.year.toString();
        _mileage.text = listing.carDetails.mileage.toString();
        _transmission.text = listing.carDetails.transmission;
        _fuel.text = listing.carDetails.fuel;
        _color.text = listing.carDetails.color;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _district.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _mileage.dispose();
    _transmission.dispose();
    _fuel.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(listingsRepositoryProvider);
      final price = double.parse(_price.text.trim());

      if (_listingId == null) {
        final created = await repo.create(
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: price,
          city: 'ISTANBUL',
          district: _district.text.trim(),
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          year: int.parse(_year.text.trim()),
          mileage: int.parse(_mileage.text.trim()),
          transmission: _transmission.text.trim(),
          fuel: _fuel.text.trim(),
          color: _color.text.trim(),
        );
        _listingId = created.id;
        if (_pendingPhoto != null) {
          try {
            await repo.uploadPhoto(listingId: created.id, filename: _pendingPhoto!.name, bytes: _pendingPhoto!.bytes!, contentType: _imageType(_pendingPhoto!.name));
            _pendingPhoto = null;
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Taslak kaydedildi; fotoğraf yüklenemedi. Düzenleme ekranından yeniden deneyin. ${friendlyErrorText(e)}')));
          }
        }
        ref.invalidate(myListingsProvider);
        ref.invalidate(listingsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Ilan olusturuldu')));
          context.go('/app/listings/${created.id}/edit');
        }
      } else {
        await repo.update(
          id: _listingId!,
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: price,
          district: _district.text.trim(),
        );
        ref.invalidate(listingDetailProvider(_listingId!));
        ref.invalidate(myListingsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Kaydedildi')));
        }
      }
    } catch (e) {
      final err = ErrorMapper.fromDio(e);
      final msg = err.when(
        network: (m) => m,
        unauthorized: () => 'Oturum suresi doldu',
        forbidden: (m) => m ?? 'Erisim engellendi',
        rateLimited: (m) => m ?? 'Cok fazla istek',
        validation: (m, _) => m ?? 'Gecersiz veri',
        server: (m) => m,
        unknown: (m) => m,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted) return;
    final file = res?.files.single;
    if (file == null) return;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dosya okunamadi')));
      return;
    }

    if (_listingId == null) {
      setState(() => _pendingPhoto = file);
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = null;
    });

    try {
      await ref.read(listingsRepositoryProvider).uploadPhoto(
            listingId: _listingId!,
            filename: file.name,
            bytes: file.bytes!,
            contentType: _imageType(file.name),
            onProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              setState(() => _uploadProgress = sent / total);
            },
          );
      ref.invalidate(listingDetailProvider(_listingId!));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto yuklendi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorText(e))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _publish() async {
    if (_listingId == null) return;
    await ref.read(listingsRepositoryProvider).publish(_listingId!);
    ref.invalidate(listingDetailProvider(_listingId!));
    ref.invalidate(myListingsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Yayinlandi')));
      context.go('/app/listings/${_listingId!}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _listingId != null;
    final detailAsync =
        isEdit ? ref.watch(listingDetailProvider(_listingId!)) : null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'İlanı Düzenle' : 'Yeni İlan Oluştur')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircleAvatar(radius: 12, backgroundColor: AppColors.secondary, child: Text('1', style: TextStyle(fontSize: 12, color: AppColors.primary))),
              const SizedBox(width: 8), const Text('Medya', style: TextStyle(fontSize: 12)),
              Container(width: 36, height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.secondary),
              const CircleAvatar(radius: 12, backgroundColor: AppColors.surfaceMuted, child: Text('2', style: TextStyle(fontSize: 12, color: AppColors.primary))),
              const SizedBox(width: 8), const Text('Detaylar', style: TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 24),
            if (!isEdit) ...[
              AppGlass(radius: 12, padding: const EdgeInsets.all(20), child: Column(children: [
                Text('İlanınıza hayat verin', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                const Text('Aracınızın fotoğrafını seçin, detayları ekleyin. Yayınlamadan önce her şeyi gözden geçirebilirsiniz.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.6)),
                const SizedBox(height: 20),
                Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFECFAFE), border: Border.all(color: AppColors.secondary.withValues(alpha: .5)), borderRadius: BorderRadius.circular(8)), child: Column(children: [
                  if (_pendingPhoto == null) const AppHeroBadgeIcon(icon: Icons.cloud_upload_outlined, size: 60)
                  else ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_pendingPhoto!.bytes!, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 60))),
                  const SizedBox(height: 16),
                  Text(_pendingPhoto == null ? 'İlk fotoğrafınızı ekleyin' : _pendingPhoto!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _saving ? null : _uploadPhoto, icon: const Icon(Icons.add_photo_alternate_outlined, size: 18), label: Text(_pendingPhoto == null ? 'Fotoğraf Seç' : 'Fotoğrafı Değiştir')),
                ])),
              ])),
              const SizedBox(height: 24),
            ],
            Text('İlan Detayları', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Bilgileri kontrol edin ve taslağınızı kaydedin.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            AppGlass(
              radius: 12,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Baslik'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Baslik gerekli'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Aciklama'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Aciklama gerekli'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fiyat'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        final n = double.tryParse(t);
                        if (n == null || !n.isFinite || n <= 0) return 'Gecerli fiyat girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _district,
                      decoration: const InputDecoration(labelText: 'Ilce'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ilce gerekli'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (!isEdit) ...[
                      TextFormField(
                        controller: _brand,
                        decoration: const InputDecoration(labelText: 'Marka'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Marka gerekli'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _model,
                        decoration: const InputDecoration(labelText: 'Model'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Model gerekli'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _year,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Yil'),
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null ||
                                    n < 1980 ||
                                    n > DateTime.now().year + 1) {
                                  return 'Gecerli yil';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _mileage,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Km'),
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null || n < 0) return 'Gecerli km';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _transmission,
                          decoration: const InputDecoration(
                              labelText: 'Sanziman (Automatic/Manual)')),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _fuel,
                          decoration: const InputDecoration(
                              labelText: 'Yakit (Gasoline/Diesel/...)')),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _color,
                          decoration: const InputDecoration(labelText: 'Renk')),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(
                            child:
                                Text(_saving ? 'Kaydediliyor…' : 'Taslağı Kaydet ve Devam Et')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isEdit) ...[
              AppGlass(
                radius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Fotograflar',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          onPressed: _uploading ? null : _uploadPhoto,
                          icon: const Icon(Icons.add_photo_alternate),
                        ),
                      ],
                    ),
                    if (_uploading) ...[
                      const SizedBox(height: 8),
                      const AppLoading(message: 'Yukleniyor...'),
                      if (_uploadProgress != null)
                        LinearProgressIndicator(value: _uploadProgress),
                    ],
                    const SizedBox(height: 8),
                    detailAsync!.when(
                      data: (listing) {
                        if (listing.photos.isEmpty) {
                          return const Text('Fotograf yok');
                        }

                        final ids = listing.photos.map((p) => p.id).toList();

                        return ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: listing.photos.length,
                          onReorderItem: (oldIndex, newIndex) async {
                            final moved = ids.removeAt(oldIndex);
                            ids.insert(newIndex, moved);
                            await ref
                                .read(listingsRepositoryProvider)
                                .reorderPhotos(
                                    listingId: listing.id, photoIds: ids);
                            ref.invalidate(listingDetailProvider(listing.id));
                          },
                          itemBuilder: (context, i) {
                            final p = listing.photos[i];
                            return ListTile(
                              key: ValueKey(p.id),
                              leading: SizedBox(width: 64, height: 48, child: ClipRRect(borderRadius: BorderRadius.circular(6), child: ListingPhotoView(url: resolvePublicUrl(publicBaseUrl: ref.read(appConfigProvider).publicBaseUrl, maybeRelative: p.url)))),
                              title: Text('Fotoğraf ${i + 1}'),
                              subtitle: const Text('Sıralamak için basılı tutun'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await ref
                                      .read(listingsRepositoryProvider)
                                      .deletePhoto(
                                          listingId: listing.id, photoId: p.id);
                                  ref.invalidate(
                                      listingDetailProvider(listing.id));
                                },
                              ),
                            );
                          },
                        );
                      },
                      error: (e, _) => Text(friendlyErrorText(e)),
                      loading: () => const AppLoading(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _publish,
                icon: const Icon(Icons.publish),
                label: const Text('Yayinla'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/app/listings/${_listingId!}'),
                child: const Text('Detaya don'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _imageType(String name) {
  final extension = name.split('.').last.toLowerCase();
  return switch (extension) { 'png' => 'image/png', 'webp' => 'image/webp', 'heic' => 'image/heic', 'heif' => 'image/heif', _ => 'image/jpeg' };
}
