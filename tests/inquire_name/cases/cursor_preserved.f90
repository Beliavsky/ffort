program p
implicit none
integer::iu
character(24)::nm
character(5)::record
iu=17
! GNU_REGISTER_INPUT
read(iu,'(a)') record
inquire(unit=iu,name=nm)
read(iu,'(a)') record
write(*,'(a)') record
end program
