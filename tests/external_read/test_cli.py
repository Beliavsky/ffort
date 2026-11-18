#!/usr/bin/env python3
"""Opt-in CLI loader checks. Every path is created inside one temporary directory."""
from pathlib import Path
import argparse,json,os,subprocess,tempfile

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--candidate',required=True);parser.add_argument('--result',default='cli-results.json');args=parser.parse_args()
    records=[]
    with tempfile.TemporaryDirectory(prefix='fortfront-explicit-input-') as folder:
        root=Path(folder);source=root/'reader.f90'
        source.write_text("program p\ninteger::u,s\ncharacter(4)::line\nu=27\nread(u,'(a)',iostat=s)line\nif(s/=0.or.line/='word')stop 1\nprint '(a)','OK'\nend\n")
        record=root/'record.txt';record.write_bytes(b'word\n')
        missing=root/'missing.txt';large=root/'large.txt';large.write_bytes(b'x'*1048577)
        def check(name,options,code,needle='',out='',src=source):
            proc=subprocess.run([args.candidate,*options,str(src)],cwd=root,stdin=subprocess.DEVNULL,capture_output=True,timeout=15)
            err=proc.stderr.decode(errors='replace');stdout=proc.stdout.decode(errors='replace')
            ok=proc.returncode==code and stdout==out and (needle in err if code else err=='')
            records.append(dict(name=name,passed=ok,code=proc.returncode,stdout=stdout,stderr=err))
            if not ok: print(name,'FAIL',records[-1])
        check('regular_file',['--input','27='+str(record)],0,out='OK\n')
        check('missing_binding',['--input','27='+str(missing)],1,'Cannot open explicit')
        check('check_does_not_open',['--check','--input','27='+str(missing)],0)
        check('check_ignores_file_size',['--check','--input','27='+str(large)],0)
        check('size_cap',['--input','27='+str(large)],1,'1048576-byte')
        check('directory',['--input','27='+str(root)],1,'regular file')
        for name,value in [('missing_equals','27'),('zero_unit','0=x'),('negative_unit','-27=x'),('overflow_unit','2147483648=x'),('empty_path','27='),('empty_unit','=x'),('signed_unit','+27=x'),('nondecimal_unit','2a=x')]:
            check(name,['--input',value],1,'--input')
        check('duplicate',['--input','27='+str(record),'--input','27='+str(missing)],1,'duplicate')
        check('unit_limit',sum((['--input',str(i)+'='+str(missing)] for i in range(1,34)),[]),1,'at most 32')
        # Compile errors must not be displaced by errors in a file that should never open.
        bad=root/'bad.f90';bad.write_text('program p\nnot valid Fortran\nend\n')
        check('compile_before_binding',['--input','27='+str(missing)],1,'unsupported',src=bad)
        if hasattr(os,'mkfifo'):
            fifo=root/'fifo';os.mkfifo(fifo)
            check('fifo_nonblocking',['--input','27='+str(fifo)],1,'regular file')
        try:
            link=root/'link';link.symlink_to(record)
        except (OSError,NotImplementedError): pass
        else: check('symlink_rejected',['--input','27='+str(link)],1,'input')
        cap=root/'cap.txt';cap.write_bytes(b'word\n'+b' '*(1048576-5))
        check('individual_cap_inclusive',['--input','27='+str(cap)],0,out='OK\n')
        check('aggregate_cap',sum((['--input',str(i)+'='+str(cap)] for i in range(27,32)),[]),1,'total byte limit')
        check('aggregate_cap_inclusive',sum((['--input',str(i)+'='+str(cap)] for i in range(27,31)),[]),0,out='OK\n')
        if any(p.name.startswith('fort.') for p in root.iterdir()): raise AssertionError('Implicit unit file created')
        assert record.read_bytes()==b'word\n'
    result=dict(total=len(records),failed=sum(not x['passed'] for x in records),records=records)
    (Path(__file__).parent/args.result).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='records'}))
    return bool(result['failed'])
if __name__=='__main__':raise SystemExit(main())
