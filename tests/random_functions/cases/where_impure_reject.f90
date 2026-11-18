program p
implicit none
real(8)::x(3)
x=-1d0
where([.true.,.false.,.true.])
x=draw()
end where
if(x(1)/=x(3).or.x(2)/=-1d0) error stop 1
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
end function
end program
