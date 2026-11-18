program p
implicit none
character(2)::x(32769)
x='xx'
write(*,'(a)')'before'
write(*,'("prefix",*(g0))')x
end program
