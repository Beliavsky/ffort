"""Exact source/run and GNU contracts; observational results are never expectations."""
CRASH=('backtrace','traceback','internal compiler error','segmentation fault','sigsegv','sigabrt','addresssanitizer','timeout','fortran runtime error','core dumped')
def stage_errors(record,label='stage'):
 """Validate producer records before using status or streams semantically.

 JSON booleans are not exit statuses. An optional timeout marker must be the
 actual boolean False, not a false-like number/string. Unknown metadata such
 as argv is allowed; malformed required data is an error, never coerced.
 """
 if type(record) is not dict:return [label+': record must be an object']
 bad=[]
 if type(record.get('status')) is not int or record['status']<0:bad.append(label+': status must be a nonnegative integer')
 for key in ['stdout','stderr']:
  if type(record.get(key)) is not str:bad.append(label+': '+key+' must be a string')
 if 'timeout' in record and record['timeout'] is not False:bad.append(label+': timeout must be absent or boolean false')
 if 'valid_utf8' in record and record['valid_utf8'] is not True:bad.append(label+': valid_utf8 must be absent or boolean true')
 if bad:return bad
 streams=record['stdout']+'\n'+record['stderr']
 if '\ufffd' in streams or any(0xd800<=ord(ch)<=0xdfff for ch in streams):bad.append(label+': corrupted decoded stream')
 if any(marker in streams.lower() for marker in CRASH):bad.append(label+': crash/timeout marker')
 return bad
def version_errors(record,prefix,label='version'):
 bad=stage_errors(record,label)
 if bad:return bad
 if record['status']!=0 or record['stderr'] or not record['stdout'].startswith(prefix):bad.append(label+': invalid version record')
 return bad
def candidate_errors(c,check,ran,source):
 bad=stage_errors(check,'candidate check')+stage_errors(ran,'candidate run')
 if bad:return bad
 if c['category']=='success':
  if check['status']!=0 or check['stdout']or check['stderr']:bad.append('successful check must be silent')
  if ran['status']!=0 or ran['stdout']!=c['expected_stdout']or ran['stderr']:bad.append('exact successful execution differs')
 else:
  d=c.get('diagnostic')
  if not d:raise ValueError('Unpinned diagnostic: '+c['name'])
  expected=f"{source}:{d['line']}:{d['column']}: {d['message']}\n"
  if c['category']=='reject':
   if d['phase']!='source'or d['status']!=1:raise ValueError('Bad source phase/status')
   for x in [check,ran]:
    if x['status']!=1 or x['stdout']!=''or x['stderr']!=expected:bad.append('exact source rejection differs')
  elif c['category']=='runtime':
   if d['phase']!='runtime'or d['status']!=2:raise ValueError('Bad runtime phase/status')
   if check['status']!=0 or check['stdout']or check['stderr']:bad.append('runtime case must check silently')
   if ran['status']!=2 or ran['stdout']!=c['expected_stdout']or ran['stderr']!=expected:bad.append('exact runtime rejection differs')
  else:raise ValueError('Unknown case category')
 return bad
def gnu_errors(c,compiled,ran,source):
 bad=stage_errors(compiled,'GNU compile')
 if ran is not None:bad+=stage_errors(ran,'GNU run')
 if bad:return bad
 if c['gnu']=='reject':
  return []if compiled['status']==1 and not compiled['stdout']and compiled['stderr'].strip() and ran is None else['GNU source rejection mode differs']
 bad=[]
 if compiled['status']!=0 or compiled['stdout']or compiled['stderr']!=c.get('gnu_compile_stderr','').replace('{source}',source):bad.append('GNU compilation or exact expected diagnostics differ')
 if c['gnu']=='compile':
  if ran is not None:bad.append('unsafe GNU execution')
 elif c['gnu']=='run':
  if ran is None or ran['status']!=0 or ran['stderr']or ran['stdout']!=c['expected_stdout']:bad.append('GNU exact execution differs')
 else:raise ValueError('Unknown GNU mode')
 return bad
