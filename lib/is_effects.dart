/// The shared vocabulary of actions: what reading, writing, starting a
/// program, reaching the world and calling the model take and give back,
/// and the drivers that carry them out.
///
/// Tools describe actions in these words, the airlock decides on them, and
/// drivers carry them out. A driver is given only the action's program and
/// input; the trajectory, the decision and what follows stay with the
/// airlock.
library;

// Re-exported so Origin, WebPath, PathPrefix and AddressPrefix stay one type
// whichever package a caller imports them from.
export 'package:is_web_address_vocabulary/is_web_address_vocabulary.dart';

export 'src/bot_pool.dart';
export 'src/drivers.dart';
export 'src/file.dart';
export 'src/model.dart';
export 'src/outcome.dart';
export 'src/program.dart';
export 'src/relative_path.dart';
export 'src/web.dart';
export 'src/wire.dart';
