program p
implicit none
character(2)::s
call fill(s,7)
print "(a)",s
contains
pure subroutine fill(s,n)
character(*),intent(out)::s
integer,intent(in)::n
write(s,"(i2.2)")n
end subroutine
end program
