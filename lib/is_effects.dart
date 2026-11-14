/// The shared vocabulary of effects: what reading, writing, starting a
/// program and sending out of the home take and give back, and the drivers
/// that carry them out.
///
/// Tools describe effects in these words, the airlock decides on them, and
/// drivers carry them out. A driver depends on this alone, so it sees no
/// run, journey path or decision.
library;

export 'src/drivers.dart';
export 'src/relative_path.dart';
export 'src/values.dart';
export 'src/web.dart';
