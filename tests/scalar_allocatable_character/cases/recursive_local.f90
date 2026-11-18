program p
implicit none
integer::i
call rec(3)
contains
recursive subroutine rec(n)
integer,intent(in)::n
character(:),allocatable::x
if(allocated(x)) error stop 1
x=repeat('a',n)
if(n>0) call rec(n-1)
if(len(x)/=n) error stop 2
end subroutine
end program
