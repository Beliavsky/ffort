program p
implicit none
if(query()/=11) error stop 1
contains
integer function query() result(n)
character(256)::c
integer::s
call getcwd(c,s)
if(s/=0) error stop 2
call get_command_argument(0,length=n,status=s)
if(s/=0) error stop 3
end function
end program
