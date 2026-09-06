import 'dart:io';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../screens/flat_image_library_screen.dart';
import '../services/exercise_image_service.dart';
import '../services/exercise_field_help.dart';
import '../services/portable_exercise_image.dart';
import 'portable_exercise_image.dart';

enum ScriptRecognitionMode { imageToText, textToImage }

/// Owns the unsaved canonical Select fields, including stable option identities.
class ScriptRecognitionController extends ChangeNotifier {
  ScriptRecognitionController(Exercise exercise) : _original = exercise {
    _mode =
        exercise.interaction.items.any(
              (item) => item.content.any((element) => element.type == 'image'),
            ) ||
            (exercise.interaction.items.isEmpty &&
                exercise.prompt.trim().isNotEmpty &&
                !exercise.promptElements.any(
                  (element) => element.type == 'image',
                ))
        ? ScriptRecognitionMode.textToImage
        : ScriptRecognitionMode.imageToText;
    _initialMode = _mode;
    _textPrompt = exercise.promptElements.indexWhere(
      (element) => element.type == 'text' && element.role == 'primary',
    );
    if (_textPrompt < 0) {
      _textPrompt = exercise.promptElements.indexWhere(
        (element) => element.type == 'text',
      );
    }
    prompt = TextEditingController(
      text: _textPrompt < 0 ? '' : exercise.promptElements[_textPrompt].text,
    )..addListener(notifyListeners);
    _promptImages.addAll(
      exercise.promptElements.where((element) => element.type == 'image'),
    );
    _usedIds.addAll(exercise.interaction.items.map((item) => item.id));
    for (final item in exercise.interaction.items) {
      _options.add(_ScriptOption(item, notifyListeners));
    }
    _correctIds.addAll(exercise.evaluation.correctItemIds);
  }

  final Exercise _original;
  late final TextEditingController prompt;
  late int _textPrompt;
  late ScriptRecognitionMode _mode;
  late final ScriptRecognitionMode _initialMode;
  final List<PromptElement> _promptImages = [];
  final List<_ScriptOption> _options = [];
  final Set<String> _usedIds = {};
  final List<String> _correctIds = [];
  int _nextId = 1;

  ScriptRecognitionMode get mode => _mode;
  List<PromptElement> get promptImages => List.unmodifiable(_promptImages);
  int get optionCount => _options.length;
  TextEditingController optionText(int index) => _options[index].text;
  String optionImage(int index) => _options[index].image;
  String optionId(int index) => _options[index].original.id;
  bool isCorrect(int index) => _correctIds.contains(optionId(index));

  void setMode(ScriptRecognitionMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void addPromptImage(String asset) {
    _promptImages.add(PromptElement(type: 'image', asset: asset));
    notifyListeners();
  }

  void removePromptImage(int index) {
    _promptImages.removeAt(index);
    notifyListeners();
  }

  void replacePromptImage(int index, String asset) {
    final previous = _promptImages[index];
    _promptImages[index] = PromptElement(
      role: previous.role,
      type: previous.type,
      text: previous.text,
      asset: asset,
      speaker: previous.speaker,
    );
    notifyListeners();
  }

  void addOption() {
    String id;
    do {
      id = 'script_option_${_nextId++}';
    } while (_usedIds.contains(id));
    _usedIds.add(id);
    _options.add(
      _ScriptOption(ExerciseItem(id: id, content: const []), notifyListeners),
    );
    notifyListeners();
  }

  void removeOption(int index) {
    final removed = _options.removeAt(index);
    _correctIds.removeWhere((id) => id == removed.original.id);
    removed.dispose();
    notifyListeners();
  }

  void moveOption(int from, int to) {
    if (from == to) return;
    final option = _options.removeAt(from);
    _options.insert(to, option);
    notifyListeners();
  }

  void setCorrect(int index) {
    _correctIds
      ..clear()
      ..add(optionId(index));
    notifyListeners();
  }

  void setOptionImage(int index, String asset) {
    _options[index].image = asset;
    notifyListeners();
  }

  Exercise build(PublicationState publicationState) {
    final elements = <PromptElement>[];
    var imageIndex = 0;
    for (var index = 0; index < _original.promptElements.length; index++) {
      final original = _original.promptElements[index];
      if (original.type == 'image') {
        if ((_mode == ScriptRecognitionMode.imageToText ||
                _mode == _initialMode) &&
            imageIndex < _promptImages.length) {
          elements.add(_promptImages[imageIndex++]);
        }
      } else if (index == _textPrompt) {
        elements.add(
          PromptElement(
            role: original.role,
            type: original.type,
            text: prompt.text,
            asset: original.asset,
            speaker: original.speaker,
          ),
        );
      } else {
        elements.add(original);
      }
    }
    if (_textPrompt < 0 &&
        (prompt.text.isNotEmpty ||
            _mode == ScriptRecognitionMode.textToImage)) {
      elements.add(PromptElement(type: 'text', text: prompt.text));
    }
    if (_mode == ScriptRecognitionMode.imageToText) {
      elements.addAll(_promptImages.skip(imageIndex));
    }
    return Exercise.v2(
      id: _original.id,
      publicationState: publicationState,
      updatedAt: _original.updatedAt,
      editorTemplate: 'script_recognition',
      promptElements: elements,
      interaction: ExerciseInteraction(
        kind: 'select',
        inputType: _original.interaction.inputType,
        minSelections: _original.interaction.minSelections,
        maxSelections: _original.interaction.maxSelections,
        items: _options
            .map((option) => option.build(_mode, _mode != _initialMode))
            .toList(),
      ),
      evaluation: ExerciseEvaluation(
        kind: 'selected_items',
        correctItemIds: List.of(_correctIds),
        accepted: _original.evaluation.accepted,
        correctOrders: _original.evaluation.correctOrders,
        pairs: _original.evaluation.pairs,
        normalization: _original.evaluation.normalization,
      ),
      hint: _original.hint,
      feedback: _original.feedback,
      missingWords: _original.missingWords,
    );
  }

  @override
  void dispose() {
    prompt.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }
}

class _ScriptOption {
  _ScriptOption(this.original, VoidCallback onChanged)
    : text = TextEditingController(text: original.text),
      image = original.image {
    text.addListener(onChanged);
  }

  final ExerciseItem original;
  final TextEditingController text;
  String image;

  ExerciseItem build(ScriptRecognitionMode mode, bool modeChanged) {
    final desiredType = mode == ScriptRecognitionMode.imageToText
        ? 'text'
        : 'image';
    var replaced = false;
    final elements = <PromptElement>[];
    for (final element in original.content) {
      // The alternate mode stays in the controller until the user saves.
      if (modeChanged &&
          element.type == (desiredType == 'text' ? 'image' : 'text')) {
        continue;
      }
      if (element.type == desiredType && !replaced) {
        replaced = true;
        elements.add(
          PromptElement(
            role: element.role,
            type: element.type,
            text: desiredType == 'text' ? text.text : element.text,
            asset: desiredType == 'image' ? image : element.asset,
            speaker: element.speaker,
          ),
        );
      } else {
        elements.add(element);
      }
    }
    if (!replaced) {
      elements.add(
        PromptElement(
          type: desiredType,
          text: desiredType == 'text' ? text.text : '',
          asset: desiredType == 'image' ? image : '',
        ),
      );
    }
    return ExerciseItem(id: original.id, content: elements);
  }

  void dispose() => text.dispose();
}

class ScriptRecognitionEditor extends StatelessWidget {
  const ScriptRecognitionEditor({super.key, required this.controller});

  final ScriptRecognitionController controller;

  Widget _help(BuildContext context, String fieldKey) {
    final help = ExerciseFieldHelpRegistry.forEditorField(
      'script_recognition',
      fieldKey,
    );
    return IconButton(
      key: ValueKey('exercise-field-help-$fieldKey'),
      tooltip: help.purpose,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(help.title),
          content: SingleChildScrollView(child: Text(help.text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      icon: const Icon(Icons.help_outline),
    );
  }

  Future<String?> _pickImage(BuildContext context) async {
    final source = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose character image'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'bundled'),
            child: const Text('Choose from Image Bank'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'import'),
            child: const Text('Import portable image'),
          ),
        ],
      ),
    );
    if (source == null || !context.mounted) return null;
    try {
      if (source == 'bundled') {
        final asset = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => const FlatImageLibraryScreen(readOnly: true),
          ),
        );
        if (asset == null) return null;
        if (PortableExerciseImageService.isPortable(asset)) return asset;
        // Existing locally imported bank images become course-owned bytes.
        return await PortableExerciseImageService.fromFile(File(asset));
      }
      final directory = await ExerciseImageService().fixedImportDirectory();
      final files = await directory
          .list(followLinks: false)
          .where((entry) => entry is File)
          .cast<File>()
          .where(
            (file) => const {
              'png',
              'jpg',
              'jpeg',
              'webp',
            }.contains(file.path.toLowerCase().split('.').last),
          )
          .toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      if (files.isEmpty) {
        throw StateError(
          'Copy a PNG, JPEG or WEBP image to ${directory.path}, then try again. '
          'Each image must be at most 50 KB.',
        );
      }
      if (!context.mounted) return null;
      final picked = files.length == 1
          ? files.single
          : await showDialog<File>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Choose image to import'),
                children: [
                  for (final file in files)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, file),
                      child: Text(file.uri.pathSegments.last),
                    ),
                ],
              ),
            );
      return picked == null
          ? null
          : await PortableExerciseImageService.fromFile(picked);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image could not be loaded: $error')),
        );
      }
      return null;
    }
  }

  Widget _image(BuildContext context, String asset, String label) => Tooltip(
    message: label,
    child: asset.isEmpty
        ? const SizedBox(
            width: 96,
            height: 96,
            child: Icon(Icons.image_outlined),
          )
        : PortableExerciseImage(asset: asset, width: 96, height: 96),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Each item pairs a character image with its corresponding text.\n\n'
          'Image to text: learners see a character image and choose the matching text.\n\n'
          'Text to image: learners see the text and choose the matching character image.\n\n'
          'The text can be the character’s name, sound, pronunciation, transliteration or another identifying label.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ScriptRecognitionMode>(
          key: const ValueKey('script-mode'),
          initialValue: controller.mode,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Recognition mode',
            suffixIcon: _help(context, 'scriptMode'),
          ),
          items: const [
            DropdownMenuItem(
              value: ScriptRecognitionMode.imageToText,
              child: Text('Image to text'),
            ),
            DropdownMenuItem(
              value: ScriptRecognitionMode.textToImage,
              child: Text('Text to image'),
            ),
          ],
          onChanged: (mode) {
            if (mode != null) controller.setMode(mode);
          },
        ),
        const SizedBox(height: 8),
        Text(
          key: const ValueKey('script-mode-explanation'),
          controller.mode == ScriptRecognitionMode.imageToText
              ? 'Learners see an image and choose the matching text.'
              : 'Learners see text and choose the matching image.',
        ),
        Text(
          controller.mode == ScriptRecognitionMode.imageToText
              ? 'Show one or more images of the same character or syllable, '
                    'with at least two text options and exactly one correct option.'
              : 'Enter a text prompt and choose at least two image options, '
                    'with exactly one correct option.',
        ),
        const Text(
          'Switching modes keeps both sets of fields for this editing session. '
          'Saving uses only the selected mode. Imported images are stored with '
          'the course; use PNG, JPEG or WEBP up to 50 KB.',
        ),
        const SizedBox(height: 12),
        if (controller.mode == ScriptRecognitionMode.textToImage)
          TextField(
            key: const ValueKey('script-prompt'),
            controller: controller.prompt,
            decoration: InputDecoration(
              labelText: 'Text prompt',
              suffixIcon: _help(context, 'scriptPrompt'),
            ),
            minLines: 1,
            maxLines: 3,
          )
        else ...[
          Row(
            children: [
              const Expanded(child: Text('Prompt images')),
              _help(context, 'scriptPromptImages'),
            ],
          ),
          for (var i = 0; i < controller.promptImages.length; i++)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                _image(
                  context,
                  controller.promptImages[i].asset,
                  'Prompt image ${i + 1}',
                ),
                TextButton(
                  onPressed: () async {
                    final asset = await _pickImage(context);
                    if (asset != null && context.mounted) {
                      controller.replacePromptImage(i, asset);
                    }
                  },
                  child: Text('Replace image ${i + 1}'),
                ),
                IconButton(
                  tooltip: 'Remove prompt image ${i + 1}',
                  onPressed: () => controller.removePromptImage(i),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          TextButton.icon(
            key: const ValueKey('script-add-prompt-image'),
            onPressed: () async {
              final asset = await _pickImage(context);
              if (asset != null && context.mounted) {
                controller.addPromptImage(asset);
              }
            },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add prompt image'),
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < controller.optionCount; i++)
          Card(
            key: ValueKey('script-option-${controller.optionId(i)}'),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.mode == ScriptRecognitionMode.imageToText)
                    TextField(
                      key: ValueKey('script-option-text-$i'),
                      controller: controller.optionText(i),
                      decoration: InputDecoration(
                        labelText: 'Option ${i + 1}',
                        suffixIcon: _help(context, 'scriptTextOptions'),
                      ),
                    )
                  else
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _image(
                          context,
                          controller.optionImage(i),
                          'Option ${i + 1}',
                        ),
                        TextButton(
                          key: ValueKey('script-option-image-$i'),
                          onPressed: () async {
                            final asset = await _pickImage(context);
                            if (asset != null && context.mounted) {
                              controller.setOptionImage(i, asset);
                            }
                          },
                          child: Text('Choose image for option ${i + 1}'),
                        ),
                        _help(context, 'scriptImageOptions'),
                      ],
                    ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        key: ValueKey('script-correct-$i'),
                        tooltip: controller.isCorrect(i)
                            ? 'Correct option ${i + 1}'
                            : 'Mark option ${i + 1} correct',
                        isSelected: controller.isCorrect(i),
                        onPressed: () => controller.setCorrect(i),
                        icon: Icon(
                          controller.isCorrect(i)
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                      ),
                      const Text('Correct'),
                      _help(context, 'scriptCorrect'),
                      IconButton(
                        tooltip: 'Move option ${i + 1} up',
                        onPressed: i == 0
                            ? null
                            : () => controller.moveOption(i, i - 1),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Move option ${i + 1} down',
                        onPressed: i + 1 == controller.optionCount
                            ? null
                            : () => controller.moveOption(i, i + 1),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      IconButton(
                        tooltip: 'Delete option ${i + 1}',
                        onPressed: () => controller.removeOption(i),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          key: const ValueKey('script-add-option'),
          onPressed: controller.addOption,
          icon: const Icon(Icons.add),
          label: const Text('Add answer option'),
        ),
      ],
    ),
  );
}
