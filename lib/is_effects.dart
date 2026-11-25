/// The shared vocabulary of actions: what reading, writing, starting a
/// program, reaching the world and calling the model take and give back,
/// and the drivers that carry them out.
///
/// Tools describe actions in these words, the airlock decides on them, and
/// drivers carry them out. A driver is given only the action's program and
/// input; the trajectory, the decision and what follows stay with the
/// airlock.
library;

// Re-exported so SignIn, Origin, WebPath, PathPrefix, AddressPrefix, the
// reply endpoints and the model's replies stay one type whichever package a
// caller imports them from.
//
// A reply is recorded as Ran even when cut off or proposing tools: tokens
// were spent and a reply came back. Only the reply and what a proposal of
// tools carries come through here; the turns and the request are imported
// from is_model_vocabulary itself, since airlock_api has a ModelRequest of
// its own.
export 'package:is_model_vocabulary/is_model_vocabulary.dart'
    show
        CalledToolName,
        CutOffReply,
        FinishedReply,
        IllFormedName,
        ModelReply,
        ModelUsage,
        ProposedToolCalls,
        ProviderContinuation,
        ToolCall,
        ToolCallId,
        ToolInput,
        ToolName,
        WellFormedName;
export 'package:is_reply_vocabulary/is_reply_vocabulary.dart';
export 'package:is_sign_in_vocabulary/is_sign_in_vocabulary.dart';
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
