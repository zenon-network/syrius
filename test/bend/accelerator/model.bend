import Base

# Syrius Accelerator-Z Formal Verification Model
# ==============================================
#
# Unit Scaling Convention (for conformance tests):
# - Vote counts, pillar counts, and quorum counts are exact non-negative integers (Nat).
# - Progress-bar spans are scaled in percentage points [0..100] (100 = 100%,
#   matching AcceleratorVotingProgressBar's clamped [0.0..1.0] fractions).
# - Project creation fee and budget caps use whole-coin units:
#     PROJECT_CREATION_FEE_ZNN =     1  (1 ZNN)
#     PROJECT_MIN_ZNN          =    10  (10 ZNN)
#     PROJECT_MAX_ZNN          =  5000  (5,000 ZNN)
#     PROJECT_MIN_QSR          =   100  (100 QSR)
#     PROJECT_MAX_QSR          = 50000  (50,000 QSR)
#   (and parametric range/conservation helpers work in arbitrary base units).

# ------------------------------------------------------------------------------
# 1. Constants
# ------------------------------------------------------------------------------

def QUORUM_NUM() -> Nat:
  33n

def QUORUM_DEN() -> Nat:
  100n

def BAR_SCALE() -> Nat:
  100n

def PROJECT_CREATION_FEE_ZNN() -> Nat:
  1n

def PROJECT_MIN_ZNN() -> Nat:
  10n

def PROJECT_MAX_ZNN() -> Nat:
  5000n

def PROJECT_MIN_QSR() -> Nat:
  100n

def PROJECT_MAX_QSR() -> Nat:
  50000n

# ------------------------------------------------------------------------------
# 2. Pillar Role Resolution & Voting Authorization (accelerator_pillar_resolver)
# ------------------------------------------------------------------------------

type PillarEntry is Data:
  Pillar{id: Nat, owner: Nat, producer: Nat}

type VoteMethod is Data:
  ByName{}
  ByProdAddress{}

type ProjectStatus is Data:
  Voting{}
  Active{}
  Paid{}
  Closed{}
  Completed{}

def vote_method_is_by_name(+m: VoteMethod) -> Bool:
  match m:
    case ByName{}:
      True{}
    case ByProdAddress{}:
      False{}

def vote_method_is_by_prod(+m: VoteMethod) -> Bool:
  match m:
    case ByName{}:
      False{}
    case ByProdAddress{}:
      True{}

def status_eq(+a: ProjectStatus, +b: ProjectStatus) -> Bool:
  match a b:
    case Voting{} Voting{}:
      True{}
    case Active{} Active{}:
      True{}
    case Paid{} Paid{}:
      True{}
    case Closed{} Closed{}:
      True{}
    case Completed{} Completed{}:
      True{}
    case _ _:
      False{}

def status_is_active(+s: ProjectStatus) -> Bool:
  match s:
    case Active{}:
      True{}
    case _:
      False{}

def status_is_voting(+s: ProjectStatus) -> Bool:
  match s:
    case Voting{}:
      True{}
    case _:
      False{}

def status_is_paid(+s: ProjectStatus) -> Bool:
  match s:
    case Paid{}:
      True{}
    case _:
      False{}

def pick_pillar(+matched: Bool, +p: PillarEntry, +fallback: Maybe<&2, PillarEntry>) -> Maybe<&2, PillarEntry>:
  match matched:
    case True{}:
      Some{p}
    case False{}:
      fallback

def find_owner(pillars: +List<PillarEntry>, +addr: Nat) -> Maybe<&2, PillarEntry>:
  match pillars:
    case Nil{}:
      None{}
    case Con{Pillar{id, +own, prod}, t}:
      pick_pillar(Nat.is_eq(own, addr), Pillar{id, own, prod}, find_owner(t, addr))

def find_producer(pillars: +List<PillarEntry>, +addr: Nat) -> Maybe<&2, PillarEntry>:
  match pillars:
    case Nil{}:
      None{}
    case Con{Pillar{id, own, +prod}, t}:
      pick_pillar(Nat.is_eq(prod, addr), Pillar{id, own, prod}, find_producer(t, addr))

def pillar_for_address.or(+own_match: Maybe<&2, PillarEntry>, +pillars: +List<PillarEntry>, +addr: Nat) -> Maybe<&2, PillarEntry>:
  match own_match:
    case Some{p}:
      Some{p}
    case None{}:
      find_producer(pillars, addr)

def pillar_for_address(+pillars: +List<PillarEntry>, +addr: Nat) -> Maybe<&2, PillarEntry>:
  pillar_for_address.or(find_owner(pillars, addr), pillars, addr)

def vote_method_for.pick(+is_owner: Bool) -> VoteMethod:
  match is_owner:
    case True{}:
      ByName{}
    case False{}:
      ByProdAddress{}

def vote_method_for(+pillar: PillarEntry, +addr: Nat) -> VoteMethod:
  match pillar:
    case Pillar{_, own, _}:
      vote_method_for.pick(Nat.is_eq(own, addr))

def can_submit_vote(+pillar: Maybe<&2, PillarEntry>, +status: ProjectStatus) -> Bool:
  match pillar:
    case None{}:
      False{}
    case Some{_}:
      status_is_voting(status)

# ------------------------------------------------------------------------------
# 3. Quorum, Majority & Clamped 3-Span Progress-Bar Conservation
# ------------------------------------------------------------------------------

def quorum_needed(+total_pillars: Nat) -> Nat:
  match total_pillars:
    case 0n:
      0n
    case 1n+p:
      1n+Nat.div(Nat.mul(1n+p, QUORUM_NUM()), QUORUM_DEN())

def vote_total(+yes: Nat, +no: Nat, +abstain: Nat) -> Nat:
  Nat.add(Nat.add(yes, no), abstain)

def quorum_reached(+total_votes: Nat, +total_pillars: Nat) -> Bool:
  Bool.and(Nat.is_gt(total_pillars, 0n), Nat.is_ge(total_votes, quorum_needed(total_pillars)))

def has_majority(+yes: Nat, +no: Nat) -> Bool:
  Nat.is_gt(yes, no)

type BarSpans3 is Data:
  Spans3{s1: Nat, s2: Nat, s3: Nat}

def bar_span_sum(+b: BarSpans3) -> Nat:
  match b:
    case Spans3{s1, s2, s3}:
      Nat.add(Nat.add(s1, s2), s3)

def clamped_bar_3_with(+v1: Nat, +v2: Nat, +v3: Nat, +denom: Nat, +scale: Nat) -> BarSpans3:
  match denom:
    case 0n:
      Spans3{0n, 0n, 0n}
    case 1n+dp:
      +s1 = Nat.min(scale, Nat.div(Nat.mul(v1, scale), 1n+dp))
      +rem1 = Nat.sub(scale, s1)
      +s2 = Nat.min(rem1, Nat.div(Nat.mul(v2, scale), 1n+dp))
      +rem2 = Nat.sub(rem1, s2)
      +s3 = Nat.min(rem2, Nat.div(Nat.mul(v3, scale), 1n+dp))
      Spans3{s1, s2, s3}

def clamped_bar_3(+yes: Nat, +no: Nat, +abstain: Nat, +total: Nat) -> BarSpans3:
  clamped_bar_3_with(yes, no, abstain, total, BAR_SCALE())

def quorum_progress_bar(+quorum: Nat, +total_pillars: Nat) -> BarSpans3:
  +qn = quorum_needed(total_pillars)
  +to_quorum = Nat.min(Nat.sub(qn, quorum), total_pillars)
  +can_still = Nat.min(Nat.sub(Nat.sub(total_pillars, quorum), to_quorum), total_pillars)
  clamped_bar_3_with(quorum, to_quorum, can_still, total_pillars, BAR_SCALE())

# ------------------------------------------------------------------------------
# 4. ProjectListBloc Visibility & Tag Conjunction
# ------------------------------------------------------------------------------

type FilterTags is Data:
  Tags{my_projects: Bool, only_accepted: Bool, needs_voting: Bool, already_voted: Bool}

type ProjectView is Data:
  ProjView{status: ProjectStatus, is_owner: Bool, has_needs_voting: Bool, has_already_voted: Bool}

def proj_all_tags_satisfied(+p: ProjectView) -> Bool:
  match p:
    case ProjView{st, own, hnv, hav}:
      Bool.and(own, Bool.and(status_is_active(st), Bool.and(hnv, hav)))

def is_visible_project(+has_pillar: Bool, +status: ProjectStatus, +is_owner: Bool) -> Bool:
  match has_pillar:
    case True{}:
      True{}
    case False{}:
      Bool.or(status_is_active(status), is_owner)

def strip_pillar_tags(+has_pillar: Bool, +tags: FilterTags) -> FilterTags:
  match has_pillar:
    case True{}:
      tags
    case False{}:
      match tags:
        case Tags{mp, oa, _, _}:
          Tags{mp, oa, False{}, False{}}

def bool_implies(+cond: Bool, +req: Bool) -> Bool:
  match cond:
    case False{}:
      True{}
    case True{}:
      req

def matches_tags(+has_pillar: Bool, +tags: FilterTags, +proj: ProjectView) -> Bool:
  match tags proj:
    case Tags{mp, oa, nv, av} ProjView{st, own, hnv, hav}:
      Bool.and(
        bool_implies(mp, own),
        Bool.and(
          bool_implies(oa, status_is_active(st)),
          Bool.and(
            bool_implies(Bool.and(has_pillar, nv), hnv),
            bool_implies(Bool.and(has_pillar, av), hav)
          )
        )
      )

def matches_project_list(+has_pillar: Bool, +tags: FilterTags, +proj: ProjectView) -> Bool:
  match proj:
    case ProjView{st, own, hnv, hav}:
      Bool.and(
        matches_tags(has_pillar, tags, ProjView{st, own, hnv, hav}),
        is_visible_project(has_pillar, st, own)
      )

# ------------------------------------------------------------------------------
# 5. Donation Validation & Partial-Commit Retry Safety (SubmitDonationBloc)
# ------------------------------------------------------------------------------

# SignedAmt models exact non-negative values and negative values -(1 + mag).
type SignedAmt is Data:
  NonNeg{val: Nat}
  Neg{mag: Nat}

def is_valid_donation(+znn: SignedAmt, +qsr: SignedAmt, +bal_znn: Nat, +bal_qsr: Nat) -> Bool:
  match znn qsr:
    case NonNeg{z} NonNeg{q}:
      Bool.and(
        Nat.is_le(z, bal_znn),
        Bool.and(
          Nat.is_le(q, bal_qsr),
          Bool.or(Nat.is_gt(z, 0n), Nat.is_gt(q, 0n))
        )
      )
    case _ _:
      False{}

type DonationStatus is Data:
  DonInitial{}
  DonSubmitted{}
  DonFailed{znn_submitted: Bool}

type DonationForm is Data:
  DonForm{znn: Nat, qsr: Nat, status: DonationStatus}

type DonationAttempt is Data:
  DonAttempt{sent_znn: Bool, sent_qsr: Bool, next_form: DonationForm}

def don_status_is_submitted(+st: DonationStatus) -> Bool:
  match st:
    case DonSubmitted{}:
      True{}
    case _:
      False{}

def don_status_znn_submitted(+st: DonationStatus) -> Bool:
  match st:
    case DonFailed{zs}:
      zs
    case _:
      False{}

def form_znn(+f: DonationForm) -> Nat:
  match f:
    case DonForm{z, _, _}:
      z

def form_qsr(+f: DonationForm) -> Nat:
  match f:
    case DonForm{_, q, _}:
      q

def form_status(+f: DonationForm) -> DonationStatus:
  match f:
    case DonForm{_, _, st}:
      st

def attempt_sent_znn(+a: DonationAttempt) -> Bool:
  match a:
    case DonAttempt{sz, _, _}:
      sz

def attempt_sent_qsr(+a: DonationAttempt) -> Bool:
  match a:
    case DonAttempt{_, sq, _}:
      sq

def attempt_form(+a: DonationAttempt) -> DonationForm:
  match a:
    case DonAttempt{_, _, f}:
      f

def submit_donation_attempt(+form: DonationForm, +znn_ok: Bool, +qsr_ok: Bool) -> DonationAttempt:
  match form:
    case DonForm{z, q, _}:
      match z q:
        case 0n 0n:
          DonAttempt{False{}, False{}, DonForm{0n, 0n, DonFailed{False{}}}}
        case 1n+zp 0n:
          match znn_ok:
            case True{}:
              DonAttempt{True{}, False{}, DonForm{0n, 0n, DonSubmitted{}}}
            case False{}:
              DonAttempt{False{}, False{}, DonForm{1n+zp, 0n, DonFailed{False{}}}}
        case 0n 1n+qp:
          match qsr_ok:
            case True{}:
              DonAttempt{False{}, True{}, DonForm{0n, 0n, DonSubmitted{}}}
            case False{}:
              DonAttempt{False{}, False{}, DonForm{0n, 1n+qp, DonFailed{False{}}}}
        case 1n+zp 1n+qp:
          match znn_ok qsr_ok:
            case False{} _:
              DonAttempt{False{}, False{}, DonForm{1n+zp, 1n+qp, DonFailed{False{}}}}
            case True{} False{}:
              # ZNN committed, QSR failed: clear ZNN amount to 0 so retry submits ONLY QSR!
              DonAttempt{True{}, False{}, DonForm{0n, 1n+qp, DonFailed{True{}}}}
            case True{} True{}:
              DonAttempt{True{}, True{}, DonForm{0n, 0n, DonSubmitted{}}}

# ------------------------------------------------------------------------------
# 6. Project & Phase Budget Conservation & Sequential Phase Gate
# ------------------------------------------------------------------------------

def valid_project_budget(+owner_znn_bal: Nat, +znn_needed: Nat, +qsr_needed: Nat) -> Bool:
  Bool.and(
    Nat.is_ge(owner_znn_bal, PROJECT_CREATION_FEE_ZNN()),
    Bool.and(
      Bool.and(Nat.is_le(PROJECT_MIN_ZNN(), znn_needed), Nat.is_le(znn_needed, PROJECT_MAX_ZNN())),
      Bool.and(Nat.is_le(PROJECT_MIN_QSR(), qsr_needed), Nat.is_le(qsr_needed, PROJECT_MAX_QSR()))
    )
  )

def remaining_funds(+total: Nat, +paid: Nat) -> Nat:
  Nat.sub(total, paid)

def valid_phase_funds(+phase_znn: Nat, +phase_qsr: Nat, +total_znn: Nat, +paid_znn: Nat, +total_qsr: Nat, +paid_qsr: Nat) -> Bool:
  Bool.and(
    Nat.is_le(phase_znn, remaining_funds(total_znn, paid_znn)),
    Nat.is_le(phase_qsr, remaining_funds(total_qsr, paid_qsr))
  )

def last_phase_allows_next(+last_phase: Maybe<&2, ProjectStatus>) -> Bool:
  match last_phase:
    case None{}:
      True{}
    case Some{st}:
      status_is_paid(st)

def can_create_phase(+is_owner: Bool, +project_status: ProjectStatus, +last_phase: Maybe<&2, ProjectStatus>) -> Bool:
  Bool.and(
    is_owner,
    Bool.and(status_is_active(project_status), last_phase_allows_next(last_phase))
  )

def can_update_phase(+is_owner: Bool, +phase_status: ProjectStatus) -> Bool:
  Bool.and(is_owner, status_is_voting(phase_status))

# ------------------------------------------------------------------------------
# 7. Parallelized Multi-Check Helper (Bend parallel-let with named defs on RHS)
# ------------------------------------------------------------------------------

def check_governance_leg(+pillar: Maybe<&2, PillarEntry>, +status: ProjectStatus, +yes: Nat, +no: Nat, +abstain: Nat, +total_pillars: Nat) -> Bool:
  Bool.and(
    can_submit_vote(pillar, status),
    Bool.and(quorum_reached(vote_total(yes, no, abstain), total_pillars), has_majority(yes, no))
  )

def check_budget_leg(+owner_znn_bal: Nat, +znn_needed: Nat, +qsr_needed: Nat, +is_owner: Bool, +proj_status: ProjectStatus, +last_phase: Maybe<&2, ProjectStatus>) -> Bool:
  Bool.and(
    valid_project_budget(owner_znn_bal, znn_needed, qsr_needed),
    can_create_phase(is_owner, proj_status, last_phase)
  )

def parallel_accelerator_audit(
  +pillar: Maybe<&2, PillarEntry>,
  +vote_status: ProjectStatus,
  +yes: Nat,
  +no: Nat,
  +abstain: Nat,
  +total_pillars: Nat,
  +owner_znn_bal: Nat,
  +znn_needed: Nat,
  +qsr_needed: Nat,
  +is_owner: Bool,
  +proj_status: ProjectStatus,
  +last_phase: Maybe<&2, ProjectStatus>
) -> Bool:
  a b = check_governance_leg(pillar, vote_status, yes, no, abstain, total_pillars) check_budget_leg(owner_znn_bal, znn_needed, qsr_needed, is_owner, proj_status, last_phase)
  Bool.and(a, b)
