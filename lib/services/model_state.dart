import 'package:flutter/foundation.dart';
import 'model_service.dart';

class ModelState {
  static final ModelState _instance = ModelState._internal();
  factory ModelState() => _instance;
  ModelState._internal();

  final ValueNotifier<String?> _selectedModelId = ValueNotifier<String?>(null);
  ValueNotifier<String?> get selectedModelId => _selectedModelId;

  Future<void> init() async {
    final selectedId = await ModelService.getSelectedModel();
    _selectedModelId.value = selectedId;
  }

  Future<void> setSelectedModel(String id) async {
    await ModelService.setSelectedModel(id);
    _selectedModelId.value = id;
  }

  Future<void> clearSelectedModel() async {
    await ModelService.clearSelectedModel();
    _selectedModelId.value = null;
  }
}