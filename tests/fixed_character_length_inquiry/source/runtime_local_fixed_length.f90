program p
implicit none
integer::n
n=5
call work(n)
contains
subroutine work(n)
integer,intent(in)::n
character(n),allocatable::x
if(allocated(x).or.len(x)/=n) error stop 1
x='hi'
if(x/='hi   ') error stop 2
end subroutine
end program
