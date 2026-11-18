program p
implicit none
character(:),allocatable::c,v
integer::n,s
allocate(character(256)::c)
allocate(character(20)::v)
call getcwd(c,s)
if(s/=0.or.len(c)/=256) error stop 1
call get_command_argument(0,v,n,s)
if(v/='program.f90'.or.n/=11.or.s/=0.or.len(v)/=20) error stop 2
if(.not.allocated(c).or..not.allocated(v)) error stop 3
end program
