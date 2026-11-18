program p
implicit none
character(4)::v
integer::n,s
v='xxxx'
n=-7
s=-7
call get_command_argument(2147483647,v,n,s)
if(n/=0.or.s<=0) error stop 1
write(*,'(A)') '['//v//']'
end program
