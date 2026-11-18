program p
implicit none
integer::a(-2:3)=[5,2,5,2,5,9]
print *,findloc(a,5),findloc(a,5,dim=1),findloc(a,5,back=.true.)
print *,findloc(a,4),findloc(a(3:-2:-1),5,dim=1)
end program
