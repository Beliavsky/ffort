program p
implicit none
real(8)::x
x=draw(1d0)
print *, "PASS"
contains
real(8) function draw(n) result(r)
real(8),intent(in)::n
integer::i
call random_number(n)
r=0d0
end function
end program
