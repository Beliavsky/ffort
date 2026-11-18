program p
implicit none
character(:),allocatable::s
s='old'
call fill(s)
if(s/='newlong'.or.len(s)/=7) error stop 1
contains
subroutine fill(x)
character(:),allocatable,intent(out)::x
if(allocated(x)) error stop 2
x='newlong'
end subroutine
end program
