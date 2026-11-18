program p
implicit none
integer::n
call probe()
contains
subroutine probe(x)
character(*),optional,intent(in)::x
print *,x%len
end subroutine
end program
