program p
implicit none
integer :: iu,i
character(15) :: name
character(15) :: saved(3)
iu=17
! GNU_REGISTER_INPUT
i=1
do while(i<=3)
  if(i==2) then
    iu=18
  else
    iu=17
  end if
  inquire(unit=iu,name=name)
  saved(i)=name
  i=i+1
end do
write(*,'(a,a,a,a,a,a,i0)') trim(saved(1)),'|',trim(saved(2)),'|',trim(saved(3)),'|',i-1
end program
