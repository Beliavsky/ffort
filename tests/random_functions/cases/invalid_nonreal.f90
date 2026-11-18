program p
implicit none
real(8)::x
x=draw(1)
print *, "PASS"
contains
real(8) function draw(n) result(r)
integer,intent(in)::n
integer::i
call random_number(i)
r=0d0
end function
end program
