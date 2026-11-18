program p
implicit none
integer :: iu
character(:),allocatable :: name,moved
character(9) :: second
iu=17
! GNU_REGISTER_INPUT
allocate(character(9)::name)
inquire(unit=iu,name=name)
call move_alloc(name,moved)
iu=18
inquire(unit=iu,name=second)
write(*,'(a,a,i0,a,a,a)') moved,'|',len(moved),'|[',second,']'
end program
