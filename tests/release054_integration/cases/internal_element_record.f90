program p
implicit none
integer :: iu
character(18) :: name
character(20) :: records(3)
iu=17
! GNU_REGISTER_INPUT
records='UNCHANGED!'
inquire(name=name,unit=iu)
write(records(2),'(a,a,i0)') trim(name),':',len_trim(name)
write(*,'(a,a,a,a,a)') records(1),'|',records(2),'|',records(3)
end program
