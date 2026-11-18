program p
implicit none
real(8)::a(3,4),b(3,4)
a=draw()
b=draw()
if(any(a/=a(1,1)).or.any(b/=b(1,1))) error stop 1
if(a(1,1)==b(1,1)) error stop 2
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
end function
end program
