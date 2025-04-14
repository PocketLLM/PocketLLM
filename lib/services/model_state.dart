import 'package:flutter/foundation.dart';
import 'model_service.dart';

class ModelState {
  static final ModelState _instance = ModelState._internal();
  factory ModelState() => _instance;
  ModelState._internal();

  final ValueNotifier<String?> _selectedModelId = ValueNotifier<String?>(null);
  ValueNotifier<String?> get selectedModelId => _selectedModelId;
  
  final ModelService _modelService = ModelService();

  Future<void> init() async {
    try {
      final selectedId = await _modelService.getDefaultModelId();
      debugPrint('ModelState: Initialized with selected model ID: $selectedId');
      _selectedModelId.value = selectedId;
      
      if (selectedId != null) {
        // Verify the model exists
        final models = await _modelService.getSavedModels();
        final modelExists = models.any((model) => model.id == selectedId);
        if (!modelExists) {
          debugPrint('ModelState: Warning - Selected model ID $selectedId does not exist in saved models');
        } else {
          final model = models.firstWhere((model) => model.id == selectedId);
          debugPrint('ModelState: Using model: ${model.name} (${model.provider})');
        }
      } else {
        debugPrint('ModelState: No model selected');
      }
    } catch (e) {
      debugPrint('ModelState: Error initializing: $e');
    }
  }

  Future<void> setSelectedModel(String id) async {
    try {
      debugPrint('ModelState: Setting selected model ID to: $id');
      await _modelService.setDefaultModel(id);
      _selectedModelId.value = id;
      
      // Verify the model exists
      final models = await _modelService.getSavedModels();
      final modelExists = models.any((model) => model.id == id);
      if (!modelExists) {
        debugPrint('ModelState: Warning - Selected model ID $id does not exist in saved models');
      } else {
        final model = models.firstWhere((model) => model.id == id);
        debugPrint('ModelState: Now using model: ${model.name} (${model.provider})');
      }
    } catch (e) {
      debugPrint('ModelState: Error setting selected model: $e');
    }
  }

  Future<void> clearSelectedModel() async {
    try {
      debugPrint('ModelState: Clearing selected model');
      // Remove the default model by setting it to null
      await _modelService.setDefaultModel('');
      _selectedModelId.value = null;
    } catch (e) {
      debugPrint('ModelState: Error clearing selected model: $e');
    }
  }
}