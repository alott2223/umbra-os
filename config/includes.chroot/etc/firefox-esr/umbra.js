// Umbra OS — system-wide Firefox hardening (autoconfig).
// Loaded via /usr/lib/firefox-esr/defaults/pref/autoconfig.js (set by branding hook).
// A pragmatic arkenfox-style subset: privacy + anti-fingerprinting without
// breaking everyday browsing. Users can still override per-profile.

// --- Telemetry / data collection: off ---
lockPref("datareporting.healthreport.uploadEnabled", false);
lockPref("datareporting.policy.dataSubmissionEnabled", false);
lockPref("toolkit.telemetry.enabled", false);
lockPref("toolkit.telemetry.unified", false);
lockPref("toolkit.telemetry.archive.enabled", false);
lockPref("app.shield.optoutstudies.enabled", false);
lockPref("browser.discovery.enabled", false);
lockPref("browser.newtabpage.activity-stream.feeds.telemetry", false);

// --- Anti-fingerprinting & tracking protection ---
defaultPref("privacy.resistFingerprinting", true);
defaultPref("privacy.trackingprotection.enabled", true);
defaultPref("privacy.trackingprotection.socialtracking.enabled", true);
defaultPref("privacy.partition.network_state", true);
defaultPref("privacy.firstparty.isolate", true);
defaultPref("network.cookie.cookieBehavior", 5); // dFPI / total cookie protection

// --- Encrypted DNS / connection safety ---
defaultPref("network.trr.mode", 2);              // DoH with system fallback
defaultPref("network.trr.uri", "https://dns.quad9.net/dns-query");
defaultPref("dom.security.https_only_mode", true);
defaultPref("security.ssl.require_safe_negotiation", true);

// --- Reduce leaks ---
defaultPref("media.peerconnection.enabled", false);   // WebRTC IP leak off
defaultPref("geo.enabled", false);
defaultPref("browser.safebrowsing.downloads.remote.enabled", false);
defaultPref("network.prefetch-next", false);
defaultPref("network.dns.disablePrefetch", true);
defaultPref("network.predictor.enabled", false);
defaultPref("browser.send_pings", false);

// --- Search / suggestions don't phone home as you type ---
defaultPref("browser.search.suggest.enabled", false);
defaultPref("browser.urlbar.suggest.searches", false);
defaultPref("keyword.enabled", true);
