program p
implicit none
integer::u,s
character(80)::line
character(4)::a,b
real(8)::v(2)
u=27
read(u,'(a)',iostat=s)line
if(s/=0)error stop 1
read(line,*,iostat=s)v,a,b
if(s/=0)error stop 2
print '(f5.1,1x,a,1x,l1)',norm2(v),a,lgt(a,b)
end program
