program p
implicit none
character(40)::text
character(:),allocatable::a(:)
text='word'
read(text,*)a
end program
