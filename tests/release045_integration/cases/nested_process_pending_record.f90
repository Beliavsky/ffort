program p
implicit none
integer::n,s
call get_command_argument(0,length=n,status=s)
if(s/=0.or.n<=0)error stop 1
write(*,'(a,t2,a)',advance='no')'ABCD','x'
call helper()
write(*,'(a)')'!'
contains
subroutine helper()
integer::m,st
call get_command_argument(0,length=m,status=st)
if(st/=0.or.m<=0)error stop 2
write(*,'(tl10,a)',advance='no')'Z'
end subroutine
end program
