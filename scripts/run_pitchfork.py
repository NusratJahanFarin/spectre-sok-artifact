#!/usr/bin/env python3

import argparse
import sys
import time
from pathlib import Path
import csv
import logging
import multiprocessing
import traceback
import io
import re
import os
import tempfile
from contextlib import redirect_stdout, redirect_stderr

import claripy
import pitchfork
from pitchfork import angr, funcEntryState, _spectreSimgr, getAddressOfSymbol, addSecretObject, getArgBVS
from abstractdata import publicValue, secretValue, pointerTo, pointerToUnconstrainedPublic, publicArray, secretArray, array, struct

l = logging.getLogger(__name__)
l.setLevel(logging.INFO)

# ---------- Helper functions ----------

def generate_filename(test_name, spec=False, guided=False, misforwarding=False, trace=False):
    parts = [test_name]
    if spec: parts.append("spec")
    if guided: parts.append("guided")
    if misforwarding: parts.append("misforwarding")
    if trace: parts.append("trace")
    parts.append("O0")
    return ".".join(parts)

def save_test_results(results, csv_filename="pitchfork_results.csv", append=True):
    csv_path = Path(csv_filename)
    mode = "a" if append and csv_path.exists() else "w"
    fieldnames = ["test", "violations", "paths", "addresses", "spec", "misforwarding",
                  "guided", "trace", "filename", "wall_time", "running_time"]
    with open(csv_path, mode=mode, newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if mode == "w":
            writer.writeheader()
        for row in results:
            filename = generate_filename(
                test_name=row["test"],
                spec=row.get("spec", False),
                guided=row.get("guided", False),
                misforwarding=row.get("misforwarding", False),
                trace=row.get("trace", False)
            )
            row_copy = row.copy()
            row_copy["filename"] = filename
            writer.writerow(row_copy)
    print(f"[+] Results saved to {csv_filename}")

def arg_to_fname(arg, val):
    sarg = ''
    if isinstance(val, bool):
        if not val:
            sarg = 'no-'
        sarg += arg
    elif isinstance(val, int):
        if val is not None:
            sarg = arg + str(val)
    return sarg

# ---------- Spectre Cases ----------

SPECTREV1_CASES = (
    [f"case_{i}" for i in range(1, 11)] +
    ["case_11gcc", "case_11ker", "case_11sub"] +
    [f"case_{i}" for i in range(12, 15)]
)

SPECTREV4_CASES = (
    [f"case_{i}" for i in range(1, 9)] +
    #["case_9_bis"] +
    [f"case_{i}" for i in range(10, 14)]
)

# ---------- Test Functions ----------
#======================================
# Spectrev1
#======================================

def spectrev1(args, generating_fname=False):
    parser = argparse.ArgumentParser('spectrev1')
    parser.add_argument('--case', required=True)
    args = parser.parse_args(args)
    if generating_fname:
        return f".{args.case}"
    proj = angr.Project('bench/binaries/spectrev1_clang_O0', load_options={"auto_load_libs": False})
    state = funcEntryState(proj, args.case, [
        ("idx", publicValue(bits=64)),
        ("secretarray", pointerTo(secretArray(16), 16)),
    ])
    whitelist = []   # NOT None
    path = ''        # NOT None
    return proj, state, args.case, whitelist, path 
    
#======================================
# Spectrev4
#======================================

def spectrev4(args, generating_fname=False):
    parser = argparse.ArgumentParser('spectrev4')
    parser.add_argument('--case', required=True)
    args = parser.parse_args(args)
    if generating_fname:
        return f".{args.case}"
    proj = angr.Project('bench/binaries/spectrev4_clang_O0', load_options={"auto_load_libs": False})
    state = funcEntryState(proj, args.case, [
        ("idx", publicValue(bits=64)),
        ("secretarray", pointerTo(secretArray(16), 16)),
    ])
    whitelist = []   # NOT None
    path = ''        # NOT None
    return proj, state, args.case, whitelist, path 
    
#======================================
# Tea
#======================================

def tea(args, generating_fname=False):
    parser = argparse.ArgumentParser('tea')
    args = parser.parse_args(args)
    if generating_fname:
        return ''
    proj = angr.Project('bench/binaries/tea', load_options={"auto_load_libs": False})
    state = funcEntryState(proj, "encipher", [
        ("data", pointerTo(publicArray(8), 8)),
        ("out", pointerTo(publicArray(8), 8)),
        ("key", pointerTo(secretArray(16), 16)),
    ])

    whitelist = []   # NOT None
    path = ''        # NOT None
        
    return proj, state, "encipher", whitelist, path 
    
#======================================
# Secretbox
#======================================

def secretbox(args, generating_fname=False):
    parser = argparse.ArgumentParser('secretbox')
    args = parser.parse_args(args)

    if generating_fname:
        return ''

    proj = angr.Project('bench/binaries/secretbox', load_options={"auto_load_libs": False})

    fname = "crypto_secretbox"
    params = [
        ("c", pointerToUnconstrainedPublic()), 
        ("m", pointerToUnconstrainedPublic()),
        ("mlen", publicValue()),    
        ("n", pointerTo(publicArray(24), 24)),
        ("k", pointerTo(secretArray(32), 32)),
    ]

    state = funcEntryState(proj, fname, params)

    whitelist = []   # NOT None
    path = ''        # NOT None

    return proj, state, fname, whitelist, path 
    
#======================================
# Poly1305
#====================================== 
def poly1305(args, generating_fname=False):
    parser = argparse.ArgumentParser('poly1305', add_help=False)
    args, _ = parser.parse_known_args(args)

    if generating_fname:
        return ''

    proj = angr.Project('bench/binaries/poly1305', load_options={"auto_load_libs": False})
    
    MSG_SIZE = 16
    
    state = funcEntryState(proj, "crypto_onetimeauth_poly1305", [
        ("mac", pointerTo(publicArray(16), 16)),
        ("m", pointerTo(secretArray(MSG_SIZE), MSG_SIZE)),
        ("mlen", publicValue(16, bits=64)),          # <-- FIXED
        ("k", pointerTo(secretArray(32), 32)),
    ])
    # ===== Speed improvements =====
    mlen = getArgBVS(state, "mlen")
    state.add_constraints(mlen == MSG_SIZE)
    
    whitelist = []
    path = ''

    return proj, state, "crypto_onetimeauth_poly1305", whitelist, path
#======================================
# Salsa
#====================================== 
def salsa(args, generating_fname=False):
    parser = argparse.ArgumentParser('salsa', add_help=False)
    args, _ = parser.parse_known_args(args)

    if generating_fname:
        return ''

    proj = angr.Project('bench/binaries/salsa', load_options={"auto_load_libs": False})
    
    MSG_SIZE = 16
    
    state = funcEntryState(proj, "crypto_stream_salsa20_xor", [
        ("c", pointerTo(publicArray(16), 16)),
        ("m", pointerTo(secretArray(MSG_SIZE), MSG_SIZE)),
        ("n", pointerTo(publicArray(24), 24)),
        ("k", pointerTo(secretArray(32), 32)),
    ])
    # ===== Speed improvements =====
    mlen = getArgBVS(state, "mlen")
    state.add_constraints(mlen == MSG_SIZE)
    
    whitelist = []
    path = ''

    return proj, state, "crypto_stream_salsa20_xor", whitelist, path

#======================================
# sha512
#====================================== 
def sha512(args, generating_fname=False):
    parser = argparse.ArgumentParser('sha512', add_help=False)
    args, _ = parser.parse_known_args(args)

    if generating_fname:
        return ''

    proj = angr.Project('bench/binaries/sha512', load_options={"auto_load_libs": False})
    
    MSG_SIZE = 16
    
    state = funcEntryState(proj, "crypto_hash_sha512", [
        ("out", pointerTo(publicArray(16), 16)),
        ("in", pointerTo(secretArray(MSG_SIZE), MSG_SIZE)),
        ("mlen", publicValue(16, bits=64)),          # <-- FIXED
    ])
    # ===== Speed improvements =====
    mlen = getArgBVS(state, "mlen")
    state.add_constraints(mlen == MSG_SIZE)
    
    whitelist = []
    path = ''

    return proj, state, "crypto_hash_sha512", whitelist, path
    

#======================================
# streamxor
#====================================== 
def streamxor(args, generating_fname=False):
    parser = argparse.ArgumentParser('streamxor', add_help=False)
    args, _ = parser.parse_known_args(args)

    if generating_fname:
        return ''

    proj = angr.Project('bench/binaries/streamxor', load_options={"auto_load_libs": False})
    
    MSG_SIZE = 16
    
    state = funcEntryState(proj, "crypto_stream_xor", [
        ("out", pointerTo(publicArray(16), 16)),
        ("message", pointerTo(secretArray(MSG_SIZE), MSG_SIZE)),
        ("mlen", publicValue(16, bits=64)),          # <-- FIXED
        ("n", pointerTo(publicArray(24), 24)),        
        ("k", pointerTo(secretArray(32), 32)),       
    ])
    # ===== Speed improvements =====
    mlen = getArgBVS(state, "mlen")
    state.add_constraints(mlen == MSG_SIZE)
    
    whitelist = []
    path = ''

    return proj, state, "crypto_hash_sha512", whitelist, path
        
#======================================
# ed25519
#====================================== 
def ed25519(args, generating_fname=False):
    parser = argparse.ArgumentParser('ed25519', add_help=False)
    args, _ = parser.parse_known_args(args)

    if generating_fname:
        return ''

    proj = angr.Project('bench/binaries/ed25519', load_options={"auto_load_libs": False})
    
    MSG_SIZE = 16
    
    state = funcEntryState(proj, "crypto_sign_ed25519", [
        ("out", pointerTo(publicArray(16), 16)),
        ("pout", pointerTo(publicArray(16), 16)),      
        ("message", pointerTo(secretArray(MSG_SIZE), MSG_SIZE)),
        ("mlen", publicValue(16, bits=64)),          
        ("k", pointerTo(secretArray(32), 32)),   # <-- FIXED    
    ])
    # ===== Speed improvements =====
    mlen = getArgBVS(state, "mlen")
    state.add_constraints(mlen == MSG_SIZE)
    
    whitelist = []
    path = ''

    return proj, state, "crypto_sign_ed25519", whitelist, path
 
#======================================    
# Auto-run Configuration
#======================================

AUTO_RUN_TESTS = [
   ("spectrev1", [{"case": c} for c in SPECTREV1_CASES]),
   ("spectrev4", [{"case": c} for c in SPECTREV4_CASES]),
   ("tea", [{}]),
   ("secretbox", [{}]),
   ("poly1305", [{}]),
   ("salsa", [{}]),
   ("sha512", [{}]),
   ("streamxor", [{}]),
   ("ed25519", [{}])
]

#======================================
#Test Runner with Timeout
#======================================

class ViolationCounter(logging.Handler):
    def __init__(self):
        super().__init__()
        self.addresses = set()
        self.pending = False

    def emit(self, record):
        msg = record.getMessage()

        if "UNSAFE READ" in msg or "UNSAFE WRITE" in msg:
            self.pending = True

        elif self.pending and "Instruction Address" in msg:
            try:
                addr = msg.split("Instruction Address")[1].strip()
                self.addresses.add(addr)
            except:
                pass
            self.pending = False

    @property
    def count(self):
        return len(self.addresses)

def capture_violations(proj, state, fname, whitelist, path, spec, misforwarding, window, trace):

    fd, pathfile = tempfile.mkstemp()

    # Save original stderr
    old_stderr = os.dup(2)

    # Redirect stderr to temp file
    os.dup2(fd, 2)

    start = time.perf_counter()

    _spectreSimgr(
        lambda: (proj, state),
        [],
        fname,
        "explicit",
        spec=spec,
        misforwarding=misforwarding,
        whitelist=whitelist,
        window=window,
        trace=trace,
        takepath=path
    )

    end = time.perf_counter()

    # Restore stderr
    os.dup2(old_stderr, 2)
    os.close(old_stderr)

    # Read captured output
    with open(pathfile) as f:
        output = f.read()

    os.remove(pathfile)

    # Replay logs to terminal
    sys.stderr.write(output)
    sys.stderr.flush()

    # Count unique instruction addresses
    addresses = set()
    pending = False

    for line in output.splitlines():
        if "UNSAFE READ" in line or "UNSAFE WRITE" in line or "UNSAFE BRANCH" in line:
            pending = True
        elif pending and "Instruction Address" in line:
            addresses.add(line.strip())
            pending = False

    return len(addresses), end - start, ",".join(addresses)
       
def run_test_with_timeout(test_name, test_args, timeout_seconds=3600):

    result_dict = {
        "test": test_name + " " + " ".join(test_args),
        "violations": "NA",
        "paths": "NA",
        "addresses": "",
        "spec": getattr(args, "spec", False),
        "misforwarding": getattr(args, "misforwarding", False),
        "guided": getattr(args, "guided", False),
        "trace": getattr(args, "trace", False),
        "filename": generate_filename(test_name),
        "wall_time": "NA",
        "running_time": "NA"
    }

    def target(queue):
        try:
            start_time = time.perf_counter()

            rvals = globals()[test_name](test_args)
            proj, state, fname = rvals[:3]
            whitelist = rvals[3] if len(rvals) > 3 else []
            path = rvals[4] if len(rvals) > 4 else ""

            violations, exec_time, addr_str = capture_violations(
                proj=proj,
                state=state,
                fname=fname,
                whitelist=whitelist,
                path=path,
                spec=args.spec,
                misforwarding=args.misforwarding,
                window=args.window,
                trace=args.trace
            )

            end_time = time.perf_counter()

            result = result_dict.copy()
            result["violations"] = violations
            result["wall_time"] = end_time - start_time
            result["running_time"] = exec_time
            result["addresses"] = addr_str

            queue.put(result)

        except Exception:
            tb = traceback.format_exc()
            sys.__stderr__.write(tb)
            sys.__stderr__.flush()

            result = result_dict.copy()
            result["violations"] = "failed"
            queue.put(result)

    queue = multiprocessing.Queue()
    p = multiprocessing.Process(target=target, args=(queue,))
    p.start()
    p.join(timeout_seconds)

    if p.is_alive():
        p.terminate()
        p.join()
        result_dict["violations"] = "timeout"
        result_dict["wall_time"] = timeout_seconds
        return result_dict

    if not queue.empty():
        return queue.get()
    else:
        result_dict["violations"] = "failed"
        return result_dict

#======================================
# main
#======================================

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--trace', action='store_true')
    parser.add_argument('--spec', action='store_true')
    parser.add_argument('--window', type=int, default=200)
    parser.add_argument('--misforwarding', action='store_true')
    parser.add_argument('--guided', action='store_true')
    parser.add_argument('--auto', action='store_true')
    parser.add_argument('--generating-filename', action='store_true')
    parser.add_argument('--timeout', type=int, default=3600, help="Timeout per test in seconds")
    parser.add_argument('test', nargs='?', help="Name of the test function to run")
    args, remaining_args = parser.parse_known_args()

    ALL_RESULTS = []

    if args.auto:
        for test, variants in AUTO_RUN_TESTS:
            for variant in variants:
                print(f"\n[+] Running {test} with args {variant}", flush=True)
                test_args = []
                for k, v in variant.items():
                    test_args += [f"--{k}", str(v)]
                result = run_test_with_timeout(test, test_args, timeout_seconds=args.timeout)
                if result:
                    ALL_RESULTS.append(result)
        if ALL_RESULTS:
            save_test_results(ALL_RESULTS, csv_filename="pitchfork_results.csv", append=True)
        sys.exit(0)

    if args.generating_filename:
            print(generate_filename(
            test_name=args.test,
            spec=args.spec,
            guided=args.guided,
            misforwarding=args.misforwarding,
            trace=args.trace
        ))
            sys.exit(0)

    if not args.test:
        print("[!] No test specified. Use --auto to run all tests.", file=sys.stderr)
        sys.exit(1)

    result = run_test_with_timeout(args.test, remaining_args, timeout_seconds=args.timeout)
    if result:
        ALL_RESULTS.append(result)
    if ALL_RESULTS:
        save_test_results(ALL_RESULTS, csv_filename="bench_analysis_results.csv", append=True)

