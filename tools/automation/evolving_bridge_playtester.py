#!/usr/bin/env python3
"""Run an evolving playtester through the real Godot automation bridge.

The tool does not read process memory, scrape screenshots, or move the mouse.
It launches the real game with the local JSON bridge enabled, asks the game for
legal snapshots/previews, and sends normal player-like commands.
"""

from __future__ import annotations

import argparse
import itertools
import json
import math
import os
import random
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any


DEFAULT_PORT = 24886
DEFAULT_WEIGHTS = {
    "settle_score": 1.00,
    "settle_progress": 0.85,
    "settle_overkill_penalty": 0.16,
    "reroll_keep_preview": 1.00,
    "reroll_keep_duplicate": 10.0,
    "reroll_keep_straight": 6.0,
    "reroll_keep_high_pip": 2.2,
    "reroll_keep_special": 8.0,
    "reroll_low_score_floor": 220.0,
    "reward_pip": 7.0,
    "reward_red": 46.0,
    "reward_blue": 22.0,
    "reward_purple": 18.0,
    "reward_wild": 28.0,
    "reward_burst": 38.0,
    "reward_stay": 48.0,
    "reward_mult": 30.0,
    "reward_chip": 18.0,
    "reward_foil": 30.0,
    "reward_holo": 42.0,
    "reward_poly": 54.0,
    "reward_lucky": 14.0,
    "install_high_pip": 5.0,
    "install_low_pip_for_pip": 4.0,
    "install_empty_slot": 30.0,
    "install_combo_face": 16.0,
}


@dataclass
class RunResult:
    run_number: int
    weights: dict[str, float]
    fitness: float
    won: bool
    lost: bool
    battle: int
    max_battles: int
    total_score: int
    best_hand: int
    hands: int
    installed: int
    elapsed: float
    decisions: list[str] = field(default_factory=list)


class BridgeClient:
    def __init__(self, host: str, port: int, timeout: float = 15.0) -> None:
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.sock.settimeout(timeout)
        self.reader = self.sock.makefile("r", encoding="utf-8", newline="\n")
        self.writer = self.sock.makefile("w", encoding="utf-8", newline="\n")

    def close(self) -> None:
        try:
            self.writer.close()
            self.reader.close()
            self.sock.close()
        except OSError:
            pass

    def command(self, cmd: str, **args: Any) -> dict[str, Any]:
        payload: dict[str, Any] = {"cmd": cmd}
        if args:
            payload["args"] = args
        self.writer.write(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n")
        self.writer.flush()
        line = self.reader.readline()
        if not line:
            raise RuntimeError(f"automation bridge closed while waiting for {cmd}")
        response = json.loads(line)
        if not isinstance(response, dict):
            raise RuntimeError(f"invalid bridge response for {cmd}: {response!r}")
        return response


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Evolving real-game bridge playtester")
    parser.add_argument("--runs", type=int, default=10, help="number of runs to play")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="local automation bridge port")
    parser.add_argument("--godot-bin", default="", help="path to Godot executable")
    parser.add_argument("--project", default=str(find_project_root()), help="Godot project root")
    parser.add_argument("--report-dir", default="", help="output report directory")
    parser.add_argument(
        "--state-file",
        default="",
        help="persistent strategy state JSON; defaults to reports/evolving_bridge_strategy_state.json",
    )
    parser.add_argument("--headless", action="store_true", help="run Godot headless for CI/smoke tests")
    parser.add_argument("--keep-open", action="store_true", help="leave Godot running after the tool exits")
    parser.add_argument("--connect-only", action="store_true", help="connect to an already running bridge")
    parser.add_argument("--seed", type=int, default=None, help="evolution RNG seed; omit for a fresh random seed")
    parser.add_argument("--mutation-scale", type=float, default=0.16, help="relative mutation scale")
    parser.add_argument("--max-steps", type=int, default=900, help="safety action limit per run")
    parser.add_argument("--startup-timeout", type=float, default=20.0, help="seconds to wait for bridge startup")
    return parser.parse_args()


def find_project_root() -> Path:
    path = Path(__file__).resolve()
    for parent in [path.parent, *path.parents]:
        if (parent / "project.godot").exists():
            return parent
    return Path.cwd()


def find_godot_bin(requested: str, headless: bool) -> str:
    if requested:
        return requested
    env_bin = os.environ.get("GODOT_BIN", "")
    if env_bin:
        return env_bin
    temp_root = Path(tempfile.gettempdir()) / "codex_godot_4_6_2"
    temp_candidates = [
        temp_root / "Godot_v4.6.2-stable_win64_console.exe",
        temp_root / "Godot_v4.6.2-stable_win64.exe",
    ]
    if not headless:
        temp_candidates.reverse()
    for candidate in temp_candidates:
        if candidate.exists():
            return str(candidate)
    path_bin = shutil.which("godot") or shutil.which("godot4")
    if path_bin:
        return path_bin
    raise FileNotFoundError("找不到 Godot。请传入 --godot-bin 或设置 GODOT_BIN。")


def wait_for_bridge(port: int, timeout: float) -> BridgeClient:
    deadline = time.time() + timeout
    last_error: Exception | None = None
    while time.time() < deadline:
        try:
            client = BridgeClient("127.0.0.1", port, timeout=5.0)
            ping = client.command("ping")
            if ping.get("ok"):
                return client
            client.close()
        except Exception as exc:  # noqa: BLE001 - startup retry path
            last_error = exc
            time.sleep(0.10)
    raise TimeoutError(f"automation bridge did not start on port {port}: {last_error}")


def launch_godot(args: argparse.Namespace, project: Path) -> subprocess.Popen[Any] | None:
    if args.connect_only:
        return None
    godot_bin = find_godot_bin(args.godot_bin, args.headless)
    command = [godot_bin]
    if args.headless:
        command.append("--headless")
    command.extend([
        "--path",
        str(project),
        "--",
        "--automation-bridge",
        "--automation-lock",
        f"--automation-port={args.port}",
    ])
    creationflags = 0
    if os.name == "nt" and args.headless:
        creationflags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
    return subprocess.Popen(command, cwd=project, creationflags=creationflags)


def load_state(path: Path) -> dict[str, Any]:
    if path.exists():
        with path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        if isinstance(data, dict):
            data.setdefault("best_weights", DEFAULT_WEIGHTS.copy())
            data.setdefault("best_fitness", -1.0)
            data.setdefault("runs", [])
            return data
    return {
        "version": 1,
        "best_weights": DEFAULT_WEIGHTS.copy(),
        "best_fitness": -1.0,
        "runs": [],
    }


def save_state(path: Path, state: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        json.dump(state, fh, ensure_ascii=False, indent=2)


def mutated_weights(base: dict[str, float], rng: random.Random, scale: float) -> dict[str, float]:
    weights: dict[str, float] = {}
    for key, value in base.items():
        factor = 1.0 + rng.gauss(0.0, scale)
        weights[key] = max(0.0, float(value) * factor)
    return weights


def bridge_snapshot(client: BridgeClient) -> dict[str, Any]:
    response = client.command("snapshot")
    if not response.get("ok"):
        raise RuntimeError(response.get("error", "snapshot failed"))
    return response.get("snapshot", {})


def choose_best_settle(client: BridgeClient, battle: dict[str, Any], weights: dict[str, float]) -> dict[str, Any]:
    rolls = battle.get("rolls", [])
    max_selected = int(battle.get("max_selected", 5))
    target = int(battle.get("target_score", 0))
    total = int(battle.get("total_score", 0))
    best: dict[str, Any] = {"indices": [], "score": -1, "combo": "", "value": -1.0, "winning": False}
    indices = [int(roll.get("die_index", idx)) for idx, roll in enumerate(rolls)]

    selections: list[list[int]] = []
    for size in range(1, min(max_selected, len(indices)) + 1):
        selections.extend([list(combo) for combo in itertools.combinations(indices, size)])

    response = client.command("preview_selections", selections=selections)
    if not response.get("ok"):
        return best

    for entry in response.get("previews", []):
        combo = list(entry.get("indices", []))
        preview = entry.get("preview", {})
        if not preview:
            continue
        score = int(preview.get("final_score", 0))
        winning = total + score >= target
        overkill = max(0, total + score - target)
        if winning:
            value = (
                score * weights["settle_score"]
                + (total + score) * weights["settle_progress"]
                - overkill * weights["settle_overkill_penalty"]
            )
        else:
            value = score * weights["settle_score"] + (total + score) * weights["settle_progress"]
        if winning:
            value += 100000.0 - overkill * weights["settle_overkill_penalty"]
        if value > float(best["value"]):
            best = {
                "indices": combo,
                "score": score,
                "combo": str(preview.get("combo", "")),
                "summary": str(preview.get("summary", "")),
                "value": value,
                "winning": winning,
            }
    return best


def choose_reroll_indices(best_settle: dict[str, Any], battle: dict[str, Any], weights: dict[str, float]) -> list[int]:
    rolls = battle.get("rolls", [])
    keep = set(int(i) for i in best_settle.get("indices", []))
    pips = {int(roll.get("die_index", idx)): int(roll.get("pip", 0)) for idx, roll in enumerate(rolls)}
    counts: dict[int, int] = {}
    for pip in pips.values():
        counts[pip] = counts.get(pip, 0) + 1

    for idx, pip in pips.items():
        score = pip * weights["reroll_keep_high_pip"]
        score += max(0, counts.get(pip, 0) - 1) * weights["reroll_keep_duplicate"]
        if any(abs(pip - other) <= 2 for other in pips.values() if other != pip):
            score += weights["reroll_keep_straight"]
        roll = next((r for r in rolls if int(r.get("die_index", -1)) == idx), {})
        if str(roll.get("ornament_id", "orn_none")) != "orn_none" or str(roll.get("mark_id", "mark_none")) != "mark_none":
            score += weights["reroll_keep_special"]
        if idx in keep:
            score += float(best_settle.get("score", 0)) * 0.10 * weights["reroll_keep_preview"]
        if score >= weights["reroll_low_score_floor"] / 8.0:
            keep.add(idx)

    reroll = [int(roll.get("die_index", idx)) for idx, roll in enumerate(rolls) if int(roll.get("die_index", idx)) not in keep]
    if not reroll and rolls:
        low = min(rolls, key=lambda roll: int(roll.get("pip", 0)))
        reroll = [int(low.get("die_index", 0))]
    return reroll


def reward_value(choice: dict[str, Any], weights: dict[str, float]) -> float:
    text = f"{choice.get('name', '')} {choice.get('description', '')} {choice.get('tags', '')}"
    value = 0.0
    for digit in "12345678":
        if digit in text:
            value += int(digit) * weights["reward_pip"]
    keyword_weights = {
        "红印": "reward_red",
        "蓝印": "reward_blue",
        "紫印": "reward_purple",
        "万能": "reward_wild",
        "爆裂": "reward_burst",
        "留场": "reward_stay",
        "倍率": "reward_mult",
        "基础": "reward_chip",
        "箔光": "reward_foil",
        "幻彩": "reward_holo",
        "多彩": "reward_poly",
        "幸运": "reward_lucky",
    }
    for keyword, weight_key in keyword_weights.items():
        if keyword in text:
            value += weights[weight_key]
    return value


def choose_reward(snapshot: dict[str, Any], weights: dict[str, float]) -> int:
    rewards = snapshot.get("run", {}).get("reward_choices", [])
    if not rewards:
        return -1
    return max(range(len(rewards)), key=lambda i: reward_value(rewards[i], weights))


def choose_install_target(snapshot: dict[str, Any], weights: dict[str, float]) -> tuple[int, int]:
    pending = snapshot.get("run", {}).get("pending_piece", {})
    piece_text = f"{pending.get('name', '')} {pending.get('description', '')} {pending.get('tags', '')}"
    dice = snapshot.get("battle", {}).get("dice", [])
    best = (-1.0, 0, 0)
    for die in dice:
        die_index = int(die.get("die_index", 0))
        for face in die.get("faces", []):
            face_index = int(face.get("face_index", 0))
            pip = int(face.get("pip", 1))
            ornament_empty = str(face.get("ornament_id", "orn_none")) == "orn_none"
            mark_empty = str(face.get("mark_id", "mark_none")) == "mark_none"
            value = pip * weights["install_high_pip"]
            if "点数" in piece_text:
                value += (7 - pip) * weights["install_low_pip_for_pip"]
            if ("面饰" in piece_text and ornament_empty) or ("印" in piece_text and mark_empty):
                value += weights["install_empty_slot"]
            if pip in (4, 5, 6):
                value += weights["install_combo_face"]
            if value > best[0]:
                best = (value, die_index, face_index)
    return best[1], best[2]


def play_run(client: BridgeClient, run_number: int, weights: dict[str, float], max_steps: int) -> RunResult:
    start = time.time()
    client.command("start_run")
    decisions: list[str] = []
    last_snapshot = bridge_snapshot(client)

    for _step in range(max_steps):
        snapshot = bridge_snapshot(client)
        last_snapshot = snapshot
        run = snapshot.get("run", {})
        battle = snapshot.get("battle", {})
        flow_state = str(snapshot.get("flow_state", ""))
        view = str(snapshot.get("view", ""))

        if run.get("won") or run.get("lost") or flow_state in ("run_victory", "run_defeat"):
            break

        if run.get("pending_piece"):
            die_index, face_index = choose_install_target(snapshot, weights)
            decisions.append(
                f"安装 {run.get('pending_piece', {}).get('name', '')} 到 D{die_index + 1} 第{face_index + 1}面"
            )
            client.command("install_piece", die_index=die_index, face_index=face_index)
            time.sleep(0.02)
            continue

        if run.get("reward_choices"):
            index = choose_reward(snapshot, weights)
            if index >= 0:
                choice = run["reward_choices"][index]
                decisions.append(f"第 {run.get('battle')} 战后选择奖励：{choice.get('name')}")
                client.command("choose_reward", index=index)
                time.sleep(0.02)
            continue

        if view == "battle" and battle.get("phase") == "WAITING_ACTION":
            best_settle = choose_best_settle(client, battle, weights)
            remaining_hands = max(1, int(battle.get("hands_per_battle", 4)) - int(battle.get("hand", 1)) + 1)
            need = max(0, int(battle.get("target_score", 0)) - int(battle.get("total_score", 0)))
            should_score = (
                bool(best_settle.get("winning"))
                or int(best_settle.get("score", 0)) >= math.ceil(need / remaining_hands)
                or int(battle.get("rerolls_left", 0)) <= 0
            )
            if should_score:
                client.command("select_dice", indices=best_settle["indices"])
                response = client.command("score")
                decisions.append(
                    f"第 {run.get('battle')} 战第 {battle.get('hand')} 手结算 {best_settle['indices']}："
                    f"{best_settle.get('combo')} {best_settle.get('score')}"
                )
                if not response.get("ok"):
                    decisions.append(f"结算失败：{response.get('error')}")
                time.sleep(0.02)
            else:
                reroll = choose_reroll_indices(best_settle, battle, weights)
                client.command("select_dice", indices=reroll)
                response = client.command("reroll")
                decisions.append(f"第 {run.get('battle')} 战第 {battle.get('hand')} 手重投 {reroll}")
                if not response.get("ok"):
                    client.command("select_dice", indices=best_settle["indices"])
                    client.command("score")
                time.sleep(0.02)
            continue

        time.sleep(0.03)

    final = bridge_snapshot(client) or last_snapshot
    run = final.get("run", {})
    battle = int(run.get("battle", 0))
    max_battles = int(run.get("max_battles", 24))
    won = bool(run.get("won", False))
    lost = bool(run.get("lost", False))
    total_score = int(run.get("total_score_scored", 0))
    best_hand = int(run.get("best_hand_score", 0))
    hands = int(run.get("total_hands_scored", 0))
    installed = int(run.get("installed_piece_count", 0))
    fitness = (
        battle * 10000.0
        + total_score * 0.05
        + best_hand * 0.8
        + installed * 400.0
        + (500000.0 if won else 0.0)
        - (1000.0 if lost else 0.0)
    )
    return RunResult(
        run_number=run_number,
        weights=weights,
        fitness=fitness,
        won=won,
        lost=lost,
        battle=battle,
        max_battles=max_battles,
        total_score=total_score,
        best_hand=best_hand,
        hands=hands,
        installed=installed,
        elapsed=time.time() - start,
        decisions=decisions,
    )


def write_reports(report_dir: Path, results: list[RunResult], state: dict[str, Any]) -> None:
    report_dir.mkdir(parents=True, exist_ok=True)
    completed = max(1, len(results))
    average_progress = sum(result.battle for result in results) / completed
    average_progress_percent = (
        sum(result.battle / max(1, result.max_battles) for result in results)
        / completed
        * 100.0
    )
    best_progress = max((result.battle for result in results), default=0)
    max_battles = max((result.max_battles for result in results), default=0)
    average_fitness = sum(result.fitness for result in results) / completed
    state_file_text = str(state.get("state_file", ""))
    last_seed = state.get("last_seed", "")
    lines = [
        "# 进化桥接游玩报告",
        "",
        f"- 运行时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"- 完成局数：{len(results)}",
        f"- 通关局数：{sum(1 for result in results if result.won)} / {len(results)}",
        f"- 平均推进：{average_progress:.2f} / {max_battles} 关（{average_progress_percent:.1f}%）",
        f"- 最远推进：{best_progress} / {max_battles} 关",
        f"- 平均适应度：{average_fitness:.2f}",
        f"- 当前最佳适应度：{float(state.get('best_fitness', -1.0)):.2f}",
        f"- 策略状态文件：`{state_file_text}`",
        f"- 本批随机种子：`{last_seed}`",
        "",
        "| 局数 | 结果 | 推进 | 适应度 | 最佳单手 | 总结算战力 | 安装数 | 耗时 |",
        "|---:|---|---:|---:|---:|---:|---:|---:|",
    ]
    for result in results:
        status = "通关" if result.won else "失败"
        lines.append(
            f"| {result.run_number} | {status} | {result.battle}/{result.max_battles} | "
            f"{result.fitness:.1f} | {result.best_hand} | {result.total_score} | "
            f"{result.installed} | {result.elapsed:.2f}s |"
        )
    (report_dir / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    for result in results:
        run_lines = [
            f"# 第 {result.run_number:02d} 局",
            "",
            f"- 结果：{'通关' if result.won else '失败'}",
            f"- 推进：{result.battle}/{result.max_battles}",
            f"- 适应度：{result.fitness:.2f}",
            f"- 最佳单手：{result.best_hand}",
            f"- 总结算战力：{result.total_score}",
            f"- 耗时：{result.elapsed:.2f}s",
            "",
            "## 决策记录",
            "",
        ]
        run_lines.extend(f"- {line}" for line in result.decisions)
        (report_dir / f"run_{result.run_number:02d}.md").write_text("\n".join(run_lines) + "\n", encoding="utf-8")

    (report_dir / "strategy_state.json").write_text(
        json.dumps(state, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    args = parse_args()
    if args.seed is None:
        args.seed = random.SystemRandom().randrange(1, 2**31)
    rng = random.Random(args.seed)
    project = Path(args.project).resolve()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_dir = Path(args.report_dir) if args.report_dir else project / "reports" / f"evolving_bridge_playtest_{timestamp}"
    state_file = Path(args.state_file) if args.state_file else project / "reports" / "evolving_bridge_strategy_state.json"
    state = load_state(state_file)
    state["state_file"] = str(state_file)
    state["last_seed"] = args.seed

    process = launch_godot(args, project)
    client: BridgeClient | None = None
    results: list[RunResult] = []
    try:
        client = wait_for_bridge(args.port, args.startup_timeout)
        for run_index in range(1, args.runs + 1):
            global_run_index = len(state.get("runs", [])) + 1
            base_weights = {key: float(value) for key, value in state.get("best_weights", DEFAULT_WEIGHTS).items()}
            weights = mutated_weights(base_weights, rng, args.mutation_scale)
            result = play_run(client, run_index, weights, args.max_steps)
            results.append(result)
            if result.fitness >= float(state.get("best_fitness", -1.0)):
                state["best_fitness"] = result.fitness
                state["best_weights"] = weights
            state.setdefault("runs", []).append({
                "run": global_run_index,
                "batch_run": run_index,
                "fitness": result.fitness,
                "won": result.won,
                "battle": result.battle,
                "best_hand": result.best_hand,
                "total_score": result.total_score,
                "installed": result.installed,
                "elapsed": result.elapsed,
            })
            save_state(state_file, state)
            print(
                f"第 {run_index:02d} 局：{'通关' if result.won else '失败'}，"
                f"推进 {result.battle}/{result.max_battles}，适应度 {result.fitness:.1f}，"
                f"耗时 {result.elapsed:.2f}s"
            )
        write_reports(report_dir, results, state)
        print(f"报告目录：{report_dir}")
        return 0
    finally:
        if client is not None:
            try:
                client.command("set_input_lock", locked=False)
            except Exception:
                pass
            client.close()
        if process is not None and not args.keep_open:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()


if __name__ == "__main__":
    raise SystemExit(main())
