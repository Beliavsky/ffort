program p
implicit none
integer :: iu,i
character(15) :: name
character(20) :: a(2)
! GNU_REGISTER_INPUT
i=1
do while(i<=2)
  iu=16+i
  inquire(unit=iu,name=name)
  write(a(i),'(a,1x,f0.1)') trim(name),real(i)
  a(i)(1:1)='@'
  i=i+1
end do
write(*,'(a,a,a)') '[',a(1),']'
write(*,'(a,a,a)') '[',a(2),']'
end program
