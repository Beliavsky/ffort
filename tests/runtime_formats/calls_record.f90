program p
implicit none

write(*,'(a)',advance='no')'A'
call show
print '(a)','C'
contains
subroutine show()
write(*,'(a,1x)',advance='no')'B'
end subroutine
end program
