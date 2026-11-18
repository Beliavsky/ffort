program p
implicit none
character(:),allocatable::a
print *,'must not leak',min(a,'z')
end program
