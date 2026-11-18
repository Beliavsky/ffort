program p
implicit none
character(4) :: a(2)
a(1)='ABCD'
a(2)='WXYZ'
a(1)(2:3)='zz'
write(*,'(a,a,a)') '[',a(1),']'
write(*,'(a)',advance='no') 'KEEP'
write(a(2),'(f0.2)') 123.45
write(*,'(a)') 'unexpected commit'
end program
