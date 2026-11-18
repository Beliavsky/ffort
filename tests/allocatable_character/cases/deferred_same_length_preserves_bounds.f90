program main
implicit none
character(:),allocatable::a(:),b(:)
allocate(character(2)::a(-1:0))
allocate(character(2)::b(5:6))
a='xx';b='yy';a=b
print *,len(a),lbound(a,1),ubound(a,1)
a=b(:)
print *,lbound(a,1)

end program
