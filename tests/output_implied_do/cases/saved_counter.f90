program main
implicit none

call work()
contains
subroutine work()
integer,save::i
print *, (i,i=1,3)
end subroutine
end program
