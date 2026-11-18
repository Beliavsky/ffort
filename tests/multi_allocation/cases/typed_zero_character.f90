program p
implicit none
character(:),allocatable::a(:),b(:)
integer::s
allocate(character(len=-3)::a(0),b(2),stat=s)
b="x"
print *,s,len(a),len(b),size(a),size(b)
end program
