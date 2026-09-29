import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// The QuisquisLingo mascot pictures bundled under `assets/mascots/`. The
/// learner Round path shows every one of them; exercises show all but the
/// ones `ExerciseMascotPolicy.excludedAssets` leaves out (Build 256
/// Revision 9).
const learnerMascotAssetDirectory = 'assets/mascots/';

List<String> learnerMascotAssetsFromManifest(Iterable<String> assets) {
  final mascots = assets
      .where(
        (asset) =>
            asset.startsWith(learnerMascotAssetDirectory) &&
            asset.toLowerCase().endsWith('.png'),
      )
      .toSet()
      .toList();
  mascots.sort();
  return mascots;
}

Future<List<String>> loadLearnerMascotAssets(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  return loadRenderableLearnerMascotAssets(bundle, manifest.listAssets());
}

Future<List<String>>? _productionLearnerMascotAssetsFuture;

Future<List<String>> loadProductionLearnerMascotAssets() =>
    _productionLearnerMascotAssetsFuture ??= loadLearnerMascotAssets(
      rootBundle,
    );

Future<List<String>> loadRenderableLearnerMascotAssets(
  AssetBundle bundle,
  Iterable<String> assets,
) async {
  final renderable = <String>[];
  for (final asset in learnerMascotAssetsFromManifest(assets)) {
    ui.Codec? codec;
    ui.Image? image;
    try {
      final data = await bundle.load(asset);
      codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: 1,
        targetHeight: 1,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      renderable.add(asset);
    } catch (_) {
      // An invalid mascot leaves no slot and never enters the selection cycle.
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
  return renderable;
}
