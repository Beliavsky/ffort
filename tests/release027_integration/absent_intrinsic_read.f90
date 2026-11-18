program p
implicit none
call probe()
contains
subroutine probe(x)
character(*),optional,intent(in)::x
print *,index(x,'a')
end subroutine
end program
