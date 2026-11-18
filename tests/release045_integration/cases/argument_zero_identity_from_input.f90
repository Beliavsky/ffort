program p
implicit none
integer::u,n,s,k
character(80)::expected
character(:),allocatable::name
u=27
read(u,'(a)')expected
k=len_trim(expected)
call get_command_argument(0,length=n,status=s)
if(s/=0.or.n<k)error stop 1
allocate(character(len=n)::name)
call get_command_argument(0,value=name,status=s)
if(s/=0)error stop 2
print '(a,l1)','argv0=',lle(name(n-k+1:n),expected).and.lge(name(n-k+1:n),expected)
end program
