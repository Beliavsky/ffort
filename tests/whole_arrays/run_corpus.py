#!/usr/bin/env python3
"""Independent whole-array CLI oracle, sharing scalar/element output checks."""
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('element_array_runner', ROOT.parent / 'arrays' / 'run_corpus.py')
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)
base.ROOT = ROOT
base.shared.ROOT = ROOT
original_assess_candidate = base.assess_candidate


def assess_candidate(case, command, timeout):
    return original_assess_candidate(case, command + case.get('candidate_args', []), timeout)


base.assess_candidate = assess_candidate

if __name__ == '__main__':
    raise SystemExit(base.main())
