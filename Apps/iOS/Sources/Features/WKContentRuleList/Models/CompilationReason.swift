enum CompilationReason {
    case initialLoad
    case newTDS
    case whitelistUpdated(added: [String], removed: [String])
} 