#!/usr/bin/env python3
"""Bind independently executed evidence, without inventing a native pass."""
from pathlib import Path
import datetime,hashlib,json,re
ROOT=Path(__file__).resolve().parent
REPO=ROOT.parent.parent
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def main():
    result=json.loads((ROOT/'results.json').read_text())
    assert result['summary']==dict(total=32,failed=0,integrity_failed=0,candidate_checked=32,gnu_checked=32,gnu_skipped=0,gnu_executed=18,gnu_compile_only=8,gnu_compile_rejections=6)
    assert not result['integrity_errors']
    h=(ROOT/'harness-results.log').read_text();assert 'Ran 37 tests' in h and h.rstrip().endswith('OK') and 'skipped=' not in h
    n=(ROOT/'native-results.log').read_text();assert 'release039 composition: 1117 assertions passed' in n
    assert (ROOT/'native-results.exit').read_text().strip()=='0'
    discrepancy=json.loads((ROOT/'oracle-limitations/independent-receipt.json').read_text())
    assert discrepancy['candidate_sha256']==result['candidate_sha256'] and len(discrepancy['gnu'])==2
    binaries=list(REPO.glob('build/*/test/test_release039_composition'))
    assert len(binaries)==1,binaries
    artifacts={str(p.relative_to(ROOT)):sha(p) for p in sorted(ROOT.rglob('*')) if p.is_file() and '__pycache__' not in str(p) and p.name!='receipt.json'}
    source=REPO/'test/test_release039_composition.f90'
    receipt=dict(scope='Independent bounded synthetic release039 composition; no upstream rewrite and no whole xutilities execution claim.',utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),candidate_sha256=result['candidate_sha256'],source=dict(file='results.json',summary=result['summary'],fixed_manifest_sha256=sha(ROOT/'synthetic-manifest.json')),harness=dict(log='harness-results.log',tests=37,failed=0,skipped=0),native=dict(source='test/test_release039_composition.f90',source_sha256=sha(source),log='native-results.log',exit_file='native-results.exit',exit=0,assertions=1117,command='fpm test --profile debug --target test_release039_composition',executed_by='integration owner',binary=str(binaries[0].relative_to(REPO)),binary_sha256=sha(binaries[0])),oracle_limitation=dict(file='oracle-limitations/independent-receipt.json',classification='explicit known GNU runtime discrepancy, not execution agreement',optimizations=['-O0','-O2']),core_sha256={str(p.relative_to(REPO)):sha(p) for p in [REPO/'src/fi_ir.f90',REPO/'src/fi_parser.f90',REPO/'src/fi_frontend.f90',REPO/'src/fi_runtime.f90']},artifact_sha256=artifacts)
    (ROOT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(dict(candidate_sha256=result['candidate_sha256'],source_contracts=32,gnu_executed=18,gnu_compile_only=8,gnu_compile_rejections=6,harness=37,native_assertions=1117,artifacts=len(artifacts))))
if __name__=='__main__':main()
