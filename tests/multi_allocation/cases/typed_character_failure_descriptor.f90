program p
implicit none
character(:),allocatable::a(:),b(:),c(:)
integer::s
allocate(character(len=1)::b(-2:2))
b="Q"
allocate(character(len=4)::a(2),b(3),c(1),stat=s)
print *,s>0,allocated(a),allocated(b),allocated(c),len(a),len(b),size(b),lbound(b,1),all(b=="Q")
end program
