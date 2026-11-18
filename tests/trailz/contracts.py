"""Fail-closed source, process, and record contracts for TRAILZ."""
import base64, hashlib, json, re
from pathlib import Path
TOKEN = re.compile(r'(?:0|-?[1-9][0-9]*|T|F)\Z', re.ASCII)
HASH = re.compile(r'[0-9a-f]{64}\Z', re.ASCII)
VERSION = re.compile(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\Z', re.ASCII)
CRASH = re.compile(r'backtrace|traceback|internal compiler error|Fortran runtime error|segmentation fault|sig(?:segv|abrt|bus|fpe|ill|kill|term)|core dumped|addresssanitizer|undefinedbehaviorsanitizer|program received signal|error termination|floating.point exception', re.I)
PROCESS_KEYS = {'command','returncode','stdout','stderr','timeout','valid_utf8','stdout_sha256','stderr_sha256','stdout_base64','stderr_base64'}
MODES = {'execute','compile','reject','processor_reject','backend_reject'}
SPECIAL_REJECTS = {
 'shadow_explicit': ('backend_reject','284ff9477b29e4fb191b4b79cafe8daeaf35dd82d8a42a4868243bafaf15594b'),
 'model_consistency': ('processor_reject','8355278fb5744b29671ab3b5e4afcdba58d4f7d22aaefc08bfc49c0a268c38d8'),
 'vector_parameter_copy': ('processor_reject','12895ae28c967ee5c996393273452e0a089c885cb79789684827047caf1414be')}
PROCESSOR_DIAGNOSTICS = {'model_consistency': '{source}:4:12-27:\n\n    4 | print *,all(integer_kinds==[int32,int64]),bit_size(0_int32),bit_size(0_int64)\n      |            1              2\nError: Shapes for operands at (1) and (2) are not conformable\n', 'vector_parameter_copy': "{source}:4:26:\n\n    4 | integer,parameter::copy(2)=integer_kinds\n      |                          1\nError: Different shape for array assignment at (1) on dimension 1 (2 and 5)\n{source}:5:12:\n\n    5 | print *,copy\n      |            1\nError: Symbol 'copy' at (1) has no IMPLICIT type\n"}
BACKEND_TEXT = "symbol `__iso_fortran_env_MOD_integer_kinds' is already defined"
ORIGINAL_SHA = '387a08537833bee3d7af1be7ec8c3a12dbde79cbfb4584ffc50c583429055f0c'
ORIGINAL_STDOUT_SHA = '5e56b38e9df96f853f4147ddebba861a5b970c978bb17f98e665c90199de26e9'

def require(ok, message):
    if not ok: raise ValueError(message)

def digest(data): return hashlib.sha256(data).hexdigest()
def sha(path): return digest(Path(path).read_bytes())
def pairs_unique(pairs):
    d = {}
    for k,v in pairs:
        require(k not in d, 'duplicate JSON key: '+k); d[k] = v
    return d

def load_json(path):
    return json.loads(Path(path).read_bytes().decode('utf-8'), object_pairs_hook=pairs_unique,
                      parse_constant=lambda x: (_ for _ in ()).throw(ValueError('nonfinite JSON constant')))

def valid_records(x):
    return isinstance(x,list) and all(isinstance(r,list) and bool(r) and all(isinstance(t,str) and TOKEN.fullmatch(t) for t in r) for r in x)

def validate_manifest(manifest, root, final=False):
    root=Path(root).resolve()
    require(isinstance(manifest,dict), 'manifest object')
    require(set(manifest) <= {'status','initial_manifest_sha256','first_gnu_results_sha256','cases','predecessor_manifest_sha256'},'unknown manifest key')
    require(isinstance(manifest.get('status'),str) and bool(manifest['status']), 'manifest status')
    for key in set(manifest)-{'status','cases'}: require(isinstance(manifest[key],str) and HASH.fullmatch(manifest[key]),'manifest identity hash')
    cases=manifest.get('cases');require(isinstance(cases,list) and bool(cases),'nonempty cases')
    names=set();sources=set()
    allowed={'name','source','sha256','candidate_stage','gnu','expected_records','processor_model','gnu_expected_records','source_note','gnu_stage_reason','gnu_diagnostic_contains','reference_stdout','reference_stdout_sha256','oracle_note','original','diagnostics'}
    for c in cases:
        require(isinstance(c,dict) and set(c)<=allowed,'case schema')
        name=c.get('name');require(isinstance(name,str) and re.fullmatch(r'[a-z][a-z0-9_]*',name,re.ASCII),'case name')
        require(name not in names,'duplicate case name');names.add(name)
        source=c.get('source');require(source=='cases/'+name+'.f90','case/source bijection')
        require(source not in sources,'duplicate source');sources.add(source)
        p=root/source
        require(not p.is_symlink() and not p.parent.is_symlink() and p.is_file() and p.resolve().parent==root/'cases','source containment/symlink')
        require(isinstance(c.get('sha256'),str) and HASH.fullmatch(c['sha256']) and sha(p)==c['sha256'],'exact source identity')
        require(c.get('candidate_stage') in {'success','check','runtime'},'candidate stage')
        require(c.get('gnu') in MODES,'GNU mode')
        require(valid_records(c.get('expected_records')),'expected record schema')
        if 'gnu_expected_records' in c: require(valid_records(c['gnu_expected_records']),'GNU expected record schema')
        for k in ['original','processor_model']:
            if k in c:require(type(c[k]) is bool,'boolean case field')
        for k in ['source_note','gnu_stage_reason','oracle_note']:
            if k in c:require(isinstance(c[k],str) and bool(c[k]),'nonempty case note')
        if name in SPECIAL_REJECTS:
            mode,h=SPECIAL_REJECTS[name];require(c['gnu']==mode and c['sha256']==h and c.get('processor_model') is True,'pinned special GNU classification')
        elif c['gnu'] in {'processor_reject','backend_reject'}:raise ValueError('unknown special GNU rejection')
        if c['gnu']=='backend_reject':require(c.get('gnu_diagnostic_contains')==BACKEND_TEXT,'exact backend cause')
        else:require('gnu_diagnostic_contains' not in c,'backend text outside backend category')
        if c.get('original'):
            require(name=='original_demo_trailz' and c['sha256']==ORIGINAL_SHA and c.get('reference_stdout_sha256')==ORIGINAL_STDOUT_SHA and isinstance(c.get('reference_stdout'),str) and digest(c['reference_stdout'].encode())==ORIGINAL_STDOUT_SHA,'pinned original contract')
        else:require('reference_stdout' not in c and 'reference_stdout_sha256' not in c,'unexpected reference output')
        diagnostics=c.get('diagnostics',{})
        require(isinstance(diagnostics,dict) and set(diagnostics)<= {'check','run'},'diagnostic phases')
        phases={'check','run'} if c['candidate_stage']=='check' else ({'run'} if c['candidate_stage']=='runtime' else set())
        require(set(diagnostics)<=phases and (not final or set(diagnostics)==phases),'diagnostic stage agreement')
        for d in diagnostics.values():
            require(isinstance(d,dict) and set(d)=={'line','column','message'},'diagnostic schema')
            require(type(d['line']) is int and d['line']>0 and type(d['column']) is int and d['column']>0,'diagnostic location')
            require(isinstance(d['message'],str) and d['message'] and not re.search(r'[\r\n\0]',d['message']) and not CRASH.search(d['message']),'diagnostic message')
    inventory={str(p.relative_to(root)) for p in (root/'cases').iterdir()}
    require(inventory==sources,'manifest/source inventory bijection')
    return {s:sha(root/s) for s in sorted(sources)}

def integer_records(output,expected):
    if not isinstance(output,str):return False
    if not expected:return output==''
    if not output.endswith('\n') or any(x in output for x in '\r\t\v\f\0'):return False
    lines=output[:-1].split('\n')
    if len(lines)!=len(expected):return False
    for line,wanted in zip(lines,expected):
        if re.search(r'[^ 0-9TF-]',line):return False
        got=[x for x in line.split(' ') if x]
        if not got or any(not TOKEN.fullmatch(x) for x in got) or got!=wanted:return False
    return True

def output_matches(case,output):
    if not case.get('original'):return integer_records(output,case['expected_records'])
    if case['sha256']!=ORIGINAL_SHA:return False
    reference=case['reference_stdout']
    if digest(reference.encode())!=ORIGINAL_STDOUT_SHA:return False
    if not isinstance(output,str):return False
    a=output.splitlines(keepends=True);b=reference.splitlines(keepends=True)
    if len(a)!=len(b) or len(a)!=10:return False
    for i,(x,y) in enumerate(zip(a,b),1):
        if i==1:
            if re.fullmatch(r' Note default integer is +32 bits\n',x) is None:return False
        elif i==7:
            if not integer_records(x,[['5','13','4']]):return False
        elif x!=y:return False
    return True

def process_errors(record, command=None):
    """Validate actual raw bytes, not caller-supplied status/encoding assertions."""
    if not isinstance(record,dict) or set(record)!=PROCESS_KEYS:return ['exact process schema']
    errors=[];argv=record['command']
    if not isinstance(argv,list) or not argv or any(not isinstance(x,str) or not x or '\0' in x for x in argv):errors.append('command schema')
    if command is not None and argv!=list(map(str,command)):errors.append('exact command')
    if type(record['returncode']) is not int or record['returncode']<0:errors.append('integer non-signal status')
    if record['timeout'] is not False:errors.append('timeout state')
    if record['valid_utf8'] is not True:errors.append('UTF-8 state')
    for stream in ['stdout','stderr']:
        try:
            encoded=record[stream+'_base64'];require(isinstance(encoded,str),'base64 type')
            raw=base64.b64decode(encoded,validate=True)
            require(base64.b64encode(raw).decode()==encoded,'canonical base64')
            require(raw.decode('utf-8')==record[stream],'raw/text binding')
            require(digest(raw)==record[stream+'_sha256'],'raw/hash binding')
            require('\0' not in record[stream],'NUL output')
            if CRASH.search(record[stream]):errors.append('host crash marker')
        except (ValueError,TypeError,UnicodeError):errors.append(stream+' raw encoding/hash/text binding')
    return errors

def version_errors(record, *, expected_version=None, gnu_stdout_sha256=None, command=None):
    errors=process_errors(record,command)
    if errors:return errors
    if record['returncode']!=0 or record['stderr']!='':errors.append('successful version stage')
    if expected_version is not None:
        if not isinstance(expected_version,str) or not VERSION.fullmatch(expected_version) or re.fullmatch('fortfront-interpreter '+re.escape(expected_version)+r'; FortFront [0-9a-f]{7,40} \+ documented local patches\n',record['stdout']) is None:errors.append('exact CLI version banner')
    elif gnu_stdout_sha256 is not None:
        if not isinstance(gnu_stdout_sha256,str) or not HASH.fullmatch(gnu_stdout_sha256) or record['stdout_sha256']!=gnu_stdout_sha256 or re.match(r'GNU Fortran [^\r\n]+\n',record['stdout']) is None:errors.append('exact GNU version banner')
    else:errors.append('explicit version contract required')
    return errors

def gnu_errors(case,phase,record,command=None):
    errors=process_errors(record,command)
    if errors:return errors
    mode=case.get('gnu')
    if mode not in MODES:return ['unknown GNU mode']
    if phase=='compile':
        rejected=mode in {'reject','backend_reject','processor_reject'}
        if record['returncode']!=(1 if rejected else 0):errors.append('exact GNU compile status')
        if record['stdout']!='':errors.append('GNU compile stdout')
        if rejected and not record['stderr']:errors.append('missing GNU rejection diagnostic')
        if mode=='backend_reject' and BACKEND_TEXT not in record['stderr']:errors.append('exact known backend cause')
        if mode=='processor_reject':
            name=case.get('name');argv=record['command']
            if name not in PROCESSOR_DIAGNOSTICS or case.get('sha256')!=SPECIAL_REJECTS.get(name,(None,None))[1] or len(argv)!=9 or argv[1:6]!=['-std=f2018','-pedantic-errors','-fcheck=all','-ffree-line-length-none','-O0'] or argv[-2]!='-o' or not argv[-3].endswith('/cases/'+str(name)+'.f90'):
                errors.append('exact processor-shape source/command binding')
            elif record['stderr']!=PROCESSOR_DIAGNOSTICS[name].format(source=argv[-3]):
                errors.append('exact source-located processor-shape diagnostic stream')
        # Successful compiler warnings are preserved, not treated as runtime output.
    elif phase=='run':
        if mode!='execute':errors.append('GNU run not authorized by case mode')
        if record['returncode']!=0 or record['stderr']!='':errors.append('successful GNU runtime status/stderr')
        if not output_matches({**case,'expected_records':case.get('gnu_expected_records',case['expected_records'])},record['stdout']):errors.append('GNU exact expected records')
    else:errors.append('unknown GNU phase')
    return errors

def stage_errors(case,phase,record,source,observe=False,command=None):
    errors=process_errors(record,command)
    if errors:return errors
    if phase not in {'check','run'} or case.get('candidate_stage') not in {'check','runtime','success'}:return ['unknown candidate phase/stage']
    code=(1 if case['candidate_stage']=='check' else 0) if phase=='check' else {'check':1,'runtime':2,'success':0}[case['candidate_stage']]
    if record['returncode']!=code:errors.append('exact integer exit status')
    out,err=record['stdout'],record['stderr']
    if phase=='check':
        if out!='':errors.append('check stdout not empty')
    elif not output_matches(case,out):errors.append('exact output records')
    if code==0:
        if err!='':errors.append('successful stderr not empty')
    elif observe:
        if re.fullmatch(re.escape(str(source))+r':[1-9][0-9]*:[1-9][0-9]*: [^\r\n]+\n',err) is None:errors.append('observed single source-located diagnostic')
    else:
        diagnostic=case.get('diagnostics',{}).get(phase)
        if not diagnostic:errors.append('exact diagnostic contract not yet pinned')
        elif err!=f"{source}:{diagnostic['line']}:{diagnostic['column']}: {diagnostic['message']}\n":errors.append('exact phase/location/message')
    return errors
