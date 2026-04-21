#!/usr/bin/env bash
# LinkUnbound — Dev cleanup for macOS.
#
# Removes user-scoped traces of LinkUnbound so the next run boots from a
# clean state: Application Support, caches, preferences, saved state,
# Launch Services handler registration, login items, and build outputs.
#
# Usage:
#   ./scripts/dev_clean.sh                # full clean
#   ./scripts/dev_clean.sh --dry-run      # show what would be removed
#   ./scripts/dev_clean.sh --skip-files   # only LaunchServices / login items
#   ./scripts/dev_clean.sh --skip-ls      # only files
#
# Safe to run repeatedly. Does not require sudo.

set -u

DRY_RUN=0
SKIP_FILES=0
SKIP_LS=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --skip-files) SKIP_FILES=1 ;;
    --skip-ls) SKIP_LS=1 ;;
    -h|--help)
      sed -n '2,15p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

BUNDLE_ID="com.rgdevment.linkunbound"
APP_NAME="LinkUnbound"
removed=0

c_gray()   { printf '\033[90m%s\033[0m\n' "$*"; }
c_green()  { printf '\033[32m%s\033[0m\n' "$*"; }
c_yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
c_cyan()   { printf '\n\033[36m=== %s ===\033[0m\n' "$*"; }

step()    { c_gray   "  [-] $*"; }
done_msg(){ c_green  "  [OK] $*"; }
skip_msg(){ c_yellow "  [--] $*"; }

remove_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    if (( DRY_RUN )); then
      step "Would remove: $path"
    else
      rm -rf "$path" 2>/dev/null && {
        done_msg "Removed: $path"
        removed=$((removed + 1))
      } || skip_msg "Failed to remove: $path"
    fi
  fi
}

remove_glob() {
  local pattern="$1"
  shopt -s nullglob
  for p in $pattern; do
    remove_path "$p"
  done
  shopt -u nullglob
}

printf '\n\033[1mLinkUnbound Dev Cleanup (macOS)\033[0m\n'
(( DRY_RUN )) && c_yellow "(DRY RUN — nothing will be deleted)"

if (( ! SKIP_FILES )); then
  c_cyan "Files: Application Support / Caches / Preferences"

  remove_path "$HOME/Library/Application Support/$APP_NAME"
  remove_path "$HOME/Library/Application Support/$BUNDLE_ID"
  remove_path "$HOME/Library/Caches/$BUNDLE_ID"
  remove_path "$HOME/Library/HTTPStorages/$BUNDLE_ID"
  remove_path "$HOME/Library/HTTPStorages/$BUNDLE_ID.binarycookies"
  remove_path "$HOME/Library/WebKit/$BUNDLE_ID"
  remove_path "$HOME/Library/Preferences/$BUNDLE_ID.plist"
  remove_path "$HOME/Library/Saved Application State/$BUNDLE_ID.savedState"
  remove_path "$HOME/Library/Containers/$BUNDLE_ID"
  remove_path "$HOME/Library/Group Containers/$BUNDLE_ID"

  c_cyan "Files: Logs"
  remove_path "$HOME/Library/Logs/$APP_NAME"
  remove_path "$HOME/Library/Logs/$BUNDLE_ID"

  c_cyan "Files: Build outputs"
  project_root="$(cd "$(dirname "$0")/.." && pwd)"
  remove_path "$project_root/build"
  remove_path "$project_root/apps/linkunbound/build"
  remove_path "$project_root/apps/linkunbound/macos/Pods"
  remove_path "$project_root/apps/linkunbound/macos/Flutter/ephemeral"
fi

if (( ! SKIP_LS )); then
  c_cyan "Launch Services: handler registration"

  lsreg="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
  if [[ -x "$lsreg" ]]; then
    if (( DRY_RUN )); then
      step "Would unregister bundle id: $BUNDLE_ID"
      step "Would rebuild Launch Services database"
    else
      "$lsreg" -u -all "/Applications/$APP_NAME.app" 2>/dev/null || true
      "$lsreg" -kill -r -domain local -domain system -domain user >/dev/null 2>&1
      done_msg "Launch Services database rebuilt"
      removed=$((removed + 1))
    fi
  else
    skip_msg "lsregister not found — skipping LS reset"
  fi

  c_cyan "Default browser association (LSHandlers in Global Preferences)"

  matches=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure 2>/dev/null \
    | grep -ic "$BUNDLE_ID" || true)
  if [[ "$matches" -gt 0 ]]; then
    if (( DRY_RUN )); then
      step "Would remove $matches LSHandlers entries referencing $BUNDLE_ID"
      step "(use System Settings → Desktop & Dock → Default web browser to switch)"
    else
      skip_msg "$matches LSHandlers entries reference $BUNDLE_ID — change default browser in System Settings → Desktop & Dock"
    fi
  fi

  c_cyan "Login Items (auto-launch on startup)"

  if osascript -e "tell application \"System Events\" to get the name of every login item" 2>/dev/null \
       | tr ',' '\n' | grep -qi "$APP_NAME"; then
    if (( DRY_RUN )); then
      step "Would remove login item: $APP_NAME"
    else
      osascript -e "tell application \"System Events\" to delete every login item whose name is \"$APP_NAME\"" >/dev/null 2>&1 \
        && { done_msg "Removed login item: $APP_NAME"; removed=$((removed + 1)); } \
        || skip_msg "Failed to remove login item (may need accessibility permissions)"
    fi
  fi
fi

printf '\n\033[1m--- Done. %d items cleaned. ---\033[0m\n\n' "$removed"
