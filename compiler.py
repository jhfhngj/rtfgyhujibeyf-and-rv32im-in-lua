from collections import deque
from math import isqrt

def find_shortest_paths():
    """Uses Breadth-First Search to find the shortest ops from 1 to every ASCII value (0-255)."""
    paths = {1: ""}
    queue = deque([(1, "")])
    
    ops = [
        ("u", lambda x: x + 1),
        ("j", lambda x: x - 1),
        ("y", lambda x: x * 2),
        ("h", lambda x: x // 2),
        ("f", lambda x: x ** 2),
        ("g", lambda x: isqrt(x) if x >= 0 else -1),
    ]
    
    while queue:
        val, path = queue.popleft()
        for code, fn in ops:
            nxt = fn(val)
            if 0 <= nxt <= 1000 and nxt not in paths:
                paths[nxt] = path + code
                queue.append((nxt, path + code))
    return paths

def compile_text(text, paths):
    """Compiles a string into clean rtfgyhujibeyfnsd instructions."""
    program = []
    for idx, ch in enumerate(text):
        code = ord(ch)
        if code not in paths:
            raise ValueError(f"Character {repr(ch)} (ASCII {code}) out of range!")
        # First character uses the starting [1] on the stack; subsequent ones push 1 with 'i'
        prefix = "" if idx == 0 else "i"
        program.append(prefix + paths[code] + "t")
    return "".join(program)

def simulate(prgm):
    """Verifies the compiled code against exact rtfgyhujibeyfnsd rules."""
    stak = [1]
    out = []
    for chrr in prgm:
        if chrr == "t": out.append(chr(stak.pop()))
        elif chrr == "f": stak.append(stak.pop() ** 2)
        elif chrr == "g":
            value = stak.pop()
            stak.append(isqrt(value) if value >= 0 else -1)
        elif chrr == "y": stak.append(stak.pop() * 2)
        elif chrr == "h": stak.append(stak.pop() // 2)
        elif chrr == "u": stak.append(stak.pop() + 1)
        elif chrr == "j": stak.append(stak.pop() - 1)
        elif chrr == "i": stak.append(1)
        elif chrr == "b": stak.append(-1)
        elif chrr == "e": stak.append(0)
        elif chrr == "n": stak.append(stak[-1])
        elif chrr == "s": stak.append(stak.pop() + stak.pop())
        elif chrr == "d": stak.append(stak.pop() - stak.pop())
    return "".join(out), stak

if __name__ == "__main__":
    print("=== rtfgyhujibeyfnsd Optimizing Compiler ===")
    paths = find_shortest_paths()
    
    print("Enter text to compile (type 'END' on a new line when finished):")
    lines = []
    while True:
        line = input()
        if line == "END":
            break
        lines.append(line)
    
    target_text = "\n".join(lines)
    compiled = compile_text(target_text, paths)
    verified_output, final_stack = simulate(compiled)
    
    assert verified_output == target_text, "Verification failed!"
    expected_stack = [] if target_text else [1]
    assert final_stack == expected_stack, f"Unexpected final stack: {final_stack}"
    
    print(f"\n[VERIFIED] Length: {len(compiled)} chars | Final Stack: {final_stack}")
    print("\n--- COMPILED CODE ---")
    print(compiled)
