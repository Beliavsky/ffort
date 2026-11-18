program p
implicit none
character(:),allocatable::name
integer::n,s
call get_command_argument(0,length=n,status=s)
if(s/=0.or.n<=0)error stop 1
allocate(character(len=n)::name)
call get_command_argument(0,value=name,status=s)
if(s/=0.or.len_trim(name)/=n)error stop 2
print '(a,l1)','name=',lgt(name,'')
end program
