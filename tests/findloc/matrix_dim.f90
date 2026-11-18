program p
implicit none
integer::a(2,3)
a=reshape([1,2,2,1,2,2],[2,3])
print *,findloc(a,2),findloc(a,2,back=.true.)
print *,findloc(a,2,dim=1),findloc(a,2,dim=2)
print *,findloc(a,2,dim=1,back=.true.),findloc(a,2,dim=2,back=.true.)
end program
