#!/usr/bin/python3
import sys
sys.path.insert(1, '../../python_scripts/')
import params as P
import benchs as B
import libxp as E

TIMEOUT = 3600          
N_ITER = 1
STAT_FILE = "stats/streamxor.csv"
DEBUG = P.NONE
# DEBUG = P.VERBOSE
# DEBUG = P.VERBOSE_LIGHT
# DEBUG = P.DEBUG
# DEBUG = P.DEBUG_LIGHT

# Use cases
streamxor = B.Executable("streamxor", high_syms="message,key",
			memory_file="streamxor.mem")
executables = [streamxor]

if __name__ == '__main__':

    benchs = B.BenchsFromExecutables(executables)
    params = P.Params(timeout=TIMEOUT, n_iter=N_ITER,
                      stat_file=STAT_FILE, debug=DEBUG)


    # Experiments for Spectre_PHT Dynamic
    # E.xp_runner(benchs, params, pht=E.PHT_EXPLICIT, dyn_pht=E.DYN_PHT_FULL)
    E.xp_runner(benchs, params, pht=E.PHT_HAUNTED, dyn_pht=E.DYN_PHT_FULL)

    # Experiments for Spectre-STL
    # E.xp_runner(benchs, params, stl=E.STL_EXPLICIT)
    E.xp_runner(benchs, params, stl=E.STL_HAUNTED)
