program p
implicit none
integer::cshift(3),x
cshift=[4,5,6]
x=cshift(2)
if(x/=5) error stop 1
print *, "PASS"
end program
