program p
implicit none
character(4)::b
integer::n,s
b='junk'
call get_command_argument(1,value=b,length=n,status=s)
if(s<=0.or.n/=0.or.b/='')error stop 1
write(*,'(a,t2,a)',advance='no')'ABCDE','x'
write(*,'(tr1,a)')'!'
end program
