module optional_index_array
contains
subroutine probe(x,b)
character(*),intent(in)::x(:)
logical,optional,intent(in)::b(:)
print *,index(x,'a',back=b)
end subroutine
end module
program p
use optional_index_array
implicit none
character(4)::x(2)
x=['aba ','baba']
call probe(x)
call probe(x,[.true.,.true.])
call probe(x(:0))
end program
