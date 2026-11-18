program p
implicit none
character(8),target::storage(1)
character(8),pointer::a(:)
integer::n
storage="17"
a=>storage
read(a(1),*)n
end program
