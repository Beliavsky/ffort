program p
implicit none
integer::a(3)=[2,1,2]
print *,findloc(a,2,1,[.true.,.true.,.true.],8,.true.)
print *,findloc(a,2,1,.false.,4,.false.)
end program
