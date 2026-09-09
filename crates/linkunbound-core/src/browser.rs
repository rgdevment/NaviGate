use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Profile {
    pub id: String,
    pub name: String,
    pub args: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Browser {
    pub id: String,
    pub name: String,
    pub exe: String,
    #[serde(default)]
    pub profiles: Vec<Profile>,
    /// Declared at detection, never guessed: browsers treat an unknown switch as a URL.
    #[serde(default)]
    pub private_flag: Option<String>,
}

impl Browser {
    pub fn profile(&self, id: &str) -> Option<&Profile> {
        self.profiles.iter().find(|p| p.id == id)
    }

    pub fn supports_private(&self) -> bool {
        self.private_flag.is_some()
    }

    pub fn launch_args(&self, profile: Option<&str>, private: bool, url: &str) -> Vec<String> {
        let mut args = Vec::new();
        if let Some(p) = profile.and_then(|id| self.profile(id)) {
            args.extend(p.args.iter().cloned());
        }
        if private && let Some(flag) = &self.private_flag {
            args.push(flag.clone());
        }
        args.push(url.to_owned());
        args
    }
}
