program p
implicit none
write(*,'(a)',advance='no') 'P'
call emit_text()
write(*,'(t2,a)') 'Z'
contains
subroutine emit_text()
write(*,'(a,tl2,a)',advance='no')'abcd','X'
end subroutine
end program
