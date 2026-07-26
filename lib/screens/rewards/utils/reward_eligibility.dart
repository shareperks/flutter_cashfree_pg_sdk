/// 3-tier reward eligibility (high → mid → low).
///
/// Product labels ↔ API:
/// 1. **Shareholder Reward** — maximum reward
///    (`isEligible` → `withHolderRewardRate`) — listed companies only in UI
/// 2. **Member Reward** — any-holding reward
///    (`isBrokerageEligible` → `withAnyHoldingRewardRate`)
///    Non-listed connected holdings also map here (API may set `isEligible`)
/// 3. **Standard Reward** — no holdings for this reward
///    (neither flag → `nonHolderRewardRate`)
enum RewardEligibilityTier { fullyEligible, brokerageEligible, nonHolder }

/// Product-facing label shown in the rates list and top eligibility banner.
enum RewardRateLabel { shareholder, member, standard }

/// Resolves which eligibility tier applies.
///
/// [reqReimport] forces Standard Reward until holdings are refreshed.
RewardEligibilityTier resolveRewardTier({
  required bool isEligible,
  required bool isBrokerageEligible,
  bool reqReimport = false,
}) {
  if (reqReimport) return RewardEligibilityTier.nonHolder;
  if (isEligible) return RewardEligibilityTier.fullyEligible;
  if (isBrokerageEligible) return RewardEligibilityTier.brokerageEligible;
  return RewardEligibilityTier.nonHolder;
}

/// Maps API tier → product label (Shareholder / Member / Standard).
///
/// Non-listed never surfaces Shareholder: connected holdings → Member.
RewardRateLabel resolveRewardRateLabel({
  required RewardEligibilityTier tier,
  required bool listedOnExchange,
}) {
  if (!listedOnExchange) {
    return tier == RewardEligibilityTier.nonHolder
        ? RewardRateLabel.standard
        : RewardRateLabel.member;
  }
  switch (tier) {
    case RewardEligibilityTier.fullyEligible:
      return RewardRateLabel.shareholder;
    case RewardEligibilityTier.brokerageEligible:
      return RewardRateLabel.member;
    case RewardEligibilityTier.nonHolder:
      return RewardRateLabel.standard;
  }
}

extension RewardRateLabelX on RewardRateLabel {
  String get title {
    switch (this) {
      case RewardRateLabel.shareholder:
        return 'Shareholder Reward';
      case RewardRateLabel.member:
        return 'Brokerage Reward';
      case RewardRateLabel.standard:
        return 'Standard Reward';
    }
  }

  String subtitle(String perkLabel) {
    switch (this) {
      case RewardRateLabel.shareholder:
        return 'Maximum $perkLabel rate applies';
      case RewardRateLabel.member:
        return 'Brokerage $perkLabel rate applies';
      case RewardRateLabel.standard:
        return 'Standard $perkLabel rate applies';
    }
  }
}

num? _positiveOrNull(num? rate) => rate != null && rate > 0 ? rate : null;

/// Picks the active reward rate for [tier].
///
/// Listed:
/// - Shareholder → `withHolderRewardRate`
/// - Member → `withAnyHoldingRewardRate`
/// - Standard → `nonHolderRewardRate`
///
/// Non-listed (no Shareholder):
/// - Member (connected / `isEligible`) → `withAnyHoldingRewardRate`
///   (fall back to `withHolderRewardRate` only if any-holding rate is unset)
/// - Standard → `nonHolderRewardRate`
num resolveRewardRate({
  required RewardEligibilityTier tier,
  num? withHolderRewardRate,
  num? withAnyHoldingRewardRate,
  num? nonHolderRewardRate,
  bool listedOnExchange = true,
}) {
  switch (tier) {
    case RewardEligibilityTier.fullyEligible:
      if (!listedOnExchange) {
        // Non-listed connected → Member / any-holding rate.
        return _positiveOrNull(withAnyHoldingRewardRate) ??
            _positiveOrNull(withHolderRewardRate) ??
            _positiveOrNull(nonHolderRewardRate) ??
            0;
      }
      // Listed Shareholder / maximum.
      return _positiveOrNull(withHolderRewardRate) ??
          _positiveOrNull(withAnyHoldingRewardRate) ??
          _positiveOrNull(nonHolderRewardRate) ??
          0;
    case RewardEligibilityTier.brokerageEligible:
      // Member / any-holding.
      return _positiveOrNull(withAnyHoldingRewardRate) ??
          _positiveOrNull(nonHolderRewardRate) ??
          0;
    case RewardEligibilityTier.nonHolder:
      return _positiveOrNull(nonHolderRewardRate) ?? 0;
  }
}

/// Convenience: resolve tier then rate in one call.
num resolveActiveRewardRate({
  required bool isEligible,
  required bool isBrokerageEligible,
  num? withHolderRewardRate,
  num? withAnyHoldingRewardRate,
  num? nonHolderRewardRate,
  bool reqReimport = false,
  bool listedOnExchange = true,
}) {
  final tier = resolveRewardTier(
    isEligible: isEligible,
    isBrokerageEligible: isBrokerageEligible,
    reqReimport: reqReimport,
  );
  return resolveRewardRate(
    tier: tier,
    withHolderRewardRate: withHolderRewardRate,
    withAnyHoldingRewardRate: withAnyHoldingRewardRate,
    nonHolderRewardRate: nonHolderRewardRate,
    listedOnExchange: listedOnExchange,
  );
}

/// Member rate row on listed companies when an any-holding rate is configured.
bool shouldShowBrokerageRateRow({
  required bool listedOnExchange,
  num? withAnyHoldingRewardRate,
}) {
  return listedOnExchange &&
      withAnyHoldingRewardRate != null &&
      withAnyHoldingRewardRate > 0;
}

/// Rate shown on the **Member Reward** row — always the any-holding rate.
///
/// Listed and non-listed both use [withAnyHoldingRewardRate].
/// For non-listed, if that field is unset/0, fall back to [withHolderRewardRate]
/// (some backends only populate the holder field for connected rewards).
num? memberRewardDisplayRate({
  required bool listedOnExchange,
  num? withHolderRewardRate,
  num? withAnyHoldingRewardRate,
}) {
  final anyHolding = _positiveOrNull(withAnyHoldingRewardRate);
  if (anyHolding != null) return anyHolding;
  // Non-listed only: fall back if any-holding rate was not configured.
  if (!listedOnExchange) {
    return _positiveOrNull(withHolderRewardRate) ?? withAnyHoldingRewardRate;
  }
  return withAnyHoldingRewardRate;
}

/// Rate shown on the top eligibility banner — must match the active rates row
/// and the claim/calc applied rate.
num? activeRewardDisplayRate({
  required RewardEligibilityTier tier,
  required bool listedOnExchange,
  num? withHolderRewardRate,
  num? withAnyHoldingRewardRate,
  num? nonHolderRewardRate,
}) {
  final label = resolveRewardRateLabel(
    tier: tier,
    listedOnExchange: listedOnExchange,
  );
  switch (label) {
    case RewardRateLabel.shareholder:
      return withHolderRewardRate;
    case RewardRateLabel.member:
      return memberRewardDisplayRate(
        listedOnExchange: listedOnExchange,
        withHolderRewardRate: withHolderRewardRate,
        withAnyHoldingRewardRate: withAnyHoldingRewardRate,
      );
    case RewardRateLabel.standard:
      return nonHolderRewardRate;
  }
}
