program p
implicit none
call probe()
contains
subroutine probe(x)
character(*),optional,intent(in)::x
print *,len(x(:))
end subroutine
end program
