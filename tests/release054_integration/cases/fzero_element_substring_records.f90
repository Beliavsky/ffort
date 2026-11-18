program p
implicit none
character(12) :: a(2)
a='............'
write(a(1),'(f0.2)') -1.25_8
a(1)(2:2)='9'
write(a(2),'(f0.1)') 2.5
write(*,'(a,a,a,a,a)') '[',a(1),']|[',a(2),']'
end program
