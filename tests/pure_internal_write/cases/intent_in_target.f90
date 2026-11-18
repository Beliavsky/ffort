program p
implicit none
call fill("00",7)
contains
pure subroutine fill(s,n)
character(*),intent(in)::s
integer,intent(in)::n
write(s,"(i2.2)")n
end subroutine
end program
