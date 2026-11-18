program test
implicit none
real(8) :: a,b
call cpu_time(a)
call cpu_time(time=b)
if(a>=0.and.b>=0.and.b<a)stop 1
print *,"PASS"

end program
