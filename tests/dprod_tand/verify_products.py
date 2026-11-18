"""Independent exact REAL4 widening products, compared as printed Decimal tokens."""
from pathlib import Path
import json,struct
ROOT=Path(__file__).resolve().parent

def model():
    values=[-16777216.,-123.75,-2.5,-1.00000011920928955078125,-.125,-0.,0.,.125,1.00000011920928955078125,2.5,123.75,16777216.]
    f32=lambda x:struct.unpack('f',struct.pack('f',x))[0]
    source='program p\nimplicit none\n'
    expected=[]
    for a in values:
        for b in values:
            source+=f"write(*,'(es26.17)')dprod({a!r},{b!r})\n"
            # The product has at most 48 significant binary bits, so widening
            # two binary32 values before binary64 multiplication is exact.
            expected.append(format(f32(a)*f32(b),'.17E'))
    return source+'end program\n','\n'.join(expected)+'\n'

def verify_matrix():
    source,expected=model()
    if (ROOT/'cases/exact_products.f90').read_text()!=source:raise SystemExit('Independent product source differs')
    found=[c for c in json.loads((ROOT/'manifest.json').read_text())['cases'] if c['name']=='exact_products']
    if len(found)!=1 or found[0]['expected_stdout']!=expected or found[0]['rel_tol']!=0 or found[0]['abs_tol']!=0:raise SystemExit('Independent product expectation differs')
    return 144
if __name__=='__main__':print(verify_matrix(),'independent exact products verified')
