import Base
import ../common/nat.bend as NatL
import ./model.bend as M
import ./LAWS.bend as Laws

# Constructive proofs for all Syrius WalletConnect v2 laws.

# ---------------------------------------------------------------------------
# Domain-specific helper lemmas
# ---------------------------------------------------------------------------

def Not.verified(s: M.VerifySeverity) -> Type:
  match s:
    case M.SevVerified{}:
      Empty
    case M.SevInvalid{}:
      Unit
    case M.SevUnverified{}:
      Unit
    case M.SevScam{}:
      Unit

def not_verified_absurd(+s: M.VerifySeverity, ok: {s == M.SevVerified{} : M.VerifySeverity}, wit: Not.verified(s)) -> Empty:
  %ok : Not.verified(_)
  wit

def Not.ns_accepted(r: M.NamespaceCheckResult) -> Type:
  match r:
    case M.NsAccepted{}:
      Empty
    case M.NsRejectUnsupportedActiveChain{}:
      Unit
    case M.NsRejectUnsupportedNamespace{}:
      Unit
    case M.NsRejectUnsupportedChain{}:
      Unit
    case M.NsRejectUnsupportedMethod{}:
      Unit
    case M.NsRejectUnsupportedEvent{}:
      Unit

def not_ns_accepted_absurd(
  +r: M.NamespaceCheckResult,
  ok: {r == M.NsAccepted{} : M.NamespaceCheckResult},
  wit: Not.ns_accepted(r)
) -> Empty:
  %ok : Not.ns_accepted(_)
  wit

def Not.valid_ok(r: M.ValidationOutcome) -> Type:
  match r:
    case M.ValidOk{}:
      Empty
    case M.ValidErr{_}:
      Unit

def valid_err_not_ok(+c: U32, e: {M.ValidErr{c} == M.ValidOk{} : M.ValidationOutcome}) -> Empty:
  %e : Not.valid_ok(_)
  Unit{}

def list_head_or(-A: Data, +d: A, +xs: List<&2, A>) -> A:
  match xs:
    case Nil{}:
      d
    case Con{+h, _}:
      h

def list_tail_or(-A: Data, +xs: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{_, +t}:
      t

def list_cons_head_eq(
  -A: Data,
  +x1: A,
  +x2: A,
  +t1: List<&2, A>,
  +t2: List<&2, A>,
  e: {x1 <> t1 == x2 <> t2 : List<&2, A>}
) -> {x1 == x2 : A}:
  %e : {list_head_or(A, x1, x1 <> t1) == list_head_or(A, x1, _) : A}
  {==}

def list_cons_tail_eq(
  -A: Data,
  +x1: A,
  +x2: A,
  +t1: List<&2, A>,
  +t2: List<&2, A>,
  e: {x1 <> t1 == x2 <> t2 : List<&2, A>}
) -> {t1 == t2 : List<&2, A>}:
  %e : {list_tail_or(A, x1 <> t1) == list_tail_or(A, _) : List<&2, A>}
  {==}

def append_cancel_left(
  -A: Data,
  +p: List<&2, A>,
  +xs: List<&2, A>,
  +ys: List<&2, A>,
  e: {List.append(&2, A, p, xs) == List.append(&2, A, p, ys) : List<&2, A>}
) -> {xs == ys : List<&2, A>}:
  match p:
    case Nil{}:
      e
    case Con{+h, +t}:
      append_cancel_left(
        A,
        t,
        xs,
        ys,
        list_cons_tail_eq(A, h, h, List.append(&2, A, t, xs), List.append(&2, A, t, ys), e)
      )

def digit_ascii_not_newline(+d: M.Digit) -> {U32.is_eq(M.digit_to_ascii(d), 10) == False{} : Bool}:
  match d:
    case M.D0{}: {==}
    case M.D1{}: {==}
    case M.D2{}: {==}
    case M.D3{}: {==}
    case M.D4{}: {==}
    case M.D5{}: {==}
    case M.D6{}: {==}
    case M.D7{}: {==}
    case M.D8{}: {==}
    case M.D9{}: {==}

def digit_eq_10_to_eq_bool(+d: M.Digit, e: {10 == M.digit_to_ascii(d) : U32}) -> {True{} == U32.is_eq(M.digit_to_ascii(d), 10) : Bool}:
  %e : {U32.is_eq(10, 10) == U32.is_eq(_, 10) : Bool}
  {==}

def digit_eq_10_absurd(+d: M.Digit, e: {10 == M.digit_to_ascii(d) : U32}) -> Empty:
  e2 = digit_eq_10_to_eq_bool(d, e)
  e3 = Equal.trans(Bool, True{}, U32.is_eq(M.digit_to_ascii(d), 10), False{}, e2, digit_ascii_not_newline(d))
  NatL.true_is_not_false(e3)

def digits_sep_injective(
  +d1: List<&2, M.Digit>,
  +d2: List<&2, M.Digit>,
  +m1: List<&2, U32>,
  +m2: List<&2, U32>,
  e: {List.append(&2, U32, M.digits_to_bytes(d1), 10 <> m1) == List.append(&2, U32, M.digits_to_bytes(d2), 10 <> m2) : List<&2, U32>}
) -> {m1 == m2 : List<&2, U32>}:
  match d1 d2:
    case Nil{} Nil{}:
      list_cons_tail_eq(U32, 10, 10, m1, m2, e)
    case Nil{} Con{+h2, +t2}:
      he = list_cons_head_eq(U32, 10, M.digit_to_ascii(h2), m1, List.append(&2, U32, M.digits_to_bytes(t2), 10 <> m2), e)
      Empty.absurd({m1 == m2 : List<&2, U32>}, digit_eq_10_absurd(h2, he))
    case Con{+h1, +t1} Nil{}:
      he = list_cons_head_eq(U32, M.digit_to_ascii(h1), 10, List.append(&2, U32, M.digits_to_bytes(t1), 10 <> m1), m2, e)
      Empty.absurd({m1 == m2 : List<&2, U32>}, digit_eq_10_absurd(h1, Equal.sym(U32, M.digit_to_ascii(h1), 10, he)))
    case Con{+h1, +t1} Con{+h2, +t2}:
      te = list_cons_tail_eq(
        U32,
        M.digit_to_ascii(h1),
        M.digit_to_ascii(h2),
        List.append(&2, U32, M.digits_to_bytes(t1), 10 <> m1),
        List.append(&2, U32, M.digits_to_bytes(t2), 10 <> m2),
        e
      )
      digits_sep_injective(t1, t2, m1, m2, te)

def u32_list_length_append(+xs: List<&2, U32>, +ys: List<&2, U32>) -> {List.length(&2, U32, List.append(&2, U32, xs, ys)) == Nat.add(List.length(&2, U32, xs), List.length(&2, U32, ys)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{_, +t}:
      %u32_list_length_append(t, ys) : {1n+List.length(&2, U32, List.append(&2, U32, t, ys)) == 1n+_ : Nat}
      {==}

def digits_to_bytes_len(+ds: List<&2, M.Digit>) -> {List.length(&2, U32, M.digits_to_bytes(ds)) == List.length(&2, M.Digit, ds) : Nat}:
  match ds:
    case Nil{}:
      {==}
    case Con{_, +t}:
      %digits_to_bytes_len(t) : {1n+List.length(&2, U32, M.digits_to_bytes(t)) == 1n+_ : Nat}
      {==}

def list_rev_go_len(+xs: List<&2, M.Digit>, +acc: List<&2, M.Digit>) -> {List.length(&2, M.Digit, List.reverse.go(&2, M.Digit, xs, acc)) == Nat.add(List.length(&2, M.Digit, xs), List.length(&2, M.Digit, acc)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      e1 = list_rev_go_len(t, h <> acc)
      e2 = NatL.add_succ(List.length(&2, M.Digit, t), List.length(&2, M.Digit, acc))
      Equal.trans(
        Nat,
        List.length(&2, M.Digit, List.reverse.go(&2, M.Digit, t, h <> acc)),
        Nat.add(List.length(&2, M.Digit, t), 1n+List.length(&2, M.Digit, acc)),
        1n+Nat.add(List.length(&2, M.Digit, t), List.length(&2, M.Digit, acc)),
        e1,
        e2
      )

def list_rev_len(+xs: List<&2, M.Digit>) -> {List.length(&2, M.Digit, List.reverse(&2, M.Digit, xs)) == List.length(&2, M.Digit, xs) : Nat}:
  e1 = list_rev_go_len(xs, Nil{})
  e2 = NatL.add_zero(List.length(&2, M.Digit, xs))
  Equal.trans(
    Nat,
    List.length(&2, M.Digit, List.reverse(&2, M.Digit, xs)),
    Nat.add(List.length(&2, M.Digit, xs), 0n),
    List.length(&2, M.Digit, xs),
    e1,
    e2
  )

def inc_digits_len_ge1(+ds: List<&2, M.Digit>) -> {Nat.is_le(1n, List.length(&2, M.Digit, M.inc_digits(ds))) == True{} : Bool}:
  match ds:
    case Nil{}:
      {==}
    case Con{+d, +rest}:
      match d:
        case M.D0{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D1{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D2{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D3{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D4{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D5{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D6{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D7{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D8{}: NatL.is_le_zero(List.length(&2, M.Digit, rest))
        case M.D9{}: NatL.is_le_zero(List.length(&2, M.Digit, M.inc_digits(rest)))

def nat_to_digits_lsb_len_ge1(+n: Nat) -> {Nat.is_le(1n, List.length(&2, M.Digit, M.nat_to_digits_lsb(n))) == True{} : Bool}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      inc_digits_len_ge1(M.nat_to_digits_lsb(p))

def nat_to_digits_len_ge1(+n: Nat) -> {Nat.is_le(1n, List.length(&2, M.Digit, M.nat_to_digits(n))) == True{} : Bool}:
  %Equal.sym(Nat, List.length(&2, M.Digit, M.nat_to_digits(n)), List.length(&2, M.Digit, M.nat_to_digits_lsb(n)), list_rev_len(M.nat_to_digits_lsb(n))) : {Nat.is_le(1n, _) == True{} : Bool}
  nat_to_digits_lsb_len_ge1(n)

def all_methods_append(
  +xs: List<&2, M.WcMethod>,
  +ys: List<&2, M.WcMethod>,
  hx: {M.all_methods_supported(xs) == True{} : Bool},
  hy: {M.all_methods_supported(ys) == True{} : Bool}
) -> {M.all_methods_supported(List.append(&2, M.WcMethod, xs, ys)) == True{} : Bool}:
  match xs:
    case Nil{}:
      hy
    case Con{+h, +t}:
      match h:
        case M.MethodZnnSign{}:
          all_methods_append(t, ys, hx, hy)
        case M.MethodZnnInfo{}:
          all_methods_append(t, ys, hx, hy)
        case M.MethodZnnSend{}:
          all_methods_append(t, ys, hx, hy)
        case M.MethodOther{}:
          Empty.absurd({False{} == True{} : Bool}, NatL.false_is_not_true(hx))

def filter_supported_methods_ok(+ms: List<&2, M.WcMethod>) -> {M.all_methods_supported(M.filter_supported_methods(ms)) == True{} : Bool}:
  match ms:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      match h:
        case M.MethodZnnSign{}:
          filter_supported_methods_ok(t)
        case M.MethodZnnInfo{}:
          filter_supported_methods_ok(t)
        case M.MethodZnnSend{}:
          filter_supported_methods_ok(t)
        case M.MethodOther{}:
          filter_supported_methods_ok(t)

def collect_methods_pick_ok(
  +ok: Bool,
  +ms: List<&2, M.WcMethod>,
  +rest: List<&2, M.WcMethod>,
  hrest: {M.all_methods_supported(rest) == True{} : Bool}
) -> {M.all_methods_supported(M.collect_methods.pick(ok, ms, rest)) == True{} : Bool}:
  match ok:
    case False{}:
      hrest
    case True{}:
      all_methods_append(M.filter_supported_methods(ms), rest, filter_supported_methods_ok(ms), hrest)

def collect_methods_supported(+entries: List<&2, M.NamespaceEntry>, +active: M.ChainId) -> {M.all_methods_supported(M.collect_methods(entries, active)) == True{} : Bool}:
  match entries:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      match h:
        case M.NamespaceEntry{+ns_key, +cs, +ms, _}:
          match ns_key:
            case M.NsOther{}:
              collect_methods_supported(t, active)
            case M.NsZenon{}:
              collect_methods_pick_ok(M.entry_matches_active_chain(cs, active), ms, M.collect_methods(t, active), collect_methods_supported(t, active))

def all_events_append(
  +xs: List<&2, M.WcEvent>,
  +ys: List<&2, M.WcEvent>,
  hx: {M.all_events_supported(xs) == True{} : Bool},
  hy: {M.all_events_supported(ys) == True{} : Bool}
) -> {M.all_events_supported(List.append(&2, M.WcEvent, xs, ys)) == True{} : Bool}:
  match xs:
    case Nil{}:
      hy
    case Con{+h, +t}:
      match h:
        case M.EventChainIdChange{}:
          all_events_append(t, ys, hx, hy)
        case M.EventAddressChange{}:
          all_events_append(t, ys, hx, hy)
        case M.EventOther{}:
          Empty.absurd({False{} == True{} : Bool}, NatL.false_is_not_true(hx))

def filter_supported_events_ok(+es: List<&2, M.WcEvent>) -> {M.all_events_supported(M.filter_supported_events(es)) == True{} : Bool}:
  match es:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      match h:
        case M.EventChainIdChange{}:
          filter_supported_events_ok(t)
        case M.EventAddressChange{}:
          filter_supported_events_ok(t)
        case M.EventOther{}:
          filter_supported_events_ok(t)

def collect_events_pick_ok(
  +ok: Bool,
  +es: List<&2, M.WcEvent>,
  +rest: List<&2, M.WcEvent>,
  hrest: {M.all_events_supported(rest) == True{} : Bool}
) -> {M.all_events_supported(M.collect_events.pick(ok, es, rest)) == True{} : Bool}:
  match ok:
    case False{}:
      hrest
    case True{}:
      all_events_append(M.filter_supported_events(es), rest, filter_supported_events_ok(es), hrest)

def collect_events_supported(+entries: List<&2, M.NamespaceEntry>, +active: M.ChainId) -> {M.all_events_supported(M.collect_events(entries, active)) == True{} : Bool}:
  match entries:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      match h:
        case M.NamespaceEntry{+ns_key, +cs, _, +es}:
          match ns_key:
            case M.NsOther{}:
              collect_events_supported(t, active)
            case M.NsZenon{}:
              collect_events_pick_ok(M.entry_matches_active_chain(cs, active), es, M.collect_events(t, active), collect_events_supported(t, active))

def check_ns_list_step_non_accepted(
  +first_res: M.NamespaceCheckResult,
  +rest_res: M.NamespaceCheckResult,
  hr: {M.is_ns_accepted(rest_res) == False{} : Bool}
) -> {M.is_ns_accepted(M.check_ns_list.step(first_res, rest_res)) == False{} : Bool}:
  match first_res:
    case M.NsAccepted{}:
      hr
    case M.NsRejectUnsupportedActiveChain{}:
      {==}
    case M.NsRejectUnsupportedNamespace{}:
      {==}
    case M.NsRejectUnsupportedChain{}:
      {==}
    case M.NsRejectUnsupportedMethod{}:
      {==}
    case M.NsRejectUnsupportedEvent{}:
      {==}

def check_ns_list_rejects_non_zenon(
  +reqs: List<&2, M.NamespaceEntry>,
  +active: M.ChainId,
  has_other: {M.has_non_zenon_ns(reqs) == True{} : Bool}
) -> {M.is_ns_accepted(M.check_ns_list(reqs, active)) == False{} : Bool}:
  match reqs:
    case Nil{}:
      Empty.absurd({M.is_ns_accepted(M.NsAccepted{}) == False{} : Bool}, NatL.false_is_not_true(has_other))
    case Con{+h, +t}:
      match h:
        case M.NamespaceEntry{+ns_key, +cs, +ms, +es}:
          match ns_key:
            case M.NsOther{}:
              {==}
            case M.NsZenon{}:
              check_ns_list_step_non_accepted(
                M.check_ns_entry(M.NamespaceEntry{M.NsZenon{}, cs, ms, es}, active),
                M.check_ns_list(t, active),
                check_ns_list_rejects_non_zenon(t, active, has_other)
              )

def check_ns_entry_ev_sound(
  +ev_ok: Bool,
  ok: {M.check_ns_entry.ev(ev_ok) == M.NsAccepted{} : M.NamespaceCheckResult}
) -> {ev_ok == True{} : Bool}:
  match ev_ok:
    case True{}:
      {==}
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedEvent{}, ok, Unit{}))

def check_ns_entry_meth_sound(
  +m_ok: Bool,
  +es: List<&2, M.WcEvent>,
  ok: {M.check_ns_entry.meth(m_ok, es) == M.NsAccepted{} : M.NamespaceCheckResult}
) -> {Bool.and(m_ok, M.all_events_supported(es)) == True{} : Bool}:
  match m_ok:
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedMethod{}, ok, Unit{}))
    case True{}:
      check_ns_entry_ev_sound(M.all_events_supported(es), ok)

def check_ns_entry_ch_sound(
  +ch_ok: Bool,
  +ms: List<&2, M.WcMethod>,
  +es: List<&2, M.WcEvent>,
  ok: {M.check_ns_entry.ch(ch_ok, ms, es) == M.NsAccepted{} : M.NamespaceCheckResult}
) -> {Bool.and(ch_ok, Bool.and(M.all_methods_supported(ms), M.all_events_supported(es))) == True{} : Bool}:
  match ch_ok:
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedChain{}, ok, Unit{}))
    case True{}:
      check_ns_entry_meth_sound(M.all_methods_supported(ms), es, ok)

def check_ns_entry_sound(
  +e: M.NamespaceEntry,
  +active: M.ChainId,
  ok: {M.check_ns_entry(e, active) == M.NsAccepted{} : M.NamespaceCheckResult}
) -> {M.entry_is_valid(e, active) == True{} : Bool}:
  match e:
    case M.NamespaceEntry{+ns_key, +cs, +ms, +es}:
      match ns_key:
        case M.NsOther{}:
          Empty.absurd({False{} == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedNamespace{}, ok, Unit{}))
        case M.NsZenon{}:
          check_ns_entry_ch_sound(M.all_chains_match_active(cs, active), ms, es, ok)

def check_ns_list_sound.step(
  +h: M.NamespaceEntry,
  +t: List<&2, M.NamespaceEntry>,
  +active: M.ChainId,
  +first_res: M.NamespaceCheckResult,
  eq_first: {M.check_ns_entry(h, active) == first_res : M.NamespaceCheckResult},
  ok: {M.check_ns_list.step(first_res, M.check_ns_list(t, active)) == M.NsAccepted{} : M.NamespaceCheckResult},
  rest_fn: {M.check_ns_list(t, active) == M.NsAccepted{} : M.NamespaceCheckResult} -> {M.all_entries_valid(t, active) == True{} : Bool}
) -> {Bool.and(M.entry_is_valid(h, active), M.all_entries_valid(t, active)) == True{} : Bool}:
  match first_res:
    case M.NsAccepted{}:
      h1 = check_ns_entry_sound(h, active, eq_first)
      h2 = rest_fn(ok)
      %Equal.sym(Bool, M.entry_is_valid(h, active), True{}, h1) : {Bool.and(_, M.all_entries_valid(t, active)) == True{} : Bool}
      h2
    case M.NsRejectUnsupportedActiveChain{}:
      Empty.absurd({Bool.and(M.entry_is_valid(h, active), M.all_entries_valid(t, active)) == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedActiveChain{}, ok, Unit{}))
    case M.NsRejectUnsupportedNamespace{}:
      Empty.absurd({Bool.and(M.entry_is_valid(h, active), M.all_entries_valid(t, active)) == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedNamespace{}, ok, Unit{}))
    case M.NsRejectUnsupportedChain{}:
      Empty.absurd({Bool.and(M.entry_is_valid(h, active), M.all_entries_valid(t, active)) == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedChain{}, ok, Unit{}))
    case M.NsRejectUnsupportedMethod{}:
      Empty.absurd({Bool.and(M.entry_is_valid(h, active), M.all_entries_valid(t, active)) == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedMethod{}, ok, Unit{}))
    case M.NsRejectUnsupportedEvent{}:
      Empty.absurd({Bool.and(M.entry_is_valid(h, active), M.all_entries_valid(t, active)) == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedEvent{}, ok, Unit{}))

def check_ns_list_sound(
  +reqs: List<&2, M.NamespaceEntry>,
  +active: M.ChainId,
  ok: {M.check_ns_list(reqs, active) == M.NsAccepted{} : M.NamespaceCheckResult}
) -> {M.all_entries_valid(reqs, active) == True{} : Bool}:
  match reqs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      check_ns_list_sound.step(
        h,
        t,
        active,
        M.check_ns_entry(h, active),
        {==},
        ok,
        ok2 => check_ns_list_sound(t, active, ok2)
      )

def extract_check_sound(
  +v: Nat,
  +t: Bool,
  +r: Bool,
  +s: Bool,
  +valid: Bool,
  ok: {M.is_wc_uri_extracted(M.extract_wc_uri.check(v, t, r, s, valid)) == True{} : Bool}
) -> {valid == True{} : Bool}:
  match valid:
    case True{}:
      {==}
    case False{}:
      ok

def extract_win_sound(
  +slash_blocked: Bool,
  +v: Nat,
  +t: Bool,
  +r: Bool,
  +s: Bool,
  ok: {M.is_wc_uri_extracted(M.extract_wc_uri.win(slash_blocked, v, t, r, s)) == True{} : Bool}
) -> {M.is_valid_wc_v2_fields(v, t, r, s) == True{} : Bool}:
  match slash_blocked:
    case True{}:
      Empty.absurd({M.is_valid_wc_v2_fields(v, t, r, s) == True{} : Bool}, NatL.false_is_not_true(ok))
    case False{}:
      extract_check_sound(v, t, r, s, M.is_valid_wc_v2_fields(v, t, r, s), ok)

def extract_win_invalid(
  +slash_blocked: Bool,
  +v: Nat,
  +t: Bool,
  +r: Bool,
  +s: Bool,
  bad: {M.is_valid_wc_v2_fields(v, t, r, s) == False{} : Bool}
) -> {M.extract_wc_uri.win(slash_blocked, v, t, r, s) == M.UriRejected{} : M.WcUriExtractResult}:
  match slash_blocked:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, M.is_valid_wc_v2_fields(v, t, r, s), False{}, bad) : {M.extract_wc_uri.check(v, t, r, s, _) == M.UriRejected{} : M.WcUriExtractResult}
      {==}

def extract_src_invalid(
  +src: M.WcUriSource,
  +slash_q: Bool,
  +ws: Bool,
  +v: Nat,
  +t: Bool,
  +r: Bool,
  +s: Bool,
  +is_windows: Bool,
  bad: {M.is_valid_wc_v2_fields(v, t, r, s) == False{} : Bool}
) -> {M.extract_wc_uri(M.WcUriCandidate{src, slash_q, ws, v, t, r, s}, is_windows) == M.UriRejected{} : M.WcUriExtractResult}:
  match src:
    case M.NonWcInput{}:
      {==}
    case M.DirectWc{}:
      extract_win_invalid(Bool.and(slash_q, Bool.not(is_windows)), v, t, r, s, bad)
    case M.PercentEncodedOnce{}:
      extract_win_invalid(Bool.and(slash_q, Bool.not(is_windows)), v, t, r, s, bad)
    case M.PercentEncodedTwice{}:
      extract_win_invalid(Bool.and(slash_q, Bool.not(is_windows)), v, t, r, s, bad)
    case M.QueryUriParam{}:
      extract_win_invalid(Bool.and(slash_q, Bool.not(is_windows)), v, t, r, s, bad)
    case M.RegexUriFallback{}:
      extract_win_invalid(Bool.and(slash_q, Bool.not(is_windows)), v, t, r, s, bad)

def extract_check_idempotent(
  +v: Nat,
  +t: Bool,
  +r: Bool,
  +s: Bool,
  +is_windows: Bool,
  +valid: Bool,
  eq_valid: {M.is_valid_wc_v2_fields(v, t, r, s) == valid : Bool}
) -> {M.reextract_wc_uri(M.extract_wc_uri.check(v, t, r, s, valid), is_windows) == M.extract_wc_uri.check(v, t, r, s, valid) : M.WcUriExtractResult}:
  match valid:
    case False{}:
      {==}
    case True{}:
      %Equal.sym(Bool, M.is_valid_wc_v2_fields(v, t, r, s), True{}, eq_valid) : {M.extract_wc_uri.check(v, t, r, s, _) == M.UriExtracted{v, t, r, s} : M.WcUriExtractResult}
      {==}

def extract_win_idempotent(
  +slash_blocked: Bool,
  +v: Nat,
  +t: Bool,
  +r: Bool,
  +s: Bool,
  +is_windows: Bool
) -> {M.reextract_wc_uri(M.extract_wc_uri.win(slash_blocked, v, t, r, s), is_windows) == M.extract_wc_uri.win(slash_blocked, v, t, r, s) : M.WcUriExtractResult}:
  match slash_blocked:
    case True{}:
      {==}
    case False{}:
      extract_check_idempotent(v, t, r, s, is_windows, M.is_valid_wc_v2_fields(v, t, r, s), {==})

def bool_and_left_false(+a: Bool, +b: Bool, h: {a == False{} : Bool}) -> {Bool.and(a, b) == False{} : Bool}:
  %Equal.sym(Bool, a, False{}, h) : {Bool.and(_, b) == False{} : Bool}
  {==}

def bool_and_right_false(+a: Bool, +b: Bool, h: {b == False{} : Bool}) -> {Bool.and(a, b) == False{} : Bool}:
  %Equal.sym(Bool, b, False{}, h) : {Bool.and(a, _) == False{} : Bool}
  NatL.and_false_right(a)

# ---------------------------------------------------------------------------
# Proofs of Laws (31 laws)
# ---------------------------------------------------------------------------

def Laws.wc_uri_extracted_requires_valid_v2_fields(cand, is_windows, ok):
  match cand:
    case M.WcUriCandidate{src, +has_slash_q, _, +v, +t, +r, +s}:
      match src:
        case M.NonWcInput{}:
          Empty.absurd({M.is_valid_wc_v2_fields(v, t, r, s) == True{} : Bool}, NatL.false_is_not_true(ok))
        case M.DirectWc{}:
          extract_win_sound(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, ok)
        case M.PercentEncodedOnce{}:
          extract_win_sound(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, ok)
        case M.PercentEncodedTwice{}:
          extract_win_sound(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, ok)
        case M.QueryUriParam{}:
          extract_win_sound(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, ok)
        case M.RegexUriFallback{}:
          extract_win_sound(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, ok)

def Laws.wc_uri_rejects_non_v2(src, slash_q, ws, v, t, r, s, is_windows, not_v2):
  extract_src_invalid(
    src,
    slash_q,
    ws,
    v,
    t,
    r,
    s,
    is_windows,
    bool_and_left_false(Nat.is_eq(v, 2n), Bool.and(t, Bool.and(r, s)), not_v2)
  )

def Laws.wc_uri_rejects_missing_required_fields(src, slash_q, ws, v, t, r, s, is_windows, missing):
  extract_src_invalid(
    src,
    slash_q,
    ws,
    v,
    t,
    r,
    s,
    is_windows,
    bool_and_right_false(Nat.is_eq(v, 2n), Bool.and(t, Bool.and(r, s)), missing)
  )

def Laws.wc_uri_extract_idempotent(cand, is_windows):
  match cand:
    case M.WcUriCandidate{src, +has_slash_q, _, +v, +t, +r, +s}:
      match src:
        case M.NonWcInput{}:
          {==}
        case M.DirectWc{}:
          extract_win_idempotent(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, is_windows)
        case M.PercentEncodedOnce{}:
          extract_win_idempotent(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, is_windows)
        case M.PercentEncodedTwice{}:
          extract_win_idempotent(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, is_windows)
        case M.QueryUriParam{}:
          extract_win_idempotent(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, is_windows)
        case M.RegexUriFallback{}:
          extract_win_idempotent(Bool.and(has_slash_q, Bool.not(is_windows)), v, t, r, s, is_windows)

def Laws.request_key_distinct_ids_never_collide(m1, m2, t1, t2, fp1, fp2, id1, id2, diff):
  e1 = bool_and_right_false(Nat.is_eq(t1, t2), Nat.is_eq(id1, id2), diff)
  bool_and_right_false(Nat.is_eq(m1, m2), Bool.and(Nat.is_eq(t1, t2), Nat.is_eq(id1, id2)), e1)

def Laws.request_key_with_id_ignores_params(m, t, fp1, fp2, rid):
  {==}

def Laws.wc_error_preserves_known_codes(kind, code):
  match kind:
    case M.KindJsonRpc{}:
      {==}
    case M.KindReownSign{}:
      {==}
    case M.KindReownCore{}:
      {==}

def Laws.wc_error_unknown_maps_to_5000():
  {==}

def Laws.verify_scam_cases_complete(is_scam_flag, val):
  e_scam = NatL.or_true_right(is_scam_flag)
  %Equal.sym(Bool, Bool.or(is_scam_flag, True{}), True{}, e_scam) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

def Laws.verify_scam_dominates_all_validations(ctx, scam):
  match ctx:
    case M.NoVerifyContext{}:
      Empty.absurd({M.SevUnverified{} == M.SevScam{} : M.VerifySeverity}, NatL.false_is_not_true(scam))
    case M.HasVerifyContext{+flag, +val}:
      match flag:
        case True{}:
          {==}
        case False{}:
          match val:
            case M.ValScam{}:
              {==}
            case M.ValValid{}:
              Empty.absurd({M.SevVerified{} == M.SevScam{} : M.VerifySeverity}, NatL.false_is_not_true(scam))
            case M.ValInvalid{}:
              Empty.absurd({M.SevInvalid{} == M.SevScam{} : M.VerifySeverity}, NatL.false_is_not_true(scam))
            case M.ValUnknown{}:
              Empty.absurd({M.SevUnverified{} == M.SevScam{} : M.VerifySeverity}, NatL.false_is_not_true(scam))

def Laws.verify_severity_strict_precedence():
  {==}

def Laws.verify_verified_requires_non_scam_valid(ctx, ok):
  match ctx:
    case M.NoVerifyContext{}:
      Empty.absurd({M.NoVerifyContext{} == M.HasVerifyContext{False{}, M.ValValid{}} : M.VerifyContext}, not_verified_absurd(M.SevUnverified{}, ok, Unit{}))
    case M.HasVerifyContext{+flag, +val}:
      match flag:
        case True{}:
          Empty.absurd({M.HasVerifyContext{True{}, val} == M.HasVerifyContext{False{}, M.ValValid{}} : M.VerifyContext}, not_verified_absurd(M.SevScam{}, ok, Unit{}))
        case False{}:
          match val:
            case M.ValValid{}:
              {==}
            case M.ValScam{}:
              Empty.absurd({M.HasVerifyContext{False{}, M.ValScam{}} == M.HasVerifyContext{False{}, M.ValValid{}} : M.VerifyContext}, not_verified_absurd(M.SevScam{}, ok, Unit{}))
            case M.ValUnknown{}:
              Empty.absurd({M.HasVerifyContext{False{}, M.ValUnknown{}} == M.HasVerifyContext{False{}, M.ValValid{}} : M.VerifyContext}, not_verified_absurd(M.SevUnverified{}, ok, Unit{}))
            case M.ValInvalid{}:
              Empty.absurd({M.HasVerifyContext{False{}, M.ValInvalid{}} == M.HasVerifyContext{False{}, M.ValValid{}} : M.VerifyContext}, not_verified_absurd(M.SevInvalid{}, ok, Unit{}))

def sanitize_pick_sound(+s: M.UrlScheme, +ok_b: Bool, ok: {M.is_url_allowed(M.sanitize_http_url.pick(s, ok_b)) == True{} : Bool}) -> {ok_b == True{} : Bool}:
  match ok_b:
    case True{}:
      {==}
    case False{}:
      ok

def Laws.sanitize_http_url_allows_only_http_https_with_host(u, ok):
  match u:
    case M.UrlMissingOrMalformed{}:
      ok
    case M.UrlParsed{+s, +has_auth, +host_ok}:
      sanitize_pick_sound(s, Bool.and(M.is_http_or_https(s), Bool.and(has_auth, host_ok)), ok)

def Laws.sanitize_http_url_blocks_dangerous_schemes_and_empty_host(has_auth, host_ok, s):
  match has_auth host_ok s:
    case False{} False{} M.SchemeHttp{}: {==}
    case False{} True{} M.SchemeHttp{}: {==}
    case True{} False{} M.SchemeHttp{}: {==}
    case True{} True{} M.SchemeHttp{}: {==}
    case False{} False{} M.SchemeHttps{}: {==}
    case False{} True{} M.SchemeHttps{}: {==}
    case True{} False{} M.SchemeHttps{}: {==}
    case True{} True{} M.SchemeHttps{}: {==}
    case False{} False{} M.SchemeJavascript{}: {==}
    case False{} True{} M.SchemeJavascript{}: {==}
    case True{} False{} M.SchemeJavascript{}: {==}
    case True{} True{} M.SchemeJavascript{}: {==}
    case False{} False{} M.SchemeFile{}: {==}
    case False{} True{} M.SchemeFile{}: {==}
    case True{} False{} M.SchemeFile{}: {==}
    case True{} True{} M.SchemeFile{}: {==}
    case False{} False{} M.SchemeData{}: {==}
    case False{} True{} M.SchemeData{}: {==}
    case True{} False{} M.SchemeData{}: {==}
    case True{} True{} M.SchemeData{}: {==}
    case False{} False{} M.SchemeOther{}: {==}
    case False{} True{} M.SchemeOther{}: {==}
    case True{} False{} M.SchemeOther{}: {==}
    case True{} True{} M.SchemeOther{}: {==}

def Laws.display_value_fallback_on_empty_or_null(fb, txt):
  e_fb = NatL.is_eq_same(fb)
  e_txt = NatL.is_eq_same(txt)
  %Equal.sym(Bool, Nat.is_eq(fb, fb), True{}, e_fb) : {Bool.and(_, Bool.and(_, Bool.and(_, Nat.is_eq(txt, txt)))) == True{} : Bool}
  e_txt

def Laws.namespace_rejects_unsupported_active_chain(active, reqs, bad):
  %Equal.sym(Bool, M.is_supported_chain(active), False{}, bad) : {M.unsupported_required_namespace_reason.go(_, active, reqs) == M.NsRejectUnsupportedActiveChain{} : M.NamespaceCheckResult}
  {==}

def ns_go_rejects_non_zenon(
  +active_ok: Bool,
  +active: M.ChainId,
  +reqs: List<&2, M.NamespaceEntry>,
  has_other: {M.has_non_zenon_ns(reqs) == True{} : Bool}
) -> {M.is_ns_accepted(M.unsupported_required_namespace_reason.go(active_ok, active, reqs)) == False{} : Bool}:
  match active_ok:
    case False{}:
      {==}
    case True{}:
      check_ns_list_rejects_non_zenon(reqs, active, has_other)

def Laws.namespace_rejects_non_zenon_required(active, reqs, has_other):
  ns_go_rejects_non_zenon(M.is_supported_chain(active), active, reqs, has_other)

def ns_go_sound(
  +active_ok: Bool,
  +active: M.ChainId,
  +reqs: List<&2, M.NamespaceEntry>,
  ok: {M.unsupported_required_namespace_reason.go(active_ok, active, reqs) == M.NsAccepted{} : M.NamespaceCheckResult}
) -> {Bool.and(active_ok, M.all_entries_valid(reqs, active)) == True{} : Bool}:
  match active_ok:
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, not_ns_accepted_absurd(M.NsRejectUnsupportedActiveChain{}, ok, Unit{}))
    case True{}:
      check_ns_list_sound(reqs, active, ok)

def Laws.namespace_accepted_implies_all_requirements_supported(active, reqs, ok):
  ns_go_sound(M.is_supported_chain(active), active, reqs, ok)

def Laws.approved_namespaces_only_active_chain_and_supported(active, reqs, opts):
  match reqs opts:
    case Nil{} Nil{}:
      {==}
    case Nil{} Con{+oh, +ot}:
      hm = collect_methods_supported(oh <> ot, active)
      he = collect_events_supported(oh <> ot, active)
      %Equal.sym(Bool, M.all_methods_supported(M.collect_methods(oh <> ot, active)), True{}, hm) : {Bool.and(_, M.all_events_supported(M.collect_events(oh <> ot, active))) == True{} : Bool}
      he
    case Con{+rh, +rt} +o:
      hm1 = collect_methods_supported(rh <> rt, active)
      hm2 = collect_methods_supported(o, active)
      hm = all_methods_append(M.collect_methods(rh <> rt, active), M.collect_methods(o, active), hm1, hm2)
      he1 = collect_events_supported(rh <> rt, active)
      he2 = collect_events_supported(o, active)
      he = all_events_append(M.collect_events(rh <> rt, active), M.collect_events(o, active), he1, he2)
      %Equal.sym(Bool, M.all_methods_supported(List.append(&2, M.WcMethod, M.collect_methods(rh <> rt, active), M.collect_methods(o, active))), True{}, hm) : {Bool.and(_, M.all_events_supported(List.append(&2, M.WcEvent, M.collect_events(rh <> rt, active), M.collect_events(o, active)))) == True{} : Bool}
      he

def Laws.approved_namespaces_chains_is_singleton_active(active, reqs, opts):
  match reqs opts:
    case Nil{} Nil{}:
      {==}
    case Nil{} Con{_, _}:
      {==}
    case Con{_, _} _:
      {==}

def Laws.approved_namespaces_empty_grants_all_supported(active):
  {==}

def Laws.signed_message_payload_injective(m1, m2, eq):
  e1 = append_cancel_left(
    U32,
    M.signed_message_prefix(),
    List.append(&2, U32, M.digits_to_bytes(M.nat_to_digits(List.length(&2, U32, m1))), 10 <> m1),
    List.append(&2, U32, M.digits_to_bytes(M.nat_to_digits(List.length(&2, U32, m2))), 10 <> m2),
    eq
  )
  digits_sep_injective(
    M.nat_to_digits(List.length(&2, U32, m1)),
    M.nat_to_digits(List.length(&2, U32, m2)),
    m1,
    m2,
    e1
  )

def Laws.signed_message_payload_has_domain_prefix(msg):
  {==}

def payload_len_step(
  +mlen: Nat,
  +dlen: Nat,
  +plen: Nat,
  e_plen: {plen == Nat.add(23n, Nat.add(dlen, 1n+mlen)) : Nat},
  h_dlen: {Nat.is_le(1n, dlen) == True{} : Bool}
) -> {Nat.is_le(Nat.add(25n, mlen), plen) == True{} : Bool}:
  %Equal.sym(Nat, plen, Nat.add(23n, Nat.add(dlen, 1n+mlen)), e_plen) : {Nat.is_le(Nat.add(25n, mlen), _) == True{} : Bool}
  %Equal.sym(Nat, Nat.add(dlen, 1n+mlen), 1n+Nat.add(dlen, mlen), NatL.add_succ(dlen, mlen)) : {Nat.is_le(Nat.add(25n, mlen), Nat.add(23n, _)) == True{} : Bool}
  %Equal.sym(Nat, Nat.add(23n, 1n+Nat.add(dlen, mlen)), 24n+Nat.add(dlen, mlen), NatL.add_succ(23n, Nat.add(dlen, mlen))) : {Nat.is_le(Nat.add(25n, mlen), _) == True{} : Bool}
  NatL.add_monotone_le(1n, dlen, mlen, mlen, h_dlen, NatL.is_le_refl(mlen))

def payload_len_eq(+msg: List<&2, U32>) -> {List.length(&2, U32, M.encode_signed_message_payload(msg)) == Nat.add(23n, Nat.add(List.length(&2, M.Digit, M.nat_to_digits(List.length(&2, U32, msg))), 1n+List.length(&2, U32, msg))) : Nat}:
  +mlen = List.length(&2, U32, msg)
  +ds = M.nat_to_digits(mlen)
  +dbytes = M.digits_to_bytes(ds)
  e_outer = u32_list_length_append(M.signed_message_prefix(), List.append(&2, U32, dbytes, 10 <> msg))
  e_inner = u32_list_length_append(dbytes, 10 <> msg)
  e_dlen = digits_to_bytes_len(ds)
  %Equal.sym(Nat, List.length(&2, U32, M.encode_signed_message_payload(msg)), Nat.add(23n, List.length(&2, U32, List.append(&2, U32, dbytes, 10 <> msg))), e_outer) : {_ == Nat.add(23n, Nat.add(List.length(&2, M.Digit, ds), 1n+mlen)) : Nat}
  %Equal.sym(Nat, List.length(&2, U32, List.append(&2, U32, dbytes, 10 <> msg)), Nat.add(List.length(&2, U32, dbytes), 1n+mlen), e_inner) : {Nat.add(23n, _) == Nat.add(23n, Nat.add(List.length(&2, M.Digit, ds), 1n+mlen)) : Nat}
  %Equal.sym(Nat, List.length(&2, U32, dbytes), List.length(&2, M.Digit, ds), e_dlen) : {Nat.add(23n, Nat.add(_, 1n+mlen)) == Nat.add(23n, Nat.add(List.length(&2, M.Digit, ds), 1n+mlen)) : Nat}
  {==}

def Laws.signed_message_payload_length_lower_bound(msg):
  payload_len_step(
    List.length(&2, U32, msg),
    List.length(&2, M.Digit, M.nat_to_digits(List.length(&2, U32, msg))),
    List.length(&2, U32, M.encode_signed_message_payload(msg)),
    payload_len_eq(msg),
    nat_to_digits_len_ge1(List.length(&2, U32, msg))
  )

def payload_eq_pref_true(
  +msg: List<&2, U32>,
  +raw_hash: List<&2, U32>,
  eq: {M.encode_signed_message_payload(msg) == raw_hash : List<&2, U32>}
) -> {True{} == M.has_signed_message_prefix(raw_hash) : Bool}:
  %eq : {M.has_signed_message_prefix(M.encode_signed_message_payload(msg)) == M.has_signed_message_prefix(_) : Bool}
  {==}

def Laws.signed_message_payload_disjoint_from_unprefixed_hash(msg, raw_hash, no_pref, eq):
  e_tf = Equal.trans(Bool, True{}, M.has_signed_message_prefix(raw_hash), False{}, payload_eq_pref_true(msg, raw_hash, eq), no_pref)
  NatL.true_is_not_false(e_tf)

def validate_pick_sound(+b: Bool, ok: {M.validate_send_account_block.pick(b) == M.ValidOk{} : M.ValidationOutcome}) -> {b == True{} : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, valid_err_not_ok(5003, ok))

def Laws.send_block_valid_implies_all_invariants(blk, active_id, ok):
  validate_pick_sound(M.send_block_invariants_hold(blk, active_id), ok)

def Laws.send_block_any_violation_rejected_5003(blk, active_id, bad):
  %Equal.sym(Bool, M.send_block_invariants_hold(blk, active_id), False{}, bad) : {M.validate_send_account_block.pick(_) == M.ValidErr{5003} : M.ValidationOutcome}
  {==}

def Laws.signer_null_or_empty_defaults_to_active(active, owned):
  e = NatL.is_eq_same(active)
  %Equal.sym(Bool, Nat.is_eq(active, active), True{}, e) : {Bool.and(_, _) == True{} : Bool}
  {==}

def Laws.signer_owned_address_allowed(active, req, owned, is_owned):
  %Equal.sym(Bool, M.nat_list_contains(owned, req), True{}, is_owned) : {M.resolve_signer_address.pick(req, _) == M.SignerResolved{req} : M.SignerResolution}
  {==}

def Laws.signer_foreign_address_rejected(active, req, owned, not_owned):
  %Equal.sym(Bool, M.nat_list_contains(owned, req), False{}, not_owned) : {M.resolve_signer_address.pick(req, _) == M.SignerRejectedUnsupportedAccounts{} : M.SignerResolution}
  {==}

def Laws.revalidate_rejects_locked_wallet(m, sess_active, has_req_id, still_pending, svc_ch, sess_ch, act_ch):
  {==}

def Laws.revalidate_rejects_inactive_session(m, has_req_id, still_pending, svc_ch, sess_ch, act_ch):
  {==}

def Laws.revalidate_rejects_non_pending_5005(m, svc_ch, sess_ch, act_ch):
  {==}

def Laws.revalidate_rejects_chain_drift_5003(m, svc_ch, sess_ch, act_ch, need_chain, drifted):
  %Equal.sym(Bool, M.method_requires_active_chain_match(m), True{}, need_chain) : {M.revalidate.chain(_, Bool.and(M.chain_id_eq(svc_ch, act_ch), M.chain_id_eq(sess_ch, act_ch))) == M.RevalErr{5003} : M.RevalidationResult}
  %Equal.sym(Bool, Bool.and(M.chain_id_eq(svc_ch, act_ch), M.chain_id_eq(sess_ch, act_ch)), False{}, drifted) : {M.revalidate.chain(True{}, _) == M.RevalErr{5003} : M.RevalidationResult}
  {==}

def uri_card_pick_cleared(+cur: Nat, +non_empty: Bool, +b: Bool) -> {M.card_outcome_cleared(M.uri_card_on_pair_success.pick(cur, non_empty, b)) == b : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.uri_card_clears_iff_revision_matches(cur_rev, sub_rev, non_empty):
  uri_card_pick_cleared(cur_rev, non_empty, Nat.is_eq(sub_rev, cur_rev))

def preflight_locked_false(
  +meta_ok: Bool,
  +tx_ok: Bool,
  +reval_ok: Bool,
  h: {reval_ok == False{} : Bool}
) -> {Bool.and(meta_ok, Bool.and(tx_ok, reval_ok)) == False{} : Bool}:
  e1 = bool_and_right_false(tx_ok, reval_ok, h)
  bool_and_right_false(meta_ok, Bool.and(tx_ok, reval_ok), e1)

def preflight_cases(
  +scam: Bool,
  +locked: Bool,
  +url: M.ParsedUrl,
  +blk: M.SendAccountBlock,
  +active_chain_id: Nat,
  +active_addr: Nat,
  +req_addr: M.RequestedAddress,
  +owned_addrs: List<&2, Nat>,
  +sess_active: Bool,
  +has_req_id: Bool,
  +still_pending: Bool,
  +svc_ch: M.ChainId,
  +sess_ch: M.ChainId,
  +act_ch: M.ChainId,
  +ctx: M.VerifyContext,
  hscam: {M.is_verify_scam(ctx) == scam : Bool},
  blocked: {Bool.or(scam, locked) == True{} : Bool}
) -> {M.parallel_send_preflight(ctx, url, blk, active_chain_id, active_addr, req_addr, owned_addrs, M.RevalidationState{locked, sess_active, has_req_id, still_pending, svc_ch, sess_ch, act_ch}) == False{} : Bool}:
  match scam locked:
    case True{} _:
      %Equal.sym(Bool, M.is_verify_scam(ctx), True{}, hscam) : {Bool.and(Bool.and(Bool.not(_), M.is_url_allowed(M.sanitize_http_url(url))), Bool.and(M.check_tx_and_signer_branch(blk, active_chain_id, active_addr, req_addr, owned_addrs), M.check_reval_branch(M.RevalidationState{locked, sess_active, has_req_id, still_pending, svc_ch, sess_ch, act_ch}))) == False{} : Bool}
      {==}
    case False{} True{}:
      preflight_locked_false(
        M.check_metadata_branch(ctx, url),
        M.check_tx_and_signer_branch(blk, active_chain_id, active_addr, req_addr, owned_addrs),
        M.check_reval_branch(M.RevalidationState{True{}, sess_active, has_req_id, still_pending, svc_ch, sess_ch, act_ch}),
        {==}
      )
    case False{} False{}:
      Empty.absurd(
        {M.parallel_send_preflight(ctx, url, blk, active_chain_id, active_addr, req_addr, owned_addrs, M.RevalidationState{False{}, sess_active, has_req_id, still_pending, svc_ch, sess_ch, act_ch}) == False{} : Bool},
        NatL.false_is_not_true(blocked)
      )

def Laws.parallel_send_preflight_equiv_sequential(ctx, url, blk, active_chain_id, active_addr, req_addr, owned_addrs, reval_st):
  {==}

def Laws.parallel_preflight_accepts_valid_send(active_addr):
  {==}

def Laws.parallel_preflight_blocks_scam_or_locked(ctx, url, blk, active_chain_id, active_addr, req_addr, owned_addrs, reval_st, blocked):
  match reval_st:
    case M.RevalidationState{+locked, +sess_active, +has_req_id, +still_pending, +svc_ch, +sess_ch, +act_ch}:
      preflight_cases(
        M.is_verify_scam(ctx),
        locked,
        url,
        blk,
        active_chain_id,
        active_addr,
        req_addr,
        owned_addrs,
        sess_active,
        has_req_id,
        still_pending,
        svc_ch,
        sess_ch,
        act_ch,
        ctx,
        {==},
        blocked
      )
