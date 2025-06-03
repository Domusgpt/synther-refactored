import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';
import '../../config/api_config.dart';
import 'llm_preset_service_stub.dart';

/// A widget for generating synthesizer presets using LLM
class LlmPresetWidget extends StatefulWidget {
  const LlmPresetWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<LlmPresetWidget> createState() => _LlmPresetWidgetState();
}

class _LlmPresetWidgetState extends State<LlmPresetWidget> {
  final TextEditingController _descriptionController = TextEditingController();
  final LlmPresetService _presetService = LlmPresetService();
  bool _isGenerating = false;
  String? _errorMessage;
  String? _presetName;
  String? _presetDescription;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeService() {
    // In production, get API keys from secure storage
    // For prototype, using the default values set in ApiConfig
    _presetService.initialize();
    
    // Inform user which API is being used
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String apiTypeText;
      String statusMessage;
      Color statusColor = Colors.blue;
      
      switch (_presetService.apiType) {
        case ApiType.huggingFace:
          apiTypeText = 'Hugging Face API';
          if (ApiConfig.huggingFaceApiKey == 'YOUR_HF_TOKEN_HERE') {
            statusMessage = 'No HF API key configured - using rule-based fallback';
            statusColor = Colors.orange;
          } else {
            statusMessage = 'Using $apiTypeText for preset generation';
          }
          break;
        case ApiType.groq:
          apiTypeText = 'Groq API (free tier)';
          if (ApiConfig.groqApiKey == 'YOUR_GROQ_API_KEY') {
            statusMessage = 'No Groq API key configured - using rule-based fallback';
            statusColor = Colors.orange;
          } else {
            statusMessage = 'Using $apiTypeText for preset generation';
          }
          break;
        case ApiType.gemini:
          apiTypeText = 'Gemini API';
          if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
            statusMessage = 'No Gemini API key configured - using rule-based fallback';
            statusColor = Colors.orange;
          } else {
            statusMessage = 'Using $apiTypeText for preset generation';
          }
          break;
      }
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusMessage),
          backgroundColor: statusColor,
          duration: const Duration(seconds: 4),
          action: statusColor == Colors.orange ? SnackBarAction(
            label: 'Get API Key',
            textColor: Colors.white,
            onPressed: () {
              // Show dialog with instructions on how to get API keys
              _showApiKeyInstructions();
            },
          ) : null,
        ),
      );
    });
  }

  Future<void> _generatePreset() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a description of the sound you want';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _presetName = null;
      _presetDescription = null;
    });

    try {
      final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
      
      // Log current parameters before generation
      print('[LLM Widget] Current parameters before generation:');
      print('  - Frequency: ${synthParams.oscillators.first.frequency}');
      print('  - Oscillator Type: ${synthParams.oscillators.first.type}');
      print('  - Filter Cutoff: ${synthParams.filterCutoff}');
      print('  - Reverb Mix: ${synthParams.reverbMix}');
      
      final generatedParams = await _presetService.generatePreset(description);

      if (generatedParams != null) {
        // Apply the generated parameters to the synth
        synthParams.loadFromJson(generatedParams.toJson());
        
        // Log new parameters after generation
        print('[LLM Widget] New parameters after generation:');
        print('  - Frequency: ${synthParams.oscillators.first.frequency}');
        print('  - Oscillator Type: ${synthParams.oscillators.first.type}');
        print('  - Filter Cutoff: ${synthParams.filterCutoff}');
        print('  - Reverb Mix: ${synthParams.reverbMix}');
        
        setState(() {
          _presetName = "Generated Preset";
          _presetDescription = "A sound based on: $description";
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preset generated and applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to generate preset. Please try again.';
          _isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isGenerating = false;
      });
    }
  }

  void _showApiKeyInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Getting API Keys'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To use LLM-based preset generation, you need an API key:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildApiKeySection(
                'Hugging Face (Free)',
                '1. Sign up at https://huggingface.co/\n'
                '2. Go to Settings > Access Tokens\n'
                '3. Create a new token\n'
                '4. Copy the token and update api_config.dart',
                ApiType.huggingFace,
              ),
              const SizedBox(height: 16),
              _buildApiKeySection(
                'Groq (Free Tier)',
                '1. Sign up at https://console.groq.com/\n'
                '2. Navigate to API Keys section\n'
                '3. Create a new API key\n'
                '4. Copy the key and update api_config.dart',
                ApiType.groq,
              ),
              const SizedBox(height: 16),
              _buildApiKeySection(
                'Gemini (Paid)',
                '1. Go to https://makersuite.google.com/app/apikey\n'
                '2. Create a new API key\n'
                '3. Copy the key and update api_config.dart',
                ApiType.gemini,
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: For web builds, the app uses a local JavaScript-based generator that works without API keys.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildApiKeySection(String title, String instructions, ApiType apiType) {
    final isSelected = _presetService.apiType == apiType;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.blue, size: 16),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'AI Preset Generator',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description
            const Text(
              'Describe the sound you want to create in natural language, and AI will generate synthesizer parameters to match your description.',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            // Input field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Describe your sound',
                hintText: 'E.g., "A thick bass with some distortion and reverb"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _generatePreset(),
            ),
            
            const SizedBox(height: 16),
            
            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generatePreset,
                icon: _isGenerating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.flash_on),
                label: Text(_isGenerating ? 'Generating...' : 'Generate Preset'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Generated preset info
            if (_presetName != null && _presetDescription != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _presetName!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _presetDescription!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Add some example prompts
            const SizedBox(height: 16),
            const Text(
              'Example prompts:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ExampleChip(
                  label: 'Spacey ambient pad',
                  onTap: () {
                    _descriptionController.text = 'A spacey ambient pad with lots of reverb that slowly evolves';
                  },
                ),
                _ExampleChip(
                  label: 'Punchy bass',
                  onTap: () {
                    _descriptionController.text = 'A punchy bass sound with a quick attack and moderate distortion';
                  },
                ),
                _ExampleChip(
                  label: 'Retro synth lead',
                  onTap: () {
                    _descriptionController.text = 'A retro 80s synth lead with some delay, like from a classic synthwave track';
                  },
                ),
                _ExampleChip(
                  label: 'Dubstep wobble',
                  onTap: () {
                    _descriptionController.text = 'A heavy dubstep wobble bass with aggressive filter modulation';
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Divider(),
            
            // API Selection
            Row(
              children: [
                Text(
                  'LLM API:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                DropdownButton<ApiType>(
                  value: _presetService.apiType,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _presetService.setApiType(value);
                      });
                      
                      final apiName = value == ApiType.huggingFace ? 'Hugging Face' : 'Gemini';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to $apiName API'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ApiType.huggingFace,
                      child: Row(
                        children: [
                          Icon(Icons.public, size: 16),
                          SizedBox(width: 8),
                          Text('Hugging Face (Free)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: ApiType.gemini,
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16),
                          SizedBox(width: 8),
                          Text('Gemini (Paid)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              _presetService.apiType == ApiType.huggingFace
                  ? 'Using free Hugging Face API (Mistral-7B) - may be slower but no API key required'
                  : 'Note: Gemini API requires a valid API key to be configured.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExampleChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
    );
  }
}