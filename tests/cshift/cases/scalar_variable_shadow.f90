program p
implicit none
integer::cshift
cshift=17
if(cshift/=17) error stop 1
print *, "PASS"
end program
