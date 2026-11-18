program p
implicit none

call show
print '(a)','B'
contains
subroutine show()
write(*,'(a)',advance='no')'A'
end subroutine
end program
