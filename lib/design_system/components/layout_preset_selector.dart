import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system.dart';
import '../../core/layout_preset_manager.dart';

/// Visual interface for selecting and managing layout presets
/// Provides the preset selection UI shown in the design mockups
class LayoutPresetSelector extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final Function(LayoutPreset)? onPresetSelected;
  final Function(LayoutPreset)? onPresetEdit;
  final Function(LayoutPreset)? onPresetDelete;
  
  const LayoutPresetSelector({
    Key? key,
    this.isExpanded = false,
    this.onToggleExpanded,
    this.onPresetSelected,
    this.onPresetEdit,
    this.onPresetDelete,
  }) : super(key: key);
  
  @override
  State<LayoutPresetSelector> createState() => _LayoutPresetSelectorState();
}

class _LayoutPresetSelectorState extends State<LayoutPresetSelector>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _glowController;
  late Animation<double> _expandAnimation;
  late Animation<double> _glowAnimation;
  
  String _searchQuery = '';
  PresetCategory _selectedCategory = PresetCategory.system;
  bool _showCreateDialog = false;
  
  @override
  void initState() {
    super.initState();
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _glowController.repeat(reverse: true);
    
    if (widget.isExpanded) {
      _expandController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(LayoutPresetSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _expandController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutPresetManager>(
      builder: (context, presetManager, child) {
        return AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return GlassmorphicPane(
              width: 320,
              height: 80 + (_expandAnimation.value * 500),
              tintColor: DesignTokens.neonBlue,
              opacity: 0.08,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(presetManager),
                  
                  if (_expandAnimation.value > 0.1) ...[
                    SizedBox(height: 16 * _expandAnimation.value),
                    Expanded(
                      child: Opacity(
                        opacity: _expandAnimation.value,
                        child: _buildPresetInterface(presetManager),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildHeader(LayoutPresetManager presetManager) {
    return Row(
      children: [
        Icon(
          Icons.dashboard_customize,
          color: DesignTokens.neonBlue,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Layout Presets',
                style: SyntherTypography.labelMedium.copyWith(
                  color: DesignTokens.neonBlue,
                ),
              ),
              if (presetManager.activePreset != null)
                Text(
                  presetManager.activePreset!.name,
                  style: SyntherTypography.caption.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: widget.onToggleExpanded,
          child: Icon(
            widget.isExpanded ? Icons.expand_less : Icons.expand_more,
            color: DesignTokens.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPresetInterface(LayoutPresetManager presetManager) {
    return Column(
      children: [
        // Search and actions
        _buildSearchAndActions(presetManager),
        
        const SizedBox(height: 16),
        
        // Category tabs
        _buildCategoryTabs(),
        
        const SizedBox(height: 16),
        
        // Preset grid
        Expanded(
          child: _buildPresetGrid(presetManager),
        ),
      ],
    );
  }
  
  Widget _buildSearchAndActions(LayoutPresetManager presetManager) {
    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: DesignTokens.neonBlue.withOpacity(0.3),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: SyntherTypography.caption.copyWith(
                color: DesignTokens.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search presets...',
                hintStyle: SyntherTypography.caption.copyWith(
                  color: DesignTokens.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: DesignTokens.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Create new preset button
        GestureDetector(
          onTap: () => _showCreatePresetDialog(presetManager),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonGreen.withOpacity(0.3),
                  DesignTokens.neonGreen.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignTokens.neonGreen.withOpacity(0.5),
              ),
            ),
            child: Icon(
              Icons.add,
              color: DesignTokens.neonGreen,
              size: 18,
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Import preset button
        GestureDetector(
          onTap: () => _showImportDialog(presetManager),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonPurple.withOpacity(0.3),
                  DesignTokens.neonPurple.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignTokens.neonPurple.withOpacity(0.5),
              ),
            ),
            child: Icon(
              Icons.file_download,
              color: DesignTokens.neonPurple,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PresetCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      category.color.withOpacity(isSelected ? 0.3 : 0.1),
                      category.color.withOpacity(isSelected ? 0.1 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: isSelected ? 2 : 1,
                    color: category.color.withOpacity(isSelected ? 0.8 : 0.3),
                  ),
                ),
                child: Text(
                  category.displayName,
                  style: SyntherTypography.caption.copyWith(
                    color: category.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildPresetGrid(LayoutPresetManager presetManager) {
    List<LayoutPreset> presets;
    
    if (_searchQuery.isNotEmpty) {
      presets = presetManager.searchPresets(_searchQuery);
    } else {
      presets = presetManager.getPresetsByCategory(_selectedCategory);
    }
    
    if (presets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 48,
              color: DesignTokens.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ? 'No matching presets' : 'No presets in this category',
              style: SyntherTypography.bodySmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isActive = presetManager.activePreset?.id == preset.id;
        
        return _buildPresetCard(preset, isActive, presetManager);
      },
    );
  }
  
  Widget _buildPresetCard(LayoutPreset preset, bool isActive, LayoutPresetManager presetManager) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _selectPreset(preset, presetManager),
          onLongPress: () => _showPresetOptions(preset, presetManager),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  preset.category.color.withOpacity(isActive ? 0.3 : 0.15),
                  preset.category.color.withOpacity(isActive ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: isActive ? 2 : 1,
                color: preset.category.color.withOpacity(
                  isActive 
                    ? _glowAnimation.value 
                    : 0.3
                ),
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: preset.category.color.withOpacity(0.3 * _glowAnimation.value),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and status
                Row(
                  children: [
                    Icon(
                      _getPresetIcon(preset),
                      size: 16,
                      color: preset.category.color,
                    ),
                    const Spacer(),
                    if (isActive) ...[
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: DesignTokens.neonGreen,
                      ),
                    ],
                    if (preset.isSystemPreset) ...[
                      Icon(
                        Icons.lock,
                        size: 12,
                        color: DesignTokens.textSecondary,
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Preset name
                Text(
                  preset.name,
                  style: SyntherTypography.labelSmall.copyWith(
                    color: preset.category.color,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Description
                Text(
                  preset.description,
                  style: SyntherTypography.caption.copyWith(
                    color: DesignTokens.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Spacer(),
                
                // Preset info
                Row(
                  children: [
                    Text(
                      preset.category.displayName,
                      style: SyntherTypography.caption.copyWith(
                        color: preset.category.color.withOpacity(0.8),
                        fontSize: 9,
                      ),
                    ),
                    const Spacer(),
                    if (preset.modifiedAt != null)
                      Text(
                        _formatDate(preset.modifiedAt!),
                        style: SyntherTypography.caption.copyWith(
                          color: DesignTokens.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  IconData _getPresetIcon(LayoutPreset preset) {
    switch (preset.category) {
      case PresetCategory.system:
        return Icons.settings;
      case PresetCategory.user:
        return Icons.person;
      case PresetCategory.performance:
        return Icons.music_note;
      case PresetCategory.soundDesign:
        return Icons.tune;
      case PresetCategory.live:
        return Icons.live_tv;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
  
  void _selectPreset(LayoutPreset preset, LayoutPresetManager presetManager) {
    presetManager.loadPreset(preset.id);
    widget.onPresetSelected?.call(preset);
  }
  
  void _showPresetOptions(LayoutPreset preset, LayoutPresetManager presetManager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PresetOptionsSheet(
        preset: preset,
        presetManager: presetManager,
        onEdit: widget.onPresetEdit,
        onDelete: widget.onPresetDelete,
      ),
    );
  }
  
  void _showCreatePresetDialog(LayoutPresetManager presetManager) {
    showDialog(
      context: context,
      builder: (context) => _CreatePresetDialog(
        presetManager: presetManager,
      ),
    );
  }
  
  void _showImportDialog(LayoutPresetManager presetManager) {
    showDialog(
      context: context,
      builder: (context) => _ImportPresetDialog(
        presetManager: presetManager,
      ),
    );
  }
}

/// Options sheet for preset actions
class _PresetOptionsSheet extends StatelessWidget {
  final LayoutPreset preset;
  final LayoutPresetManager presetManager;
  final Function(LayoutPreset)? onEdit;
  final Function(LayoutPreset)? onDelete;
  
  const _PresetOptionsSheet({
    required this.preset,
    required this.presetManager,
    this.onEdit,
    this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return GlassmorphicPane(
      width: double.infinity,
      height: 280,
      tintColor: preset.category.color,
      opacity: 0.1,
      padding: const EdgeInsets.all(20),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.dashboard_customize,
                color: preset.category.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                preset.name,
                style: SyntherTypography.labelMedium.copyWith(
                  color: preset.category.color,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  color: DesignTokens.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Actions
          ..._buildActionButtons(context),
        ],
      ),
    );
  }
  
  List<Widget> _buildActionButtons(BuildContext context) {
    return [
      // Duplicate
      _buildActionButton(
        icon: Icons.copy,
        label: 'Duplicate',
        color: DesignTokens.neonCyan,
        onTap: () async {
          Navigator.pop(context);
          await presetManager.duplicatePreset(preset.id);
        },
      ),
      
      const SizedBox(height: 12),
      
      // Export
      _buildActionButton(
        icon: Icons.file_upload,
        label: 'Export',
        color: DesignTokens.neonPurple,
        onTap: () {
          Navigator.pop(context);
          final jsonData = presetManager.exportPreset(preset.id);
          // TODO: Share or save the JSON data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Preset exported: ${preset.name}')),
          );
        },
      ),
      
      const SizedBox(height: 12),
      
      // Edit (if not system preset)
      if (!preset.isSystemPreset) ...[
        _buildActionButton(
          icon: Icons.edit,
          label: 'Edit',
          color: DesignTokens.neonOrange,
          onTap: () {
            Navigator.pop(context);
            onEdit?.call(preset);
          },
        ),
        
        const SizedBox(height: 12),
        
        // Delete
        _buildActionButton(
          icon: Icons.delete,
          label: 'Delete',
          color: DesignTokens.neonPink,
          onTap: () async {
            Navigator.pop(context);
            final success = await presetManager.deletePreset(preset.id);
            if (success) {
              onDelete?.call(preset);
            }
          },
        ),
      ],
    ];
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: SyntherTypography.bodyMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating new presets
class _CreatePresetDialog extends StatefulWidget {
  final LayoutPresetManager presetManager;
  
  const _CreatePresetDialog({required this.presetManager});
  
  @override
  State<_CreatePresetDialog> createState() => _CreatePresetDialogState();
}

class _CreatePresetDialogState extends State<_CreatePresetDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  PresetCategory _selectedCategory = PresetCategory.user;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicPane(
        width: 320,
        height: 400,
        tintColor: DesignTokens.neonGreen,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: DesignTokens.neonGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Create New Preset',
                  style: SyntherTypography.labelMedium.copyWith(
                    color: DesignTokens.neonGreen,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: DesignTokens.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Name field
            _buildTextField(
              controller: _nameController,
              label: 'Preset Name',
              hint: 'Enter preset name...',
            ),
            
            const SizedBox(height: 16),
            
            // Description field
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter description...',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Category selector
            Text(
              'Category',
              style: SyntherTypography.labelSmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: [PresetCategory.user, PresetCategory.performance, PresetCategory.soundDesign, PresetCategory.live]
                  .map((category) {
                final isSelected = _selectedCategory == category;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          category.color.withOpacity(isSelected ? 0.3 : 0.1),
                          category.color.withOpacity(isSelected ? 0.1 : 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: category.color.withOpacity(isSelected ? 0.8 : 0.3),
                      ),
                    ),
                    child: Text(
                      category.displayName,
                      style: SyntherTypography.caption.copyWith(
                        color: category.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const Spacer(),
            
            // Create button
            GestureDetector(
              onTap: _createPreset,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.neonGreen.withOpacity(0.3),
                      DesignTokens.neonGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignTokens.neonGreen.withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Create Preset',
                    style: SyntherTypography.bodyMedium.copyWith(
                      color: DesignTokens.neonGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SyntherTypography.labelSmall.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: DesignTokens.neonGreen.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: SyntherTypography.bodySmall.copyWith(
              color: DesignTokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: SyntherTypography.bodySmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }
  
  void _createPreset() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a preset name')),
      );
      return;
    }
    
    final newId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    final preset = LayoutPreset(
      id: newId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      isSystemPreset: false,
      layoutConfig: LayoutConfig.defaultConfig(), // Use current layout
      parameterBindings: {}, // Use current bindings
      visualizerConfig: VisualizerConfig.defaultConfig(),
      uiTheme: UIThemeConfig.defaultTheme(),
    );
    
    final success = await widget.presetManager.savePreset(preset);
    
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preset created: ${preset.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create preset')),
      );
    }
  }
}

/// Dialog for importing presets
class _ImportPresetDialog extends StatefulWidget {
  final LayoutPresetManager presetManager;
  
  const _ImportPresetDialog({required this.presetManager});
  
  @override
  State<_ImportPresetDialog> createState() => _ImportPresetDialogState();
}

class _ImportPresetDialogState extends State<_ImportPresetDialog> {
  final _jsonController = TextEditingController();
  final _nameController = TextEditingController();
  
  @override
  void dispose() {
    _jsonController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicPane(
        width: 360,
        height: 480,
        tintColor: DesignTokens.neonPurple,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.file_download,
                  color: DesignTokens.neonPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Import Preset',
                  style: SyntherTypography.labelMedium.copyWith(
                    color: DesignTokens.neonPurple,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: DesignTokens.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // JSON input
            Text(
              'Preset JSON Data',
              style: SyntherTypography.labelSmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DesignTokens.neonPurple.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _jsonController,
                  maxLines: null,
                  expands: true,
                  style: SyntherTypography.bodySmall.copyWith(
                    color: DesignTokens.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Paste preset JSON data here...',
                    hintStyle: SyntherTypography.bodySmall.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Optional name override
            Text(
              'Custom Name (optional)',
              style: SyntherTypography.labelSmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DesignTokens.neonPurple.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _nameController,
                style: SyntherTypography.bodySmall.copyWith(
                  color: DesignTokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter custom name...',
                  hintStyle: SyntherTypography.bodySmall.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Import button
            GestureDetector(
              onTap: _importPreset,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.neonPurple.withOpacity(0.3),
                      DesignTokens.neonPurple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignTokens.neonPurple.withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Import Preset',
                    style: SyntherTypography.bodyMedium.copyWith(
                      color: DesignTokens.neonPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _importPreset() async {
    if (_jsonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter JSON data')),
      );
      return;
    }
    
    final customName = _nameController.text.trim().isNotEmpty 
        ? _nameController.text.trim() 
        : null;
    
    final presetId = await widget.presetManager.importPreset(
      _jsonController.text.trim(),
      newName: customName,
    );
    
    if (presetId != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preset imported successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to import preset - invalid JSON')),
      );
    }
  }
}