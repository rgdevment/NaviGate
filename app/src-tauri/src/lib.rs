use std::io::Write;
use std::sync::Mutex;
use std::time::{Instant, SystemTime, UNIX_EPOCH};

use serde::Serialize;
use tauri::{AppHandle, Emitter, Manager};

#[derive(Default)]
struct Delivery {
    started: Option<Instant>,
    url: Option<String>,
}

#[derive(Clone, Serialize)]
struct Incoming {
    url: String,
}

#[derive(Serialize)]
pub struct Timing {
    to_show_us: u128,
    to_paint_us: u128,
}

fn url_from(args: &[String]) -> Option<String> {
    args.iter()
        .skip(1)
        .find(|a| a.starts_with("http://") || a.starts_with("https://"))
        .cloned()
}

/// Release builds have no console on Windows, so measurements go to a file.
fn record(stage: &str, micros: u128) {
    let path = std::env::temp_dir().join("linkunbound-spike-latency.csv");
    if let Ok(mut f) = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
    {
        let _ = writeln!(f, "{stage},{micros}");
    }
}

/// The window is created hidden at startup and never destroyed: the click path
/// costs a show, not a webview.
fn deliver(app: &AppHandle, url: String) {
    let started = Instant::now();
    {
        let state = app.state::<Mutex<Delivery>>();
        let Ok(mut held) = state.lock() else { return };
        held.started = Some(started);
        held.url = Some(url.clone());
    }

    let Some(window) = app.get_webview_window("picker") else {
        return;
    };
    record("emit", 0);
    let _ = window.emit("link:incoming", Incoming { url });
    let _ = window.show();
    let _ = window.set_focus();

    record("to_show_us", started.elapsed().as_micros());
}

/// Pulled, not pushed: on a cold start `deliver` runs before the webview exists,
/// so an emitted link would land on nobody.
#[tauri::command]
fn picker_boot(state: tauri::State<'_, Mutex<Delivery>>) -> Option<Incoming> {
    record("frontend_booted", 0);
    let held = state.lock().ok()?;
    held.url.clone().map(|url| Incoming { url })
}

#[tauri::command]
fn picker_painted(app: AppHandle, state: tauri::State<'_, Mutex<Delivery>>) -> Option<u128> {
    let epoch_ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |d| d.as_millis());
    record("paint_epoch_ms", epoch_ms);
    let elapsed = {
        let Ok(held) = state.lock() else {
            record("lock_failed", 0);
            return None;
        };
        let Some(started) = held.started else {
            record("painted_without_delivery", 0);
            return None;
        };
        started.elapsed().as_micros()
    };
    record("to_paint_us", elapsed);
    if std::env::var_os("SPIKE_BENCH").is_some()
        && let Some(window) = app.get_webview_window("picker")
    {
        let _ = window.hide();
    }
    Some(elapsed)
}

#[tauri::command]
fn picker_dismiss(app: AppHandle) {
    if let Some(window) = app.get_webview_window("picker") {
        let _ = window.hide();
    }
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, argv, _cwd| {
            if let Some(url) = url_from(&argv) {
                deliver(app, url);
            }
        }))
        .manage(Mutex::new(Delivery::default()))
        .invoke_handler(tauri::generate_handler![
            picker_boot,
            picker_painted,
            picker_dismiss
        ])
        .setup(|app| {
            let args: Vec<String> = std::env::args().collect();
            if let Some(url) = url_from(&args) {
                deliver(app.handle(), url);
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("tauri failed to start");
}

#[cfg(test)]
mod tests {
    use super::url_from;

    #[test]
    fn picks_the_url_and_ignores_the_executable() {
        let args = vec![
            "linkunbound.exe".to_owned(),
            "--background".to_owned(),
            "https://github.com".to_owned(),
        ];
        assert_eq!(url_from(&args).as_deref(), Some("https://github.com"));
    }

    #[test]
    fn no_url_means_no_delivery() {
        let args = vec!["linkunbound.exe".to_owned(), "--register".to_owned()];
        assert!(url_from(&args).is_none());
    }
}
