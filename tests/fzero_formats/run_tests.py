#!/usr/bin/env python3
"""Portable verifier adapter: pin this invocation and preserve exclusive receipts."""
import argparse,hashlib,json,subprocess,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parent.parent
MANIFEST_SHA='f336dc93ff2e018d428a2ad9ca22df14476434cc50e0ff3abc9ce5ce64d65939'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 ap=argparse.ArgumentParser()
 ap.add_argument('--candidate',type=Path,required=True)
 ap.add_argument('--gfortran',type=Path,required=True)
 ap.add_argument('--compiler-binary',type=Path)
 ap.add_argument('--expected-version',required=True)
 ap.add_argument('--result',type=Path)
 a=ap.parse_args();candidate=a.candidate.resolve();compiler=a.gfortran.resolve()
 binary=(a.compiler_binary or compiler).resolve();runtime=PROJECT/'src/fi_runtime.f90'
 if a.result is not None:
  result=a.result.resolve()
  if result.exists() or result.is_relative_to(ROOT) or result in {candidate,compiler,binary,runtime}:raise SystemExit('Choose a new receipt outside fixture directory')
 else:
  evidence=PROJECT/'verification/fzero_formats';evidence.mkdir(parents=True,exist_ok=True)
  result=Path(tempfile.mkdtemp(prefix='run-',dir=evidence))/'results.json'
 # Refuse fixture edits before even invoking the candidate's version command.
 if sha(ROOT/'manifest.json')!=MANIFEST_SHA:raise SystemExit('F0 manifest hash mismatch')
 before={str(p):sha(p) for p in [candidate,compiler,binary,runtime]}
 banner=subprocess.run([str(candidate),'--version'],capture_output=True,timeout=20)
 result.parent.mkdir(parents=True,exist_ok=True)
 with result.with_suffix('.invocation.json').open('x') as receipt:
  json.dump(dict(identities=before,expected_version=a.expected_version,version_status=banner.returncode,version_stdout_hex=banner.stdout.hex(),version_stderr_hex=banner.stderr.hex(),underlying_compiler_explicit=a.compiler_binary is not None),receipt,indent=2)
  receipt.write('\n')
 expected='fortfront-interpreter '+a.expected_version+'; FortFront 9a5896a + documented local patches\n'
 if banner.returncode!=0 or banner.stderr or banner.stdout!=expected.encode():raise SystemExit('F0 candidate version/full stream mismatch')
 if any(sha(Path(p))!=h for p,h in before.items()):raise SystemExit('Input identity changed during version check')
 command=[sys.executable,str(ROOT/'run_strict.py'),'--candidate',str(candidate),'--candidate-sha256',before[str(candidate)],'--gfortran',str(compiler),'--compiler-sha256',before[str(compiler)],'--compiler-binary',str(binary),'--compiler-binary-sha256',before[str(binary)],'--runtime-source',str(runtime),'--runtime-sha256',before[str(runtime)],'--manifest-sha256',MANIFEST_SHA,'--result',str(result)]
 print('F0 immutable receipt: '+str(result),flush=True)
 done=subprocess.run(command)
 if any(sha(Path(p))!=h for p,h in before.items()):raise SystemExit('Input identity changed during F0 run')
 return done.returncode
if __name__=='__main__':raise SystemExit(main())
