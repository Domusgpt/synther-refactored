import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';
import '../../core/granular_parameters.dart';
import 'preset_manager_platform.dart';

/// Dialog for saving and loading presets
class PresetDialog extends StatefulWidget {
  final bool isSaving;
  
  const PresetDialog({
    Key? key,
    required this.isSaving,
  }) : super(key: key);
  
  static Future<void> showSaveDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const PresetDialog(isSaving: true),
    );
  }
  
  static Future<void> showLoadDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const PresetDialog(isSaving: false),
    );
  }

  @override
  State<PresetDialog> createState() => _PresetDialogState();
}

class _PresetDialogState extends State<PresetDialog> {
  final TextEditingController _nameController = TextEditingController();
  List<String> _presets = [];
  bool _isLoading = true;
  String? _selectedPreset;
  
  @override
  void initState() {
    super.initState();
    _loadPresets();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPresets() async {
    final presets = await PresetManager.getPresetList();
    final lastPreset = await PresetManager.getLastPresetName();
    
    setState(() {
      _presets = presets;
      _isLoading = false;
      if (lastPreset != null && presets.contains(lastPreset)) {
        _selectedPreset = lastPreset;
      }
    });
  }
  
  Future<void> _savePreset() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a preset name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if preset already exists
    if (_presets.contains(name)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Overwrite Preset?'),
          content: Text('A preset named "$name" already exists. Overwrite it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }
    
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    
    final success = await PresetManager.savePreset(
      name: name,
      synthParams: synthParams,
      granularParams: synthParams.granularParameters,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preset saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save preset'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _loadPreset() async {
    if (_selectedPreset == null) return;
    
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    
    // Since we now include granular parameters in the synth model,
    // we only need to load into the synth model
    final success = await PresetManager.loadPreset(
      name: _selectedPreset!,
      synthParams: synthParams,
      granularParams: synthParams.granularParameters,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preset loaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load preset'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deletePreset() async {
    if (_selectedPreset == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: Text('Delete preset "$_selectedPreset"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await PresetManager.deletePreset(_selectedPreset!);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preset deleted'),
          ),
        );
        await _loadPresets();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSaving ? 'Save Preset' : 'Load Preset'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isSaving) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Preset Name',
                        hintText: 'Enter preset name',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      onSubmitted: (_) => _savePreset(),
                    ),
                  ] else ...[
                    if (_presets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No presets found.\nSave a preset first!',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _presets.length,
                          itemBuilder: (context, index) {
                            final preset = _presets[index];
                            return ListTile(
                              title: Text(preset),
                              selected: preset == _selectedPreset,
                              onTap: () {
                                setState(() {
                                  _selectedPreset = preset;
                                });
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedPreset = preset;
                                  });
                                  _deletePreset();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.isSaving)
          ElevatedButton(
            onPressed: _savePreset,
            child: const Text('Save'),
          )
        else if (_selectedPreset != null)
          ElevatedButton(
            onPressed: _loadPreset,
            child: const Text('Load'),
          ),
      ],
    );
  }
}