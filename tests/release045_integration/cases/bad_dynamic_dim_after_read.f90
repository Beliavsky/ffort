program p
implicit none
integer::u,d
character(30)::line
real(8)::a(2,2)
u=27
read(u,'(a)')line
read(line,*)a
d=3
print '(a)','SAFE'
print '(2f5.1)',norm2(a,dim=d)
end program
