import Base

# Formal model for Syrius WalletConnect v2 protocol, verification,
# namespace negotiation, signing domain separation, block validation,
# signer authorization, post-confirmation TOCTOU revalidation, and UI
# revision guards.
#
# Mirrors:
#   - lib/utils/wallet_connect_uri_utils.dart
#   - lib/utils/wallet_connect_request_utils.dart
#   - lib/rearchitecture/utils/wallet_connect_metadata_utils.dart
#   - lib/services/web3wallet_service.dart (namespace helpers)
#   - lib/services/nom_service.dart
#   - lib/rearchitecture/features/wallet_connect_uri/view/wallet_connect_uri_card.dart

# ---------------------------------------------------------------------------
# 1. WalletConnect v2 URI validation & extraction
# ---------------------------------------------------------------------------

type WcUriSource is Data:
  DirectWc{}
  PercentEncodedOnce{}
  PercentEncodedTwice{}
  QueryUriParam{}
  RegexUriFallback{}
  NonWcInput{}

type WcUriCandidate is Data:
  WcUriCandidate{
    source: WcUriSource,
    has_windows_slash_query: Bool,
    has_outer_whitespace: Bool,
    version: Nat,
    topic_non_empty: Bool,
    relay_protocol_non_empty: Bool,
    sym_key_non_empty: Bool
  }

type WcUriExtractResult is Data:
  UriRejected{}
  UriExtracted{
    version: Nat,
    topic_non_empty: Bool,
    relay_protocol_non_empty: Bool,
    sym_key_non_empty: Bool
  }

def is_valid_wc_v2_fields(
  +version: Nat,
  +topic_non_empty: Bool,
  +relay_protocol_non_empty: Bool,
  +sym_key_non_empty: Bool
) -> Bool:
  Bool.and(
    Nat.is_eq(version, 2n),
    Bool.and(
      topic_non_empty,
      Bool.and(relay_protocol_non_empty, sym_key_non_empty)
    )
  )

def cand_has_valid_v2_fields(+cand: WcUriCandidate) -> Bool:
  match cand:
    case WcUriCandidate{_, _, _, +v, +t, +r, +s}:
      is_valid_wc_v2_fields(v, t, r, s)

def extract_wc_uri.check(
  +version: Nat,
  +topic_non_empty: Bool,
  +relay_protocol_non_empty: Bool,
  +sym_key_non_empty: Bool,
  +valid: Bool
) -> WcUriExtractResult:
  match valid:
    case True{}:
      UriExtracted{version, topic_non_empty, relay_protocol_non_empty, sym_key_non_empty}
    case False{}:
      UriRejected{}

def extract_wc_uri.win(
  +slash_blocked: Bool,
  +version: Nat,
  +topic_non_empty: Bool,
  +relay_protocol_non_empty: Bool,
  +sym_key_non_empty: Bool
) -> WcUriExtractResult:
  match slash_blocked:
    case True{}:
      UriRejected{}
    case False{}:
      extract_wc_uri.check(
        version,
        topic_non_empty,
        relay_protocol_non_empty,
        sym_key_non_empty,
        is_valid_wc_v2_fields(version, topic_non_empty, relay_protocol_non_empty, sym_key_non_empty)
      )

def extract_wc_uri(+cand: WcUriCandidate, +is_windows: Bool) -> WcUriExtractResult:
  match cand:
    case WcUriCandidate{src, +has_slash_q, _, +v, +t, +r, +s}:
      match src:
        case NonWcInput{}:
          UriRejected{}
        case DirectWc{}:
          extract_wc_uri.win(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s)
        case PercentEncodedOnce{}:
          extract_wc_uri.win(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s)
        case PercentEncodedTwice{}:
          extract_wc_uri.win(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s)
        case QueryUriParam{}:
          extract_wc_uri.win(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s)
        case RegexUriFallback{}:
          extract_wc_uri.win(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s)

def is_wc_uri_extracted(+res: WcUriExtractResult) -> Bool:
  match res:
    case UriRejected{}:
      False{}
    case UriExtracted{_, _, _, _}:
      True{}

def reextract_wc_uri(+res: WcUriExtractResult, +is_windows: Bool) -> WcUriExtractResult:
  match res:
    case UriRejected{}:
      UriRejected{}
    case UriExtracted{+v, +t, +r, +s}:
      extract_wc_uri(WcUriCandidate{DirectWc{}, False{}, False{}, v, t, r, s}, is_windows)

# ---------------------------------------------------------------------------
# 2. Canonical request identity & error mapping
# ---------------------------------------------------------------------------

type RequestKey is Data:
  ReqKeyById{method: Nat, topic: Nat, request_id: Nat}
  ReqKeyByFingerprint{method: Nat, topic: Nat, params_fp: Nat}

def interactive_request_key(
  +method: Nat,
  +topic: Nat,
  +params_fp: Nat,
  +request_id: Maybe<&2, Nat>
) -> RequestKey:
  match request_id:
    case Some{+rid}:
      ReqKeyById{method, topic, rid}
    case None{}:
      ReqKeyByFingerprint{method, topic, params_fp}

def request_key_eq(+a: RequestKey, +b: RequestKey) -> Bool:
  match a b:
    case ReqKeyById{+m1, +t1, +r1} ReqKeyById{+m2, +t2, +r2}:
      Bool.and(Nat.is_eq(m1, m2), Bool.and(Nat.is_eq(t1, t2), Nat.is_eq(r1, r2)))
    case ReqKeyByFingerprint{+m1, +t1, +f1} ReqKeyByFingerprint{+m2, +t2, +f2}:
      Bool.and(Nat.is_eq(m1, m2), Bool.and(Nat.is_eq(t1, t2), Nat.is_eq(f1, f2)))
    case _ _:
      False{}

type KnownErrorKind is Data:
  KindJsonRpc{}
  KindReownSign{}
  KindReownCore{}

type WcHandlerError is Data:
  ErrJsonRpc{code: U32}
  ErrReownSign{code: U32}
  ErrReownCore{code: U32}
  ErrUnknown{}

def make_known_error(+kind: KnownErrorKind, +code: U32) -> WcHandlerError:
  match kind:
    case KindJsonRpc{}:
      ErrJsonRpc{code}
    case KindReownSign{}:
      ErrReownSign{code}
    case KindReownCore{}:
      ErrReownCore{code}

def wc_error_to_json_rpc_code(+err: WcHandlerError) -> U32:
  match err:
    case ErrJsonRpc{+code}:
      code
    case ErrReownSign{+code}:
      code
    case ErrReownCore{+code}:
      code
    case ErrUnknown{}:
      5000

# ---------------------------------------------------------------------------
# 3. Verify API & metadata sanitization
# ---------------------------------------------------------------------------

type VerifyValidation is Data:
  ValValid{}
  ValInvalid{}
  ValUnknown{}
  ValScam{}

type VerifyContext is Data:
  NoVerifyContext{}
  HasVerifyContext{is_scam_flag: Bool, validation: VerifyValidation}

type VerifySeverity is Data:
  SevVerified{}
  SevUnverified{}
  SevInvalid{}
  SevScam{}

def validation_is_scam(+v: VerifyValidation) -> Bool:
  match v:
    case ValScam{}:
      True{}
    case ValValid{}:
      False{}
    case ValInvalid{}:
      False{}
    case ValUnknown{}:
      False{}

def is_verify_scam(+ctx: VerifyContext) -> Bool:
  match ctx:
    case NoVerifyContext{}:
      False{}
    case HasVerifyContext{+is_scam_flag, +validation}:
      Bool.or(is_scam_flag, validation_is_scam(validation))

def describe_verify_context(+ctx: VerifyContext) -> VerifySeverity:
  match ctx:
    case NoVerifyContext{}:
      SevUnverified{}
    case HasVerifyContext{+is_scam_flag, +validation}:
      match is_scam_flag:
        case True{}:
          SevScam{}
        case False{}:
          match validation:
            case ValScam{}:
              SevScam{}
            case ValUnknown{}:
              SevUnverified{}
            case ValInvalid{}:
              SevInvalid{}
            case ValValid{}:
              SevVerified{}

def severity_rank(+sev: VerifySeverity) -> Nat:
  match sev:
    case SevVerified{}:
      0n
    case SevUnverified{}:
      1n
    case SevInvalid{}:
      2n
    case SevScam{}:
      3n

type UrlScheme is Data:
  SchemeHttp{}
  SchemeHttps{}
  SchemeJavascript{}
  SchemeFile{}
  SchemeData{}
  SchemeOther{}

type ParsedUrl is Data:
  UrlMissingOrMalformed{}
  UrlParsed{scheme: UrlScheme, has_authority: Bool, host_non_empty: Bool}

type UrlSanitizeResult is Data:
  UrlBlocked{}
  UrlAllowed{scheme: UrlScheme}

def is_http_or_https(+s: UrlScheme) -> Bool:
  match s:
    case SchemeHttp{}:
      True{}
    case SchemeHttps{}:
      True{}
    case SchemeJavascript{}:
      False{}
    case SchemeFile{}:
      False{}
    case SchemeData{}:
      False{}
    case SchemeOther{}:
      False{}

def parsed_url_is_valid_http(+u: ParsedUrl) -> Bool:
  match u:
    case UrlMissingOrMalformed{}:
      False{}
    case UrlParsed{+s, +has_auth, +host_ok}:
      Bool.and(is_http_or_https(s), Bool.and(has_auth, host_ok))

def sanitize_http_url.pick(+s: UrlScheme, +ok: Bool) -> UrlSanitizeResult:
  match ok:
    case True{}:
      UrlAllowed{s}
    case False{}:
      UrlBlocked{}

def sanitize_http_url(+u: ParsedUrl) -> UrlSanitizeResult:
  match u:
    case UrlMissingOrMalformed{}:
      UrlBlocked{}
    case UrlParsed{+s, +has_auth, +host_ok}:
      sanitize_http_url.pick(s, Bool.and(is_http_or_https(s), Bool.and(has_auth, host_ok)))

def is_url_allowed(+res: UrlSanitizeResult) -> Bool:
  match res:
    case UrlBlocked{}:
      False{}
    case UrlAllowed{_}:
      True{}

type RawDisplayInput is Data:
  DisplayNull{}
  DisplayWhitespaceOnly{}
  DisplayLiteralNull{}
  DisplayText{trimmed_id: Nat}

def display_value(+raw: RawDisplayInput, +fallback_id: Nat) -> Nat:
  match raw:
    case DisplayNull{}:
      fallback_id
    case DisplayWhitespaceOnly{}:
      fallback_id
    case DisplayLiteralNull{}:
      fallback_id
    case DisplayText{+trimmed_id}:
      trimmed_id

# ---------------------------------------------------------------------------
# 4. Namespace allowlist & negotiation
# ---------------------------------------------------------------------------

type ChainId is Data:
  ChainMainnet{}
  ChainTestnet{}
  ChainUnsupported{id: Nat}

type WcNamespaceKey is Data:
  NsZenon{}
  NsOther{}

type WcMethod is Data:
  MethodZnnSign{}
  MethodZnnInfo{}
  MethodZnnSend{}
  MethodOther{}

type WcEvent is Data:
  EventChainIdChange{}
  EventAddressChange{}
  EventOther{}

type NamespaceEntry is Data:
  NamespaceEntry{
    ns_key: WcNamespaceKey,
    chains: List<&2, ChainId>,
    methods: List<&2, WcMethod>,
    events: List<&2, WcEvent>
  }

type NamespaceCheckResult is Data:
  NsAccepted{}
  NsRejectUnsupportedActiveChain{}
  NsRejectUnsupportedNamespace{}
  NsRejectUnsupportedChain{}
  NsRejectUnsupportedMethod{}
  NsRejectUnsupportedEvent{}

type ApprovedNamespace is Data:
  ApprovedNamespace{
    chains: List<&2, ChainId>,
    methods: List<&2, WcMethod>,
    events: List<&2, WcEvent>
  }

def approved_chains(+a: ApprovedNamespace) -> List<&2, ChainId>:
  match a:
    case ApprovedNamespace{+cs, _, _}:
      cs

def approved_methods(+a: ApprovedNamespace) -> List<&2, WcMethod>:
  match a:
    case ApprovedNamespace{_, +ms, _}:
      ms

def approved_events(+a: ApprovedNamespace) -> List<&2, WcEvent>:
  match a:
    case ApprovedNamespace{_, _, +es}:
      es

def is_supported_chain(+c: ChainId) -> Bool:
  match c:
    case ChainMainnet{}:
      True{}
    case ChainTestnet{}:
      True{}
    case ChainUnsupported{_}:
      False{}

def chain_id_eq(+a: ChainId, +b: ChainId) -> Bool:
  match a b:
    case ChainMainnet{} ChainMainnet{}:
      True{}
    case ChainTestnet{} ChainTestnet{}:
      True{}
    case ChainUnsupported{+x} ChainUnsupported{+y}:
      Nat.is_eq(x, y)
    case _ _:
      False{}

def chain_from_nat(+id: Nat) -> ChainId:
  match id:
    case 0n:
      ChainUnsupported{0n}
    case 1n:
      ChainMainnet{}
    case 2n:
      ChainUnsupported{2n}
    case 3n:
      ChainTestnet{}
    case 4n+p:
      ChainUnsupported{4n+p}

def is_supported_method(+m: WcMethod) -> Bool:
  match m:
    case MethodZnnSign{}:
      True{}
    case MethodZnnInfo{}:
      True{}
    case MethodZnnSend{}:
      True{}
    case MethodOther{}:
      False{}

def is_supported_event(+e: WcEvent) -> Bool:
  match e:
    case EventChainIdChange{}:
      True{}
    case EventAddressChange{}:
      True{}
    case EventOther{}:
      False{}

def all_supported_methods() -> List<&2, WcMethod>:
  [MethodZnnSign{}, MethodZnnInfo{}, MethodZnnSend{}]

def all_supported_events() -> List<&2, WcEvent>:
  [EventChainIdChange{}, EventAddressChange{}]

def all_chains_match_active(+cs: List<&2, ChainId>, +active: ChainId) -> Bool:
  match cs:
    case Nil{}:
      True{}
    case Con{+h, +t}:
      Bool.and(
        Bool.and(chain_id_eq(h, active), is_supported_chain(h)),
        all_chains_match_active(t, active)
      )

def all_methods_supported(+ms: List<&2, WcMethod>) -> Bool:
  match ms:
    case Nil{}:
      True{}
    case Con{+h, +t}:
      Bool.and(is_supported_method(h), all_methods_supported(t))

def all_events_supported(+es: List<&2, WcEvent>) -> Bool:
  match es:
    case Nil{}:
      True{}
    case Con{+h, +t}:
      Bool.and(is_supported_event(h), all_events_supported(t))

def entry_is_valid(+e: NamespaceEntry, +active: ChainId) -> Bool:
  match e:
    case NamespaceEntry{+ns_key, +cs, +ms, +es}:
      match ns_key:
        case NsZenon{}:
          Bool.and(
            all_chains_match_active(cs, active),
            Bool.and(all_methods_supported(ms), all_events_supported(es))
          )
        case NsOther{}:
          False{}

def all_entries_valid(+reqs: List<&2, NamespaceEntry>, +active: ChainId) -> Bool:
  match reqs:
    case Nil{}:
      True{}
    case Con{+h, +t}:
      Bool.and(entry_is_valid(h, active), all_entries_valid(t, active))

def has_non_zenon_ns(+reqs: List<&2, NamespaceEntry>) -> Bool:
  match reqs:
    case Nil{}:
      False{}
    case Con{+h, +t}:
      match h:
        case NamespaceEntry{+ns_key, _, _, _}:
          match ns_key:
            case NsZenon{}:
              has_non_zenon_ns(t)
            case NsOther{}:
              True{}

def check_ns_entry.ev(+ev_ok: Bool) -> NamespaceCheckResult:
  match ev_ok:
    case True{}:
      NsAccepted{}
    case False{}:
      NsRejectUnsupportedEvent{}

def check_ns_entry.meth(+m_ok: Bool, +es: List<&2, WcEvent>) -> NamespaceCheckResult:
  match m_ok:
    case True{}:
      check_ns_entry.ev(all_events_supported(es))
    case False{}:
      NsRejectUnsupportedMethod{}

def check_ns_entry.ch(+ch_ok: Bool, +ms: List<&2, WcMethod>, +es: List<&2, WcEvent>) -> NamespaceCheckResult:
  match ch_ok:
    case True{}:
      check_ns_entry.meth(all_methods_supported(ms), es)
    case False{}:
      NsRejectUnsupportedChain{}

def check_ns_entry(+e: NamespaceEntry, +active: ChainId) -> NamespaceCheckResult:
  match e:
    case NamespaceEntry{+ns_key, +cs, +ms, +es}:
      match ns_key:
        case NsOther{}:
          NsRejectUnsupportedNamespace{}
        case NsZenon{}:
          check_ns_entry.ch(all_chains_match_active(cs, active), ms, es)

def check_ns_list.step(+first_res: NamespaceCheckResult, +rest_res: NamespaceCheckResult) -> NamespaceCheckResult:
  match first_res:
    case NsAccepted{}:
      rest_res
    case NsRejectUnsupportedActiveChain{}:
      NsRejectUnsupportedActiveChain{}
    case NsRejectUnsupportedNamespace{}:
      NsRejectUnsupportedNamespace{}
    case NsRejectUnsupportedChain{}:
      NsRejectUnsupportedChain{}
    case NsRejectUnsupportedMethod{}:
      NsRejectUnsupportedMethod{}
    case NsRejectUnsupportedEvent{}:
      NsRejectUnsupportedEvent{}

def check_ns_list(+reqs: List<&2, NamespaceEntry>, +active: ChainId) -> NamespaceCheckResult:
  match reqs:
    case Nil{}:
      NsAccepted{}
    case Con{+h, +t}:
      check_ns_list.step(check_ns_entry(h, active), check_ns_list(t, active))

def unsupported_required_namespace_reason.go(+active_ok: Bool, +active: ChainId, +reqs: List<&2, NamespaceEntry>) -> NamespaceCheckResult:
  match active_ok:
    case False{}:
      NsRejectUnsupportedActiveChain{}
    case True{}:
      check_ns_list(reqs, active)

def unsupported_required_namespace_reason(
  +active_chain: ChainId,
  +reqs: List<&2, NamespaceEntry>
) -> NamespaceCheckResult:
  unsupported_required_namespace_reason.go(is_supported_chain(active_chain), active_chain, reqs)

def is_ns_accepted(+res: NamespaceCheckResult) -> Bool:
  match res:
    case NsAccepted{}:
      True{}
    case NsRejectUnsupportedActiveChain{}:
      False{}
    case NsRejectUnsupportedNamespace{}:
      False{}
    case NsRejectUnsupportedChain{}:
      False{}
    case NsRejectUnsupportedMethod{}:
      False{}
    case NsRejectUnsupportedEvent{}:
      False{}

def chain_list_contains(+cs: List<&2, ChainId>, +target: ChainId) -> Bool:
  match cs:
    case Nil{}:
      False{}
    case Con{+h, +t}:
      Bool.or(chain_id_eq(h, target), chain_list_contains(t, target))

def entry_matches_active_chain(+cs: List<&2, ChainId>, +active: ChainId) -> Bool:
  match cs:
    case Nil{}:
      True{}
    case Con{+h, +t}:
      chain_list_contains(h <> t, active)

def filter_supported_methods.put(+h: WcMethod, +rest: List<&2, WcMethod>, +keep: Bool) -> List<&2, WcMethod>:
  match keep:
    case True{}:
      h <> rest
    case False{}:
      rest

def filter_supported_methods(+ms: List<&2, WcMethod>) -> List<&2, WcMethod>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+h, +t}:
      filter_supported_methods.put(h, filter_supported_methods(t), is_supported_method(h))

def filter_supported_events.put(+h: WcEvent, +rest: List<&2, WcEvent>, +keep: Bool) -> List<&2, WcEvent>:
  match keep:
    case True{}:
      h <> rest
    case False{}:
      rest

def filter_supported_events(+es: List<&2, WcEvent>) -> List<&2, WcEvent>:
  match es:
    case Nil{}:
      Nil{}
    case Con{+h, +t}:
      filter_supported_events.put(h, filter_supported_events(t), is_supported_event(h))

def collect_methods.pick(+ok: Bool, +ms: List<&2, WcMethod>, +rest: List<&2, WcMethod>) -> List<&2, WcMethod>:
  match ok:
    case True{}:
      List.append(&2, WcMethod, filter_supported_methods(ms), rest)
    case False{}:
      rest

def collect_methods(+entries: List<&2, NamespaceEntry>, +active: ChainId) -> List<&2, WcMethod>:
  match entries:
    case Nil{}:
      Nil{}
    case Con{+h, +t}:
      match h:
        case NamespaceEntry{+ns_key, +cs, +ms, _}:
          match ns_key:
            case NsOther{}:
              collect_methods(t, active)
            case NsZenon{}:
              collect_methods.pick(entry_matches_active_chain(cs, active), ms, collect_methods(t, active))

def collect_events.pick(+ok: Bool, +es: List<&2, WcEvent>, +rest: List<&2, WcEvent>) -> List<&2, WcEvent>:
  match ok:
    case True{}:
      List.append(&2, WcEvent, filter_supported_events(es), rest)
    case False{}:
      rest

def collect_events(+entries: List<&2, NamespaceEntry>, +active: ChainId) -> List<&2, WcEvent>:
  match entries:
    case Nil{}:
      Nil{}
    case Con{+h, +t}:
      match h:
        case NamespaceEntry{+ns_key, +cs, _, +es}:
          match ns_key:
            case NsOther{}:
              collect_events(t, active)
            case NsZenon{}:
              collect_events.pick(entry_matches_active_chain(cs, active), es, collect_events(t, active))

def build_approved_namespaces(
  +active_chain: ChainId,
  +reqs: List<&2, NamespaceEntry>,
  +opts: List<&2, NamespaceEntry>
) -> ApprovedNamespace:
  match reqs opts:
    case Nil{} Nil{}:
      ApprovedNamespace{[active_chain], all_supported_methods(), all_supported_events()}
    case +r +o:
      ApprovedNamespace{
        [active_chain],
        List.append(&2, WcMethod, collect_methods(r, active_chain), collect_methods(o, active_chain)),
        List.append(&2, WcEvent, collect_events(r, active_chain), collect_events(o, active_chain))
      }

# ---------------------------------------------------------------------------
# 5. Signing domain separation (encodeSignedMessagePayload)
# ---------------------------------------------------------------------------
# UTF-8 "\x19Zenon Signed Message:\n" (23 bytes) ++ decimal(len(msg)) ++ "\n" ++ msg

type Digit is Data:
  D0{}
  D1{}
  D2{}
  D3{}
  D4{}
  D5{}
  D6{}
  D7{}
  D8{}
  D9{}

def digit_to_ascii(+d: Digit) -> U32:
  match d:
    case D0{}: 48
    case D1{}: 49
    case D2{}: 50
    case D3{}: 51
    case D4{}: 52
    case D5{}: 53
    case D6{}: 54
    case D7{}: 55
    case D8{}: 56
    case D9{}: 57

def inc_digits(+ds: List<&2, Digit>) -> List<&2, Digit>:
  match ds:
    case Nil{}:
      [D1{}]
    case Con{+d, +rest}:
      match d:
        case D0{}: D1{} <> rest
        case D1{}: D2{} <> rest
        case D2{}: D3{} <> rest
        case D3{}: D4{} <> rest
        case D4{}: D5{} <> rest
        case D5{}: D6{} <> rest
        case D6{}: D7{} <> rest
        case D7{}: D8{} <> rest
        case D8{}: D9{} <> rest
        case D9{}: D0{} <> inc_digits(rest)

def nat_to_digits_lsb(+n: Nat) -> List<&2, Digit>:
  match n:
    case 0n:
      [D0{}]
    case 1n+p:
      inc_digits(nat_to_digits_lsb(p))

def nat_to_digits(+n: Nat) -> List<&2, Digit>:
  List.reverse(&2, Digit, nat_to_digits_lsb(n))

def digits_to_bytes(+ds: List<&2, Digit>) -> List<&2, U32>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{+d, +t}:
      digit_to_ascii(d) <> digits_to_bytes(t)

# Exact 23 bytes of "\x19Zenon Signed Message:\n"
def signed_message_prefix() -> List<&2, U32>:
  [25, 90, 101, 110, 111, 110, 32, 83, 105, 103, 110, 101, 100, 32, 77, 101, 115, 115, 97, 103, 101, 58, 10]

def encode_signed_message_payload(+msg: List<&2, U32>) -> List<&2, U32>:
  List.append(
    &2,
    U32,
    signed_message_prefix(),
    List.append(
      &2,
      U32,
      digits_to_bytes(nat_to_digits(List.length(&2, U32, msg))),
      10 <> msg
    )
  )

def has_prefix_bytes(+pref: List<&2, U32>, +bs: List<&2, U32>) -> Bool:
  match pref bs:
    case Nil{} _:
      True{}
    case Con{_, _} Nil{}:
      False{}
    case Con{+p, +pt} Con{+b, +bt}:
      Bool.and(U32.is_eq(p, b), has_prefix_bytes(pt, bt))

def has_signed_message_prefix(+bs: List<&2, U32>) -> Bool:
  has_prefix_bytes(signed_message_prefix(), bs)

# ---------------------------------------------------------------------------
# 6. znn_send AccountBlock validation
# ---------------------------------------------------------------------------

type BlockType is Data:
  BlockUserSend{}
  BlockUserReceive{}
  BlockContractSend{}
  BlockContractReceive{}
  BlockOther{}

type HashKind is Data:
  HashEmpty{}
  HashNonEmpty{id: Nat}

type SendAccountBlock is Data:
  SendAccountBlock{
    block_type: BlockType,
    from_block_hash: HashKind,
    chain_id: Nat,
    session_chain: ChainId
  }

type ValidationOutcome is Data:
  ValidOk{}
  ValidErr{code: U32}

def is_user_send_block(+bt: BlockType) -> Bool:
  match bt:
    case BlockUserSend{}:
      True{}
    case BlockUserReceive{}:
      False{}
    case BlockContractSend{}:
      False{}
    case BlockContractReceive{}:
      False{}
    case BlockOther{}:
      False{}

def is_empty_hash(+hk: HashKind) -> Bool:
  match hk:
    case HashEmpty{}:
      True{}
    case HashNonEmpty{_}:
      False{}

def send_block_invariants_hold(+blk: SendAccountBlock, +active_chain_id: Nat) -> Bool:
  match blk:
    case SendAccountBlock{+bt, +fh, +cid, +sch}:
      Bool.and(
        is_user_send_block(bt),
        Bool.and(
          is_empty_hash(fh),
          Bool.and(
            Nat.is_eq(cid, active_chain_id),
            chain_id_eq(sch, chain_from_nat(active_chain_id))
          )
        )
      )

def validate_send_account_block.pick(+ok: Bool) -> ValidationOutcome:
  match ok:
    case True{}:
      ValidOk{}
    case False{}:
      ValidErr{5003}

def validate_send_account_block(+blk: SendAccountBlock, +active_chain_id: Nat) -> ValidationOutcome:
  validate_send_account_block.pick(send_block_invariants_hold(blk, active_chain_id))

def is_valid_ok(+res: ValidationOutcome) -> Bool:
  match res:
    case ValidOk{}:
      True{}
    case ValidErr{_}:
      False{}

# ---------------------------------------------------------------------------
# 7. Signer address authorization (resolveSignerAddress)
# ---------------------------------------------------------------------------

type RequestedAddress is Data:
  ReqAddrNone{}
  ReqAddrEmpty{}
  ReqAddrValue{addr_id: Nat}

type SignerResolution is Data:
  SignerResolved{addr_id: Nat}
  SignerRejectedUnsupportedAccounts{}

def nat_list_contains(+xs: List<&2, Nat>, +target: Nat) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+h, +t}:
      Bool.or(Nat.is_eq(h, target), nat_list_contains(t, target))

def resolve_signer_address.pick(+addr_id: Nat, +owned: Bool) -> SignerResolution:
  match owned:
    case True{}:
      SignerResolved{addr_id}
    case False{}:
      SignerRejectedUnsupportedAccounts{}

def resolve_signer_address(
  +active_addr: Nat,
  +req: RequestedAddress,
  +owned_addrs: List<&2, Nat>
) -> SignerResolution:
  match req:
    case ReqAddrNone{}:
      SignerResolved{active_addr}
    case ReqAddrEmpty{}:
      SignerResolved{active_addr}
    case ReqAddrValue{+a}:
      resolve_signer_address.pick(a, nat_list_contains(owned_addrs, a))

def is_signer_resolved(+res: SignerResolution) -> Bool:
  match res:
    case SignerResolved{_}:
      True{}
    case SignerRejectedUnsupportedAccounts{}:
      False{}

def signer_resolution_eq(+a: SignerResolution, +b: SignerResolution) -> Bool:
  match a b:
    case SignerResolved{+x} SignerResolved{+y}:
      Nat.is_eq(x, y)
    case SignerRejectedUnsupportedAccounts{} SignerRejectedUnsupportedAccounts{}:
      True{}
    case _ _:
      False{}

# ---------------------------------------------------------------------------
# 8. Post-confirmation TOCTOU revalidation (revalidateInteractiveRequest)
# ---------------------------------------------------------------------------

type WcInteractiveMethod is Data:
  InteractiveZnnInfo{}
  InteractiveZnnSign{}
  InteractiveZnnSend{}

def method_requires_active_chain_match(+m: WcInteractiveMethod) -> Bool:
  match m:
    case InteractiveZnnInfo{}:
      False{}
    case InteractiveZnnSign{}:
      True{}
    case InteractiveZnnSend{}:
      True{}

type RevalidationState is Data:
  RevalidationState{
    wallet_locked: Bool,
    session_active: Bool,
    has_request_id: Bool,
    request_still_pending: Bool,
    service_chain: ChainId,
    session_chain: ChainId,
    active_chain: ChainId
  }

def reval_wallet_locked(+st: RevalidationState) -> Bool:
  match st:
    case RevalidationState{+locked, _, _, _, _, _, _}:
      locked

type RevalidationResult is Data:
  RevalOk{}
  RevalErr{code: U32}

def revalidate.chain(+need_chain: Bool, +chain_ok: Bool) -> RevalidationResult:
  match need_chain:
    case False{}:
      RevalOk{}
    case True{}:
      match chain_ok:
        case True{}:
          RevalOk{}
        case False{}:
          RevalErr{5003}

def revalidate.pending(
  +pending_failed: Bool,
  +need_chain: Bool,
  +chain_ok: Bool
) -> RevalidationResult:
  match pending_failed:
    case True{}:
      RevalErr{5005}
    case False{}:
      revalidate.chain(need_chain, chain_ok)

def revalidate_interactive_request(
  +method: WcInteractiveMethod,
  +st: RevalidationState
) -> RevalidationResult:
  match st:
    case RevalidationState{+locked, +sess_active, +has_req_id, +still_pending, +svc_chain, +sess_chain, +act_chain}:
      match locked:
        case True{}:
          RevalErr{9000}
        case False{}:
          match sess_active:
            case False{}:
              RevalErr{5001}
            case True{}:
              revalidate.pending(
                Bool.and(has_req_id, Bool.not(still_pending)),
                method_requires_active_chain_match(method),
                Bool.and(chain_id_eq(svc_chain, act_chain), chain_id_eq(sess_chain, act_chain))
              )

def is_reval_ok(+res: RevalidationResult) -> Bool:
  match res:
    case RevalOk{}:
      True{}
    case RevalErr{_}:
      False{}

# ---------------------------------------------------------------------------
# 9. WalletConnectUriCard revision guard
# ---------------------------------------------------------------------------

type UriCardState is Data:
  UriCardState{
    input_rev: Nat,
    submitted_rev: Maybe<&2, Nat>,
    field_non_empty: Bool
  }

type UriCardOutcome is Data:
  UriCardOutcome{
    next_state: UriCardState,
    cleared_input: Bool
  }

def card_outcome_cleared(+o: UriCardOutcome) -> Bool:
  match o:
    case UriCardOutcome{_, +cl}:
      cl

def uri_card_on_pair_success.pick(+input_rev: Nat, +field_non_empty: Bool, +matches: Bool) -> UriCardOutcome:
  match matches:
    case True{}:
      UriCardOutcome{UriCardState{input_rev, None{}, False{}}, True{}}
    case False{}:
      UriCardOutcome{UriCardState{input_rev, None{}, field_non_empty}, False{}}

def uri_card_on_pair_success(+st: UriCardState) -> UriCardOutcome:
  match st:
    case UriCardState{+cur_rev, +sub_rev, +non_empty}:
      match sub_rev:
        case None{}:
          UriCardOutcome{UriCardState{cur_rev, None{}, non_empty}, False{}}
        case Some{+srev}:
          uri_card_on_pair_success.pick(cur_rev, non_empty, Nat.is_eq(srev, cur_rev))

def uri_card_on_pair_failure(+st: UriCardState) -> UriCardOutcome:
  match st:
    case UriCardState{+cur_rev, _, +non_empty}:
      UriCardOutcome{UriCardState{cur_rev, None{}, non_empty}, False{}}

# ---------------------------------------------------------------------------
# 10. Parallelized multi-check preflight helper (Bend parallel-let)
# ---------------------------------------------------------------------------

def check_metadata_branch(+ctx: VerifyContext, +url: ParsedUrl) -> Bool:
  Bool.and(Bool.not(is_verify_scam(ctx)), is_url_allowed(sanitize_http_url(url)))

def check_tx_and_signer_branch(
  +blk: SendAccountBlock,
  +active_chain_id: Nat,
  +active_addr: Nat,
  +req_addr: RequestedAddress,
  +owned_addrs: List<&2, Nat>
) -> Bool:
  Bool.and(
    is_valid_ok(validate_send_account_block(blk, active_chain_id)),
    is_signer_resolved(resolve_signer_address(active_addr, req_addr, owned_addrs))
  )

def check_reval_branch(+reval_st: RevalidationState) -> Bool:
  is_reval_ok(revalidate_interactive_request(InteractiveZnnSend{}, reval_st))

def sequential_send_preflight(
  +ctx: VerifyContext,
  +url: ParsedUrl,
  +blk: SendAccountBlock,
  +active_chain_id: Nat,
  +active_addr: Nat,
  +req_addr: RequestedAddress,
  +owned_addrs: List<&2, Nat>,
  +reval_st: RevalidationState
) -> Bool:
  Bool.and(
    check_metadata_branch(ctx, url),
    Bool.and(
      check_tx_and_signer_branch(blk, active_chain_id, active_addr, req_addr, owned_addrs),
      check_reval_branch(reval_st)
    )
  )

def parallel_send_preflight(
  +ctx: VerifyContext,
  +url: ParsedUrl,
  +blk: SendAccountBlock,
  +active_chain_id: Nat,
  +active_addr: Nat,
  +req_addr: RequestedAddress,
  +owned_addrs: List<&2, Nat>,
  +reval_st: RevalidationState
) -> Bool:
  meta_ok tx_ok reval_ok = check_metadata_branch(ctx, url) check_tx_and_signer_branch(blk, active_chain_id, active_addr, req_addr, owned_addrs) check_reval_branch(reval_st)
  Bool.and(meta_ok, Bool.and(tx_ok, reval_ok))
