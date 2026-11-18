program p
implicit none
integer::i,j,indices(3)
real(8)::x(3)=[10.0_8,100.0_8,1000.0_8]
character(:),allocatable::a(:,:)
allocate(character(3)::a(-1:1,2:3))
a='---'
forall(i=1:3) indices(i)=nint(log10(x(i)))
forall(i=-1:1,j=2:3)
 a(i,j)=achar(64+indices(i+2))//achar(47+j)//'!'
 a(i,j)=a(-i,5-j)
end forall
print *,len(a),lbound(a,1),lbound(a,2),ubound(a,1),ubound(a,2),indices
print '(6a3)',a
end program
