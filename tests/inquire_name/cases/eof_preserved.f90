program p
implicit none
integer::iu
character(24)::nm
character(5)::record
integer::ios
iu=17
! GNU_REGISTER_INPUT
read(iu,'(a)') record
read(iu,'(a)') record
read(iu,'(a)',iostat=ios) record
inquire(unit=iu,name=nm)
write(*,'(a)') trim(nm)
end program
