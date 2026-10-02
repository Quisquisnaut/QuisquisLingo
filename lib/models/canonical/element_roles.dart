import 'exercise_primitive.dart';

/// Where an element sits in an exercise: in the prompt, or in an item's
/// content (what the learner chooses, orders, places or pairs).
enum ElementPlace { prompt, item }

/// One role QQL reads on an element (Build 261 Revision 6, owner decision
/// of 2 October 2026): its stored [id], the element [types] it applies to,
/// where it sits, whether only a Presentation uses it, and a short English
/// description for the canonical editor's Role menu.
class ElementRole {
  const ElementRole(
    this.id,
    this.description, {
    required this.types,
    this.place = ElementPlace.prompt,
    this.presentation = false,
  });

  /// The value stored in Course JSON (`role`).
  final String id;

  /// One line saying what the role does, for authors.
  final String description;

  /// Element types (`text`, `audio`, `image`, `link`) the role applies to.
  final Set<String> types;

  final ElementPlace place;

  /// True for the roles a Presentation reads (Flashcard, Before you start,
  /// Story line and cover, Page); false for the roles every other
  /// primitive reads. Item roles apply to every primitive with items.
  final bool presentation;
}

/// The roles QQL reads, the one list behind the canonical editor's Role
/// menu (Build 261 Revision 6). Roles are free strings in Course Model v12:
/// a file may carry any role and QQL keeps it, but only these have an
/// effect, so the editor offers only these. When the runtime learns a new
/// role, add it here in the same change.
abstract final class ElementRoles {
  static const all = <ElementRole>[
    // Prompt, every primitive but Presentation.
    ElementRole(
      'primary',
      'The main text. Without a language it is the Instruction or context, '
          'shown in place of the standard instruction; with a language it is '
          'material, such as a text to translate.',
      types: {'text'},
    ),
    ElementRole(
      'question',
      'The question, or the sentence to complete.',
      types: {'text'},
    ),
    ElementRole(
      'passage',
      'A text to read before answering (Read and answer).',
      types: {'text'},
    ),
    ElementRole(
      'situation',
      'A situation to read; the learner chooses the reply.',
      types: {'text'},
    ),
    ElementRole(
      'clue',
      'A clue: the text to translate, or the description of a word to spell.',
      types: {'text'},
    ),
    ElementRole(
      'context',
      'Context shown above the question.',
      types: {'text'},
    ),
    ElementRole(
      'dialogue_turn',
      'One line of a dialogue to read; Speaker says who says it.',
      types: {'text'},
    ),
    ElementRole(
      'primary',
      'What the learner listens to: it plays by itself when Playback is '
          'automatic, else with a button.',
      types: {'audio'},
    ),
    ElementRole(
      'passage',
      'A longer recording to listen to before answering.',
      types: {'audio'},
    ),
    ElementRole(
      'context',
      'Audio context, played with the Play context audio button.',
      types: {'audio'},
    ),
    ElementRole(
      'dialogue_turn',
      'The read-aloud of one dialogue line, in the order of the lines.',
      types: {'audio'},
    ),
    ElementRole(
      'primary',
      'An illustration: a picture shown with the exercise.',
      types: {'image'},
    ),
    ElementRole(
      'clue',
      'An illustration, as presets write it beside a word to translate or '
          'spell.',
      types: {'image'},
    ),
    ElementRole('context', 'An illustration of the context.', types: {'image'}),
    ElementRole(
      'picture',
      'The picture the learner names or answers about (What is in the '
          'picture, Type what you see, Name what you see).',
      types: {'image'},
    ),
    ElementRole(
      'character',
      'A character to recognize (Recognize characters).',
      types: {'image'},
    ),
    // Prompt, Presentation only.
    ElementRole(
      'term',
      'Flashcard: the word or expression.',
      types: {'text'},
      presentation: true,
    ),
    ElementRole(
      'meaning',
      'Flashcard: what it means.',
      types: {'text'},
      presentation: true,
    ),
    ElementRole(
      'usage',
      'Flashcard: an example of use.',
      types: {'text'},
      presentation: true,
    ),
    ElementRole(
      'usage_translation',
      'Flashcard: the translation of the example.',
      types: {'text'},
      presentation: true,
    ),
    ElementRole(
      'audio',
      'Flashcard: the read-aloud of the word.',
      types: {'audio'},
      presentation: true,
    ),
    ElementRole(
      'intro',
      'Before you start card: the note shown before the Round.',
      types: {'text'},
      presentation: true,
    ),
    ElementRole(
      'line',
      'Story dialogue line: what the speaker says.',
      types: {'text', 'audio'},
      presentation: true,
    ),
    ElementRole(
      'title',
      'Story cover: the title line.',
      types: {'text'},
      presentation: true,
    ),
    ElementRole(
      'picture',
      'The picture of a Flashcard or a Story cover.',
      types: {'image'},
      presentation: true,
    ),
    ElementRole(
      'block',
      'Page: one block of the page (its style is set in the Page form).',
      types: {'text', 'audio', 'image', 'link'},
      presentation: true,
    ),
    // Item content, every primitive with items.
    ElementRole(
      'primary',
      'The text of this item.',
      types: {'text'},
      place: ElementPlace.item,
    ),
    ElementRole(
      'icon',
      'An icon key drawn as a picture (Select the image).',
      types: {'text'},
      place: ElementPlace.item,
    ),
    ElementRole(
      'primary',
      'The sound of this item (Match the sounds).',
      types: {'audio'},
      place: ElementPlace.item,
    ),
    ElementRole(
      'primary',
      'The picture of this item.',
      types: {'image'},
      place: ElementPlace.item,
    ),
    ElementRole(
      'character',
      'A character to recognize (Recognize characters).',
      types: {'image'},
      place: ElementPlace.item,
    ),
  ];

  /// The roles offered for an element of [type] in [place] of an exercise
  /// of [primitive], in catalog order.
  static List<ElementRole> offered({
    required String type,
    required ElementPlace place,
    required ExercisePrimitive primitive,
  }) => [
    for (final role in all)
      if (role.place == place &&
          role.types.contains(type) &&
          (place == ElementPlace.item ||
              role.presentation ==
                  (primitive == ExercisePrimitive.presentation)))
        role,
  ];

  /// The offered role [id], or null when it is not offered here.
  static ElementRole? find(
    String id, {
    required String type,
    required ElementPlace place,
    required ExercisePrimitive primitive,
  }) {
    for (final role in offered(
      type: type,
      place: place,
      primitive: primitive,
    )) {
      if (role.id == id) return role;
    }
    return null;
  }

  /// Why a stored role [id] is not offered for this element: another
  /// primitive uses it, or QQL reads it nowhere.
  static String notOfferedNote(
    String id, {
    required String type,
    required ElementPlace place,
  }) {
    final elsewhere = all.any(
      (role) =>
          role.id == id && role.place == place && role.types.contains(type),
    );
    return elsewhere ? 'not used by this primitive' : 'not a QQL role';
  }
}
