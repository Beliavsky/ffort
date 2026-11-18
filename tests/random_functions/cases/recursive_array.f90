program p
implicit none
real(8)::x(5)
x=draw(5,3)
if(any(x<0d0).or.any(x>=4d0)) error stop 1
print *, "PASS"
contains
recursive function draw(n,k) result(r)
integer,intent(in)::n,k
real(8)::r(n)
call random_number(r)
if(k>0) r=r+draw(n,k-1)
end function
end program
