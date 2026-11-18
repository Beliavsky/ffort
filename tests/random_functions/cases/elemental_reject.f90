program p
implicit none
real(8)::x
x=draw(1)
print *, "PASS"
contains
elemental real(8) function draw(n) result(r)
integer,intent(in)::n
call random_number(r)
end function
end program
