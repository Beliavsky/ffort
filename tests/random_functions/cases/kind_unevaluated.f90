program p
implicit none
integer::k
k=kind(draw())
if(k/=8) error stop 1
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
error stop "KIND evaluated function"
end function
end program
