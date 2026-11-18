program main
implicit none
character(65536),allocatable::a(:),b(:)
integer::s
allocate(a(200),stat=s)
if(s/=0) error stop 1
allocate(b(100),stat=s)
if(s==0.or.allocated(b)) error stop 2
print *,size(a),len(a),allocated(b)

end program
