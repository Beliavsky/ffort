program p
implicit none
real(8)::x
x=draw(70)
print *, "PASS"
contains
recursive function draw(n) result(r)
integer,intent(in)::n
real(8)::r
call random_number(r)
if(n>0) r=r+draw(n-1)
end function
end program
