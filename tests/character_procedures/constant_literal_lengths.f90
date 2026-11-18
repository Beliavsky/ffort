program test
implicit none
character(len('Ab c'))::a
character(len=len("A""B"))::b
character(len=len('X) + Z'))::c
print *,len(a),len(b),len(c)
end program
