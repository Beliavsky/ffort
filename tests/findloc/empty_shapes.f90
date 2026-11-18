program p
implicit none
integer::a(0),b(0,3),c(3,0)
print *,findloc(a,1),findloc(a,1,1),findloc(b,1),findloc(c,1)
print *,findloc(b,1,1),findloc(c,1,2)
print *,size(findloc(b,1,2)),size(findloc(c,1,1))
end program
