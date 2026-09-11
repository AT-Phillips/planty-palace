/// Outbound links and contact details.
///
/// Thicket ships through TestFlight and has no public App Store listing yet,
/// so [appStoreId] is still a placeholder. Anything that would deep-link to
/// that listing is gated behind [hasAppStoreListing] rather than shipped
/// pointing at a URL that resolves to an App Store error page - a dead "Rate
/// this app" row is worse than no row at all.
///
/// To enable them: replace [appStoreId] with the real numeric ID from App
/// Store Connect. The Rate and Share rows reappear on their own.
const String appStoreId = 'REPLACE_WITH_APP_STORE_ID';

bool get hasAppStoreListing =>
    appStoreId.isNotEmpty && int.tryParse(appStoreId) != null;

const String appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';
const String appStoreReviewUrl = '$appStoreUrl?action=write-review';

const String supportEmail = 'atom.phillips@gmail.com';
