program main
implicit none

call work()
contains
subroutine work()
integer::i=1
print *, (i,i=1,3)
end subroutine
end program
