program p
implicit none
integer::u,s
character(:),allocatable::line,a,b
real(8)::v(2)
u=27
allocate(character(len=80)::line)
allocate(character(len=5)::a,b)
read(u,'(a)')line
read(line,*,iostat=s)v,a,b
if(s/=0.or.len(a)/=5.or.len(b)/=5)error stop 1
print '(a,1x,a,1x,f4.1,1x,l1)',a,b,norm2(v),llt(b,a)
end program
