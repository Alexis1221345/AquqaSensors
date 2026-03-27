import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/supabase/supabase_storage_service.dart';

class AddPoolSheet extends StatefulWidget {
  final VoidCallback? onSaved;
  const AddPoolSheet({super.key, this.onSaved});

  @override
  State<AddPoolSheet> createState() => _AddPoolSheetState();
}

class _AddPoolSheetState extends State<AddPoolSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _largoCtrl = TextEditingController();
  final _anchoCtrl = TextEditingController();
  final _diametroCtrl = TextEditingController();
  final _profMinCtrl = TextEditingController();
  final _profMaxCtrl = TextEditingController();

  String _tipoAlberca = 'rectangular';
  bool _saving = false;
  File? _imageFile;

  final List<Map<String, String>> _tipos = [
    {'value': 'rectangular', 'label': 'Rectangular'},
    {'value': 'circular', 'label': 'Circular'},
    {'value': 'ovalada', 'label': 'Ovalada'},
    {'value': 'ovalada_rectos', 'label': 'Ovalada con lados rectos'},
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    _largoCtrl.dispose();
    _anchoCtrl.dispose();
    _diametroCtrl.dispose();
    _profMinCtrl.dispose();
    _profMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? imageUrl;
      if (_imageFile != null) {
        final storage = SupabaseStorageService();
        imageUrl = await storage.uploadPoolImage(
          poolId: 'tmp-${DateTime.now().millisecondsSinceEpoch}',
          imageFile: _imageFile!,
        );
      }

      await Supabase.instance.client.from(AppConstants.tablePools).insert({
        'owner_id': user.id,
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        'ubicacion': _ubicacionCtrl.text.trim().isEmpty
            ? null
            : _ubicacionCtrl.text.trim(),
        'tipo': _tipoAlberca,
        'largo_m': _tipoAlberca != 'circular'
            ? double.tryParse(_largoCtrl.text)
            : null,
        'ancho_m': _tipoAlberca != 'circular'
            ? double.tryParse(_anchoCtrl.text)
            : null,
        'diametro_m': _tipoAlberca == 'circular'
            ? double.tryParse(_diametroCtrl.text)
            : null,
        'prof_minima_m': double.tryParse(_profMinCtrl.text),
        'prof_maxima_m': double.tryParse(_profMaxCtrl.text),
        'imagen_url': imageUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alberca registrada correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.statusCritico,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCircular = _tipoAlberca == 'circular';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, scrollCtrl) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Agregar Alberca',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Completa los datos para calcular el volumen y las dosis correctas',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // ── Foto ────────────────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: AppColors.primary.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            const Text(
                              'Toca para agregar foto',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                                onPressed: () =>
                                    setState(() => _imageFile = null),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Nombre ──────────────────────────────────────────────────
              _label('NOMBRE DE LA ALBERCA'),
              _field(
                controller: _nombreCtrl,
                hint: 'Ej. Alberca principal',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),

              // ── Descripción ─────────────────────────────────────────────
              _label('DESCRIPCIÓN (OPCIONAL)'),
              _field(
                controller: _descripcionCtrl,
                hint: 'Ej. Alberca residencial con sistema AquaSensors',
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // ── Ubicación ───────────────────────────────────────────────
              _label('UBICACIÓN (OPCIONAL)'),
              _field(
                controller: _ubicacionCtrl,
                hint: 'Ej. Monterrey, Nuevo León',
              ),
              const SizedBox(height: 16),

              // ── Tipo ────────────────────────────────────────────────────
              _label('TIPO DE ALBERCA'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tipoAlberca,
                    isExpanded: true,
                    items: _tipos.map((t) {
                      return DropdownMenuItem(
                        value: t['value'],
                        child: Text(t['label']!,
                            style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _tipoAlberca = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Dimensiones ─────────────────────────────────────────────
              _label('DIMENSIONES (metros)'),
              const SizedBox(height: 8),

              if (isCircular) ...[
                _field(
                  controller: _diametroCtrl,
                  label: 'Diámetro',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _largoCtrl,
                        label: 'Largo',
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _anchoCtrl,
                        label: 'Ancho',
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _profMinCtrl,
                      label: 'Prof. mínima',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: _profMaxCtrl,
                      label: 'Prof. máxima',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fórmula informativa
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formulaLabel(),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // ── Guardar ─────────────────────────────────────────────────
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar alberca'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formulaLabel() {
    switch (_tipoAlberca) {
      case 'circular':
        return 'Volumen = Diámetro² × Prof. media × 0.785 × 1,000 litros';
      case 'ovalada':
        return 'Volumen = Largo × Ancho × Prof. media × 0.785 × 1,000 litros';
      default:
        return 'Volumen = Largo × Ancho × Prof. media × 1,000 litros';
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    String? label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
          ],
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      );
}
