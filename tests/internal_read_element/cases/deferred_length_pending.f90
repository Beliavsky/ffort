program p
implicit none
character(:),allocatable::a(:)
integer::n
allocate(character(8)::a(1))
a(1)="17"
read(a(1),*)n
end program
