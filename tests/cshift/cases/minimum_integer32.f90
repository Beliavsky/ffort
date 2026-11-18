program p
implicit none
integer::s
s=-2147483647-1
if(any(cshift([1,2,3],s)/=[2,3,1])) error stop 1
print *, "PASS"
end program
