program main
implicit none
character(65535)::a
a=repeat('x',65535)
write(*,*)a
end program
