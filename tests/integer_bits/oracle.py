"""Independent declared-width oracle, with no floating-point conversion."""
def signed(value,kind):
    if kind not in (4,8):raise ValueError('unsupported kind')
    modulus=1<<(8*kind);value%=modulus
    return value-modulus if value>=modulus//2 else value
def binary(name,a,b,kind):
    operations={'iand':lambda:a&b,'ior':lambda:a|b,'ieor':lambda:a^b}
    return signed(operations[name](),kind)
def complement(a,kind):return signed(~a,kind)
def test(a,pos,kind):
    if not 0<=pos<8*kind:raise ValueError('position outside width')
    return bool(((a % (1<<(8*kind)))>>pos)&1)
