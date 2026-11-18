program p
implicit none
integer::i
i=2
call outer('abc'(i:i))
contains
subroutine outer(s)
character(*),intent(in)::s
call inner(s)
end subroutine
subroutine inner(s)
character(*),intent(in)::s
if(s/='b') error stop 1
print *, 'nested forwarding'
end subroutine
end program
