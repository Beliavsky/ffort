program p
implicit none
integer::a(2,3)
logical::m(2,3)
a=reshape([2,7,7,-1,-1,3],[2,3])
m=reshape([.true.,.false.,.false.,.false.,.true.,.true.],[2,3])
print *,minloc(a,mask=m),maxloc(a,1,m),minloc(a,2,m)
end program
