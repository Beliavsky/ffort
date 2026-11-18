program p
implicit none
character(65536)::c,v
integer::n,s
call getcwd(c,s)
if(s/=0.or.len(c)/=65536) error stop 1
call get_command_argument(0,v,n,s)
if(n/=11.or.s/=0.or.len(v)/=65536) error stop 2
if(trim(v)/='program.f90') error stop 3
end program
