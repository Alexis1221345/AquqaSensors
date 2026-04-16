import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/pool_chemical_model.dart';
import '../../../data/supabase/supabase_chemicals_service.dart';
import '../../../shared/providers/pool_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/loading_widget.dart';

class PoolChemicalsScreen extends StatefulWidget {
  const PoolChemicalsScreen({super.key});

  @override
  State<PoolChemicalsScreen> createState() => _PoolChemicalsScreenState();
}

class _PoolChemicalsScreenState extends State<PoolChemicalsScreen> {
  static const List<String> _orderedCategories = [
    'cloro',
    'bajar_ph',
    'subir_ph',
    'alcalinidad',
    'turbidez',
    'algicida',
  ];

  final _chemicalsService = SupabaseChemicalsService();
  final Map<String, PoolChemicalModel> _existingByCategory = {};
  bool _isLoading = true;
  String? _activePoolId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadExistingChemicals());
  }

  Future<void> _loadExistingChemicals() async {
    final poolId = context.read<PoolProvider>().activePoolId;
    setState(() {
      _activePoolId = poolId;
      _isLoading = poolId != null;
    });

    if (poolId == null) return;

    try {
      final items = await _chemicalsService.getPoolChemicals(poolId);
      if (!mounted) return;
      setState(() {
        _existingByCategory
          ..clear()
          ..addEntries(items.map((e) => MapEntry(e.categoria, e)));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar químicos: $e'),
          backgroundColor: AppColors.statusCritico,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Mis Químicos',
        subtitle: 'Configuración por alberca',
        showBack: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildBody() {
    if (_activePoolId == null) {
      return const Center(
        child: Text(
          'Selecciona una alberca primero',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    if (_isLoading) {
      return const LoadingWidget(message: 'Cargando químicos...');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      children: _orderedCategories
          .map(
            (categoria) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChemicalCategoryCard(
                poolId: _activePoolId!,
                categoria: categoria,
                initialValue: _existingByCategory[categoria],
                onSaved: (saved) {
                  setState(() => _existingByCategory[categoria] = saved);
                },
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ChemicalCategoryCard extends StatefulWidget {
  final String poolId;
  final String categoria;
  final PoolChemicalModel? initialValue;
  final ValueChanged<PoolChemicalModel> onSaved;

  const _ChemicalCategoryCard({
    required this.poolId,
    required this.categoria,
    required this.initialValue,
    required this.onSaved,
  });

  @override
  State<_ChemicalCategoryCard> createState() => _ChemicalCategoryCardState();
}

class _ChemicalCategoryCardState extends State<_ChemicalCategoryCard> {
  final _service = SupabaseChemicalsService();
  bool _isSaving = false;
  String? _selectedChemicalId;
  double? _selectedConcentration;

  List<ChemicalOption> get _options =>
      ChemicalCatalog.byCategoria[widget.categoria] ?? const [];

  ChemicalOption? get _selectedOption {
    for (final option in _options) {
      if (option.id == _selectedChemicalId) return option;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.initialValue;
    if (existing != null) {
      _selectedChemicalId = existing.quimicoId;
      _selectedConcentration = existing.concentracion;
      return;
    }

    if (_options.isNotEmpty) {
      _selectedChemicalId = _options.first.id;
      _selectedConcentration = _options.first.concentraciones.first;
    }
  }

  Future<void> _save() async {
    if (_selectedOption == null || _selectedConcentration == null) return;

    setState(() => _isSaving = true);

    try {
      final model = PoolChemicalModel(
        id: widget.initialValue?.id,
        poolId: widget.poolId,
        categoria: widget.categoria,
        quimicoId: _selectedOption!.id,
        quimicoNombre: _selectedOption!.nombre,
        concentracion: _selectedConcentration!,
        activo: true,
      );

      await _service.upsertChemical(model);

      if (!mounted) return;
      widget.onSaved(model);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppColors.statusCritico,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (ChemicalCatalog.categoriaLabel[widget.categoria] ??
                      widget.categoria)
                  .toUpperCase(),
              style: AppTextStyles.labelField,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedChemicalId,
              decoration: _inputDecoration('Químico'),
              items: _options
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option.id,
                      child: Text(option.nombre),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      final selected =
                          _options.firstWhere((o) => o.id == value);
                      setState(() {
                        _selectedChemicalId = value;
                        _selectedConcentration = selected.concentraciones.first;
                      });
                    },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<double>(
              initialValue: _selectedConcentration,
              decoration: _inputDecoration('Concentración'),
              items: (_selectedOption?.concentraciones ?? const <double>[])
                  .map(
                    (value) => DropdownMenuItem<double>(
                      value: value,
                      child: Text('${_fmtConcentration(value)}%'),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _selectedConcentration = value);
                    },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  String _fmtConcentration(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? value.toStringAsFixed(0) : fixed;
  }
}
