#!/usr/bin/env python3
"""Replay retained GNU scope/kind probes separately from the ordinary oracle suite."""
from pathlib import Path
import argparse,datetime,hashlib,json,subprocess
ROOT=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0']
RUN={'outer_preserved','negative_zero','kind_inherited','active_do','allocatable_name','pointer_name','no_outer_defined','kind8_runtime','kind8_small','kind8_leaf_precision','zero_char_length','function_controls'}
def invoke(argv,cwd):
    p=subprocess.run([str(x) for x in argv],cwd=cwd,capture_output=True,timeout=30,stdin=subprocess.DEVNULL)
    return dict(command=[str(x) for x in argv],code=p.returncode,stdout=p.stdout.decode('latin1'),stderr=p.stderr.decode('latin1'))
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--gfortran',required=True);ap.add_argument('--result',type=Path,default=ROOT/'evidence/semantic-probes.json');a=ap.parse_args()
    folder=ROOT/'evidence'/('probes-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ'));folder.mkdir(parents=True)
    rows=[]
    for src in sorted((ROOT/'probes').glob('*.f90')):
        exe=folder/src.stem
        command=[a.gfortran,*FLAGS,src]+(['-o',exe] if src.stem in RUN else ['-fsyntax-only'])
        c=invoke(command,folder);row=dict(name=src.stem,source='probes/'+src.name,source_sha256=hashlib.sha256(src.read_bytes()).hexdigest(),compile=c,execution_allowed=src.stem in RUN)
        if c['code']==0 and src.stem in RUN:row['run']=invoke([exe],folder)
        rows.append(row)
    r=dict(compiler=invoke([a.gfortran,'--version'],folder),flags=FLAGS,notes='Exploratory standards evidence. kind_inherited intentionally captures a GNU constant-folding anomaly and is not a normal oracle fixture. Invalid inputs never execute.',records=rows)
    a.result.write_text(json.dumps(r,indent=2)+'\n');print(f'Recorded {len(rows)} semantic probes')
if __name__=='__main__':main()
