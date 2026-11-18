program p
implicit none
character(256),save::c=' '
character(20),save::v=' '
integer,save::n=-7
integer,save::s=-7
call getcwd(c,s)
if(s/=0) error stop 1
call get_command_argument(0,v,n,s)
if(v/='program.f90'.or.n/=11.or.s/=0) error stop 2
end program
