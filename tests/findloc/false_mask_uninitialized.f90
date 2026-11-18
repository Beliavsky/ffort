program p
implicit none
integer::a(3)
print *,findloc(a,3,mask=.false.)
end program
