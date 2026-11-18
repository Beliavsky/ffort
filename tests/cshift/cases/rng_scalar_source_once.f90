program p
implicit none
real(8)::a(128),b(128)
a=0d0
b=cshift(a+draw(),31)
if(any(b/=b(1))) error stop 1
if(b(1)<0d0.or.b(1)>=1d0) error stop 2
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
end function
end program
