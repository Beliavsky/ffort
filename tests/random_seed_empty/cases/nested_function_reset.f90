program p
implicit none
real(8)::a(2),x
call random_number(a)
x=draw()
if(x/=a(1)) error stop 1
call random_number(x)
if(x/=a(2)) error stop 2
print '(a)','seed-ok'
contains
real(8) function draw() result(r)
call reset()
call random_number(r)
end function
subroutine reset()
call random_seed
end subroutine
end program
