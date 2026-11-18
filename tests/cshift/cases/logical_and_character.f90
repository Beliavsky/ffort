program p
implicit none
logical::a(2,3),b(2,3)
character(len=3)::c(2,3),d(2,3)
a=reshape([.true.,.false.,.false.,.true.,.true.,.true.],[2,3])
b=cshift(a,shift=[1,-1],dim=2)
if(any(b.neqv.reshape([.false.,.true.,.true.,.false.,.true.,.true.],[2,3]))) error stop 1
c=reshape(['a  ',' bb','c c',' dd','e  ',' ff'],[2,3])
d=cshift(c,shift=[1,-1],dim=2)
if(any(d/=reshape(['c c',' ff','e  ',' bb','a  ',' dd'],[2,3]))) error stop 2
if(len(d)/=3.or.kind(d)/=kind(c)) error stop 3
print *, "PASS"
end program
