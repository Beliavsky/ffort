program p
implicit none
character(5)::x(3)
integer::i
x=[(repeat("a",i),i=1,3)]
end program
