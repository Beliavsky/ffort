program p
implicit none
integer::a(2,3)
a=reshape([2,7,7,-1,-1,3],[2,3])
print *,minloc(a,1),maxloc(a,1),minloc(a,2),maxloc(a,2)
end program
