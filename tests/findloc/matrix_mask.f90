program p
implicit none
integer::a(2,3)
logical::m(2,3)
a=reshape([1,2,2,1,2,2],[2,3]);m=reshape([.true.,.false.,.false.,.true.,.true.,.false.],[2,3])
print *,findloc(a,2,mask=m),findloc(a,2,dim=1,mask=m),findloc(a,2,dim=2,mask=m)
print *,findloc(a,2,mask=m,back=.true.)
end program
