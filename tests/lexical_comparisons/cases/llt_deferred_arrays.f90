program p
implicit none
character(:),allocatable::a(:),b(:)
logical::x(2)
allocate(character(2)::a(2),b(2))
a=['ab','bc']
b=['ab','ab']
x=llt(a,b)
print *,x
end program
