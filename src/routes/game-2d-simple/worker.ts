import "@lib/ts/worker-shim";
import { initWasm } from "@lib/ts/wasm";
import type { WasmRef } from "@lib/ts/wasm";
import wasmUrl from "@zig/game-2d-simple.wasm?url";
import { WorkerCtx } from "@lib/ts/util";
import { set } from "idb-keyval";
import { handleInput, findCanvas } from "@lib/ts/gamescreen";

const ctx = new WorkerCtx<InputMessage, OutMessage>(postMessage);
onmessage = ctx.onmessageCallback();

import type { InputMessage as BaseMessage } from "@lib/ts/gamescreen";
export type InputMessage =
  | BaseMessage
  | { kind: "uploadLevel"; data: any }
  | { kind: "levelDownload"; data: any }
  | { kind: "saveLevel"; data: any };

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

let glCtx: CanvasRenderingContext2D | null = null;

const initGl = async (
  canvas: any
): Promise<CanvasRenderingContext2D | null> => {
  const ctx = canvas.getContext("2d");
  if (!ctx) return null;

  return ctx;
};

const main = async (wasmRef: WasmRef) => {
  function run(timestamp: number) {
    wasmRef.abi.run(timestamp);

    requestAnimationFrame(run);
  }

  function run1(timestamp: number) {
    wasmRef.abi.setInitialTime(timestamp);
    requestAnimationFrame(run);
  }

  requestAnimationFrame(run1);

  while (true) {
    const captured = await ctx.msgWait();

    const seen: Record<string, true> = {};
    captured.forEach((msg) => {
      switch (msg.kind) {
        case "uploadLevel": {
          const value = wasmRef.addObj(msg.data);
          wasmRef.abi.uploadLevel(value);
          set("level", msg.data).catch(() => {});
          break;
        }

        case "levelDownload":
          if (!seen[msg.kind]) {
            wasmRef.abi.download();
          }
          break;

        case "saveLevel":
          if (!seen[msg.kind]) {
            wasmRef.abi.saveLevel();
          }
          break;

        default:
          handleInput(wasmRef, glCtx, msg);
      }

      seen[msg.kind] = true;
    });
  }
};

const init = async () => {
  const wasmRef = await initWasm(fetch(wasmUrl), {
    postMessage: (kind: string, data: any) => ctx.postMessage({ kind, data }),
    raw: (wasmRef: WasmRef) => ({
      pushMessage: (kindId: number, dataId: number) => {
        const kind = wasmRef.readObj(kindId);
        const data = wasmRef.readObj(dataId);
        ctx.push({ kind, data });
      },

      clearScreen: () => {
        if (!glCtx) return;
        glCtx.clearRect(0, 0, glCtx.canvas.width, glCtx.canvas.height);
      },

      saveLevelToIdb: (levelTextId: number) => {
        const levelText = wasmRef.readObj(levelTextId);
        set("level", levelText).catch(() => {});
      },

      setFont: (fontId: number) => {
        if (!glCtx) return;
        const font = wasmRef.readObj(fontId);
        glCtx.font = font;
      },

      fillText: (textId: number, x: number, y: number) => {
        if (!glCtx) return;
        const text = wasmRef.readObj(textId);
        glCtx.fillText(text, x, y);
      },

      strokeStyle: (rF: number, gF: number, bF: number, a: number) => {
        if (!glCtx) return;
        glCtx.globalAlpha = a;
        const [r, g, b] = [rF, gF, bF].map((f) => Math.floor(255 * f));

        glCtx.strokeStyle = `rgba(${r},${g},${b})`;
      },
      fillStyle: (rF: number, gF: number, bF: number, a: number) => {
        if (!glCtx) return;
        glCtx.globalAlpha = a;
        const [r, g, b] = [rF, gF, bF].map((f) => Math.floor(255 * f));

        glCtx.fillStyle = `rgba(${r},${g},${b})`;
      },

      strokeRect: (x: number, y: number, width: number, height: number) => {
        if (!glCtx) return;
        glCtx.strokeRect(x, y, width, height);
      },
      fillRect: (x: number, y: number, width: number, height: number) => {
        if (!glCtx) return;
        glCtx.fillRect(x, y, width, height);
      },
    }),
  });

  wasmRef.abi.init();

  const result = await findCanvas(ctx);
  glCtx = await initGl(result.canvas);

  if (!glCtx) {
    ctx.postMessage({ kind: "error", data: "WebGL2 not supported!" });
    return;
  }

  ctx.postMessage({ kind: "log", data: "WebGL2 context initialized!" });
  ctx.postMessage({ kind: "initDone" });

  result.remainder.forEach((msg) => {
    handleInput(wasmRef, glCtx, msg);
  });

  main(wasmRef);
};

init();
