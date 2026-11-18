program p
implicit none
real(8)::x(3,4,2)
real::y(9)
integer::j
x=wide()
y=narrow()
do j=1,2
if(any(x(:,:,j)<0d0).or.any(x(:,:,j)>=1d0)) error stop 1
end do
if(any(y<0.0).or.any(y>=1.0)) error stop 2
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
end function
function wide() result(r)
real(8)::r(3,4,2)
call random_number(r(:,4:1:-1,:))
end function
function narrow() result(r)
real::r(9)
call random_number(harvest=r)
end function
end program
