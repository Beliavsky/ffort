program p
implicit none
integer::i
i=2
call take('abc'(i:))
contains
subroutine take(s)
character(*),intent(in)::s
if(s/='bc'.or.len(s)/=2) error stop 1
print *, 'input actual'
end subroutine
end program
