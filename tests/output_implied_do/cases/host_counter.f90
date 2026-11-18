program main
implicit none
integer::i
i=0
call work()
contains
subroutine work()
print *, (i,i=1,3)
end subroutine
end program
