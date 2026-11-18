program p
implicit none
character(2),allocatable::a(:)
character(4),allocatable::b(:)
allocate(a(2),b(3))
a="abcd"
b="xy"
print *,len(a),len(b),all(a=="ab"),all(b=="xy  ")
end program
