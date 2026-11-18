program p
implicit none
logical::a(4)
character(len=3)::c(4)
a=[.true.,.false.,.true.,.true.]
if(any(cshift(a,-1).neqv.[.true.,.true.,.false.,.true.])) error stop 1
c=['a  ','b b',' cc',' d ']
if(any(cshift(c,2)/=[' cc',' d ','a  ','b b'])) error stop 2
print *, "PASS"
end program
