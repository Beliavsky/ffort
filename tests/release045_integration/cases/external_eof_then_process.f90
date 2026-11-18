program p
implicit none
integer::u,s,n,ps
character(8)::line,missing
u=27
read(u,'(a)',iostat=s)line
if(s/=0)error stop 1
print '(a)',trim(line)
read(u,'(a)',iostat=s)line
if(s>=0)error stop 2
call get_command_argument(1,value=missing,length=n,status=ps)
print '(l1,1x,l1)',s<0,ps>0.and.n==0.and.missing==''
end program
