program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
character(20)::msg
s=2
allocate(a(s),b(2),stat=s)
end program
