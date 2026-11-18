program main
implicit none
call emit()
contains
pure subroutine emit()
write(*,*)1
end subroutine
end program
