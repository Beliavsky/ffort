program p
implicit none
integer::u,s
character(0)::empty
character(8)::line
u=27
read(u,'(a)',iostat=s)empty
if(s/=0)error stop 1
read(u,'(a)',iostat=s)line
if(s/=0)error stop 2
print '(a,1x,l1)',trim(line),lle(empty,' ')
end program
