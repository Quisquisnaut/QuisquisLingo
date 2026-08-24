import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/course_models.dart';

/// Manages creator-supplied recorded speech. Imported MP3 files are copied into
/// app-owned storage so moving or deleting the creator's original file does not
/// break the local course. Course packaging can later export this directory as
/// an optional audio pack.
class RecordedAudioService {
  Future<Directory> fixedImportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Imports${Platform.pathSeparator}Audio',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<List<CourseAudioClip>> importMp3Files(String courseCode) async {
    final importDir = await fixedImportDirectory();
    final sources = await importDir
        .list(followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => file.path.toLowerCase().endsWith('.mp3'))
        .toList();
    sources.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    if (sources.isEmpty) {
      throw StateError('No MP3 files found in ${importDir.path}. Copy the MP3 files you want to import there and try again.');
    }
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}quisquislingo_audio${Platform.pathSeparator}${courseCode.toLowerCase()}');
    await dir.create(recursive: true);
    final out = <CourseAudioClip>[];
    for (final source in sources) {
      final size = await source.length();
      if (size > 50 * 1024 * 1024) { throw StateError('MP3 files larger than 50 MB are not accepted.'); }
      final sourceName = source.uri.pathSegments.last;
      final safeName = sourceName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final destination = '${dir.path}${Platform.pathSeparator}${stamp}_$safeName';
      await source.copy(destination);
      out.add(CourseAudioClip(id:'audio_$stamp', text:'', filePath:destination));
    }
    return out;
  }

  List<CourseAudioClip> orphaned(Course course) => course.audioLibrary.where((c)=>c.text.trim().isEmpty).toList();

  Future<void> deleteFiles(Iterable<CourseAudioClip> clips) async {
    for (final clip in clips) {
      try { final f=File(clip.filePath); if(await f.exists()) await f.delete(); } catch (_) {}
    }
  }

  /// Longest-match segmentation prevents a single-word recording from taking
  /// precedence over an available multi-word expression.
  List<CourseAudioClip>? segment(String text,List<CourseAudioClip> library) {
    final words=text.trim().split(RegExp(r'\s+')); if(words.isEmpty)return const [];
    final byText={for(final c in library.where((c)=>c.text.trim().isNotEmpty))c.text.trim().toLowerCase():c};
    final out=<CourseAudioClip>[]; var i=0;
    while(i<words.length){CourseAudioClip? found;int foundLen=0;
      for(var len=words.length-i;len>=1;len--){
        final raw=words.sublist(i,i+len).join(' ').replaceAll(RegExp(r'^[^\wÀ-ÿ]+|[^\wÀ-ÿ]+$'), '').toLowerCase();
        if(byText.containsKey(raw)){found=byText[raw];foundLen=len;break;}
      }
      if(found==null)return null; out.add(found);i+=foundLen;
    }
    return out;
  }

  Source? sourceForClip(CourseAudioClip clip) {
    final path=clip.filePath.trim();
    if(path.isEmpty)return null;
    // Bundled course recordings are Flutter assets, not normal filesystem
    // files on Android/iOS. AssetSource expects the path below assets/.
    if(path.startsWith('assets/'))return AssetSource(path.substring('assets/'.length));
    final file=File(path);
    if(!file.existsSync())return null;
    return DeviceFileSource(path);
  }

  Future<bool> playConcatenated(String text,List<CourseAudioClip> library,{Duration gap=const Duration(milliseconds:90)}) async {
    final clips=segment(text,library); if(clips==null||clips.isEmpty)return false;
    final player=AudioPlayer();
    try {
      for(final clip in clips){
        final source=sourceForClip(clip);if(source==null)return false;
        await player.play(source);await player.onPlayerComplete.first;await Future<void>.delayed(gap);
      }
      return true;
    } catch(_){return false;} finally {await player.dispose();}
  }
}
