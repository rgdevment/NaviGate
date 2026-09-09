import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import App from "./App";

const invoke = vi.fn();
const listen = vi.fn();

vi.mock("@tauri-apps/api/core", () => ({ invoke: (...a: unknown[]) => invoke(...a) }));
vi.mock("@tauri-apps/api/event", () => ({ listen: (...a: unknown[]) => listen(...a) }));

describe("picker", () => {
  beforeEach(() => {
    invoke.mockReset().mockResolvedValue(null);
    listen.mockReset().mockResolvedValue(() => {});
  });

  it("asks for the pending link on mount instead of waiting for an event", async () => {
    render(<App />);
    await vi.waitFor(() => expect(invoke).toHaveBeenCalledWith("picker_boot"));
  });

  it("shows the link the backend hands back on a cold start", async () => {
    invoke.mockImplementation((cmd: string) =>
      cmd === "picker_boot"
        ? Promise.resolve({ url: "https://gist.github.com/rgdevment/a1b2" })
        : Promise.resolve(null),
    );
    render(<App />);
    expect(await screen.findByText("gist.github.com", { selector: "p" })).toBeInTheDocument();
  });

  it("offers every configured destination, profiles included", () => {
    render(<App />);
    expect(screen.getAllByRole("button")).toHaveLength(4);
    expect(screen.getByText("Work")).toBeInTheDocument();
    expect(screen.getByText("Personal")).toBeInTheDocument();
  });
});
