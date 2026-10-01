import 'learner_panel_en.dart';
import 'learner_panel_es.dart';
import 'learner_panel_it.dart';
import 'learner_panel_de.dart';
import 'learner_panel_pt.dart';
import 'learner_panel_nl.dart';
import 'learner_panel_fr.dart';

/// The learner panel catalogs by instruction language (Build 260 Revision
/// 1). English is complete; another language falls back to it per key.
const learnerPanelCatalogs = <String, Map<String, String>>{
  'en': learnerPanelEn,
  'es': learnerPanelEs,
  'it': learnerPanelIt,
  'de': learnerPanelDe,
  'pt': learnerPanelPt,
  'nl': learnerPanelNl,
  'fr': learnerPanelFr,
};
