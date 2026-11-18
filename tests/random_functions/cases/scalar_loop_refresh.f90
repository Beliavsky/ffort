program p
implicit none
real(8)::a(8)
integer::j
do j=1,8
a(j)=draw()
end do
if(all(a==a(1))) error stop 1
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
end function
end program
