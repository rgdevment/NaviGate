mod browser;
mod rule;

pub use browser::{Browser, Profile};
pub use rule::{HostPattern, Rule, RuleSet, Target};

pub fn host_of(url: &str) -> Option<String> {
    let rest = url.split_once("://")?.1;
    let authority = rest.split(['/', '?', '#']).next()?;
    let host = authority.rsplit_once('@').map_or(authority, |(_, h)| h);
    let host = host.split_once(':').map_or(host, |(h, _)| h);
    if host.is_empty() {
        return None;
    }
    Some(host.trim_end_matches('.').to_ascii_lowercase())
}

#[cfg(test)]
mod tests {
    use super::host_of;

    #[test]
    fn strips_port_credentials_path_and_case() {
        assert_eq!(
            host_of("https://GitHub.com/rgdevment").as_deref(),
            Some("github.com")
        );
        assert_eq!(
            host_of("https://user:pw@example.com:8443/x").as_deref(),
            Some("example.com")
        );
        assert_eq!(
            host_of("https://example.com?q=1").as_deref(),
            Some("example.com")
        );
        assert_eq!(
            host_of("https://example.com#frag").as_deref(),
            Some("example.com")
        );
    }

    #[test]
    fn a_trailing_dot_is_the_same_host() {
        assert_eq!(
            host_of("https://example.com./x").as_deref(),
            Some("example.com")
        );
    }

    #[test]
    fn nothing_usable_yields_nothing() {
        assert!(host_of("not a url").is_none());
        assert!(host_of("https://").is_none());
        assert!(host_of("https:///path").is_none());
    }
}
