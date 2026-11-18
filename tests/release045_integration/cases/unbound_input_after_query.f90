program p
implicit none
integer::u,n,s
character(12)::line
call get_command_argument(0,length=n,status=s)
if(s/=0.or.n<=0)error stop 1
print '(a)','SAFE'
u=27
read(u,'(a)')line
end program
