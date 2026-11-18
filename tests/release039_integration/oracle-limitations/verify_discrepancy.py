#!/usr/bin/env python3
"""Independently replay exact GNU O0/O2 discrepancy, never count agreement."""
from pathlib import Path
from decimal import Decimal,ROUND_DOWN,ROUND_HALF_UP,localcontext
import argparse,importlib.util,json,tempfile
ROOT=Path(__file__).resolve().parent
s=importlib.util.spec_from_file_location('composition_runner',ROOT.parent/'run_tests.py');r=importlib.util.module_from_spec(s);s.loader.exec_module(r)
SOURCE_SHA256='3e9737f167d902546dd440a3922e69eb4a863227d7ff19e8c027a019c0ad72df'
# IEEE REAL8 input decimals are strictly inside the same rounding intervals;
# distance to boundary is >10^-12 for 1.999... and >9e-13 for .499... .
EXPECTED=['0','-0','1','-1','0','-0','2','-2','1','0','0','-0','1','-1','0','-0','2','-2']
GNU_EXPECTED=['0','-0','2','-2','1','-1','2','-2','1','0','0','-0','1','-1','0','-0','2','-2']
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True);ap.add_argument('--gfortran',required=True);a=ap.parse_args()
    src=ROOT/'narrow_result.f90'
    if r.digest(src)!=SOURCE_SHA256:raise ValueError('probe bytes changed')
    # Decimal arguments and one-ULP neighboring decimal bounds independently
    # yield the same integral round results; no candidate or GNU oracle used.
    with localcontext() as ctx:
        ctx.prec=100
        for value in ['0.499999999999','-0.499999999999','1.999999999999','-1.999999999999']:
            x=Decimal(value)
            for delta in [Decimal('-2e-16'),Decimal('0'),Decimal('2e-16')]:
                for mode in [ROUND_DOWN,ROUND_HALF_UP]:
                    assert (x+delta).to_integral_value(rounding=mode)==x.to_integral_value(rounding=mode)
    receipt=dict(source='narrow_result.f90',source_sha256=SOURCE_SHA256,classification='known GNU runtime optional-KIND discrepancy; not execution agreement',candidate_expected=EXPECTED,gnu_observed_expected=GNU_EXPECTED,gnu=[],independent_basis='Round A before converting its whole-valued result to the KIND representation. The required whole values0,1,2 are exactly representable in REAL4. Decimal intervals including all possible binary64 parse rounding preserve the rounding decisions.',primary_sources=['https://gcc.gnu.org/onlinedocs/gfortran/AINT.html','https://gcc.gnu.org/onlinedocs/gfortran/ANINT.html'])
    with tempfile.TemporaryDirectory(prefix='release039-discrepancy-') as td:
        folder=Path(td);candidate=folder/'candidate';receipt['candidate_sha256']=r.snapshot(Path(a.candidate),candidate)
        receipt['compiler_version']=r.execute([a.gfortran,'--version'],folder)
        if receipt['compiler_version']['code'] or receipt['compiler_version']['err']:raise ValueError('compiler version')
        for opt in ['-O0','-O2']:
            binary=folder/('gnu'+opt);comp=r.execute([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all',opt,src,'-o',binary],folder)
            if comp['code'] or comp['out'] or comp['err']:raise ValueError('GNU compile')
            run=r.execute([binary],folder)
            if r.crash(run) or run['code'] or run['err'] or not r.exact_numeric(run['out'],GNU_EXPECTED):raise ValueError('GNU observation changed; review manually')
            receipt['gnu'].append(dict(optimization=opt,compile=comp,run=run))
        run=r.execute([candidate,src],folder);receipt['candidate']=run
        if r.crash(run) or run['code'] or run['err'] or not r.exact_numeric(run['out'],EXPECTED):raise ValueError('candidate failed independent round-before-convert values')
    (ROOT/'independent-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print('O0/O2 discrepancy reproduced; candidate independent exact expectations passed')
if __name__=='__main__':main()
