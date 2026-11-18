program p
implicit none
integer::u,s,i
character(80)::line
real(8)::a(2,2),b(2,2)
u=27
read(u,'(a)')line
read(line,*)a
b=transpose(a)
print '(*(f4.0,tl1,a))',(b(i,1),'X',i=1,2)
print '(2f5.1)',norm2(b,dim=1)
end program
