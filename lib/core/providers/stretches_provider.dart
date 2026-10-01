import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';
import 'package:fitness_app/services/stretch_service.dart';

final stretchServiceProvider = Provider<StretchService>(
  (ref) => StretchService(),
);

/// The full stretch library from `GET /api/stretches`, which the routine
/// builder's picker needs for each stretch's id and `poseKey`.
final stretchesProvider = FutureProvider.autoDispose<List<StretchModel>>(
  (ref) => ref.watch(stretchServiceProvider).fetchStretches(),
);
