import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { useEffect, useState } from "react";

type Choice = { id: string; name: string; profile?: string; tint: string };

const BROWSERS: Choice[] = [
  { id: "firefox", name: "Firefox", tint: "bg-orange-500" },
  { id: "chrome", name: "Chrome", profile: "Work", tint: "bg-sky-500" },
  { id: "chrome", name: "Chrome", profile: "Personal", tint: "bg-emerald-500" },
  { id: "edge", name: "Edge", tint: "bg-teal-500" },
];

export default function App() {
  const [url, setUrl] = useState("https://gist.github.com/rgdevment/a1b2c3");
  const [delivery, setDelivery] = useState(0);
  const [remember, setRemember] = useState(false);
  const [priv, setPriv] = useState(false);

  useEffect(() => {
    void invoke<{ url: string } | null>("picker_boot").then((pending) => {
      if (!pending) return;
      setUrl(pending.url);
      setDelivery((n) => n + 1);
    });
  }, []);

  useEffect(() => {
    const stop = listen<{ url: string }>("link:incoming", (e) => {
      setUrl(e.payload.url);
      setDelivery((n) => n + 1);
    });
    return () => {
      void stop.then((f) => f());
    };
  }, []);

  // One measurement per delivery, not per mount: the window outlives every
  // link, so a mount-only effect never sees the second one.
  useEffect(() => {
    if (delivery === 0) return;
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        void invoke("picker_painted");
      });
    });
  }, [delivery]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") void invoke("picker_dismiss");
      setPriv(e.shiftKey);
    };
    window.addEventListener("keydown", onKey);
    window.addEventListener("keyup", onKey);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("keyup", onKey);
    };
  }, []);

  let host = url;
  try {
    host = new URL(url).host;
  } catch {
    /* the picker shows the raw string when the URL will not parse */
  }

  return (
    <div className="flex h-full flex-col justify-between rounded-xl border border-neutral-200/60 bg-white/95 p-4 text-neutral-900 shadow-2xl backdrop-blur dark:border-white/10 dark:bg-neutral-900/95 dark:text-neutral-100">
      <div>
        <p className="truncate text-sm font-semibold">{host}</p>
        <p className="truncate text-xs text-neutral-500 dark:text-neutral-400">{url}</p>
      </div>

      <div className="grid grid-cols-4 gap-2">
        {BROWSERS.map((b) => (
          <button
            key={`${b.id}-${b.profile ?? "default"}`}
            type="button"
            className="flex flex-col items-center gap-1.5 rounded-lg p-2 transition hover:bg-neutral-100 focus:ring-2 focus:ring-sky-500 focus:outline-none dark:hover:bg-white/5"
          >
            <span className={`h-9 w-9 rounded-full ${b.tint}`} />
            <span className="text-xs leading-tight font-medium">{b.name}</span>
            {b.profile && (
              <span className="text-[10px] text-neutral-500 dark:text-neutral-400">
                {b.profile}
              </span>
            )}
          </button>
        ))}
      </div>

      <div className="flex items-center justify-between text-xs">
        <label className="flex items-center gap-1.5">
          <input
            type="checkbox"
            checked={remember}
            onChange={(e) => setRemember(e.target.checked)}
          />
          <span>
            Always for <span className="font-medium">{host}</span>
          </span>
        </label>
        <span
          className={
            priv
              ? "rounded bg-violet-500/15 px-1.5 py-0.5 font-medium text-violet-600 dark:text-violet-300"
              : "text-neutral-400"
          }
        >
          {priv ? "Private window" : "Shift = private"}
        </span>
      </div>
    </div>
  );
}
