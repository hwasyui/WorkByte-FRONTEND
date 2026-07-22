/// Currency codes a client can pick when posting a job (see job_roles.dart)
/// and, by extension, anywhere a job's currency needs to be re-entered or
/// re-picked (e.g. contract generation) — kept as a single source of truth
/// so the two lists can't drift apart.
const List<String> kSupportedCurrencies = ['IDR', 'USD', 'EUR', 'SGD', 'AUD', 'MYR'];
